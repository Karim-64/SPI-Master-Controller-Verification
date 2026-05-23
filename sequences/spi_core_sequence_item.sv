package spi_core_sequence_item_pkg;
import uvm_pkg::*;
import spi_core_shared_pkg::*;
`include "uvm_macros.svh"
`define WRITE_ADDR_ins 3'b000
`define WRITE_DATA_ins 3'b001
`define READ_ADDR_ins  3'b110
`define READ_DATA_ins  3'b111

class spi_core_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(spi_core_sequence_item)
    
    // randomized signals
    rand bit         presetn;
    rand bit         tx_empty;
    rand bit         miso;
    rand bit         cfg_en;
    rand bit         cfg_mstr;
    rand bit         cfg_lsb_first;
    rand bit         cfg_loopback;
    rand bit [1:0]   cfg_mode;
    rand bit [1:0]   cfg_width;
    rand bit [3:0]   ss_n;
    rand bit [7:0]   cfg_delay;
    rand bit [15:0]  cfg_clk_div;
    rand bit [31:0]  tx_word;

    // non-randomized signals
    logic         tx_pop;
    logic         rx_push_valid;
    logic         busy;
    logic         transfer_done_pulse;
    logic         sclk;
    logic         mosi;
    logic [31:0] rx_push_data;

    logic         tx_pop_expected;
    logic         rx_push_valid_expected;
    logic         busy_expected;
    logic         transfer_done_pulse_expected;
    logic         sclk_expected;
    logic         mosi_expected;
    logic [31:0] rx_push_data_expected;

     
    function new(string name = "spi_core_sequence_item");
        super.new(name);
    endfunction

    /*constraints*/
   


    function string convert2string();
        return $sformatf("presetn=%0d tx_empty=%0d miso=%0d cfg_en=%0d cfg_mstr=%0d cfg_lsb_first=%0d cfg_loopback=%0d tx_pop=%0d rx_push_valid=%0d busy=%0d transfer_done_pulse=%0d sclk=%0d mosi=%0d, cfg_mode=%0b cfg_width=%0b ss_n=%0b cfg_delay=%0d cfg_clk_div=%0d tx_word=%0h rx_push_data=%0h, tx_pop_expected=%0d rx_push_valid_expected=%0d busy_expected=%0d transfer_done_pulse_expected=%0d sclk_expected=%0d mosi_expected=%0d rx_push_data_expected=%0h",
                          presetn, tx_empty, miso, cfg_en, cfg_mstr, cfg_lsb_first, cfg_loopback,
                          tx_pop, rx_push_valid, busy, transfer_done_pulse, sclk, mosi,
                          cfg_mode, cfg_width, ss_n, cfg_delay, cfg_clk_div, tx_word, rx_push_data,
                          tx_pop_expected, rx_push_valid_expected, busy_expected,
                          transfer_done_pulse_expected, sclk_expected, mosi_expected,
                          rx_push_data_expected);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("presetn=%0d tx_empty=%0d miso=%0d cfg_en=%0d cfg_mstr=%0d cfg_lsb_first=%0d cfg_loopback=%0d, cfg_mode=%0b cfg_width=%0b ss_n=%0b cfg_delay=%0d cfg_clk_div=%0d tx_word=%0h",
                          presetn, tx_empty, miso, cfg_en, cfg_mstr, cfg_lsb_first,
                          cfg_loopback, cfg_mode, cfg_width, ss_n,
                          cfg_delay, cfg_clk_div, tx_word);
    endfunction        
endclass
endpackage