`default_nettype none
`timescale 1ns/1ps

// =============================================================================
// spi_core_rm.sv (Reference Model)
// -----------------------------------------------------------------------------
// Simulation-only behavioral predictor for the SPI Shift Engine.
// Designed to be instantiated in a testbench/scoreboard to predict cycle-accurate
// SCLK, MOSI, busy, pop, and push signals.
// =============================================================================

module spi_core_rm (
    input  wire         PCLK,
    input  wire         PRESETn,

    // Configuration
    input  wire         cfg_en,
    input  wire         cfg_mstr,
    input  wire [1:0]   cfg_mode,
    input  wire         cfg_lsb_first,
    input  wire         cfg_loopback,
    input  wire [1:0]   cfg_width,
    input  wire [15:0]  cfg_clk_div,
    input  wire [7:0]   cfg_delay,

    // SS observation
    input  wire [3:0]   ss_n_drive,

    // TX FIFO
    input  wire [31:0]  tx_word,
    input  wire         tx_empty,
    output logic        tx_pop,

    // RX FIFO
    output logic        rx_push_valid,
    output logic [31:0] rx_push_data,

    // Status
    output logic        busy,
    output logic        transfer_done_pulse,

    // SPI pins
    output logic        SCLK,
    output logic        MOSI,
    input  wire         MISO
);

    // -------------------------------------------------------------------------
    // Abstract Behavioral State Machine
    // -------------------------------------------------------------------------
    typedef enum int {
        RM_IDLE, 
        RM_SHIFT, 
        RM_FINISH, 
        RM_GAP
    } rm_state_e;

    rm_state_e state;

    // Latched configurations for the active transfer
    logic [1:0]  xfer_mode;
    logic        xfer_lsb_first;
    logic [1:0]  xfer_width;
    int          xfer_div;      // Using int for simulation ease
    int          half_period;

    // Internal trackers
    logic [31:0] sh_tx;
    logic [31:0] sh_rx;
    int          bit_cnt;
    int          sclk_cnt;
    int          gap_cnt;
    bit          sclk_phase;

    // Derived abstract parameters
    int  total_bits;
    wire miso_eff = cfg_loopback ? MOSI : MISO;
    
    // Continuous assignment for busy flag
    assign busy = (state != RM_IDLE);

    // -------------------------------------------------------------------------
    // Behavioral Execution (Cycle-Accurate)
    // -------------------------------------------------------------------------
    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state               <= RM_IDLE;
            SCLK                <= 1'b0;
            MOSI                <= 1'b0;
            sh_tx               <= 32'h0;
            sh_rx               <= 32'h0;
            bit_cnt             <= 0;
            sclk_cnt            <= 0;
            sclk_phase          <= 0;
            gap_cnt             <= 0;
            xfer_mode           <= 2'b00;
            xfer_lsb_first      <= 1'b0;
            xfer_width          <= 2'b00;
            xfer_div            <= 0;
            half_period         <= 0;
            total_bits          <= 0;
            
            tx_pop              <= 1'b0;
            rx_push_valid       <= 1'b0;
            rx_push_data        <= 32'h0;
            transfer_done_pulse <= 1'b0;
            
        end else begin
            // Default pulse clears
            tx_pop              <= 1'b0;
            rx_push_valid       <= 1'b0;
            transfer_done_pulse <= 1'b0;

            if (!cfg_en) begin
                // IP Disabled: reset to idle and drive SCLK to current CPOL
                state      <= RM_IDLE;
                SCLK       <= cfg_mode[1]; 
                MOSI       <= 1'b0;
                sclk_cnt   <= 0;
                sclk_phase <= 0;
                gap_cnt    <= 0;
                
            end else begin
                case (state)
                    
                    // =========================================================
                    RM_IDLE: begin
                        SCLK <= cfg_mode[1]; // Hold SCLK at CPOL
                        
                        // Condition to begin transfer
                        if (!tx_empty && cfg_mstr && (ss_n_drive != 4'hF)) begin
                            // Latch configuration (Rule R25)
                            xfer_mode      <= cfg_mode;
                            xfer_lsb_first <= cfg_lsb_first;
                            xfer_width     <= cfg_width;
                            xfer_div       <= cfg_clk_div;
                            half_period    <= cfg_clk_div + 1;
                            
                            // Determine bit width cleanly
                            total_bits <= (cfg_width == 2'b00) ? 8 :
                                          (cfg_width == 2'b01) ? 16 : 32;
                            bit_cnt    <= (cfg_width == 2'b00) ? 8 :
                                          (cfg_width == 2'b01) ? 16 : 32;

                            sh_tx  <= tx_word;
                            tx_pop <= 1'b1; // Pulse TX pop

                            sclk_cnt   <= 0;
                            sclk_phase <= 0;
                            sh_rx      <= 32'h0;

                            // CPHA=0: Drive the very first bit immediately
                            if (cfg_mode[0] == 1'b0) begin
                                int start_idx = cfg_lsb_first ? 0 : 
                                                ((cfg_width == 2'b00) ? 7 :
                                                 (cfg_width == 2'b01) ? 15 : 31);
                                MOSI <= tx_word[start_idx];
                            end

                            state <= RM_SHIFT;
                        end
                    end

                    // =========================================================
                    RM_SHIFT: begin
                        if (sclk_cnt == half_period - 1) begin
                            sclk_cnt   <= 0;
                            sclk_phase <= ~sclk_phase;
                            SCLK       <= ~SCLK;

                            // Behavioral edge classification
                            // sclk_phase == 0 means we are transitioning to the leading edge
                            // sclk_phase == 1 means we are transitioning to the trailing edge
                            begin : edge_evaluation
                                bit is_sample_edge;
                                bit is_launch_edge;
                                
                                is_sample_edge = (xfer_mode[0] == 1'b0) ? (sclk_phase == 0) : (sclk_phase == 1);
                                is_launch_edge = !is_sample_edge;

                                // --- SAMPLE BEHAVIOR ---
                                if (is_sample_edge) begin
                                    if (xfer_lsb_first) begin
                                        sh_rx[total_bits - bit_cnt] <= miso_eff;
                                    end else begin
                                        sh_rx[bit_cnt - 1] <= miso_eff;
                                    end

                                    // If this is the last bit being sampled, move to FINISH
                                    if (bit_cnt == 1) begin
                                        state <= RM_FINISH;
                                    end
                                    bit_cnt <= bit_cnt - 1;
                                end

                                // --- LAUNCH BEHAVIOR ---
                                if (is_launch_edge) begin
                                    if (bit_cnt > 0) begin
                                        int next_idx = xfer_lsb_first ? (total_bits - bit_cnt) : (bit_cnt - 1);
                                        MOSI <= sh_tx[next_idx];
                                    end
                                end

                                // --- CPHA=1 SPECIAL CASE ---
                                // Launch the first bit on the very first edge (which is the leading edge)
                                if (xfer_mode[0] == 1'b1 && sclk_phase == 0 && bit_cnt == total_bits) begin
                                    int first_idx = xfer_lsb_first ? 0 : (total_bits - 1);
                                    MOSI <= sh_tx[first_idx];
                                end
                            end
                        end else begin
                            sclk_cnt <= sclk_cnt + 1;
                        end
                    end

                    // =========================================================
                    RM_FINISH: begin
                        if (sclk_cnt == half_period - 1) begin
                            sclk_cnt   <= 0;
                            SCLK       <= xfer_mode[1]; // Return to CPOL
                            sclk_phase <= 0;

                            // Formulate the padded RX payload
                            rx_push_valid <= 1'b1;
                            transfer_done_pulse <= 1'b1;
                            
                            if (total_bits == 32)
                                rx_push_data <= sh_rx;
                            else
                                rx_push_data <= sh_rx & ((32'h1 << total_bits) - 1);

                            // Determine if we gap or idle
                            if (!tx_empty && cfg_delay != 0) begin
                                gap_cnt <= cfg_delay;
                                state   <= RM_GAP;
                            end else begin
                                state   <= RM_IDLE;
                            end
                        end else begin
                            sclk_cnt <= sclk_cnt + 1;
                        end
                    end

                    // =========================================================
                    RM_GAP: begin
                        SCLK <= xfer_mode[1]; // Hold SCLK at CPOL
                        if (sclk_cnt == half_period - 1) begin
                            sclk_cnt <= 0;
                            if (gap_cnt == 1) begin
                                state <= RM_IDLE;
                            end
                            gap_cnt <= gap_cnt - 1;
                        end else begin
                            sclk_cnt <= sclk_cnt + 1;
                        end
                    end
                    
                    default: state <= RM_IDLE;
                endcase
            end
        end
    end
endmodule
`default_nettype wire