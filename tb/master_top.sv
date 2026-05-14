import uvm_pkg::*;
`include "uvm_macros.svh"
import mode_coverage_test_pkg::*;
import clk_div_corner_test_pkg::*;
import master_test_pkg::*;
import sanity_test_pkg::*;
import master_shared_pkg::*;
import error_injection_test_pkg::*;

`timescale 1ns/1ps
module top ();
    //=========================================================================
    // Clock Generation
    // PCLK: 500MHz (period = 2ns, toggle every 1ns)
    //=========================================================================
    bit PCLK;
    initial begin
        PCLK = 0;
        forever begin
            #1 PCLK = ~PCLK;
        end
    end

    //=========================================================================
    // Interface Instantiations
    //  - master_if  : APB Master-side signals (stimulus + DUT outputs)
    //  - apb_if     : Internal APB register file signals (regfile ↔ core)
    //  - spi_core_if: SPI Core internal config/data bus
    //=========================================================================
    master_if  masterif(PCLK);
    apb_if     apb(PCLK);
    spi_if     spi(PCLK);

    //=========================================================================
    // DUT Instantiation
    // All DUT ports are conn exclusively through master_if.
    //  - Inputs : PCLK, PRESETn, psel, PENABLE, PWRITE, PADDR, PWDATA, MISO
    //  - Outputs: PREADY, PSLVERR, PRDATA, MOSI, ss_n, SCLK, irq
    //=========================================================================
    dut_wrapper DUT (
        .apb(apb), 
        .spi(spi)
    );

    // 1. Inputs to DUT (driven by testbench via masterif)
    assign apb.psel                 = masterif.psel;
    assign apb.presetn              = masterif.presetn;
    assign apb.penable              = masterif.penable;
    assign apb.pwrite               = masterif.pwrite;
    assign apb.paddr                = masterif.paddr;
    assign apb.pwdata               = masterif.pwdata;
    
    // 2. Outputs from DUT (driven by DUT to masterif)
    assign masterif.prdata          = apb.prdata;
    assign masterif.pready          = apb.pready;
    assign masterif.pslverr         = apb.pslverr;
    assign masterif.ss_n            = apb.ss_n;
    assign masterif.irq             = spi.irq;
    assign masterif.mosi            = spi.mosi;
    assign masterif.sclk            = spi.sclk;

    assign apb.tx_pop               = DUT.u_dut.tx_pop;
    assign apb.rx_push_valid        = DUT.u_dut.rx_push_valid;
    assign apb.rx_push_data         = DUT.u_dut.rx_push_data;
    assign apb.busy_in              = DUT.u_dut.busy;
    assign apb.transfer_done_pulse  = DUT.u_dut.transfer_done_pulse;
    assign apb.cfg_en               = DUT.u_dut.cfg_en;
    assign apb.cfg_mstr             = DUT.u_dut.cfg_mstr;
    assign apb.cfg_mode             = DUT.u_dut.cfg_mode;
    assign apb.cfg_lsb_first        = DUT.u_dut.cfg_lsb_first;
    assign apb.cfg_loopback         = DUT.u_dut.cfg_loopback;
    assign apb.cfg_width            = DUT.u_dut.cfg_width;
    assign apb.cfg_clk_div          = DUT.u_dut.cfg_clk_div;
    assign apb.cfg_delay            = DUT.u_dut.cfg_delay;
    assign apb.tx_word              = DUT.u_dut.tx_word;
    assign apb.tx_empty             = DUT.u_dut.tx_empty;
    assign apb.ss_n                 = DUT.u_dut.u_regfile.SS_n;  // correct
    assign apb.irq                  = DUT.u_dut.u_regfile.IRQ;

    // ==================== Core interface =====================

    assign spi.presetn = masterif.presetn;

    assign spi.tx_pop               = DUT.u_dut.tx_pop;
    assign spi.rx_push_valid        = DUT.u_dut.rx_push_valid;
    assign spi.rx_push_data         = DUT.u_dut.rx_push_data;
    assign spi.busy                 = DUT.u_dut.busy;
    assign spi.transfer_done_pulse  = DUT.u_dut.transfer_done_pulse;
    assign spi.cfg_en               = DUT.u_dut.cfg_en;
    assign spi.cfg_mstr             = DUT.u_dut.cfg_mstr;
    assign spi.cfg_mode             = DUT.u_dut.cfg_mode;
    assign spi.cfg_lsb_first        = DUT.u_dut.cfg_lsb_first;
    assign spi.cfg_loopback         = DUT.u_dut.cfg_loopback;
    assign spi.cfg_width            = DUT.u_dut.cfg_width;
    assign spi.cfg_clk_div          = DUT.u_dut.cfg_clk_div;
    assign spi.cfg_delay            = DUT.u_dut.cfg_delay;

    // Internal assignments from DUT wrapper output signals to SPI interface
    assign spi.tx_word              = DUT.u_dut.tx_word;
    assign spi.tx_empty             = DUT.u_dut.tx_empty;
    assign spi.ss_n                 = DUT.u_dut.ss_n_int;

    assign masterif.miso=spi.miso;
    spi_slave_bfm slave_bfm(
    spi,              
    mode_pkg,        // {CPOL, CPHA} - from CTRL[3:2]
    lsb_first_pkg,   // 1 = LSB-first, 0 = MSB-first - from CTRL[4]
    width_cfg_pkg,   // 00=8b, 01=16b, 10=32b - from CTRL[7:6]
    miso_data_pkg    // 32-bit pattern repeatedly returned on MISO
    );

    // apb_SVA apb_sva_checker_inst (apb.DUT);
    initial begin
        uvm_config_db#(virtual master_if)  ::set  (null, "uvm_test_top", "MASTER_IF",   masterif);
        uvm_config_db#(virtual apb_if)     ::set  (null, "uvm_test_top", "APB_IF",      apb);
        uvm_config_db#(virtual spi_if)     ::set(null, "uvm_test_top", "spi_core_IF",   spi);
        // run_test("master_access_test");
        // run_test("mode_coverage_test");
        // run_test("error_injection_test");
        run_test("clk_div_corner_test");
        // run_test("sanity_test");
    end

endmodule