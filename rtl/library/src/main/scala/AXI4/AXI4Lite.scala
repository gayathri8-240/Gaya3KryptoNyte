package AXI4

import chisel3._
import chisel3.util._

case class AXI4LiteParams(addrBits: Int = 32, dataBits: Int = 32) {
  require(dataBits % 8 == 0, "dataBits must be byte-addressable")
  val strbBits: Int = dataBits / 8
}

object AXI4LiteResp {
  val OKAY   = "b00".U(2.W)
  val SLVERR = "b10".U(2.W)
}

class AXI4LiteAW(p: AXI4LiteParams) extends Bundle {
  val addr = UInt(p.addrBits.W)
  val prot = UInt(3.W)
}

class AXI4LiteW(p: AXI4LiteParams) extends Bundle {
  val data = UInt(p.dataBits.W)
  val strb = UInt(p.strbBits.W)
}

class AXI4LiteB extends Bundle {
  val resp = UInt(2.W)
}

class AXI4LiteAR(p: AXI4LiteParams) extends Bundle {
  val addr = UInt(p.addrBits.W)
  val prot = UInt(3.W)
}

class AXI4LiteR(p: AXI4LiteParams) extends Bundle {
  val data = UInt(p.dataBits.W)
  val resp = UInt(2.W)
}

/** AXI4-Lite master interface. */
class AXI4LiteIO(p: AXI4LiteParams) extends Bundle {
  val aw = Decoupled(new AXI4LiteAW(p))
  val w  = Decoupled(new AXI4LiteW(p))
  val b  = Flipped(Decoupled(new AXI4LiteB))
  val ar = Decoupled(new AXI4LiteAR(p))
  val r  = Flipped(Decoupled(new AXI4LiteR(p)))
}
