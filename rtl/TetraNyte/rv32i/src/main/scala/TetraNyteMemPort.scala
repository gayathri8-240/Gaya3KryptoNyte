package TetraNyte

import chisel3._
import chisel3.util._
import TileLink._

/** Legacy memory interface bridged to a TileLink-UL master.
  * Keeps the passthrough SRAM-style signals usable while exposing TL for bus attach.
  */
class TetraNyteMemPort(p: TLParams = TLParams()) extends Module {
  require(p.beatBytes == 4, "TetraNyteMemPort assumes a 32-bit data path")
  val io = IO(new Bundle {
    val legacy = new Bundle {
      val valid     = Input(Bool())
      val addr      = Input(UInt(32.W))
      val writeData = Input(UInt(32.W))
      val writeMask = Input(UInt(4.W))
      val readData  = Output(UInt(32.W))
    }

    val passthroughMem = new Bundle {
      val addr      = Output(UInt(32.W))
      val writeData = Output(UInt(32.W))
      val writeMask = Output(UInt(4.W))
      val readData  = Input(UInt(32.W))
    }

    val tl = new TLBundleUL(p)
  })

  // Legacy passthrough wiring
  io.passthroughMem.addr := io.legacy.addr
  io.passthroughMem.writeData := io.legacy.writeData
  io.passthroughMem.writeMask := io.legacy.writeMask

  // Prefer TL D-channel data; hold last response for observation after the beat.
  val hasD = RegInit(false.B)
  val lastD = RegInit(0.U(p.dataBits.W))
  when(io.tl.d.valid) {
    hasD := true.B
    lastD := io.tl.d.bits.data
  }
  io.legacy.readData := Mux(io.tl.d.valid, io.tl.d.bits.data, Mux(hasD, lastD, io.passthroughMem.readData))

  val store = io.legacy.writeMask.orR
  val size = Wire(UInt(p.sizeBits.W))
  size := 2.U // default to word access
  switch(io.legacy.writeMask) {
    is("b0001".U) { size := 0.U }
    is("b0010".U) { size := 0.U }
    is("b0100".U) { size := 0.U }
    is("b1000".U) { size := 0.U }
    is("b0011".U) { size := 1.U }
    is("b1100".U) { size := 1.U }
    is("b1111".U) { size := 2.U }
  }

  val tlMask = Mux(store, io.legacy.writeMask, TLMask(io.legacy.addr, size, p.beatBytes))
  val opcode = Mux(store,
    Mux(io.legacy.writeMask === Fill(p.beatBytes, 1.U(1.W)), TLOpcodesA.PutFullData, TLOpcodesA.PutPartialData),
    TLOpcodesA.Get)

  io.tl.a.valid := io.legacy.valid
  io.tl.a.bits.opcode := opcode
  io.tl.a.bits.param := 0.U
  io.tl.a.bits.size := size
  io.tl.a.bits.source := 0.U
  io.tl.a.bits.address := io.legacy.addr
  io.tl.a.bits.mask := tlMask
  io.tl.a.bits.data := io.legacy.writeData
  io.tl.a.bits.corrupt := false.B

  io.tl.d.ready := true.B
}
