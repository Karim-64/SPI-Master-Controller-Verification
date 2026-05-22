// =============================================================================
// apb_regfile_golden.sv
// -----------------------------------------------------------------------------
// Ain Shams University - Digital Design Verification - Spring 2026
// Final Project - SPI Master Controller, APB Slave + Register File sub-block
//
// APB v2.0 zero-wait-state slave.  Implements nine programmable registers,
// dual 8-deep x 32-bit FIFOs, W1C interrupt logic, and chip-select drive.
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

module apb_regfile_golden (
    input  wire         PCLK,
    input  wire         PRESETn,

    /* ---- APB slave bus ---- */
    input  wire         PSEL,
    input  wire         PENABLE,
    input  wire         PWRITE,
    input  wire [7:0]   PADDR,
    input  wire [31:0]  PWDATA,
    output reg  [31:0]  PRDATA,
    output wire         PREADY,
    output wire         PSLVERR,

    /* ---- SPI core configuration ---- */
    output wire         cfg_en,
    output wire         cfg_mstr,
    output wire [1:0]   cfg_mode,
    output wire         cfg_lsb_first,
    output wire         cfg_loopback,
    output wire [1:0]   cfg_width,
    output wire [15:0]  cfg_clk_div,
    output wire [7:0]   cfg_delay,

    /* ---- Chip-select outputs ---- */
    output wire [3:0]   SS_n,

    /* ---- TX FIFO to core ---- */
    output wire [31:0]  tx_word,
    output wire         tx_empty,
    input  wire         tx_pop,

    /* ---- RX FIFO from core ---- */
    input  wire         rx_push_valid,
    input  wire [31:0]  rx_push_data,

    /* ---- Core status ---- */
    input  wire         busy_in,
    input  wire         transfer_done_pulse,

    /* ---- Interrupt line ---- */
    output wire         IRQ
);


    localparam [7:0]
        ADDR_CTRL     = 8'h00,
        ADDR_STATUS   = 8'h04,
        ADDR_TX       = 8'h08,
        ADDR_RX       = 8'h0C,
        ADDR_BAUDIV   = 8'h10,
        ADDR_CS_CTRL  = 8'h14,
        ADDR_IRQ_MASK = 8'h18,
        ADDR_IRQ_STAT = 8'h1C,
        ADDR_DELAY    = 8'h20;

    /* IRQ bit positions */
    localparam integer
        BIT_TX_MT   = 0,   // TX became empty
        BIT_RX_FULL = 1,   // RX became full
        BIT_TX_OVF  = 2,   // TX overflow (write to full)
        BIT_RX_OVF  = 3,   // RX overflow (push to full)
        BIT_DONE    = 4,   // Transfer complete
        NUM_IRQ     = 5;

    localparam integer DEPTH = 8;
    localparam integer PW    = 3;   // pointer width = log2(DEPTH)

    /* TX FIFO */
    reg [31:0]    tx_ram  [0:DEPTH-1];
    reg [PW:0]    wr_tx,  rd_tx;
    wire [PW:0]   tx_lvl  = wr_tx - rd_tx;
    wire          tx_afull  = (tx_lvl == DEPTH);
    wire          tx_aempty = (tx_lvl == 0);

    /* RX FIFO */
    reg [31:0]    rx_ram  [0:DEPTH-1];
    reg [PW:0]    wr_rx,  rd_rx;
    wire [PW:0]   rx_lvl  = wr_rx - rd_rx;
    wire          rx_afull  = (rx_lvl == DEPTH);
    wire          rx_aempty = (rx_lvl == 0);

    /* TX FIFO head exposed to core */
    assign tx_empty = tx_aempty;
    assign tx_word  = tx_ram[rd_tx[PW-1:0]];


    reg        spi_en;           // global enable
    reg        spi_master;       // master/slave select
    reg [1:0]  spi_mode;         // {CPOL, CPHA}
    reg        spi_lsb;          // LSB-first
    reg        spi_loop;         // loopback
    reg [1:0]  spi_width;        // transfer width: 00=8b, 01=16b, 1x=32b

    reg [15:0] baud_div;         // clock divider
    reg [3:0]  cs_sel;           // chip-select enable mask
    reg [3:0]  cs_pol;           // chip-select value/polarity
    reg [NUM_IRQ-1:0] irq_en;   // interrupt enable mask
    reg [NUM_IRQ-1:0] irq_pend; // interrupt pending (W1C)
    reg [7:0]  pre_delay;        // inter-transfer delay

    assign cfg_en        = spi_en;
    assign cfg_mstr      = spi_master;
    assign cfg_mode      = spi_mode;
    assign cfg_lsb_first = spi_lsb;
    assign cfg_loopback  = spi_loop;
    assign cfg_width     = spi_width;
    assign cfg_clk_div   = baud_div;
    assign cfg_delay      = pre_delay;

    assign SS_n = ~cs_sel | cs_pol;
    assign IRQ  = |(irq_pend & irq_en);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    wire bus_phase  = PSEL & PENABLE;
    wire bus_wr     = bus_phase &  PWRITE;
    wire bus_rd     = bus_phase & ~PWRITE;

    wire wr_tx_req  = bus_wr && (PADDR == ADDR_TX) && spi_en;
    wire [31:0] wr_tx_din =
        (spi_width == 2'b00) ? {24'h0, PWDATA[7:0]}  :
        (spi_width == 2'b01) ? {16'h0, PWDATA[15:0]} :
                                PWDATA;

    wire wr_tx_ok  = wr_tx_req & ~tx_afull;   // accepted into FIFO
    wire wr_tx_ovf = wr_tx_req &  tx_afull;   // dropped -> TX_OVF interrupt

    wire [NUM_IRQ-1:0] ev_new;
    assign ev_new[BIT_TX_MT]   = tx_pop        && (tx_lvl == 1);
    assign ev_new[BIT_RX_FULL] = rx_push_valid && !rx_afull && (rx_lvl == DEPTH-1);
    assign ev_new[BIT_TX_OVF]  = wr_tx_ovf;
    assign ev_new[BIT_RX_OVF]  = rx_push_valid && rx_afull;
    assign ev_new[BIT_DONE]    = transfer_done_pulse;

    reg rd_rx_req;
    always @(*) begin
        PRDATA    = 32'h0;
        rd_rx_req = 1'b0;

        if (bus_rd) begin
            case (PADDR)
                ADDR_CTRL : PRDATA = {24'h0,
                                      spi_width, spi_loop, spi_lsb,
                                      spi_mode, spi_master, spi_en};
                ADDR_STATUS : PRDATA = {25'h0,
                                        irq_pend[BIT_RX_OVF], irq_pend[BIT_TX_OVF],
                                        rx_aempty, rx_afull,
                                        tx_aempty, tx_afull,
                                        busy_in};
                ADDR_TX      : PRDATA = 32'h0;        // write-only register
                ADDR_RX      : begin
                    PRDATA    = rx_aempty ? 32'h0 : rx_ram[rd_rx[PW-1:0]];
                    rd_rx_req = ~rx_aempty;
                end
                ADDR_BAUDIV  : PRDATA = {16'h0, baud_div};
                ADDR_CS_CTRL : PRDATA = {24'h0, cs_pol, cs_sel};
                ADDR_IRQ_MASK: PRDATA = {{(32-NUM_IRQ){1'b0}}, irq_en};
                ADDR_IRQ_STAT: PRDATA = {{(32-NUM_IRQ){1'b0}}, irq_pend};
                ADDR_DELAY   : PRDATA = {24'h0, pre_delay};
                default      : PRDATA = 32'h0;
            endcase
        end
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            /* --- reset all config registers --- */
            {spi_width, spi_loop, spi_lsb,
             spi_mode, spi_master, spi_en} <= 8'h0;
            baud_div   <= 16'h0;
            {cs_pol, cs_sel} <= 8'h0;
            irq_en     <= '0;
            irq_pend   <= '0;
            pre_delay  <= 8'h0;
        end else begin
            /* --- APB write decode --- */
            if (bus_wr) begin
                case (PADDR)
                    ADDR_CTRL:
                        {spi_width, spi_loop, spi_lsb,
                         spi_mode, spi_master, spi_en} <= PWDATA[7:0];
                    ADDR_BAUDIV :  baud_div          <= PWDATA[15:0];
                    ADDR_CS_CTRL: {cs_pol, cs_sel}   <= PWDATA[7:0];
                    ADDR_IRQ_MASK: irq_en            <= PWDATA[NUM_IRQ-1:0];
                    ADDR_DELAY:    pre_delay         <= PWDATA[7:0];
                    default: ;
                endcase
            end

            /* --- IRQ flags: W1C then OR new events (set beats clear) --- */
            if (bus_wr && (PADDR == ADDR_IRQ_STAT))
                irq_pend <= (irq_pend & ~PWDATA[NUM_IRQ-1:0]) | ev_new;
            else
                irq_pend <= irq_pend | ev_new;
        end
    end

    integer k;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            wr_tx <= '0;  rd_tx <= '0;
            wr_rx <= '0;  rd_rx <= '0;
            for (k = 0; k < DEPTH; k = k+1) begin
                tx_ram[k] <= 32'h0;
                rx_ram[k] <= 32'h0;
            end
        end else if (!spi_en) begin
            /* Flush both FIFOs when SPI is disabled */
            wr_tx <= '0;  rd_tx <= '0;
            wr_rx <= '0;  rd_rx <= '0;
        end else begin
            /* TX FIFO */
            if (wr_tx_ok) begin
                tx_ram[wr_tx[PW-1:0]] <= wr_tx_din;
                wr_tx <= wr_tx + 1'b1;
            end
            if (tx_pop)
                rd_tx <= rd_tx + 1'b1;

            /* RX FIFO */
            if (rx_push_valid && !rx_afull) begin
                rx_ram[wr_rx[PW-1:0]] <= rx_push_data;
                wr_rx <= wr_rx + 1'b1;
            end
            if (rd_rx_req)
                rd_rx <= rd_rx + 1'b1;
        end
    end

endmodule

`default_nettype wire