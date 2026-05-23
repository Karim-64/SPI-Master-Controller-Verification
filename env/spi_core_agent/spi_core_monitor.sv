package spi_core_monitor_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class spi_core_monitor extends uvm_monitor ;
        `uvm_component_utils(spi_core_monitor);

        virtual spi_if vif_cfg; 
        spi_core_sequence_item rsp_seq_item;

        uvm_analysis_port #(spi_core_sequence_item) mon_ap;

        function new (string name = "spi_core_monitor" , uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            mon_ap = new("mon_ap",this);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                rsp_seq_item = spi_core_sequence_item::type_id::create("rsp_seq_item");
                @(negedge vif_cfg.pclk); 
                // spi_core inputs
                rsp_seq_item.presetn        = vif_cfg.presetn;
                rsp_seq_item.tx_empty       = vif_cfg.tx_empty;
                rsp_seq_item.miso           = vif_cfg.miso;
                rsp_seq_item.cfg_en         = vif_cfg.cfg_en;
                rsp_seq_item.cfg_mstr       = vif_cfg.cfg_mstr;
                rsp_seq_item.cfg_lsb_first  = vif_cfg.cfg_lsb_first;
                rsp_seq_item.cfg_loopback   = vif_cfg.cfg_loopback;
                rsp_seq_item.cfg_mode       = vif_cfg.cfg_mode;
                rsp_seq_item.cfg_width      = vif_cfg.cfg_width;
                rsp_seq_item.ss_n           = vif_cfg.ss_n;
                rsp_seq_item.cfg_delay      = vif_cfg.cfg_delay;
                rsp_seq_item.cfg_clk_div    = vif_cfg.cfg_clk_div;
                rsp_seq_item.tx_word        = vif_cfg.tx_word;
                
                // DUT output
                rsp_seq_item.tx_pop                 = vif_cfg.tx_pop;
                rsp_seq_item.rx_push_valid          = vif_cfg.rx_push_valid;
                rsp_seq_item.busy                   = vif_cfg.busy;
                rsp_seq_item.transfer_done_pulse    = vif_cfg.transfer_done_pulse;
                rsp_seq_item.sclk                   = vif_cfg.sclk;
                rsp_seq_item.mosi                   = vif_cfg.mosi;
                rsp_seq_item.rx_push_data           = vif_cfg.rx_push_data;

                // Golden model output
                rsp_seq_item.tx_pop_expected              = vif_cfg.tx_pop_expected;
                rsp_seq_item.rx_push_valid_expected       = vif_cfg.rx_push_valid_expected;
                rsp_seq_item.busy_expected                = vif_cfg.busy_expected;
                rsp_seq_item.transfer_done_pulse_expected = vif_cfg.transfer_done_pulse_expected;
                rsp_seq_item.sclk_expected                = vif_cfg.sclk_expected;
                rsp_seq_item.mosi_expected                = vif_cfg.mosi_expected;
                rsp_seq_item.rx_push_data_expected        = vif_cfg.rx_push_data_expected;
                
                mon_ap.write(rsp_seq_item);
                `uvm_info("run_phase",rsp_seq_item.convert2string_stimulus(),UVM_HIGH)
            end
        endtask   
    endclass
endpackage