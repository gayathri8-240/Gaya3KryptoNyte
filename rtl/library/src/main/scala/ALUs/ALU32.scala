package ALUs

import chisel3._
import chisel3.util._

object ALU32 {
  object Opcode {
    val WIDTH = 5

    val ADD  = "b00000".U(WIDTH.W)
    val SUB  = "b00001".U(WIDTH.W)
    val SLL  = "b00010".U(WIDTH.W)
    val SLT  = "b00100".U(WIDTH.W)
    val SLTU = "b00110".U(WIDTH.W)
    val XOR  = "b01000".U(WIDTH.W)
    val SRL  = "b01010".U(WIDTH.W)
    val SRA  = "b01011".U(WIDTH.W)
    val OR   = "b01100".U(WIDTH.W)
    val AND  = "b01110".U(WIDTH.W)
  }
}

class ALU32 extends Module {
  val io = IO(new Bundle {
    val a = Input(UInt(32.W))
    val b = Input(UInt(32.W))
    val opcode = Input(UInt(ALU32.Opcode.WIDTH.W))
    val result = Output(UInt(32.W))
  })

  val shamt = io.b(4, 0)

  val addResult  = (io.a.asSInt +& io.b.asSInt).asUInt
  val subResult  = (io.a.asSInt -& io.b.asSInt).asUInt
  val sllResult  = io.a << shamt
  val sltResult  = Mux(io.a.asSInt < io.b.asSInt, 1.U, 0.U)
  val sltuResult = Mux(io.a < io.b, 1.U, 0.U)
  val xorResult  = io.a ^ io.b
  val srlResult  = io.a >> shamt
  val sraResult  = (io.a.asSInt >> shamt).asUInt
  val orResult   = io.a | io.b
  val andResult  = io.a & io.b

  val result = WireDefault(0.U(32.W))

  switch(io.opcode) {
    is(ALU32.Opcode.ADD)  { result := addResult }
    is(ALU32.Opcode.SUB)  { result := subResult }
    is(ALU32.Opcode.SLL)  { result := sllResult }
    is(ALU32.Opcode.SLT)  { result := sltResult }
    is(ALU32.Opcode.SLTU) { result := sltuResult }
    is(ALU32.Opcode.XOR)  { result := xorResult }
    is(ALU32.Opcode.SRL)  { result := srlResult }
    is(ALU32.Opcode.SRA)  { result := sraResult }
    is(ALU32.Opcode.OR)   { result := orResult }
    is(ALU32.Opcode.AND)  { result := andResult }
  }

  io.result := result
}
