package AHB

import chisel3._
import chisel3.util._

/** Simple AHB-Lite RAM model for simulation. */
class AHBLiteRAM(p: AHBLiteParams = AHBLiteParams(), depth: Int = 1024) extends Module {
  val io = IO(new Bundle {
    val ahb = Flipped(new AHBLiteIO(p))
  })

  val mem = Mem(depth, UInt(p.dataBits.W))

  val addrIdx = io.ahb.haddr(p.addrBits - 1, log2Ceil(p.dataBits / 8))
  val isActive = io.ahb.hsel && (io.ahb.htrans === AHBTrans.NONSEQ)

  val readData = mem.read(addrIdx)
  io.ahb.hrdata := readData
  io.ahb.hready := true.B
  io.ahb.hresp := false.B

  when(isActive && io.ahb.hwrite) {
    val bytes = p.dataBits / 8
    val byteOffset = io.ahb.haddr(log2Ceil(bytes) - 1, 0)
    val mask = Wire(UInt(bytes.W))
    mask := 0.U
    switch(io.ahb.hsize) {
      is(0.U) { mask := (1.U(bytes.W) << byteOffset) } // byte
      is(1.U) { // halfword
        mask := Mux(byteOffset(0), "b1100".U(bytes.W), "b0011".U(bytes.W))
      }
      is(2.U) { mask := Fill(bytes, 1.U(1.W)) } // word
    }

    val curr = mem.read(addrIdx)
    val wdata = io.ahb.hwdata
    val mergedBytes = VecInit(Seq.tabulate(bytes) { i =>
      val byte = wdata(8 * (i + 1) - 1, 8 * i)
      val keep = mask(i)
      Mux(keep, byte, curr(8 * (i + 1) - 1, 8 * i))
    })
    mem.write(addrIdx, mergedBytes.asUInt)
  }
}
