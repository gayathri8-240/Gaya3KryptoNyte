package Pipeline

import chisel3._
import chisel3.util._

/** Minimal slot description for dispatch filtering. */
class DispatchSlot extends Bundle {
  val valid    = Bool()
  val rs1      = UInt(5.W)
  val rs2      = UInt(5.W)
  val rd       = UInt(5.W)
  val isALU    = Bool()
  val isLoad   = Bool()
  val isStore  = Bool()
  val isBranch = Bool()
  val isJAL    = Bool()
  val isJALR   = Bool()
  val isLUI    = Bool()
  val isAUIPC  = Bool()
}

/** Dispatch unit that enforces simple structural caps and RAW/WAW hazards. */
class DispatchUnit(issueWidth: Int, maxALU: Int = 2, maxLoad: Int = 1, maxStore: Int = 1, maxBranch: Int = 1)
    extends Module {
  val io = IO(new Bundle {
    val threadEnable = Input(Bool())
    val flushThread  = Input(Bool())
    val inFlightBusy = Input(Vec(32, Bool())) // per-dst register busy for this thread
    val inSlots      = Input(Vec(issueWidth, new DispatchSlot))
    val outSlots     = Output(Vec(issueWidth, new DispatchSlot))
    val issueMask    = Output(Vec(issueWidth, Bool()))
    val issuedCount  = Output(UInt(log2Ceil(issueWidth + 1).W))
  })

  val usedRdState = Wire(Vec(issueWidth + 1, Vec(32, Bool())))
  usedRdState(0) := VecInit(Seq.fill(32)(false.B))
  val aluCount  = Wire(Vec(issueWidth + 1, UInt(log2Ceil(maxALU + 1).W)))
  val loadUsed  = Wire(Vec(issueWidth + 1, Bool()))
  val storeUsed = Wire(Vec(issueWidth + 1, Bool()))
  val brUsed    = Wire(Vec(issueWidth + 1, Bool()))

  aluCount(0) := 0.U
  loadUsed(0) := false.B
  storeUsed(0) := false.B
  brUsed(0) := false.B

  val issueMask = Wire(Vec(issueWidth, Bool()))
  val outSlots  = Wire(Vec(issueWidth, new DispatchSlot))
  issueMask := VecInit(Seq.fill(issueWidth)(false.B))
  for (i <- 0 until issueWidth) { outSlots(i) := io.inSlots(i) ; outSlots(i).valid := false.B }

  val issuingEnabled = Wire(Vec(issueWidth + 1, Bool()))
  issuingEnabled(0) := io.threadEnable && !io.flushThread

  for (i <- 0 until issueWidth) {
    val in = io.inSlots(i)
    val canConsider = issuingEnabled(i) && in.valid

    val structOk = Mux(in.isLoad,  loadUsed(i) === false.B && maxLoad.U =/= 0.U,
                  Mux(in.isStore, storeUsed(i) === false.B && maxStore.U =/= 0.U,
                  Mux(in.isBranch || in.isJAL || in.isJALR, brUsed(i) === false.B && maxBranch.U =/= 0.U,
                  Mux(in.isALU || in.isLUI || in.isAUIPC, aluCount(i) < maxALU.U, true.B))))

    val rawHaz = (in.rs1 =/= 0.U && (usedRdState(i)(in.rs1) || io.inFlightBusy(in.rs1))) ||
                 (in.rs2 =/= 0.U && (usedRdState(i)(in.rs2) || io.inFlightBusy(in.rs2)))
    val wawHaz = in.rd =/= 0.U && (usedRdState(i)(in.rd) || io.inFlightBusy(in.rd))

    val nextUsed = Wire(Vec(32, Bool()))
    nextUsed := usedRdState(i)
    when(in.rd =/= 0.U) { nextUsed(in.rd) := true.B }

    when(canConsider && structOk && !rawHaz && !wawHaz) {
      outSlots(i) := in
      outSlots(i).valid := true.B
      issueMask(i) := true.B
      usedRdState(i + 1) := nextUsed
      aluCount(i + 1) := aluCount(i) + Mux(in.isALU || in.isLUI || in.isAUIPC || in.isLoad || in.isStore, 1.U, 0.U)
      loadUsed(i + 1) := loadUsed(i) || in.isLoad
      storeUsed(i + 1) := storeUsed(i) || in.isStore
      brUsed(i + 1) := brUsed(i) || in.isBranch || in.isJAL || in.isJALR
      issuingEnabled(i + 1) := true.B
    }.otherwise {
      usedRdState(i + 1) := usedRdState(i)
      aluCount(i + 1) := aluCount(i)
      loadUsed(i + 1) := loadUsed(i)
      storeUsed(i + 1) := storeUsed(i)
      brUsed(i + 1) := brUsed(i)
      issuingEnabled(i + 1) := false.B // stop further issue to maintain in-order
    }
  }

  io.outSlots := outSlots
  io.issueMask := issueMask
  io.issuedCount := PopCount(issueMask)
}

/** Writeback unit that limits concurrent writes. */
class WritebackSlot(threadBits: Int) extends Bundle {
  val valid     = Bool()
  val rd        = UInt(5.W)
  val data      = UInt(32.W)
  val threadId  = UInt(threadBits.W)
  val writeEn   = Bool() // computed earlier (e.g., isALU/isLoad/etc.)
}

class WritebackUnit(threadBits: Int, issueWidth: Int, maxWrites: Int = 2) extends Module {
  val io = IO(new Bundle {
    val threadEnable = Input(Vec(issueWidth, Bool()))
    val inSlots      = Input(Vec(issueWidth, new WritebackSlot(threadBits)))
    val wen          = Output(Vec(issueWidth, Bool()))
    val dst          = Output(Vec(issueWidth, UInt(5.W)))
    val data         = Output(Vec(issueWidth, UInt(32.W)))
    val threadId     = Output(Vec(issueWidth, UInt(threadBits.W)))
  })

  val writeCount = Wire(Vec(issueWidth + 1, UInt(log2Ceil(maxWrites + 1).W)))
  writeCount(0) := 0.U
  for (i <- 0 until issueWidth) {
    val s = io.inSlots(i)
    val allow = s.valid && s.writeEn && s.rd =/= 0.U && io.threadEnable(i) && (writeCount(i) < maxWrites.U)
    io.wen(i) := allow
    io.dst(i) := s.rd
    io.data(i) := s.data
    io.threadId(i) := s.threadId
    writeCount(i + 1) := writeCount(i) + Mux(allow, 1.U, 0.U)
  }
}
