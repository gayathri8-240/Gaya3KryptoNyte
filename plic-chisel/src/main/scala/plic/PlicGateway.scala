package plic

import chisel3._
import chisel3.util._

class PlicGatewayIO(countBits: Int) extends Bundle {
  val rst_n = Input(Bool())
  val src = Input(Bool())
  val edge_lvl = Input(Bool())
  val ip = Output(Bool())
  val claim = Input(Bool())
  val complete = Input(Bool())
}

class PlicGateway(val maxPendingCount: Int = 16) extends Module {
  val countBits = if (maxPendingCount >= 0) log2Ceil(maxPendingCount + 1) else 1
  val io = IO(new PlicGatewayIO(countBits))

  val asyncReset = (!io.rst_n).asAsyncReset

  val (src_dly, src_edge, pending_cnt, decr_pending, ip_state) = withReset(asyncReset) {
    val sd = RegInit(false.B)
    val se = RegInit(false.B)
    val pc = RegInit(0.U(countBits.W))
    val dp = RegInit(false.B)
    val sIdle :: sPending :: sClaimed :: Nil = Enum(3)
    val st = RegInit(sIdle)
    (sd, se, pc, dp, st)
  }

  val nxt_pending_cnt = Wire(UInt(countBits.W))

  // edge detect (synchronous)
  src_dly := io.src
  src_edge := io.src && !src_dly

  // next pending counter logic (combinational)
  when(decr_pending && !src_edge) {
    when(pending_cnt > 0.U) { nxt_pending_cnt := pending_cnt - 1.U }
    .otherwise { nxt_pending_cnt := pending_cnt }
  } .elsewhen(!decr_pending && src_edge) {
    when(pending_cnt < maxPendingCount.U) { nxt_pending_cnt := pending_cnt + 1.U }
    .otherwise { nxt_pending_cnt := pending_cnt }
  } .otherwise {
    nxt_pending_cnt := pending_cnt
  }

  when(!io.edge_lvl) {
    pending_cnt := 0.U
  } .otherwise {
    pending_cnt := nxt_pending_cnt
  }

  // ip FSM
  decr_pending := false.B
  switch(ip_state) {
    is(0.U) {
      when((io.edge_lvl && (nxt_pending_cnt =/= 0.U)) || (!io.edge_lvl && io.src)) {
        ip_state := 1.U
        decr_pending := true.B
      }
    }
    is(1.U) {
      when(io.claim) { ip_state := 2.U }
    }
    is(2.U) {
      when(io.complete) { ip_state := 0.U }
    }
  }

  io.ip := ip_state === 1.U
}
