package ZeroNyte

import chisel3._
import chisel3.util._
import Decoders.RV32IDecode
import ALUs.ALU32

class ICacheSimpleConfig(val cacheBytes: Int, val blockBytes: Int, val ways: Int)

class ICacheSimpleIO extends Bundle {
  // CPU side
  val pc        = Input(UInt(32.W))
  val pc_valid  = Input(Bool())   // request new instruction
  val instr     = Output(UInt(32.W))
  val instr_valid = Output(Bool())
  val stall     = Output(Bool())

  // Memory side (same as your imem)
  val mem_addr  = Output(UInt(32.W))
  val mem_rdata = Input(UInt(32.W))
  val mem_rvalid= Input(Bool())
}

class ICacheSimple(cfg: ICacheSimpleConfig) extends Module {
  val io = IO(new ICacheSimpleIO)

  // Derived parameters
  require(cfg.blockBytes >= 4 && (cfg.blockBytes & (cfg.blockBytes - 1)) == 0, "blockBytes must be power of two")
  require(cfg.cacheBytes % (cfg.blockBytes * cfg.ways) == 0, "cacheBytes must be divisible by blockBytes*ways")

  val sets = cfg.cacheBytes / (cfg.blockBytes * cfg.ways)
  val offBits = log2Ceil(cfg.blockBytes)
  val idxBits = if (sets > 1) log2Ceil(sets) else 1   // avoid zero-width
  val tagBits = 32 - offBits - idxBits
  val wordsPerLine = cfg.blockBytes / 4

  // storage
  val data = RegInit(VecInit(Seq.fill(sets)(VecInit(Seq.fill(cfg.ways)(
    VecInit(Seq.fill(wordsPerLine)(0.U(32.W)))
  )))))

  val tagArray = RegInit(VecInit(Seq.fill(sets)(VecInit(Seq.fill(cfg.ways)(0.U(tagBits.W))))))
  val valid    = RegInit(VecInit(Seq.fill(sets)(VecInit(Seq.fill(cfg.ways)(false.B)))))
  val age      = RegInit(VecInit(Seq.fill(sets)(VecInit(Seq.fill(cfg.ways)(0.U(32.W))))))

  val globalTime = RegInit(0.U(32.W))
  globalTime := globalTime + 1.U

  // address decode for the incoming PC
  val blockAddr = io.pc >> offBits
  // idx: if only 1 set, use 0.U as index to avoid dynamic-width Vec warnings
  val idx = if (sets > 1) blockAddr(idxBits - 1, 0) else 0.U
  val tag = blockAddr >> idxBits
  val wordOffset = io.pc(offBits - 1, 2)

  // compute the byte address for the requested word (so combinational mem sees correct address)
  val blockBase = Cat(io.pc(31, offBits), 0.U(offBits.W))
  val wordByteAddr = (blockBase + (wordOffset << 2))(31,0)

  // hit detection
  val hit = Wire(Bool()); hit := false.B
  val hitWay = Wire(UInt(log2Ceil(cfg.ways).W)); hitWay := 0.U
  for (w <- 0 until cfg.ways) {
    when(valid(idx)(w) && tagArray(idx)(w) === tag) {
      hit := true.B
      hitWay := w.U
    }
  }

  // victim selection
  val invalidMask = Wire(Vec(cfg.ways, Bool()))
  for (w <- 0 until cfg.ways) invalidMask(w) := !valid(idx)(w)
  val anyInvalid = invalidMask.asUInt.orR
  val firstInvalid = PriorityEncoder(invalidMask.asUInt)

  val minIdxWire = Wire(UInt(log2Ceil(cfg.ways).W))
  val minAgeWire = Wire(UInt(32.W))
  minIdxWire := 0.U
  // avoid reading age(idx)(0) if ways==0 - ways is >=1 by design
  minAgeWire := age(idx)(0)
  for (w <- 1 until cfg.ways) {
    when(age(idx)(w) < minAgeWire) {
      minAgeWire := age(idx)(w)
      minIdxWire := w.U
    }
  }
  val victim = Mux(anyInvalid, firstInvalid, minIdxWire)

  // FSM
  val sIdle :: sMiss :: sFill :: Nil = Enum(3)
  val state = RegInit(sIdle)
  val fillCnt = RegInit(0.U(log2Ceil(wordsPerLine + 1).W))

  // defaults
  io.instr := 0.U
  io.instr_valid := false.B
  io.stall := (state =/= sIdle)

  // Default mem_addr: drive the wordByteAddr so combinational memory produces proper mem_rdata
  // sFill overrides mem_addr when filling block words.
  io.mem_addr := wordByteAddr

  // Accept/serve requests
  when(state === sIdle && io.pc_valid) {
    when(hit) {
      // immediate hit: return from cache
      io.instr := data(idx)(hitWay)(wordOffset)
      io.instr_valid := true.B
      age(idx)(hitWay) := globalTime
      state := sIdle
    } .elsewhen(io.mem_rvalid) {
      // FAST PATH: memory is combinational and has the requested word now.
      // IMPORTANT CHANGE: install the returned word into data array but DO NOT set valid/tag/age.
      // This prevents incorrectly marking the whole line valid while only one word is present.
      data(idx)(victim)(wordOffset) := io.mem_rdata
      // DO NOT: valid(idx)(victim) := true.B
      // DO NOT: tagArray(idx)(victim) := tag
      // DO NOT: age(idx)(victim) := globalTime

      // Return the instruction immediately to the CPU
      io.instr := io.mem_rdata
      io.instr_valid := true.B

      state := sIdle
    } .otherwise {
      // miss -> start multi-cycle fill
      state := sMiss
      fillCnt := 0.U
    }
  }

  // Multi-cycle path (kept for completeness)
  when(state === sMiss) {
    io.mem_addr := blockBase
    state := sFill
    fillCnt := 0.U
  }

  when(state === sFill) {
    io.mem_addr := (blockBase + (fillCnt << 2))(31,0)
    when(io.mem_rvalid) {
      data(idx)(victim)(fillCnt) := io.mem_rdata
      fillCnt := fillCnt + 1.U
      when(fillCnt === (wordsPerLine - 1).U) {
        // Only mark valid/tag/age after the whole block is filled
        valid(idx)(victim) := true.B
        tagArray(idx)(victim) := tag
        age(idx)(victim) := globalTime

        // respond to CPU using the filled data
        io.instr := data(idx)(victim)(wordOffset)
        io.instr_valid := true.B
        state := sIdle
        fillCnt := 0.U
      }
    }
  }
}