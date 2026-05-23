// =============================================================================
// spi_core_scoreboard_draft.sv
// -----------------------------------------------------------------------------
// Ain Shams University - Digital Design Verification - Spring 2026
// Final Project - SPI Master Controller
//
// Self-checking scoreboard for the SPI core sub-block.
//
// Architecture:
//   run_phase  ->  predict_and_check(seq_item)
//                      |-- decode inputs (cfg_*, tx_*, miso, ss_n)
//                      |-- calculate expected outputs from FSM state
//                      |-- compare expected vs observed DUT outputs
//                      `-- advance FSM state for next cycle
//
// FSM states:  S_IDLE -> S_SHIFT -> S_FINISH -> (S_GAP ->) S_IDLE
//
// Outputs checked every cycle:
//   tx_pop, rx_push_valid, rx_push_data, busy,
//   transfer_done_pulse, sclk, mosi
// =============================================================================

package spi_core_scoreboard_pkg;
    import uvm_pkg::*;
    import spi_core_shared_pkg::*;
    import spi_core_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class spi_core_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(spi_core_scoreboard)

        // -----------------------------------------------------------------------
        // TLM port / FIFO
        // -----------------------------------------------------------------------
        uvm_analysis_export #(spi_core_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(spi_core_sequence_item) sb_fifo;
        spi_core_sequence_item sb_seq_item;

        int error_count;
        int correct_count;

        // -----------------------------------------------------------------------
        // Internal FSM state (mirrors spi_core RTL exactly)
        // -----------------------------------------------------------------------
        typedef enum logic [1:0] {
            S_IDLE   = 2'd0,
            S_SHIFT  = 2'd1,
            S_FINISH = 2'd2,
            S_GAP    = 2'd3
        } xfer_state_e;

        xfer_state_e state;

        // Config latched at start of each transfer (R25)
        logic [1:0]  xfer_mode;
        logic        xfer_lsb_first;
        logic [1:0]  xfer_width;
        logic [15:0] xfer_div;

        // Datapath
        logic [31:0] sh_tx, sh_rx;
        logic [5:0]  bit_cnt;
        logic [16:0] sclk_cnt;
        logic [8:0]  gap_cnt;
        logic        sclk_phase;

        // One-cycle deferred action flags (fixed RTL pattern)
        logic do_sample, do_launch, do_first_cpha1;

        // Current predicted registered DUT outputs (valid for the *current* cycle)
        logic pred_tx_pop, pred_rx_push_valid;
        logic [31:0] pred_rx_push_data;
        logic pred_transfer_done_pulse;
        logic pred_sclk, pred_mosi;

        // -----------------------------------------------------------------------
        // Constructor / build / connect
        // -----------------------------------------------------------------------
        function new(string name = "spi_core_scoreboard", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sb_export = new("sb_export", this);
            sb_fifo   = new("sb_fifo",   this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            sb_export.connect(sb_fifo.analysis_export);
        endfunction

        // -----------------------------------------------------------------------
        // Reset helper
        // -----------------------------------------------------------------------
        function void do_reset();
            state                    = S_IDLE;
            pred_sclk                = 1'b0;
            pred_mosi                = 1'b0;
            sh_tx                    = 32'h0;
            sh_rx                    = 32'h0;
            bit_cnt                  = 6'h0;
            sclk_cnt                 = 17'h0;
            sclk_phase               = 1'b0;
            gap_cnt                  = 9'h0;
            xfer_mode                = 2'b00;
            xfer_lsb_first           = 1'b0;
            xfer_width               = 2'b00;
            xfer_div                 = 16'h0;
            pred_tx_pop              = 1'b0;
            pred_rx_push_valid       = 1'b0;
            pred_rx_push_data        = 32'h0;
            pred_transfer_done_pulse = 1'b0;
            do_sample                = 1'b0;
            do_launch                = 1'b0;
            do_first_cpha1           = 1'b0;
        endfunction

        // -----------------------------------------------------------------------
        // Helper functions (match spi_core RTL helpers)
        // -----------------------------------------------------------------------
        function automatic logic [5:0] get_width_bits(input logic [1:0] w);
            case (w)
                2'b00:   get_width_bits = 6'd8;
                2'b01:   get_width_bits = 6'd16;
                default: get_width_bits = 6'd32;
            endcase
        endfunction

        function automatic logic get_tx_bit(
            input logic [31:0] v,
            input logic [5:0]  remaining,
            input logic [5:0]  total_bits,
            input logic        lsb_first
        );
            if (lsb_first) get_tx_bit = v[total_bits - remaining];
            else           get_tx_bit = v[remaining - 1];
        endfunction

        function automatic logic [31:0] align_rx(
            input logic [31:0] sh,
            input logic [5:0]  total_bits
        );
            align_rx = sh & ((total_bits == 6'd32) ? 32'hFFFF_FFFF
                                                   : ((32'h1 << total_bits) - 32'h1));
        endfunction

        // -----------------------------------------------------------------------
        // predict_and_check
        // -----------------------------------------------------------------------
        // Receives one transaction (one PCLK cycle snapshot):
        //   Step 1 – Derive combinational helper values from INPUT signals
        //   Step 2 – The current pred_* class vars hold expected outputs for
        //            this cycle (set at end of the previous call)
        //   Step 3 – Compare expected vs observed DUT outputs
        //   Step 4 – Advance the internal FSM state (posedge PCLK logic)
        // -----------------------------------------------------------------------
        task predict_and_check(spi_core_sequence_item item);
            // All locals declared first (Questa 2021.1 requirement)
            logic [5:0]  wb;           // transfer width in bits
            logic        cpol, cpha;
            logic [16:0] half_per;
            logic        miso_eff;     // MISO or loopback MOSI
            // Edge-detect temporaries for S_SHIFT
            logic leading, is_smp, is_lnch;

            // ------------------------------------------------------------------
            // Step 1 – Derive combinational helpers from INPUT signals
            // ------------------------------------------------------------------
            wb       = get_width_bits(xfer_width);
            cpol     = xfer_mode[1];
            cpha     = xfer_mode[0];
            half_per = {1'b0, xfer_div} + 17'd1;

            // Loopback: if cfg_loopback is set, the core feeds MOSI back to MISO
            miso_eff = item.cfg_loopback ? pred_mosi : item.miso;

            // ------------------------------------------------------------------
            // Step 2 – Calculate EXPECTED outputs
            // The registered DUT outputs observed at negedge PCLK reflect the
            // state computed on the *previous* posedge.  The pred_* class members
            // were updated at the end of the previous call, so they represent
            // exactly what the DUT should be driving right now.
            // busy is combinational: (state != S_IDLE)
            // ------------------------------------------------------------------

            // ------------------------------------------------------------------
            // Step 3 – Compare expected vs observed
            // ------------------------------------------------------------------
            check1("tx_pop",             pred_tx_pop,              item.tx_pop);
            check1("rx_push_valid",       pred_rx_push_valid,       item.rx_push_valid);
            check1("busy",               (state != S_IDLE),        item.busy);
            check1("transfer_done_pulse", pred_transfer_done_pulse, item.transfer_done_pulse);
            check1("sclk",               pred_sclk,                item.sclk);
            check1("mosi",               pred_mosi,                item.mosi);
            check32("rx_push_data",       pred_rx_push_data,        item.rx_push_data);

            `uvm_info("CORE_SB",
                $sformatf("[CYCLE] state=%-7s bit_cnt=%0d sclk_cnt=%0d | "
                         +"busy=%0b sclk=%0b mosi=%0b tx_pop=%0b rx_valid=%0b",
                         state.name(), bit_cnt, sclk_cnt,
                         item.busy, item.sclk, item.mosi,
                         item.tx_pop, item.rx_push_valid),
                UVM_HIGH)

            // ------------------------------------------------------------------
            // Step 4 – Advance internal FSM state (mirrors posedge PCLK block)
            // ------------------------------------------------------------------
            if (!item.presetn) begin
                do_reset();
            end else begin
                // Clear one-shot outputs for the next cycle
                pred_tx_pop              = 1'b0;
                pred_rx_push_valid       = 1'b0;
                pred_rx_push_data        = 32'h0;
                pred_transfer_done_pulse = 1'b0;
                // Clear deferred flags
                do_sample      = 1'b0;
                do_launch      = 1'b0;
                do_first_cpha1 = 1'b0;

                if (!item.cfg_en) begin
                    // cfg_en=0: hold SCLK at CPOL idle, reset counters
                    state      = S_IDLE;
                    pred_sclk  = item.cfg_mode[1];
                    pred_mosi  = 1'b0;
                    sclk_cnt   = 17'h0;
                    sclk_phase = 1'b0;
                    gap_cnt    = 9'h0;
                end else begin
                    case (state)

                        // -------------------------------------------------------
                        // S_IDLE: wait for TX data + master mode + SS asserted
                        // -------------------------------------------------------
                        S_IDLE: begin
                            pred_sclk = item.cfg_mode[1];  // hold CPOL idle

                            // Start condition: TX data available, master, at least
                            // one SS lane driven low (ss_n != 4'hF)
                            if (!item.tx_empty &&
                                item.cfg_mstr  &&
                                (item.ss_n != 4'hF))
                            begin
                                // Latch per-transfer config (R25)
                                xfer_mode      = item.cfg_mode;
                                xfer_lsb_first = item.cfg_lsb_first;
                                xfer_width     = item.cfg_width;
                                xfer_div       = item.cfg_clk_div;

                                // Load TX shift register and pop FIFO
                                sh_tx       = item.tx_word;
                                pred_tx_pop = 1'b1;

                                // Initialise bit counter
                                bit_cnt = (item.cfg_width == 2'b00) ? 6'd8  :
                                          (item.cfg_width == 2'b01) ? 6'd16 : 6'd32;

                                sclk_cnt   = 17'h0;
                                sclk_phase = 1'b0;

                                // CPHA=0: present MSB/LSB immediately before first clock edge
                                if (item.cfg_mode[0] == 1'b0)
                                    pred_mosi = item.cfg_lsb_first ?
                                        item.tx_word[0] :
                                        item.tx_word[
                                            (item.cfg_width == 2'b00) ? 7  :
                                            (item.cfg_width == 2'b01) ? 15 : 31];

                                sh_rx     = 32'h0;
                                state     = S_SHIFT;
                                pred_sclk = item.cfg_mode[1];
                            end
                        end

                        // -------------------------------------------------------
                        // S_SHIFT: clock out / in bits
                        // -------------------------------------------------------
                        S_SHIFT: begin
                            // Act on deferred flags set in the previous cycle
                            if (do_sample) begin
                                // Sample MISO into shift register
                                if (xfer_lsb_first)
                                    sh_rx[wb - bit_cnt] = miso_eff;
                                else
                                    sh_rx[bit_cnt - 1] = miso_eff;

                                if (bit_cnt == 6'd1) state = S_FINISH;
                                bit_cnt = bit_cnt - 6'd1;
                            end

                            if (do_launch && (bit_cnt > 6'd0))
                                pred_mosi = get_tx_bit(sh_tx, bit_cnt, wb, xfer_lsb_first);

                            // CPHA=1: first bit launched one cycle after first edge
                            if (do_first_cpha1)
                                pred_mosi = get_tx_bit(sh_tx, bit_cnt, wb, xfer_lsb_first);

                            // Detect SCLK edge; set deferred flags for next cycle
                            if (sclk_cnt == half_per - 1) begin
                                sclk_cnt   = 17'h0;
                                sclk_phase = ~sclk_phase;
                                pred_sclk  = ~pred_sclk;

                                leading    = ~sclk_phase;   // pre-toggle value
                                is_smp     = (cpha == 1'b0) ? leading : ~leading;
                                is_lnch    = ~is_smp;
                                do_sample  = is_smp;
                                do_launch  = is_lnch;

                                if (cpha == 1'b1 && leading && (bit_cnt == wb))
                                    do_first_cpha1 = 1'b1;
                            end else
                                sclk_cnt = sclk_cnt + 17'h1;
                        end

                        // -------------------------------------------------------
                        // S_FINISH: complete final half-period, push RX word
                        // -------------------------------------------------------
                        S_FINISH: begin
                            if (sclk_cnt == half_per - 1) begin
                                sclk_cnt                 = 17'h0;
                                pred_sclk                = cpol;
                                sclk_phase               = 1'b0;
                                pred_rx_push_valid       = 1'b1;
                                pred_rx_push_data        = align_rx(sh_rx, wb);
                                pred_transfer_done_pulse = 1'b1;

                                // Gap between back-to-back transfers
                                if (!item.tx_empty &&
                                    item.cfg_delay != 8'h0)
                                begin
                                    gap_cnt = {1'b0, item.cfg_delay};
                                    state   = S_GAP;
                                end else
                                    state = S_IDLE;
                            end else
                                sclk_cnt = sclk_cnt + 17'h1;
                        end

                        // -------------------------------------------------------
                        // S_GAP: inter-transfer delay
                        // -------------------------------------------------------
                        S_GAP: begin
                            pred_sclk = cpol;  // hold SCLK at CPOL idle during gap
                            if (sclk_cnt == half_per - 1) begin
                                sclk_cnt = 17'h0;
                                if (gap_cnt == 9'h1) state = S_IDLE;
                                gap_cnt = gap_cnt - 9'h1;
                            end else
                                sclk_cnt = sclk_cnt + 17'h1;
                        end

                        default: state = S_IDLE;
                    endcase
                end
            end // !reset
        endtask

        // -----------------------------------------------------------------------
        // Run phase
        // -----------------------------------------------------------------------
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            do_reset();
            forever begin
                sb_fifo.get(sb_seq_item);
                predict_and_check(sb_seq_item);
            end
        endtask

        // -----------------------------------------------------------------------
        // Comparison helpers
        // -----------------------------------------------------------------------
        task check1(input string name, input logic exp, input logic obs);
            if (exp !== obs) begin
                `uvm_error("CORE_SB",
                    $sformatf("[MISMATCH] %-25s  expected=%0b  observed=%0b",
                              name, exp, obs))
                error_count++;
            end else correct_count++;
        endtask

        task check32(input string name,
                     input logic [31:0] exp, input logic [31:0] obs);
            if (exp !== obs) begin
                `uvm_error("CORE_SB",
                    $sformatf("[MISMATCH] %-25s  expected=0x%08h  observed=0x%08h",
                              name, exp, obs))
                error_count++;
            end else correct_count++;
        endtask

        // -----------------------------------------------------------------------
        // Report phase
        // -----------------------------------------------------------------------
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("CORE_SB",
                $sformatf("============================================================\n"
                         +"  SPI CORE SCOREBOARD SUMMARY\n"
                         +"  Total checks passed : %0d\n"
                         +"  Total mismatches    : %0d\n"
                         +"============================================================",
                         correct_count, error_count),
                UVM_MEDIUM)
            if (error_count != 0)
                `uvm_error("CORE_SB",
                    $sformatf("TEST FAILED - %0d mismatch(es) detected.", error_count))
            else
                `uvm_info("CORE_SB",
                    "TEST PASSED - all SPI core predictions matched DUT outputs.",
                    UVM_MEDIUM)
        endfunction

    endclass

endpackage
