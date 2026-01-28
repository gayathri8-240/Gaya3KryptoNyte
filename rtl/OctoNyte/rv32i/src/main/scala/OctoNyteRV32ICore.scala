package OctoNyte

import chisel3._
import chisel3.util._
import chisel3.dontTouch
import ALUs.ALU32
import Decoders.RV32IDecode
import Pipeline.ThreadScheduler
import BranchUnit.BranchUnit
import LoadUnit.LoadUnit
import StoreUnit.StoreUnit
import RegFiles.RegFileMTMultiWVec


// *********************************************************
// Core IO Definition
// *********************************************************
class OctoNyteRV32ICoreIO(val numThreads: Int, val fetchWidth: Int) extends Bundle {
  private val threadBits = log2Ceil(numThreads)

  val threadEnable = Input(Vec(numThreads, Bool()))
  val instrMem     = Input(UInt((fetchWidth * 32).W))
  val dataMemResp  = Input(UInt(32.W))
  val memAddr      = Output(UInt(32.W))
  val memWrite     = Output(UInt(32.W))
  val memMask      = Output(UInt(4.W))
  val memMisaligned= Output(Bool())

  val debugStageThreads = Output(Vec(8, UInt(threadBits.W)))
  val debugStageValids  = Output(Vec(8, Bool()))
  val debugPC           = Output(Vec(numThreads, UInt(32.W)))
  val debugRegs01234    = Output(Vec(numThreads, Vec(5, UInt(32.W))))
  val debugRegX1        = Output(Vec(numThreads, UInt(32.W)))
  val debugCtrlValid    = Output(Bool())
  val debugCtrlInstr    = Output(UInt(32.W))
  val debugCtrlTaken    = Output(Bool())
  val debugCtrlThread   = Output(UInt(threadBits.W))
  val debugCtrlFromPC   = Output(UInt(32.W))
  val debugCtrlTarget   = Output(UInt(32.W))
  val debugCtrlIsBranch = Output(Bool())
  val debugCtrlIsJal    = Output(Bool())
  val debugCtrlIsJalr   = Output(Bool())
  val debugExecValid    = Output(Bool())
  val debugExecThread   = Output(UInt(threadBits.W))
  val debugExecPC       = Output(UInt(32.W))
  val debugExecInstr    = Output(UInt(32.W))
  val debugExecIsBranch = Output(Bool())
  val debugExecIsJal    = Output(Bool())
  val debugExecIsJalr   = Output(Bool())
  val debugExecBranchOp = Output(UInt(3.W))
  val debugExecRs1      = Output(UInt(32.W))
  val debugExecRs2      = Output(UInt(32.W))
  val debugExecCtrlTaken = Output(Bool())
  val debugExecCtrlTarget = Output(UInt(32.W))
}

// ****************************************************************************************
// Pipeline Register Definitions
// Pipeline registers are defined in outer scope so Verilog generation doesn't mangle names
// ****************************************************************************************
class FetchPipelineRegs(threadBits: Int) extends Bundle {
  val valid    = Bool()
  val pc       = UInt(32.W)
  val instr    = UInt(32.W)
}


class DecodePipelineRegs(threadBits: Int) extends Bundle {
  val fetchSignals = new FetchPipelineRegs(threadBits)
  val decodeSignals = new RV32IDecode.DecodeSignals
}

class DispatchPipelineRegs(threadBits: Int) extends Bundle {
  val decodePipelineSignals = new DecodePipelineRegs(threadBits)
  // Additional dispatch-specific signals can be added here when multiple-issue is implemented
}

class RegisterReadPipelineRegs(threadBits: Int) extends Bundle {
  val dispatchSignals = new DispatchPipelineRegs(threadBits)
  val rs1Data  = UInt(32.W)
  val rs2Data  = UInt(32.W) 
}

class Exec1PipelineRegs(threadBits: Int) extends Bundle {
  val regReadSignals = new RegisterReadPipelineRegs(threadBits)
  val result   = UInt(32.W)
  val doRegFileWrite = Bool()
  val ctrlTaken = Bool()
  val ctrlTarget = UInt(32.W)
} 

class Exec2PipelineRegs(threadBits: Int) extends Bundle {
  val exec1Signals = new Exec1PipelineRegs(threadBits)
} 

class Exec3PipelineRegs(threadBits: Int) extends Bundle {
  val exec2Signals = new Exec2PipelineRegs(threadBits)
}

class WritebackPipelineRegs(threadBits: Int) extends Bundle {
  val exec3Signals = new Exec3PipelineRegs(threadBits)
} 

// *********************************************************
// OctoNyte RV32I Core Definition
// *********************************************************
class OctoNyteRV32ICore extends Module {
  val numThreads = 8
  // Keep this aligned with OctoNyte tests, which drive a 4-wide (128b) instruction packet.
  // The core currently only consumes slot 0 (`instrMem(31,0)`), so the extra slots are ignored.
  val fetchWidth = 4
  val regFileReadPorts = 2 * fetchWidth
  val regFileWritePorts = fetchWidth
  val io = IO(new OctoNyteRV32ICoreIO(numThreads, fetchWidth))

  private val threadBits = log2Ceil(numThreads)

  // Default IO outputs 
  io.memAddr := 0.U
  io.memWrite := 0.U
  io.memMask := 0.U
  io.memMisaligned := false.B


  // ******************************************
  // Program counter registers for each thread
  // ******************************************
  val pcRegs = RegInit(VecInit(Seq.fill(numThreads)("h8000_0000".U(32.W))))

  // Debug shadow registers (synthesizable): track architectural x1-x4 per thread on writeback.
  // x0 is always 0 and is not stored.
  val debugRegs1to4 = RegInit(VecInit(Seq.fill(numThreads)(VecInit(Seq.fill(4)(0.U(32.W)))))) // (thread)(reg-1)


  // ***********************************************************************************
  // Multithreaded register file: 1 write port, 2 read groups (only port0 used for now)
  // ***********************************************************************************
  val regFile = Module(new RegFileMTMultiWVec(numThreads = numThreads, numWritePorts = regFileWritePorts, numReadPorts = regFileReadPorts))
  regFile.io.readThreadID := VecInit(Seq.fill(regFileReadPorts)(0.U(threadBits.W)))
  regFile.io.src1 := VecInit(Seq.fill(regFileReadPorts)(0.U(5.W)))
  regFile.io.src2 := VecInit(Seq.fill(regFileReadPorts)(0.U(5.W)))
  regFile.io.writeThreadID := VecInit(Seq.fill(regFileWritePorts)(0.U(threadBits.W)))
  regFile.io.dst := VecInit(Seq.fill(regFileWritePorts)(0.U(5.W)))
  regFile.io.wen := VecInit(Seq.fill(regFileWritePorts)(false.B))
  regFile.io.dstData := VecInit(Seq.fill(regFileWritePorts)(0.U(32.W)))

  val unusedRegDebugX1 = Wire(Vec(numThreads, UInt(32.W)))
  val unusedRegDebugRegs = Wire(Vec(numThreads, Vec(5, UInt(32.W))))
  unusedRegDebugX1 := regFile.io.debugX1
  unusedRegDebugRegs := regFile.io.debugRegs01234
  dontTouch(unusedRegDebugX1)
  dontTouch(unusedRegDebugRegs)

  // ***************************************************************************
  // Execution Units
  // ***************************************************************************
  // ALU 
  val alu = Module(new ALU32)
  alu.io.a := 0.U
  alu.io.b := 0.U
  alu.io.opcode := ALU32.Opcode.ADD

  // Branch Unit
  val branchUnit = Module(new BranchUnit)
  branchUnit.io.rs1 := 0.U    // TODO: This is really rs1data not rs1
  branchUnit.io.rs2 := 0.U    // TODO: This is really rs2data not rs2
  branchUnit.io.pc := 0.U
  branchUnit.io.imm := 0.S(32.W)
  branchUnit.io.branchOp := 0.U
  branchUnit.io.valid := false.B
  val unusedBranchNextPc = Wire(UInt(32.W))
  val unusedBranchMisaligned = Wire(Bool())
  unusedBranchNextPc := branchUnit.io.nextPc
  unusedBranchMisaligned := branchUnit.io.misaligned
  dontTouch(unusedBranchNextPc)
  dontTouch(unusedBranchMisaligned)

  // Load Unit
  val loadUnit = Module(new LoadUnit)
  loadUnit.io.addr := 0.U
  loadUnit.io.dataIn := io.dataMemResp
  loadUnit.io.funct3 := 0.U

  // Store Unit
  val storeUnit = Module(new StoreUnit)
  storeUnit.io.addr := 0.U
  storeUnit.io.data := 0.U
  storeUnit.io.storeType := 0.U


  // =============================
  // Fetch stage
  // =============================

  // Thread scheduler for Fetch stage
  val fetchScheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 0))
  
  //pipeline regs
  val fetchRegs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new FetchPipelineRegs(threadBits)))
    init.valid := false.B
    init.pc    := "h80000000".U
    init.instr := 0.U
    init // return the bundle
  }))

  val fetchThreadSel = fetchScheduler.io.currentThread  // Get current fetch thread

  val fetchEntry = fetchRegs(fetchThreadSel)
  when(io.threadEnable(fetchThreadSel)) {
    val instrWord = io.instrMem(31, 0)
    fetchEntry.valid := true.B
    fetchEntry.pc := pcRegs(fetchThreadSel)
    fetchEntry.instr := instrWord
    // Increment PC for next fetch
    pcRegs(fetchThreadSel) := pcRegs(fetchThreadSel) + 4.U
  }.otherwise {
    fetchEntry.valid := false.B
  }

  // =============================
  // Decode stage
  // =============================

  // Thread scheduler for Decode stage
  val decodeScheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 7))

  // pipeline regs
  val decodeRegs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new DecodePipelineRegs(threadBits)))
    init.fetchSignals := 0.U.asTypeOf(new FetchPipelineRegs(threadBits))
    init.decodeSignals := 0.U.asTypeOf(new RV32IDecode.DecodeSignals)
    init // return the bundle
  })) 


  val decodeThreadSel = decodeScheduler.io.currentThread // Get current decode thread
  val fetchToDecodeEntry = fetchRegs(decodeThreadSel)
  
  when(fetchToDecodeEntry.valid && io.threadEnable(decodeThreadSel)) {
    val decodeEntry = decodeRegs(decodeThreadSel)
    val dec = RV32IDecode.decodeInstr(fetchToDecodeEntry.instr)
    decodeEntry.fetchSignals := fetchToDecodeEntry  // propagate fetch signals
    decodeEntry.decodeSignals := dec
  }

  // =============================
  // Dispatch stage
  // =============================

  // Thread scheduler for Dispatch stage
  val dispatchScheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 6))

  // pipeline regs
  val dispatchRegs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new DispatchPipelineRegs(threadBits)))
    init.decodePipelineSignals := 0.U.asTypeOf(new DecodePipelineRegs(threadBits))
    init // return the bundle
  }))

  val dispatchThreadSel = dispatchScheduler.io.currentThread // Get current dispatch thread
  val decodeToDispatchEntry = decodeRegs(dispatchThreadSel)
  when(decodeToDispatchEntry.fetchSignals.valid && io.threadEnable(dispatchThreadSel)) {
    dispatchRegs(dispatchThreadSel).decodePipelineSignals := decodeToDispatchEntry
  }


  // =============================
  // Register read stage
  // =============================

  // Thread scheduler for Register Read stage
  val regReadScheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 5))

  // pipeline regs
  val regReadRegs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new RegisterReadPipelineRegs(threadBits)))
    init.dispatchSignals := 0.U.asTypeOf(new DispatchPipelineRegs(threadBits))
    init.rs1Data := 0.U
    init.rs2Data := 0.U
    init // return the bundle
  }))

  val regReadThreadSel = regReadScheduler.io.currentThread // Get current register read thread
  val dispatchToRegReadEntry = dispatchRegs(regReadThreadSel)
  when(dispatchToRegReadEntry.decodePipelineSignals.fetchSignals.valid && io.threadEnable(regReadThreadSel)) {
    val regReadEntry = regReadRegs(regReadThreadSel)
    regReadEntry.dispatchSignals := dispatchToRegReadEntry
    // Read register file
    regFile.io.readThreadID(0) := regReadThreadSel
    regFile.io.src1(0) := dispatchToRegReadEntry.decodePipelineSignals.decodeSignals.rs1
    regFile.io.src2(0) := dispatchToRegReadEntry.decodePipelineSignals.decodeSignals.rs2
    regReadEntry.rs1Data := regFile.io.src1data(0)
    regReadEntry.rs2Data := regFile.io.src2data(0)
  } 


  // =============================
  // Execute 1 stage (ALU)
  // =============================

  // Thread scheduler for Execute 1 stage
  val exec1Scheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 4))
  
  // pipeline regs
  val exec1Regs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new Exec1PipelineRegs(threadBits)))
    init.regReadSignals := 0.U.asTypeOf(new RegisterReadPipelineRegs(threadBits))
    init.result := 0.U
    init.doRegFileWrite := false.B
    init // return the bundle
  }))

  
  val exec1ThreadSel = exec1Scheduler.io.currentThread // Get current execute 1 thread
  val regReadToExec1Entry = regReadRegs(exec1ThreadSel)

  val exec1DebugValid = WireDefault(false.B)
  val exec1DebugPC = WireDefault(0.U(32.W))
  val exec1DebugInstr = WireDefault(0.U(32.W))
  val exec1DebugIsBranch = WireDefault(false.B)
  val exec1DebugIsJal = WireDefault(false.B)
  val exec1DebugIsJalr = WireDefault(false.B)
  val exec1DebugBranchOp = WireDefault(0.U(3.W))
  val exec1DebugRs1 = WireDefault(0.U(32.W))
  val exec1DebugRs2 = WireDefault(0.U(32.W))
  val exec1DebugCtrlTaken = WireDefault(false.B)
  val exec1DebugCtrlTarget = WireDefault(0.U(32.W))

  when(regReadToExec1Entry.dispatchSignals.decodePipelineSignals.fetchSignals.valid && io.threadEnable(exec1ThreadSel)) {
    val exec1RegsEntry = exec1Regs(exec1ThreadSel) // propagate pipeline regs
    val decodeSignals = regReadToExec1Entry.dispatchSignals.decodePipelineSignals.decodeSignals
    val fetchSignals = regReadToExec1Entry.dispatchSignals.decodePipelineSignals.fetchSignals
    exec1RegsEntry.regReadSignals := regReadToExec1Entry
    exec1RegsEntry.doRegFileWrite := false.B
    exec1RegsEntry.ctrlTaken := exec1DebugCtrlTaken
    exec1RegsEntry.ctrlTarget := exec1DebugCtrlTarget

    exec1DebugValid := true.B
    exec1DebugPC := fetchSignals.pc
    exec1DebugInstr := fetchSignals.instr
    exec1DebugIsBranch := decodeSignals.isBranch
    exec1DebugIsJal := decodeSignals.isJAL
    exec1DebugIsJalr := decodeSignals.isJALR
    exec1DebugBranchOp := fetchSignals.instr(14, 12)
    exec1DebugRs1 := regReadToExec1Entry.rs1Data
    exec1DebugRs2 := regReadToExec1Entry.rs2Data

    // ALU
    when(decodeSignals.isALU ||
         decodeSignals.isLUI ||
         decodeSignals.isAUIPC) {
      val instr = fetchSignals.instr
      val opcode = instr(6, 0)
      val useImm = (opcode === RV32IDecode.OP_I) || decodeSignals.isLUI || 
        decodeSignals.isAUIPC
      val opA = Mux(decodeSignals.isAUIPC, 
        fetchSignals.pc,
        Mux(decodeSignals.isLUI, 
          0.U, 
          regReadToExec1Entry.rs1Data))
      val opB = Mux(useImm, 
        decodeSignals.imm, 
        regReadToExec1Entry.rs2Data)

      alu.io.a := opA
      alu.io.b := opB
      alu.io.opcode := decodeSignals.aluOp

      val result = Mux(decodeSignals.isAUIPC, 
        fetchSignals.pc + decodeSignals.imm,
        Mux(decodeSignals.isLUI, 
          decodeSignals.imm, 
          alu.io.result))

      exec1RegsEntry.result := result
      exec1RegsEntry.doRegFileWrite := true.B

    // JAL
    } .elsewhen (decodeSignals.isJAL) {
      val pc = fetchSignals.pc
      val imm = decodeSignals.imm
      exec1RegsEntry.result := pc + 4.U
      exec1RegsEntry.doRegFileWrite := true.B
      exec1DebugCtrlTaken := true.B
      exec1DebugCtrlTarget := (pc.asSInt + imm.asSInt).asUInt

    // JALR
    } .elsewhen (decodeSignals.isJALR) {
      val pc = fetchSignals.pc
      val imm = decodeSignals.imm
      val target = ((regReadToExec1Entry.rs1Data.asSInt + imm.asSInt).asUInt & ~1.U(32.W))
      exec1RegsEntry.result := pc + 4.U
      exec1RegsEntry.doRegFileWrite := true.B
      exec1DebugCtrlTaken := true.B
      exec1DebugCtrlTarget := target

    
    // Branch
    } .elsewhen (decodeSignals.isBranch) {
      branchUnit.io.rs1 := regReadToExec1Entry.rs1Data
      branchUnit.io.rs2 := regReadToExec1Entry.rs2Data
      branchUnit.io.pc := fetchSignals.pc
      // Decode stores branch immediates in halfword units; restore byte offset here.
      val branchImm = decodeSignals.imm
      branchUnit.io.imm := (branchImm << 1)(31, 0).asSInt
      branchUnit.io.branchOp := fetchSignals.instr(14, 12)
      branchUnit.io.valid := true.B
      exec1DebugCtrlTaken := branchUnit.io.taken
      exec1DebugCtrlTarget := branchUnit.io.target
      

      // Load
    } .elsewhen (decodeSignals.isLoad) {
      val address = regReadToExec1Entry.rs1Data + decodeSignals.imm
      val alignedAddr = Cat(address(31, 2), 0.U(2.W))
      loadUnit.io.addr := address
      loadUnit.io.funct3 := fetchSignals.instr(14, 12)
      io.memAddr := alignedAddr
      val loadData = loadUnit.io.dataOut
      exec1RegsEntry.result := loadData
      exec1RegsEntry.doRegFileWrite := true.B

      // Store
    } .elsewhen (decodeSignals.isStore) {
      exec1RegsEntry.doRegFileWrite := false.B
      val address = regReadToExec1Entry.rs1Data + decodeSignals.imm
      val alignedAddr = Cat(address(31, 2), 0.U(2.W))
      storeUnit.io.addr := address
      storeUnit.io.data := regReadToExec1Entry.rs2Data
      storeUnit.io.storeType := fetchSignals.instr(13, 12)
      io.memAddr := alignedAddr
      io.memWrite := storeUnit.io.memWrite
      io.memMask := storeUnit.io.mask
      io.memMisaligned := storeUnit.io.misaligned
      

  }} 

  

  // =============================
  // Execute 2 stage (pass-through)
  // =============================

  // Thread scheduler for Execute 2 stage
  val exec2Scheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 3))
  
  // pipeline regs
  val exec2Regs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new Exec2PipelineRegs(threadBits)))
    init.exec1Signals := 0.U.asTypeOf(new Exec1PipelineRegs(threadBits))
    init // return the bundle
  }))

  
  val exec2ThreadSel = exec2Scheduler.io.currentThread // Get current execute 2 thread
  val exec1ToExec2Entry = exec1Regs(exec2ThreadSel)
  when(exec1ToExec2Entry.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid && io.threadEnable(exec2ThreadSel)) {
    exec2Regs(exec2ThreadSel).exec1Signals := exec1ToExec2Entry
  } 


  // =============================
  // Execute 3 stage (pass-through)
  // =============================

  // Thread scheduler for Execute 3 stage
  val exec3Scheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 2))
  // pipeline regs
  val exec3Regs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new Exec3PipelineRegs(threadBits)))
    init.exec2Signals := 0.U.asTypeOf(new Exec2PipelineRegs(threadBits))
    init // return the bundle
  }))

  val exec3ThreadSel = exec3Scheduler.io.currentThread // Get current execute 3 thread
  val exec2ToExec3Entry = exec2Regs(exec3ThreadSel)
  when(exec2ToExec3Entry.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid && io.threadEnable(exec3ThreadSel)) {
    exec3Regs(exec3ThreadSel).exec2Signals := exec2ToExec3Entry
  }



  // =============================
  // Writeback stage
  // =============================

  // Thread scheduler for Writeback stage
  val wbScheduler = Module(new ThreadScheduler(numThreads = numThreads, startingThread = 1))
  // pipeline regs
  val wbRegs = RegInit(VecInit(Seq.fill(numThreads) {
    val init = WireDefault(0.U.asTypeOf(new WritebackPipelineRegs(threadBits)))
    init.exec3Signals := 0.U.asTypeOf(new Exec3PipelineRegs(threadBits))
    init // return the bundle
  }))

  val wbThreadSel = wbScheduler.io.currentThread // Get current writeback thread
  val exec3ToWbEntry = exec3Regs(wbThreadSel)
  val wbValid = exec3ToWbEntry.exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid &&
    io.threadEnable(wbThreadSel)
  val wbRd = exec3ToWbEntry.exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.decodeSignals.rd
  val wbDoWrite = wbValid && exec3ToWbEntry.exec2Signals.exec1Signals.doRegFileWrite && (wbRd =/= 0.U)
  val wbCtrlTaken = wbValid && exec3ToWbEntry.exec2Signals.exec1Signals.ctrlTaken
  when(wbDoWrite) {
    val data = exec3ToWbEntry.exec2Signals.exec1Signals.result
    regFile.io.writeThreadID(0) := wbThreadSel
    regFile.io.dst(0) := wbRd
    regFile.io.wen(0) := true.B
    regFile.io.dstData(0) := data

  }
  when(wbCtrlTaken) {
    pcRegs(wbThreadSel) := exec3ToWbEntry.exec2Signals.exec1Signals.ctrlTarget
  }

  when(wbDoWrite) {
    when(wbRd === 1.U) { debugRegs1to4(wbThreadSel)(0) := exec3ToWbEntry.exec2Signals.exec1Signals.result }
      .elsewhen(wbRd === 2.U) { debugRegs1to4(wbThreadSel)(1) := exec3ToWbEntry.exec2Signals.exec1Signals.result }
      .elsewhen(wbRd === 3.U) { debugRegs1to4(wbThreadSel)(2) := exec3ToWbEntry.exec2Signals.exec1Signals.result }
      .elsewhen(wbRd === 4.U) { debugRegs1to4(wbThreadSel)(3) := exec3ToWbEntry.exec2Signals.exec1Signals.result }
  }

  // -----------------
  // Debug outputs
  // -----------------
  io.debugStageThreads := VecInit(
    fetchThreadSel,
    decodeThreadSel,
    dispatchThreadSel,
    regReadThreadSel,
    exec1ThreadSel,
    exec2ThreadSel,
    exec3ThreadSel,
    wbThreadSel
  )

  io.debugStageValids := VecInit(
    fetchRegs(fetchThreadSel).valid,
    decodeRegs(decodeThreadSel).fetchSignals.valid,
    dispatchRegs(dispatchThreadSel).decodePipelineSignals.fetchSignals.valid,
    regReadRegs(regReadThreadSel).dispatchSignals.decodePipelineSignals.fetchSignals.valid,
    exec1Regs(exec1ThreadSel).regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid,
    exec2Regs(exec2ThreadSel).exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid,
    exec3Regs(exec3ThreadSel).exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.valid,
    wbValid
  )

  io.debugPC := pcRegs

  io.debugRegs01234 := VecInit.tabulate(numThreads) { t =>
    VecInit(
      0.U(32.W),
      debugRegs1to4(t)(0),
      debugRegs1to4(t)(1),
      debugRegs1to4(t)(2),
      debugRegs1to4(t)(3)
    )
  }

  io.debugRegX1 := VecInit.tabulate(numThreads)(t => debugRegs1to4(t)(0))

  val wbDecodeSignals = exec3ToWbEntry.exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.decodeSignals
  io.debugCtrlValid := wbValid
  io.debugCtrlInstr := exec3ToWbEntry.exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.instr
  io.debugCtrlTaken := wbCtrlTaken
  io.debugCtrlThread := wbThreadSel
  io.debugCtrlFromPC := exec3ToWbEntry.exec2Signals.exec1Signals.regReadSignals.dispatchSignals.decodePipelineSignals.fetchSignals.pc
  io.debugCtrlTarget := exec3ToWbEntry.exec2Signals.exec1Signals.ctrlTarget
  io.debugCtrlIsBranch := wbDecodeSignals.isBranch
  io.debugCtrlIsJal := wbDecodeSignals.isJAL
  io.debugCtrlIsJalr := wbDecodeSignals.isJALR

  io.debugExecValid := exec1DebugValid
  io.debugExecThread := exec1ThreadSel
  io.debugExecPC := exec1DebugPC
  io.debugExecInstr := exec1DebugInstr
  io.debugExecIsBranch := exec1DebugIsBranch
  io.debugExecIsJal := exec1DebugIsJal
  io.debugExecIsJalr := exec1DebugIsJalr
  io.debugExecBranchOp := exec1DebugBranchOp
  io.debugExecRs1 := exec1DebugRs1
  io.debugExecRs2 := exec1DebugRs2
  io.debugExecCtrlTaken := exec1DebugCtrlTaken
  io.debugExecCtrlTarget := exec1DebugCtrlTarget
}
