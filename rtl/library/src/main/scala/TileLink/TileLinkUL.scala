package TileLink

import chisel3._
import chisel3.util._

// Minimal TileLink-Uncached Lite parameters for a single master.
case class TLParams(addrBits: Int = 32, dataBits: Int = 32, sourceBits: Int = 4) {
  require(dataBits % 8 == 0, "dataBits must be byte-addressable")
  val beatBytes: Int = dataBits / 8
  // Allow sizes up to the beat width; width+1 keeps room for a future burst size.
  val sizeBits: Int = log2Ceil(beatBytes) + 1
}

object TLOpcodesA {
  val PutFullData    = "b000".U(3.W)
  val PutPartialData = "b001".U(3.W)
  val ArithmeticData = "b010".U(3.W)
  val LogicalData    = "b011".U(3.W)
  val Get            = "b100".U(3.W)
  val Intent         = "b101".U(3.W) // Unused in TL-UL, reserved
  val AcquireBlock   = "b110".U(3.W) // Unused in TL-UL, reserved
  val AcquirePerm    = "b111".U(3.W) // Unused in TL-UL, reserved
}

object TLOpcodesD {
  val AccessAck     = "b000".U(3.W)
  val AccessAckData = "b001".U(3.W)
  val HintAck       = "b010".U(3.W)
  val Grant         = "b100".U(3.W) // Unused in TL-UL, reserved
  val GrantData     = "b101".U(3.W) // Unused in TL-UL, reserved
  val ReleaseAck    = "b110".U(3.W) // Unused in TL-UL, reserved
}

object TLMask {
  /** Compute a byte mask for a TL-UL beat given address and size (log2 of bytes). */
  def apply(addr: UInt, size: UInt, beatBytes: Int): UInt = {
    require(beatBytes >= 1, "beatBytes must be positive")
    val offWidth = log2Ceil(beatBytes)
    // If beatBytes == 1 there is no offset; synthesize a zero-width wire safely.
    val byteOffset = if (offWidth == 0) 0.U(1.W) else addr(offWidth - 1, 0)
    val span = (1.U((offWidth + 1).W)) << size // number of bytes in the access
    val upper = byteOffset + span

    val maskBits = (0 until beatBytes).map { i =>
      val within = (i.U >= byteOffset) && (i.U < upper)
      within
    }
    Cat(maskBits.reverse).asUInt
  }
}

class TLBundleA(p: TLParams) extends Bundle {
  val opcode  = UInt(3.W)
  val param   = UInt(3.W)
  val size    = UInt(p.sizeBits.W)
  val source  = UInt(p.sourceBits.W)
  val address = UInt(p.addrBits.W)
  val mask    = UInt(p.beatBytes.W)
  val data    = UInt(p.dataBits.W)
  val corrupt = Bool()
}

class TLBundleD(p: TLParams) extends Bundle {
  val opcode  = UInt(3.W)
  val param   = UInt(2.W)
  val size    = UInt(p.sizeBits.W)
  val source  = UInt(p.sourceBits.W)
  val denied  = Bool()
  val data    = UInt(p.dataBits.W)
  val corrupt = Bool()
}

/** Convenience bundle for a TL-UL master port (A out, D in). */
class TLBundleUL(p: TLParams) extends Bundle {
  val a = Decoupled(new TLBundleA(p))
  val d = Flipped(Decoupled(new TLBundleD(p)))
}
