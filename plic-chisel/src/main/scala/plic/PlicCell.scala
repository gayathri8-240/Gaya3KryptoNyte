package plic

import chisel3._
import chisel3.util._

class PlicCellIO(sourceBits: Int, priorityBits: Int) extends Bundle {
  val rst_n = Input(Bool())
  val ip = Input(Bool())
  val ie = Input(Bool())
  val priority = Input(UInt(priorityBits.W))
  val id = Output(UInt(sourceBits.W))
  val priorityOut = Output(UInt(priorityBits.W))
}

class PlicCell(val id: Int = 1, val sources: Int = 8, val priorities: Int = 7) extends Module {
  val sourceBits = log2Ceil(sources + 1)
  val priorityBits = log2Ceil(priorities)
  val io = IO(new PlicCellIO(sourceBits, priorityBits))

  val asyncReset = (!io.rst_n).asAsyncReset

  val (priorityReg, idReg) = withReset(asyncReset) {
    val p = RegInit(0.U(priorityBits.W))
    val i = RegInit(0.U(sourceBits.W))
    (p, i)
  }

  when(io.ip && io.ie) {
    priorityReg := io.priority
    idReg := id.U
  }.otherwise {
    priorityReg := 0.U
    idReg := 0.U
  }

  io.priorityOut := priorityReg
  io.id := idReg
}
