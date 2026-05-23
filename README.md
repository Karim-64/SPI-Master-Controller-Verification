# SPI Master Controller — UVM Verification Environment
**Ain Shams University | Digital Design Verification | Spring 2026**

---

## Overview

A full UVM-based verification environment for an APB-slave SPI Master Controller IP. The environment targets an 8/16/32-bit, 4 slave-select, 8-deep FIFO SPI master with a 32-bit AMBA APB v2.0 slave interface. The testbench achieves **98% functional coverage** across all 10 mandatory tests and qualifies for the **UVM bonus**.

---

## Team

| Name | 
|---|
| Karim Maaty | 
| Mohamed Lotfy |
| Rawan Waziry | 
| Marina Bebawy | 
| Mohamed Hassan |
| Saeed Nabawy |
| Ziad Abdalah |

---

## DUT Architecture

```
spi_master (top)
 ├── u_regfile : apb_regfile   (APB slave + 9 registers + TX/RX FIFOs + IRQ)
 └── u_core    : spi_core      (SPI shift FSM + SCLK generator)
```

The DUT is wrapped via `harness/dut_wrapper.sv`. Do not modify any file in `harness/`.

---

## Repository Layout

```
Karim_2200746/
├── harness/                  # Provided — do not modify
│   ├── apb_if.sv
│   ├── master_if.sv
│   ├── spi_if.sv
│   └── dut_wrapper.sv
├── tb/
│   ├── master_top.sv         # UVM top — run_test() entry point
│   ├── master_shared_pkg.sv
│   ├── apb_shared_pkg.sv
│   ├── spi_core_shared_pkg.sv
│   └── spi_slave_bfm.sv
├── env/
│   ├── master_agent/         # Black-box APB stimulus agent
│   ├── apb_agent/            # Internal APB regfile monitor agent
│   ├── spi_core_agent/       # Internal SPI core monitor agent
│   ├── spi_env.sv            # Top-level uvm_env
│   ├── master_env.sv
│   ├── apb_env.sv
│   └── spi_core_env.sv
├── sequences/                # All UVM sequences
├── tests/                    # All 10 mandatory tests + base_test
├── assertions/               # SVA bind files
│   ├── apb_assertions.sv
│   ├── spi_core_assertions.sv
│   └── master_assertions.sv
├── golden_rtl/               # Reference RTL (local dev only)
├── docs/
│   ├── test_plan.pdf
│   ├── final_report.pdf
│   └── coverage_report.pdf
├── Makefile
└── README.md
```

---

## Toolchain

| Tool | Version |
|---|---|
| Simulator | QuestaSim |
| Language | SystemVerilog + UVM 1.2 |
| OS | Windows 11 |
| Shell | PowerShell + GNU Make |

---

## How to Run

### Compile
```bash
make compile DUT_SRCS="<path>/spi_core.sv <path>/apb_regfile.sv <path>/spi_master.sv"
```

### Run a single test
```bash
make run TEST=sanity_test SEED=1
```

### Run with waveforms
```bash
make run TEST=sanity_test SEED=1 WAVES=1
```

### Full regression
```bash
make regress DUT_SRCS="..." REGRESSION_SEEDS=5
```

### Coverage report
```bash
make cov
```

### Clean
```bash
make clean
```

---

## Mandatory Tests

| # | Test | Description |
|---|---|---|
| 1 | `sanity_test` | Single byte, Mode 0, verify RX |
| 2 | `reg_access_test` | Reset values + write/read all R/W registers |
| 3 | `mode_coverage_test` | All 4 modes × MSB/LSB × 8/16/32-bit |
| 4 | `width_coverage_test` | Width boundary edge cases |
| 5 | `fifo_stress_test` | Back-to-back transfers, near full/empty |
| 6 | `interrupt_test` | All 5 interrupt sources, mask, W1C, race |
| 7 | `clk_div_corner_test` | DIV = 0, 1, small, large (≥1024), max |
| 8 | `loopback_test` | Loopback on/off, MISO ignored in loopback |
| 9 | `delay_transfer_test` | DELAY > 0 inter-transfer idle cycles |
| 10 | `error_injection_test` | TX overflow, RX underflow, reserved offsets, RO writes |

---

## Log Contract

The grader recognises the following lines:

```
[SCOREBOARD_ERROR] <description>    — DUT output mismatch
[ASSERTION_ERROR] <name> <text>     — SVA failure
[TEST_PASSED] <test_name>           — zero errors, all checks passed
[TEST_FAILED] <test_name> errors=N  — at least one error detected
```

---

## UVM Bonus Compliance

- `tb/master_top.sv` imports `uvm_pkg` and calls `run_test()`
- `env/spi_env.sv` extends `uvm_env` and calls `uvm_config_db::get()` for APB virtual interface in `build_phase`
- `tests/error_injection_test.sv` registers a factory override via `set_type_override_by_type` at build time
- `env/master_agent/coverage_subscriber.sv` extends `uvm_subscriber` and is instantiated inside `spi_env`

---

## SVA Coverage (R-number references from spec)

| Assertion | Requirement |
|---|---|
| APB PSEL high for ≥2 PCLK to complete transaction | R22 |
| PENABLE only asserts while PSEL=1 | R22 |
| PADDR/PWRITE/PWDATA stable from SETUP to ACCESS | R22 |
| SCLK idle level matches CPOL when BUSY=0 | R4 |
| SCLK half-period = DIV+1 PCLK cycles | R8 |
| SS_n held asserted for full transfer | R7 |
| IRQ == \|(INT_STAT & INT_EN) every PCLK | R16 |
| No TX FIFO pop when empty | R9 |

---

## Coverage Results

| Metric | Result |
|---|---|
| Functional Coverage | **98%** |
| Code Coverage (stmt/branch) | **≥85%** |

---

## Notes

- `golden_rtl/` is for **local development only** — the grader injects its own DUT via `DUT_SRCS`
- Do not submit `work/`, `*.wlf`, or any binary simulator output
- `tests/ral_hw_reset_test.sv` is a stub that prints `[TEST_SKIPPED] ral_hw_reset_test` — RAL bonus not attempted
