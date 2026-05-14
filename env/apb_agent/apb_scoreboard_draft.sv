// =============================================================================
// apb_scoreboard_draft.sv
// -----------------------------------------------------------------------------
// Ain Shams University - Digital Design Verification - Spring 2026
// Final Project - SPI Master Controller
//
// Self-checking scoreboard that mirrors the apb_regfile_gm golden model
// entirely in SystemVerilog.
//
// Register map (from apb_regfile.sv):
//   0x00 CTRL      - {width[1:0], loopback, lsb_first, mode[1:0], mstr, en}
//   0x04 STATUS    - read-only, built from FIFOs + busy
//   0x08 TX_DATA   - WO, pushes to TX FIFO (masked by ctrl_width)
//   0x0C RX_DATA   - RO, pops from RX FIFO
//   0x10 CLK_DIV   - lower 16 bits
//   0x14 SS_CTRL   - {ss_val[3:0], ss_en[3:0]}
//   0x18 INT_EN    - 5 interrupt enable bits
//   0x1C INT_STAT  - W1C sticky interrupt status
//   0x20 DELAY     - lower 8 bits
// =============================================================================

package apb_scoreboard_pkg;
    import uvm_pkg::*;
    import apb_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class apb_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(apb_scoreboard)

        // TLM port / FIFO
        uvm_analysis_export #(apb_sequence_item) sb_export;
        uvm_tlm_analysis_fifo #(apb_sequence_item) sb_fifo;
        apb_sequence_item sb_seq_item;

        // Score counters
        int error_count;
        int correct_count;

        // -----------------------------------------------------------------------
        // Internal golden-model state
        // -----------------------------------------------------------------------
        localparam int FIFO_DEPTH = 8;
        localparam int FIFO_AW    = 3;

        // Config registers
        logic        r_ctrl_en;
        logic        r_ctrl_mstr;
        logic [1:0]  r_ctrl_mode;
        logic        r_ctrl_lsb_first;
        logic        r_ctrl_loopback;
        logic [1:0]  r_ctrl_width;
        logic [15:0] r_clk_div;
        logic [3:0]  r_ss_en;
        logic [3:0]  r_ss_val;
        logic [4:0]  r_int_en;
        logic [4:0]  r_int_stat;
        logic [7:0]  r_delay_cfg;

        // TX FIFO model
        logic [31:0] tx_mem [0:FIFO_DEPTH-1];
        logic [FIFO_AW:0] tx_wp;
        logic [FIFO_AW:0] tx_rp;

        // RX FIFO model
        logic [31:0] rx_mem [0:FIFO_DEPTH-1];
        logic [FIFO_AW:0] rx_wp;
        logic [FIFO_AW:0] rx_rp;

        // Interrupt bit indices
        localparam int IRQ_TX_EMPTY      = 0;
        localparam int IRQ_RX_FULL       = 1;
        localparam int IRQ_TX_OVF        = 2;
        localparam int IRQ_RX_OVF        = 3;
        localparam int IRQ_TRANSFER_DONE = 4;

        // Register address offsets
        localparam logic [7:0] OFF_CTRL     = 8'h00;
        localparam logic [7:0] OFF_STATUS   = 8'h04;
        localparam logic [7:0] OFF_TX_DATA  = 8'h08;
        localparam logic [7:0] OFF_RX_DATA  = 8'h0C;
        localparam logic [7:0] OFF_CLK_DIV  = 8'h10;
        localparam logic [7:0] OFF_SS_CTRL  = 8'h14;
        localparam logic [7:0] OFF_INT_EN   = 8'h18;
        localparam logic [7:0] OFF_INT_STAT = 8'h1C;
        localparam logic [7:0] OFF_DELAY    = 8'h20;

        // -----------------------------------------------------------------------
        // Constructor
        // -----------------------------------------------------------------------
        function new(string name = "apb_scoreboard", uvm_component parent = null);
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
        // Helper: full reset (mirrors RTL reset)
        // -----------------------------------------------------------------------
        function void do_reset();
            int i;
            r_ctrl_en        = 1'b0;
            r_ctrl_mstr      = 1'b0;
            r_ctrl_mode      = 2'b00;
            r_ctrl_lsb_first = 1'b0;
            r_ctrl_loopback  = 1'b0;
            r_ctrl_width     = 2'b00;
            r_clk_div        = 16'h0;
            r_ss_en          = 4'h0;
            r_ss_val         = 4'h0;
            r_int_en         = 5'h0;
            r_int_stat       = 5'h0;
            r_delay_cfg      = 8'h0;
            tx_wp = '0; tx_rp = '0;
            rx_wp = '0; rx_rp = '0;
            for (i = 0; i < FIFO_DEPTH; i++) begin
                tx_mem[i] = 32'h0;
                rx_mem[i] = 32'h0;
            end
        endfunction

        // -----------------------------------------------------------------------
        // Helper: flush FIFOs when ctrl_en goes low
        // -----------------------------------------------------------------------
        function void flush_fifos();
            tx_wp = '0; tx_rp = '0;
            rx_wp = '0; rx_rp = '0;
        endfunction

        // -----------------------------------------------------------------------
        // Run phase
        // -----------------------------------------------------------------------
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            do_reset();

            forever begin
                sb_fifo.get(sb_seq_item);

                begin : predict_block
                    // -----------------------------------------------------------
                    // ALL local declarations FIRST - Questa requires this
                    // -----------------------------------------------------------
                    logic apb_access, apb_write, apb_read;
                    logic [FIFO_AW:0] tx_count_w, rx_count_w;
                    logic tx_full_w, tx_empty_w, rx_full_w, rx_empty_w;
                    logic        tx_push_valid;
                    logic [31:0] tx_push_data;
                    logic tx_push_accepted, tx_push_dropped;
                    logic rx_pop_this_cycle;
                    logic pred_pready, pred_pslverr;
                    logic        pred_cfg_en, pred_cfg_mstr;
                    logic        pred_cfg_lsb_first, pred_cfg_loopback;
                    logic [1:0]  pred_cfg_mode, pred_cfg_width;
                    logic [7:0]  pred_cfg_delay;
                    logic [15:0] pred_cfg_clk_div;
                    logic [31:0] pred_tx_word;
                    logic        pred_tx_empty;
                    logic [3:0]  pred_ss_n;
                    logic        pred_irq;
                    logic [31:0] pred_prdata;

                    // -----------------------------------------------------------
                    // Statements begin here
                    // -----------------------------------------------------------

                    // APB handshake decode
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
                    tx_push_valid = 1'b0;
                    tx_push_data  = 32'h0;
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

                    // RX pop decode
                    rx_pop_this_cycle = apb_read &&
                                        (sb_seq_item.paddr == OFF_RX_DATA) &&
                                        !rx_empty_w;

                    // Predicted outputs
                    pred_pready      = 1'b1;
                    pred_pslverr     = 1'b0;
                    pred_cfg_en        = r_ctrl_en;
                    pred_cfg_mstr      = r_ctrl_mstr;
                    pred_cfg_lsb_first = r_ctrl_lsb_first;
                    pred_cfg_loopback  = r_ctrl_loopback;
                    pred_cfg_mode      = r_ctrl_mode;
                    pred_cfg_width     = r_ctrl_width;
                    pred_cfg_delay     = r_delay_cfg;
                    pred_cfg_clk_div   = r_clk_div;
                    pred_tx_word       = tx_mem[tx_rp[FIFO_AW-1:0]];
                    pred_tx_empty      = tx_empty_w;
                    pred_ss_n          = ~r_ss_en | r_ss_val;
                    pred_irq           = |(r_int_stat & r_int_en);

                    // PRDATA mux
                    pred_prdata = 32'h0;
                    if (apb_read) begin
                        case (sb_seq_item.paddr)
                            OFF_CTRL:     pred_prdata = {24'b0,
                                                         r_ctrl_width,
                                                         r_ctrl_loopback,
                                                         r_ctrl_lsb_first,
                                                         r_ctrl_mode,
                                                         r_ctrl_mstr,
                                                         r_ctrl_en};
                            OFF_STATUS:   pred_prdata = {25'b0,
                                                         r_int_stat[IRQ_RX_OVF],
                                                         r_int_stat[IRQ_TX_OVF],
                                                         rx_empty_w,
                                                         rx_full_w,
                                                         tx_empty_w,
                                                         tx_full_w,
                                                         sb_seq_item.busy_in};
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
                    // Compare predicted vs observed outputs
                    // ==============================================================
                    check_output("pready",        pred_pready,        sb_seq_item.pready);
                    check_output("pslverr",        pred_pslverr,       sb_seq_item.pslverr);
                    check_output("cfg_en",         pred_cfg_en,        sb_seq_item.cfg_en);
                    check_output("cfg_mstr",       pred_cfg_mstr,      sb_seq_item.cfg_mstr);
                    check_output("cfg_lsb_first",  pred_cfg_lsb_first, sb_seq_item.cfg_lsb_first);
                    check_output("cfg_loopback",   pred_cfg_loopback,  sb_seq_item.cfg_loopback);
                    check_output2("cfg_mode",      pred_cfg_mode,      sb_seq_item.cfg_mode);
                    check_output2("cfg_width",     pred_cfg_width,     sb_seq_item.cfg_width);
                    check_output4("ss_n",          pred_ss_n,          sb_seq_item.ss_n);
                    check_output8("cfg_delay",     pred_cfg_delay,     sb_seq_item.cfg_delay);
                    check_output16("cfg_clk_div",  pred_cfg_clk_div,   sb_seq_item.cfg_clk_div);
                    check_output32("tx_word",      pred_tx_word,       sb_seq_item.tx_word);
                    check_output32("prdata",       pred_prdata,        sb_seq_item.prdata);
                    check_output("tx_empty",       pred_tx_empty,      sb_seq_item.tx_empty);
                    check_output("irq",            pred_irq,           sb_seq_item.irq);

                    if (error_count == 0)
                        `uvm_info("SB",
                            $sformatf("[PASS] %s", sb_seq_item.convert2string()),
                            UVM_HIGH)

                    // ==============================================================
                    // Advance golden model state (clocked updates)
                    // ==============================================================
                    if (!sb_seq_item.presetn) begin
                        do_reset();
                    end else begin
                        if (!r_ctrl_en) flush_fifos();

                        // Config register writes
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

                        // INT_STAT: W1C + new events (R18 priority chain)
                        begin : int_stat_update
                            // Declarations first
                            logic [4:0] next_stat;
                            // Statements
                            next_stat = r_int_stat;
                            if (apb_write && sb_seq_item.paddr == OFF_INT_STAT)
                                next_stat = next_stat & ~sb_seq_item.pwdata[4:0];
                            if (tx_push_dropped)
                                next_stat[IRQ_TX_OVF] = 1'b1;
                            if (sb_seq_item.rx_push_valid && rx_full_w)
                                next_stat[IRQ_RX_OVF] = 1'b1;
                            if (sb_seq_item.rx_push_valid && !rx_full_w &&
                                (rx_count_w == (FIFO_DEPTH - 1)))
                                next_stat[IRQ_RX_FULL] = 1'b1;
                            if (sb_seq_item.tx_pop && (tx_count_w == 1))
                                next_stat[IRQ_TX_EMPTY] = 1'b1;
                            if (sb_seq_item.transfer_done_pulse)
                                next_stat[IRQ_TRANSFER_DONE] = 1'b1;
                            r_int_stat = next_stat;
                        end

                        // TX FIFO update
                        if (r_ctrl_en) begin
                            if (tx_push_accepted) begin
                                tx_mem[tx_wp[FIFO_AW-1:0]] = tx_push_data;
                                tx_wp = tx_wp + 1'b1;
                            end
                            if (sb_seq_item.tx_pop)
                                tx_rp = tx_rp + 1'b1;
                        end

                        // RX FIFO update
                        if (r_ctrl_en) begin
                            if (sb_seq_item.rx_push_valid && !rx_full_w) begin
                                rx_mem[rx_wp[FIFO_AW-1:0]] = sb_seq_item.rx_push_data;
                                rx_wp = rx_wp + 1'b1;
                            end
                            if (rx_pop_this_cycle)
                                rx_rp = rx_rp + 1'b1;
                        end

                    end // !reset

                end : predict_block
            end // forever
        endtask

        // -----------------------------------------------------------------------
        // Comparison helpers
        // -----------------------------------------------------------------------
        task check_output(input string sig_name,
                          input logic  pred,
                          input logic  obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=%0b  observed=%0b",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check_output2(input string sig_name,
                           input logic [1:0] pred,
                           input logic [1:0] obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=%02b  observed=%02b",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check_output4(input string sig_name,
                           input logic [3:0] pred,
                           input logic [3:0] obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%01h  observed=0x%01h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check_output8(input string sig_name,
                           input logic [7:0] pred,
                           input logic [7:0] obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%02h  observed=0x%02h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check_output16(input string sig_name,
                            input logic [15:0] pred,
                            input logic [15:0] obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%04h  observed=0x%04h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        task check_output32(input string sig_name,
                            input logic [31:0] pred,
                            input logic [31:0] obs);
            if (pred !== obs) begin
                `uvm_error("SB",
                    $sformatf("[MISMATCH] %-20s  predicted=0x%08h  observed=0x%08h",
                              sig_name, pred, obs))
                error_count++;
            end else
                correct_count++;
        endtask

        // -----------------------------------------------------------------------
        // Report phase
        // -----------------------------------------------------------------------
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SB",
                $sformatf("============================================================\n"
                          +"  SCOREBOARD SUMMARY\n"
                          +"  Total checks passed : %0d\n"
                          +"  Total mismatches    : %0d\n"
                          +"============================================================",
                          correct_count, error_count),
                UVM_MEDIUM)
            if (error_count != 0)
                `uvm_error("SB",
                    $sformatf("TEST FAILED - %0d mismatch(es) detected.", error_count))
            else
                `uvm_info("SB",
                    "TEST PASSED - all predictions matched DUT outputs.",
                    UVM_MEDIUM)
        endfunction

    endclass

endpackage
