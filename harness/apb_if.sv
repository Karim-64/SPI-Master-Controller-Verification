interface apb_if (PCLK);
// interface input
input bit PCLK ; 

// input signals
bit presetn;
bit psel;
bit penable;
bit pwrite;
bit tx_pop;
bit rx_push_valid;
bit busy_in;
bit transfer_done_pulse;

logic [7:0]   paddr;
logic [31:0]  pwdata;
logic [31:0]  rx_push_data;
// dut output signal

bit pready;
bit pslverr;
bit cfg_en;
bit cfg_mstr;
bit cfg_lsb_first;
bit cfg_loopback;
bit tx_empty;
bit irq;

logic [1:0]   cfg_mode;
logic [1:0]   cfg_width;
logic [3:0]   ss_n;
logic [7:0]   cfg_delay;
logic [15:0]  cfg_clk_div;
logic [31:0]  tx_word;
logic [31:0]  prdata;

// output signals (golden model)
bit pready_exp;
bit pslverr_exp;
bit cfg_en_exp;
bit cfg_mstr_exp;
bit cfg_lsb_first_exp;
bit cfg_loopback_exp;
bit tx_empty_exp;
bit irq_exp;

logic [1:0]   cfg_mode_exp;
logic [1:0]   cfg_width_exp;
logic [3:0]   ss_n_exp;
logic [7:0]   cfg_delay_exp;
logic [15:0]  cfg_clk_div_exp;
logic [31:0]  tx_word_exp;
logic [31:0]  prdata_exp;

modport DUT (
    input  PCLK,presetn,psel,penable,pwrite,tx_pop,rx_push_valid,busy_in,transfer_done_pulse,paddr,pwdata,rx_push_data,  
    output pready,pslverr,cfg_en,cfg_mstr,cfg_lsb_first,cfg_loopback,tx_empty,irq,cfg_mode,
           cfg_width,ss_n,cfg_delay,cfg_clk_div,tx_word,prdata
);

modport apb_golden_model (
    input  PCLK,presetn,psel,penable,pwrite,tx_pop,rx_push_valid,busy_in,transfer_done_pulse,paddr,pwdata,rx_push_data,  
    output pready_exp,pslverr_exp,cfg_en_exp,cfg_mstr_exp,cfg_lsb_first_exp,cfg_loopback_exp,tx_empty_exp,irq_exp,cfg_mode_exp,
           cfg_width_exp,ss_n_exp,cfg_delay_exp,cfg_clk_div_exp,tx_word_exp,prdata_exp
);

endinterface