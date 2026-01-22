package plic

import chisel3._
import chisel3.stage.ChiselStage
import java.nio.file.{Files, Paths, StandardCopyOption}
import java.nio.file.StandardOpenOption
import java.nio.charset.StandardCharsets

object PlicCellGenerator extends App {
  println("Generating PlicCell Verilog...")
  (new ChiselStage).emitVerilog(
    new PlicCell(id = 1, sources = 8, priorities = 7),
    Array("--target-dir", "generated")
  )
  println("✓ PlicCell.v generated in generated/ directory")
}

object PlicCoreGenerator extends App {
  println("Generating PlicCore Verilog via Chisel...")
  (new ChiselStage).emitVerilog(new PlicCore(), Array("--target-dir", "generated"))

  // Insert Verilator-friendly pragmas at top of generated file to avoid
  // tool warnings originating from generator patterns (generate blocks,
  // width/replicate idioms, etc.). This reduces the need for separate
  // postprocessing steps and keeps the generator self-contained.
  val genPath = Paths.get("generated", "PlicCore.v")
  if (Files.exists(genPath)) {
    val pragmas = Seq(
      "/* verilator lint_off DECLFILENAME */",
      "/* verilator lint_off MODDUP */",
      "/* verilator lint_off MULTITOP */",
      "/* verilator lint_off GENUNNAMED */",
      "/* verilator lint_off VARHIDDEN */",
      "/* verilator lint_off WIDTHEXPAND */",
      "/* verilator lint_off WIDTHTRUNC */",
      "/* verilator lint_off UNUSEDSIGNAL */",
      "/* verilator lint_off UNUSEDGENVAR */",
      ""
    ).mkString(System.lineSeparator())
    val original = new String(Files.readAllBytes(genPath), StandardCharsets.UTF_8)
    if (!original.contains("verilator lint_off DECLFILENAME")) {
      val updated = pragmas + System.lineSeparator() + original
      Files.write(genPath, updated.getBytes(StandardCharsets.UTF_8), StandardOpenOption.TRUNCATE_EXISTING)
    }
  }

  println("✓ PlicCore.v generated in generated/")
}

object PlicGatewayGenerator extends App {
  println("Generating PlicGateway Verilog via Chisel...")
  (new ChiselStage).emitVerilog(new PlicGateway(), Array("--target-dir", "generated"))
  println("✓ PlicGateway.v generated in generated/")
}

object PlicTargetGenerator extends App {
  println("Generating PlicTarget Verilog via Chisel...")
  (new ChiselStage).emitVerilog(new PlicTarget(), Array("--target-dir", "generated"))
  println("✓ PlicTarget.v generated in generated/")
}

object PlicGeneratorAll extends App {
  // Generate only the top-level PlicCore. It contains all submodules
  // and avoids producing duplicate per-module files which lead to
  // multiple-definition warnings in downstream tools (Verilator).
  PlicCoreGenerator.main(Array())
  println("✓ PlicCore generated in generated/ (single canonical file)")
}
