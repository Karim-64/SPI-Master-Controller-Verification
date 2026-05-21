package master_interrupts_sequence_pkg;
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

    class master_interrupts_sequence extends uvm_sequence #(master_sequence_item);
            `uvm_object_utils(master_interrupts_sequence)

            master_sequence_item seq_item;

            function new(string name = "master_interrupts_sequence");
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
                            pwdata[3:2]  == 2'b00;   // Force Mode 0 for deterministic timing
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
                    repeat(3) begin
                    seq_item.TX_FULL_OVF_c.constraint_mode(1);
                        start_item(seq_item);
                            assert (seq_item.randomize())
                                else `uvm_fatal("RAND", "TX fill randomize failed");
                        finish_item(seq_item);
                    seq_item.TX_FULL_OVF_c.constraint_mode(0);
                    end
                end

               
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


                //enable interrupt for TX_OVF
               
                    seq_item.int_EN_c.constraint_mode(1);
                repeat(3) begin
                    start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1;  pwdata == 32'h0000_0004; pwrite == 1; }) ;
                    finish_item(seq_item);
                    
                end
                    seq_item.int_EN_c.constraint_mode(0);
               
                // Wait to make IRQ visible on waveform
                repeat(2) begin
                    start_item(seq_item);
                    seq_item.psel = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                //write one to clear the TX_OVF interrupt
                repeat(30) begin
                repeat(3) begin
                    seq_item.clr_STAT_c.constraint_mode(1);
                    start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1; pwdata == 32'h0000_0004; pwrite == 1; });
                    finish_item(seq_item);
                    seq_item.clr_STAT_c.constraint_mode(0);
                    
                end
                end
            //=================================================
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
                //   1 transfer  = 8 bits × 4 + 2 cycles = 34 PCLK
                //   8 transfers = ~256 PCLK + FINISH/GAP overhead
                // Send 300 idle items to allow SPI core FSM to complete
                // (Wait covers both TX emptying and RX filling)
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

                // =================================================
                // enable interrupt for TX_EMPTY and RX_FULL
                
                    repeat(3) begin
                        seq_item.int_EN_c.constraint_mode(1);
                        start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1;
                                                                 pwdata == 32'h0000_0003;   // enable RX_FULL and TX_EMPTY interrupts   
                                                                 pwrite == 1;
                                                                });
                        finish_item(seq_item);
                        seq_item.int_EN_c.constraint_mode(0);
                        
                    end
               
                // Wait to make IRQ visible on waveform
                repeat(2) begin
                    start_item(seq_item);
                    seq_item.psel = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                //write one to clear the TX_EMPTY interrupt and RX_FULL interrupt
                
                    repeat(3) begin
                        seq_item.clr_STAT_c.constraint_mode(1);
                        start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1; pwdata == 32'h0000_0003; pwrite == 1;  // clear RX_FULL and TX_EMPTY interrupts
                                                                    });
                        finish_item(seq_item);
                        seq_item.clr_STAT_c.constraint_mode(0);
                        
                    end
                
                //=================================================

                // ======================= RX OVF Test ==============================
                // ==============================================================
                // Re-enable master (cfg_mstr=1) and push one more TX
                // RX FIFO is now full (rx_count==8). When the SPI core
                // completes the transfer it asserts rx_push_valid while
                // rx_full_w=1 → int_stat[IRQ_RX_OVF] latches to 1
                // (apb_regfile.sv line 262-263).
                // STATUS bit[6] = int_stat[IRQ_RX_OVF] will be set.
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
                            pwdata[3:2] == 2'b00;   // Force Mode 0
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
                // PHASE 17 – Wait for the overflow transfer to complete
                //   1 transfer ≈ 34 PCLK
                // ==============================================================
                repeat(34) begin
                    start_item(seq_item);
                    finish_item(seq_item);
                end

                // =================================================
                // enable interrupt for RX_OVF
              
                    repeat(3) begin
                        seq_item.int_EN_c.constraint_mode(1);
                        start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1; pwdata == 32'h0000_0008; pwrite == 1;  // enable RX_OVF interrupt
                                                                });
                        finish_item(seq_item);
                        seq_item.int_EN_c.constraint_mode(0);
                        
                    end
               
                // Wait to make IRQ visible on waveform
                repeat(2) begin
                    start_item(seq_item);
                    seq_item.psel = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                //write one to clear the RX_OVF interrupt
               
                    repeat(3) begin
                        seq_item.clr_STAT_c.constraint_mode(1);
                        start_item(seq_item);
                            assert (seq_item.randomize() with { presetn == 1; pwdata == 32'h0000_0008; pwrite == 1; });
                        finish_item(seq_item);
                        seq_item.clr_STAT_c.constraint_mode(0);
                        
                    end
             
                //=================================================


                // ======================= TRANSFER DONE Test =======================

                seq_item.int_EN_c.constraint_mode(1);

                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {
                            presetn == 1;
                            pwrite  == 1;
                            pwdata  == 32'h0000_0010;
                        });
                    finish_item(seq_item);
                end

                seq_item.int_EN_c.constraint_mode(0);

                // ----------------------------------------------------------
                // Push TX data (4 x 16-bit words)
                // ----------------------------------------------------------
                repeat(4) begin

                    seq_item.TX_FULL_OVF_c.constraint_mode(1);

                    repeat(3) begin
                        start_item(seq_item);
                            assert(seq_item.randomize() with {
                                presetn == 1;
                                pwrite  == 1;
                                pwdata[15:0] inside {
                                    16'hA5A5,
                                    16'h1234,
                                    16'hFFFF,
                                    16'h0000
                                };
                            });
                        finish_item(seq_item);
                    end

                    seq_item.TX_FULL_OVF_c.constraint_mode(0);

                end

                // ----------------------------------------------------------
                // Wait for SPI transfer completion
                // 16-bit transfer:
                // ~16 * 4 + margin
                // ----------------------------------------------------------
                repeat(100) begin
                    start_item(seq_item);
                    finish_item(seq_item);
                end

                // ----------------------------------------------------------
                // Wait to make IRQ visible on waveform
                // ----------------------------------------------------------
                repeat(2) begin
                    start_item(seq_item);
                    seq_item.psel = 0;
                    seq_item.penable = 0;
                    finish_item(seq_item);
                end

                // ----------------------------------------------------------
                // Clear TRANSFER_DONE interrupt (W1C)
                // ----------------------------------------------------------
                seq_item.clr_STAT_c.constraint_mode(1);

                repeat(3) begin
                    start_item(seq_item);
                        assert(seq_item.randomize() with {
                            presetn == 1;
                            pwrite  == 1;
                            pwdata  == 32'h0000_0010;
                        });
                    finish_item(seq_item);
                end

                seq_item.clr_STAT_c.constraint_mode(0);



                // ----------------------------------------------------------
                // W1C RACE TEST (TRANSFER_DONE) -
                // ----------------------------------------------------------
                begin

                    // =========================
                    // 1. CONFIGURE CORE
                    // =========================
                    seq_item.ctrl_c.constraint_mode(1);

                    repeat(3) begin
                        start_item(seq_item);
                            assert(seq_item.randomize() with {
                                presetn     == 1;
                                pwrite      == 1;
                                pwdata[0]   == 1;        // EN
                                pwdata[1]   == 1;        // MSTR
                                pwdata[3:2] == 2'b00;    // CPOL=0, CPHA=0 (Mode 0)
                                pwdata[7:6] == 2'b00;    // 8-bit
                            });
                        finish_item(seq_item);
                    end

                    seq_item.ctrl_c.constraint_mode(0);

                    // clk_div = 0 → fastest deterministic timing
                    seq_item.clk_div_c.constraint_mode(1);

                    repeat(3) begin
                        start_item(seq_item);
                            assert(seq_item.randomize() with {
                                presetn      == 1;
                                pwrite       == 1;
                                pwdata[15:0] == 16'd0;
                            });
                        finish_item(seq_item);
                    end

                    seq_item.clk_div_c.constraint_mode(0);

                    // =========================
                    // 2. ENABLE SS
                    // =========================
                    seq_item.ss_ctrl_c.constraint_mode(1);

                    repeat(3) begin
                        start_item(seq_item);
                            assert(seq_item.randomize() with {
                                presetn    == 1;
                                pwrite     == 1;
                                pwdata[7:0]== 8'b0000_0001;
                            });
                        finish_item(seq_item);
                    end

                    seq_item.ss_ctrl_c.constraint_mode(0);

                    // =========================
                    // 3. START SINGLE TRANSFER
                    // =========================
                    seq_item.TX_FULL_OVF_c.constraint_mode(1);

                    repeat(3) begin
                        start_item(seq_item);
                            assert(seq_item.randomize() with {
                                presetn == 1;
                                pwrite  == 1;
                                pwdata  == 32'hAAAA;
                            });
                        finish_item(seq_item);
                    end

                    seq_item.TX_FULL_OVF_c.constraint_mode(0);

                    // Wait for Step 3 transfer to finish completely so FIFO is empty
                    repeat(40) begin
                        start_item(seq_item);
                            seq_item.psel = 0; seq_item.penable = 0;
                        finish_item(seq_item);
                    end

                    // =========================
                    // 4. WAIT EXACT TRANSFER TIME
                    // =========================
                    // For clk_div=0, width=8: pulse fires during Cycle 18.
                    // Access phase @ i+2. i+2=18 => i=16.
                    // Sweeping 15-17 to be safe.
                    for (int i = 15; i <= 17; i++) begin
                        // 4a. Trigger Transfer
                        seq_item.TX_FULL_OVF_c.constraint_mode(1);
                        repeat(3) begin
                            start_item(seq_item);
                                assert(seq_item.randomize() with {
                                    presetn == 1; pwrite == 1; pwdata == 32'hAAAA;
                                });
                            finish_item(seq_item);
                        end
                        seq_item.TX_FULL_OVF_c.constraint_mode(0);

                        // 4b. Wait
                        repeat(i) begin
                            start_item(seq_item);
                                seq_item.psel = 0; seq_item.penable = 0;
                            finish_item(seq_item);
                        end

                        // =========================
                        // 5. W1C AT EXACT TRANSFER_DONE CYCLE
                        // =========================
                        seq_item.clr_STAT_c.constraint_mode(1);
                        repeat(3) begin
                            start_item(seq_item);
                                assert(seq_item.randomize() with {
                                    presetn == 1; pwrite == 1;
                                    pwdata  == 32'h0000_0010; // TRANSFER_DONE W1C
                                });
                            finish_item(seq_item);
                        end
                        seq_item.clr_STAT_c.constraint_mode(0);

                        // =========================
                        // 6. CLEANUP WAIT
                        // =========================
                        repeat(20) begin
                            start_item(seq_item);
                                seq_item.psel = 0; seq_item.penable = 0;
                            finish_item(seq_item);
                        end
                    end

                 
                end

             

                            endtask
                            
                        endclass

endpackage