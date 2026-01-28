package Pipeline

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class ThreadSchedulerTest extends AnyFlatSpec {
  behavior of "ThreadScheduler"

  private val stageNames = Vector("F", "DEC", "DIS", "RR", "EX1", "EX2", "EX3", "WB")

  private def stageName(i: Int): String =
    if (i < stageNames.length) stageNames(i) else s"S$i"

  private def checkSequence(start: Int): Unit = {
    simulate(new ThreadScheduler(numThreads = 8, startingThread = start)) { dut =>
      dut.reset.poke(true.B)
      dut.clock.step()
      dut.reset.poke(false.B)
      val totalCycles = 16
      for (c <- 0 until totalCycles) {
        val expected = (start + c) % 8
        val expStages = Seq.tabulate(8)(i => (expected + 8 - i) % 8)
        val curr = dut.io.currentThread.peek().litValue.toInt
        val stages = dut.io.stageThreads.map(_.peek().litValue.toInt)
        val stageStr = stages.zipWithIndex.map { case (t, i) => s"${stageName(i)}:$t" }.mkString(" ")
        println(f"[ThreadScheduler start=$start%1d cycle=$c%02d] current=$curr expected=$expected | $stageStr")
        assert(curr == expected, s"cycle $c currentThread $curr != expected $expected (start=$start)")
        assert(stages == expStages, s"cycle $c stageThreads $stages != expected $expStages (start=$start)")
        dut.clock.step()
      }
    }
  }

  it should "roll through 8 threads starting at 0" in {
    checkSequence(start = 0)
  }

  it should "roll through 8 threads starting at 5" in {
    checkSequence(start = 5)
  }
}
