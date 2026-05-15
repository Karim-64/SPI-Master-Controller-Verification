// =============================================================================
// width_coverage_test.sv
// -----------------------------------------------------------------------------
// Edge-cases at width boundaries:
//   - 8-bit  (width_cfg = 2'b00): boundary data, MSB/LSB first
//   - 16-bit (width_cfg = 2'b01): boundary data, MSB/LSB first
//   - 32-bit (width_cfg = 2'b10): boundary data, MSB/LSB first
//   - Invalid width (2'b11): graceful handling
//   - Hot-swap: width changed between transfers
//   - All widths × all SPI modes crossed
// =============================================================================

package width_coverage_test_pkg;
    import uvm_pkg::*;
    import master_env_pkg::*;
    import master_config_pkg::*;
    import master_sequence_item_pkg::*;
    import spi_core_config_pkg::*;
    import apb_config_pkg::*;
    import apb_env_pkg::*;
    import spi_core_env_pkg::*;
    import width_coverage_sequence_pkg::*;

    `include "uvm_macros.svh"

    class width_coverage_test extends uvm_test;
        `uvm_component_utils(width_coverage_test)

        // Environments
        master_env      env;
        apb_env         apb_env_inst;
        spi_core_env    spi_core_env_inst;

        // Config objects
        master_config       master_cfg;
        apb_config          apb_object_inst;
        spi_core_config     spi_core_object_inst;

        // Sequences
        width_rst_sequence       rst_seq;
        width_8bit_sequence      seq_8bit;
        width_16bit_sequence     seq_16bit;
        width_32bit_sequence     seq_32bit;
        width_invalid_sequence   seq_invalid;
        width_hot_swap_sequence  seq_hot_swap;
        width_all_modes_sequence seq_all_modes;

        function new(string name = "width_coverage_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // -----------------------------------------------------------------
        // build_phase: create all components and get virtual interfaces
        // -----------------------------------------------------------------
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            env               = master_env::type_id::create("env",               this);
            apb_env_inst      = apb_env::type_id::create("apb_env_inst",         this);
            spi_core_env_inst = spi_core_env::type_id::create("spi_core_env_inst", this);

            master_cfg           = master_config::type_id::create("master_cfg");
            apb_object_inst      = apb_config::type_id::create("apb_object_inst");
            spi_core_object_inst = spi_core_config::type_id::create("spi_core_object_inst");

            // Create all sequences
            rst_seq       = width_rst_sequence::type_id::create("rst_seq");
            seq_8bit      = width_8bit_sequence::type_id::create("seq_8bit");
            seq_16bit     = width_16bit_sequence::type_id::create("seq_16bit");
            seq_32bit     = width_32bit_sequence::type_id::create("seq_32bit");
            seq_invalid   = width_invalid_sequence::type_id::create("seq_invalid");
            seq_hot_swap  = width_hot_swap_sequence::type_id::create("seq_hot_swap");
            seq_all_modes = width_all_modes_sequence::type_id::create("seq_all_modes");

            // Get virtual interfaces from config DB
            if (!uvm_config_db#(virtual master_if)::get(this, "", "MASTER_IF", master_cfg.master_vif))
                `uvm_fatal("build_phase", "Unable to get master virtual interface")

            if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_core_IF", spi_core_object_inst.spi_vif))
                `uvm_fatal("build_phase", "Unable to get spi_core virtual interface")

            if (!uvm_config_db#(virtual apb_if)::get(this, "", "APB_IF", apb_object_inst.apb_vif))
                `uvm_fatal("build_phase", "Unable to get APB virtual interface")

            // Set agent active/passive modes
            master_cfg.is_active           = UVM_ACTIVE;
            apb_object_inst.is_active      = UVM_PASSIVE;
            spi_core_object_inst.is_active = UVM_PASSIVE;

            // Publish configs to config DB
            uvm_config_db#(master_config)::set(this,   "*", "Master_CFG",   master_cfg);
            uvm_config_db#(apb_config)::set(this,      "*", "apb_CFG",      apb_object_inst);
            uvm_config_db#(spi_core_config)::set(this, "*", "spi_core_CFG", spi_core_object_inst);
        endfunction

        // -----------------------------------------------------------------
        // run_phase: execute sequences in order
        // -----------------------------------------------------------------
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            phase.raise_objection(this);

            `uvm_info("run_phase", "=== PHASE: Reset ===", UVM_LOW)
            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: 8-bit width boundary transfers ===", UVM_LOW)
            seq_8bit.start(env.agent.sqr);

            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: 16-bit width boundary transfers ===", UVM_LOW)
            seq_16bit.start(env.agent.sqr);

            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: 32-bit width boundary transfers ===", UVM_LOW)
            seq_32bit.start(env.agent.sqr);

            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: Invalid width encoding (2'b11) ===", UVM_LOW)
            seq_invalid.start(env.agent.sqr);

            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: Width hot-swap between transfers ===", UVM_LOW)
            seq_hot_swap.start(env.agent.sqr);

            rst_seq.start(env.agent.sqr);

            `uvm_info("run_phase", "=== PHASE: All widths x all SPI modes ===", UVM_LOW)
            seq_all_modes.start(env.agent.sqr);

            phase.drop_objection(this);
        endtask

    endclass

endpackage
