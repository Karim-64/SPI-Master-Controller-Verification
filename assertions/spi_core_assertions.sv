module spi_coreSVA (spi_if.DUT spicoreif);

//====================M spi 1=====================
property p_sclk_idle_matches_cpol;

    @(posedge spicoreif.pclk)
    disable iff (~spicoreif.presetn)

    (!spicoreif.busy &&
     $past(!spicoreif.busy) &&
     $stable(spicoreif.cfg_mode))

    |-> (spicoreif.sclk == spicoreif.cfg_mode[1]);

endproperty

ast_sclk_idle_cpol: assert property (p_sclk_idle_matches_cpol);
cov_sclk_idle_cpol: cover property (p_sclk_idle_matches_cpol);
//====================M spi 2=====================

property p_mosi_stable_around_sample;
    @(posedge spicoreif.sclk)
    disable iff(!spicoreif.presetn)

    (spicoreif.busy && $rose(spicoreif.sclk))
    |->
       $past($stable(spicoreif.mosi))  // stable before edge
    && $stable(spicoreif.mosi)         // stable at edge
    ##1 $stable(spicoreif.mosi);       // stable after edge
endproperty

AST_MOSI_STABLE:
    assert property(p_mosi_stable_around_sample)
    else $error("MOSI changed around SPI sample edge");

COV_MOSI_STABLE:
    cover property(p_mosi_stable_around_sample);
//====================M spi 3=====================
property p_ss_held_during_transfer;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    $rose(spicoreif.busy)
    |-> (spicoreif.ss_n != 4'hF) throughout (spicoreif.busy [*1:$]);
endproperty

AST_SS_HELD_DURING_TRANSFER: assert property (p_ss_held_during_transfer)
    else $error("SS_n deasserted during active SPI transfer");
COV_SS_HELD_DURING_TRANSFER: cover property (p_ss_held_during_transfer);


//====================R3=====================

// property p_disabled_busy_low;
//     @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
//     !spicoreif.cfg_en |-> !spicoreif.busy;
// endproperty

// property p_disabled_sclk_idle;
//     @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
//     !spicoreif.cfg_en |-> (spicoreif.sclk == spicoreif.cfg_mode[1]);
// endproperty

// ast_disabled_busy_low:  assert property (p_disabled_busy_low);
// ast_disabled_sclk_idle: assert property (p_disabled_sclk_idle);

// cov_disabled_busy_low:  cover property (p_disabled_busy_low);
// cov_disabled_sclk_idle: cover property (p_disabled_sclk_idle);

//==================R5=======================
// property p_r5_mosi_stable_sample;
//     @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
//     (spicoreif.busy && spicoreif.cfg_en && (
//         (spicoreif.cfg_mode == 2'b00 && $rose(spicoreif.sclk)) ||
//         (spicoreif.cfg_mode == 2'b01 && $fell(spicoreif.sclk)) ||
//         (spicoreif.cfg_mode == 2'b10 && $fell(spicoreif.sclk)) ||
//         (spicoreif.cfg_mode == 2'b11 && $rose(spicoreif.sclk))
//     ) && $past(spicoreif.busy))  
//     |-> ($past(spicoreif.mosi) == spicoreif.mosi);
// endproperty

// ast_r5_mosi_stable: assert property (p_r5_mosi_stable_sample);
// cov_r5_mosi_stable: cover  property (p_r5_mosi_stable_sample);


// //==================R6=======================
// property p_r6_tx_msb_first;//-------> hwa el width momkn yt8yr?
//     logic [31:0] tx;
//     @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
//     (!spicoreif.cfg_lsb_first && spicoreif.tx_pop, tx = spicoreif.tx_word)
//     |-> ##[1:4] (spicoreif.busy && spicoreif.mosi == tx[31]);
// endproperty

// property p_r6_rx_upper_zero_16;//-----------------msh sha8ala
//     @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
//     (spicoreif.rx_push_valid && spicoreif.cfg_width == 2'b01)
//     |-> (spicoreif.rx_push_data[31:16] == '0);
// endproperty

// ast_r6_tx_msb:     assert property (p_r6_tx_msb_first);
// ast_r6_rx_16bit:   assert property (p_r6_rx_upper_zero_16);

// cov_r6_tx_msb:     cover property (p_r6_tx_msb_first);
// cov_r6_rx_16bit:   cover property (p_r6_rx_upper_zero_16);

//====================R6=====================
property p_tx_first_bit;
    @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
    (spicoreif.tx_pop && spicoreif.cfg_mode[0] == 1'b0)
    |=> spicoreif.mosi == ($past(spicoreif.cfg_lsb_first) ?
        $past(spicoreif.tx_word[0]) :
        $past(spicoreif.tx_word[(spicoreif.cfg_width == 2'b00) ? 7 :
                                (spicoreif.cfg_width == 2'b01) ? 15 : 31]));
endproperty

ast_tx_first_bit: assert property (p_tx_first_bit);
cov_tx_first_bit: cover  property (p_tx_first_bit);

//==================R7=======================

// property p_busy_deasserts_after_done;
//     @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
//     (spicoreif.transfer_done_pulse && spicoreif.tx_empty)
//     |=> !spicoreif.busy;
// endproperty


// property p_busy_width_8;
//     @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
//     ($rose(spicoreif.busy) && spicoreif.cfg_width == 2'b00)
//     |-> spicoreif.busy [*1:$] ##1 spicoreif.transfer_done_pulse;
// endproperty

// ast_busy_width_8:          assert property (p_busy_width_8);
// ast_busy_deasserts_done:   assert property (p_busy_deasserts_after_done);

// //====================R8=====================
//     logic [16:0] half_period = {1'b0, spicoreif.cfg_clk_div} + 17'd1;
// property p_sclk_freq;
//     @(posedge spicoreif.pclk) disable iff (!spicoreif.presetn)
//     (spicoreif.busy && spicoreif.sclk == 1'b1)  |-> ##[1:512] $fell(spicoreif.sclk);        
// endproperty

// AST_SCLK_FREQ: assert property (p_sclk_freq);
// COV_SCLK_FREQ: cover property (p_sclk_freq);


//==================R21=======================

property p_r21_no_gap_delay_zero;
    @(posedge spicoreif.pclk) disable iff (~spicoreif.presetn)
    (spicoreif.transfer_done_pulse && 
     spicoreif.cfg_delay == 8'h0  &&
     spicoreif.tx_empty)           // no next word queued
    |=> !spicoreif.busy;
endproperty

ast_r21_no_gap_delay_zero: assert property (p_r21_no_gap_delay_zero);
cov_r21_no_gap_delay_zero: cover  property (p_r21_no_gap_delay_zero);
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