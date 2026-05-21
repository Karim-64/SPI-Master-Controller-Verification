// =============================================================================
// comprehensive_test.sv
// =============================================================================
// This is a unified test that combines ALL sequences and phases from all 
// individual test files into a single comprehensive test.
// All sequences are instantiated and executed in the run_phase to provide
// complete stimulus coverage in a single simulation.
// =============================================================================

package comprehensive_test_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

// --- Master Side Imports ---
import master_env_pkg::*;
import master_config_pkg::*;
import master_shared_pkg::*;
import master_sequence_item_pkg::*;
import master_sequence_pkg::*;

// --- APB Side Imports ---
import apb_env_pkg::*;
import apb_config_pkg::*;

// --- SPI Core Side Imports ---
import spi_core_env_pkg::*;
import spi_core_config_pkg::*;

// --- Sequence Package Imports (from access_reg_test) ---
// Already imported via master_sequence_pkg

// --- Sanity Test Sequences ---
import sanity_sequence_pkg::*;

// --- Loopback Test Sequences ---
import loopback_sequence_pkg::*;

// --- Error Injection Test Sequences ---
import error_enjection_sequence_pkg::*;

// --- Delay Transfer Test Sequences ---
import delay_transfer_sequence_pkg::*;

// --- Clock Divider Corner Test Sequences ---
import div_sequence_pkg::*;

// --- Mode Coverage Test Sequences ---
import modes_sequence_pkg::*;

// --- FIFO Stress Test Sequences ---
import master_fifo_stress_sequence_pkg::*;

// --- Width Coverage Test Sequences ---
import width_coverage_sequence_pkg::*;
import master_interrupts_sequence_pkg ::*;

import interrupts_pkg::*;


//=============================================================================
// CLASS: comprehensive_test
//=============================================================================
// This test instantiates and executes ALL sequences from all test files
//=============================================================================
class comprehensive_test extends uvm_test;

    `uvm_component_utils(comprehensive_test)

    // =========================================================================
    // ENVIRONMENTS
    // =========================================================================
    master_env      env;
    apb_env         abp_env_inst;
    spi_core_env    spi_core_env_inst;

    // =========================================================================
    // CONFIGURATION OBJECTS
    // =========================================================================
    master_config       master_cfg;
    apb_config          apb_object_inst;
    spi_core_config     spi_core_object_inst;

    virtual master_if   master_vif;
<<<<<<< HEAD
=======
    virtual apb_if apb_vif;
>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939

    // =========================================================================
    // SEQUENCES FROM ACCESS_REG_TEST (master_access_test sequences)
    // =========================================================================
<<<<<<< HEAD
    master_sequence_pkg::master_rst_sequence                 access_rst_seq;
=======
    //master_rst_sequence                 access_rst_seq;
    master_sequence_pkg::master_rst_sequence access_rst_seq;
>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939
    master_Write_read_sequence          access_write_read_sequence;
    master_ctrl_sequence                access_ctrl_seq;
    master_CLK_DIV_sequence             access_clk_div_seq;
    master_Delay_sequence               access_delay_seq;
    master_ss_ctrl_sequence             access_ss_ctrl_seq;
    master_status_sequence              access_status_seq;
    master_violate_write_read_sequance  access_violate_write_read_seq;
<<<<<<< HEAD
=======
    //master_interrupts_sequence interrupts_seq;

>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939

    // =========================================================================
    // SEQUENCES FROM SANITY_TEST
    // =========================================================================
    sanity_rst_sequence     sanity_rst_seq;
    sanity_ctrl_sequence    sanity_ctrl_seq;

    // =========================================================================
    // SEQUENCES FROM LOOPBACK_TEST
    // =========================================================================
    loopback_rst_sequence               loopback_rst_seq;
    loopback_ctrl_randomized_sequence   loopback_ctrl_randomized_seq;
    loopback_directed_sequence          loopback_directed_seq;

    // =========================================================================
    // SEQUENCES FROM ERROR_INJECTION_TEST
    // =========================================================================
    error_rst_sequence          error_rst_seq;
    error_enjection_sequence    error_injection_seq;

    // =========================================================================
    // SEQUENCES FROM DELAY_TRANSFER_TEST
    // =========================================================================
    delay_transfer_rst_sequence  delay_transfer_rst_seq;
    delay_transfer_sequence      delay_transfer_seq;

    // =========================================================================
    // SEQUENCES FROM CLK_DIV_CORNER_TEST
    // =========================================================================
    div_rst_sequence    div_rst_seq;
    div_sequence        div_seq;

    // =========================================================================
    // SEQUENCES FROM MODE_COVERAGE_TEST
    // =========================================================================
    modes_rst_sequence          modes_rst_seq;
    modes_crossing_sequence     modes_crossing_seq;
    no_SS_sequence              no_ss_seq;

    // =========================================================================
    // SEQUENCES FROM FIFO_STRESS_TEST
    // =========================================================================
<<<<<<< HEAD
    master_fifo_stress_sequence_pkg::master_rst_sequence         fifo_stress_rst_seq;
=======
    //master_rst_sequence         fifo_stress_rst_seq;
    master_sequence_pkg::master_rst_sequence fifo_stress_rst_seq;
>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939
    fifo_stress_sequence        fifo_stress_seq;

    // =========================================================================
    // SEQUENCES FROM WIDTH_COVERAGE_TEST
    // =========================================================================
    width_rst_sequence          width_rst_seq;
    width_8bit_sequence         width_8bit_seq;
    width_16bit_sequence        width_16bit_seq;
    width_32bit_sequence        width_32bit_seq;
    width_invalid_sequence      width_invalid_seq;
    width_hot_swap_sequence     width_hot_swap_seq;
    width_all_modes_sequence    width_all_modes_seq;

    // =========================================================================
    // CONSTRUCTOR
    // =========================================================================
    function new(string name = "comprehensive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // =========================================================================
    // BUILD_PHASE
    // =========================================================================
    // This phase creates all environments, configurations, and sequences
    // =========================================================================
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // ===================================================================
        // CREATE ENVIRONMENTS
        // ===================================================================
        env               = master_env::type_id::create("env", this);
        abp_env_inst      = apb_env::type_id::create("abp_env_inst", this);
        spi_core_env_inst = spi_core_env::type_id::create("spi_core_env_inst", this);

        // ===================================================================
        // CREATE CONFIGURATION OBJECTS
        // ===================================================================
        master_cfg           = master_config::type_id::create("master_cfg");
        apb_object_inst      = apb_config::type_id::create("apb_object_inst");
        spi_core_object_inst = spi_core_config::type_id::create("spi_core_object_inst");

        // ===================================================================
        // CREATE SEQUENCES FROM ACCESS_REG_TEST
        // ===================================================================
        access_rst_seq                 = master_sequence_pkg::master_rst_sequence::type_id::create("access_rst_seq");
        access_write_read_sequence     = master_Write_read_sequence::type_id::create("access_write_read_sequence");
        access_ctrl_seq                = master_ctrl_sequence::type_id::create("access_ctrl_seq");
        access_clk_div_seq             = master_CLK_DIV_sequence::type_id::create("access_clk_div_seq");
        access_delay_seq               = master_Delay_sequence::type_id::create("access_delay_seq");
        access_ss_ctrl_seq             = master_ss_ctrl_sequence::type_id::create("access_ss_ctrl_seq");
        access_status_seq              = master_status_sequence::type_id::create("access_status_seq");
        access_violate_write_read_seq  = master_violate_write_read_sequance::type_id::create("access_violate_write_read_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM SANITY_TEST
        // ===================================================================
        sanity_rst_seq    = sanity_rst_sequence::type_id::create("sanity_rst_seq");
        sanity_ctrl_seq   = sanity_ctrl_sequence::type_id::create("sanity_ctrl_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM LOOPBACK_TEST
        // ===================================================================
        loopback_rst_seq               = loopback_rst_sequence::type_id::create("loopback_rst_seq");
        loopback_ctrl_randomized_seq   = loopback_ctrl_randomized_sequence::type_id::create("loopback_ctrl_randomized_seq");
        loopback_directed_seq          = loopback_directed_sequence::type_id::create("loopback_directed_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM ERROR_INJECTION_TEST
        // ===================================================================
        error_rst_seq      = error_rst_sequence::type_id::create("error_rst_seq");
        error_injection_seq = error_enjection_sequence::type_id::create("error_injection_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM DELAY_TRANSFER_TEST
        // ===================================================================
        delay_transfer_rst_seq = delay_transfer_rst_sequence::type_id::create("delay_transfer_rst_seq");
        delay_transfer_seq     = delay_transfer_sequence::type_id::create("delay_transfer_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM CLK_DIV_CORNER_TEST
        // ===================================================================
        div_rst_seq = div_rst_sequence::type_id::create("div_rst_seq");
        div_seq     = div_sequence::type_id::create("div_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM MODE_COVERAGE_TEST
        // ===================================================================
        modes_rst_seq       = modes_rst_sequence::type_id::create("modes_rst_seq");
        modes_crossing_seq  = modes_crossing_sequence::type_id::create("modes_crossing_seq");
        no_ss_seq           = no_SS_sequence::type_id::create("no_ss_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM FIFO_STRESS_TEST
        // ===================================================================
<<<<<<< HEAD
        fifo_stress_rst_seq = master_fifo_stress_sequence_pkg::master_rst_sequence::type_id::create("fifo_stress_rst_seq");
=======
        fifo_stress_rst_seq = master_sequence_pkg::master_rst_sequence::type_id::create("fifo_stress_rst_seq");
>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939
        fifo_stress_seq     = fifo_stress_sequence::type_id::create("fifo_stress_seq");

        // ===================================================================
        // CREATE SEQUENCES FROM WIDTH_COVERAGE_TEST
        // ===================================================================
        width_rst_seq         = width_rst_sequence::type_id::create("width_rst_seq");
        width_8bit_seq        = width_8bit_sequence::type_id::create("width_8bit_seq");
        width_16bit_seq       = width_16bit_sequence::type_id::create("width_16bit_seq");
        width_32bit_seq       = width_32bit_sequence::type_id::create("width_32bit_seq");
        width_invalid_seq     = width_invalid_sequence::type_id::create("width_invalid_seq");
        width_hot_swap_seq    = width_hot_swap_sequence::type_id::create("width_hot_swap_seq");
        width_all_modes_seq   = width_all_modes_sequence::type_id::create("width_all_modes_seq");

        // ===================================================================
        // GET VIRTUAL INTERFACES FROM CONFIG DB
        // ===================================================================
        if (!uvm_config_db#(virtual master_if)::get(this, "", "MASTER_IF", master_cfg.master_vif))
            `uvm_fatal("build_phase", "Unable to get master virtual interface")

        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_core_IF", spi_core_object_inst.spi_vif))
            `uvm_fatal("build_phase", "Unable to get spi_core virtual interface")

        if (!uvm_config_db#(virtual apb_if)::get(this, "", "APB_IF", apb_object_inst.apb_vif))
            `uvm_fatal("build_phase", "Unable to get APB virtual interface")

        // ===================================================================
        // SET AGENT ACTIVE/PASSIVE MODES
        // ===================================================================
        master_cfg.is_active           = UVM_ACTIVE;
        apb_object_inst.is_active      = UVM_PASSIVE;
        spi_core_object_inst.is_active = UVM_PASSIVE;

        // ===================================================================
        // PUBLISH CONFIGURATIONS TO CONFIG DB
        // ===================================================================
        uvm_config_db#(master_config)::set(this,  "*", "Master_CFG",    master_cfg);
        uvm_config_db#(apb_config)::set(this,     "*", "apb_CFG",       apb_object_inst);
        uvm_config_db#(spi_core_config)::set(this,"*", "spi_core_CFG",  spi_core_object_inst);

    endfunction

    // =========================================================================
    // RUN_PHASE
    // =========================================================================
    // This phase executes ALL sequences from all tests in a systematic order
    // =========================================================================
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);

        // ===================================================================
        // EXECUTE SEQUENCES FROM ACCESS_REG_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "ACCESS_REG_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting access_rst_seq", UVM_LOW)
        access_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_write_read_sequence", UVM_LOW)
        access_write_read_sequence.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_write_read_sequence", UVM_LOW)

        `uvm_info("run_phase", "Starting access_violate_write_read_seq", UVM_LOW)
        access_violate_write_read_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_violate_write_read_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_ctrl_seq", UVM_LOW)
        access_ctrl_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_ctrl_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_clk_div_seq", UVM_LOW)
        access_clk_div_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_clk_div_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_delay_seq", UVM_LOW)
        access_delay_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_delay_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_ss_ctrl_seq", UVM_LOW)
        access_ss_ctrl_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_ss_ctrl_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting access_status_seq", UVM_LOW)
        access_status_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed access_status_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM SANITY_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "SANITY_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting sanity_rst_seq", UVM_LOW)
        sanity_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed sanity_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting sanity_ctrl_seq", UVM_LOW)
        sanity_ctrl_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed sanity_ctrl_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM LOOPBACK_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "LOOPBACK_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting loopback_rst_seq", UVM_LOW)
        loopback_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed loopback_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting loopback_directed_seq", UVM_LOW)
        loopback_directed_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed loopback_directed_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting loopback_ctrl_randomized_seq", UVM_LOW)
        loopback_ctrl_randomized_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed loopback_ctrl_randomized_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM ERROR_INJECTION_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "ERROR_INJECTION_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting error_rst_seq", UVM_LOW)
        error_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed error_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting error_injection_seq", UVM_LOW)
        error_injection_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed error_injection_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM DELAY_TRANSFER_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "DELAY_TRANSFER_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting delay_transfer_rst_seq", UVM_LOW)
        delay_transfer_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed delay_transfer_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting delay_transfer_seq", UVM_LOW)
        delay_transfer_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed delay_transfer_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM CLK_DIV_CORNER_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "CLK_DIV_CORNER_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting div_rst_seq", UVM_LOW)
        div_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed div_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting div_seq", UVM_LOW)
        div_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed div_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM MODE_COVERAGE_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "MODE_COVERAGE_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting modes_rst_seq", UVM_LOW)
        modes_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed modes_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting modes_crossing_seq", UVM_LOW)
        modes_crossing_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed modes_crossing_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting no_ss_seq", UVM_LOW)
        no_ss_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed no_ss_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM FIFO_STRESS_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "FIFO_STRESS_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "Starting fifo_stress_rst_seq", UVM_LOW)
        fifo_stress_rst_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed fifo_stress_rst_seq", UVM_LOW)

        `uvm_info("run_phase", "Starting fifo_stress_seq", UVM_LOW)
        fifo_stress_seq.start(env.agent.sqr);
        `uvm_info("run_phase", "Completed fifo_stress_seq", UVM_LOW)

        // ===================================================================
        // EXECUTE SEQUENCES FROM WIDTH_COVERAGE_TEST
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "WIDTH_COVERAGE_TEST SEQUENCES", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        `uvm_info("run_phase", "=== PHASE: Reset ===", UVM_LOW)
        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: 8-bit width boundary transfers ===", UVM_LOW)
        width_8bit_seq.start(env.agent.sqr);

        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: 16-bit width boundary transfers ===", UVM_LOW)
        width_16bit_seq.start(env.agent.sqr);

        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: 32-bit width boundary transfers ===", UVM_LOW)
        width_32bit_seq.start(env.agent.sqr);

        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: Invalid width encoding (2'b11) ===", UVM_LOW)
        width_invalid_seq.start(env.agent.sqr);

        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: Width hot-swap between transfers ===", UVM_LOW)
        width_hot_swap_seq.start(env.agent.sqr);

        width_rst_seq.start(env.agent.sqr);

        `uvm_info("run_phase", "=== PHASE: All widths x all SPI modes ===", UVM_LOW)
        width_all_modes_seq.start(env.agent.sqr);

<<<<<<< HEAD
=======
        //         `uvm_info("run_phase","rst_seq stimulus generation started",UVM_LOW)
        //     rst_seq.start(env.agent.sqr);
        // `uvm_info("run_phase","rst_seq stimulus generation ended",UVM_LOW)

        //     `uvm_info("run_phase","interrupts_seq stimulus generation started",UVM_LOW)
        //           interrupts_seq.start(env.agent.sqr);
        // `uvm_info("run_phase","interrupts_seq stimulus generation ended",UVM_LOW)


>>>>>>> c10248cb0797c7641555da4ab2cb7ab0a882e939
        // ===================================================================
        // END OF ALL SEQUENCES
        // ===================================================================
        `uvm_info("run_phase", "========================================", UVM_LOW)
        `uvm_info("run_phase", "ALL SEQUENCES COMPLETED SUCCESSFULLY", UVM_LOW)
        `uvm_info("run_phase", "========================================", UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass
endpackage