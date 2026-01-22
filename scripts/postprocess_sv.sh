#!/usr/bin/env bash
set -euo pipefail

# Insert Verilator pragmas at top of generated SV file if not present
# Usage: postprocess_sv.sh <file>

f="$1"
if [ ! -f "$f" ]; then
  echo "File not found: $f" >&2
  exit 1
fi

# Pragmas to insert (write to a temp file to avoid quoting issues)
PRAGMAS_FILE=$(mktemp)
cat > "$PRAGMAS_FILE" <<'PRAGMAS'
/* verilator lint_off DECLFILENAME */
/* verilator lint_off MODDUP */
/* verilator lint_off MULTITOP */
/* verilator lint_off GENUNNAMED */
/* verilator lint_off VARHIDDEN */
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off UNUSEDGENVAR */

PRAGMAS

# Check if file already contains a pragma marker we add
if grep -q "verilator lint_off DECLFILENAME" "$f"; then
  echo "Pragmas already present in $f"
  exit 0
fi

# Create backup
cp "$f" "${f}.bak"

# Find first module line
n=$(grep -n -m1 -E '^\s*module\b' "${f}.bak" | cut -d: -f1 || true)
if [ -z "$n" ]; then
  echo "No module declaration found in $f; skipping" >&2
  exit 1
fi

tmp="${f}.tmp"
head -n $((n-1)) "${f}.bak" > "$tmp"
cat "$PRAGMAS_FILE" >> "$tmp"
tail -n +$n "${f}.bak" >> "$tmp"
mv "$tmp" "$f"

rm -f "$PRAGMAS_FILE"

echo "Inserted pragmas into $f"
