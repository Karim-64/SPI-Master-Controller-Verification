package master_driver_pkg ;
    import uvm_pkg::*;
    // import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    class master_driver extends uvm_driver #(master_sequence_item);
      `uvm_component_utils(master_driver)
        virtual master_if vif_cfg;
        master_sequence_item seq_item;

        function new (string name = "master_driver",uvm_component parent = null);
            super.new(name,parent);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin 
                seq_item =master_sequence_item::type_id::create("seq_item");
                seq_item_port.get_next_item(seq_item);
                vif_cfg.presetn = seq_item.presetn;
                vif_cfg.psel = seq_item.psel;
                vif_cfg.penable = seq_item.penable;
                vif_cfg.pwrite = seq_item.pwrite;
                vif_cfg.paddr = seq_item.paddr;
                vif_cfg.pwdata = seq_item.pwdata;
                // vif_cfg.miso = seq_item.miso;
                @(negedge vif_cfg.pclk);
                seq_item_port.item_done();
                `uvm_info("run_phase",seq_item.convert2string_stimulus(),UVM_HIGH)
            end
        endtask

        // task automatic apb_write(input [7:0] addr, input [31:0] data);  
        //     @(negedge vif_cfg.PCLK);
        //     apb.cb_master.psel    <= 1'b1;
        //     apb.cb_master.penable <= 1'b0;
        //     apb.cb_master.pwrite  <= 1'b1;
        //     apb.cb_master.paddr   <= addr;
        //     apb.cb_master.pwdata  <= data;
        //     @(apb.cb_master);
        //     apb.cb_master.penable <= 1'b1;
        //     do @(apb.cb_master); while (!apb.cb_master.pready);
        //     apb.cb_master.psel    <= 1'b0;
        //     apb.cb_master.penable <= 1'b0;
        //     apb.cb_master.pwrite  <= 1'b0;
        // endtask    

        // task automatic apb_read(input [7:0] addr, output [31:0] data);
        //     @(apb.cb_master);
        //     apb.cb_master.psel    <= 1'b1;
        //     apb.cb_master.penable <= 1'b0;
        //     apb.cb_master.pwrite  <= 1'b0;
        //     apb.cb_master.paddr   <= addr;
        //     @(apb.cb_master);
        //     apb.cb_master.penable <= 1'b1;
        //     do @(apb.cb_master); while (!apb.cb_master.pready);
        //     data = apb.cb_master.prdata;
        //     apb.cb_master.psel    <= 1'b0;
        //     apb.cb_master.penable <= 1'b0;
        // endtask
    endclass
endpackage