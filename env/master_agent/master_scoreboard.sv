package master_scoreboard_pkg;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    
    class master_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(master_scoreboard)
        
        uvm_analysis_export #(master_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(master_sequence_item) sb_;
        master_sequence_item sb_seq_item;
        
        int error_count , correct_count ;
        
        function new (string name = "master_scoreboard" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export",this);
            sb_ = new("sb_",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin
                sb_.get(sb_seq_item);
                /*check outputs*/

                if (sb_seq_item.pready !== sb_seq_item.pready_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] pready - mismatch in predicted_pready=%0d vs observed_pready=%0d", sb_seq_item.pready_exp, sb_seq_item.pready));
                    error_count++;
                end

                if (sb_seq_item.pslverr !== sb_seq_item.pslverr_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] pslverr - mismatch in predicted_pslverr=%0d vs observed_pslverr=%0d", sb_seq_item.pslverr_exp, sb_seq_item.pslverr));
                    error_count++;
                end

                if (sb_seq_item.prdata !== sb_seq_item.prdata_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] prdata - mismatch in predicted_prdata=0x%0h vs observed_prdata=0x%0h", sb_seq_item.prdata_exp, sb_seq_item.prdata));
                    error_count++;
                end

                if (sb_seq_item.mosi !== sb_seq_item.mosi_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] mosi - mismatch in predicted_mosi=%0b vs observed_mosi=%0b", sb_seq_item.mosi_exp, sb_seq_item.mosi));
                    error_count++;
                end

                if (sb_seq_item.ss_n !== sb_seq_item.ss_n_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] ss_n - mismatch in predicted_ss_n=%0b vs observed_ss_n=%0b", sb_seq_item.ss_n_exp, sb_seq_item.ss_n));
                    error_count++;
                end

                if (sb_seq_item.sclk !== sb_seq_item.sclk_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] sclk - mismatch in predicted_sclk=%0b vs observed_sclk=%0b", sb_seq_item.sclk_exp, sb_seq_item.sclk));
                    error_count++;
                end

                if (sb_seq_item.irq !== sb_seq_item.irq_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] irq - mismatch in predicted_irq=%0d vs observed_irq=%0d", sb_seq_item.irq_exp, sb_seq_item.irq));
                    error_count++;
                end

                if (error_count == 0) begin
                    `uvm_info("run_phase", $sformatf("correct output :%s", sb_seq_item.convert2string()), UVM_HIGH);
                    correct_count++;
                end
            end
        endtask

        function void report_phase (uvm_phase phase);
            super.report_phase(phase);
            `uvm_info ("report_phase",$sformatf("Correct_count = %d , Error_count = %d",correct_count,error_count),UVM_MEDIUM);
        endfunction
    endclass
    
endpackage