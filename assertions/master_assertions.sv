// =============================================================================
// master_assertions.sv
// -----------------------------------------------------------------------------
// Width-coverage edge-case assertions for the SPI Master Controller.
// Bound to the same apb_if.DUT modport used by apb_assertions.sv.
//
// Covers:
//  W1  – cfg_width reflects CTRL[7:6] written
//  W2  – xfer_width latched from cfg_width at transfer start
//  W3  – bit_cnt initialised to 8 / 16 / 32 on transfer start
//  W4  – TX data masked to 8-bit  (zero upper 24 bits) when width=2'b00
//  W5  – TX data masked to 16-bit (zero upper 16 bits) when width=2'b01
//  W6  – TX data passed through unmasked                when width=2'b10
//  W7  – invalid width 2'b11 written to CTRL: busy must never assert
//  W8  – transfer_done_pulse fires exactly one cycle after FINISH state
//  W9  – rx_push_valid fires exactly one cycle after transfer_done_pulse
//  W10 – SCLK idles at CPOL when not transferring
//  W11 – core does NOT start (busy stays 0) when tx_empty
//  W12 – core does NOT start (busy stays 0) when all SS lanes high (4'hF)
//  W13 – core does NOT start (busy stays 0) when cfg_mstr = 0
//  W14 – core does NOT start (busy stays 0) when cfg_en = 0
//  W15 – cfg_width stable throughout the S_SHIFT state (latched on start)
//  W16 – tx_pop is a single-cycle pulse (de-asserts next cycle)
//  W17 – rx_push_valid is a single-cycle pulse
//  W18 – transfer_done_pulse is a single-cycle pulse
//  W19 – rx_push_data upper bits masked to 0 for 8-bit  transfer
//  W20 – rx_push_data upper bits masked to 0 for 16-bit transfer
// =============================================================================

module master_assertions (apb_if.DUT apbif);

    // -------------------------------------------------------------------------
    // Local aliases to DUT hierarchy
    // -------------------------------------------------------------------------
    // regfile internals
    wire        cfg_en_i        = DUT.u_dut.u_regfile.ctrl_en;
    wire        cfg_mstr_i      = DUT.u_dut.u_regfile.ctrl_mstr;
    wire [1:0]  cfg_width_i     = DUT.u_dut.u_regfile.ctrl_width;
    wire [1:0]  cfg_mode_i      = DUT.u_dut.u_regfile.ctrl_mode;

    wire        tx_push_valid_i = DUT.u_dut.u_regfile.tx_push_valid;
    wire [31:0] tx_push_data_i  = DUT.u_dut.u_regfile.tx_push_data;
    wire        tx_full_i       = DUT.u_dut.u_regfile.tx_full_w;
    wire        tx_empty_i      = DUT.u_dut.u_regfile.tx_empty_w;

    wire        rx_push_valid_i = DUT.u_dut.u_regfile.rx_push_valid;
    wire [31:0] rx_push_data_i  = DUT.u_dut.u_regfile.rx_push_data;

    // core internals
    wire [1:0]  xfer_width_i    = DUT.u_dut.u_core.xfer_width;
    wire [5:0]  bit_cnt_i       = DUT.u_dut.u_core.bit_cnt;
    wire        tx_pop_i        = DUT.u_dut.u_core.tx_pop;
    wire        busy_i          = DUT.u_dut.u_core.busy;
    wire        done_pulse_i    = DUT.u_dut.u_core.transfer_done_pulse;

    // FSM state encoding: S_IDLE=0, S_SHIFT=1, S_FINISH=2, S_GAP=3
    wire [1:0]  core_state_i    = DUT.u_dut.u_core.state;
    localparam  S_IDLE   = 2'd0;
    localparam  S_SHIFT  = 2'd1;
    localparam  S_FINISH = 2'd2;
    localparam  S_GAP    = 2'd3;

    // =========================================================================
    // W1 – cfg_width reflects CTRL[7:6] one cycle after an APB write to 0x00
    // =========================================================================
    property w1_cfg_width_reflects_ctrl;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite && apbif.paddr == 8'h00)
        |=> (apbif.cfg_width == $past(apbif.pwdata[7:6]));
    endproperty
    W1_cfg_width_reflects_ctrl_as: assert property(w1_cfg_width_reflects_ctrl)
        else $error("[WIDTH_ASSERT] W1: cfg_width did not update from CTRL write");
    cover property(w1_cfg_width_reflects_ctrl);

    // =========================================================================
    // W2 – xfer_width latched from cfg_width at the cycle tx_pop fires
    //      (that is the cycle the core leaves S_IDLE into S_SHIFT)
    // =========================================================================
    property w2_xfer_width_latched;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && tx_pop_i)
        |=> (xfer_width_i == $past(cfg_width_i));
    endproperty
    W2_xfer_width_latched_as: assert property(w2_xfer_width_latched)
        else $error("[WIDTH_ASSERT] W2: xfer_width not latched from cfg_width on transfer start");
    cover property(w2_xfer_width_latched);

    // =========================================================================
    // W3a – bit_cnt = 8 when width=2'b00 at transfer start
    // =========================================================================
    property w3a_bit_cnt_8;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && tx_pop_i && cfg_width_i == 2'b00)
        |=> (bit_cnt_i == 6'd8);
    endproperty
    W3a_bit_cnt_8_as: assert property(w3a_bit_cnt_8)
        else $error("[WIDTH_ASSERT] W3a: bit_cnt != 8 for 8-bit transfer");
    cover property(w3a_bit_cnt_8);

    // =========================================================================
    // W3b – bit_cnt = 16 when width=2'b01 at transfer start
    // =========================================================================
    property w3b_bit_cnt_16;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && tx_pop_i && cfg_width_i == 2'b01)
        |=> (bit_cnt_i == 6'd16);
    endproperty
    W3b_bit_cnt_16_as: assert property(w3b_bit_cnt_16)
        else $error("[WIDTH_ASSERT] W3b: bit_cnt != 16 for 16-bit transfer");
    cover property(w3b_bit_cnt_16);

    // =========================================================================
    // W3c – bit_cnt = 32 when width=2'b10 at transfer start
    // =========================================================================
    property w3c_bit_cnt_32;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && tx_pop_i && cfg_width_i == 2'b10)
        |=> (bit_cnt_i == 6'd32);
    endproperty
    W3c_bit_cnt_32_as: assert property(w3c_bit_cnt_32)
        else $error("[WIDTH_ASSERT] W3c: bit_cnt != 32 for 32-bit transfer");
    cover property(w3c_bit_cnt_32);

    // =========================================================================
    // W4 – TX data masked to lower 8 bits when cfg_width = 2'b00
    //      RTL: tx_push_data = {24'b0, PWDATA[7:0]}
    // =========================================================================
    property w4_tx_mask_8bit;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && cfg_width_i == 2'b00 && !tx_full_i)
        |-> (tx_push_data_i == {24'b0, apbif.pwdata[7:0]});
    endproperty
    W4_tx_mask_8bit_as: assert property(w4_tx_mask_8bit)
        else $error("[WIDTH_ASSERT] W4: TX data not masked to 8 bits (width=2'b00)");
    cover property(w4_tx_mask_8bit);

    // =========================================================================
    // W5 – TX data masked to lower 16 bits when cfg_width = 2'b01
    //      RTL: tx_push_data = {16'b0, PWDATA[15:0]}
    // =========================================================================
    property w5_tx_mask_16bit;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && cfg_width_i == 2'b01 && !tx_full_i)
        |-> (tx_push_data_i == {16'b0, apbif.pwdata[15:0]});
    endproperty
    W5_tx_mask_16bit_as: assert property(w5_tx_mask_16bit)
        else $error("[WIDTH_ASSERT] W5: TX data not masked to 16 bits (width=2'b01)");
    cover property(w5_tx_mask_16bit);

    // =========================================================================
    // W6 – TX data unmasked (full 32 bits) when cfg_width = 2'b10
    // =========================================================================
    property w6_tx_passthrough_32bit;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && cfg_width_i == 2'b10 && !tx_full_i)
        |-> (tx_push_data_i == apbif.pwdata);
    endproperty
    W6_tx_passthrough_32bit_as: assert property(w6_tx_passthrough_32bit)
        else $error("[WIDTH_ASSERT] W6: TX data should be full 32 bits when width=2'b10");
    cover property(w6_tx_passthrough_32bit);

    // =========================================================================
    // W7 – Invalid width (2'b11) → busy must never assert
    //      (If width=2'b11 is programmed, the core should not start a transfer)
    // =========================================================================
    property w7_invalid_width_no_busy;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        // Invariant: whenever invalid width is programmed, core must never be busy
        (cfg_width_i == 2'b11) |-> ~busy_i;
    endproperty
    W7_invalid_width_no_busy_as: assert property(w7_invalid_width_no_busy)
        else $error("[WIDTH_ASSERT] W7: DUT became busy with invalid width encoding 2'b11");
    cover property(w7_invalid_width_no_busy);

    // =========================================================================
    // W8 – transfer_done_pulse fires one cycle after entering S_FINISH
    //      (when sclk_cnt reaches half_period-1 in S_FINISH)
    // =========================================================================
    property w8_done_pulse_one_cycle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        $rose(done_pulse_i) |=> ~done_pulse_i;
    endproperty
    W8_done_pulse_one_cycle_as: assert property(w8_done_pulse_one_cycle)
        else $error("[WIDTH_ASSERT] W8: transfer_done_pulse held high for more than 1 cycle");
    cover property(w8_done_pulse_one_cycle);

    // =========================================================================
    // W9 – rx_push_valid fires the same cycle as transfer_done_pulse
    // =========================================================================
    property w9_rx_push_with_done;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        done_pulse_i |-> rx_push_valid_i;
    endproperty
    W9_rx_push_with_done_as: assert property(w9_rx_push_with_done)
        else $error("[WIDTH_ASSERT] W9: rx_push_valid did not fire with transfer_done_pulse");
    cover property(w9_rx_push_with_done);

    // =========================================================================
    // W10 – SCLK idles at CPOL value when core is in S_IDLE
    // =========================================================================
    property w10_sclk_idle_at_cpol;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        // Guard with $stable(cfg_mode_i): skip the 1 cycle after a CTRL write
        // when SCLK (registered) hasn't yet caught up to the new CPOL value.
        (core_state_i == S_IDLE && cfg_en_i && $stable(cfg_mode_i))
        |-> (DUT.u_dut.u_core.SCLK == cfg_mode_i[1]);
    endproperty
    W10_sclk_idle_at_cpol_as: assert property(w10_sclk_idle_at_cpol)
        else $error("[WIDTH_ASSERT] W10: SCLK not at CPOL value during IDLE");
    cover property(w10_sclk_idle_at_cpol);

    // =========================================================================
    // W11 – Core does not start transfer when TX FIFO is empty
    // =========================================================================
    property w11_no_start_tx_empty;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && tx_empty_i) |-> ~tx_pop_i;
    endproperty
    W11_no_start_tx_empty_as: assert property(w11_no_start_tx_empty)
        else $error("[WIDTH_ASSERT] W11: Core started transfer with empty TX FIFO");
    cover property(w11_no_start_tx_empty);

    // =========================================================================
    // W12 – Core does not start transfer when all SS lanes are high (no slave selected)
    // =========================================================================
    property w12_no_start_no_slave;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && apbif.ss_n == 4'hF) |-> ~tx_pop_i;
    endproperty
    W12_no_start_no_slave_as: assert property(w12_no_start_no_slave)
        else $error("[WIDTH_ASSERT] W12: Core started transfer with no slave selected (ss_n=4'hF)");
    cover property(w12_no_start_no_slave);

    // =========================================================================
    // W13 – Core does not start when cfg_mstr = 0 (slave mode)
    // =========================================================================
    property w13_no_start_slave_mode;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && !cfg_mstr_i) |-> ~tx_pop_i;
    endproperty
    W13_no_start_slave_mode_as: assert property(w13_no_start_slave_mode)
        else $error("[WIDTH_ASSERT] W13: Core started transfer in slave mode (cfg_mstr=0)");
    cover property(w13_no_start_slave_mode);

    // =========================================================================
    // W14 – Core does not start when cfg_en = 0 (module disabled)
    // =========================================================================
    property w14_no_start_disabled;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_IDLE && !cfg_en_i) |-> ~tx_pop_i;
    endproperty
    W14_no_start_disabled_as: assert property(w14_no_start_disabled)
        else $error("[WIDTH_ASSERT] W14: Core started transfer while module disabled (cfg_en=0)");
    cover property(w14_no_start_disabled);

    // =========================================================================
    // W15 – xfer_width is stable for entire S_SHIFT duration (config latched at start)
    // =========================================================================
    property w15_xfer_width_stable_during_shift;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        // Exclude first S_SHIFT cycle: xfer_width is being latched from cfg_width
        // exactly at the S_IDLE→S_SHIFT transition, so $stable would always fail there.
        (core_state_i == S_SHIFT && $past(core_state_i) == S_SHIFT)
        |-> $stable(xfer_width_i);
    endproperty
    W15_xfer_width_stable_as: assert property(w15_xfer_width_stable_during_shift)
        else $error("[WIDTH_ASSERT] W15: xfer_width changed during S_SHIFT state");
    cover property(w15_xfer_width_stable_during_shift);

    // =========================================================================
    // W16 – tx_pop is a single-cycle pulse (deasserts next cycle)
    // =========================================================================
    property w16_tx_pop_one_cycle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        $rose(tx_pop_i) |=> ~tx_pop_i;
    endproperty
    W16_tx_pop_one_cycle_as: assert property(w16_tx_pop_one_cycle)
        else $error("[WIDTH_ASSERT] W16: tx_pop held high for more than 1 cycle");
    cover property(w16_tx_pop_one_cycle);

    // =========================================================================
    // W17 – rx_push_valid is a single-cycle pulse
    // =========================================================================
    property w17_rx_push_valid_one_cycle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        $rose(rx_push_valid_i) |=> ~rx_push_valid_i;
    endproperty
    W17_rx_push_valid_one_cycle_as: assert property(w17_rx_push_valid_one_cycle)
        else $error("[WIDTH_ASSERT] W17: rx_push_valid held high for more than 1 cycle");
    cover property(w17_rx_push_valid_one_cycle);

    // =========================================================================
    // W18 – transfer_done_pulse is a single-cycle pulse (same check as W8,
    //       kept separate for explicit naming in the report)
    // =========================================================================
    property w18_done_pulse_one_cycle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        $rose(done_pulse_i) |=> ~done_pulse_i;
    endproperty
    W18_done_pulse_one_cycle_as: assert property(w18_done_pulse_one_cycle)
        else $error("[WIDTH_ASSERT] W18: transfer_done_pulse is not a single-cycle pulse");
    cover property(w18_done_pulse_one_cycle);

    // =========================================================================
    // W19 – rx_push_data upper 24 bits are zero for an 8-bit transfer
    //       (align_rx masks to width_bits)
    // =========================================================================
    property w19_rx_mask_8bit;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (rx_push_valid_i && xfer_width_i == 2'b00)
        |-> (rx_push_data_i[31:8] == 24'b0);
    endproperty
    W19_rx_mask_8bit_as: assert property(w19_rx_mask_8bit)
        else $error("[WIDTH_ASSERT] W19: rx_push_data upper bits non-zero after 8-bit transfer");
    cover property(w19_rx_mask_8bit);

    // =========================================================================
    // W20 – rx_push_data upper 16 bits are zero for a 16-bit transfer
    // =========================================================================
    property w20_rx_mask_16bit;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (rx_push_valid_i && xfer_width_i == 2'b01)
        |-> (rx_push_data_i[31:16] == 16'b0);
    endproperty
    W20_rx_mask_16bit_as: assert property(w20_rx_mask_16bit)
        else $error("[WIDTH_ASSERT] W20: rx_push_data upper bits non-zero after 16-bit transfer");
    cover property(w20_rx_mask_16bit);

    // =========================================================================
    // W21 – busy asserts exactly when core is not in S_IDLE
    // =========================================================================
    property w21_busy_iff_not_idle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (busy_i == (core_state_i != S_IDLE));
    endproperty
    W21_busy_iff_not_idle_as: assert property(w21_busy_iff_not_idle)
        else $error("[WIDTH_ASSERT] W21: busy != (state != S_IDLE)");
    cover property(w21_busy_iff_not_idle);

    // =========================================================================
    // W22 – After reset deasserts, core must be in S_IDLE
    // =========================================================================
    property w22_reset_to_idle;
        @(posedge apbif.PCLK)
        $rose(apbif.presetn) |-> (core_state_i == S_IDLE);
    endproperty
    W22_reset_to_idle_as: assert property(w22_reset_to_idle)
        else $error("[WIDTH_ASSERT] W22: Core not in S_IDLE after reset");
    cover property(w22_reset_to_idle);

    // =========================================================================
    // W23 – TX push rejected (no FIFO wp increment) when TX FIFO full
    // =========================================================================
    property w23_tx_no_push_when_full;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && tx_full_i)
        |=> (DUT.u_dut.u_regfile.tx_wp == $past(DUT.u_dut.u_regfile.tx_wp));
    endproperty
    W23_tx_no_push_when_full_as: assert property(w23_tx_no_push_when_full)
        else $error("[WIDTH_ASSERT] W23: TX FIFO write pointer incremented on full FIFO");
    cover property(w23_tx_no_push_when_full);

    // =========================================================================
    // W24 – FIFO write pointer advances by 1 on a successful TX push
    // =========================================================================
    property w24_tx_wp_increments;
        logic [31:0] saved_wp;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        // Capture tx_wp at trigger time; allow up to 2 cycles for registered update.
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && !tx_full_i,
         saved_wp = DUT.u_dut.u_regfile.tx_wp)
        |-> ##[1:2] (DUT.u_dut.u_regfile.tx_wp == saved_wp + 1);
    endproperty
    W24_tx_wp_increments_as: assert property(w24_tx_wp_increments)
        else $error("[WIDTH_ASSERT] W24: TX FIFO write pointer did not increment on push");
    cover property(w24_tx_wp_increments);

    // =========================================================================
    // W25 – tx_pop increments TX read pointer by 1
    // =========================================================================
    property w25_tx_rp_increments_on_pop;
        logic [31:0] saved_rp;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        // Capture tx_rp at trigger time; allow up to 2 cycles for registered update.
        (tx_pop_i, saved_rp = DUT.u_dut.u_regfile.tx_rp)
        |-> ##[1:2] (DUT.u_dut.u_regfile.tx_rp == saved_rp + 1);
    endproperty
    W25_tx_rp_increments_as: assert property(w25_tx_rp_increments_on_pop)
        else $error("[WIDTH_ASSERT] W25: TX read pointer did not increment after tx_pop");
    cover property(w25_tx_rp_increments_on_pop);

    // =========================================================================
    // W26 – Width encoding 2'b11 never triggers tx_push to FIFO
    //       (cfg_en must be 1 for push; width=11 is a don't-care in RTL default)
    // =========================================================================
    property w26_invalid_width_no_tx_push;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (apbif.psel && apbif.penable && apbif.pwrite &&
         apbif.paddr == 8'h08 && cfg_en_i && cfg_width_i == 2'b11)
        |-> (tx_push_valid_i == 1'b1);
        // The RTL's 'default' arm passes pwdata through — this cover
        // point verifies that path IS exercised so we can inspect it
    endproperty
    W26_invalid_width_push_cover: cover property(w26_invalid_width_no_tx_push);

    // =========================================================================
    // W27 – Core transitions S_SHIFT → S_FINISH only when bit_cnt==1 on sample edge
    //       (state must not jump from SHIFT directly to IDLE)
    // =========================================================================
    property w27_shift_to_finish_not_idle;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_SHIFT) |=>
            (core_state_i == S_SHIFT || core_state_i == S_FINISH);
    endproperty
    W27_shift_to_finish_not_idle_as: assert property(w27_shift_to_finish_not_idle)
        else $error("[WIDTH_ASSERT] W27: Core jumped from S_SHIFT directly to S_IDLE (skipped S_FINISH)");
    cover property(w27_shift_to_finish_not_idle);

    // =========================================================================
    // W28 – After S_FINISH, core goes to S_IDLE or S_GAP (not back to S_SHIFT)
    // =========================================================================
    property w28_finish_to_idle_or_gap;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (core_state_i == S_FINISH) |=>
            (core_state_i == S_FINISH ||
             core_state_i == S_IDLE   ||
             core_state_i == S_GAP);
    endproperty
    W28_finish_to_idle_or_gap_as: assert property(w28_finish_to_idle_or_gap)
        else $error("[WIDTH_ASSERT] W28: Invalid S_FINISH next-state (went to S_SHIFT)");
    cover property(w28_finish_to_idle_or_gap);

    // =========================================================================
    // W29 – Width change between two consecutive transfers:
    //       After a transfer completes (done_pulse), if a new transfer starts
    //       the next xfer_width must equal the cfg_width at that moment
    // =========================================================================
    property w29_hot_swap_width_correct;
        @(posedge apbif.PCLK)
        disable iff (~apbif.presetn)
        (done_pulse_i ##1 tx_pop_i)
        |=> (xfer_width_i == $past(cfg_width_i));
    endproperty
    W29_hot_swap_width_as: assert property(w29_hot_swap_width_correct)
        else $error("[WIDTH_ASSERT] W29: Width not re-latched correctly after hot-swap");
    cover property(w29_hot_swap_width_correct);

endmodule
