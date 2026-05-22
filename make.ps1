# ==============================================================================
# make.ps1 — PowerShell equivalent of the SPI Master UVM Verification Makefile
# ==============================================================================
# Usage:
#   .\make.ps1 compile
#   .\make.ps1 run   [-Test sanity_test] [-Seed 1] [-Waves 0]
#   .\make.ps1 regress [-RegressionTests "comprehensive_test"] [-RegressionSeeds 1] [-DutSrcs "golden_rtl/spi_core.sv golden_rtl/apb_regfile.sv golden_rtl/spi_master.sv"]
#   .\make.ps1 cov
#   .\make.ps1 clean
# ==============================================================================

param(
    [Parameter(Position=0)]
    [string]$Target = "compile",

    [string]$Test             = "mode_coverage_test",
    [int]   $Seed             = 1,
    [int]   $Waves            = 0,
    [string]$RegressionTests  = "comprehensive_test",
    [int]   $RegressionSeeds  = 1,
    [string]$DutSrcs          = "golden_rtl/spi_core.sv golden_rtl/apb_regfile.sv golden_rtl/spi_master.sv"
)

# Allow DUT_SRC (singular) to override DutSrcs for backward compatibility
if ($env:DUT_SRC) { $DutSrcs = $env:DUT_SRC }

# ---------------------------------------------------------------------------
# Helper: run a command and stop on error
# ---------------------------------------------------------------------------
function Invoke-Tool {
    param([string]$Cmd)
    Write-Host "> $Cmd" -ForegroundColor Cyan
    Invoke-Expression $Cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Command failed (exit $LASTEXITCODE): $Cmd"
        exit $LASTEXITCODE
    }
}

# ==============================================================================
# TARGET: compile
# ==============================================================================
function Invoke-Compile {
    Write-Host "=> Creating work library..." -ForegroundColor Yellow
    vlib work
    vmap work work

    Write-Host "=> Compiling Packages..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv tb/apb_shared_pkg.sv tb/master_shared_pkg.sv tb/spi_core_shared_pkg.sv"

    Write-Host "=> Compiling Interfaces & BFM..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv harness/apb_if.sv harness/master_if.sv harness/spi_if.sv"
    Invoke-Tool "vlog -sv tb/spi_slave_bfm.sv"
    Invoke-Tool "vlog -sv harness/dut_wrapper.sv"

    Write-Host "=> Compiling DUT..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv +cover $DutSrcs"

    Write-Host "=> Compiling Golden / Reference Models..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv tb/apb_regfile_golden.sv tb/spi_core_golden.sv tb/spi_master_golden.sv"

    Write-Host "=> Compiling Sequences..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv sequences/apb_sequence_item.sv sequences/master_sequence_item.sv sequences/spi_core_sequence_item.sv"
    Invoke-Tool "vlog -sv sequences/master_sequence.sv sequences/sanity_sequence.sv sequences/modes_sequence.sv sequences/div_sequence.sv sequences/error_injection_sequence.sv sequences/master_fifo_stress_sequance.sv sequences/delay_transfer_sequence.sv sequences/loopback_sequence.sv sequences/width_coverage_sequance.sv sequences/master_interrupts_sequance.sv"

    Write-Host "=> Compiling Environment..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv env/apb_agent/apb_config.sv env/apb_agent/apb_sequencer.sv env/apb_agent/apb_driver.sv env/apb_agent/apb_monitor.sv env/apb_agent/apb_coverage.sv env/apb_agent/apb_scoreboard.sv env/apb_agent/apb_agent.sv"
    Invoke-Tool "vlog -sv env/spi_core_agent/spi_core_config.sv env/spi_core_agent/spi_core_sequencer.sv env/spi_core_agent/spi_core_driver.sv env/spi_core_agent/spi_core_monitor.sv env/spi_core_agent/spi_core_coverage.sv env/spi_core_agent/spi_core_scoreboard.sv env/spi_core_agent/spi_core_agent.sv"
    Invoke-Tool "vlog -sv env/master_agent/master_config.sv env/master_agent/master_sequencer.sv env/master_agent/master_driver.sv env/master_agent/master_monitor.sv env/master_agent/master_coverage.sv env/master_agent/coverage_subscriber.sv env/master_agent/master_scoreboard.sv env/master_agent/master_agent.sv"
    Invoke-Tool "vlog -sv env/apb_env.sv env/spi_core_env.sv env/master_env.sv"

    Write-Host "=> Compiling Assertions & Tests..." -ForegroundColor Yellow
    Invoke-Tool "vlog -sv assertions/apb_assertions.sv assertions/spi_core_assertions.sv assertions/master_assertions.sv"
    Invoke-Tool "vlog -sv tests/comprehensive_test.sv"
    Invoke-Tool "vlog -sv tb/master_top.sv"

    Write-Host "=> Compile complete!" -ForegroundColor Green
}

# ==============================================================================
# TARGET: run
# ==============================================================================
function Invoke-Run {
    Write-Host "=> Running $Test with SEED=$Seed..." -ForegroundColor Yellow
    if ($Waves -eq 1) {
        Invoke-Tool "vsim -c work.top +UVM_TESTNAME=$Test -sv_seed $Seed -do `"log -r /*; run -all; quit`" -wlf waves_${Test}_${Seed}.wlf"
    } else {
        Invoke-Tool "vsim -c work.top +UVM_TESTNAME=$Test -sv_seed $Seed -do `"run -all; quit`""
    }
}

# ==============================================================================
# TARGET: regress
# ==============================================================================
function Invoke-Regress {
    Write-Host "=> Starting Regression..." -ForegroundColor Yellow
    if (-not (Test-Path "build")) { New-Item -ItemType Directory -Path "build" | Out-Null }

    $testList = $RegressionTests -split '\s+' | Where-Object { $_ -ne '' }
    $seedList = 1..$RegressionSeeds

    foreach ($t in $testList) {
        foreach ($s in $seedList) {
            Write-Host "   Running $t | SEED=$s..." -ForegroundColor Cyan
            $log  = "build/log_${t}_${s}.log"
            $ucdb = "build/cov_${t}_${s}.ucdb"
            Invoke-Tool "vsim -c work.top +UVM_TESTNAME=$t -sv_seed $s -coverage -do `"coverage save -onexit $ucdb; run -all; quit`" -l $log"
        }
    }
    Write-Host "=> Regression Complete!" -ForegroundColor Green
}

# ==============================================================================
# TARGET: cov
# ==============================================================================
function Invoke-Cov {
    Write-Host "=> Merging coverage databases..." -ForegroundColor Yellow
    Invoke-Tool "vcover merge merged_coverage.ucdb build/cov_*.ucdb"
    Write-Host "=> Generating coverage_report.txt..." -ForegroundColor Yellow
    Invoke-Tool "vcover report -details -output coverage_report.txt merged_coverage.ucdb"
    Write-Host "=> Coverage report generated!" -ForegroundColor Green
}

# ==============================================================================
# TARGET: clean
# ==============================================================================
function Invoke-Clean {
    Write-Host "=> Cleaning workspace..." -ForegroundColor Yellow
    if (Test-Path "work")                { Remove-Item -Recurse -Force "work" }
    if (Test-Path "build")               { Remove-Item -Recurse -Force "build" }
    if (Test-Path "transcript")          { Remove-Item -Force "transcript" }
    if (Test-Path "coverage_report.txt") { Remove-Item -Force "coverage_report.txt" }
    if (Test-Path "merged_coverage.ucdb"){ Remove-Item -Force "merged_coverage.ucdb" }
    Get-Item "*.wlf"       -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-Item "*.log"       -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-Item "*.ucdb"      -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-Item "*.vstf"      -ErrorAction SilentlyContinue | Remove-Item -Force
    Get-Item "certe_dump.xml" -ErrorAction SilentlyContinue | Remove-Item -Force
    Write-Host "=> Clean complete!" -ForegroundColor Green
}

# ==============================================================================
# Dispatch
# ==============================================================================
switch ($Target.ToLower()) {
    "compile" { Invoke-Compile }
    "run"     { Invoke-Run }
    "regress" { Invoke-Regress }
    "cov"     { Invoke-Cov }
    "clean"   { Invoke-Clean }
    default {
        Write-Error "Unknown target: '$Target'. Valid targets: compile, run, regress, cov, clean"
        exit 1
    }
}
