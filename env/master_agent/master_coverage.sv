package master_coverage_pkg;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    
    class master_coverage extends uvm_component;
        `uvm_component_utils(master_coverage)
        uvm_analysis_export #(master_sequence_item) cov_export;
        uvm_tlm_analysis_fifo #(master_sequence_item) cov_fifo;
        master_sequence_item seq_item_cov;
        
        // Local state tracker
        bit tracker_cfg_en = 0;
        
        /*covergroups*/
        covergroup cg_apb_silent_failures;
            option.per_instance = 1;

            cp_paddr: coverpoint seq_item_cov.paddr {
                bins status_reg  = {8'h04};
                bins rx_data_reg = {8'h0C};
                bins reserved    = {[8'h24 : 8'hFF]};
            }

            cp_pwrite: coverpoint seq_item_cov.pwrite {
                bins read_op  = {0};
                bins write_op = {1};
            }

            cx_illegal_access: cross cp_paddr, cp_pwrite {
                bins write_to_status = binsof(cp_paddr.status_reg)  && binsof(cp_pwrite.write_op);
                bins write_to_rx     = binsof(cp_paddr.rx_data_reg) && binsof(cp_pwrite.write_op);
                bins write_reserved  = binsof(cp_paddr.reserved) && binsof(cp_pwrite.write_op);
                bins read_reserved   = binsof(cp_paddr.reserved) && binsof(cp_pwrite.read_op);
            }
        endgroup

        covergroup cg_disabled_ops;
            option.per_instance = 1;

            cp_tx_write: coverpoint (seq_item_cov.pwrite == 1'b1 && seq_item_cov.paddr == 8'h08) {
                bins attempted_push = {1};
            }

            cp_enable_state: coverpoint tracker_cfg_en {
                bins disabled = {0};
                bins enabled  = {1};
            }

            cx_push_while_disabled: cross cp_tx_write, cp_enable_state {
                bins hit = binsof(cp_tx_write.attempted_push) && binsof(cp_enable_state.disabled);
            }
        endgroup

        function new(string name = "master_coverage",uvm_component parent = null);
            super.new(name , parent);
            // create covergroup
            cg_apb_silent_failures = new();
            cg_disabled_ops = new();
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase (phase);
            cov_export = new("cov_export",this);
            cov_fifo = new("cov_fifo",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            cov_export.connect(cov_fifo.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase (phase);
            forever begin
                cov_fifo.get(seq_item_cov);
                
                if (seq_item_cov.presetn && seq_item_cov.psel && seq_item_cov.penable) begin
                    
                    if (seq_item_cov.pwrite && seq_item_cov.paddr == 8'h00) begin
                        tracker_cfg_en = seq_item_cov.pwdata[0];
                    end

                    cg_apb_silent_failures.sample();
                    cg_disabled_ops.sample();
                end
            end
        endtask
    endclass 
endpackage