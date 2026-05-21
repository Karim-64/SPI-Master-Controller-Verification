module spi_coreSVA (spi_if.DUT spicoreif);
/*             spicoreif.pclk,
               spicoreif.presetn,
               spicoreif.tx_empty,
               spicoreif.miso,
               spicoreif.cfg_en,
               spicoreif.cfg_mstr,
               spicoreif.cfg_lsb_first,
               spicoreif.cfg_loopback,
               spicoreif.cfg_mode,
               spicoreif.cfg_width,
               spicoreif.ss_n,
               spicoreif.cfg_delay,
               spicoreif.cfg_clk_div,
               spicoreif.tx_word,
               spicoreif.tx_pop,
               spicoreif.rx_push_valid,
               spicoreif.busy,
               spicoreif.transfer_done_pulse,
               spicoreif.sclk,
               spicoreif.mosi,
               spicoreif.rx_push_data
*/
//====================M spi 1=====================

property p_sclk_idle_matches_cpol;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    !spicoreif.busy |-> (spicoreif.sclk == spicoreif.cfg_mode[0]);
endproperty

ast_sclk_idle_cpol: assert property (p_sclk_idle_matches_cpol);
cov_sclk_idle_cpol: cover property (p_sclk_idle_matches_cpol);

//====================M spi 2=====================
property p_mosi_stable;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    (spicoreif.busy && $rose(spicoreif.sclk))
    |-> $stable(spicoreif.mosi) and $past($stable(spicoreif.mosi)) and ##1 $stable(spicoreif.mosi);   
endproperty

AST_MOSI_STABLE: assert property (p_mosi_stable);
COV_MOSI_STABLE: cover property (p_mosi_stable);


//====================M spi 3=====================

property p_ssn_held_low_during_transfer;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    spicoreif.busy |-> (spicoreif.ss_n != 4'hF);  // at least one lane asserted low
endproperty

ast_ssn_held_low: assert property (p_ssn_held_low_during_transfer);
cov_ssn_held_low: cover property (p_ssn_held_low_during_transfer);


//====================R3=====================

property p_disabled_busy_low;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    !spicoreif.cfg_en |-> !spicoreif.busy;
endproperty

property p_disabled_sclk_idle;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    !spicoreif.cfg_en |-> (spicoreif.sclk == spicoreif.cfg_mode[1]);
endproperty

ast_disabled_busy_low:  assert property (p_disabled_busy_low);
ast_disabled_sclk_idle: assert property (p_disabled_sclk_idle);

cov_disabled_busy_low:  cover property (p_disabled_busy_low);
cov_disabled_sclk_idle: cover property (p_disabled_sclk_idle);

//==================R5=======================

property p_r5_mosi_stable_sample;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.busy && $changed(spicoreif.sclk))
    |-> (spicoreif.mosi == $past(spicoreif.mosi));
endproperty

ast_r5_mosi_stable: assert property (p_r5_mosi_stable_sample);
cov_r5_mosi_stable: cover  property (p_r5_mosi_stable_sample);


//==================R6=======================

property p_r6_tx_msb_first;//-------> hwa el width momkn yt8yr?
    logic [31:0] tx;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (!spicoreif.cfg_lsb_first && spicoreif.tx_pop, tx = spicoreif.tx_word)
    |-> ##[1:4] (spicoreif.busy && spicoreif.mosi == tx[31]);
endproperty

property p_r6_tx_lsb_first;//--------------msh sha8ala
    logic [31:0] tx;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.cfg_lsb_first && spicoreif.tx_pop, tx = spicoreif.tx_word)
    |->##[0:4] (spicoreif.busy && spicoreif.mosi == tx[0]);
endproperty

property p_r6_rx_upper_zero;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.rx_push_valid && spicoreif.cfg_width == 2'b00)
    |-> (spicoreif.rx_push_data[31:8]  == '0);
endproperty

property p_r6_rx_upper_zero_16;//-----------------msh sha8ala
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.rx_push_valid && spicoreif.cfg_width == 2'b01)
    |-> (spicoreif.rx_push_data[31:16] == '0);
endproperty

ast_r6_tx_msb:     assert property (p_r6_tx_msb_first);
ast_r6_tx_lsb:     assert property (p_r6_tx_lsb_first);
ast_r6_rx_8bit:    assert property (p_r6_rx_upper_zero);
ast_r6_rx_16bit:   assert property (p_r6_rx_upper_zero_16);

cov_r6_tx_msb:     cover property (p_r6_tx_msb_first);
cov_r6_tx_lsb:     cover property (p_r6_tx_lsb_first);
cov_r6_rx_8bit:    cover property (p_r6_rx_upper_zero);
cov_r6_rx_16bit:   cover property (p_r6_rx_upper_zero_16);




//====================R6=====================
property p_tx_first_bit;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    (spicoreif.tx_pop && spicoreif.cfg_mode[0] == 1'b0)
    |=> spicoreif.mosi == (spicoreif.cfg_lsb_first?
     spicoreif.tx_word[0]: spicoreif.tx_word[(spicoreif.cfg_width == 2'b00) ? 7 :(spicoreif.cfg_width == 2'b01) ? 15 : 31]);
endproperty
ast_tx_first_bit: assert property (p_tx_first_bit);
cov_tx_first_bit: cover property (p_tx_first_bit);

//==================R7=======================

property p_busy_width_8;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    ($rose(spicoreif.busy) && spicoreif.cfg_width == 2'b00)|-> $rose(spicoreif.sclk)[->8] ##1 $fell(spicoreif.busy);

endproperty

property p_busy_width_16;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    ($rose(spicoreif.busy) && spicoreif.cfg_width == 2'b01)
    |-> $rose(spicoreif.sclk)[->16] 
                ##1 $fell(spicoreif.busy);

endproperty

property p_busy_width_32;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    ($rose(spicoreif.busy) && spicoreif.cfg_width == 2'b10)
    |-> $rose(spicoreif.sclk)[->32] 
        ##1 $fell(spicoreif.busy);
endproperty

AST_BUSY_WIDTH_8:  assert property (p_busy_width_8);
AST_BUSY_WIDTH_16: assert property (p_busy_width_16);
AST_BUSY_WIDTH_32: assert property (p_busy_width_32);

//====================R8=====================
    logic [16:0] half_period = {1'b0, spicoreif.cfg_clk_div} + 17'd1;
// In assertions/spi_core_assertions.sv

property sclk_high_period_check;
    longint count;
    @(posedge spicoreif.pclk)
    disable iff (!spicoreif.presetn || !spicoreif.cfg_en)
    ($rose(spicoreif.sclk), count = 0)
    ##1 (spicoreif.sclk === 1'b1, count = count + 1) [*0:$]
    ##1 $fell(spicoreif.sclk)
    |->
    (count == spicoreif.cfg_clk_div + 1'b1);
endproperty

R8_SCLK_FREQUENCY: assert property (sclk_high_period_check);
    // else `uvm_error("SVA",
    //     $sformatf("[ASSERTION_ERROR] R8_SCLK_FREQUENCY: expected=%0d got=%0d PCLK cycles",
    //     spicoreif.cfg_clk_div + 1, count))

    // else `uvm_error("SVA",
    //     $sformatf("[ASSERTION_ERROR]: SCLK_FREQUENCY SCLK high period wrong: expected=%0d got=%0d",
    //     cfg_clk_div + 1, count))

// AST_SCLK_FREQ: assert property (p_sclk_freq);
// COV_SCLK_FREQ: cover property (p_sclk_freq);

//==================R18=======================
// w1c_race_transfer_done_as: assert property(w1c_race_transfer_done);
// else $error("[ASSERTION_ERROR] w1c_race_transfer_done test fail");
// w1c_race_transfer_done_cov: cover property(w1c_race_transfer_done);

// property w1c_race_tx_ovf;
//     disable iff(~apbif.presetn)
//     @(posedge apbif.PCLK)

//     (
//         apbif.psel &&
//         apbif.penable &&
//         apbif.pwrite &&
//         apbif.paddr == 8'h1C &&
//         apbif.pwdata[2] &&
//         DUT.u_dut.u_regfile.tx_push_dropped
//     )
//     |=> ##0 (apb_read_int_stat[2] == 1'b1);
// endproperty

// w1c_race_tx_ovf_as: assert property(w1c_race_tx_ovf)
// else $error("[ASSERTION_ERROR] w1c_race_tx_ovf test fail");
// cover property(w1c_race_tx_ovf);

//==================R19=======================
property p_r19_loopback_rx_equals_tx;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.cfg_loopback && spicoreif.tx_pop)
    |-> ##[1:10] (spicoreif.rx_push_valid &&
                 spicoreif.rx_push_data == $past(spicoreif.tx_word));
endproperty

ast_r19_loopback: assert property (p_r19_loopback_rx_equals_tx);
cov_r19_loopback: cover  property (p_r19_loopback_rx_equals_tx);


//==================R21=======================

property p_r21_no_gap_when_delay_zero;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.transfer_done_pulse && spicoreif.cfg_delay == 8'h0)
    |=> !spicoreif.busy;
endproperty

ast_r21_no_gap_delay_zero: assert property (p_r21_no_gap_when_delay_zero);
cov_r21_no_gap_delay_zero: cover  property (p_r21_no_gap_when_delay_zero);

//==================R24=======================
property p_zero_clk_div;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    (spicoreif.busy && spicoreif.cfg_clk_div == 16'h0 
     && ($rose(spicoreif.sclk) || $fell(spicoreif.sclk)))
    |-> $past(spicoreif.sclk, 1) != spicoreif.sclk;
endproperty

AST_ZERO_CLK_DIV: assert property (p_zero_clk_div);
COV_ZERO_CLK_DIV: cover property (p_zero_clk_div);

//==================R25=======================
property p_r25_mode_held;
    logic cpol;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    ($rose(spicoreif.busy), cpol = spicoreif.cfg_mode[1])
    |-> ##[1:$] (spicoreif.transfer_done_pulse &&
                 spicoreif.sclk == cpol);
endproperty

property p_r25_width_held;
    logic [1:0] w;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    ($rose(spicoreif.busy), w = spicoreif.cfg_width)
    |-> ##[1:$] (spicoreif.rx_push_valid &&
                ((w == 2'b00 && spicoreif.rx_push_data[31:8]  == '0) ||
                 (w == 2'b01 && spicoreif.rx_push_data[31:16] == '0) ||
                 (w == 2'b10)));
endproperty

property p_r25_div_held;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.busy && $rose(spicoreif.sclk))
    |-> ##1 !$rose(spicoreif.sclk);
endproperty


ast_r25_mode:  assert property (p_r25_mode_held);
ast_r25_width: assert property (p_r25_width_held);
ast_r25_div:   assert property (p_r25_div_held);

cov_r25_mode:  cover property (p_r25_mode_held);
cov_r25_width: cover property (p_r25_width_held);
cov_r25_div:   cover property (p_r25_div_held);



endmodule