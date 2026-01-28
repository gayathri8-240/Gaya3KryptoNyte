package Decoders

import chisel3._
import chisel3.util._
import ALUs.ALU32

object RV32IDecode {
  // Common opcodes
  val OP_R    = "b0110011".U(7.W)
  val OP_I    = "b0010011".U(7.W)
  val LOAD    = "b0000011".U(7.W)
  val STORE   = "b0100011".U(7.W)
  val BRANCH  = "b1100011".U(7.W)
  val JAL     = "b1101111".U(7.W)
  val JALR    = "b1100111".U(7.W)
  val LUI     = "b0110111".U(7.W)
  val AUIPC   = "b0010111".U(7.W)
  val SYSTEM  = "b1110011".U(7.W)
  val FENCE   = "b0001111".U(7.W)

  /** Helper signals for controlling the pipeline. */
  class DecodeSignals extends Bundle {
    val isALU    = Bool()
    val isLoad   = Bool()
    val isStore  = Bool()
    val isBranch = Bool()
    val isJAL    = Bool()
    val isJALR   = Bool()
    val isLUI    = Bool()
    val isAUIPC  = Bool()
    val isSystem = Bool()
    val isFence  = Bool()
    val usesImm  = Bool()

    val rs1      = UInt(5.W)
    val rs2      = UInt(5.W)
    val rd       = UInt(5.W)

    val aluOp    = UInt(5.W)
    val imm      = UInt(32.W)
  }

  // Sign-extend utilities
  def signExt12(value: UInt): UInt = {
    val sign = value(11)
    Cat(Fill(20, sign), value)
  }
  def signExt13(value: UInt): UInt = {
    val sign = value(12)
    Cat(Fill(19, sign), value)
  }
  def signExt20(value: UInt): UInt = {
    val sign = value(19)
    Cat(Fill(12, sign), value)
  }
  def signExt21(value: UInt): UInt = {
    val sign = value(20)
    Cat(Fill(11, sign), value)
  }

  /** Main decode function */
  def decodeInstr(instr: UInt): DecodeSignals = {
    val dec = Wire(new DecodeSignals)
    dec := 0.U.asTypeOf(new DecodeSignals)

    val opcode = instr(6,0)
    val funct3 = instr(14,12)
    val funct7 = instr(31,25)

    dec.rs1 := instr(19,15)
    dec.rs2 := instr(24,20)
    dec.rd  := instr(11,7)

    switch(opcode) {
      // R-type
      is(OP_R) {
        dec.isALU := true.B
        when(funct3 === "b000".U) {
          when(funct7 === "b0100000".U) {
            dec.aluOp := ALU32.Opcode.SUB
          }.otherwise {
            dec.aluOp := ALU32.Opcode.ADD
          }
        }.elsewhen(funct3 === "b001".U) { dec.aluOp := ALU32.Opcode.SLL }
         .elsewhen(funct3 === "b010".U) { dec.aluOp := ALU32.Opcode.SLT }
         .elsewhen(funct3 === "b011".U) { dec.aluOp := ALU32.Opcode.SLTU }
         .elsewhen(funct3 === "b100".U) { dec.aluOp := ALU32.Opcode.XOR }
         .elsewhen(funct3 === "b101".U) {
           when(funct7 === "b0100000".U) {
             dec.aluOp := ALU32.Opcode.SRA
           }.otherwise {
             dec.aluOp := ALU32.Opcode.SRL
           }
         }
         .elsewhen(funct3 === "b110".U) { dec.aluOp := ALU32.Opcode.OR }
         .elsewhen(funct3 === "b111".U) { dec.aluOp := ALU32.Opcode.AND }
      }

      // I-type ALU
      is(OP_I) {
        dec.isALU := true.B
        dec.usesImm := true.B
        val immI = signExt12(instr(31,20))
        dec.imm := immI
        switch(funct3) {
          is("b000".U) { dec.aluOp := ALU32.Opcode.ADD }
          is("b010".U) { dec.aluOp := ALU32.Opcode.SLT }
          is("b011".U) { dec.aluOp := ALU32.Opcode.SLTU }
          is("b100".U) { dec.aluOp := ALU32.Opcode.XOR }
          is("b110".U) { dec.aluOp := ALU32.Opcode.OR }
          is("b111".U) { dec.aluOp := ALU32.Opcode.AND }
          is("b001".U) { dec.aluOp := ALU32.Opcode.SLL }
          is("b101".U) {
            when(instr(30) === 1.U) {
              dec.aluOp := ALU32.Opcode.SRA
            }.otherwise {
              dec.aluOp := ALU32.Opcode.SRL
            }
          }
        }
      }

      // Loads
      is(LOAD) {
        dec.isLoad := true.B
        dec.usesImm := true.B
        dec.imm := signExt12(instr(31,20))
      }

      // Stores
      is(STORE) {
        dec.isStore := true.B
        dec.usesImm := true.B
        val storeImm = Cat(instr(31,25), instr(11,7))
        dec.imm := signExt12(storeImm)
      }

      // Branch
      is(BRANCH) {
        dec.isBranch := true.B
        // Keep branch immediate in halfword units (bit0 dropped); pipeline shifts left by 1.
        val branchImm = Cat(instr(31), instr(7), instr(30,25), instr(11,8))
        dec.imm := signExt12(branchImm)
      }

      // JAL
      is(JAL) {
        dec.isJAL := true.B
        val jumpImm = Cat(instr(31), instr(19,12), instr(20), instr(30,21), 0.U(1.W))
        dec.imm := signExt21(jumpImm(20,0))
      }

      // JALR
      is(JALR) {
        dec.isJALR := true.B
        dec.usesImm := true.B
        dec.imm := signExt12(instr(31,20))
      }

      // LUI
      is(LUI) {
        dec.isLUI := true.B
        dec.usesImm := true.B
        dec.imm   := Cat(instr(31,12), Fill(12, 0.U))
      }

      // AUIPC
      is(AUIPC) {
        dec.isAUIPC := true.B
        dec.usesImm := true.B
        dec.imm     := Cat(instr(31,12), Fill(12, 0.U))
      }

      // SYSTEM
      is(SYSTEM) {
        dec.isSystem := true.B
      }

      // FENCE
      is(FENCE) {
        dec.isFence := true.B
      }
    }

    dec
  }
}

class RV32IDecodeModule extends Module {
  val io = IO(new Bundle {
    val instr = Input(UInt(32.W))
    val signals = Output(new RV32IDecode.DecodeSignals)
  })

  io.signals := RV32IDecode.decodeInstr(io.instr)
}
