package plic

import chisel3._
import chisel3.util._

class PlicCoreIO(val sources: Int, val targets: Int, val priorities: Int) extends Bundle {
  val rst_n = Input(Bool())
  val src = Input(Vec(sources, Bool()))
  val el = Input(Vec(sources, Bool()))
  val ip = Output(Vec(sources, Bool()))

  val ie = Input(Vec(targets, Vec(sources, Bool())))
  val ipriority = Input(Vec(sources, UInt(log2Ceil(priorities).W)))
  val threshold = Input(Vec(targets, UInt(log2Ceil(priorities).W)))

  val ireq = Output(Vec(targets, Bool()))
  val id = Output(Vec(targets, UInt(log2Ceil(sources + 1).W)))

  val claim = Input(Vec(targets, Bool()))
  val complete = Input(Vec(targets, Bool()))
}

class PlicCore(val sources: Int = 8, val targets: Int = 1, val priorities: Int = 8, val maxPendingCount: Int = 16) extends Module {
  val io = IO(new PlicCoreIO(sources, targets, priorities))
  val asyncReset = (!io.rst_n).asAsyncReset

  // arrays for id and priority per (target, source)
  val id_array = Seq.fill(targets)(Seq.fill(sources)(Wire(UInt(log2Ceil(sources + 1).W))))
  val pr_array = Seq.fill(targets)(Seq.fill(sources)(Wire(UInt(log2Ceil(priorities).W))))

  // claimed id per target
  val id_claimed = withReset(asyncReset) { RegInit(VecInit(Seq.fill(targets)(0.U(log2Ceil(sources + 1).W)))) }

  // claim/complete arrays per source -> per target
  val claim_array = Seq.fill(sources)(Wire(Vec(targets, Bool())))
  val complete_array = Seq.fill(sources)(Wire(Vec(targets, Bool())))

  // create gateways per source
  val gateways = Seq.fill(sources)(Module(new PlicGateway(maxPendingCount)))
  for (s <- 0.until(sources)) {
    gateways(s).io.rst_n := io.rst_n
    gateways(s).io.src := io.src(s)
    gateways(s).io.edge_lvl := io.el(s)
  }

  // instantiate cells and build id/pr arrays
  for (t <- 0.until(targets)) {
    for (s <- 0.until(sources)) {
      val cell = Module(new PlicCell(id = s + 1, sources = sources, priorities = priorities))
      cell.io.rst_n := io.rst_n
      cell.io.ip := gateways(s).io.ip
      cell.io.ie := io.ie(t)(s)
      cell.io.priority := io.ipriority(s)
      id_array(t)(s) := cell.io.id
      pr_array(t)(s) := cell.io.priorityOut
    }
  }

  // id claimed register per target
  for (t <- 0.until(targets)) {
    when(io.claim(t)) {
      id_claimed(t) := io.id(t)
    }
  }

  // build claim/complete arrays per source
  for (s <- 0.until(sources)) {
    for (t <- 0.until(targets)) {
      claim_array(s)(t) := (io.id(t) === (s + 1).U) && io.claim(t)
      complete_array(s)(t) := (id_claimed(t) === (s + 1).U) && io.complete(t)
    }
  }

  // connect gateway claim/complete (OR across targets)
  for (s <- 0.until(sources)) {
    gateways(s).io.claim := claim_array(s).asUInt.orR
    gateways(s).io.complete := complete_array(s).asUInt.orR
    io.ip(s) := gateways(s).io.ip
  }

  // instantiate targets
  for (t <- 0.until(targets)) {
    val tgt = Module(new PlicTarget(sources, priorities))
    tgt.io.rst_n := io.rst_n
    // connect id/pr arrays
    for (s <- 0.until(sources)) {
      tgt.io.id_i(s) := id_array(t)(s)
      tgt.io.priority_i(s) := pr_array(t)(s)
    }
    tgt.io.threshold_i := io.threshold(t)
    io.ireq(t) := tgt.io.ireq_o
    io.id(t) := tgt.io.id_o
  }
}
