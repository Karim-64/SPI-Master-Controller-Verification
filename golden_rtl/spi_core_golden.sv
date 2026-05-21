// =============================================================================
// spi_core_golden.sv
// -----------------------------------------------------------------------------
// Ain Shams University - Digital Design Verification - Spring 2026
// Final Project - SPI Master Controller, Shift / SCLK / SS engine sub-block
//
// Pure slave of apb_regfile. Consumes configuration (mode/width/div/delay/
// lsb/loopback/en/mstr/ss_en/ss_val), pops TX words from the regfile, and
// pushes RX words back. Drives SCLK/MOSI directly; SS_n is driven by the
// regfile so register readback of SS_CTRL matches what is on the pins.
//
// Contains the ST_IDLE / ST_SHIFT / ST_FINISH / ST_GAP FSM and all per-transfer
// latching required by R25 of the spec.
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module spi_core_golden (
    input  wire         PCLK,
    input  wire         PRESETn,

    // Configuration (live from regfile)
    input  wire         cfg_en,
    input  wire         cfg_mstr,
    input  wire [1:0]   cfg_mode,
    input  wire         cfg_lsb_first,
    input  wire         cfg_loopback,
    input  wire [1:0]   cfg_width,
    input  wire [15:0]  cfg_clk_div,
    input  wire [7:0]   cfg_delay,

    // SS observation: core starts only when at least one SS lane is asserted
    // low on the pins (regfile owns the final drive).
    input  wire [3:0]   ss_n_drive,

    // TX FIFO -> core
    input  wire [31:0]  tx_word,
    input  wire         tx_empty,
    output reg          tx_pop,

    // core -> RX FIFO
    output reg          rx_push_valid,
    output reg  [31:0]  rx_push_data,

    // Status
    output wire         busy,
    output reg          transfer_done_pulse,

    // SPI pins
    output reg          SCLK,
    output reg          MOSI,
    input  wire         MISO
);

    // -------------------------------------------------------------------------
    // FSM State Definition
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        ST_IDLE   = 2'd0,
        ST_SHIFT  = 2'd1,
        ST_FINISH = 2'd2,
        ST_GAP    = 2'd3
    } state_t;

    state_t curr_state;

    // Latched configuration registers
    reg [1:0]  mode_reg;
    reg        lsb_reg;
    reg [1:0]  width_reg;
    reg [15:0] div_reg;

    // Internal registers
    reg [31:0] tx_shifter;
    reg [31:0] rx_shifter;
    reg [5:0]  bit_counter;
    reg [16:0] baud_counter;
    reg [8:0]  gap_counter;
    reg        clk_phase;

    // Width mapping logic to remove duplicate ternary operations
    wire [5:0] cfg_width_bits  = (cfg_width == 2'b00) ? 6'd8  :
                                 (cfg_width == 2'b01) ? 6'd16 : 6'd32;

    wire [5:0] xfer_width_bits = (width_reg == 2'b00) ? 6'd8  :
                                 (width_reg == 2'b01) ? 6'd16 : 6'd32;

    wire cpol = mode_reg[1];
    wire cpha = mode_reg[0];

    // Since half_period = div_reg + 1, sclk_cnt == half_period - 1 is exactly sclk_cnt == div_reg.
    // Using div_reg directly saves arithmetic operations (eliminating +1 and -1).
    wire [16:0] baud_limit = {1'b0, div_reg};

    assign busy = (curr_state != ST_IDLE);

    wire miso_eff = cfg_loopback ? MOSI : MISO;

    // Direct edge detection flags using clk_phase and cpha
    wire is_sample_edge = (clk_phase == cpha);
    wire is_launch_edge = ~is_sample_edge;

    // Unified bit-index calculation for both Tx and Rx to eliminate helper function
    wire [5:0] bit_index = lsb_reg ? (xfer_width_bits - bit_counter) : (bit_counter - 6'd1);

    // -------------------------------------------------------------------------
    // FSM + datapath
    // -------------------------------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            curr_state          <= ST_IDLE;
            SCLK                <= 1'b0;
            MOSI                <= 1'b0;
            tx_shifter          <= 32'h0;
            rx_shifter          <= 32'h0;
            bit_counter         <= 6'h0;
            baud_counter        <= 17'h0;
            clk_phase           <= 1'b0;
            gap_counter         <= 9'h0;
            mode_reg            <= 2'b00;
            lsb_reg             <= 1'b0;
            width_reg           <= 2'b00;
            div_reg             <= 16'h0;
            tx_pop              <= 1'b0;
            rx_push_valid       <= 1'b0;
            rx_push_data        <= 32'h0;
            transfer_done_pulse <= 1'b0;
        end else begin
            tx_pop              <= 1'b0;
            rx_push_valid       <= 1'b0;
            transfer_done_pulse <= 1'b0;

            if (!cfg_en) begin
                curr_state   <= ST_IDLE;
                SCLK         <= cfg_mode[1];   // hold at CPOL idle
                MOSI         <= 1'b0;
                baud_counter <= 17'h0;
                clk_phase    <= 1'b0;
                gap_counter  <= 9'h0;
            end else begin
                case (curr_state)
                    // ---------------- IDLE ------------------------------------
                    ST_IDLE: begin
                        SCLK <= cfg_mode[1];
                        // Start condition: TX has data, master mode, and at
                        // least one SS lane on the pins is driven low.
                        if (!tx_empty && cfg_mstr && (ss_n_drive != 4'hF)) begin
                            // Latch config for this transfer (R25)
                            mode_reg  <= cfg_mode;
                            lsb_reg   <= cfg_lsb_first;
                            width_reg <= cfg_width;
                            div_reg   <= cfg_clk_div;

                            tx_shifter <= tx_word;
                            tx_pop     <= 1'b1;

                            bit_counter  <= cfg_width_bits;
                            baud_counter <= 17'h0;
                            clk_phase    <= 1'b0;

                            // Present first bit immediately for CPHA=0
                            if (cfg_mode[0] == 1'b0) begin
                                MOSI <= cfg_lsb_first ? tx_word[0] : tx_word[cfg_width_bits - 6'd1];
                            end
                            rx_shifter <= 32'h0;
                            curr_state <= ST_SHIFT;
                            SCLK       <= cfg_mode[1];
                        end
                    end

                    // ---------------- SHIFT -----------------------------------
                    ST_SHIFT: begin
                        if (baud_counter == baud_limit) begin
                            baud_counter <= 17'h0;
                            clk_phase    <= ~clk_phase;
                            SCLK         <= ~SCLK;

                            begin : edge_work
                                if (is_sample_edge) begin
                                    rx_shifter[bit_index] <= miso_eff;

                                    if (bit_counter == 6'd1) begin
                                        curr_state <= ST_FINISH;
                                    end
                                    bit_counter <= bit_counter - 6'd1;
                                end

                                if (is_launch_edge) begin
                                    if (bit_counter > 6'd0) begin
                                        MOSI <= tx_shifter[bit_index];
                                    end
                                end

                                // CPHA=1 first-bit-launch on very first edge (clk_phase == 0 is leading edge)
                                if (cpha == 1'b1 && ~clk_phase && bit_counter == xfer_width_bits) begin
                                    MOSI <= tx_shifter[bit_index];
                                end
                            end
                        end else begin
                            baud_counter <= baud_counter + 17'h1;
                        end
                    end

                    // ---------------- FINISH ----------------------------------
                    ST_FINISH: begin
                        if (baud_counter == baud_limit) begin
                            baud_counter <= 17'h0;
                            SCLK         <= cpol;
                            clk_phase    <= 1'b0;

                            rx_push_valid <= 1'b1;
                            rx_push_data  <= rx_shifter & ((xfer_width_bits == 6'd32) ? 32'hFFFF_FFFF :
                                                           ((32'h1 << xfer_width_bits) - 32'h1));
                            transfer_done_pulse <= 1'b1;

                            if (!tx_empty && cfg_delay != 8'h0) begin
                                gap_counter <= {1'b0, cfg_delay};
                                curr_state  <= ST_GAP;
                            end else begin
                                curr_state  <= ST_IDLE;
                            end
                        end else begin
                            baud_counter <= baud_counter + 17'h1;
                        end
                    end

                    // ---------------- GAP -------------------------------------
                    ST_GAP: begin
                        SCLK <= cpol;
                        if (baud_counter == baud_limit) begin
                            baud_counter <= 17'h0;
                            if (gap_counter == 9'h1) begin
                                curr_state <= ST_IDLE;
                            end
                            gap_counter <= gap_counter - 9'h1;
                        end else begin
                            baud_counter <= baud_counter + 17'h1;
                        end
                    end

                    default: curr_state <= ST_IDLE;
                endcase
            end
        end
    end
endmodule

`default_nettype wire
