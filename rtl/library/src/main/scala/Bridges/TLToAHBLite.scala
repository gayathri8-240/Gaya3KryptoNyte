package Bridges

import chisel3._
import TileLink._
import AXI4._
import AHB._

/** TileLink-UL to AHB-Lite bridge via AXI4-Lite (single outstanding transaction). */
class TLToAHBLite(tlParams: TLParams = TLParams(),
                  axiParams: AXI4LiteParams = AXI4LiteParams(),
                  ahbParams: AHBLiteParams = AHBLiteParams()) extends Module {
  require(tlParams.dataBits == axiParams.dataBits, "TL and AXI data widths must match")
  require(axiParams.dataBits == ahbParams.dataBits, "AXI and AHB data widths must match")
  val io = IO(new Bundle {
    val tl  = Flipped(new TLBundleUL(tlParams))
    val ahb = new AHBLiteIO(ahbParams)
  })

  private val tlToAxi = Module(new TLToAXI4Lite(tlParams, axiParams))
  private val axiToAhb = Module(new AXI4LiteToAHBLite(axiParams, ahbParams))

  tlToAxi.io.tl <> io.tl
  axiToAhb.io.axi <> tlToAxi.io.axi
  io.ahb <> axiToAhb.io.ahb
}
