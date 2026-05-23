package master_shared_pkg;
    localparam [7:0] APB_CTRL     = 8'h00;
    localparam [7:0] APB_STATUS   = 8'h04;
    localparam [7:0] APB_TX_DATA  = 8'h08;
    localparam [7:0] APB_RX_DATA  = 8'h0C;
    localparam [7:0] APB_CLK_DIV  = 8'h10;
    localparam [7:0] APB_SS_CTRL  = 8'h14;
    localparam [7:0] APB_INT_EN   = 8'h18;
    localparam [7:0] APB_INT_STAT = 8'h1C;
    localparam [7:0] APB_DELAY    = 8'h20;

    // BFM signals
    logic      [1:0]  mode_pkg;         // {CPOL, CPHA} - from CTRL[3:2]
    logic             lsb_first_pkg;    // 1 = LSB-first, 0 = MSB-first - from CTRL[4]
    logic      [1:0]  width_cfg_pkg;    // 00=8b, 01=16b, 10=32b - from CTRL[7:6]
    logic      [31:0] miso_data_pkg;    // 32-bit pattern repeatedly returned on MISO
endpackage