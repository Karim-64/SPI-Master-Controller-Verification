package apb_driver_pkg ;
    import uvm_pkg::*;
    // import apb_shared_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class apb_driver extends uvm_driver #(apb_sequence_item);
      `uvm_component_utils(apb_driver)
        virtual apb_if vif_cfg;
        apb_sequence_item seq_item;

        function new (string name = "apb_driver",uvm_component parent = null);
            super.new(name,parent);            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin 
                seq_item =apb_sequence_item::type_id::create("seq_item");
                seq_item_port.get_next_item(seq_item);
                    vif_cfg.presetn = seq_item.presetn;
                    vif_cfg.psel = seq_item.psel;
                    vif_cfg.penable = seq_item.penable;
                    vif_cfg.pwrite = seq_item.pwrite;
                    vif_cfg.paddr = seq_item.paddr;
                    vif_cfg.pwdata = seq_item.pwdata;
                    vif_cfg.tx_pop = seq_item.tx_pop;
                    vif_cfg.rx_push_valid = seq_item.rx_push_valid;
                    vif_cfg.rx_push_data = seq_item.rx_push_data;
                    vif_cfg.busy_in = seq_item.busy_in;
                    vif_cfg.transfer_done_pulse = seq_item.transfer_done_pulse;
                    @(negedge vif_cfg.PCLK);
                seq_item_port.item_done();
                `uvm_info("run_phase",seq_item.convert2string_stimulus(),UVM_HIGH)
            end
        endtask
    endclass
endpackage