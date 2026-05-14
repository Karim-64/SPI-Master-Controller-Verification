package master_fifo_stress_sequence_pkg;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class master_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(master_rst_sequence)
        master_sequence_item req;

        function new(string name = "master_rst_sequence");
            super.new(name);
        endfunction

        task body();
            req = master_sequence_item::type_id::create("req");
            repeat(5) begin
                start_item(req);
                    req.presetn = 0;
                finish_item(req);
            end
        endtask
    endclass

    class fifo_stress_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(fifo_stress_sequence)

        master_sequence_item seq_item;

        function new(string name = "fifo_stress_sequence");
            super.new(name);
        endfunction

        task body ();
            seq_item = master_sequence_item::type_id::create("seq_item");
            // disable all constraints; only enable what we need per phase
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);

            // ======================= TX Full Test =============================
            // ==============================================================
            // Configure CLK_DIV
            // ==============================================================
            seq_item.clk_div_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn    == 1;
                        pwrite     == 1;
                        pwdata[15:0] == 16'd1;   // clk_div = 1
                    }) else `uvm_fatal("RAND", "clk_div_c randomize failed");
                finish_item(seq_item);
            end
            seq_item.clk_div_c.constraint_mode(0);

            // ==============================================================
            // Configure CTRL: cfg_en=1, cfg_mstr=0, width=8-bit
            // cfg_mstr=0 keeps tx_pop de-asserted → FIFO won't drain
            // ==============================================================
            seq_item.ctrl_mstr_off_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn      == 1;
                        pwrite       == 1;
                        pwdata[7:6]  == 2'b00;   // 8-bit width
                    }) else `uvm_fatal("RAND", "ctrl_mstr_off_c randomize failed");
                finish_item(seq_item);
            end
            seq_item.ctrl_mstr_off_c.constraint_mode(0);

            // ==============================================================
            // Configure SS_CTRL: select slave-0
            // PWDATA[7:4]=ss_val=4'b0000, PWDATA[3:0]=ss_en=4'b0001
            // SS_n[0] = ~1|0 = 0  (slave-0 driven low for later pop phase)
            // ==============================================================
            seq_item.ss_ctrl_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn      == 1;
                        pwrite       == 1;
                        pwdata[7:0]  == 8'b0000_0001;  // ss_val=0, ss_en[0]=1
                    }) else `uvm_fatal("RAND", "ss_ctrl_c (setup) randomize failed");
                finish_item(seq_item);
            end
            seq_item.ss_ctrl_c.constraint_mode(0);

            // ==============================================================
            // Write TX_DATA 8 times to FILL the FIFO
            // No pop occurs because cfg_mstr = 0
            // ==============================================================
            repeat(8) begin
                seq_item.TX_FULL_OVF_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize())
                            else `uvm_fatal("RAND", "TX fill randomize failed");
                    finish_item(seq_item);
                end
                seq_item.TX_FULL_OVF_c.constraint_mode(0);
            end

            // ==============================================================
            // Read STATUS register → TX_FULL (bit[1]) should be 1
            // ==============================================================
            seq_item.status_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "status read (TX_FULL) randomize failed");
                finish_item(seq_item);
            end
            seq_item.status_read_c.constraint_mode(0);

            // ======================= TX OVF Test ==============================
            // ==============================================================
            // Write one MORE element to TX_DATA → OVERFLOW
            // ==============================================================
            seq_item.TX_FULL_OVF_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "TX overflow randomize failed");
                finish_item(seq_item);
            end
            seq_item.TX_FULL_OVF_c.constraint_mode(0);

            // ==============================================================
            // Read STATUS register → TX_OVF (bit[5]) should be 1
            // ==============================================================
            seq_item.status_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "status read (TX_OVF) randomize failed");
                finish_item(seq_item);
            end
            seq_item.status_read_c.constraint_mode(0);
            
            // ======================= Merged TX EMPTY & RX FULL Test ===========
            // ==============================================================
            // Enable pops: Write CTRL with cfg_en=1, cfg_mstr=1
            // ==============================================================
            seq_item.ctrl_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn     == 1;
                        pwrite      == 1;
                        pwdata[0]   == 1;       // cfg_en   = 1
                        pwdata[1]   == 1;       // cfg_mstr = 1  (redundant with ctrl_c but explicit)
                        pwdata[7:6] == 2'b00;   // 8-bit width
                    }) else `uvm_fatal("RAND", "ctrl_c (enable master) randomize failed");
                finish_item(seq_item);
            end
            seq_item.ctrl_c.constraint_mode(0);

            // ==============================================================
            // Wait for FIFO to drain (all 8 elements transferred)
            // 8-bit transfers, clk_div=1:
            //   half_period = clk_div+1 = 2 PCLK cycles
            //   1 transfer  = 8 bits × 2 edges × 2 cycles + 2 = 34 PCLK
            // ==============================================================
            repeat(272) begin
                start_item(seq_item);
                finish_item(seq_item);
            end

            // ==============================================================
            // Disable master (cfg_mstr=0) to freeze state
            // Keeps cfg_en=1 so the RX FIFO state is preserved.
            // ctrl_mstr_off_c: PADDR=0x00, PWRITE=1, pwdata[1]=0
            // ==============================================================
            seq_item.ctrl_mstr_off_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn      == 1;
                        pwrite       == 1;
                        pwdata[7:6]  == 2'b00;   // 8-bit width
                    }) else `uvm_fatal("RAND", "ctrl_mstr_off_c (stop master) randomize failed");
                finish_item(seq_item);
            end
            seq_item.ctrl_mstr_off_c.constraint_mode(0);

            // ==============================================================
            // Read STATUS register → TX_EMPTY (bit[2])=1 AND RX_FULL (bit[3])=1
            // After all 8 elements are popped and transmitted,
            // tx_count==0 → tx_empty_w=1 → STATUS[2]=1
            // rx_count==8 → rx_full_w=1  → STATUS[3]=1
            // ==============================================================
            seq_item.status_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "status read (TX_EMPTY & RX_FULL) randomize failed");
                finish_item(seq_item);
            end
            seq_item.status_read_c.constraint_mode(0);

            // ======================= RX OVF Test ==============================
            // ==============================================================
            // Re-enable master (cfg_mstr=1) and push one more TX
            // RX FIFO is now full (rx_count==8). When the SPI core
            // ==============================================================
            seq_item.ctrl_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn     == 1;
                        pwrite      == 1;
                        pwdata[0]   == 1;       // cfg_en   = 1
                        pwdata[1]   == 1;       // cfg_mstr = 1
                        pwdata[7:6] == 2'b00;   // 8-bit width
                    }) else `uvm_fatal("RAND", "ctrl_c (RX OVF: enable master) randomize failed");
                finish_item(seq_item);
            end
            seq_item.ctrl_c.constraint_mode(0);

            // Write one word to TX to trigger the overflow transfer
            seq_item.TX_FULL_OVF_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "TX write (RX OVF trigger) randomize failed");
                finish_item(seq_item);
            end
            seq_item.TX_FULL_OVF_c.constraint_mode(0);

            // ==============================================================
            // Wait for the overflow transfer to complete
            // 1 transfer ≈ 34 PCLK
            // ==============================================================
            repeat(34) begin
                start_item(seq_item);
                finish_item(seq_item);
            end

            // ==============================================================
            // Read STATUS register → RX_OVF (bit[6]) should be 1
            // RX_FULL (bit[3]) remains 1; overflow word was dropped.
            // ==============================================================
            seq_item.status_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "status read (RX_OVF) randomize failed");
                finish_item(seq_item);
            end
            seq_item.status_read_c.constraint_mode(0);

            // ======================= RX EMPTY Test =============================
            // ==============================================================
            // Disable master so no new transfers start
            // ctrl_mstr_off_c: PADDR=0x00, PWRITE=1, pwdata[1]=0
            // ==============================================================
            seq_item.ctrl_mstr_off_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize() with {
                        presetn      == 1;
                        pwrite       == 1;
                        pwdata[7:6]  == 2'b00;   // 8-bit width
                    }) else `uvm_fatal("RAND", "ctrl_mstr_off_c (RX empty: stop master) randomize failed");
                finish_item(seq_item);
            end
            seq_item.ctrl_mstr_off_c.constraint_mode(0);

            // ==============================================================
            // Read RX_DATA 8 times to drain the RX FIFO + 1 additional read to check the empty output
            // Each APB read to PADDR=0x0C triggers rx_pop_this_cycle=1
            // (apb_regfile.sv line 175) → rx_rp increments each cycle.
            // After 8 reads: rx_count==0 → rx_empty_w=1.
            // ==============================================================
            repeat(9) begin
                seq_item.RX_EMPTY_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                        assert (seq_item.randomize())
                            else `uvm_fatal("RAND", "RX_DATA pop randomize failed");
                    finish_item(seq_item);
                end
                seq_item.RX_EMPTY_c.constraint_mode(0);
            end

            // ==============================================================
            //Read STATUS register → RX_EMPTY (bit[4]) should be 1
            //After all 8 entries are popped, rx_count==0 → rx_empty_w=1
            //→ STATUS[4]=1. RX_FULL (bit[3]) will be 0.
            // ==============================================================
            seq_item.status_read_c.constraint_mode(1);
            repeat(3) begin
                start_item(seq_item);
                    assert (seq_item.randomize())
                        else `uvm_fatal("RAND", "status read (RX_EMPTY) randomize failed");
                finish_item(seq_item);
            end
            seq_item.status_read_c.constraint_mode(0);

        endtask
    endclass
endpackage