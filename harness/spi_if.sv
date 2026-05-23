`ifndef SPI_SPI_IF_SV
`define SPI_SPI_IF_SV
`timescale 1ns/1ps

interface spi_if (input bit pclk);
// interface input
// input signals
    logic         tx_empty;
    logic         miso;
    logic         presetn;
    logic         cfg_en;
    logic         cfg_mstr;
    logic         cfg_lsb_first;
    logic         cfg_loopback;
    logic [1:0]   cfg_mode;
    logic [1:0]   cfg_width;
    wire  [3:0]   ss_n;
    logic [7:0]   cfg_delay;
    logic [15:0]  cfg_clk_div;
    logic [31:0]  tx_word;
    logic         irq;


// output signals
    logic          tx_pop;
    logic          rx_push_valid;
    logic          busy;
    logic          transfer_done_pulse;
    wire           sclk;
    wire           mosi;
    logic  [31:0]  rx_push_data;


// golden model output signal
    logic          tx_pop_expected;
    logic          rx_push_valid_expected;
    logic          busy_expected;
    logic          transfer_done_pulse_expected;
    logic          sclk_expected;
    logic          mosi_expected;
    logic  [31:0]  rx_push_data_expected;



    modport DUT (
        input  pclk,
               presetn,
               tx_empty,
               miso,
               cfg_en,
               cfg_mstr,
               cfg_lsb_first,
               cfg_loopback,
               cfg_mode,
               cfg_width,
               ss_n,
               cfg_delay,
               cfg_clk_div,
               tx_word,

        output tx_pop,
               rx_push_valid,
               busy,
               transfer_done_pulse,
               sclk,
               mosi,
               rx_push_data
    );

modport spi_core_golden_model (
        input  pclk,
               presetn,
               tx_empty,
               miso,
               cfg_en,
               cfg_mstr,
               cfg_lsb_first,
               cfg_loopback,
               cfg_mode,
               cfg_width,
               ss_n,
               cfg_delay,
               cfg_clk_div,
               tx_word,

        output tx_pop_expected,
               rx_push_valid_expected,
               busy_expected,
               transfer_done_pulse_expected,
               sclk_expected,
               mosi_expected,
               rx_push_data_expected
    );

    clocking cb_slave @(posedge pclk);
        default input #1step output #0;
        input  sclk, mosi, ss_n, irq;
        output miso;
    endclocking

    modport slave (
        input  pclk,
        input  sclk,
        input  mosi,
        input  ss_n,
        input  irq,
        output miso
    );


endinterface
`endif