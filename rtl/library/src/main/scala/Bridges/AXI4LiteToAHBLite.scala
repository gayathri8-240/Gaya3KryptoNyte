package Bridges

import chisel3._
import chisel3.util._
import AXI4._
import AHB._

/** AXI4-Lite to AHB-Lite bridge (single outstanding transaction). */
class AXI4LiteToAHBLite(axiParams: AXI4LiteParams = AXI4LiteParams(),
                        ahbParams: AHBLiteParams = AHBLiteParams()) extends Module {
  require(axiParams.dataBits == ahbParams.dataBits, "AXI and AHB data widths must match")
  val io = IO(new Bundle {
    val axi = Flipped(new AXI4LiteIO(axiParams))
    val ahb = new AHBLiteIO(ahbParams)
  })

  val sIdle :: sAhbWrite :: sWriteResp :: sAhbRead :: sReadResp :: Nil = Enum(5)
  val state = RegInit(sIdle)

  val awReg = RegInit(0.U.asTypeOf(new AXI4LiteAW(axiParams)))
  val wReg  = RegInit(0.U.asTypeOf(new AXI4LiteW(axiParams)))
  val arReg = RegInit(0.U.asTypeOf(new AXI4LiteAR(axiParams)))

  val awLatched = RegInit(false.B)
  val wLatched = RegInit(false.B)

  // AXI defaults
  io.axi.aw.ready := state === sIdle && !awLatched
  io.axi.w.ready := state === sIdle && !wLatched
  io.axi.b.valid := state === sWriteResp
  io.axi.b.bits.resp := AXI4LiteResp.OKAY
  io.axi.ar.ready := state === sIdle && !awLatched && !wLatched
  io.axi.r.valid := state === sReadResp
  io.axi.r.bits.data := io.ahb.hrdata
  io.axi.r.bits.resp := AXI4LiteResp.OKAY

  // AHB defaults
  io.ahb.haddr := 0.U
  io.ahb.hwrite := false.B
  io.ahb.htrans := AHBTrans.IDLE
  io.ahb.hsize := 2.U
  io.ahb.hsel := false.B
  io.ahb.hwdata := 0.U

  val sizeFromStrb = Wire(UInt(3.W))
  sizeFromStrb := 2.U
  switch(wReg.strb) {
    is("b0001".U) { sizeFromStrb := 0.U }
    is("b0010".U) { sizeFromStrb := 0.U }
    is("b0100".U) { sizeFromStrb := 0.U }
    is("b1000".U) { sizeFromStrb := 0.U }
    is("b0011".U) { sizeFromStrb := 1.U }
    is("b1100".U) { sizeFromStrb := 1.U }
    is("b1111".U) { sizeFromStrb := 2.U }
  }

  when(state === sIdle) {
    when(io.axi.aw.fire) {
      awReg := io.axi.aw.bits
      awLatched := true.B
    }
    when(io.axi.w.fire) {
      wReg := io.axi.w.bits
      wLatched := true.B
    }
    when(awLatched && wLatched) {
      state := sAhbWrite
    }.elsewhen(io.axi.ar.fire) {
      arReg := io.axi.ar.bits
      state := sAhbRead
    }
  }

  when(state === sAhbWrite) {
    io.ahb.hsel := true.B
    io.ahb.haddr := awReg.addr
    io.ahb.hwrite := true.B
    io.ahb.htrans := AHBTrans.NONSEQ
    io.ahb.hsize := sizeFromStrb
    io.ahb.hwdata := wReg.data
    when(io.ahb.hready) {
      state := sWriteResp
      awLatched := false.B
      wLatched := false.B
    }
  }

  when(state === sWriteResp) {
    when(io.axi.b.fire) {
      state := sIdle
    }
  }

  when(state === sAhbRead) {
    io.ahb.hsel := true.B
    io.ahb.haddr := arReg.addr
    io.ahb.hwrite := false.B
    io.ahb.htrans := AHBTrans.NONSEQ
    io.ahb.hsize := 2.U
    when(io.ahb.hready) {
      state := sReadResp
    }
  }

  when(state === sReadResp) {
    when(io.axi.r.fire) {
      state := sIdle
    }
  }
}
