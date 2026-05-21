package div_sequence_pkg;
    import master_shared_pkg::*;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class div_rst_sequence extends uvm_sequence #(master_sequence_item);
    `uvm_object_utils(div_rst_sequence)

        function new(string name = "div_rst_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;

            // Reset
            repeat(3) begin
                seq_item = master_sequence_item::type_id::create("seq_item");
                start_item(seq_item);
                seq_item.presetn = 0;
                seq_item.psel = 0;
                seq_item.penable = 0;
                finish_item(seq_item);
            end
        endtask
    endclass

    class div_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(div_sequence)

        function new(string name = "div_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;
            master_sequence_item cfg_item;
            longint wait_cycles;
            int actual_width;
            //transfer takes pclk=2xwidthx(div+1)
            //busy asserted 1pclk after last sample clk
            
            repeat(10) begin
                cfg_item = master_sequence_item::type_id::create("cfg_item");
                cfg_item.constraint_mode(0);
                cfg_item.modes_crossing_c.constraint_mode(1);

                assert(cfg_item.randomize());
                mode_pkg=cfg_item.mode_r;
                lsb_first_pkg=cfg_item.lsb_first_r;
                width_cfg_pkg=cfg_item.width_cfg_r;
                assert(std::randomize(miso_data_pkg));

                apb_write(APB_CLK_DIV, {16'h0,cfg_item.div_r});

                apb_write(APB_CTRL,{24'h0, cfg_item.width_cfg_r, 1'b0, cfg_item.lsb_first_r, cfg_item.mode_r, 2'b11});

                //assert ss_n
                apb_write(APB_SS_CTRL, {24'h0,cfg_item.ss_n_r});
                //push data 
                apb_write(APB_TX_DATA, cfg_item.data_r);

                actual_width = (cfg_item.width_cfg_r == 2'b10) ? 32 : (cfg_item.width_cfg_r == 2'b01) ? 16 : 8;
                wait_cycles=longint'(((1+cfg_item.div_r)*2*longint'(actual_width)))+2;
                repeat(wait_cycles) begin
                    seq_item = master_sequence_item::type_id::create("seq_item");
                    start_item(seq_item);
                    seq_item.presetn = 1;
                    seq_item.psel    = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                apb_write(APB_SS_CTRL , 32'h0000_0000);
            end
        endtask

        task automatic apb_write(input [7:0] addr, input [31:0] data);
            master_sequence_item seq_item;
            // Setup Phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.presetn =1'b1;
            seq_item.psel    = 1'b1;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b1;
            seq_item.paddr   = addr;
            seq_item.pwdata  = data;
            finish_item(seq_item);
            // Access Phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.presetn=1'b1;
            seq_item.psel    = 1'b1;
            seq_item.pwrite  = 1'b1;
            seq_item.paddr   = addr;
            seq_item.pwdata  = data;
            seq_item.penable = 1'b1;
            finish_item(seq_item);
            // idle phase
            seq_item = master_sequence_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.presetn =1'b1;
            seq_item.psel    = 1'b0;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b0;
            finish_item(seq_item);
        endtask
    endclass
endpackage
