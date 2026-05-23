# ==============================================================================
# SPI Master UVM Verification Makefile
# ==============================================================================

# Default Variables (Grader will override these via command line)
TEST             ?= mode_coverage_test
SEED             ?= 1
WAVES            ?= 0
REGRESSION_TESTS ?= comprehensive_test
REGRESSION_SEEDS ?= 1
BONUS_TEST       ?= ral_hw_reset_test

# Default DUT sources 
DUT_SRCS         ?= golden_rtl/spi_core.sv golden_rtl/apb_regfile.sv golden_rtl/spi_master.sv 

# Grader Backward Compatibility: If the older 'DUT_SRC' is passed, it replaces 'DUT_SRCS'
ifdef DUT_SRC
    DUT_SRCS = $(DUT_SRC)
endif

# Waveform and Coverage dumping logic
ifeq ($(WAVES), 1)
    VSIM_WAVE_CMD = -do "coverage save -onexit build/cov_$(TEST)_$(SEED).ucdb; log -r /*; run -all; quit" -wlf waves_$(TEST)_$(SEED).wlf
else
    VSIM_WAVE_CMD = -do "coverage save -onexit build/cov_$(TEST)_$(SEED).ucdb; run -all; quit"
endif

# ==============================================================================
# Target: compile
# Compiles the testbench and the DUT sources given by DUT_SRCS
# ==============================================================================
compile:
	@echo "=> Creating work library..."
	vlib work
	vmap work work
	
	@echo "=> Compiling Packages..."
	vlog -sv tb/apb_shared_pkg.sv tb/master_shared_pkg.sv tb/spi_core_shared_pkg.sv
	
	@echo "=> Compiling Interfaces & BFM..."
	vlog -sv harness/apb_if.sv harness/master_if.sv harness/spi_if.sv
	vlog -sv tb/spi_slave_bfm.sv
	vlog -sv harness/dut_wrapper.sv
	
	@echo "=> Compiling DUT..."
	vlog -sv +cover $(DUT_SRCS)
	
	@echo "=> Compiling Golden / Reference Models..."
	vlog -sv tb/apb_regfile_golden.sv tb/spi_core_golden.sv tb/spi_master_golden.sv
	
	@echo "=> Compiling Sequences..."
	vlog -sv sequences/apb_sequence_item.sv sequences/master_sequence_item.sv sequences/spi_core_sequence_item.sv
	vlog -sv sequences/master_sequence.sv sequences/sanity_sequence.sv \
	         sequences/modes_sequence.sv sequences/div_sequence.sv sequences/error_injection_sequence.sv \
	         sequences/master_fifo_stress_sequance.sv \
	         sequences/delay_transfer_sequence.sv sequences/loopback_sequence.sv sequences/width_coverage_sequance.sv \
	         sequences/master_interrupts_sequance.sv
	
	@echo "=> Compiling Environment..."
	vlog -sv env/apb_agent/apb_config.sv env/apb_agent/apb_sequencer.sv env/apb_agent/apb_driver.sv env/apb_agent/apb_monitor.sv env/apb_agent/apb_coverage.sv env/apb_agent/apb_scoreboard.sv env/apb_agent/apb_agent.sv
	vlog -sv env/spi_core_agent/spi_core_config.sv env/spi_core_agent/spi_core_sequencer.sv env/spi_core_agent/spi_core_driver.sv env/spi_core_agent/spi_core_monitor.sv env/spi_core_agent/spi_core_coverage.sv env/spi_core_agent/spi_core_scoreboard.sv env/spi_core_agent/spi_core_agent.sv
	vlog -sv env/master_agent/master_config.sv env/master_agent/master_sequencer.sv env/master_agent/master_driver.sv env/master_agent/master_monitor.sv env/master_agent/master_coverage.sv env/master_agent/coverage_subscriber.sv env/master_agent/master_scoreboard.sv env/master_agent/master_agent.sv
	vlog -sv env/apb_env.sv env/spi_core_env.sv env/master_env.sv
	
	@echo "=> Compiling Assertions & Tests..."
	vlog -sv assertions/apb_assertions.sv assertions/spi_core_assertions.sv assertions/master_assertions.sv
	vlog -sv tests/comprehensive_test.sv tests/ral_hw_reset_test.sv
	vlog -sv tb/master_top.sv

# ==============================================================================
# Target: run
# Runs a single test with the given seed. Dumps .wlf if WAVES=1.
# ==============================================================================
run:
	@if not exist build mkdir build
	@echo "=> Running $(TEST) with SEED=$(SEED)..."
	vsim -c -coverage work.top +UVM_TESTNAME=$(TEST) -sv_seed $(SEED) $(VSIM_WAVE_CMD)

# ==============================================================================
# Target: regress
# Runs the full regression list, once per REGRESSION_SEEDS.
# ==============================================================================
regress:
	@echo "=> Starting Regression..."
	@if not exist build mkdir build
	powershell -ExecutionPolicy Bypass -File make.ps1 regress -RegressionTests "$(REGRESSION_TESTS)" -RegressionSeeds $(REGRESSION_SEEDS) -DutSrcs "$(DUT_SRCS)"

# ==============================================================================
# Target: run_bonus
# Runs the mandatory RAL bonus test (or the skipped stub)
# ==============================================================================
run_bonus:
	@echo "=> Running RAL Bonus Test..."
	$(MAKE) run TEST=$(BONUS_TEST) SEED=1

# ==============================================================================
# Target: cov
# Merges all UCDB databases and produces coverage_report.txt
# ==============================================================================
cov:
	@echo "=> Merging coverage databases..."
	vcover merge merged_coverage.ucdb $(wildcard build/cov_*.ucdb)
	@echo "=> Generating coverage_report.txt..."
	vcover report -details -output coverage_report.txt merged_coverage.ucdb
	@echo "=> Coverage report generated!"

# ==============================================================================
# Target: clean
# Removes all build artifacts
# ==============================================================================
clean:
	@echo "=> Cleaning workspace..."
	rm -rf work transcript *.wlf build/ coverage_report.txt *.ucdb certe_dump.xml *.log *.vstf