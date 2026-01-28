package RegFiles

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class RegFileMTMultiWVecTest extends AnyFlatSpec {
  behavior of "RegFileMTMultiWVec"

  it should "support independent writes across threads and read them back" in {
    simulate(new RegFileMTMultiWVec(width = 32, depth = 32, numThreads = 4, numWritePorts = 4, numReadPorts = 4)) { dut =>
      // Drive four parallel writes to four different threads/regs
      val threads = Seq(0, 1, 2, 3)
      val regs    = Seq(1, 2, 3, 4)
      val data    = Seq(0x11, 0x22, 0x33, 0x44)
      for (wp <- threads.indices) {
        dut.io.writeThreadID(wp).poke(threads(wp).U)
        dut.io.dst(wp).poke(regs(wp).U)
        dut.io.dstData(wp).poke(data(wp).U)
        dut.io.wen(wp).poke(true.B)
      }
      // Reads are ignored this cycle; keep them benign
      for (rp <- threads.indices) {
        dut.io.readThreadID(rp).poke(0.U)
        dut.io.src1(rp).poke(0.U)
        dut.io.src2(rp).poke(0.U)
      }
      dut.clock.step()

      // Set up four concurrent reads: each port looks at its thread/reg
      for (rp <- threads.indices) {
        dut.io.readThreadID(rp).poke(threads(rp).U)
        dut.io.src1(rp).poke(regs(rp).U)
        dut.io.src2(rp).poke(0.U) // don't-care second read
      }
      dut.clock.step()

      for (rp <- threads.indices) {
        dut.io.src1data(rp).expect(data(rp).U, s"Readback mismatch on thread ${threads(rp)} reg ${regs(rp)}")
      }
    }
  }

  it should "apply later write ports with priority when targeting the same register" in {
    simulate(new RegFileMTMultiWVec(width = 32, depth = 32, numThreads = 2, numWritePorts = 4, numReadPorts = 1)) { dut =>
      // Two writes to the same thread/register in the same cycle on different ports
      dut.io.writeThreadID(0).poke(0.U); dut.io.dst(0).poke(5.U); dut.io.dstData(0).poke("hAAAA_BBBB".U); dut.io.wen(0).poke(true.B)
      dut.io.writeThreadID(1).poke(0.U); dut.io.dst(1).poke(5.U); dut.io.dstData(1).poke("hCCCC_DDDD".U); dut.io.wen(1).poke(true.B)
      dut.io.writeThreadID(2).poke(0.U); dut.io.dst(2).poke(0.U); dut.io.dstData(2).poke(0.U); dut.io.wen(2).poke(false.B)
      dut.io.writeThreadID(3).poke(0.U); dut.io.dst(3).poke(0.U); dut.io.dstData(3).poke(0.U); dut.io.wen(3).poke(false.B)

      // Read port idle this cycle
      dut.io.readThreadID(0).poke(0.U)
      dut.io.src1(0).poke(5.U)
      dut.io.src2(0).poke(0.U)
      dut.clock.step()

      // Read back reg5 from thread0
      dut.io.readThreadID(0).poke(0.U)
      dut.io.src1(0).poke(5.U)
      dut.io.src2(0).poke(0.U)
      dut.clock.step()

      // Expect the later port (index 1) to win
      dut.io.src1data(0).expect("hCCCC_DDDD".U)
    }
  }
}
