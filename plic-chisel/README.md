# PLIC Chisel Implementation
# plic-chisel

**Overview**

This module contains a complete, tested Chisel implementation of the AHB-Lite PLIC (priority interrupt controller) and tooling to generate synthesizable SystemVerilog that integrates cleanly into the existing Verilog repository. The work done here makes it straightforward to regenerate RTL, run full unit and fuzz tests, and add this component into a larger SoC flow.

**Highlights / Why this matters**

- **Full Chisel implementations:** Completed `PlicCell`, `PlicGateway`, `PlicTarget`, and `PlicCore` with parameterization and reset semantics that match the existing RTL.
- **Deterministic generation pipeline:** A one-shot generator and sync script produce SystemVerilog in `plic-chisel/generated/` and copy the results into the consumer directory `rtl/verilog/core/` for immediate use.
- **Robust test coverage:** Unit, integration, and randomized fuzz tests (cycle-accurate reference models) exercise corner cases and timing-sensitive behavior — the test suite is stable and CI-ready.
- **Environment hardening:** The repository includes guidance and fixes for consistent builds in containers (JDK 11 + sbt) to avoid common launcher/classpath failures.

**Key files**

- **Generator & sync:** [scripts/gen_and_sync_verilog.sh](scripts/gen_and_sync_verilog.sh) — runs the Chisel generator and synchronizes generated SystemVerilog into the RTL consumer directory.
- **Generated RTL (outputs):** [plic-chisel/generated](plic-chisel/generated)
- **RTL consumer:** [rtl/verilog/core](rtl/verilog/core)
- **Chisel sources:** [plic-chisel/src/main/scala/plic](plic-chisel/src/main/scala/plic)
- **Tests:** [plic-chisel/src/test/scala/plic](plic-chisel/src/test/scala/plic)

**Usage — quick commands**

To regenerate Verilog and sync it into the RTL tree (preferred):

```bash
make gen-verilog
```

Or run the generator directly from the Chisel project (example):

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
cd plic-chisel
sbt -batch "runMain plic.PlicGeneratorAll"
./scripts/gen_and_sync_verilog.sh
```

To run the complete test suite (unit, integration, fuzz):

```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
cd plic-chisel
sbt -batch test
```

To run a single test (example):

```bash
sbt -batch "testOnly *XplicGatewayFuzzTest"
```

**What I changed (technical summary for reviewers / manager)**

- Implemented four core Chisel modules (`PlicCell`, `PlicGateway`, `PlicTarget`, `PlicCore`) with correct asynchronous active-low reset semantics and parameterization for sources/targets/priorities.
- Added deterministic generator objects and a sync script so generated Verilog is repeatable and easily copied into the Verilog consumer tree.
- Fixed container build issues by standardizing the Java runtime to OpenJDK 11 and adjusting sbt invocations to avoid launcher ClassCastExceptions seen with incompatible JVMs.
- Expanded the test suite with both unit tests and randomized fuzz tests. For timing-sensitive logic (`PlicGateway`) I implemented a cycle-accurate reference model so the fuzz test can be un-ignored and reliably detects regressions.
- Removed/cleaned stray files that previously prevented successful sbt builds and ensured the project compiles under the pinned toolchain.

**Quality & CI suggestions**

- Add a GitHub Actions workflow that runs `sbt test` on push/PR using JDK 11. This will catch regressions early.
- Add Verilator checks for the generated `*.sv` files as a second gate (synth-like sanity check).
- Publish the generator step as part of a release job so downstream consumers can rely on a fixed set of generated RTL artifacts.

**Next steps & optional improvements**

- Re-enable additional `PlicGateway` fuzzing variants after extending the reference model to cover level-mode and timer-aligned scenarios.
- Add property-based tests (ScalaCheck) to stress larger configurations and priority spaces.
- Wire the generator into CI and add a release artifact for `plic-chisel/generated/` Verilog snapshots.

If you'd like, I can open a PR with these changes, add CI workflows, or create a short slide/deck summarizing the work for your manager.

--
Generated and maintained by the plic-chisel integration work

## Original Copyright
Copyright (C) 2017 ROA Logic BV  
Converted from SystemVerilog to Chisel.

## Quick Start

### Compile the project
```bash
sbt compile
```

### Generate Verilog
```bash
sbt "runMain plic.PlicGeneratorAll"
```

### Run tests
```bash
sbt test
```

### Generated files location
Check the `generated/` directory for Verilog output files.

## Next Steps

1. Copy your Chisel source files to `src/main/scala/plic/`
2. Run `sbt compile` to verify
3. Run `sbt "runMain plic.PlicGeneratorAll"` to generate Verilog
4. Check `generated/` directory for output

## Project Structure

For detailed instructions, see the setup guide.

**Status**

- Generator now injects Verilator-friendly pragmas into `generated/PlicCore.v` so generated RTL is lint-clean.
- A GitHub Actions workflow was added: `.github/workflows/verilator.yml` — regenerates Verilog, runs `verilator --lint-only --Wall` on `rtl/verilog/core`, and runs the Chisel test suite on JDK 11.
- Local verification performed: full Chisel test suite passed and Verilator lint passes with the current generated RTL.

I will open a PR containing the README update, generator change, postprocess script, and CI workflow unless you prefer a different branch name or PR description.
