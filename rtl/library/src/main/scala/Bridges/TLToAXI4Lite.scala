package Bridges

import chisel3._
import chisel3.util._
import TileLink._
import AXI4._

/** TileLink-UL to AXI4-Lite bridge (single outstanding transaction). */
class TLToAXI4Lite(tlParams: TLParams = TLParams(), axiParams: AXI4LiteParams = AXI4LiteParams()) extends Module {
  require(tlParams.dataBits == axiParams.dataBits, "TL and AXI data widths must match for this bridge")
  val io = IO(new Bundle {
    val tl  = Flipped(new TLBundleUL(tlParams))
    val axi = new AXI4LiteIO(axiParams)
  })

  val sIdle :: sWrite :: sWriteResp :: sReadAddr :: sReadResp :: Nil = Enum(5)
  val state = RegInit(sIdle)

  val aReg = RegInit(0.U.asTypeOf(new TLBundleA(tlParams)))
  val dReg = RegInit(0.U.asTypeOf(new TLBundleD(tlParams)))
  val dValid = RegInit(false.B)

  val awSent = RegInit(false.B)
  val wSent = RegInit(false.B)

  // Default AXI signals
  io.axi.aw.valid := false.B
  io.axi.aw.bits.addr := aReg.address
  io.axi.aw.bits.prot := 0.U
  io.axi.w.valid := false.B
  io.axi.w.bits.data := aReg.data
  io.axi.w.bits.strb := aReg.mask
  io.axi.ar.valid := false.B
  io.axi.ar.bits.addr := aReg.address
  io.axi.ar.bits.prot := 0.U
  io.axi.b.ready := state === sWriteResp
  io.axi.r.ready := state === sReadResp

  // TL defaults
  io.tl.a.ready := state === sIdle
  io.tl.d.valid := dValid
  io.tl.d.bits := dReg

  def startResponse(opcode: UInt, data: UInt): Unit = {
    dReg.opcode := opcode
    dReg.param := 0.U
    dReg.size := aReg.size
    dReg.source := aReg.source
    dReg.denied := false.B
    dReg.data := data
    dReg.corrupt := false.B
    dValid := true.B
  }

  when(state === sIdle) {
    awSent := false.B
    wSent := false.B
    when(io.tl.a.fire) {
      aReg := io.tl.a.bits
      when(io.tl.a.bits.opcode === TLOpcodesA.Get) {
        state := sReadAddr
      }.otherwise {
        state := sWrite
      }
    }
  }

  when(state === sWrite) {
    io.axi.aw.valid := !awSent
    io.axi.w.valid := !wSent
    when(io.axi.aw.fire) { awSent := true.B }
    when(io.axi.w.fire) { wSent := true.B }
    when(awSent && wSent) { state := sWriteResp }
  }

  when(state === sWriteResp) {
    when(io.axi.b.fire) {
      startResponse(TLOpcodesD.AccessAck, 0.U)
      state := sIdle
    }
  }

  when(state === sReadAddr) {
    io.axi.ar.valid := true.B
    when(io.axi.ar.fire) {
      state := sReadResp
    }
  }

  when(state === sReadResp) {
    when(io.axi.r.fire) {
      startResponse(TLOpcodesD.AccessAckData, io.axi.r.bits.data)
      state := sIdle
    }
  }

  when(dValid && io.tl.d.ready) {
    dValid := false.B
  }
}
