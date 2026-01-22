#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/plic-chisel"

if ! command -v sbt >/dev/null 2>&1; then
  echo "sbt not found in PATH. Please install sbt to generate Verilog." >&2
  exit 2
fi

echo "Compiling Chisel project..."
sbt compile

echo "Generating Verilog via PlicGeneratorAll..."
sbt "runMain plic.PlicGeneratorAll"

POSTPROC="$ROOT_DIR/scripts/postprocess_sv.sh"
if [ ! -x "$POSTPROC" ]; then
  chmod +x "$POSTPROC"
fi

GEN_DIR="$ROOT_DIR/plic-chisel/generated"
echo "Postprocessing generated Verilog files for lint friendliness..."
for f in "$GEN_DIR"/*.v; do
  [ -e "$f" ] || continue
  "$POSTPROC" "$f"
done

DEST_DIR="$ROOT_DIR/rtl/verilog/core"

if [ ! -d "$GEN_DIR" ]; then
  echo "Generated directory not found: $GEN_DIR" >&2
  exit 3
fi

to_snake() {
  echo "$1" | sed -E 's/([A-Z])/_\L\1/g' | sed -E 's/^_//'
}

shopt -s nullglob
# Only copy the canonical top-level file produced by the generator to avoid
# duplicate module definitions (PlicCore contains all submodules).
for f in "$GEN_DIR"/PlicCore.v; do
  if [ -s "$f" ]; then
    dest="$DEST_DIR/plic_core.sv"
    echo "Copying $f -> $dest"
    cp "$f" "$dest"
  else
    echo "Skipping empty generated file: $f"
  fi
done

echo "Generation and sync complete."
