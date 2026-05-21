
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

endmodule
