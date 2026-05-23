# ============================================================
# run.do — QuestaSim Compilation & Simulation Script
# SPI Master Verification Project
# ============================================================

transcript on

# ------------------------------------------------------------
# 0. Setup
# ------------------------------------------------------------
quietly set DUT_PATH   "./golden_rtl"
quietly set HARNESS    "./harness"
quietly set TB         "./tb"
quietly set ENV        "./env"
quietly set SEQ        "./sequences"
quietly set TESTS      "./tests"
quietly set ASSERT     "./assertions"

# ------------------------------------------------------------
# User Arguments
# Usage:
# vsim -do "do run.do sanity_test 5"
# ------------------------------------------------------------
quietly set TEST [lindex $argv 0]
quietly set SEED [lindex $argv 1]

if {$TEST eq ""} { quietly set TEST "sanity_test" }
if {$SEED eq ""} { quietly set SEED "1" }

puts "=========================================="
puts " Running Test : $TEST"
puts " Random Seed  : $SEED"
puts "=========================================="

# ------------------------------------------------------------
# 1. Create & Map Work Library
# ------------------------------------------------------------
if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# ------------------------------------------------------------
# 2. Global Compile Options
# ------------------------------------------------------------
quietly set VLOG_OPTS "-sv -mfcu"

# ------------------------------------------------------------
# 3. Compile Shared Packages
# ------------------------------------------------------------
puts "Compiling Packages..."

eval vlog $VLOG_OPTS "$TB/apb_shared_pkg.sv"
eval vlog $VLOG_OPTS "$TB/master_shared_pkg.sv"
eval vlog $VLOG_OPTS "$TB/spi_core_shared_pkg.sv"

# ------------------------------------------------------------
# 4. Compile Interfaces & BFM
# ------------------------------------------------------------
puts "Compiling Interfaces & BFM..."

eval vlog $VLOG_OPTS "$HARNESS/apb_if.sv"
eval vlog $VLOG_OPTS "$HARNESS/master_if.sv"
eval vlog $VLOG_OPTS "$HARNESS/spi_if.sv"
eval vlog $VLOG_OPTS "$TB/spi_slave_bfm.sv"
eval vlog $VLOG_OPTS "$HARNESS/dut_wrapper.sv"

# ------------------------------------------------------------
# 5. Compile DUT
# ------------------------------------------------------------
puts "Compiling DUT..."

eval vlog $VLOG_OPTS "+cover" "$DUT_PATH/spi_core.sv" "$DUT_PATH/apb_regfile.sv" "$DUT_PATH/spi_master.sv"

# ------------------------------------------------------------
# 5b. Compile Golden / Reference Models
# ------------------------------------------------------------
puts "Compiling Golden Models..."

eval vlog $VLOG_OPTS "$TB/apb_regfile_golden.sv"
eval vlog $VLOG_OPTS "$TB/spi_core_golden.sv"
eval vlog $VLOG_OPTS "$TB/spi_master_golden.sv"

# ------------------------------------------------------------
# 6. Compile Sequences
# ------------------------------------------------------------
puts "Compiling Sequences..."

eval vlog $VLOG_OPTS "$SEQ/apb_sequence_item.sv"
eval vlog $VLOG_OPTS "$SEQ/master_sequence_item.sv"
eval vlog $VLOG_OPTS "$SEQ/spi_core_sequence_item.sv"
eval vlog $VLOG_OPTS "$SEQ/master_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/sanity_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/modes_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/div_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/error_injection_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/master_fifo_stress_sequance.sv"
eval vlog $VLOG_OPTS "$SEQ/delay_transfer_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/loopback_sequence.sv"
eval vlog $VLOG_OPTS "$SEQ/width_coverage_sequance.sv"
eval vlog $VLOG_OPTS "$SEQ/master_interrupts_sequance.sv"

# ------------------------------------------------------------
# 7. Compile Environment
# ------------------------------------------------------------
puts "Compiling Environment..."

eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_config.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_sequencer.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_driver.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_monitor.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_coverage.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_scoreboard.sv"
eval vlog $VLOG_OPTS "$ENV/apb_agent/apb_agent.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_config.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_sequencer.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_driver.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_monitor.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_coverage.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_scoreboard.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_agent/spi_core_agent.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_config.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_sequencer.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_driver.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_monitor.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_coverage.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/coverage_subscriber.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_scoreboard.sv"
eval vlog $VLOG_OPTS "$ENV/master_agent/master_agent.sv"
eval vlog $VLOG_OPTS "$ENV/apb_env.sv"
eval vlog $VLOG_OPTS "$ENV/spi_core_env.sv"
eval vlog $VLOG_OPTS "$ENV/master_env.sv"

# ------------------------------------------------------------
# 8. Compile Assertions
# ------------------------------------------------------------
puts "Compiling Assertions..."

eval vlog $VLOG_OPTS "$ASSERT/apb_assertions.sv"
eval vlog $VLOG_OPTS "$ASSERT/spi_core_assertions.sv"
eval vlog $VLOG_OPTS "$ASSERT/master_assertions.sv"

# ------------------------------------------------------------
# 9. Compile Tests
# ------------------------------------------------------------
puts "Compiling Tests..."

eval vlog $VLOG_OPTS "$TESTS/comprehensive_test.sv"
eval vlog $VLOG_OPTS "$TESTS/ral_hw_reset_test.sv"

# ------------------------------------------------------------
# 10. Compile TB Top
# ------------------------------------------------------------
puts "Compiling Top..."

eval vlog $VLOG_OPTS "$TB/master_top.sv"

# ------------------------------------------------------------
# 15. Start Simulation
# ------------------------------------------------------------
puts "Starting Simulation..."

vsim -voptargs=+acc work.top -classdebug -uvmcontrol=all -cover

# ------------------------------------------------------------
# 16. Load Waveform
# ------------------------------------------------------------
if {[file exists wave.do]} {
    puts "Loading wave.do..."
    do wave.do
}

# ------------------------------------------------------------
# 17. Run Simulation
# ------------------------------------------------------------
run -all

puts "=========================================="
puts " Simulation Finished"
puts "=========================================="