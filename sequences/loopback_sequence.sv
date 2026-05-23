package loopback_sequence_pkg;
    import uvm_pkg::*;
    import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    // reset sequence
    class loopback_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(loopback_rst_sequence)
        master_sequence_item seq_item;

        function new(string name = "loopback_rst_sequence");
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
                    seq_item.miso    = 1'b0;
                finish_item(seq_item);
            end
        endtask
    endclass

       // directed sequence
    class loopback_directed_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(loopback_directed_sequence)
        master_sequence_item seq_item;
        int counter =0;
        function new(string name = "loopback_directed_sequence");
            super.new(name);
        endfunction

        task body();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // configuiring the bfm 
            mode_pkg        = 2'b00; 
            lsb_first_pkg   = 1'b0;
            width_cfg_pkg   = 2'b0;
            miso_data_pkg   = 32'h0000_00f8;

            apb_write(APB_CTRL,    32'h0000_00023); // loopback on              
            apb_write(APB_CLK_DIV, 32'h0000_0000);
            apb_write(APB_INT_EN,  32'h0000_000F);
            apb_write(APB_SS_CTRL, 32'h0000_0001);  // assert ss[0] LOW
            apb_write(APB_TX_DATA, 32'h0000_005A);

            // wait until the write happens
            repeat(16) begin
                start_item(seq_item);
                counter++;
                if(counter==15) begin
                    seq_item.presetn = 1'b1;
                    seq_item.psel    = 1'b1;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b1;
                    seq_item.paddr   = APB_SS_CTRL;
                    seq_item.pwdata  = 32'h0000_0000;
                end
                else if(counter == 16)   seq_item.penable = 1'b1;
                else begin
                    seq_item.psel    = 1'b0;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b0;
                end
                finish_item(seq_item);
            end

            apb_write(APB_SS_CTRL,32'h0000_0000);              


            apb_write(APB_CTRL,32'h0000_0003);   // loopback off           
            apb_write(APB_CLK_DIV, 32'h0000_0000);  
            apb_write(APB_INT_EN,  32'h0000_000F);
            apb_write(APB_SS_CTRL, 32'h0000_0001);  
            apb_write(APB_TX_DATA, 32'h0000_005A);
             
             repeat(16) begin
                start_item(seq_item);
                counter++;
                if(counter==15) begin
                    seq_item.presetn = 1'b1;
                    seq_item.psel    = 1'b1;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b1;
                    seq_item.paddr   = APB_SS_CTRL;
                    seq_item.pwdata  = 32'h0000_0000;
                end
                else if(counter == 16)   seq_item.penable = 1'b1;
                else begin
                    seq_item.psel    = 1'b0;
                    seq_item.penable = 1'b0;
                    seq_item.pwrite  = 1'b0;
                end
                finish_item(seq_item);
            end

            apb_write(APB_SS_CTRL,32'h0000_0000);    
    
        endtask

        // write task 
        task automatic apb_write(input [7:0] addr, input [31:0] data);
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // SETUP phase
            start_item(seq_item);
                seq_item.presetn = 1'b1;
                seq_item.psel    = 1'b1;
                seq_item.penable = 1'b0;
                seq_item.pwrite  = 1'b1;
                seq_item.paddr   = addr;
                seq_item.pwdata  = data;
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


    // loopback sequence
    class loopback_ctrl_randomized_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(loopback_ctrl_randomized_sequence)

        master_sequence_item seq_item;
        bit [15:0] current_div;
        bit [1:0]  current_width;
        int        wait_cycles = 0;
        int        counter = 0;

        function new(string name = "loopback_ctrl_randomized_sequence");
            super.new(name);
        endfunction

        // calculate wait cycles 
        function int calc_wait_cycles(bit [1:0] width, bit [15:0] div);
            int bits;
            case(width)
                2'b00:   bits = 8;
                2'b01:   bits = 16;
                2'b10:   bits = 32;
                default: bits = 8;
            endcase
            return (bits * 2 * (div + 1));
        endfunction

        task body();
            repeat(50) begin
                seq_item = master_sequence_item::type_id::create("seq_item");
                seq_item.constraint_mode(0);
                seq_item.main_c.constraint_mode(1);
                //write CTRL
                seq_item.loopback_ctrl_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {presetn == 1;pwrite  == 1;});
                    finish_item(seq_item);
                end
                // save width for wait cycle calculation
                current_width = seq_item.pwdata[7:6];
                seq_item.loopback_ctrl_c.constraint_mode(0);

                // write clk_div 
                seq_item.clk_div_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {presetn == 1;pwrite  == 1;});
                    finish_item(seq_item);
                end
                // save div for wait cycle calculation
                current_div = seq_item.pwdata[15:0];
                seq_item.clk_div_c.constraint_mode(0);

                // write ss_ctrl 
                seq_item.ss_ctrl_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {presetn == 1;pwrite  == 1;});
                    finish_item(seq_item);
                end
                seq_item.ss_ctrl_c.constraint_mode(0);

                // write tx_data 
                seq_item.loopback_tx_data_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {presetn == 1;pwrite  == 1;});
                    finish_item(seq_item);
                end
                seq_item.loopback_tx_data_c.constraint_mode(0);


                wait_cycles = calc_wait_cycles(current_width, current_div);
                counter =0;
                repeat(wait_cycles) begin
                    start_item(seq_item);
                        counter ++;
                         if(counter == wait_cycles-1) begin
                             seq_item.presetn = 1'b1;
                             seq_item.psel    = 1'b1;
                             seq_item.penable = 1'b0;
                             seq_item.pwrite  = 1'b1;
                             seq_item.paddr   = APB_SS_CTRL;
                             seq_item.pwdata  = 32'h0000_0000;
                         end
                         else if(counter == wait_cycles)begin
                            seq_item.pwrite  = 1'b1;
                            seq_item.penable = 1'b1;
                            seq_item.paddr   = APB_SS_CTRL;
                            seq_item.pwdata  = 32'h0000_0000;
                         end
                         else begin
                             seq_item.psel    = 1'b0;
                             seq_item.penable = 1'b0;
                             seq_item.pwrite  = 1'b0;
                            seq_item.paddr   = APB_SS_CTRL;
                            seq_item.pwdata  = 32'h0000_0000;
                         end
                    finish_item(seq_item);
                end
            end
        endtask


        //  write task 
        task automatic apb_write(input [7:0] addr, input [31:0] data);
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // SETUP phase
            start_item(seq_item);
                seq_item.presetn = 1'b1;
                seq_item.psel    = 1'b1;
                seq_item.penable = 1'b0;
                seq_item.pwrite  = 1'b1;
                seq_item.paddr   = addr;
                seq_item.pwdata  = data;
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