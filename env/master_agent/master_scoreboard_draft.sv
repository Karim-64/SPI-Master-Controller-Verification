// =============================================================================
// master_scoreboard_draft.sv
// -----------------------------------------------------------------------------
// Ain Shams University - Digital Design Verification - Spring 2026
// Final Project - SPI Master Controller
//
// Self-checking scoreboard for the full spi_master wrapper.
// Internally combines:
//   1. APB regfile model  (mirrors apb_regfile_gm logic)
//   2. SPI core FSM model (mirrors spi_core logic)
//
// Predicted outputs checked every cycle:
//   pready, pslverr, prdata, irq, ss_n   (APB/regfile side)
//   sclk, mosi                            (SPI core side)
// =============================================================================

package master_scoreboard_pkg;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class master_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(master_scoreboard)

        uvm_analysis_export #(master_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(master_sequence_item) sb_fifo;
        master_sequence_item sb_seq_item;

        int error_count;
        int correct_count;

        // ===================================================================
        // APB / Regfile internal state
        // ===================================================================
        localparam int FIFO_DEPTH = 8;
        localparam int FIFO_AW    = 3;

        logic        r_ctrl_en, r_ctrl_mstr, r_ctrl_lsb_first, r_ctrl_loopback;
        logic [1:0]  r_ctrl_mode, r_ctrl_width;
        logic [15:0] r_clk_div;
        logic [3:0]  r_ss_en, r_ss_val;
        logic [4:0]  r_int_en, r_int_stat;
        logic [7:0]  r_delay_cfg;

        logic [31:0] tx_mem [0:FIFO_DEPTH-1];
        logic [FIFO_AW:0] tx_wp, tx_rp;
        logic [31:0] rx_mem [0:FIFO_DEPTH-1];
        logic [FIFO_AW:0] rx_wp, rx_rp;

        localparam int IRQ_TX_EMPTY      = 0;
        localparam int IRQ_RX_FULL       = 1;
        localparam int IRQ_TX_OVF        = 2;
        localparam int IRQ_RX_OVF        = 3;
        localparam int IRQ_TRANSFER_DONE = 4;

        localparam logic [7:0] OFF_CTRL     = 8'h00;
        localparam logic [7:0] OFF_STATUS   = 8'h04;
        localparam logic [7:0] OFF_TX_DATA  = 8'h08;
        localparam logic [7:0] OFF_RX_DATA  = 8'h0C;
        localparam logic [7:0] OFF_CLK_DIV  = 8'h10;
        localparam logic [7:0] OFF_SS_CTRL  = 8'h14;
        localparam logic [7:0] OFF_INT_EN   = 8'h18;
        localparam logic [7:0] OFF_INT_STAT = 8'h1C;
        localparam logic [7:0] OFF_DELAY    = 8'h20;

        // ===================================================================
        // SPI Core internal state
        // ===================================================================
        typedef enum logic [1:0] {
            S_IDLE   = 2'd0,
            S_SHIFT  = 2'd1,
            S_FINISH = 2'd2,
            S_GAP    = 2'd3
        } xfer_state_e;

        xfer_state_e core_state;

        logic [1:0]  xfer_mode;
        logic        xfer_lsb_first;
        logic [1:0]  xfer_width;
        logic [15:0] xfer_div;

        logic [31:0] sh_tx, sh_rx;
        logic [5:0]  bit_cnt;
        logic [16:0] sclk_cnt;
        logic [8:0]  gap_cnt;
        logic        sclk_phase;
        logic        do_sample, do_launch, do_first_cpha1;

        // Predicted registered core outputs
        logic pred_sclk, pred_mosi;
        logic pred_tx_pop, pred_rx_push_valid;
        logic [31:0] pred_rx_push_data;
        logic pred_transfer_done_pulse;

        // ===================================================================
        // Constructor / build / connect
        // ===================================================================
        function new(string name = "master_scoreboard", uvm_component parent = null);
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

        // ===================================================================
        // Reset helpers
        // ===================================================================
        function void reset_regfile();
            int i;
            r_ctrl_en = 1'b0; r_ctrl_mstr = 1'b0; r_ctrl_mode = 2'b00;
            r_ctrl_lsb_first = 1'b0; r_ctrl_loopback = 1'b0;
            r_ctrl_width = 2'b00; r_clk_div = 16'h0;
            r_ss_en = 4'h0; r_ss_val = 4'h0;
            r_int_en = 5'h0; r_int_stat = 5'h0; r_delay_cfg = 8'h0;
            tx_wp = '0; tx_rp = '0; rx_wp = '0; rx_rp = '0;
            for (i = 0; i < FIFO_DEPTH; i++) begin
                tx_mem[i] = 32'h0; rx_mem[i] = 32'h0;
            end
        endfunction

        function void flush_fifos();
            tx_wp = '0; tx_rp = '0; rx_wp = '0; rx_rp = '0;
        endfunction

        function void reset_core();
            core_state = S_IDLE;
            pred_sclk = 1'b0; pred_mosi = 1'b0;
            sh_tx = 32'h0; sh_rx = 32'h0;
            bit_cnt = 6'h0; sclk_cnt = 17'h0;
            sclk_phase = 1'b0; gap_cnt = 9'h0;
            xfer_mode = 2'b00; xfer_lsb_first = 1'b0;
            xfer_width = 2'b00; xfer_div = 16'h0;
            pred_tx_pop = 1'b0; pred_rx_push_valid = 1'b0;
            pred_rx_push_data = 32'h0;
            pred_transfer_done_pulse = 1'b0;
            do_sample = 1'b0; do_launch = 1'b0; do_first_cpha1 = 1'b0;
        endfunction

        // ===================================================================
        // Core helper functions
        // ===================================================================
        function automatic logic [5:0] get_width_bits(input logic [1:0] w);
            case (w)
                2'b00: get_width_bits = 6'd8;
                2'b01: get_width_bits = 6'd16;
                default: get_width_bits = 6'd32;
            endcase
        endfunction

        function automatic logic get_tx_bit(
            input logic [31:0] v, input logic [5:0] rem,
            input logic [5:0] tot, input logic lsb
        );
            if (lsb) get_tx_bit = v[tot - rem];
            else     get_tx_bit = v[rem - 1];
        endfunction

        function automatic logic [31:0] align_rx(
            input logic [31:0] sh, input logic [5:0] tot
        );
            align_rx = sh & ((tot == 6'd32) ? 32'hFFFF_FFFF
                                            : ((32'h1 << tot) - 32'h1));
        endfunction

        // ===================================================================
        // Run phase
        // ===================================================================
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            reset_regfile();
            reset_core();

            forever begin
                sb_fifo.get(sb_seq_item);

                begin : master_predict
                    // -----------------------------------------------------------
                    // ALL local declarations FIRST - Questa requires this
                    // -----------------------------------------------------------
                    // Regfile combinational
                    logic apb_access, apb_write, apb_read;
                    logic [FIFO_AW:0] tx_count_w, rx_count_w;
                    logic tx_full_w, tx_empty_w, rx_full_w, rx_empty_w;
                    logic        tx_push_valid;
                    logic [31:0] tx_push_data;
                    logic tx_push_accepted, tx_push_dropped;
                    logic rx_pop_this_cycle;
                    // Core combinational
                    logic [5:0]  wb;
                    logic        cpol, cpha;
                    logic [16:0] half_per;
                    logic        miso_eff;
                    // Edge detect temporaries (lifted here for Questa compatibility)
                    logic leading, is_smp, is_lnch;
                    // Regfile predictions
                    logic [3:0]  pred_ss_n;
                    logic        pred_irq;
                    logic [31:0] pred_prdata;
                    // INT_STAT update
                    logic [4:0]  next_stat;

                    // -----------------------------------------------------------
                    // Statements
                    // -----------------------------------------------------------
                    // APB handshake
                    apb_access = sb_seq_item.psel & sb_seq_item.penable;
                    apb_write  = apb_access &  sb_seq_item.pwrite;
                    apb_read   = apb_access & ~sb_seq_item.pwrite;

                    // FIFO status
                    tx_count_w = tx_wp - tx_rp;
                    rx_count_w = rx_wp - rx_rp;
                    tx_full_w  = (tx_count_w == FIFO_DEPTH);
                    tx_empty_w = (tx_count_w == 0);
                    rx_full_w  = (rx_count_w == FIFO_DEPTH);
                    rx_empty_w = (rx_count_w == 0);

                    // TX push decode
                    tx_push_valid = 1'b0; tx_push_data = 32'h0;
                    if (apb_write && sb_seq_item.paddr == OFF_TX_DATA && r_ctrl_en) begin
                        tx_push_valid = 1'b1;
                        case (r_ctrl_width)
                            2'b00: tx_push_data = {24'b0, sb_seq_item.pwdata[7:0]};
                            2'b01: tx_push_data = {16'b0, sb_seq_item.pwdata[15:0]};
                            default: tx_push_data = sb_seq_item.pwdata;
                        endcase
                    end
                    tx_push_accepted = tx_push_valid & ~tx_full_w;
                    tx_push_dropped  = tx_push_valid &  tx_full_w;
                    rx_pop_this_cycle = apb_read &&
                                        (sb_seq_item.paddr == OFF_RX_DATA) &&
                                        !rx_empty_w;

                    // Core helpers
                    wb       = get_width_bits(xfer_width);
                    cpol     = xfer_mode[1];
                    cpha     = xfer_mode[0];
                    half_per = {1'b0, xfer_div} + 17'd1;
                    miso_eff = r_ctrl_loopback ? pred_mosi : sb_seq_item.miso;

                    // Regfile predictions
                    pred_ss_n = ~r_ss_en | r_ss_val;
                    pred_irq  = |(r_int_stat & r_int_en);

                    // PRDATA mux
                    pred_prdata = 32'h0;
                    if (apb_read) begin
                        case (sb_seq_item.paddr)
                            OFF_CTRL:     pred_prdata = {24'b0, r_ctrl_width,
                                                         r_ctrl_loopback, r_ctrl_lsb_first,
                                                         r_ctrl_mode, r_ctrl_mstr, r_ctrl_en};
                            OFF_STATUS:   pred_prdata = {25'b0,
                                                         r_int_stat[IRQ_RX_OVF],
                                                         r_int_stat[IRQ_TX_OVF],
                                                         rx_empty_w, rx_full_w,
                                                         tx_empty_w, tx_full_w,
                                                         (core_state != S_IDLE)};
                            OFF_TX_DATA:  pred_prdata = 32'h0;
                            OFF_RX_DATA:  pred_prdata = rx_empty_w ? 32'h0
                                                      : rx_mem[rx_rp[FIFO_AW-1:0]];
                            OFF_CLK_DIV:  pred_prdata = {16'b0, r_clk_div};
                            OFF_SS_CTRL:  pred_prdata = {24'b0, r_ss_val, r_ss_en};
                            OFF_INT_EN:   pred_prdata = {27'b0, r_int_en};
                            OFF_INT_STAT: pred_prdata = {27'b0, r_int_stat};
                            OFF_DELAY:    pred_prdata = {24'b0, r_delay_cfg};
                            default:      pred_prdata = 32'h0;
                        endcase
                    end

                    // ==============================================================
                    // Compare
                    // ==============================================================
                    check1("pready",   1'b1,        sb_seq_item.pready);
                    check1("pslverr",  1'b0,        sb_seq_item.pslverr);
                    check32("prdata",  pred_prdata, sb_seq_item.prdata);
                    check4("ss_n",     pred_ss_n,   sb_seq_item.ss_n);
                    check1("irq",      pred_irq,    sb_seq_item.irq);
                    check1("sclk",     pred_sclk,   sb_seq_item.sclk);
                    check1("mosi",     pred_mosi,   sb_seq_item.mosi);

                    if (error_count == 0)
                        `uvm_info("MASTER_SB",
                            $sformatf("[PASS] %s", sb_seq_item.convert2string()),
                            UVM_HIGH)

                    // ==============================================================
                    // Advance state
                    // ==============================================================
                    if (!sb_seq_item.presetn) begin
                        reset_regfile();
                        reset_core();
                    end else begin
                        // ---- Regfile update ----
                        if (!r_ctrl_en) flush_fifos();

                        if (apb_write) begin
                            case (sb_seq_item.paddr)
                                OFF_CTRL: begin
                                    r_ctrl_width     = sb_seq_item.pwdata[7:6];
                                    r_ctrl_loopback  = sb_seq_item.pwdata[5];
                                    r_ctrl_lsb_first = sb_seq_item.pwdata[4];
                                    r_ctrl_mode      = sb_seq_item.pwdata[3:2];
                                    r_ctrl_mstr      = sb_seq_item.pwdata[1];
                                    r_ctrl_en        = sb_seq_item.pwdata[0];
                                end
                                OFF_CLK_DIV: r_clk_div   = sb_seq_item.pwdata[15:0];
                                OFF_SS_CTRL: begin
                                    r_ss_val = sb_seq_item.pwdata[7:4];
                                    r_ss_en  = sb_seq_item.pwdata[3:0];
                                end
                                OFF_INT_EN:  r_int_en    = sb_seq_item.pwdata[4:0];
                                OFF_DELAY:   r_delay_cfg = sb_seq_item.pwdata[7:0];
                                default: ;
                            endcase
                        end

                        // INT_STAT: W1C + events
                        next_stat = r_int_stat;
                        if (apb_write && sb_seq_item.paddr == OFF_INT_STAT)
                            next_stat = next_stat & ~sb_seq_item.pwdata[4:0];
                        if (tx_push_dropped)
                            next_stat[IRQ_TX_OVF] = 1'b1;
                        if (pred_rx_push_valid && rx_full_w)
                            next_stat[IRQ_RX_OVF] = 1'b1;
                        if (pred_rx_push_valid && !rx_full_w &&
                            (rx_count_w == (FIFO_DEPTH-1)))
                            next_stat[IRQ_RX_FULL] = 1'b1;
                        if (pred_tx_pop && (tx_count_w == 1))
                            next_stat[IRQ_TX_EMPTY] = 1'b1;
                        if (pred_transfer_done_pulse)
                            next_stat[IRQ_TRANSFER_DONE] = 1'b1;
                        r_int_stat = next_stat;

                        // TX FIFO
                        if (r_ctrl_en) begin
                            if (tx_push_accepted) begin
                                tx_mem[tx_wp[FIFO_AW-1:0]] = tx_push_data;
                                tx_wp = tx_wp + 1'b1;
                            end
                            if (pred_tx_pop) tx_rp = tx_rp + 1'b1;
                        end

                        // RX FIFO
                        if (r_ctrl_en) begin
                            if (pred_rx_push_valid && !rx_full_w) begin
                                rx_mem[rx_wp[FIFO_AW-1:0]] = pred_rx_push_data;
                                rx_wp = rx_wp + 1'b1;
                            end
                            if (rx_pop_this_cycle) rx_rp = rx_rp + 1'b1;
                        end

                        // ---- Core update ----
                        pred_tx_pop              = 1'b0;
                        pred_rx_push_valid       = 1'b0;
                        pred_rx_push_data        = 32'h0;
                        pred_transfer_done_pulse = 1'b0;
                        do_sample                = 1'b0;
                        do_launch                = 1'b0;
                        do_first_cpha1           = 1'b0;

                        if (!r_ctrl_en) begin
                            core_state = S_IDLE;
                            pred_sclk  = r_ctrl_mode[1];
                            pred_mosi  = 1'b0;
                            sclk_cnt   = 17'h0;
                            sclk_phase = 1'b0;
                            gap_cnt    = 9'h0;
                        end else begin
                            case (core_state)
                                S_IDLE: begin
                                    pred_sclk = r_ctrl_mode[1];
                                    if (!tx_empty_w && r_ctrl_mstr &&
                                        (pred_ss_n != 4'hF))
                                    begin
                                        xfer_mode      = r_ctrl_mode;
                                        xfer_lsb_first = r_ctrl_lsb_first;
                                        xfer_width     = r_ctrl_width;
                                        xfer_div       = r_clk_div;
                                        sh_tx          = tx_mem[tx_rp[FIFO_AW-1:0]];
                                        pred_tx_pop    = 1'b1;
                                        bit_cnt = (r_ctrl_width==2'b00) ? 6'd8  :
                                                  (r_ctrl_width==2'b01) ? 6'd16 : 6'd32;
                                        sclk_cnt   = 17'h0;
                                        sclk_phase = 1'b0;
                                        if (r_ctrl_mode[0] == 1'b0)
                                            pred_mosi = r_ctrl_lsb_first ?
                                                tx_mem[tx_rp[FIFO_AW-1:0]][0] :
                                                tx_mem[tx_rp[FIFO_AW-1:0]][
                                                    (r_ctrl_width==2'b00) ? 7  :
                                                    (r_ctrl_width==2'b01) ? 15 : 31];
                                        sh_rx      = 32'h0;
                                        core_state = S_SHIFT;
                                        pred_sclk  = r_ctrl_mode[1];
                                    end
                                end

                                S_SHIFT: begin
                                    if (do_sample) begin
                                        if (xfer_lsb_first)
                                            sh_rx[wb - bit_cnt] = miso_eff;
                                        else
                                            sh_rx[bit_cnt - 1] = miso_eff;
                                        if (bit_cnt == 6'd1) core_state = S_FINISH;
                                        bit_cnt = bit_cnt - 6'd1;
                                    end
                                    if (do_launch && (bit_cnt > 6'd0))
                                        pred_mosi = get_tx_bit(sh_tx, bit_cnt, wb, xfer_lsb_first);
                                    if (do_first_cpha1)
                                        pred_mosi = get_tx_bit(sh_tx, bit_cnt, wb, xfer_lsb_first);

                                    if (sclk_cnt == half_per - 1) begin
                                        sclk_cnt   = 17'h0;
                                        sclk_phase = ~sclk_phase;
                                        pred_sclk  = ~pred_sclk;
                                        // Using class-level vars declared above
                                        leading    = ~sclk_phase;
                                        is_smp     = (cpha == 1'b0) ? leading : ~leading;
                                        is_lnch    = ~is_smp;
                                        do_sample  = is_smp;
                                        do_launch  = is_lnch;
                                        if (cpha == 1'b1 && leading && (bit_cnt == wb))
                                            do_first_cpha1 = 1'b1;
                                    end else
                                        sclk_cnt = sclk_cnt + 17'h1;
                                end

                                S_FINISH: begin
                                    if (sclk_cnt == half_per - 1) begin
                                        sclk_cnt                 = 17'h0;
                                        pred_sclk                = cpol;
                                        sclk_phase               = 1'b0;
                                        pred_rx_push_valid       = 1'b1;
                                        pred_rx_push_data        = align_rx(sh_rx, wb);
                                        pred_transfer_done_pulse = 1'b1;
                                        if (!tx_empty_w && r_delay_cfg != 8'h0) begin
                                            gap_cnt    = {1'b0, r_delay_cfg};
                                            core_state = S_GAP;
                                        end else
                                            core_state = S_IDLE;
                                    end else
                                        sclk_cnt = sclk_cnt + 17'h1;
                                end

                                S_GAP: begin
                                    pred_sclk = cpol;
                                    if (sclk_cnt == half_per - 1) begin
                                        sclk_cnt = 17'h0;
                                        if (gap_cnt == 9'h1) core_state = S_IDLE;
                                        gap_cnt = gap_cnt - 9'h1;
                                    end else
                                        sclk_cnt = sclk_cnt + 17'h1;
                                end

                                default: core_state = S_IDLE;
                            endcase
                        end
                    end

                end : master_predict
            end // forever
        endtask

        // ===================================================================
        // Comparison helpers
        // ===================================================================
        task check1(input string sig_name, input logic pred, input logic obs);
            if (pred !== obs) begin
                `uvm_error("MASTER_SB",
                    $sformatf("[MISMATCH] %-20s  predicted=%0b  observed=%0b",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check4(input string sig_name,
                    input logic [3:0] pred, input logic [3:0] obs);
            if (pred !== obs) begin
                `uvm_error("MASTER_SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%01h  observed=0x%01h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check32(input string sig_name,
                     input logic [31:0] pred, input logic [31:0] obs);
            if (pred !== obs) begin
                `uvm_error("MASTER_SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%08h  observed=0x%08h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        // ===================================================================
        // Report phase
        // ===================================================================
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("MASTER_SB",
                $sformatf("============================================================\n"
                         +"  MASTER SCOREBOARD SUMMARY\n"
                         +"  Total checks passed : %0d\n"
                         +"  Total mismatches    : %0d\n"
                         +"============================================================",
                         correct_count, error_count),
                UVM_MEDIUM)
            if (error_count != 0)
                `uvm_error("MASTER_SB",
                    $sformatf("TEST FAILED - %0d mismatch(es) detected.", error_count))
            else
                `uvm_info("MASTER_SB",
                    "TEST PASSED - all master predictions matched DUT outputs.",
                    UVM_MEDIUM)
        endfunction

    endclass

endpackage
