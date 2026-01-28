package AHB

import chisel3._

case class AHBLiteParams(addrBits: Int = 32, dataBits: Int = 32) {
  require(dataBits % 8 == 0, "dataBits must be byte-addressable")
}

object AHBTrans {
  val IDLE   = "b00".U(2.W)
  val BUSY   = "b01".U(2.W)
  val NONSEQ = "b10".U(2.W)
  val SEQ    = "b11".U(2.W)
}

class AHBLiteIO(p: AHBLiteParams) extends Bundle {
  val haddr  = Output(UInt(p.addrBits.W))
  val hwrite = Output(Bool())
  val htrans = Output(UInt(2.W))
  val hsize  = Output(UInt(3.W))
  val hsel   = Output(Bool())
  val hwdata = Output(UInt(p.dataBits.W))

  val hrdata = Input(UInt(p.dataBits.W))
  val hready = Input(Bool())
  val hresp  = Input(Bool())
}
