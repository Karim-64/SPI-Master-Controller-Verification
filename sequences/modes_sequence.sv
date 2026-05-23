package modes_sequence_pkg;
    import master_shared_pkg::*;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class modes_rst_sequence extends uvm_sequence #(master_sequence_item);
    `uvm_object_utils(modes_rst_sequence)

        function new(string name = "modes_rst_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;

            // Reset
            seq_item = master_sequence_item::type_id::create("seq_item");
            repeat(3) begin
                start_item(seq_item);
                seq_item.presetn = 0;
                seq_item.psel = 0;
                seq_item.penable = 0;
                finish_item(seq_item);
            end
        endtask
    endclass

    class modes_crossing_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(modes_crossing_sequence)

        function new(string name = "modes_crossing_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;
            master_sequence_item cfg_item;
            int wait_cycles;
            
            apb_write(this, APB_CLK_DIV, 32'h0);
            repeat(30) begin
                cfg_item = master_sequence_item::type_id::create("cfg_item");
                cfg_item.constraint_mode(0);
                cfg_item.modes_crossing_c.constraint_mode(1);

                assert(cfg_item.randomize());
                mode_pkg=cfg_item.mode_r;
                lsb_first_pkg=cfg_item.lsb_first_r;
                width_cfg_pkg=cfg_item.width_cfg_r;
                assert(std::randomize(miso_data_pkg));

                apb_write(this, APB_CTRL,{24'h0, cfg_item.width_cfg_r, 1'b0, cfg_item.lsb_first_r, cfg_item.mode_r, 2'b11});

                //assert ss_n
                apb_write(this, APB_SS_CTRL, {24'h0,cfg_item.ss_n_r});
                //push data 
                apb_write(this, APB_TX_DATA, cfg_item.data_r);

                if (cfg_item.width_cfg_r == 2'b10)      wait_cycles = 66; 
                else if (cfg_item.width_cfg_r == 2'b01) wait_cycles = 34; 
                else                                    wait_cycles = 18; 

                repeat(wait_cycles) begin
                    seq_item = master_sequence_item::type_id::create("seq_item");
                    start_item(seq_item);
                    seq_item.presetn =1'b1;
                    seq_item.psel    = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                apb_write(this, APB_SS_CTRL ,  32'h0000_0000);   // deassert the SS_n
            end
        endtask
    endclass

    class no_SS_sequence extends uvm_sequence #(master_sequence_item);
    `uvm_object_utils(no_SS_sequence)

        function new(string name = "no_SS_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;
            master_sequence_item cfg_item;
            int wait_cycles;

            // No slave selected
            repeat(3) begin
                cfg_item = master_sequence_item::type_id::create("cfg_item");
                cfg_item.constraint_mode(0);
                cfg_item.modes_crossing_c.constraint_mode(1);

                assert(cfg_item.randomize());
                mode_pkg=cfg_item.mode_r;
                lsb_first_pkg=cfg_item.lsb_first_r;
                width_cfg_pkg=cfg_item.width_cfg_r;
                assert(std::randomize(miso_data_pkg));

                apb_write(this, APB_CTRL,{24'h0, cfg_item.width_cfg_r, 1'b0, cfg_item.lsb_first_r, cfg_item.mode_r, 2'b11});

                apb_write(this, APB_SS_CTRL , 32'h0000_00F0);
                //push data 
                apb_write(this, APB_TX_DATA, cfg_item.data_r);


                if (cfg_item.width_cfg_r == 2'b10)      wait_cycles = 66; 
                else if (cfg_item.width_cfg_r == 2'b01) wait_cycles = 34; 
                else                                    wait_cycles = 18; 

                repeat(wait_cycles) begin
                    seq_item = master_sequence_item::type_id::create("seq_item");
                    start_item(seq_item);
                    seq_item.presetn =1'b1;
                    seq_item.psel    = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end
            end
        endtask
    endclass

        task automatic apb_write(uvm_sequence_base seq, input [7:0] addr, input [31:0] data);
            master_sequence_item seq_item;
            // Setup Phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq.start_item(seq_item);
            seq_item.presetn=1'b1;
            seq_item.psel    = 1'b1;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b1;
            seq_item.paddr   = addr;
            seq_item.pwdata  = data;
            seq.finish_item(seq_item);
            // Access Phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq.start_item(seq_item);
            seq_item.presetn=1'b1;
            seq_item.psel    = 1'b1;
            seq_item.pwrite  = 1'b1;
            seq_item.paddr   = addr;
            seq_item.pwdata  = data;
            seq_item.penable = 1'b1;
            seq.finish_item(seq_item);
            // idle phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq.start_item(seq_item);
            seq_item.presetn=1'b1;
            seq_item.psel    = 1'b0;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b0;
            seq.finish_item(seq_item);
        endtask
endpackage