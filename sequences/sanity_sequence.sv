package sanity_sequence_pkg;
    import uvm_pkg::*;
    import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"
    bit [31:0] rd;
    class sanity_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(sanity_rst_sequence)
        master_sequence_item seq_item;

        function new(string name = "sanity_rst_sequence");
            super.new(name);
        endfunction

        task body();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            repeat(5) begin
                start_item(seq_item);
                    seq_item.presetn = 1'b0;
                    seq_item.psel    = 1'b0;  
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b0;
                    seq_item.paddr   = 8'b0;
                    seq_item.pwdata  = 32'b0;
                finish_item(seq_item);
            end
        endtask
    endclass


    class sanity_ctrl_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(sanity_ctrl_sequence)
        int counter = 0;

        master_sequence_item seq_item ;

        function new(string name = "sanity_ctrl_sequence");
            super.new(name);
        endfunction

        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // configuiring the bfm 
            mode_pkg        = 2'b00;          // {CPOL, CPHA} = 2'boo
            lsb_first_pkg   = 1'b0;           // msb is drived first
            width_cfg_pkg   = 2'b0;           // data width = 8
            miso_data_pkg   = 32'h0000_00f8;  // 1111_1000 we are expecting on the prdata

            /* control register configuration 
            transfer one byte (8 bits)
            1 for master operation
            transfer one byte (8 bits)
            transfer data to slave no loopback
            spi mode zero 
            no idle*/
            apb_write(APB_CTRL,    32'h0000_0003);              
            apb_write(APB_CLK_DIV, 32'h0000_0000);  // divide /2
            apb_write(APB_INT_EN,  32'h0000_000F);  // interrupts are on 
            apb_write(APB_TX_DATA, 32'h0000_005A);  // drive this data to the bfm 
            apb_write(APB_SS_CTRL, 32'h0000_0001);  // assert ss[0] LOW

            // Wait until the write happens
            // note the number of clock cycles required = width of the word * (DIV)
            // here 16 = 8 bits * (DIV = 2)
            repeat(16) begin
                start_item(seq_item);
                counter++;
                finish_item(seq_item);
            end

            apb_write(APB_SS_CTRL,  32'h0000_0000);  // deassert the SS_n
            apb_read(APB_RX_DATA);                   // reading the value from the fifo 
        endtask
    

        task automatic apb_write(input [7:0] addr, input [31:0] data);
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // Setup Phase
            start_item(seq_item);
            seq_item.presetn = 1'b1;
            seq_item.psel    = 1'b1;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b1;
            seq_item.paddr   = addr;
            seq_item.pwdata  = data;
            finish_item(seq_item);

            // Access Phase
            start_item(seq_item);
            seq_item.penable = 1'b1;
            finish_item(seq_item);
            
            // idle phase
            start_item(seq_item);
            seq_item.psel    = 1'b0;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b0;
            finish_item(seq_item);
        endtask

        task automatic apb_read(input [7:0] addr);
                seq_item = master_sequence_item::type_id::create("seq_item");
                seq_item.constraint_mode(0);

                // SETUP phase
                start_item(seq_item);
                    seq_item.presetn = 1'b1;
                    seq_item.psel    = 1'b1;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b0;
                    seq_item.paddr   = addr;
                finish_item(seq_item);

                // ACCESS phase
                start_item(seq_item);
                    seq_item.penable = 1'b1;
                finish_item(seq_item);

                // IDLE phase
                start_item(seq_item);
                    seq_item.psel    = 1'b0;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b0;
                finish_item(seq_item);
        endtask
    endclass
endpackage