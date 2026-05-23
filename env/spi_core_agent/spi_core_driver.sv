package spi_core_driver_pkg ;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class spi_core_driver extends uvm_driver #(spi_core_sequence_item);
      `uvm_component_utils(spi_core_driver)
        virtual spi_if vif_cfg;
        spi_core_sequence_item seq_item;

        function new (string name = "spi_core_driver",uvm_component parent = null);
            super.new(name,parent);            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin 
                seq_item =spi_core_sequence_item::type_id::create("seq_item");
                seq_item_port.get_next_item(seq_item);
                
                vif_cfg.presetn         = seq_item.presetn;
                vif_cfg.tx_empty        = seq_item.tx_empty;
                vif_cfg.miso            = seq_item.miso;
                vif_cfg.cfg_en          = seq_item.cfg_en;
                vif_cfg.cfg_mstr        = seq_item.cfg_mstr;
                vif_cfg.cfg_lsb_first   = seq_item.cfg_lsb_first;
                vif_cfg.cfg_loopback    = seq_item.cfg_loopback;
                vif_cfg.cfg_mode        = seq_item.cfg_mode;
                vif_cfg.cfg_width       = seq_item.cfg_width;
                // vif_cfg.ss_n      = seq_item.ss_n;
                vif_cfg.cfg_delay       = seq_item.cfg_delay;
                vif_cfg.cfg_clk_div     = seq_item.cfg_clk_div;
                vif_cfg.tx_word         = seq_item.tx_word;
                
                @(negedge vif_cfg.pclk);
                seq_item_port.item_done();
                `uvm_info("run_phase",seq_item.convert2string_stimulus(),UVM_HIGH)
            end
        endtask
    endclass
endpackage