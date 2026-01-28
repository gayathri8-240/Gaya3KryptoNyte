#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

cd "$REPO_ROOT"

SIM_DIR="tests/sim"
BUILD_DIR="$SIM_DIR/build"
OBJ_DIR="$BUILD_DIR/octonyte_obj"

mkdir -p "$BUILD_DIR"
rm -rf "$OBJ_DIR"
mkdir -p "$OBJ_DIR"

VERILOG_TOP="rtl/generators/generated/verilog_hierarchical_timed/OctoNyteRV32ICore.v"
RTL_SRC_DIRS=("rtl/OctoNyte/rv32i/src" "rtl/library/src")

regen_rtl=0
if [[ "${OCTONYTE_REGEN_RTL:-0}" == "1" ]]; then
  regen_rtl=1
elif [[ ! -f "$VERILOG_TOP" ]]; then
  regen_rtl=1
elif [[ -n "$(find "${RTL_SRC_DIRS[@]}" -type f -name '*.scala' -newer "$VERILOG_TOP" -print -quit)" ]]; then
  regen_rtl=1
fi

if [[ "$regen_rtl" -eq 1 ]]; then
  echo "Regenerating OctoNyte RTL..."
  (cd "rtl" && sbt "generators/generateOctoNyteRTL")
fi

if [[ ! -f "$VERILOG_TOP" ]]; then
  echo "Expected RTL at $VERILOG_TOP. Regenerate with 'sbt generateOctoNyteRTL' from rtl/." >&2
  exit 1
fi

verilator -cc "$VERILOG_TOP" \
  --top-module OctoNyteRV32ICore \
  --Mdir "$OBJ_DIR" \
  --timescale-override 1ns/1ns \
  --trace \
  --Wno-UNOPTFLAT \
  --build \
  -CFLAGS "-O2 -std=c++17" \
  -LDFLAGS "-O2" \
  --exe \
    "$SIM_DIR/octonyte_sim.cpp" \
    "$SIM_DIR/elf_loader.cpp" \
    "$SIM_DIR/memory.cpp"

cp "$OBJ_DIR/VOctoNyteRV32ICore" "$BUILD_DIR/octonyte_sim"
chmod +x "$BUILD_DIR/octonyte_sim"

echo "Built simulator at $BUILD_DIR/octonyte_sim"
