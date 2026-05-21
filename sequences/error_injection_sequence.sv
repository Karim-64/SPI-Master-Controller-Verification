package error_enjection_sequence_pkg;
    import uvm_pkg::*;
    import master_shared_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class error_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(error_rst_sequence)
        master_sequence_item seq_item;

        function new(string name = "error_rst_sequence");
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


    class error_enjection_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(error_enjection_sequence)
        int counter = 0;

        master_sequence_item seq_item ;

        function new(string name = "error_enjection_sequence");
            super.new(name);
        endfunction

        task body();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);

            // SCENARIO 1: TX FIFO Overflow 
            // Expected:
            // STATUS[5]   (TX_OVF) = 1
            // INT_STAT[2] (TX_OVF) = 1
            // IRQ asserts if INT_EN[2] = 1

            apb_write(APB_CTRL,    32'h0000_0003); // EN=1, MSTR=1, Mode0, 8-bit
            apb_write(APB_CLK_DIV, 32'h0000_0000);
            apb_write(APB_INT_EN,  32'h0000_0004); // enable TX_OVF interrupt only
            // SS_CTRL left at 0 — SS_n high

            // Fill FIFO to capacity (8 entries — R11)
            repeat(8) begin
                apb_write(APB_TX_DATA, 32'h0000_00AC);
            end 

            // Verify TX_FULL asserted (STATUS[1] = 1, STATUS[2] = 0)
            apb_read(APB_STATUS); 

            // TX_OVF must fire
            apb_write(APB_TX_DATA, 32'h0000_00FF);

            // Verify INT_STAT
            apb_read(APB_INT_STAT); 

            // W1C: clear TX_OVF in INT_STAT
            apb_write(APB_INT_STAT, 32'h0000_0004);

            // Verify INT_STAT cleared
            apb_read(APB_INT_STAT); // expect 32'h0000_0000

            ///////////////////////////
            // RESET between scenarios
            apb_write_reset();
            ///////////////////////////

            apb_write(APB_CTRL,    32'h0000_0003);
            apb_write(APB_CLK_DIV, 32'h0000_0000);
            apb_write(APB_INT_EN,  32'h0000_0000); // all interrupts masked

            // SCENARIO 2: RX FIFO Empty Read 
            // Expected:
            // - Returns 0
            // - RX_OVF is NOT set (this is NOT an error per spec)
            // - PSLVERR stays 0 (always 0 per R22)

            apb_read(APB_RX_DATA);  // expect PRDATA = 32'h0000_0000

            // Verify RX_OVF not set
            apb_read(APB_STATUS);   // expect bit6(RX_OVF)=0, bit4(RX_EMPTY)=1

            apb_read(APB_INT_STAT); // expect 32'h0000_0000 — no interrupt

            // SCENARIO 3: RX FIFO Overflow will be asserted using a loopback test
            // Expected:
            //   - 9th received word discarded
            //   - STATUS[6] (RX_OVF) = 1
            //   - INT_STAT[3] (RX_OVF) = 1
            apb_write(APB_CTRL,    32'h0000_0023); // EN=1,MSTR=1,LOOPBACK=1,Mode0,8-bit
            apb_write(APB_CLK_DIV, 32'h0000_0000);
            apb_write(APB_INT_EN,  32'h0000_0008); // RX_OVF interrupt enabled
            apb_write(APB_SS_CTRL, 32'h0000_0001); // assert SS_n[0]

            // Push 9 words — loopback means each completes and pushes to RX FIFO
            // 8th fills RX FIFO, 9th causes RX_OVF
            repeat(9) begin
                apb_write(APB_TX_DATA, 32'h0000_00AC);
            end

            repeat(8) begin
                wait_busy_clear();
            end

            apb_read(APB_STATUS);   // expect bit6(RX_OVF)=1, bit3(RX_FULL)=1
            apb_read(APB_INT_STAT); // expect bit3=1 (RX_OVF)

            // W1C clear RX_OVF
            apb_write(APB_INT_STAT, 32'h0000_0008);

            // SCENARIO 5: Reserved Offset Access (R23)
            // Reads return 0, writes ignored
            apb_write_reset();
            apb_write(APB_CTRL, 32'h0000_0003); // set a known CTRL value

            // Write into reserved addresses
            apb_write(8'h24, 32'hAAAA_BBBB);   // first reserved offset
            apb_write(8'hFF, 32'hCCCC_DDDD);   // deep reserved offset
            apb_read(8'h24);                   // expect 32'h0000_0000
            apb_read(8'hFF);                   // expect 32'h0000_0000

            // CTRL must be unaffected
            apb_read(APB_CTRL);  

            // SCENARIO 6: Write to Read-Only Registers 
            // STATUS and RX_DATA are read-only — writes ignored
            apb_write(APB_STATUS,  32'hFFFF_FFFF); // must be ignored
            apb_read(APB_STATUS);                  // expect reset-like value, not 0xFFFFFFFF

            apb_write(APB_RX_DATA, 32'hAAAA_BBBB); // must be ignored
            apb_read(APB_RX_DATA);                 // expect 32'h0000_0000 

            // SCENARIO 7: TX_DATA write while EN=0 
            // Write is ignored
            apb_write_reset();
            apb_write(APB_CTRL, 32'h0000_0000); // EN=0

            apb_write(APB_TX_DATA, 32'h0000_00AA); // must be ignored
            apb_read(APB_STATUS); // TX_EMPTY must still be 1 — nothing pushed

            // SCENARIO 8: CTRL.EN 1->0 flushes FIFOs 
            // Fill TX FIFO then clear EN —> FIFOs must be flushed
            apb_write(APB_CTRL, 32'h0000_0003); // EN=1
            repeat(4) begin
                apb_write(APB_TX_DATA, 32'h0000_00BB);
            end
            apb_read(APB_STATUS); // TX_EMPTY=0, some entries present

            // Clear EN — must flush TX and RX FIFOs
            apb_write(APB_CTRL, 32'h0000_0002); // EN=0

            apb_read(APB_STATUS); // expect TX_EMPTY=1, RX_EMPTY=1
        endtask

        task automatic wait_busy_clear();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            repeat(17) begin
                start_item(seq_item);
                seq_item.presetn = 1'b1;
                seq_item.psel    = 1'b0;
                seq_item.penable = 1'b0;
                seq_item.pwrite  = 1'b0;
                seq_item.paddr   = 8'b0;
                seq_item.pwdata  = 32'b0;
                finish_item(seq_item);
            end
        endtask

        task automatic apb_write_reset();
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            start_item(seq_item);
            seq_item.presetn = 1'b0;
            seq_item.psel    = 1'b0;
            seq_item.penable = 1'b0;
            seq_item.pwrite  = 1'b0;
            seq_item.paddr   = 8'b0;
            seq_item.pwdata  = 32'b0;
            finish_item(seq_item);

            start_item(seq_item);
            seq_item.presetn = 1'b1;
            finish_item(seq_item);
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