#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(dirname "$SCRIPT_DIR")

RISCV_ARCH_TEST_ROOT=${RISCV_ARCH_TEST_ROOT:-/opt/riscv-conformance/riscv-arch-test}
PLUGIN_ROOT="$RISCV_ARCH_TEST_ROOT/riscof-plugins/rv32"
SUITE_ROOT="$RISCV_ARCH_TEST_ROOT/riscv-test-suite/rv32i_m/I"
ENV_ROOT="$RISCV_ARCH_TEST_ROOT/riscv-test-suite/env"

print_usage() {
  cat <<EOF
Usage: $(basename "$0") [--processor <zeronyte|tetranyte|octonyte>]
[--smoke-test] [--timeout <seconds>]

Runs RISCOF RV32I conformance for the requested processor. Defaults to ZeroNyte.
Use --smoke-test to run a minimal ADD-only test for quicker turnaround.
Use --timeout to override the per-invocation timeout (default: 3600s).
EOF
}

PROCESSOR="zeronyte"
SMOKE_TEST=false
TIMEOUT_SECS=3600
TIMEOUT_SPECIFIED=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --processor|-p)
      if [[ $# -lt 2 ]]; then
        echo "Error: --processor requires an argument" >&2
        exit 1
      fi
      PROCESSOR="$2"
      shift 2
      ;;
    --help|-h)
      print_usage
      exit 0
      ;;
    --smoke-test)
      SMOKE_TEST=true
      shift
      ;;
    --timeout)
      if [[ $# -lt 2 ]]; then
        echo "Error: --timeout requires a value in seconds" >&2
        exit 1
      fi
      TIMEOUT_SECS="$2"
      TIMEOUT_SPECIFIED=true
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      print_usage >&2
      exit 1
      ;;
  esac
done

case "$PROCESSOR" in
  zeronyte)
    DUT_NAME="zeronyte"
    SIM_BUILD_SCRIPT="$SCRIPT_DIR/sim/build_zeronyte_sim.sh"
    SIM_BINARY="zeronyte_sim"
    ISA_FILE="zeronyte/zeronyte_isa.yaml"
    PLATFORM_FILE="zeronyte/zeronyte_platform.yaml"
    RTL_TOP="$REPO_ROOT/rtl/generators/generated/verilog_hierarchical_timed/ZeroNyteRV32ICore.v"
    RTL_GEN_TASK="generators/generateZeroNyteRTL"
    ;;
  tetranyte)
    DUT_NAME="tetranyte"
    SIM_BUILD_SCRIPT="$SCRIPT_DIR/sim/build_tetranyte_sim.sh"
    SIM_BINARY="tetranyte_sim"
    ISA_FILE="tetranyte/tetranyte_isa.yaml"
    PLATFORM_FILE="tetranyte/tetranyte_platform.yaml"
    RTL_TOP="$REPO_ROOT/rtl/generators/generated/verilog_hierarchical_timed/TetraNyteRV32ICore.v"
    RTL_GEN_TASK="generators/generateTetraNyteRTL"
    ;;
  octonyte)
    DUT_NAME="octonyte"
    SIM_BUILD_SCRIPT="$SCRIPT_DIR/sim/build_octonyte_sim.sh"
    SIM_BINARY="octonyte_sim"
    ISA_FILE="octonyte/octonyte_isa.yaml"
    PLATFORM_FILE="octonyte/octonyte_platform.yaml"
    RTL_TOP="$REPO_ROOT/rtl/generators/generated/verilog_hierarchical_timed/OctoNyteRV32ICore.v"
    RTL_GEN_TASK="generators/generateOctoNyteRTL"
    ;;
  *)
    echo "Unsupported processor: $PROCESSOR" >&2
    exit 1
    ;;
esac

if [[ "$PROCESSOR" == "octonyte" && "$TIMEOUT_SPECIFIED" == "false" ]]; then
  TIMEOUT_SECS=120
fi

# Prefer local virtualenv bins early so riscof check succeeds
VENV_BIN="$REPO_ROOT/.venv/bin"
if [[ -d "$VENV_BIN" ]]; then
  export PATH="$VENV_BIN:$PATH"
else
  echo "Warning: expected virtual environment bin directory at $VENV_BIN" >&2
fi

if [[ ! -d "$RISCV_ARCH_TEST_ROOT" ]]; then
  echo "RISCV_ARCH_TEST_ROOT not found at $RISCV_ARCH_TEST_ROOT" >&2
  exit 1
fi

RISCOF_CMD=()
if [[ -x "$VENV_BIN/python3" ]] && "$VENV_BIN/python3" -c "import riscof.cli" >/dev/null 2>&1; then
  RISCOF_CMD=("$VENV_BIN/python3" -m riscof.cli)
elif command -v riscof >/dev/null 2>&1; then
  RISCOF_CMD=(riscof)
else
  echo "riscof CLI not found. Install riscof in your Python environment." >&2
  exit 1
fi

if [[ ! -x "$SIM_BUILD_SCRIPT" ]]; then
  echo "Simulation build script not found for $PROCESSOR: $SIM_BUILD_SCRIPT" >&2
  exit 1
fi

# Ensure timed hierarchical RTL exists; generate via sbt if missing
if [[ ! -f "$RTL_TOP" ]]; then
  echo "Timed RTL not found at $RTL_TOP. Attempting to generate via sbt $RTL_GEN_TASK ..."
  pushd "$REPO_ROOT/rtl" >/dev/null
  sbt "$RTL_GEN_TASK"
  popd >/dev/null
  if [[ ! -f "$RTL_TOP" ]]; then
    echo "Failed to generate RTL for $PROCESSOR at $RTL_TOP" >&2
    exit 1
  fi
fi

"$SIM_BUILD_SCRIPT"

PLUGIN_DIR="$SCRIPT_DIR/riscof/$DUT_NAME"
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "RISCOF plugin directory not found for $PROCESSOR: $PLUGIN_DIR" >&2
  exit 1
fi

OUTPUT_DIR="$SCRIPT_DIR/output/rv32i/$PROCESSOR"
mkdir -p "$OUTPUT_DIR"

SUITE_PATH="$SUITE_ROOT"
SMOKE_CASES=()
if $SMOKE_TEST; then
  SMOKE_DIR="$SCRIPT_DIR/smoke_suite"
  mkdir -p "$SMOKE_DIR"
  rm -rf "$SMOKE_DIR/src"
  mkdir -p "$SMOKE_DIR/src"
  # Minimal representative set (short runtime): ADD (R), ADDI (I), LW (load)
  COPIED=()
  add_candidates=(add-01.S ADD-01.S I-ADD-01.S)
  addi_candidates=(addi-01.S ADDI-01.S I-ADDI-01.S)
  lw_candidates=(lw-01.S LW-01.S I-LW-01.S lw-align-01.S LW-ALIGN-01.S)
  beq_candidates=(beq-01.S BEQ-01.S I-BEQ-01.S)
  sw_candidates=(sw-01.S SW-01.S I-SW-01.S sw-align-01.S SW-ALIGN-01.S)
  jal_candidates=(jal-01.S JAL-01.S)
  jalr_candidates=(jalr-01.S JALR-01.S)
  auipc_candidates=(auipc-01.S AUIPC-01.S)

  pick_and_copy() {
    local -n cand=$1
    local found=""
    for fname in "${cand[@]}"; do
      if [[ -f "$SUITE_ROOT/src/$fname" ]]; then
        cp "$SUITE_ROOT/src/$fname" "$SMOKE_DIR/src/"
        found="$fname"
        break
      fi
    done
    if [[ -n "$found" ]]; then
      COPIED+=("$found")
    else
      echo "Warning: smoke test (${cand[*]}) not found under $SUITE_ROOT/src" >&2
    fi
  }

  pick_and_copy add_candidates
  pick_and_copy addi_candidates
  pick_and_copy lw_candidates
  pick_and_copy beq_candidates
  pick_and_copy sw_candidates
  pick_and_copy jal_candidates
  pick_and_copy jalr_candidates
  pick_and_copy auipc_candidates
  if [[ ${#COPIED[@]} -eq 0 ]]; then
    echo "Smoke tests not found; nothing copied to $SMOKE_DIR/src" >&2
    exit 1
  fi
  SUITE_PATH="$SMOKE_DIR"
  SMOKE_CASES=("${COPIED[@]}")
  echo "Smoke test enabled: running ${#COPIED[@]} tests: ${COPIED[*]}"
fi

CONFIG_GENERATED="$SCRIPT_DIR/riscof/.config.rv32i.${PROCESSOR}.ini"
cat >"$CONFIG_GENERATED" <<EOF
[RISCOF]
ReferencePlugin=spike_simple
ReferencePluginPath=$PLUGIN_ROOT/spike_simple
DUTPlugin=$DUT_NAME
DUTPluginPath=$DUT_NAME

[$DUT_NAME]
pluginpath=$DUT_NAME
ispec=$ISA_FILE
pspec=$PLATFORM_FILE
PATH=../sim/build
sim=$SIM_BINARY
jobs=1

[spike_simple]
pluginpath=$PLUGIN_ROOT/spike_simple
ispec=$PLUGIN_ROOT/spike_simple/spike_simple_isa.yaml
pspec=$PLUGIN_ROOT/spike_simple/spike_simple_platform.yaml
PATH=/opt/riscv/bin
jobs=1
EOF

TOOLCHAIN_DIR="$SCRIPT_DIR/toolchain"
mkdir -p "$TOOLCHAIN_DIR"
create_wrapper() {
  local tool="$1"
  local suffix=${tool#riscv32-unknown-elf-}
  cat >"$TOOLCHAIN_DIR/$tool" <<EOF
#!/usr/bin/env bash
exec riscv64-unknown-elf-$suffix "\$@"
EOF
  chmod +x "$TOOLCHAIN_DIR/$tool"
}
for tool in gcc g++ objcopy objdump readelf; do
  create_wrapper "riscv32-unknown-elf-$tool"
done

export PATH="$TOOLCHAIN_DIR:$PATH"
export PYTHONPATH="$VENV_BIN:${PYTHONPATH:-}"
export PYTHONPATH="$SCRIPT_DIR/riscof:$PLUGIN_ROOT:$PYTHONPATH"

run_riscof_suite() {
  local suite_dir="$1"
  local work_dir="$2"
  local label="$3"
  mkdir -p "$work_dir"
  echo "[INFO] Running RISCOF suite '$label' (suite=${suite_dir}, work=${work_dir})"
  pushd "$SCRIPT_DIR/riscof" >/dev/null
  RISCOF_TIMEOUT=${TIMEOUT_SECS} \
  TIMEOUT=${TIMEOUT_SECS} \
    "${RISCOF_CMD[@]}" run \
    --config "$CONFIG_GENERATED" \
    --work-dir "$work_dir" \
    --suite "$suite_dir" \
    --env "$ENV_ROOT"
  local status=$?
  popd >/dev/null
  return $status
}

if $SMOKE_TEST && [[ "$PROCESSOR" == "octonyte" ]]; then
  overall_status=0
  for test_name in "${SMOKE_CASES[@]}"; do
    label="${test_name%.*}"
    single_suite="$SMOKE_DIR/${label}_suite"
    rm -rf "$single_suite"
    mkdir -p "$single_suite/src"
    cp "$SMOKE_DIR/src/$test_name" "$single_suite/src/"
    single_output="$OUTPUT_DIR/$label"
    rm -rf "$single_output"
    echo "=============================="
    echo "[SMOKE] Starting $test_name for OctoNyte"
    if run_riscof_suite "$single_suite" "$single_output" "$label"; then
      echo "[SMOKE] $test_name PASSED (artifacts under $single_output)"
    else
      echo "[SMOKE] $test_name FAILED (see $single_output for logs)" >&2
      overall_status=1
      break
    fi
  done
  if [[ $overall_status -ne 0 ]]; then
    exit $overall_status
  fi
  echo "RISCV RV32I OctoNyte smoke results stored under $OUTPUT_DIR/<test>"
else
  run_riscof_suite "$SUITE_PATH" "$OUTPUT_DIR" "$PROCESSOR"
  echo "RISCV RV32I conformance results for $PROCESSOR available under $OUTPUT_DIR"
fi

if $SMOKE_TEST && [[ "$PROCESSOR" != "octonyte" ]]; then
  echo "[INFO] Smoke artifacts under $OUTPUT_DIR (signatures/logs):"
  find "$OUTPUT_DIR" -type f \( -name "*.signature" -o -name "*.log" -o -name "*.elf" \) | sed 's|^|  |'
  echo "[INFO] Smoke tests executed:"
  find "$OUTPUT_DIR/src" -maxdepth 3 -mindepth 3 -type d | sed 's|^|  |'
fi

if $SMOKE_TEST && [[ "$PROCESSOR" == "tetranyte" ]]; then
  for test_name in "${COPIED[@]}"; do
    ELF_PATH=$(find "$OUTPUT_DIR/src" -path "*${test_name}/dut/*.elf" | head -n1 || true)
    REF_SIG=$(find "$OUTPUT_DIR/src" -path "*${test_name}/ref/Reference-spike.signature" | head -n1 || true)
    if [[ -z "$ELF_PATH" || ! -f "$ELF_PATH" ]]; then
      echo "Could not locate ELF for $test_name under $OUTPUT_DIR/src" >&2
      continue
    fi
    echo "Running per-thread smoke comparisons using $ELF_PATH"
    declare -a THREAD_SIGS=()
    for tid in 0 1 2 3; do
      SIG_PATH="$OUTPUT_DIR/src/${test_name}/dut/DUT-tetranyte-rv32i.thread${tid}.signature"
      LOG_PATH="$OUTPUT_DIR/src/${test_name}/dut/DUT-tetranyte-rv32i.thread${tid}.log"
      THREAD_MASK=$((1 << tid))
      "$SCRIPT_DIR/sim/build/tetranyte_obj/VTetraNyteRV32ICore" \
        --elf "$ELF_PATH" \
        --signature "$SIG_PATH" \
        --log "$LOG_PATH" \
        --max-cycles 2000000 \
        --thread-mask "$THREAD_MASK" \
        --trace-pc || { echo "Thread $tid simulation failed for $test_name" >&2; exit 1; }
      echo "[INFO] Thread $tid simulation done for $test_name. Signature: $SIG_PATH"
      THREAD_SIGS+=("$SIG_PATH")
    done
    BASE_SIG="${THREAD_SIGS[0]}"
    for sig in "${THREAD_SIGS[@]:1}"; do
      if ! cmp -s "$BASE_SIG" "$sig"; then
        echo "Thread signature mismatch for $test_name: $BASE_SIG vs $sig" >&2
        exit 1
      fi
    done
    echo "[INFO] All thread signatures match each other for $test_name."
    if [[ -n "$REF_SIG" && -f "$REF_SIG" ]]; then
      if cmp -s "$BASE_SIG" "$REF_SIG"; then
        echo "[INFO] Thread signatures match spike reference for $test_name."
      else
        echo "Thread signatures do not match spike reference for $test_name: $REF_SIG" >&2
        exit 1
      fi
    else
      echo "Reference spike signature not found for $test_name; skipped reference compare."
    fi
  done
fi
