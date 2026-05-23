import uvm_pkg::*;
`include "uvm_macros.svh"
import comprehensive_test_pkg::*;
import master_shared_pkg::*;
import ral_hw_reset_test_pkg::*;

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

    //=========================================================================
    // SPI Slave BFM — configuration driven by master_shared_pkg variables
    // Sequences write master_shared_pkg::mode_pkg etc. directly.
    //=========================================================================
    assign masterif.miso = spi.miso;
    spi_slave_bfm slave_bfm(
        .spi        (spi),
        .mode       (mode_pkg),
        .lsb_first  (lsb_first_pkg),
        .width_cfg  (width_cfg_pkg),
        .miso_data  (miso_data_pkg)
    );

    apb_regfile_golden abp_gm (
        .PCLK(PCLK),
        .PRESETn(masterif.presetn),
        .PSEL(apb.psel),
        .PENABLE(apb.penable),
        .PWRITE(apb.pwrite),
        .PADDR(apb.paddr),
        .PWDATA(apb.pwdata),
        .PRDATA(apb.prdata_exp),
        .PREADY(apb.pready_exp),
        .PSLVERR(apb.pslverr_exp),
        .cfg_en(apb.cfg_en_exp),
        .cfg_mstr(apb.cfg_mstr_exp),
        .cfg_mode(apb.cfg_mode_exp),
        .cfg_lsb_first(apb.cfg_lsb_first_exp),
        .cfg_loopback(apb.cfg_loopback_exp),
        .cfg_width(apb.cfg_width_exp),
        .cfg_clk_div(apb.cfg_clk_div_exp),
        .cfg_delay(apb.cfg_delay_exp),
        .SS_n(apb.ss_n_exp),
        .tx_word(apb.tx_word_exp),
        .tx_empty(apb.tx_empty_exp),
        .tx_pop(apb.tx_pop),
        .rx_push_valid(apb.rx_push_valid),
        .rx_push_data(apb.rx_push_data),
        .busy_in(apb.busy_in),
        .transfer_done_pulse(apb.transfer_done_pulse),
        .IRQ(apb.irq_exp)
    );

    // ============================================================
    // SPI Core Reference Model — drives _expected signals in spi_if
    // ============================================================
    spi_core_golden spi_gm (
        .PCLK(PCLK),
        .PRESETn(masterif.presetn),
        .cfg_en(spi.cfg_en),
        .cfg_mstr(spi.cfg_mstr),
        .cfg_mode(spi.cfg_mode),
        .cfg_lsb_first(spi.cfg_lsb_first),
        .cfg_loopback(spi.cfg_loopback),
        .cfg_width(spi.cfg_width),
        .cfg_clk_div(spi.cfg_clk_div),
        .cfg_delay(spi.cfg_delay),
        .ss_n_drive(spi.ss_n),
        .tx_word(spi.tx_word),
        .tx_empty(spi.tx_empty),
        .tx_pop(spi.tx_pop_expected),  
        .rx_push_valid(spi.rx_push_valid_expected),  
        .rx_push_data(spi.rx_push_data_expected),  
        .busy(spi.busy_expected),  
        .transfer_done_pulse(spi.transfer_done_pulse_expected),  
        .SCLK(spi.sclk_expected),  
        .MOSI(spi.mosi_expected),   
        .MISO(masterif.miso)
    );
    // ============================================================
    spi_master_golden spi_golden (
        .PCLK(PCLK),
        .PRESETn(masterif.presetn),
        .PSEL(masterif.psel),
        .PENABLE(masterif.penable),
        .PWRITE(masterif.pwrite),
        .PADDR(masterif.paddr),
        .PWDATA(masterif.pwdata),
        .MISO(masterif.miso),
        .PRDATA(masterif.prdata_exp),
        .PREADY(masterif.pready_exp),
        .PSLVERR(masterif.pslverr_exp),
        .SCLK(masterif.sclk_exp),
        .MOSI(masterif.mosi_exp),
        .SS_n(masterif.ss_n_exp),
        .IRQ(masterif.irq_exp)
    );


    
    bind DUT.u_dut.u_regfile apb_SVA  apb_sva_checker_inst    (apb.DUT);
    bind DUT.u_dut.u_core spi_coreSVA spi_sva_assertions_inst (spi.DUT);

    initial begin
        uvm_config_db#(virtual master_if)  ::set  (null, "uvm_test_top", "MASTER_IF",   masterif);
        uvm_config_db#(virtual apb_if)     ::set  (null, "uvm_test_top", "APB_IF",      apb);
        uvm_config_db#(virtual spi_if)     ::set  (null, "uvm_test_top", "spi_core_IF",   spi);
        run_test("comprehensive_test");
    end
endmodule