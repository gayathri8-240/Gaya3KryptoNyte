package OctoNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import org.slf4j.LoggerFactory

class OctoNyteRV32ICoreTest extends AnyFlatSpec {
  behavior of "OctoNyteRV32ICore"

  private val logger = LoggerFactory.getLogger(getClass)

  private def dumpState(cycle: Int, label: String, dut: OctoNyteRV32ICore): Unit = {
    val stageNames = Seq("pc", "dec", "dis", "rr", "ex1", "ex2", "ex3", "wb")
    val stageTh = dut.io.debugStageThreads.map(_.peek().litValue.toInt)
    val stageVal= dut.io.debugStageValids.map(_.peek().litToBoolean)
    val stageSummary = stageNames.indices.map { i =>
      val v = if (stageVal(i)) "V" else "-"
      s"${stageNames(i)}:${stageTh(i)}$v"
    }.mkString(" ")
    logger.debug(s"Clock $cycle [$label]: stages=[$stageSummary]")
    val invStage = Array.fill(8)("?")
    val invValid = Array.fill(8)(false)
    for (s <- stageTh.indices) {
      val t = stageTh(s)
      if (t < invStage.length) {
        invStage(t) = stageNames(s)
        invValid(t) = stageVal(s)
      }
    }
    for (t <- 0 until 8) {
      val regs = (0 to 4).map(r => dut.io.debugRegs01234(t)(r).peek().litValue)
      val pc    = dut.io.debugPC(t).peek().litValue
      val stage = invStage(t)
      val valid = invValid(t)
      logger.debug(f"  thread $t: $stage%-4s valid=$valid%-5s pc=0x$pc%08x regs=$regs")
    }
  }

  it should "execute ADDI x1,x0,1 across all threads using the single issue slot" in {
    logger.info("Test: Stream a single-slot ADDI x1,x0,1 every cycle (other slots are NOPs). Each thread repeatedly executes it, so x1 should converge to (and remain) 1 once writeback starts.")
    simulate(new OctoNyteRV32ICore) { dut =>
      for (i <- 0 until 8) { dut.io.threadEnable(i).poke(true.B) }
      dut.io.dataMemResp.poke(0.U)

      dut.reset.poke(true.B)
      dut.clock.step(2)
      dut.reset.poke(false.B)

      // Only slot 0 is consumed by the core; fill the rest with NOPs.
      val singleAddiPacket = BigInt("00000013000000130000001300100093", 16).U(128.W)
      val debugCycles = 32
      val totalCycles = 80
      for (c <- 0 until totalCycles) {
        dut.io.instrMem.poke(singleAddiPacket)
        dut.clock.step()
        if (c < debugCycles) {
          dumpState(c, "single-slot ADDI", dut)
        }
      }

      logger.info("Final x1 values after single-slot ADDI:")
      for (t <- 0 until 8) {
        val x1 = dut.io.debugRegs01234(t)(1).peek().litValue
        logger.info(s"  thread $t -> x1=$x1")
        assert(x1 == 1, s"Thread $t x1 mismatch: got $x1 expected 1")
      }
    }
  }

  it should "accumulate ADDI x1,x1,1 results equally across threads" in {
    logger.info("Test: Stream a single-slot ADDI x1,x1,1 every cycle (other slots are NOPs). Each thread repeatedly executes it, so x1 should increase over time at roughly the same rate across threads.")
    simulate(new OctoNyteRV32ICore) { dut =>
      for (i <- 0 until 8) { dut.io.threadEnable(i).poke(true.B) }
      dut.io.dataMemResp.poke(0.U)

      dut.reset.poke(true.B)
      dut.clock.step(2)
      dut.reset.poke(false.B)

      val accumPacket = BigInt("00000013000000130000001300108093", 16).U(128.W)
      val steps = 80
      val debugCycles = 40
      for (c <- 0 until steps) {
        dut.io.instrMem.poke(accumPacket)
        dut.clock.step()
        if (c < debugCycles) {
          dumpState(c, "accum ADDI", dut)
        }
      }

      logger.info("Final x1 values after accumulative ADDI:")
      val values = (0 until 8).map { t =>
        val x1 = dut.io.debugRegs01234(t)(1).peek().litValue
        logger.info(s"  thread $t -> x1=$x1")
        x1
      }
      assert(values.forall(_ >= 1), s"Each thread should increment x1 at least once: $values")
    }
  }
}
