package apb_scoreboard_pkg;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    
    class apb_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(apb_scoreboard)
        
        uvm_analysis_export #(apb_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(apb_sequence_item) sb_fifo;
        apb_sequence_item sb_seq_item;
        
        int error_count , correct_count ;
        
        function new (string name = "apb_scoreboard" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export",this);
            sb_fifo = new("sb_fifo",this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_fifo.analysis_export);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin  
                sb_fifo.get(sb_seq_item);
                /*check outputs*/
                if(sb_seq_item.pready !== sb_seq_item.pready_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] pready - mismatch in predicted_pready=%d vs observed_pready=%d", sb_seq_item.pready_exp, sb_seq_item.pready));
                    error_count++;
                end
                if(sb_seq_item.pslverr !== sb_seq_item.pslverr_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] pslverr - mismatch in predicted_pslverr=%d vs observed_pslverr=%d", sb_seq_item.pslverr_exp, sb_seq_item.pslverr));
                    error_count++;
                end
                if(sb_seq_item.cfg_en !== sb_seq_item.cfg_en_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_en - mismatch in predicted_cfg_en=%d vs observed_cfg_en=%d", sb_seq_item.cfg_en_exp, sb_seq_item.cfg_en));
                    error_count++;
                end
                if(sb_seq_item.cfg_mstr !== sb_seq_item.cfg_mstr_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_mstr - mismatch in predicted_cfg_mstr=%d vs observed_cfg_mstr=%d", sb_seq_item.cfg_mstr_exp, sb_seq_item.cfg_mstr));
                    error_count++;
                end
                if(sb_seq_item.cfg_lsb_first !== sb_seq_item.cfg_lsb_first_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_lsb_first - mismatch in predicted_cfg_lsb_first=%d vs observed_cfg_lsb_first=%d", sb_seq_item.cfg_lsb_first_exp, sb_seq_item.cfg_lsb_first));
                    error_count++;
                end
                if(sb_seq_item.cfg_loopback !== sb_seq_item.cfg_loopback_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_loopback - mismatch in predicted_cfg_loopback=%d vs observed_cfg_loopback=%d", sb_seq_item.cfg_loopback_exp, sb_seq_item.cfg_loopback));
                    error_count++;
                end
                if(sb_seq_item.tx_empty !== sb_seq_item.tx_empty_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] tx_empty - mismatch in predicted_tx_empty=%d vs observed_tx_empty=%d", sb_seq_item.tx_empty_exp, sb_seq_item.tx_empty));
                    error_count++;
                end
                if(sb_seq_item.irq !== sb_seq_item.irq_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] irq - mismatch in predicted_irq=%d vs observed_irq=%d", sb_seq_item.irq_exp, sb_seq_item.irq));
                    error_count++;
                end
                if(sb_seq_item.cfg_mode !== sb_seq_item.cfg_mode_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_mode - mismatch in predicted_cfg_mode=%d vs observed_cfg_mode=%d", sb_seq_item.cfg_mode_exp, sb_seq_item.cfg_mode));
                    error_count++;
                end
                if(sb_seq_item.cfg_width !== sb_seq_item.cfg_width_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_width - mismatch in predicted_cfg_width=%d vs observed_cfg_width=%d", sb_seq_item.cfg_width_exp, sb_seq_item.cfg_width));
                    error_count++;
                end
                if(sb_seq_item.ss_n !== sb_seq_item.ss_n_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] ss_n - mismatch in predicted_ss_n=%d vs observed_ss_n=%d", sb_seq_item.ss_n_exp, sb_seq_item.ss_n));
                    error_count++;
                end
                if(sb_seq_item.cfg_delay !== sb_seq_item.cfg_delay_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_delay - mismatch in predicted_cfg_delay=%d vs observed_cfg_delay=%d", sb_seq_item.cfg_delay_exp, sb_seq_item.cfg_delay));
                    error_count++;
                end
                if(sb_seq_item.cfg_clk_div !== sb_seq_item.cfg_clk_div_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] cfg_clk_div - mismatch in predicted_cfg_clk_div=%d vs observed_cfg_clk_div=%d", sb_seq_item.cfg_clk_div_exp, sb_seq_item.cfg_clk_div));
                    error_count++;
                end
                if(sb_seq_item.tx_word !== sb_seq_item.tx_word_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] tx_word - mismatch in predicted_tx_word=%d vs observed_tx_word=%d", sb_seq_item.tx_word_exp, sb_seq_item.tx_word));
                    error_count++;
                end
                if(sb_seq_item.prdata !== sb_seq_item.prdata_exp) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] prdata - mismatch in predicted_prdata=%d vs observed_prdata=%d", sb_seq_item.prdata_exp, sb_seq_item.prdata));
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