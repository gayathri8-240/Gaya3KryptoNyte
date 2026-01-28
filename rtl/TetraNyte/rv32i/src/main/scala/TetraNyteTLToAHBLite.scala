package TetraNyte

import chisel3._
import TileLink._
import AXI4._
import AHB._
import Bridges.TLToAHBLite

/** Wrapper to expose an AHB-Lite master from the legacy TetraNyte memory signals. */
class TetraNyteTLToAHBLite(tlParams: TLParams = TLParams(),
                           axiParams: AXI4LiteParams = AXI4LiteParams(),
                           ahbParams: AHBLiteParams = AHBLiteParams()) extends Module {
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

    val ahb = new AHBLiteIO(ahbParams)
  })

  private val memPort = Module(new TetraNyteMemPort(tlParams))
  private val bridge = Module(new TLToAHBLite(tlParams, axiParams, ahbParams))

  memPort.io.legacy.valid := io.legacy.valid
  memPort.io.legacy.addr := io.legacy.addr
  memPort.io.legacy.writeData := io.legacy.writeData
  memPort.io.legacy.writeMask := io.legacy.writeMask
  io.legacy.readData := memPort.io.legacy.readData

  io.passthroughMem.addr := memPort.io.passthroughMem.addr
  io.passthroughMem.writeData := memPort.io.passthroughMem.writeData
  io.passthroughMem.writeMask := memPort.io.passthroughMem.writeMask
  memPort.io.passthroughMem.readData := io.passthroughMem.readData

  bridge.io.tl <> memPort.io.tl
  io.ahb <> bridge.io.ahb
}
