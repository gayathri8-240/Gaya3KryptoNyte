# Physical Design Config Basics

## Files
- `config.base.json` – shared defaults for Sky130A/`sky130_fd_sc_hd`.
- `config.ZeroNyteRV32ICore.json` – full-timing settings for the core.
- `config.ZeroNyteRV32ICore_relaxed.json` – looser timing/area to converge faster.
- `config.template.json` – optional starting point when creating new modules.
- `_runs/` – generated output from the OpenLane2 flow.

## Running the Flow
```bash
cd physical_design
./generate_physical_design.sh               # Uses config.ZeroNyteRV32ICore.json
./generate_physical_design.sh --config-module config.ZeroNyteRV32ICore_relaxed.json
```
The script copies RTL from `../rtl/generators/generated/verilog_hierarchical_timed/` and writes the merged `config.json` under `_runs/<module>/` before launching OpenLane2 via `nix-shell`.

## How Configs Merge
`generate_physical_design.sh` loads `config.base.json` and the chosen module config, merges them with `jq`, then passes the merged JSON directly to OpenLane2. Module settings win on conflicts. You can point to a different base or module JSON with `--config-base` and `--config-module`.

## Useful Command-Line Overrides
`--module-name`, `--clock-period <ns>`, `--utilization <ratio>`, `--output-root <dir>`, and `--openlane2-path <path>` adjust the environment before the merge. Provide a custom JSON if you need additional fields.

## Requirements & Tips
- `jq`, `nix-shell`, and an OpenLane2 checkout (default `/opt/skywater-pdk/openlane2`).
- Ensure the target RTL exists; otherwise the script aborts.
- Drop constraint files into `physical_design/constraints/` to have them copied alongside the run.
