package apb_coverage_pkg;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class apb_coverage extends uvm_component;
        `uvm_component_utils(apb_coverage)
        uvm_analysis_export #(apb_sequence_item) cov_export;
        uvm_tlm_analysis_fifo #(apb_sequence_item) cov_fifo;
        apb_sequence_item seq_item_cov;
        
        /*covergroups*/
        covergroup apb_protocol_cg;
            option.per_instance = 1;

            c_presetn: coverpoint seq_item_cov.presetn {
                bins reset_active   = {0};
                bins reset_inactive = {1};
                bins reset_asserted = (1 => 0);
                bins reset_released = (0 => 1);
            }

            c_psel: coverpoint seq_item_cov.psel;
            c_penable: coverpoint seq_item_cov.penable;

            c_protocol_phases: coverpoint ({seq_item_cov.psel, seq_item_cov.penable}) {
                bins idle   = {2'b00};
                bins setup  = {2'b10};
                bins access = {2'b11};
                
                bins idle_to_setup   = (2'b00 => 2'b10);
                bins setup_to_access = (2'b10 => 2'b11);
                bins access_to_idle  = (2'b11 => 2'b00);
                ignore_bins access_to_setup = (2'b11 => 2'b10);
            }

            c_pready: coverpoint seq_item_cov.pready {
                bins ready = {1};
            }

            c_pslverr: coverpoint seq_item_cov.pslverr {
                bins no_error = {0};
            }

            C_cfg_en: coverpoint seq_item_cov.cfg_en {
                bins disabled = {0};
                bins enabled  = {1};
            }

            c_cfg_mode: coverpoint seq_item_cov.cfg_mode {
                bins mode_0 = {2'b00};
                bins mode_1 = {2'b01};
                bins mode_2 = {2'b10};
                bins mode_3 = {2'b11};
            }

            c_cfg_lsb_first: coverpoint seq_item_cov.cfg_lsb_first {
                bins msb_first = {0};
                bins lsb_first = {1};
            }

            c_cfg_loopback: coverpoint seq_item_cov.cfg_loopback {
                bins normal_operation = {0};
                bins loopback_mode   = {1};
            }

            c_cfg_width: coverpoint seq_item_cov.cfg_width {
                bins width_8  = {0};
                bins width_16 = {1};
                bins width_32 = {2};
            }

            c_tx_pop : coverpoint seq_item_cov.tx_pop {
                bins no_pop = {0};
                bins pop    = {1};
            }

            c_rx_push_valid: coverpoint seq_item_cov.rx_push_valid {
                bins no_push = {0};
                bins push    = {1};
            }

             c_cfg_clk_div: coverpoint seq_item_cov.cfg_clk_div {

                bins div_0    = {16'd0};
                bins div_1    = {16'd1};
                bins div_2_7  = {[16'd2:16'd7]};
                bins div_8    = {16'd8};
                bins div_9_15 = {[16'd9:16'd15]};
                bins div_16   = {16'd16};
                bins div_mid  = {[16'd17:16'd255]};
                bins div_high = {[16'd256:16'd65534]};
                bins div_max  = {16'd65535};
            }

            c_cfg_delay: coverpoint seq_item_cov.cfg_delay {

                bins delay_0   = {8'd0};
                bins delay_1   = {8'd1};
                bins delay_2_7 = {[8'd2:8'd7]};
                bins delay_8   = {8'd8};
                bins delay_9_15 = {[8'd9:8'd15]};
                bins delay_16  = {8'd16};
                bins delay_17_31 = {[8'd17:8'd31]};
                bins delay_32  = {8'd32};
                bins delay_mid = {[8'd33:8'd254]};
                bins delay_max = {8'd255};
            }

            c_tx_word: coverpoint seq_item_cov.tx_word {
                bins all_zeros   = {32'h00000000};
                bins all_ones    = {32'hFFFFFFFF};
                bins toggle_01   = {32'h55555555};
                bins toggle_10   = {32'hAAAAAAAA};
                bins others_data = default;
            }

            c_irq : coverpoint seq_item_cov.irq {
                bins no_interrupt = {0};
                bins interrupt    = {1};
            }

            c_tx_empty: coverpoint seq_item_cov.tx_empty {
                bins not_empty = {0};
                bins empty     = {1};
            }
        endgroup

        covergroup apb_transaction_cg;
            option.per_instance = 1;

            c_paddr: coverpoint seq_item_cov.paddr {
                bins OFF_CTRL     = {8'h00};
                bins OFF_STATUS   = {8'h04};
                bins OFF_TX_DATA  = {8'h08};
                bins OFF_RX_DATA  = {8'h0C};
                bins OFF_CLK_DIV  = {8'h10};
                bins OFF_SS_CTRL  = {8'h14};
                bins OFF_INT_EN   = {8'h18};
                bins OFF_INT_STAT = {8'h1C};
                bins OFF_DELAY    = {8'h20};
                bins others_addr  = default;

                bins cnfg_to_write = {8'h00 >= 8'h08};
                bins cnfg_to_read  = {8'h00 >= 8'h0C};
            }

            c_pwrite: coverpoint seq_item_cov.pwrite {
                bins read_op  = {0};
                bins write_op = {1};
            }

            c_pwdata: coverpoint seq_item_cov.pwdata {
                bins all_zeros   = {32'h00000000};
                bins all_ones    = {32'hFFFFFFFF};
                bins toggle_01   = {32'h55555555};
                bins toggle_10   = {32'hAAAAAAAA};
                bins others_data = default;
            }

            c_prdata: coverpoint seq_item_cov.prdata {
                bins all_zeros   = {32'h00000000};
                bins all_ones    = {32'hFFFFFFFF};
                bins others_data = default;
            }

        endgroup

         // Loopback test coverage
        covergroup loopback_cg;

            width_cp: coverpoint seq_item_cov.cfg_width {
                bins w8  = {2'b00};
                bins w16 = {2'b01};
                bins w32 = {2'b10};
            }
        
            loopback_cp: coverpoint seq_item_cov.cfg_loopback {
                bins enabled = {1'b1};
            }
        
            transfer_cp: coverpoint seq_item_cov.transfer_done_pulse {
                bins tr = {1'b1};
            }
        
            // Ensures at least one transfer happens per width in loopback mode
            loopback_width: cross loopback_cp, width_cp, transfer_cp {
                bins lb_w8_tr  = binsof(loopback_cp.enabled) &&
                                 binsof(width_cp.w8) &&
                                 binsof(transfer_cp.tr);
        
                bins lb_w16_tr = binsof(loopback_cp.enabled) &&
                                 binsof(width_cp.w16) &&
                                 binsof(transfer_cp.tr);
        
                bins lb_w32_tr = binsof(loopback_cp.enabled) &&
                                 binsof(width_cp.w32) &&
                                 binsof(transfer_cp.tr);
            }

        endgroup

        // delay transfer coverage
        covergroup delay_cg;

            delay_cp: coverpoint seq_item_cov.cfg_delay{
            
                bins zero  = {0};
                bins one   = {1};

                bins gt_128 = {[128:255]};
            }

        endgroup

        function new(string name = "apb_coverage",uvm_component parent = null);
            super.new(name , parent);
            // create covergroup
            apb_protocol_cg = new();
            apb_transaction_cg = new();
            loopback_cg = new();
            delay_cg=new();
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase (phase);
            cov_export = new("cov_export",this);
            cov_fifo = new("cov_fifo",this);
        endfunction

        function void  connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            cov_export.connect(cov_fifo.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase (phase);
            forever begin
                cov_fifo.get(seq_item_cov);
                
                apb_protocol_cg.sample();
                loopback_cg.sample();
                delay_cg.sample();
                
                if (seq_item_cov.presetn && seq_item_cov.psel && seq_item_cov.penable) begin
                    apb_transaction_cg.sample();
                end
            end
        endtask
    endclass 
endpackage