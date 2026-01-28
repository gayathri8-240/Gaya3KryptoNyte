package TileLink

import chisel3._
import chisel3.util._

/** Simple TileLink-UL SRAM model for simulation/integration bring-up. */
class TLRAM(p: TLParams = TLParams(), depth: Int = 1024) extends Module {
  val io = IO(new Bundle {
    val tl = Flipped(new TLBundleUL(p))
  })

  val mem = Mem(depth, UInt(p.dataBits.W)) // combinational read for simple modeling

  // Accept every request; back-pressure can be added later if needed.
  io.tl.a.ready := true.B

  // Queue responses to avoid combinational paths.
  val resp = Wire(new TLBundleD(p))
  val respValid = Wire(Bool())
  val respQueue = Module(new Queue(new TLBundleD(p), 2))

  respQueue.io.enq.valid := false.B
  respQueue.io.enq.bits := 0.U.asTypeOf(resp)

  when(io.tl.a.fire) {
    val addr = io.tl.a.bits.address
    val index = addr(p.addrBits - 1, log2Ceil(p.beatBytes))
    val isPut = io.tl.a.bits.opcode === TLOpcodesA.PutFullData || io.tl.a.bits.opcode === TLOpcodesA.PutPartialData
    val isGet = io.tl.a.bits.opcode === TLOpcodesA.Get

    val readData = mem.read(index)
    when(isPut) {
      val mask = io.tl.a.bits.mask
      val wdata = io.tl.a.bits.data
      val curr = mem.read(index)
      val byteVec = VecInit(Seq.tabulate(p.beatBytes) { i =>
        val byte = wdata(8 * (i + 1) - 1, 8 * i)
        val keep = mask(i)
        Mux(keep, byte, curr(8 * (i + 1) - 1, 8 * i))
      })
      mem.write(index, byteVec.asUInt)
    }

    val d = WireDefault(0.U.asTypeOf(new TLBundleD(p)))
    d.opcode := Mux(isGet, TLOpcodesD.AccessAckData, TLOpcodesD.AccessAck)
    d.param := 0.U
    d.size := io.tl.a.bits.size
    d.source := io.tl.a.bits.source
    d.denied := false.B
    d.data := Mux(isGet, readData, 0.U)
    d.corrupt := false.B

    respQueue.io.enq.valid := true.B
    respQueue.io.enq.bits := d
  }

  respQueue.io.deq.ready := io.tl.d.ready
  respValid := respQueue.io.deq.valid
  resp := respQueue.io.deq.bits

  io.tl.d.valid := respValid
  io.tl.d.bits := resp
}
