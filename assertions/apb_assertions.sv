module apb_SVA (apb_if.DUT apbif);
// R2
// test reset values of all registers   
always_comb begin
    if(~apbif.presetn)begin
       ctrl_en_rst:         assert final(apbif.cfg_en        == 1'b0);
       cfg_mstr_rst:        assert final(apbif.cfg_mstr      == 1'b0);
       cfg_mode_rst:        assert final(apbif.cfg_mode      == 2'b0);
       cfg_lsb_first_rst:   assert final(apbif.cfg_lsb_first == 1'b0);
       cfg_loopback_rst:    assert final(apbif.cfg_loopback  == 1'b0);
       cfg_width_rst:       assert final(apbif.cfg_width     == 2'b0);
       cfg_delay_rst:       assert final(apbif.cfg_delay     == 8'b0);
       ss_n_rst:            assert final(apbif.ss_n          == 4'b1111);
       cfg_clk_div_rst:     assert final(apbif.cfg_clk_div   == 16'b0);
       tx_word_RST:         assert final(apbif.tx_word       == 32'b0);
        tx_empty_rst:       assert final(apbif.tx_empty      == 1'b1);
        irq_rst:            assert final(apbif.irq           == 1'b0);    
        prdata_rst:          assert final(apbif.prdata       == 32'b0);

        //Control Register Reset test
        control_reg_rst:        assert final(DUT.u_dut.u_regfile.ctrl_word      == 32'h0);  
        //Status Register Reset test
        status_reg_rst:         assert final(DUT.u_dut.u_regfile.status_word    == 32'h0000_0014);
        // Clock Divider Register Reset test
        Clock_Divider_rst:      assert final(DUT.u_dut.u_regfile.clk_div_word   == 32'h0);
        // Slave Select Control Register Reset test
        Slave_Select_Control:   assert final(DUT.u_dut.u_regfile.ss_ctrl_word   == 32'h0);
        // INT_STAT Register Reset test
        int_stat_rst:           assert final(DUT.u_dut.u_regfile.int_stat_word  == 32'h0);
        // DELAY Register Reset test
        DELAY_rst:              assert final(DUT.u_dut.u_regfile.delay_word     == 32'h0);
        // INT_EN Register Reset test
        INT_EN_rst:             assert final(DUT.u_dut.u_regfile.int_en_word    == 32'h0);
        // TX_DATA Register Reset test
        tx_rp_rst:              assert final(DUT.u_dut.u_regfile.tx_rp == 0);
        tx_wp_rst:              assert final(DUT.u_dut.u_regfile.tx_wp == 0);

        TX_DATA_rst:            assert final((DUT.u_dut.u_regfile.tx_mem[0] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[1] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[2] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[3] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[4] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[5] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[6] == 0 &&
                                        DUT.u_dut.u_regfile.tx_mem[7] == 0));
        // RX_DATA Register Reset test
        rx_wp_rst:              assert final(DUT.u_dut.u_regfile.rx_wp == 0);
        rx_rp_rst:              assert final(DUT.u_dut.u_regfile.rx_rp == 0);

        RX_DATA_rst:            assert final((DUT.u_dut.u_regfile.rx_mem[0] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[1] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[2] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[3] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[4] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[5] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[6] == 0 &&
                                        DUT.u_dut.u_regfile.rx_mem[7] == 0));
    end
end

// test setup phase (psel should be asserted for one cycle and penable should be low)
property setup_phase;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) $rose(apbif.psel) |-> (apbif.penable == 0);
endproperty
setup_phase_as: assert property(setup_phase)
else $error("[ASSERTION_ERROR] setup_phase test fail");
cover property(setup_phase);

// test access phase (after setup phase, psel and penale should be high at the next cycle)
property access_phase;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) ($rose(apbif.psel) && ~apbif.penable) |=> (apbif.psel && apbif.penable);
endproperty
access_phase_as: assert property(access_phase)
else $error("[ASSERTION_ERROR] access_phase test fail");
cover property(access_phase);

// test penable in idle case should be zero while psel = zero
property penable_idle_case;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (~apbif.psel) |-> (~apbif.penable);
endproperty
penable_idle_case_as: assert property(penable_idle_case)
else $error("[ASSERTION_ERROR] penable_idle_case test fail");
cover property(penable_idle_case);

// test pwrite is stable during setup and access phases  
property pwrite_stable_S_A;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && ~apbif.penable) |=> $stable(apbif.pwrite);
endproperty
pwrite_stable_S_A_as: assert property(pwrite_stable_S_A)
else $error("[ASSERTION_ERROR] pwrite_stable_S_A test fail");
cover property(pwrite_stable_S_A);

// test pwdata is stable during setup and access phases 
property pwdata_stable_S_A;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && ~apbif.penable) |=> $stable(apbif.pwdata);
endproperty
pwdata_stable_S_A_as: assert property(pwdata_stable_S_A)
else $error("[ASSERTION_ERROR] pwdata_stable_S_A test fail");
cover property(pwdata_stable_S_A);

// test paddr is stable during setup and access phases 
property paddr_stable_S_A;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && ~apbif.penable) |=> $stable(apbif.paddr) ;
endproperty
paddr_stable_S_A_as: assert property(paddr_stable_S_A)
else $error("[ASSERTION_ERROR] paddr_stable_S_A test fail");
cover property(paddr_stable_S_A);

// ========================== R1==========================================
// check that control register updated correctly after each write operation
property CTRL_write_updates;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel && apbif.penable &&
     apbif.pwrite &&
     apbif.paddr == 8'h00)

    |=> (
        apbif.cfg_width     == $past(apbif.pwdata[7:6]) &&
        apbif.cfg_loopback  == $past(apbif.pwdata[5])   &&
        apbif.cfg_lsb_first == $past(apbif.pwdata[4])   &&
        apbif.cfg_mode      == $past(apbif.pwdata[3:2]) &&
        apbif.cfg_mstr      == $past(apbif.pwdata[1])   &&
        apbif.cfg_en        == $past(apbif.pwdata[0])
    );
endproperty
CTRL_write_updates_as: assert  property(CTRL_write_updates)
else $error("[ASSERTION_ERROR] CTRL_write_updates test fail");
cover property(CTRL_write_updates);

// check that prdata is correct after reading from control regisetr 
property CTRL_read_correct;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     !apbif.pwrite &&
     apbif.paddr == 8'h00)

    |-> (
        apbif.prdata[7:6] == apbif.cfg_width     &&
        apbif.prdata[5]   == apbif.cfg_loopback  &&
        apbif.prdata[4]   == apbif.cfg_lsb_first &&
        apbif.prdata[3:2] == apbif.cfg_mode      &&
        apbif.prdata[1]   == apbif.cfg_mstr      &&
        apbif.prdata[0]   == apbif.cfg_en
    );
endproperty
CTRL_read_correct_as: assert  property(CTRL_read_correct)
else $error("[ASSERTION_ERROR] CTRL_read_correct test fail");
cover property(CTRL_read_correct);

// check that prdata is correct after reading from Status regisetr (Read Only register)
property status_read_correct;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     !apbif.pwrite &&
     apbif.paddr == 8'h04)

    |-> (apbif.prdata[31:0] == DUT.u_dut.u_regfile.status_word[31:0]);
endproperty
status_read_correct_as: assert  property(status_read_correct)
else $error("[ASSERTION_ERROR] status_read_correct test fail");
cover property(status_read_correct);

// check that clk divider register updated correctly after each write operation
property CLKDIV_write;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel && apbif.penable &&
     apbif.pwrite &&
     apbif.paddr == 8'h10)

    |=> (apbif.cfg_clk_div == $past(apbif.pwdata[15:0]));
endproperty
CLKDIV_write_as: assert  property(CLKDIV_write)
else $error("[ASSERTION_ERROR] CLKDIV_write test fail");
cover property(CLKDIV_write);

// check that prdata is correct after reading from clk divider register
property CLKDIV_read_correct;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     !apbif.pwrite &&
     apbif.paddr == 8'h10)

    |-> (
        apbif.prdata[15:0] == apbif.cfg_clk_div
    );
endproperty
CLKDIV_read_correct_as: assert  property(CLKDIV_read_correct)
else $error("[ASSERTION_ERROR] CLKDIV_read_correct test fail");
cover property(CLKDIV_read_correct);

// check that Delay register updated correctly after each write operation
property DELAY_write;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel && apbif.penable &&
     apbif.pwrite &&
     apbif.paddr == 8'h20)

    |=> (apbif.cfg_delay == $past(apbif.pwdata[7:0]));
endproperty
DELAY_write_as: assert  property(DELAY_write)
else $error("[ASSERTION_ERROR] DELAY_write test fail");
cover property(DELAY_write);

// check that prdata is correct after reading from the Delay register
property DELAY_read_correct;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     !apbif.pwrite &&
     apbif.paddr == 8'h20)

    |-> (
        apbif.prdata[7:0] == apbif.cfg_delay
    );
endproperty
DELAY_read_correct_as: assert  property(DELAY_read_correct)
else $error("[ASSERTION_ERROR] DELAY_read_correct test fail");
cover property(DELAY_read_correct);

//=====================================R10=====================================
// correct pop from fifo
property pop_correct;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && ~apbif.pwrite 
    && apbif.paddr == 8'h0C && ~DUT.u_dut.u_regfile.rx_empty_w) 
    |=> (DUT.u_dut.u_regfile.rx_rp == $past(DUT.u_dut.u_regfile.rx_rp) + 1);
endproperty
pop_correct_as: assert  property(pop_correct)
else $error("[ASSERTION_ERROR] pop_correct test fail");
cover property(pop_correct);


// ==========================R11==========================
// test tx_empty is fired when tx fifo is empty
property tx_empty_high;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (DUT.u_dut.u_regfile.tx_count == 0) |-> (apbif.tx_empty == 1);
endproperty
tx_empty_high_as: assert  property(tx_empty_high)
else $error("[ASSERTION_ERROR] tx_empty_high test fail");
cover property(tx_empty_high);

// test full is fired when tx fifo is full
property tx_full_high;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (DUT.u_dut.u_regfile.tx_count == DUT.u_dut.u_regfile.FIFO_DEPTH) |-> (DUT.u_dut.u_regfile.tx_full_w == 1'b1);
endproperty
tx_full_high_as: assert  property(tx_full_high)
else $error("[ASSERTION_ERROR] tx_full_high test fail");
cover property(tx_full_high);

// =====================R12=====================
// test rx empty is fired when rx fifo is empty
property rx_empty_high;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (DUT.u_dut.u_regfile.rx_count == 1'b0) |-> (DUT.u_dut.u_regfile.rx_empty_w == 1'b1);
endproperty
rx_empty_high_as: assert  property(rx_empty_high)
else $error("[ASSERTION_ERROR] rx_empty_high test fail");
cover property(rx_empty_high);

// test full is fired when rx fifo is full
property rx_full_high;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (DUT.u_dut.u_regfile.rx_count == DUT.u_dut.u_regfile.FIFO_DEPTH) |-> (DUT.u_dut.u_regfile.rx_full_w == 1'b1);
endproperty
rx_full_high_as: assert  property(rx_full_high)
else $error("[ASSERTION_ERROR] rx_full_high test fail");
cover property(rx_full_high);
// =============================R13=============================
// test tx overflow
property tx_ovf;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && apbif.pwrite && apbif.paddr == 8'h08 && DUT.u_dut.u_regfile.tx_full_w) 
    |=> ( DUT.u_dut.u_regfile.int_stat[DUT.u_dut.u_regfile.IRQ_TX_OVF] == 1'b1);
endproperty
tx_ovf_as: assert  property(tx_ovf)
else $error("[ASSERTION_ERROR] tx_ovf test fail");
cover property(tx_ovf);
// =======================R14=======================
// test rx overflow
property rx_ovf;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (DUT.u_dut.u_regfile.rx_full_w && DUT.u_dut.u_regfile.rx_push_valid) |=> ( DUT.u_dut.u_regfile.int_stat[DUT.u_dut.u_regfile.IRQ_RX_OVF] == 1'b1);
endproperty
rx_ovf_as: assert  property(rx_ovf)
else $error("[ASSERTION_ERROR] rx_ovf test fail");
cover property(rx_ovf);


// ==============================R15==============================
// read zero when rx fifo is empty 
property rx_empty;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && ~apbif.pwrite 
    && apbif.paddr == 8'h0C && DUT.u_dut.u_regfile.rx_empty_w) 
    |-> (apbif.prdata == 32'b0);
endproperty
rx_empty_as: assert  property(rx_empty)
else $error("[ASSERTION_ERROR] rx_empty test fail");
cover property(rx_empty);

// ==============================R16==============================
property irq_disabled;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)
    (
        apbif.psel &&
        apbif.penable &&
        apbif.pwrite &&
        apbif.paddr == 8'h18 &&
        apbif.pwdata[4:0] == 5'b0
    )
    |=> (apbif.irq == 1'b0);

endproperty
irq_disabled_as: assert property(irq_disabled)
else $error("[ASSERTION_ERROR] irq_disabled test fail");
cover property(irq_disabled);


property irq_equation;   
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.irq == |(DUT.u_dut.u_regfile.int_stat & DUT.u_dut.u_regfile.int_en));
endproperty
irq_equation_as: assert  property(irq_equation)
else $error("[ASSERTION_ERROR] irq_equation test fail");
cover property(irq_equation);

property SS_asserted_before_TX_write;
    @(posedge apbif.PCLK)
    disable iff(!apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     apbif.pwrite &&
     apbif.paddr == 8'h08)

    |=>  (apbif.ss_n != 4'b1111);
endproperty

SS_asserted_before_TX_write_as:assert property(SS_asserted_before_TX_write)
else $error("[ASSERTION_ERROR] SS_asserted_before_TX_write test fail");
cover property(SS_asserted_before_TX_write);

// ========================= W1C RACE CONDITION =========================
wire [4:0] apb_read_int_stat = DUT.u_dut.u_regfile.int_stat;

property w1c_race_transfer_done;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)

    (
        apbif.psel &&
        apbif.penable &&
        apbif.pwrite &&
        apbif.paddr == 8'h1C &&
        apbif.pwdata[4] &&
        apbif.transfer_done_pulse
    )
    |=> ##0 (apb_read_int_stat[4] == 1'b1);
endproperty

w1c_race_transfer_done_as: assert property(w1c_race_transfer_done)
else $error("[ASSERTION_ERROR] w1c_race_transfer_done test fail");
cover property(w1c_race_transfer_done);

property w1c_race_tx_ovf;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)

    (
        apbif.psel &&
        apbif.penable &&
        apbif.pwrite &&
        apbif.paddr == 8'h1C &&
        apbif.pwdata[2] &&
        DUT.u_dut.u_regfile.tx_push_dropped
    )
    |=> ##0 (apb_read_int_stat[2] == 1'b1);
endproperty

w1c_race_tx_ovf_as: assert property(w1c_race_tx_ovf)
else $error("[ASSERTION_ERROR] w1c_race_tx_ovf test fail");
cover property(w1c_race_tx_ovf);

// ======================== W1C CLEAR TEST (TX_OVF) ========================
// Verifies that a W1C write to INT_STAT clears the TX_OVF bit when it's set
property w1c_clear_tx_ovf;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)

    (
        apb_read_int_stat[2] &&                // TX_OVF is currently set
        apbif.psel &&
        apbif.penable &&
        apbif.pwrite &&
        apbif.paddr == 8'h1C &&
        apbif.pwdata[2]                        // Clear TX_OVF bit (W1C)
    )
    |=> (apb_read_int_stat[2] == 1'b0);        // Should be cleared in the next cycle
endproperty

w1c_clear_tx_ovf_as: assert property(w1c_clear_tx_ovf)
else $error("[ASSERTION_ERROR] w1c_clear_tx_ovf test fail");
cover property(w1c_clear_tx_ovf);

// ================================R20================================
// check that slave control register updated correctly after each write operation
property ss_n_correct;
    @(posedge apbif.PCLK)
    disable iff(~apbif.presetn)

    (apbif.psel &&
     apbif.penable &&
     apbif.pwrite &&
     apbif.paddr == 8'h14)

    |=> (
        apbif.ss_n ==
        ((~$past(apbif.pwdata[3:0])) |
          $past(apbif.pwdata[7:4]))
    );
endproperty

ss_n_correct_as: assert property(ss_n_correct)
else $error("[ASSERTION_ERROR] ss_n_correct test fail");
cover property(ss_n_correct);

// check that prdata is correct after reading from the ssn control register
property SS_CTRL_read_correct;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)(apbif.psel && apbif.penable && ~apbif.pwrite && apbif.paddr == 8'h14)
    |-> (apbif.prdata[31:0] == DUT.u_dut.u_regfile.ss_ctrl_word[31:0]);
endproperty
SS_CTRL_read_correct_as: assert property(SS_CTRL_read_correct)
else $error("[ASSERTION_ERROR] SS_CTRL_read_correct fail");
cover property(SS_CTRL_read_correct);

// check that prdata is correct after reading from the INT_EN register
property INT_EN_read_correct;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)(apbif.psel && apbif.penable && ~apbif.pwrite && apbif.paddr == 8'h18)
    |-> (apbif.prdata[31:0] == DUT.u_dut.u_regfile.int_en_word[31:0]);
endproperty
INT_EN_read_correct_as: assert property(INT_EN_read_correct)
else $error("[ASSERTION_ERROR] INT_EN_read_correct fail");
cover property(INT_EN_read_correct);

// check that prdata is correct after reading from the INT_STAT register
property INT_STAT_read_correct;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)(apbif.psel && apbif.penable && ~apbif.pwrite && apbif.paddr == 8'h1C)
    |-> (apbif.prdata[31:0] == DUT.u_dut.u_regfile.int_stat_word[31:0]);
endproperty
INT_STAT_read_correct_as: assert property(INT_STAT_read_correct)
else $error("[ASSERTION_ERROR] INT_STAT_read_correct fail");
cover property(INT_STAT_read_correct);

// make sure that TX_DATA is write only register can not read from it 
property TX_DATA_read_zero;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK)(apbif.psel && apbif.penable && ~apbif.pwrite && apbif.paddr == 8'h08)
    |-> (apbif.prdata == 32'h0);
endproperty
TX_DATA_read_zero_as: assert property(TX_DATA_read_zero)
else $error("[ASSERTION_ERROR] TX_DATA_read_zero fail");
cover property(TX_DATA_read_zero);

// =========================R22=========================
// test pready  should be high all the time 
property pready_1;
    @(posedge apbif.PCLK) (apbif.pready);
endproperty
pready_1_as: assert  property(pready_1)
else $error("[ASSERTION_ERROR] pready_1 test fail");
cover property(pready_1);

// test pslverr should be low all the time 
property pslverr_0;
    @(posedge apbif.PCLK) ~(apbif.pslverr);
endproperty
pslverr_0_as: assert  property(pslverr_0)
else $error("[ASSERTION_ERROR] pslverr_0 test fail");
cover property(pslverr_0);

// ==================================R23==================================
// test paddr is 4 byte allgigned (its first 2 bits always zero or modulus 4 = 0)
property paddr_correct_val;
    @(posedge apbif.PCLK) (apbif.paddr % 4 == 0);
endproperty
paddr_correct_val_as: assert  property(paddr_correct_val)
else $error("[ASSERTION_ERROR] paddr_correct_val test fail");
cover property(paddr_correct_val);

// test prdata is zero if paddr >= 24 in read case      
property prdata_correct_val;
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && ~apbif.pwrite &&(apbif.paddr >= 8'h24))
    |-> apbif.prdata == 32'h0;  // read is combinational
endproperty
prdata_correct_val_as: assert  property(prdata_correct_val)
else $error("[ASSERTION_ERROR] prdata_correct_val test fail");
cover property(prdata_correct_val);

// ignore any write when paddr >= 24  (write is sequential)   
property ignore_CTRL_write;      // write 
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && apbif.pwrite &&(apbif.paddr >= 8'h24))
    |=> $stable(DUT.u_dut.u_regfile.ctrl_word);
endproperty
ignore_CTRL_write_as: assert  property(ignore_CTRL_write)
else $error("[ASSERTION_ERROR] ignore_CTRL_write test fail");
cover property(ignore_CTRL_write);

property ignore_CLK_DIV_write;      // write
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && apbif.pwrite &&(apbif.paddr >= 8'h24))
    |=> $stable(DUT.u_dut.u_regfile.clk_div_word);
endproperty
ignore_CLK_DIV_write_as: assert  property(ignore_CLK_DIV_write)
else $error("[ASSERTION_ERROR] ignore_CLK_DIV_write test fail");
cover property(ignore_CLK_DIV_write);

property ignore_SS_CTRL_write;      // write
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable &&(apbif.paddr >= 8'h24) && apbif.pwrite ) 
    |=> $stable(DUT.u_dut.u_regfile.ss_ctrl_word);
endproperty
ignore_SS_CTRL_write_as: assert  property(ignore_SS_CTRL_write)
else $error("[ASSERTION_ERROR] ignore_SS_CTRL_write test fail");
cover property(ignore_SS_CTRL_write);

property ignore_INT_EN_write;      // write
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && apbif.pwrite &&(apbif.paddr >= 8'h24))
    |=> $stable(DUT.u_dut.u_regfile.int_en_word);
endproperty
ignore_INT_EN_write_as: assert  property(ignore_INT_EN_write)
else $error("[ASSERTION_ERROR] ignore_INT_EN_write test fail");
cover property(ignore_INT_EN_write);

property ignore_Delay_write;      // write
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) (apbif.psel && apbif.penable && apbif.pwrite &&(apbif.paddr >= 8'h24))
    |=> $stable(DUT.u_dut.u_regfile.delay_word);
endproperty
ignore_Delay_write_as: assert  property(ignore_Delay_write)
else $error("[ASSERTION_ERROR] ignore_Delay_write test fail");
cover property(ignore_Delay_write);

property ignore_TX_DATA_write;      // write
    disable iff(~apbif.presetn)
    @(posedge apbif.PCLK) ((apbif.paddr >= 8'h24) && apbif.pwrite ) |=> $stable(DUT.u_dut.u_regfile.tx_mem[7:0]);
endproperty
ignore_TX_DATA_write_as: assert  property(ignore_TX_DATA_write)
else $error("[ASSERTION_ERROR] ignore_TZ_DATA_write test fail");
cover property(ignore_TX_DATA_write);




endmodule