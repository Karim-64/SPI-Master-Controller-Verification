interface master_if (input bit pclk);
    // input signals
        logic presetn;
        logic psel;
        logic penable;
        logic pwrite;
        logic [7:0] paddr;
        logic [31:0] pwdata;
        logic miso;

    // dut output signal
        wire pready, pready_exp;
        wire pslverr, pslverr_exp;
        wire [31:0] prdata, prdata_exp;
        logic mosi, mosi_exp;
        logic [3:0] ss_n, ss_n_exp;
        logic sclk, sclk_exp;
        logic irq, irq_exp;

    modport slave(input pclk,
    input sclk, input mosi, input ss_n, input irq, output miso);

    modport DUT (
        input  pclk ,presetn,psel,penable,pwrite,paddr,pwdata,miso,
        output pready,pslverr,prdata,sclk,ss_n,irq,mosi
    );

    modport master_golden (
        input  pclk ,presetn,psel,penable,pwrite,paddr,pwdata,miso,
        output pready_exp,pslverr_exp,prdata_exp,sclk_exp,ss_n_exp,irq_exp,mosi_exp
    );

    modport tb (
        input pclk ,presetn,pready,pslverr,prdata,mosi,ss_n,sclk,irq,
        output psel,penable,pwrite,paddr,pwdata,miso
    );
endinterface