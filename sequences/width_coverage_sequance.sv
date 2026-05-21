package width_coverage_sequence_pkg;
    import master_shared_pkg::*;
    import uvm_pkg::*;
    import master_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    task automatic apb_write_w(uvm_sequence_base seq,
                                input [7:0]  addr,
                                input [31:0] data);
        master_sequence_item seq_item;
        seq_item = master_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);
        seq_item.main_c.constraint_mode(1);
        repeat(3) begin 
            seq.start_item(seq_item);
            assert(seq_item.randomize() with {
                presetn == 1'b1;
                pwrite  == 1'b1;
                paddr   == addr;
                pwdata  == data;
            });
            seq.finish_item(seq_item);
        end
    endtask

    task automatic apb_read_w(uvm_sequence_base seq,
                               input [7:0] addr);
        master_sequence_item seq_item;
        seq_item = master_sequence_item::type_id::create("seq_item");
        seq_item.constraint_mode(0);
        seq_item.main_c.constraint_mode(1);
        repeat(3) begin 
            seq.start_item(seq_item);
            assert(seq_item.randomize() with{
                presetn == 1'b1;
                pwrite  == 1'b0;
                paddr   == addr;
                pwdata  == 32'h0;  // must be stable setup→access (pwdata_stable_S_A_as)
            });
            seq.finish_item(seq_item);
        end
    endtask

    task automatic idle_cycles(uvm_sequence_base seq, int n);
        master_sequence_item seq_item;
        seq_item = master_sequence_item::type_id::create("seq_item");
        // Idle state is deterministic — no randomize needed.
        // All constraints are OFF; force APB idle directly to avoid
        // spurious psel/penable=1 that would violate APB protocol assertions.
        seq_item.constraint_mode(0);
        seq_item.presetn = 1'b1;
        seq_item.psel    = 1'b0;
        seq_item.penable = 1'b0;
        seq_item.pwrite  = 1'b0;
        seq_item.paddr   = 8'h00;
        seq_item.pwdata  = 32'h0;
        repeat(n) begin
            seq.start_item(seq_item);
            seq.finish_item(seq_item);
        end
    endtask

    class width_rst_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_rst_sequence)

        function new(string name = "width_rst_sequence");
            super.new(name);
        endfunction

        task body();
            master_sequence_item seq_item;
            seq_item = master_sequence_item::type_id::create("seq_item");
            seq_item.constraint_mode(0);
            seq_item.main_c.constraint_mode(1);
            repeat(6) begin
                start_item(seq_item);
                assert(seq_item.randomize() with{
                    presetn == 1'b0;
                });
                finish_item(seq_item);
            end
        endtask
    endclass

    // =========================================================================
    // 2. width_8bit_sequence
    //    Configures the SPI master for 8-bit transfers (width=2'b00).
    //    Sends 8 boundary-value data words and reads back from RX FIFO.
    //    Transfer time at div=0: 2 * 8 * (0+1) = 16 PCLK cycles → use 20.
    // =========================================================================
    class width_8bit_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_8bit_sequence)

        // Boundary data for 8-bit transfers
        // [7:0] is the effective field; upper bits zeroed by RTL
        localparam bit [31:0] DATA_8[8] = '{
            32'h0000_0000,  // all-zeros
            32'h0000_00FF,  // all-ones  (8-bit max)
            32'h0000_0055,  // 0101_0101
            32'h0000_00AA,  // 1010_1010
            32'h0000_0001,  // LSB only
            32'h0000_007F,  // max positive signed 8-bit
            32'h0000_0080,  // min negative signed 8-bit
            32'h0000_00FE   // max-1
        };

        function new(string name = "width_8bit_sequence");
            super.new(name);
        endfunction
        task body();
            // CLK_DIV = 0 (fastest)
            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            apb_write_w(this, APB_CTRL,    32'h0000_0003);
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0001);

            foreach (DATA_8[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_8[i]);
                // Wait for transfer completion (16 cycles + margin)
                idle_cycles(this, 20);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard: ensure rx_push settled before pop
                apb_read_w(this, APB_RX_DATA);
            end

            // Also run with LSB-first to cover bit-order boundary
            apb_write_w(this, APB_CTRL, 32'h0000_0013); // lsb_first=1, width=8
            foreach (DATA_8[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_8[i]);
                idle_cycles(this, 20);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard
                apb_read_w(this, APB_RX_DATA);
            end

            // Deassert slave select
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);
        endtask
    endclass

    // =========================================================================
    // 3. width_16bit_sequence
    //    Configures the SPI master for 16-bit transfers (width=2'b01).
    //    Transfer time at div=0: 2 * 16 * (0+1) = 32 PCLK cycles → use 36.
    // =========================================================================
    class width_16bit_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_16bit_sequence)

        // Boundary data for 16-bit transfers; [15:0] is the effective field
        localparam bit [31:0] DATA_16[8] = '{
            32'h0000_0000,  // all-zeros
            32'h0000_FFFF,  // all-ones (16-bit max)
            32'h0000_5555,  // 0101...
            32'h0000_AAAA,  // 1010...
            32'h0000_0001,  // LSB only
            32'h0000_7FFF,  // max positive signed 16-bit
            32'h0000_8000,  // min negative signed 16-bit
            32'h0000_FFFE   // max-1
        };

        function new(string name = "width_16bit_sequence");
            super.new(name);
        endfunction

        task body();
            // Initialize SPI slave BFM — prevents miso = X
            width_cfg_pkg  = 2'b01;           // 16-bit
            mode_pkg       = 2'b00;           // SPI mode 0
            lsb_first_pkg  = 1'b0;            // MSB-first
            miso_data_pkg  = 32'hC3C3_C3C3;   // known non-X pattern

            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            // CTRL: width=01(16-bit), loopback=0, lsb_first=0, mode=00, master=1, en=1
            apb_write_w(this, APB_CTRL,    32'h0000_0043); // [7:6]=01
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0001);

            foreach (DATA_16[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_16[i]);
                idle_cycles(this, 36);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard
                apb_read_w(this, APB_RX_DATA);
            end

            // LSB-first variant
            apb_write_w(this, APB_CTRL, 32'h0000_0053); // lsb_first=1, width=16
            foreach (DATA_16[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_16[i]);
                idle_cycles(this, 36);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard
                apb_read_w(this, APB_RX_DATA);
            end

            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);
        endtask
    endclass

    // =========================================================================
    // 4. width_32bit_sequence
    //    Configures the SPI master for 32-bit transfers (width=2'b10).
    //    Transfer time at div=0: 2 * 32 * (0+1) = 64 PCLK cycles → use 70.
    // =========================================================================
    class width_32bit_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_32bit_sequence)

        // Boundary data for 32-bit transfers; all 32 bits are effective
        localparam bit [31:0] DATA_32[8] = '{
            32'h0000_0000,  // all-zeros
            32'hFFFF_FFFF,  // all-ones
            32'h5555_5555,  // 0101...
            32'hAAAA_AAAA,  // 1010...
            32'h0000_0001,  // LSB only
            32'h7FFF_FFFF,  // max positive signed 32-bit
            32'h8000_0000,  // min negative signed 32-bit
            32'hFFFE_FFFF   // max-ish
        };

        function new(string name = "width_32bit_sequence");
            super.new(name);
        endfunction

        task body();
            // Initialize SPI slave BFM — prevents miso = X
            width_cfg_pkg  = 2'b10;           // 32-bit
            mode_pkg       = 2'b00;           // SPI mode 0
            lsb_first_pkg  = 1'b0;            // MSB-first
            miso_data_pkg  = 32'hF0F0_F0F0;   // known non-X pattern

            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            // CTRL: width=10(32-bit), loopback=0, lsb_first=0, mode=00, master=1, en=1
            apb_write_w(this, APB_CTRL,    32'h0000_0083); // [7:6]=10
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0001);

            foreach (DATA_32[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_32[i]);
                // 2*32 + margin
                idle_cycles(this, 70);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard
                apb_read_w(this, APB_RX_DATA);
            end

            // LSB-first variant
            apb_write_w(this, APB_CTRL, 32'h0000_0093); // lsb_first=1, width=32
            foreach (DATA_32[i]) begin
                apb_write_w(this, APB_TX_DATA, DATA_32[i]);
                idle_cycles(this, 70);
                apb_read_w(this, APB_STATUS);
                idle_cycles(this, 2);  // guard
                apb_read_w(this, APB_RX_DATA);
            end

            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);
        endtask
    endclass

    // =========================================================================
    // 5. width_invalid_sequence
    // =========================================================================
    class width_invalid_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_invalid_sequence)

        function new(string name = "width_invalid_sequence");
            super.new(name);
        endfunction

        task body();
            // BFM init — prevents miso=X during invalid-width phase
            width_cfg_pkg  = 2'b00;
            mode_pkg       = 2'b00;
            lsb_first_pkg  = 1'b0;
            miso_data_pkg  = 32'hDEAD_BEEF;

            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            // Deassert SS — no slave selected, core cannot start a transfer
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);

            // Write CTRL with invalid width=2'b11:
            //   [7:6]=11(invalid), [5]=0, [4]=0, [3:2]=00, [1]=1(mstr), [0]=1(en)
            //   = 8'hC3  — core idle because SS deasserted + TX empty
            apb_write_w(this, APB_CTRL, 32'h0000_00C3);

            // Observe: with empty TX FIFO and no slave, busy must stay 0
            idle_cycles(this, 10);
            apb_read_w(this, APB_STATUS);

            // Recover: restore valid CTRL
            apb_write_w(this, APB_CTRL, 32'h0000_0003);
        endtask
    endclass

    // =========================================================================
    // 6. width_hot_swap_sequence
    //    8→16, 16→32, 32→8  (and again with LSB-first toggled)
    // =========================================================================
    class width_hot_swap_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_hot_swap_sequence)

        function new(string name = "width_hot_swap_sequence");
            super.new(name);
        endfunction

        // Utility: run one complete transfer at a given width, return wait cycles
        task run_transfer(input [1:0] width, input [31:0] data, input lsb_f);
            int wait_cyc;
            bit [31:0] ctrl_word;
            case (width)
                2'b00: wait_cyc = 21;   // 8-bit
                2'b01: wait_cyc = 36;   // 16-bit
                2'b10: wait_cyc = 75;   // 32-bit
                default: wait_cyc = 21;
            endcase
            // Build CTRL word: [7:6]=width, [5]=0(no loopback), [4]=lsb_f, [3:2]=mode00, [1:0]=11(master+en)
            ctrl_word = {24'h0, width, 1'b0, lsb_f, 2'b00, 2'b11};
            apb_write_w(this, APB_CTRL,    ctrl_word);
            apb_write_w(this, APB_TX_DATA, data);
            idle_cycles(this, wait_cyc);
            apb_read_w(this, APB_STATUS);
            idle_cycles(this, 2);  // guard: ensure rx_push settled before pop
            apb_read_w(this, APB_RX_DATA);
        endtask

        task body();
            master_sequence_item cfg_item;
            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0001); // slave 0

            // Width transition sequences: 8→16→32→8 (MSB-first)
            run_transfer(2'b00, 32'h0000_00A5, 1'b0); // 8-bit
            run_transfer(2'b01, 32'h0000_CAFE, 1'b0); // 16-bit
            run_transfer(2'b10, 32'hDEAD_BEEF, 1'b0); // 32-bit
            run_transfer(2'b00, 32'h0000_005A, 1'b0); // back to 8-bit

            // Width transition sequences: 8→16→32→8 (LSB-first)
            run_transfer(2'b00, 32'h0000_00FF, 1'b1);
            run_transfer(2'b01, 32'h0000_FFFF, 1'b1);
            run_transfer(2'b10, 32'hFFFF_FFFF, 1'b1);
            run_transfer(2'b00, 32'h0000_0000, 1'b1);

            // Randomised width coverage using width_coverage_c
            cfg_item = master_sequence_item::type_id::create("cfg_item");
            cfg_item.constraint_mode(0);
            cfg_item.main_c.constraint_mode(1);
            repeat(20) begin
                int wait_cyc;
                cfg_item.width_coverage_c.constraint_mode(1);
                assert(cfg_item.randomize());

                // Share global config with BFM
                width_cfg_pkg  = cfg_item.width_cfg_r;
                lsb_first_pkg  = cfg_item.pwdata[4];
                mode_pkg       = cfg_item.pwdata[3:2];
                assert(std::randomize(miso_data_pkg));

                case (cfg_item.width_cfg_r)
                    2'b00: wait_cyc = 21;
                    2'b01: wait_cyc = 36;
                    2'b10: wait_cyc = 75;
                    default: wait_cyc = 21;
                endcase

                apb_write_w(this, APB_CLK_DIV, {16'h0, cfg_item.div_r});
                apb_write_w(this, APB_CTRL,    {24'h0, cfg_item.width_cfg_r,
                                                1'b0,  cfg_item.pwdata[4],
                                                cfg_item.pwdata[3:2], 2'b11});
                apb_write_w(this, APB_SS_CTRL, {24'h0, cfg_item.ss_n_r});
                apb_write_w(this, APB_TX_DATA, cfg_item.data_r);
                idle_cycles(this, wait_cyc);
                apb_read_w(this, APB_STATUS);
                apb_read_w(this, APB_RX_DATA);
                apb_write_w(this, APB_SS_CTRL, 32'h0);
            end

            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);
        endtask
    endclass

    // =========================================================================
    // 7. width_all_modes_sequence
    //    Crosses all three widths with all four SPI modes to cover the
    //    combined width×mode space (12 unique configurations).
    //    Each config sends one boundary word and waits for completion.
    // =========================================================================
    class width_all_modes_sequence extends uvm_sequence #(master_sequence_item);
        `uvm_object_utils(width_all_modes_sequence)

        function new(string name = "width_all_modes_sequence");
            super.new(name);
        endfunction

        task body();
            // 3 widths × 4 modes = 12 combinations
            bit [1:0] widths[3]  = '{2'b00, 2'b01, 2'b10};
            bit [1:0] modes[4]   = '{2'b00, 2'b01, 2'b10, 2'b11};
            bit [31:0] data_vals[3] = '{32'h0000_00A5, 32'h0000_A55A, 32'hA55A_A55A};
            int wait_cyc;

            apb_write_w(this, APB_CLK_DIV, 32'h0000_0000);
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0001);

            foreach (widths[w]) begin
                foreach (modes[m]) begin
                    bit [31:0] ctrl_word;
                    ctrl_word = {24'h0, widths[w], 1'b0, 1'b0, modes[m], 2'b11};
                    case (widths[w])
                        2'b00: wait_cyc = 21;
                        2'b01: wait_cyc = 36;
                        2'b10: wait_cyc = 75;
                        default: wait_cyc = 21;
                    endcase

                    width_cfg_pkg = widths[w];
                    mode_pkg      = modes[m];
                    lsb_first_pkg = 1'b0;
                    assert(std::randomize(miso_data_pkg));
                    apb_write_w(this, APB_CTRL,    ctrl_word);
                    apb_write_w(this, APB_TX_DATA, data_vals[w]);
                    idle_cycles(this, wait_cyc);
                    apb_read_w(this, APB_STATUS);
                    idle_cycles(this, 2);  // guard: ensure rx_push settled before pop
                    apb_read_w(this, APB_RX_DATA);
                end
            end
            apb_write_w(this, APB_SS_CTRL, 32'h0000_0000);
        endtask
    endclass

endpackage
