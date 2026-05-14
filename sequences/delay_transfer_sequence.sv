package delay_transfer_sequence_pkg;
    import uvm_pkg::*;
    import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    // reset sequence
    class delay_transfer_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(delay_transfer_rst_sequence)
        master_sequence_item seq_item;

        function new(string name = "delay_transfer_rst_sequence");
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
    class delay_transfer_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(delay_transfer_sequence)
        master_sequence_item seq_item;
        int counter =0; 
        int delay[]= '{0,1,2,4,8,16,32,255};

        function new(string name = "delay_transfer_sequence");
            super.new(name);
        endfunction

task body();
        seq_item = master_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);

        // configuiring the bfm 
        mode_pkg        = 2'b00; 
        lsb_first_pkg   = 1'b0;
        width_cfg_pkg   = 2'b0;
        miso_data_pkg   = 32'h0000_00f8;  //1111_0000

        // configuratio
        apb_write(APB_CTRL,    32'h0000_0023);
        apb_write(APB_CLK_DIV, 32'h0000_0000); 
        apb_write(APB_SS_CTRL, 32'h0000_0001);

        // test delay  
        foreach (delay[i]) begin
            apb_write(APB_DELAY, delay[i]);
            // byte 1 transfers first yhen byte 2 transfers after the delay
            apb_write(APB_TX_DATA, 32'h0000_00f0); 
            apb_write(APB_TX_DATA, 32'h0000_000f);

            // wait transfers to complete
            begin
                repeat(16) begin    // 16 because i test only 8 bit with zero div 
                    start_item(seq_item);
                        seq_item.presetn = 1'b1;
                        seq_item.psel    = 1'b0;
                        seq_item.penable = 1'b0;
                        seq_item.pwrite  = 1'b0;
                    finish_item(seq_item);
                end
            end

            apb_read(APB_RX_DATA);
            apb_read(APB_RX_DATA);
        end
            // deassert SS_n 
            apb_write(APB_SS_CTRL, 32'h0000_0000);
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


        // read task
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