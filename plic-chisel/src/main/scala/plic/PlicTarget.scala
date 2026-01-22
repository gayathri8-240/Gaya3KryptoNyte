package plic

import chisel3._
import chisel3.util._

class PlicTargetIO(sources: Int, priorities: Int) extends Bundle {
  val rst_n = Input(Bool())
  val id_i = Input(Vec(sources, UInt(log2Ceil(sources + 1).W)))
  val priority_i = Input(Vec(sources, UInt(log2Ceil(priorities).W)))
  val threshold_i = Input(UInt(log2Ceil(priorities).W))
  val ireq_o = Output(Bool())
  val id_o = Output(UInt(log2Ceil(sources + 1).W))
}

class PlicTarget(val sources: Int = 8, val priorities: Int = 8) extends Module {
  val io = IO(new PlicTargetIO(sources, priorities))
  val asyncReset = (!io.rst_n).asAsyncReset

  // simple priority index: find highest priority and corresponding id (combinational)
  val idWidth = log2Ceil(sources + 1)
  val prWidth = log2Ceil(priorities)

  val init = (0.U(prWidth.W), 0.U(idWidth.W))
  val (bestP, bestI) = (0 until sources).foldLeft(init) { case ((bp, bi), i) =>
    val sel = io.priority_i(i) > bp
    val nbp = Mux(sel, io.priority_i(i), bp)
    val nbi = Mux(sel, io.id_i(i), bi)
    (nbp, nbi)
  }

  val ireq_reg = withReset(asyncReset) { RegInit(false.B) }
  val id_reg = withReset(asyncReset) { RegInit(0.U(idWidth.W)) }

  when(bestP > io.threshold_i) { ireq_reg := true.B } .otherwise { ireq_reg := false.B }
  id_reg := bestI

  io.ireq_o := ireq_reg
  io.id_o := id_reg
}
