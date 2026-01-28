# RTL

This directory builds the RTL (Chisel/Scala) and runs unit tests via `sbt` (see `rtl/build.sbt`).

## Layout
- `rtl/library/`: reusable modules (`src/main/scala`) and unit tests (`src/test/scala`)
- `rtl/ZeroNyte/rv32i/`, `rtl/TetraNyte/rv32i/`, `rtl/OctoNyte/rv32i/`: core implementations
- `rtl/generators/`: elaboration/RTL generation entrypoints

## `build.sbt` overview
- Projects (use these IDs with `sbt <project>/<task>`):
  - `library`, `zeroNyte`, `tetraNyte`, `octoNyte`, `generators` (root aggregates all of them)
- RTL generation tasks (defined on the `generators` project):
  - `generateLibraryRTL`, `generateZeroNyteRTL`, `generateTetraNyteRTL`, `generateOctoNyteRTL`, `generateRTL`
- Convenience command aliases (root project):
  - `genLibrary`, `genZeroNyte`, `genTetraNyte`, `genOctoNyte`, `genAllRtl`

## Build
Run these from `KryptoNyte/rtl`:
- Compile everything: `sbt compile`
- Compile a single subproject: `sbt library/compile` (or `zeroNyte/compile`, `tetraNyte/compile`, `octoNyte/compile`, `generators/compile`)
- Generate RTL:
  - All: `sbt genAllRtl` (alias for `generators/generateRTL`)
  - One core/library: `sbt genLibrary`, `sbt genZeroNyte`, `sbt genTetraNyte`, `sbt genOctoNyte`

## Unit tests
Run these from `KryptoNyte/rtl`:
- All tests (across aggregated projects): `sbt test`
- Library tests only: `sbt library/test`
- Single test suite: `sbt 'library/testOnly Pipeline.ThreadSchedulerTest'`
- Core: `sbt 'octoNyte/testOnly OctoNyte.OctoNyteRV32ICoreTest'`
