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

        // task body ();
        //     repeat(1) begin
        //         seq_item = master_sequence_item::type_id::create("seq_item");
        //         seq_item.constraint_mode(0);

        //         // setting the fixed configuration 
        //         /* control register configuration 
        //         transfer one byte (8 bits)
        //         1 for master operation
        //         transfer one byte (8 bits)
        //         transfer data to slave no loopback
        //         spi mode zero 
        //         no idle*/
        //         // configuiring the bfm 
        //         mode_pkg        = 2'b00;          // {CPOL, CPHA} = 2'boo
        //         lsb_first_pkg   = 1'b0;           // msb is drived first
        //         width_cfg_pkg   = 2'b0;           // data width = 8
        //         miso_data_pkg   = 32'h0000_00f8;  // 1111_1000 we are expecting on the prdata


        //         apb_write(APB_CTRL,    32'h0000_0003);              
        //         apb_write(APB_CLK_DIV, 32'h0000_0000);  // divide /2
        //         apb_write(APB_INT_EN,  32'h0000_000F);  // interrupts are on 
        //         apb_write(APB_SS_CTRL, 32'h0000_0001);  // assert ss[0] LOW

        //         // TX_OV 
        //         // SS_n is high to fill the fifo
        //         // TX_ovf must be asserted  
        //         // pslverr must be asserted 
        //         repeat(20)begin
        //             apb_write(APB_TX_DATA, 32'h0000_00AC);
        //         end

        //         // W1C on the interrupt status register tx_ovf 
        //         // this write should be ignored 
        //         apb_write(APB_INT_STAT, 32'h0000_0004);
        //         apb_write(APB_INT_STAT, 32'h0000_0008);

        //         // reset the module 
        //         start_item(seq_item);
        //         seq_item.presetn = 1'b0;
        //         seq_item.psel    = 1'b0;  
        //         seq_item.penable = 1'b0;
        //         seq_item.pwrite  = 1'b0;
        //         seq_item.paddr   = 8'b0;
        //         seq_item.pwdata  = 32'b0;
        //         // seq_item.miso    = 1'b0;
        //         finish_item(seq_item);

        //         apb_write(APB_CTRL,    32'h0000_0003);              
        //         apb_write(APB_CLK_DIV, 32'h0000_0000);  // divide /2
        //         apb_write(APB_INT_EN,  32'h0000_000F);  // interrupts are on 
                
        //         // RX_empty read                     
        //         // no errors should be generated     
        //         // the returned value should be zero   
        //         apb_read(APB_RX_DATA);


        //         // ============================================================
        //         // SCENARIO 3: Illegal Width Encoding
        //         // Write 2'b11 to width field in CTRL — reserved value
        //         // Expected: transfer ignored or PSLVERR, no hang
        //         // ============================================================
        //         apb_write(APB_CTRL, 32'h0000_0007);      // width = 2'b11 (illegal)
        //         apb_write(APB_SS_CTRL, 32'h0000_0001);
        //         apb_write(APB_TX_DATA, 32'h0000_0011);
        //         // Wait some cycles — no transfer should complete
        //         repeat(10) begin
        //             start_item(seq_item);
        //             seq_item.presetn = 1'b1;
        //             seq_item.psel    = 1'b0;
        //             seq_item.penable = 1'b0;
        //             seq_item.pwrite  = 1'b0;
        //             seq_item.paddr   = 8'b0;
        //             seq_item.pwdata  = 32'b0;
        //             finish_item(seq_item);
        //         end
        //         // Verify busy never asserted or transfer_done never fired
        //         apb_read(APB_STATUS);  // check no transfer completed

        //         // Reset before next scenario
        //         apb_write_reset();

        //         // ============================================================
        //         // SCENARIO 4: Reserved Register Offset Access
        //         // Write/Read to addresses not in the register map
        //         // Expected: PSLVERR asserts, valid registers unaffected
        //         // ============================================================
        //         // Save current CTRL value first
        //         apb_read(APB_CTRL);

        //         // Write to reserved offsets
        //         apb_write(8'hFF, 32'hDEAD_BEEF);  // clearly unmapped
        //         apb_write(8'h50, 32'hCAFE_BABE);  // another unmapped offset
        //         apb_read(8'hFF);                   // read back reserved — expect PSLVERR

        //         // Verify CTRL is untouched
        //         apb_read(APB_CTRL);  // scoreboard checks value unchanged

        //         // ============================================================
        //         // SCENARIO 5: Write to Read-Only Registers
        //         // STATUS and RX_DATA are read-only
        //         // Expected: value unchanged after write attempt
        //         // ============================================================
        //         // Read STATUS before
        //         apb_read(APB_STATUS);

        //         // Attempt write to STATUS
        //         apb_write(APB_STATUS, 32'hFFFF_FFFF);

        //         // Read STATUS after — must be identical
        //         apb_read(APB_STATUS);

        //         // Attempt write to RX_DATA
        //         apb_write(APB_RX_DATA, 32'hDEAD_BEEF);

        //         // Read RX_DATA — must still be 0 (empty)
        //         apb_read(APB_RX_DATA);

        //         // ============================================================
        //         // SCENARIO 6: Write to CTRL While Transfer in Progress
        //         // Expected: in-flight transfer uses latched config, no corruption
        //         // ============================================================
        //         apb_write(APB_CTRL,    32'h0000_0003);  // mode 0, 8-bit, master, en
        //         apb_write(APB_CLK_DIV, 32'h0000_00FF);  // slow clock so we have time
        //         apb_write(APB_SS_CTRL, 32'h0000_0001);
        //         apb_write(APB_TX_DATA, 32'h0000_00A5);

        //         // Immediately write new config mid-transfer
        //         apb_write(APB_CTRL, 32'h0000_0007);  // try to change width mid-flight

        //         // Let transfer complete
        //         repeat(600) begin
        //             start_item(seq_item);
        //             seq_item.presetn = 1'b1;
        //             seq_item.psel    = 1'b0;
        //             seq_item.penable = 1'b0;
        //             seq_item.pwrite  = 1'b0;
        //             seq_item.paddr   = 8'b0;
        //             seq_item.pwdata  = 32'b0;
        //             finish_item(seq_item);
        //         end
        //         // Verify RX data matches original 8-bit config, not corrupted
        //         apb_read(APB_RX_DATA);

        //         // ============================================================
        //         // SCENARIO 7: Disable cfg_en Mid-Transfer
        //         // Expected: FSM returns to IDLE, SCLK returns to CPOL idle,
        //         //           no partial RX push
        //         // ============================================================
        //         apb_write(APB_CTRL,    32'h0000_0003);
        //         apb_write(APB_CLK_DIV, 32'h0000_00FF);  // slow clock
        //         apb_write(APB_SS_CTRL, 32'h0000_0001);
        //         apb_write(APB_TX_DATA, 32'h0000_00A5);

        //         // Wait a few cycles into transfer then disable
        //         repeat(5) begin
        //             start_item(seq_item);
        //             seq_item.presetn = 1'b1;
        //             seq_item.psel    = 1'b0;
        //             seq_item.penable = 1'b0;
        //             finish_item(seq_item);
        //         end

        //         // Clear EN bit
        //         apb_write(APB_CTRL, 32'h0000_0002);  // EN=0

        //         // Verify busy drops and no rx_push_valid fires
        //         repeat(10) begin
        //             start_item(seq_item);
        //             seq_item.presetn = 1'b1;
        //             seq_item.psel    = 1'b0;
        //             seq_item.penable = 1'b0;
        //             finish_item(seq_item);
        //         end
        //         apb_read(APB_STATUS);  // busy must be 0
        //     end              
        // endtask

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