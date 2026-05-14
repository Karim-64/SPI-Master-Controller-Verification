`ifndef SPI_SLAVE_BFM_SV
`define SPI_SLAVE_BFM_SV

module spi_slave_bfm (
    spi_if.slave  spi,              
    input  logic  [1:0]  mode,        // {CPOL, CPHA} - from CTRL[3:2]
    input  logic         lsb_first,   // 1 = LSB-first, 0 = MSB-first - from CTRL[4]
    input  logic  [1:0]  width_cfg,   // 00=8b, 01=16b, 10=32b - from CTRL[7:6]
    input  logic  [31:0] miso_data    // 32-bit pattern repeatedly returned on MISO
);

    logic sclk_q;   // SCLK previous value for edge detection
    int   bit_idx;  // which bit of miso_data is currently on the line
    logic first_edge_done; // Flag for CPHA=1 first-bit logic

    wire cpol   = mode[1];
    wire cpha   = mode[0];
    wire ss_act = (spi.ss_n != 4'hF); // Active if any bit is low

    // 1. Decode actual width based on CTRL.WIDTH encoding
    wire [5:0] actual_width = (width_cfg == 2'b10) ? 32 : 
                              (width_cfg == 2'b01) ? 16 : 8;

    // 2. Identify the starting bit based on endianness
    wire [5:0] start_bit = lsb_first ? 0 : (actual_width - 1);

    // 3. Helper signals for edge detection
    wire sclk_rise = (sclk_q === 1'b0 && spi.sclk === 1'b1);
    wire sclk_fall = (sclk_q === 1'b1 && spi.sclk === 1'b0);

    // 4. Generic launch edge equation derived from SPI spec
    wire launch_edge = (cpol ^ cpha) ? sclk_rise : sclk_fall;

    initial begin
        spi.miso <= 1'b0;
        sclk_q  = cpol; // Assume idle state initially
        bit_idx = start_bit;
        first_edge_done = 1'b0;
    end

    // CHANGED TO NEGEDGE: Avoids delta-cycle races with the Master
    always @(negedge spi.pclk) begin
        // Keep track of SCLK for edge detection in the next cycle
        sclk_q <= spi.sclk;

        if (!ss_act) begin
            // RESET STATE: When slave is not selected, reset the index pointer 
            // and pre-drive the first bit onto MISO so it's ready for the master.
            bit_idx <= start_bit;
            spi.miso <= miso_data[start_bit];
            first_edge_done <= 1'b0; // Reset our flag
            
        end else if (launch_edge) begin
            // SHIFT STATE: Advance to the next bit on the appropriate launch edge
            
            // Fix for CPHA=1: Hold the first bit on the very first launch edge
            if (cpha == 1'b1 && !first_edge_done) begin
                first_edge_done <= 1'b1;
                spi.miso <= miso_data[start_bit];
            end else begin
                // Normal shift logic
                if (lsb_first) begin
                    // Count UP, wrap around at (actual_width - 1)
                    bit_idx <= (bit_idx == actual_width - 1) ? 0 : bit_idx + 1;
                    spi.miso <= miso_data[(bit_idx == actual_width - 1) ? 0 : bit_idx + 1];
                end else begin
                    // Count DOWN, wrap around at 0
                    bit_idx <= (bit_idx == 0) ? actual_width - 1 : bit_idx - 1;
                    spi.miso <= miso_data[(bit_idx == 0) ? actual_width - 1 : bit_idx - 1];
                end
            end
        end
    end

endmodule
`endif