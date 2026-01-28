#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

cd "$REPO_ROOT"

SIM_DIR="tests/sim"
BUILD_DIR="$SIM_DIR/build"
OBJ_DIR="$BUILD_DIR/tetranyte_obj"

mkdir -p "$BUILD_DIR"
rm -rf "$OBJ_DIR"
mkdir -p "$OBJ_DIR"

VERILOG_TOP="rtl/generators/generated/verilog_hierarchical_timed/TetraNyteRV32ICore.v"
RTL_SRC_DIRS=("rtl/TetraNyte/rv32i/src" "rtl/library/src")

regen_rtl=0
if [[ "${TETRANYTE_REGEN_RTL:-0}" == "1" ]]; then
  regen_rtl=1
elif [[ ! -f "$VERILOG_TOP" ]]; then
  regen_rtl=1
elif [[ -n "$(find "${RTL_SRC_DIRS[@]}" -type f -name '*.scala' -newer "$VERILOG_TOP" -print -quit)" ]]; then
  regen_rtl=1
fi

if [[ "$regen_rtl" -eq 1 ]]; then
  echo "Regenerating TetraNyte RTL..."
  (cd "rtl" && sbt "generators/generateTetraNyteRTL")
fi

if [[ ! -f "$VERILOG_TOP" ]]; then
  echo "Expected RTL at $VERILOG_TOP. Regenerate with 'sbt generators/generateTetraNyteRTL' from rtl/." >&2
  exit 1
fi

verilator -cc "$VERILOG_TOP" \
  --top-module TetraNyteRV32ICore \
  --Mdir "$OBJ_DIR" \
  --timescale-override 1ns/1ns \
  --trace \
  --Wno-UNOPTFLAT \
  --build \
  -CFLAGS "-O2 -std=c++17" \
  -LDFLAGS "-O2" \
  --exe \
    "$SIM_DIR/tetranyte_sim.cpp" \
    "$SIM_DIR/elf_loader.cpp" \
    "$SIM_DIR/memory.cpp"

cp "$OBJ_DIR/VTetraNyteRV32ICore" "$BUILD_DIR/tetranyte_sim"
chmod +x "$BUILD_DIR/tetranyte_sim"

echo "Built simulator at $BUILD_DIR/tetranyte_sim"
