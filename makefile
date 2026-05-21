# ==============================================================================
# SPI Master UVM Verification Makefile
# ==============================================================================

# Default Variables (Grader will override these via command line)
TEST             ?= mode_coverage_test
SEED             ?= 1
WAVES            ?= 0
REGRESSION_TESTS ?= comprehensive_test
REGRESSION_SEEDS ?= 1

# Default DUT sources 
DUT_SRCS         ?= golden_rtl/spi_core.sv golden_rtl/apb_regfile.sv golden_rtl/spi_master.sv 

# Grader Backward Compatibility: If the older 'DUT_SRC' is passed, it replaces 'DUT_SRCS'
ifdef DUT_SRC
	DUT_SRCS = $(DUT_SRC)
endif

# Waveform dumping logic
ifeq ($(WAVES), 1)
	VSIM_WAVE_CMD = -do "log -r /*; run -all; quit" -wlf waves_$(TEST)_$(SEED).wlf
else
	VSIM_WAVE_CMD = -do "run -all; quit"
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
	
	@echo "=> Compiling DUT..."
	vlog -sv +cover $(DUT_SRCS)
	
	@echo "=> Compiling Sequences..."
	vlog -sv sequences/apb_sequence_item.sv sequences/master_sequence_item.sv sequences/spi_core_sequence_item.sv
	vlog -sv sequences/master_sequence.sv sequences/sanity_sequence.sv \
	         sequences/modes_sequence.sv sequences/div_sequence.sv sequences/error_injection_sequence.sv \
	         sequences/master_fifo_stress_sequance.sv sequences/apb_fifo_stress_sequance.sv \
	         sequences/delay_transfer_sequence.sv sequences/loopback_sequence.sv sequences/width_coverage_sequance.sv
	
	@echo "=> Compiling Environment..."
	vlog -sv env/apb_agent/apb_config.sv env/apb_agent/apb_sequencer.sv env/apb_agent/apb_driver.sv env/apb_agent/apb_monitor.sv env/apb_agent/apb_coverage.sv env/apb_agent/apb_scoreboard.sv env/apb_agent/apb_agent.sv
	vlog -sv env/spi_core_agent/spi_core_config.sv env/spi_core_agent/spi_core_sequencer.sv env/spi_core_agent/spi_core_driver.sv env/spi_core_agent/spi_core_monitor.sv env/spi_core_agent/spi_core_coverage.sv env/spi_core_agent/spi_core_scoreboard.sv env/spi_core_agent/spi_core_agent.sv
	vlog -sv env/master_agent/master_config.sv env/master_agent/master_sequencer.sv env/master_agent/master_driver.sv env/master_agent/master_monitor.sv env/master_agent/master_coverage.sv env/master_agent/coverage_subscriber.sv env/master_agent/master_scoreboard.sv env/master_agent/master_agent.sv
	vlog -sv env/apb_env.sv env/spi_core_env.sv env/master_env.sv
	
	@echo "=> Compiling Assertions & Tests..."
	vlog -sv assertions/apb_assertions.sv assertions/spi_core_assertions.sv assertions/master_assertions.sv
	vlog -sv tests/base_test.sv tests/access_reg_test.sv tests/clk_div_corner_test.sv tests/delay_transfer_test.sv \
	         tests/error_injection_test.sv tests/fifo_stress_test.sv  tests/loopback_test.sv \
	         tests/mode_coverage_test.sv tests/ral_hw_reset_test.sv tests/reg_access_test.sv tests/sanity_test.sv \
	         tests/width_coverage_test.sv tests/comprehensive_test.sv 
	vlog -sv tb/master_top.sv

# ==============================================================================
# Target: run
# Runs a single test with the given seed. Dumps .wlf if WAVES=1.
# ==============================================================================
run:
	@echo "=> Running $(TEST) with SEED=$(SEED)..."
	vsim -c work.top +UVM_TESTNAME=$(TEST) -sv_seed $(SEED) $(VSIM_WAVE_CMD)

# ==============================================================================
# Target: regress
# Runs the full regression list, once per REGRESSION_SEEDS.
# ==============================================================================
regress:
	@echo "=> Starting Regression..."
	@mkdir -p build
	@for t in $(REGRESSION_TESTS); do \
		for s in `seq 1 $(REGRESSION_SEEDS)`; do \
			echo "   Running $$t | SEED=$$s..."; \
			vsim -c work.top +UVM_TESTNAME=$$t -sv_seed $$s -coverage -do "coverage save -onexit build/cov_$${t}_$${s}.ucdb; run -all; quit" -l build/log_$${t}_$${s}.log; \
		done \
	done
	@echo "=> Regression Complete!"

# ==============================================================================
# Target: cov
# Merges all UCDB databases and produces coverage_report.txt
# ==============================================================================
cov:
	@echo "=> Merging coverage databases..."
	vcover merge merged_coverage.ucdb build/cov_*.ucdb
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