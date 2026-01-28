package TetraNyte

import chisel3._
import chisel3.util._
import ALUs._
import BranchUnit._
import Decoders._
import LoadUnit._
import StoreUnit._
import RegFiles._

class TetraNyteRV32ICoreWithCacheIO(val numThreads: Int) extends Bundle {
  val threadEnable = Input(Vec(numThreads, Bool()))
  val instrMem = Input(UInt(32.W))
  val dataMemResp = Input(UInt(32.W))
  val memAddr = Output(UInt(32.W))
  val memWrite = Output(UInt(32.W))
  val memMask = Output(UInt(4.W))
  val memValid = Output(Bool())
  val memMisaligned = Output(Bool())

  val fetchThread = Output(UInt(log2Ceil(numThreads).W))
  val if_pc = Output(Vec(numThreads, UInt(32.W)))
  val if_instr = Output(Vec(numThreads, UInt(32.W)))
  val id_rs1Data = Output(Vec(numThreads, UInt(32.W)))
  val id_rs2Data = Output(Vec(numThreads, UInt(32.W)))
  val ex_aluResult = Output(Vec(numThreads, UInt(32.W)))
  val mem_loadData = Output(Vec(numThreads, UInt(32.W)))

  // Debug/control visibility
  val ctrlTaken = Output(Bool())
  val ctrlThread = Output(UInt(log2Ceil(numThreads).W))
  val ctrlFromPC = Output(UInt(32.W))
  val ctrlTarget = Output(UInt(32.W))
  val ctrlIsJal = Output(Bool())
  val ctrlIsJalr = Output(Bool())
  val ctrlIsBranch = Output(Bool())
}

class TetraNyteRV32ICoreWithCache extends Module {
  val numThreads = 4
  val io = IO(new TetraNyteRV32ICoreWithCacheIO(numThreads))

  // Per-thread PC registers and flush tracking
  val pcResetVec = VecInit(Seq.fill(numThreads)("h80000000".U(32.W)))
  val flushResetVec = VecInit(Seq.fill(numThreads)(false.B))
  val pcRegs = Reg(Vec(numThreads, UInt(32.W)))
  val flushThread = RegInit(VecInit(Seq.fill(numThreads)(false.B)))

  // Round-robin thread scheduler
  val threadSel = RegInit(0.U(log2Ceil(numThreads).W))
  io.fetchThread := threadSel

  // Single pipeline registers (carry threadId with each instruction)
  val if_id = RegInit(0.U.asTypeOf(new PipelineRegBundle))
  val id_ex = RegInit(0.U.asTypeOf(new PipelineRegBundle))
  val ex_mem = RegInit(0.U.asTypeOf(new PipelineRegBundle))
  val mem_wb = RegInit(0.U.asTypeOf(new PipelineRegBundle))

  // Shared multithreaded register file
  val regFile = Module(new RegFileMT2R1WVec(numThreads = numThreads))

  // Debug mirrors to expose last-seen per-thread stage values
  val debugIfInstr = RegInit(VecInit(Seq.fill(numThreads)(0.U(32.W))))
  val debugIdRs1 = RegInit(VecInit(Seq.fill(numThreads)(0.U(32.W))))
  val debugIdRs2 = RegInit(VecInit(Seq.fill(numThreads)(0.U(32.W))))
  val debugExAlu = RegInit(VecInit(Seq.fill(numThreads)(0.U(32.W))))
  val debugMemLoad = RegInit(VecInit(Seq.fill(numThreads)(0.U(32.W))))

  // Default IO outputs
  io.memAddr := 0.U
  io.memWrite := 0.U
  io.memMask := 0.U
  io.memValid := false.B
  io.memMisaligned := false.B

  // ===================== Instruction Fetch (IF) =====================
  val currentThread = threadSel
  val flushThisThread = flushThread(currentThread)
  val threadEnabled = io.threadEnable(currentThread)
  val currentPC = pcRegs(currentThread)

  // Instruction cache instance (default config: 2KB, 16B block, direct-mapped)
  val icache = Module(new ICache(new ICacheConfig(2*1024, 16, 1)))
  icache.io.pc := currentPC
  icache.io.pc_valid := !flushThisThread && threadEnabled
  // Wire combinational instruction memory into cache memory port for now
  icache.io.mem_rdata := io.instrMem
  icache.io.mem_rvalid := true.B

  if_id.threadId := currentThread
  if_id.pc := currentPC
  // Prefer cache-provided instruction when valid, otherwise fall back to external combinational input
  if_id.instr := Mux(icache.io.instr_valid, icache.io.instr, io.instrMem)
  if_id.rs1 := if_id.instr(19, 15)
  if_id.rs2 := if_id.instr(24, 20)
  if_id.rd := if_id.instr(11, 7)
  // Stall fetch/advance when the ICache is busy
  if_id.valid := !flushThisThread && threadEnabled && !icache.io.stall

  when(if_id.valid) {
    debugIfInstr(currentThread) := if_id.instr
  }

  // Advance round-robin selector
  when(reset.asBool) {
    threadSel := 0.U
  }.otherwise {
    // Do not advance thread selection while icache is stalling/filling
    when(!icache.io.stall) {
      threadSel := Mux(threadSel === (numThreads - 1).U, 0.U, threadSel + 1.U)
    }
  }

  // ===================== Instruction Decode (ID) with Forwarding =====================
  val decodeSignals = RV32IDecode.decodeInstr(if_id.instr)
  val rs1 = if_id.rs1
  val rs2 = if_id.rs2

  id_ex.pc := if_id.pc
  id_ex.instr := if_id.instr
  id_ex.threadId := if_id.threadId
  id_ex.valid := if_id.valid && !flushThread(if_id.threadId)
  id_ex.rs1 := rs1
  id_ex.rs2 := rs2
  id_ex.rd := if_id.rd
  id_ex.imm := decodeSignals.imm
  id_ex.aluOp := decodeSignals.aluOp
  id_ex.isALU := decodeSignals.isALU
  id_ex.isLoad := decodeSignals.isLoad
  id_ex.isStore := decodeSignals.isStore
  id_ex.isBranch := decodeSignals.isBranch
  id_ex.isJAL := decodeSignals.isJAL
  id_ex.isJALR := decodeSignals.isJALR
  id_ex.isLUI := decodeSignals.isLUI
  id_ex.isAUIPC := decodeSignals.isAUIPC
  // If this thread is disabled, squash the decode output
  when(!io.threadEnable(if_id.threadId)) {
    id_ex.valid := false.B
  }

  // Register file reads are tagged by threadId
  regFile.io.readThreadID := if_id.threadId
  regFile.io.writeThreadID := mem_wb.threadId
  regFile.io.src1 := rs1
  regFile.io.src2 := rs2

  val rs1Raw = regFile.io.src1data
  val rs2Raw = regFile.io.src2data

  // Simple forwarding when the same thread is in later stages
  val rs1Fwd = WireDefault(rs1Raw)
  val rs2Fwd = WireDefault(rs2Raw)

  when(ex_mem.valid && ex_mem.threadId === if_id.threadId && ex_mem.rd =/= 0.U && ex_mem.rd === rs1) {
    rs1Fwd := ex_mem.aluResult
  }.elsewhen(mem_wb.valid && mem_wb.threadId === if_id.threadId && mem_wb.rd =/= 0.U && mem_wb.rd === rs1) {
    rs1Fwd := Mux(mem_wb.isLoad, mem_wb.memRdata, mem_wb.aluResult)
  }

  when(ex_mem.valid && ex_mem.threadId === if_id.threadId && ex_mem.rd =/= 0.U && ex_mem.rd === rs2) {
    rs2Fwd := ex_mem.aluResult
  }.elsewhen(mem_wb.valid && mem_wb.threadId === if_id.threadId && mem_wb.rd =/= 0.U && mem_wb.rd === rs2) {
    rs2Fwd := Mux(mem_wb.isLoad, mem_wb.memRdata, mem_wb.aluResult)
  }

  id_ex.rs1Data := rs1Fwd
  id_ex.rs2Data := rs2Fwd

  when(id_ex.valid) {
    debugIdRs1(id_ex.threadId) := rs1Fwd
    debugIdRs2(id_ex.threadId) := rs2Fwd
  }

  // ===================== Execute (EX) Stage =====================
  val alu = Module(new ALU32)
  val instr = id_ex.instr
  val opcode = instr(6, 0)
  val operandA = WireDefault(id_ex.rs1Data)
  val operandB = WireDefault(id_ex.rs2Data)

  when(opcode === RV32IDecode.OP_I || opcode === RV32IDecode.LOAD || opcode === RV32IDecode.STORE || opcode === RV32IDecode.JALR) {
    operandB := id_ex.imm
  }
  when(opcode === RV32IDecode.LOAD || opcode === RV32IDecode.STORE || opcode === RV32IDecode.JALR) {
    operandA := id_ex.rs1Data
  }
  when(opcode === RV32IDecode.LUI) {
    operandA := 0.U
    operandB := id_ex.imm
  }
  when(opcode === RV32IDecode.AUIPC) {
    operandA := id_ex.pc
    operandB := id_ex.imm
  }

  alu.io.a := operandA
  alu.io.b := operandB
  alu.io.opcode := id_ex.aluOp

  ex_mem.aluResult := alu.io.result
  ex_mem.instr := id_ex.instr
  ex_mem.threadId := id_ex.threadId
  ex_mem.rd := id_ex.rd
  ex_mem.isALU := id_ex.isALU
  ex_mem.isLoad := id_ex.isLoad
  ex_mem.isStore := id_ex.isStore
  ex_mem.isBranch := id_ex.isBranch
  ex_mem.isJAL := id_ex.isJAL
  ex_mem.isJALR := id_ex.isJALR
  ex_mem.isLUI := id_ex.isLUI
  ex_mem.isAUIPC := id_ex.isAUIPC
  ex_mem.valid := id_ex.valid
  ex_mem.rs1Data := id_ex.rs1Data
  ex_mem.rs2Data := id_ex.rs2Data
  ex_mem.pc := id_ex.pc
  ex_mem.imm := id_ex.imm

  when(ex_mem.valid) {
    debugExAlu(ex_mem.threadId) := ex_mem.aluResult
  }

  // ===================== Memory (MEM) Stage =====================
  val loadUnit = Module(new LoadUnit)
  loadUnit.io.addr := ex_mem.aluResult
  loadUnit.io.dataIn := io.dataMemResp
  loadUnit.io.funct3 := ex_mem.instr(14, 12)
  val loadData = loadUnit.io.dataOut

  val storeUnit = Module(new StoreUnit)
  storeUnit.io.addr := ex_mem.aluResult
  storeUnit.io.data := ex_mem.rs2Data
  storeUnit.io.storeType := ex_mem.instr(14, 12)

  // Shared memory interface driven by the single current MEM stage
  val memStoreActive = ex_mem.valid && ex_mem.isStore && io.threadEnable(ex_mem.threadId) && !storeUnit.io.misaligned
  val addrBase = Cat(ex_mem.aluResult(31, 2), 0.U(2.W))
  // Arbitration: allow icache to drive memory address while it is stalling (performing fills)
  io.memAddr := Mux(icache.io.stall, icache.io.mem_addr, addrBase)
  io.memWrite := Mux(memStoreActive, storeUnit.io.memWrite, 0.U)
  io.memMask := Mux(memStoreActive, storeUnit.io.mask, 0.U)
  val memLoadActive = ex_mem.valid && ex_mem.isLoad && io.threadEnable(ex_mem.threadId)
  io.memValid := memLoadActive || memStoreActive
  io.memMisaligned := ex_mem.valid && io.threadEnable(ex_mem.threadId) && storeUnit.io.misaligned

  mem_wb.aluResult := ex_mem.aluResult
  mem_wb.memRdata := loadData
  mem_wb.instr := ex_mem.instr
  mem_wb.threadId := ex_mem.threadId
  mem_wb.rd := ex_mem.rd
  mem_wb.isALU := ex_mem.isALU
  mem_wb.isLoad := ex_mem.isLoad
  mem_wb.isStore := ex_mem.isStore
  mem_wb.isBranch := ex_mem.isBranch
  mem_wb.isJAL := ex_mem.isJAL
  mem_wb.isJALR := ex_mem.isJALR
  mem_wb.isLUI := ex_mem.isLUI
  mem_wb.isAUIPC := ex_mem.isAUIPC
  mem_wb.valid := ex_mem.valid && io.threadEnable(ex_mem.threadId)
  mem_wb.pc := ex_mem.pc
  mem_wb.imm := ex_mem.imm
  mem_wb.rs1Data := ex_mem.rs1Data
  mem_wb.rs2Data := ex_mem.rs2Data

  when(mem_wb.valid) {
    debugMemLoad(mem_wb.threadId) := mem_wb.memRdata
  }

  // ===================== Writeback (WB) Stage =====================
  val pcPlus4 = mem_wb.pc + 4.U
  val auipcValue = mem_wb.pc + mem_wb.imm
  val wbData = Wire(UInt(32.W))
  wbData := mem_wb.aluResult
  when(mem_wb.isLoad) {
    wbData := mem_wb.memRdata
  }.elsewhen(mem_wb.isLUI) {
    wbData := mem_wb.imm
  }.elsewhen(mem_wb.isAUIPC) {
    wbData := auipcValue
  }.elsewhen(mem_wb.isJAL || mem_wb.isJALR) {
    wbData := pcPlus4
  }

  val writeEnable = mem_wb.valid && mem_wb.rd =/= 0.U &&
    io.threadEnable(mem_wb.threadId) &&
    (mem_wb.isALU || mem_wb.isLoad || mem_wb.isLUI ||
      mem_wb.isAUIPC || mem_wb.isJAL || mem_wb.isJALR)

  regFile.io.wen := writeEnable
  regFile.io.dst1 := Mux(writeEnable, mem_wb.rd, 0.U)
  regFile.io.dst1data := wbData

  // Writes and reads are tagged with the WB thread ID
  val wbThread = mem_wb.threadId

  // ===================== PC Update & Control =====================
  val rs1Val = mem_wb.rs1Data
  val rs2Val = mem_wb.rs2Data
  val funct3 = mem_wb.instr(14, 12)

  // Early branch/JAL/JALR resolution at EX to avoid retiring fall-through work
  val branchCondEx = WireDefault(false.B)
  switch(id_ex.instr(14, 12)) {
    is("b000".U) { branchCondEx := id_ex.rs1Data === id_ex.rs2Data }
    is("b001".U) { branchCondEx := id_ex.rs1Data =/= id_ex.rs2Data }
    is("b100".U) { branchCondEx := id_ex.rs1Data.asSInt < id_ex.rs2Data.asSInt }
    is("b101".U) { branchCondEx := !(id_ex.rs1Data.asSInt < id_ex.rs2Data.asSInt) }
    is("b110".U) { branchCondEx := id_ex.rs1Data < id_ex.rs2Data }
    is("b111".U) { branchCondEx := !(id_ex.rs1Data < id_ex.rs2Data) }
  }
  val branchTakenEx = id_ex.valid && id_ex.isBranch && branchCondEx
  val branchTargetEx = (id_ex.pc.asSInt + (id_ex.imm.asSInt << 1)).asUInt
  val jalTakenEx = id_ex.valid && id_ex.isJAL
  val jalrTakenEx = id_ex.valid && id_ex.isJALR
  val jalTargetEx = (id_ex.pc.asSInt + id_ex.imm.asSInt).asUInt
  val jalrTargetEx = ((id_ex.rs1Data.asSInt + id_ex.imm.asSInt).asUInt & ~1.U(32.W))

  // Drive debug/control visibility outputs
  io.ctrlTaken := branchTakenEx || jalTakenEx || jalrTakenEx
  io.ctrlThread := id_ex.threadId
  io.ctrlFromPC := id_ex.pc
  io.ctrlTarget := Mux(branchTakenEx, branchTargetEx, Mux(jalTakenEx, jalTargetEx, jalrTargetEx))
  io.ctrlIsBranch := branchTakenEx
  io.ctrlIsJal := jalTakenEx
  io.ctrlIsJalr := jalrTakenEx

  // Branches/JAL/JALR are resolved in EX; WB branchTaken is unused
  val branchTaken = false.B

  when(branchTakenEx && io.threadEnable(id_ex.threadId)) {
    pcRegs(id_ex.threadId) := branchTargetEx
    flushThread(id_ex.threadId) := true.B
  }.elsewhen(jalTakenEx && io.threadEnable(id_ex.threadId)) {
    pcRegs(id_ex.threadId) := jalTargetEx
    flushThread(id_ex.threadId) := true.B
  }.elsewhen(jalrTakenEx && io.threadEnable(id_ex.threadId)) {
    pcRegs(id_ex.threadId) := jalrTargetEx
    flushThread(id_ex.threadId) := true.B
  }.elsewhen(mem_wb.valid) {
    flushThread(wbThread) := false.B
  }

  // Flush younger in-flight instructions from the taken-control-transfer thread so fall-through work is discarded.
  // Only IF/ID need clearing; older stages must be preserved to retire results.
  when((branchTakenEx || jalTakenEx || jalrTakenEx) && io.threadEnable(id_ex.threadId)) {
    when(if_id.threadId === id_ex.threadId) { if_id.valid := false.B }
  }

  // Default sequential advance for the currently fetched thread unless a control transfer just wrote it.
  when(!reset.asBool && !flushThisThread && threadEnabled) {
    when(!icache.io.stall) {
      when(!(branchTakenEx && id_ex.threadId === currentThread) &&
           !(jalTakenEx && id_ex.threadId === currentThread) &&
           !(jalrTakenEx && id_ex.threadId === currentThread)) {
        pcRegs(currentThread) := currentPC + 4.U
      }
      flushThread(currentThread) := false.B
    }
  }.elsewhen(!reset.asBool && flushThisThread && threadEnabled) {
    // Clear one-shot flush after it has been observed at fetch when no new branch update happens.
    when(!(branchTakenEx && id_ex.threadId === currentThread) &&
         !(jalTakenEx && id_ex.threadId === currentThread) &&
         !(jalrTakenEx && id_ex.threadId === currentThread)) {
      flushThread(currentThread) := false.B
    }
  }

  // Commit next-state values
  when(reset.asBool) {
    pcRegs := pcResetVec
  }
  when(reset.asBool) {
    flushThread := flushResetVec
  }

  // Hold disabled threads in place and clear any pending flush for them.
  // For disabled threads, hold PC and clear any pending flush so no state toggles.
  for (t <- 0 until numThreads) {
    when(!io.threadEnable(t)) {
      pcRegs(t) := pcRegs(t)
      flushThread(t) := false.B
    }
  }

  // ===================== Expose Pipeline State =====================
  io.if_pc := pcRegs
  io.if_instr := debugIfInstr
  io.id_rs1Data := debugIdRs1
  io.id_rs2Data := debugIdRs2
  io.ex_aluResult := debugExAlu
  io.mem_loadData := debugMemLoad
  // Default debug outputs when no control transfer
  when(!io.ctrlTaken) {
    io.ctrlThread := 0.U
    io.ctrlFromPC := 0.U
    io.ctrlTarget := 0.U
  }
}
