// Licensed under the BSD 3-Clause License.
// See https://opensource.org/licenses/BSD-3-Clause for details.

package RegFiles

import chisel3._
import chisel3.util._

/**
  * Multithreaded register file with 2 read ports and N write ports.
  * Parameterised to keep existing cores unchanged (defaults: 32b width, 32 regs, 4 threads, 1 write port).
  */
class RegFileMTMultiWVec(
    width: Int = 32,
    depth: Int = 32,
    numThreads: Int = 4,
    numWritePorts: Int = 1,
    numReadPorts: Int = 1) extends Module {

  require(numWritePorts >= 1, "Must have at least one write port")
  require(numReadPorts >= 1, "Must have at least one read port")

  private val addrWidth = log2Ceil(depth)
  private val threadWidth = log2Ceil(numThreads)
  private val effectiveDepth = depth * numThreads
  private val effectiveAddrWidth = log2Ceil(effectiveDepth)

  val io = IO(new Bundle {
    val readThreadID  = Input(Vec(numReadPorts, UInt(threadWidth.W)))
    val src1          = Input(Vec(numReadPorts, UInt(addrWidth.W)))
    val src2          = Input(Vec(numReadPorts, UInt(addrWidth.W)))
    val src1data      = Output(Vec(numReadPorts, UInt(width.W)))
    val src2data      = Output(Vec(numReadPorts, UInt(width.W)))

    val writeThreadID = Input(Vec(numWritePorts, UInt(threadWidth.W)))
    val dst           = Input(Vec(numWritePorts, UInt(addrWidth.W)))
    val wen           = Input(Vec(numWritePorts, Bool()))
    val dstData       = Input(Vec(numWritePorts, UInt(width.W)))

    // Debug: per-thread x1 view
    val debugX1       = Output(Vec(numThreads, UInt(width.W)))
    val debugRegs01234= Output(Vec(numThreads, Vec(5, UInt(width.W))))
  })

  val regs = RegInit(VecInit(Seq.fill(effectiveDepth)(0.U(width.W))))

  // Combinational reads
  for (rp <- 0 until numReadPorts) {
    val effectiveSrc1 = Cat(io.readThreadID(rp), io.src1(rp))
    val effectiveSrc2 = Cat(io.readThreadID(rp), io.src2(rp))
    io.src1data(rp) := regs(effectiveSrc1)
    io.src2data(rp) := regs(effectiveSrc2)
  }

  // Writes: simple sequential priority from port 0..N-1
  for (wp <- 0 until numWritePorts) {
    when(io.wen(wp)) {
      val effDst = Cat(io.writeThreadID(wp), io.dst(wp))
      regs(effDst) := io.dstData(wp)
    }
  }

  // Debug view of x1 per thread
  for (t <- 0 until numThreads) {
    val idx = t * depth + 1
    io.debugX1(t) := regs(idx)
    val base = t * depth
    for (r <- 0 until 5) {
      io.debugRegs01234(t)(r) := regs(base + r)
    }
  }
}
