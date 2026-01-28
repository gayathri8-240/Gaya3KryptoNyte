// Licensed under the BSD 3-Clause License. 
// See https://opensource.org/licenses/BSD-3-Clause for details.

package LoadUnit
import chisel3._
import chisel3.util._

/**
  * Load unit with parameterizable bus width.
  *
  * @param dataWidth width of the incoming data bus in bits (must be >= 32 and byte-multiple).
  *                  Defaults to 32b so existing cores (Zero/TetraNyte) are unchanged.
  *                  Wider values (e.g. 128b) allow aligned packet fetches while still
  *                  extracting the targeted byte/half/word based on the byte address.
  */
class LoadUnit(dataWidth: Int = 32) extends Module {
  require(dataWidth % 8 == 0, "dataWidth must be a multiple of 8")
  require(dataWidth >= 32, "dataWidth must be at least 32 bits")

  val io = IO(new Bundle {
    val addr = Input(UInt(32.W))      // Memory address
    val dataIn = Input(UInt(dataWidth.W))    // Data from memory (bus width parameterized)
    val funct3 = Input(UInt(3.W))     // Load type (funct3 field from instruction)
    val dataOut = Output(UInt(32.W))  // Processed load data
  })

  // Load type encoding based on RISC-V funct3 field
  val LB  = "b000".U  // Load Byte (signed)
  val LH  = "b001".U  // Load Halfword (signed)
  val LW  = "b010".U  // Load Word (signed)
  val LBU = "b100".U  // Load Byte (unsigned)
  val LHU = "b101".U  // Load Halfword (unsigned)

  // Parameterized width extraction
  val loadWidth = Wire(UInt(2.W))
  val isSigned = Wire(Bool())

  loadWidth := MuxCase(2.U, Seq(
    (io.funct3 === LB || io.funct3 === LBU) -> 0.U,
    (io.funct3 === LH || io.funct3 === LHU) -> 1.U,
    (io.funct3 === LW) -> 2.U
  ))

  isSigned := (io.funct3 === LB || io.funct3 === LH || io.funct3 === LW)

  // Select the proper lane based on address offset (little endian).
  // Supports wider buses by shifting the incoming line down to the targeted byte.
  private val addrLSBWidth = log2Ceil(dataWidth / 8)
  val byteShift = (io.addr(addrLSBWidth - 1, 0) << 3)
  val aligned = (io.dataIn >> byteShift)(31, 0) // capture up to 32b window after shift
  val byteLane = aligned(7, 0)
  val halfLane = aligned(15, 0)

  val signedData = MuxCase(io.dataIn, Seq(
    (loadWidth === 0.U)  -> byteLane.asSInt.pad(32).asUInt,
    (loadWidth === 1.U)  -> halfLane.asSInt.pad(32).asUInt
  ))

  val unsignedData = MuxCase(io.dataIn, Seq(
    (loadWidth === 0.U)  -> byteLane.zext.pad(32).asUInt,
    (loadWidth === 1.U)  -> halfLane.zext.pad(32).asUInt
  ))

  io.dataOut := Mux(isSigned, signedData, unsignedData)
}
