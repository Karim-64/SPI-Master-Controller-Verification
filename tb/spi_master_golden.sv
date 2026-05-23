`default_nettype none
`timescale 1ns/1ps

module spi_master_golden (
    input  wire         PCLK,
    input  wire         PRESETn,

    // APB slave
    input  wire         PSEL,
    input  wire         PENABLE,
    input  wire         PWRITE,
    input  wire [7:0]   PADDR,
    input  wire [31:0]  PWDATA,
    output wire [31:0]  PRDATA,
    output wire         PREADY,
    output wire         PSLVERR,

    // SPI pins
    output wire         SCLK,
    output wire         MOSI,
    input  wire         MISO,
    output wire [3:0]   SS_n,

    // Interrupt
    output wire         IRQ
);

    // -------------------------------------------------------------------------
    // Internal bus: apb_regfile_golden <-> spi_core_rm
    // -------------------------------------------------------------------------
    wire         cfg_en;
    wire         cfg_mstr;
    wire [1:0]   cfg_mode;
    wire         cfg_lsb_first;
    wire         cfg_loopback;
    wire [1:0]   cfg_width;
    wire [15:0]  cfg_clk_div;
    wire [7:0]   cfg_delay;

    wire [31:0]  tx_word;
    wire         tx_empty;
    wire         tx_pop;

    wire         rx_push_valid;
    wire [31:0]  rx_push_data;

    wire         busy;
    wire         transfer_done_pulse;

    wire [3:0]   ss_n_int;
    assign SS_n = ss_n_int;

    // -------------------------------------------------------------------------
    // APB register file + TX/RX FIFO (golden model)
    // -------------------------------------------------------------------------
    apb_regfile_golden u_regfile_gm (
        .PCLK                (PCLK),
        .PRESETn             (PRESETn),

        .PSEL                (PSEL),
        .PENABLE             (PENABLE),
        .PWRITE              (PWRITE),
        .PADDR               (PADDR),
        .PWDATA              (PWDATA),
        .PRDATA              (PRDATA),
        .PREADY              (PREADY),
        .PSLVERR             (PSLVERR),

        .cfg_en              (cfg_en),
        .cfg_mstr            (cfg_mstr),
        .cfg_mode            (cfg_mode),
        .cfg_lsb_first       (cfg_lsb_first),
        .cfg_loopback        (cfg_loopback),
        .cfg_width           (cfg_width),
        .cfg_clk_div         (cfg_clk_div),
        .cfg_delay           (cfg_delay),

        .SS_n                (ss_n_int),

        .tx_word             (tx_word),
        .tx_empty            (tx_empty),
        .tx_pop              (tx_pop),

        .rx_push_valid       (rx_push_valid),
        .rx_push_data        (rx_push_data),

        .busy_in             (busy),
        .transfer_done_pulse (transfer_done_pulse),

        .IRQ                 (IRQ)
    );

    // -------------------------------------------------------------------------
    // Behavioral SPI shift engine (reference model predictor)
    // -------------------------------------------------------------------------
    spi_core_golden u_core_rm (
        .PCLK                (PCLK),
        .PRESETn             (PRESETn),

        .cfg_en              (cfg_en),
        .cfg_mstr            (cfg_mstr),
        .cfg_mode            (cfg_mode),
        .cfg_lsb_first       (cfg_lsb_first),
        .cfg_loopback        (cfg_loopback),
        .cfg_width           (cfg_width),
        .cfg_clk_div         (cfg_clk_div),
        .cfg_delay           (cfg_delay),

        .ss_n_drive          (ss_n_int),

        .tx_word             (tx_word),
        .tx_empty            (tx_empty),
        .tx_pop              (tx_pop),

        .rx_push_valid       (rx_push_valid),
        .rx_push_data        (rx_push_data),

        .busy                (busy),
        .transfer_done_pulse (transfer_done_pulse),

        .SCLK                (SCLK),
        .MOSI                (MOSI),
        .MISO                (MISO)
    );

endmodule

`default_nettype wire