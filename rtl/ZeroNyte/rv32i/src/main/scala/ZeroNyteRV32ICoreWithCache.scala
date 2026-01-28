package ZeroNyte

import chisel3._
import chisel3.util._
import Decoders.RV32IDecode
import ALUs.ALU32

class ZeroNyteRV32ICoreWithCache extends Module {
  val io = IO(new Bundle {
    // Instruction Memory Interface
    val imem_addr = Output(UInt(32.W))
    val imem_rdata = Input(UInt(32.W))

    // Data Memory Interface
    val dmem_addr = Output(UInt(32.W))
    val dmem_rdata = Input(UInt(32.W))
    val dmem_wdata = Output(UInt(32.W))
    val dmem_wen = Output(Bool())

    // Debug Outputs
    val pc_out    = Output(UInt(32.W))
    val instr_out = Output(UInt(32.W))
    val result    = Output(UInt(32.W))
  })

  // ---------- Program Counter ----------
  val pc = RegInit("h80000000".U(32.W))  // Start at RISC-V reset vector
  io.pc_out := pc

  // ---------- Instruction Cache (Simple) ----------
  val I$ = Module(new ICacheSimple(new ICacheSimpleConfig(2*1024, 16, 1)))

  // Request fetch every cycle for current PC (cache will stall/fill as needed)
  I$.io.pc := pc
  I$.io.pc_valid := true.B

  // Hook cache to external imem
  io.imem_addr := I$.io.mem_addr
  I$.io.mem_rdata := io.imem_rdata
  // If your imem returns combinationally, set mem_rvalid true
  I$.io.mem_rvalid := true.B

  // Instruction and valid flag from cache
  val instr_valid = I$.io.instr_valid
  val fetched_instr = I$.io.instr

  // Expose visible instruction for debug (0 when not valid)
  io.instr_out := Mux(instr_valid, fetched_instr, 0.U)

  // ---------- Register File ----------
  val regFile = RegInit(VecInit(Seq.fill(32)(0.U(32.W))))

  // ---------- Decode (based on fetched instruction) ----------
  // Use fetched instruction only when valid; otherwise use 0 to keep decode stable.
  val instr = Wire(UInt(32.W))
  instr := Mux(instr_valid, fetched_instr, 0.U)

  val dec = RV32IDecode.decodeInstr(instr)
  val rd  = instr(11,7)
  val rs1 = instr(19,15)
  val rs2 = instr(24,20)

  val r1 = regFile(rs1)
  val r2Reg = regFile(rs2)

  val useImmForB = (instr(6,0) === RV32IDecode.OP_I) || dec.isLoad || dec.isStore || dec.isJALR || dec.isLUI || dec.isAUIPC
  val operandB = Mux(useImmForB, dec.imm, r2Reg)
  val operandA = Mux(dec.isLUI, 0.U, r1)

  // ---------- ALU ----------
  val alu = Module(new ALU32)
  alu.io.a := operandA
  alu.io.b := operandB
  alu.io.opcode := dec.aluOp

  // ---------- Data Memory Access ----------
  // Only use ALU result when an instruction is valid; otherwise drive safe zeros
  val effAddr = Wire(UInt(32.W))
  effAddr := Mux(instr_valid, alu.io.result, 0.U)

  val addrBase   = Cat(effAddr(31, 2), 0.U(2.W))
  val byteOffset = effAddr(1, 0)
  val halfOffset = effAddr(1)
  val storeFunct3 = instr(14, 12)

  val dmemReadWord = io.dmem_rdata

  // Build storeData only when an instruction is valid; default 0
  val storeData = WireDefault(0.U(32.W))
  when(instr_valid) {
    storeData := r2Reg
    when(dec.isStore) {
      switch(storeFunct3) {
        is("b000".U) { // SB
          val byteVal = r2Reg(7, 0)
          val byteMask = (0xff.U(32.W)) << (byteOffset << 3)
          val byteShifted = (byteVal & 0xff.U) << (byteOffset << 3)
          storeData := (dmemReadWord & ~byteMask) | byteShifted
        }
        is("b001".U) { // SH
          val halfVal = r2Reg(15, 0)
          val halfMask = (0xffff.U(32.W)) << (halfOffset << 4)
          val halfShifted = (halfVal & 0xffff.U) << (halfOffset << 4)
          storeData := (dmemReadWord & ~halfMask) | halfShifted
        }
        is("b010".U) { // SW
          storeData := r2Reg
        }
      }
    }
  }

  // Drive data memory outputs only when instruction is valid and op requires it
  io.dmem_addr := Mux(instr_valid && (dec.isLoad || dec.isStore), addrBase, 0.U)
  io.dmem_wdata := Mux(instr_valid && dec.isStore, storeData, 0.U)
  io.dmem_wen := instr_valid && dec.isStore

  // ---------- Write Back ----------
  val pcPlus4 = pc + 4.U
  val auipcValue = pc + dec.imm
  val jalrTarget = ((r1.asSInt + dec.imm.asSInt).asUInt) & ~1.U(32.W)

  val write_data = Wire(UInt(32.W))
  val doWrite = Wire(Bool())
  write_data := alu.io.result
  doWrite := dec.isALU

  // Loads: only process when instr_valid
  when(instr_valid && dec.isLoad) {
    val loadWord = io.dmem_rdata
    val byteVec = VecInit(
      loadWord(7, 0),
      loadWord(15, 8),
      loadWord(23, 16),
      loadWord(31, 24)
    )
    val halfVec = VecInit(
      loadWord(15, 0),
      loadWord(31, 16)
    )
    val shiftedByte = byteVec(byteOffset)
    val shiftedHalf = halfVec(halfOffset)
    val loadFunct3 = instr(14, 12)

    write_data := loadWord
    doWrite := true.B

    switch(loadFunct3) {
      is("b000".U) { // LB
        write_data := Cat(Fill(24, shiftedByte(7)), shiftedByte)
      }
      is("b001".U) { // LH
        write_data := Cat(Fill(16, shiftedHalf(15)), shiftedHalf)
      }
      is("b010".U) { // LW
        write_data := loadWord
      }
      is("b100".U) { // LBU
        write_data := Cat(0.U(24.W), shiftedByte)
      }
      is("b101".U) { // LHU
        write_data := Cat(0.U(16.W), shiftedHalf)
      }
    }
  }

  when(instr_valid && dec.isLUI) {
    write_data := dec.imm
    doWrite := true.B
  }

  when(instr_valid && dec.isAUIPC) {
    write_data := auipcValue
    doWrite := true.B
  }

  when(instr_valid && (dec.isJAL || dec.isJALR)) {
    write_data := pcPlus4
    doWrite := true.B
  }

  // Only commit register writes when instruction is valid and destination is not x0
  when(instr_valid && doWrite && rd =/= 0.U) {
    regFile(rd) := write_data
  }

  io.result := write_data

  // ---------- PC Update ----------
  val branchEq  = r1 === r2Reg
  val branchLT  = r1.asSInt < r2Reg.asSInt
  val branchLTU = r1 < r2Reg

  val branchTaken = WireDefault(false.B)
  when(dec.isBranch) {
    switch(instr(14,12)) {
      is("b000".U) { branchTaken := branchEq }         // BEQ
      is("b001".U) { branchTaken := !branchEq }        // BNE
      is("b100".U) { branchTaken := branchLT }         // BLT
      is("b101".U) { branchTaken := !branchLT }        // BGE
      is("b110".U) { branchTaken := branchLTU }        // BLTU
      is("b111".U) { branchTaken := !branchLTU }       // BGEU
    }
  }

  val branchOffset = (dec.imm.asSInt << 1).asUInt
  val branchTarget = (pc.asSInt + branchOffset.asSInt).asUInt
  val jalTarget = (pc.asSInt + dec.imm.asSInt).asUInt

  val nextPC = WireDefault(pcPlus4)
  when(dec.isBranch && branchTaken) {
    nextPC := branchTarget
  }
  when(dec.isJAL) {
    nextPC := jalTarget
  }
  when(dec.isJALR) {
    nextPC := jalrTarget
  }

  // Update PC only when we have a valid instruction (i.e., cache returned it).
  when(instr_valid) {
    pc := nextPC
  }
}