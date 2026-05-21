package spi_core_scoreboard_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    
    class spi_core_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(spi_core_scoreboard)
        
        uvm_analysis_export #(spi_core_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(spi_core_sequence_item) sb_fifo;
        spi_core_sequence_item sb_seq_item;
        
        int error_count , correct_count ;
        
        function new (string name = "spi_core_scoreboard" , uvm_component parent = null);
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

                if (sb_seq_item.tx_pop !== sb_seq_item.tx_pop_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] tx_pop - mismatch in predicted_tx_pop=%0b vs observed_tx_pop=%0b", sb_seq_item.tx_pop_expected, sb_seq_item.tx_pop));
                    error_count++;
                end

                if (sb_seq_item.rx_push_valid !== sb_seq_item.rx_push_valid_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] rx_push_valid - mismatch in predicted_rx_push_valid=%0b vs observed_rx_push_valid=%0b", sb_seq_item.rx_push_valid_expected, sb_seq_item.rx_push_valid));
                    error_count++;
                end

                if (sb_seq_item.busy !== sb_seq_item.busy_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] busy - mismatch in predicted_busy=%0b vs observed_busy=%0b", sb_seq_item.busy_expected, sb_seq_item.busy));
                    error_count++;
                end

                if (sb_seq_item.transfer_done_pulse !== sb_seq_item.transfer_done_pulse_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] transfer_done_pulse - mismatch in predicted_transfer_done_pulse=%0b vs observed_transfer_done_pulse=%0b", sb_seq_item.transfer_done_pulse_expected, sb_seq_item.transfer_done_pulse));
                    error_count++;
                end

                if (sb_seq_item.sclk !== sb_seq_item.sclk_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] sclk - mismatch in predicted_sclk=%0b vs observed_sclk=%0b", sb_seq_item.sclk_expected, sb_seq_item.sclk));
                    error_count++;
                end

                if (sb_seq_item.mosi !== sb_seq_item.mosi_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] mosi - mismatch in predicted_mosi=%0b vs observed_mosi=%0b", sb_seq_item.mosi_expected, sb_seq_item.mosi));
                    error_count++;
                end

                if (sb_seq_item.rx_push_data !== sb_seq_item.rx_push_data_expected) begin
                    `uvm_error("run_phase", $sformatf("[SCOREBOARD_ERROR] rx_push_data - mismatch in predicted_rx_push_data=0x%0h vs observed_rx_push_data=0x%0h", sb_seq_item.rx_push_data_expected, sb_seq_item.rx_push_data));
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