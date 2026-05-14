package coverage_subscriber_pkg;
  import uvm_pkg::*;
  import master_shared_pkg::*;
  import master_sequence_item_pkg::*;
  `include "uvm_macros.svh"
  class coverage_subscriber extends uvm_subscriber #(master_sequence_item);
    `uvm_component_utils(coverage_subscriber)

    master_sequence_item seq_item_cov;

        // Added state variable to track if the module is currently enabled
        bit module_enabled = 0;

    /*covergroups*/
    covergroup modes_cg;
      option.per_instance = 1;

      cp_mode: coverpoint seq_item_cov.pwdata[3:2] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins mode0 = {2'b00};
        bins mode1 = {2'b01};
        bins mode2 = {2'b10};
        bins mode3 = {2'b11};
      }


      cp_lsb_first: coverpoint seq_item_cov.pwdata[4] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins msb_first = {0};
        bins lsb_first = {1};
      }

      cp_width: coverpoint seq_item_cov.pwdata[7:6] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins width_8 = {2'b00};
        bins width_16 = {2'b01};
        bins width_32 = {2'b10};
        ignore_bins invalid_width = {2'b11};
      }

      cp_loopback: coverpoint seq_item_cov.pwdata[5] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins loopback = {1'b1};
        bins no_loopback = {1'b0};
      }

      cross_mode_width_lsb_loopback: cross cp_mode, cp_width, cp_lsb_first, cp_loopback;


      cp_SS: coverpoint seq_item_cov.ss_n iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_SS_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins no_ss = {4'b1111};
        wildcard bins s_0 = {4'bxxx0};
        wildcard bins s_1 = {4'bxx0x};
        wildcard bins s_2 = {4'bx0xx};
        wildcard bins s_3 = {4'b0xxx};
      }

      cp_mode_transitions: coverpoint seq_item_cov.pwdata[3:2] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CTRL && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins m0_m[] = (0 => [1:3]);
        bins m1_m[] = (1 => 0,2,3);
        bins m2_m[] = (2 => [0:1],3);
        bins m3_m[] = (3 => [0:2]);
      }

      cp_div: coverpoint seq_item_cov.pwdata[15:0] iff (seq_item_cov.presetn && seq_item_cov.paddr == APB_CLK_DIV && seq_item_cov.pwrite && seq_item_cov.psel && !seq_item_cov.penable) {
        bins div_min = {0, 1};
        bins div_small[3] = {[2:1023]};
        bins div_large[6] = {[1024:65533]};
        bins div_max = {65534, 65535};
      }

      // cross modes with div ??

    endgroup

        // ---------------------------------------------------------
        // New Covergroup: cg_apb_silent_failures
        // ---------------------------------------------------------
        covergroup cg_apb_silent_failures;
            option.per_instance = 1;
            
            // NOTE: Replace APB_STATUS and APB_RX_DATA with your actual read-only macro names
            cp_paddr: coverpoint seq_item_cov.paddr iff (seq_item_cov.presetn && seq_item_cov.psel && !seq_item_cov.penable) {
                bins read_only_regs = {APB_STATUS, APB_RX_DATA}; 
                bins valid_rw_regs  = {APB_CTRL, APB_CLK_DIV, APB_SS_CTRL, APB_TX_DATA};
            }
            
            cp_pwrite: coverpoint seq_item_cov.pwrite iff (seq_item_cov.presetn && seq_item_cov.psel && !seq_item_cov.penable) {
                bins write_op = {1'b1};
                bins read_op  = {1'b0};
            }
            
            cx_illegal_access: cross cp_paddr, cp_pwrite {
                // Focus exclusively on writes to read-only addresses
                bins write_to_ro = binsof(cp_pwrite.write_op) && binsof(cp_paddr.read_only_regs);
            }
        endgroup

        // ---------------------------------------------------------
        // New Covergroup: cg_disabled_ops
        // ---------------------------------------------------------
        covergroup cg_disabled_ops;
            option.per_instance = 1;
            
            // NOTE: Replace APB_TX_DATA with your actual TX FIFO address macro
            cp_tx_write: coverpoint (seq_item_cov.paddr == APB_TX_DATA && seq_item_cov.pwrite == 1'b1) iff (seq_item_cov.presetn && seq_item_cov.psel && !seq_item_cov.penable) {
                bins attempt_push = {1'b1};
            }
            
            cp_enable_state: coverpoint module_enabled iff (seq_item_cov.presetn && seq_item_cov.psel && !seq_item_cov.penable) {
                bins disabled = {1'b0};
                bins enabled  = {1'b1};
            }
            
            cx_push_while_disabled: cross cp_tx_write, cp_enable_state {
                bins push_while_disabled = binsof(cp_tx_write.attempt_push) && binsof(cp_enable_state.disabled);
            }
        endgroup


    function new(string name = "coverage_subscriber", uvm_component parent);
      super.new(name, parent);
      modes_cg = new;
            cg_apb_silent_failures = new;
            cg_disabled_ops = new;
    endfunction

    // =========================================================================
    // Write function (Triggered whenever the Monitor sends an item)
    // =========================================================================
    virtual function void write(master_sequence_item t);
      this.seq_item_cov = t;

            // Track internal module enable state based on APB writes to the CTRL register
            // NOTE: I am assuming bit 0 of APB_CTRL is the SPI enable bit. Adjust the index if needed.
            if (t.presetn && t.psel && !t.penable && t.pwrite && t.paddr == APB_CTRL) begin
                module_enabled = t.pwdata[0]; 
            end

      modes_cg.sample();
            cg_apb_silent_failures.sample();
            cg_disabled_ops.sample();
    endfunction
    
    endclass 
endpackage