package Pipeline

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class PipelineSchedulerTest extends AnyFlatSpec {
  behavior of "PipelineScheduler"

  it should "rotate threads across stages in barrel fashion" in {
    val n = 8
    val stages = 8
    simulate(new PipelineScheduler(n, stages)) { dut =>
      for (i <- 0 until n) dut.io.threadEnable(i).poke(true.B)
      dut.io.advance.poke(true.B)
      val stageNames = Seq("F","DEC","DIS","RR","EX1","EX2","EX3","WB")
      for (cycle <- 0 until n) {
        val stagesStr = (0 until stages).map{i =>
          s"${stageNames(i)}:${dut.io.stageThreads(i).peek().litValue.toInt}"
        }.mkString(" ")
        println(s"[cycle $cycle] $stagesStr")
        // stage i should be owned by (cycle - i) mod n
        for (i <- 0 until stages) {
          val exp = ((cycle - i) % n + n) % n
          assert(dut.io.stageThreads(i).peek().litValue.toInt == exp)
        }
        dut.clock.step()
      }
    }
  }

  it should "match ThreadScheduler sequencing" in {
    val n = 8
    val stages = 8
    simulate(new PipelineScheduler(n, stages)) { dut =>
      for (i <- 0 until n) dut.io.threadEnable(i).poke(true.B)
      dut.io.advance.poke(true.B)

      val seen = collection.mutable.ArrayBuffer[Int]()
      val stageNames = Seq("F","DEC","DIS","RR","EX1","EX2","EX3","WB")

      for (cycle <- 0 until 16) {
        val fetch = dut.io.threadSelect.peek().litValue.toInt
        seen += fetch
        if (cycle < 8) {
          val stagesStr = (0 until stages).map(i => s"${stageNames(i)}:${dut.io.stageThreads(i).peek().litValue.toInt}").mkString(" ")
          println(s"[cycle $cycle] fetch=$fetch $stagesStr")
        }

        // stage 0 must equal current fetch thread like ThreadScheduler
        assert(dut.io.stageThreads(0).peek().litValue.toInt == fetch)

        // Remaining stages lag by their index, mirroring ThreadScheduler
        for (i <- 0 until stages) {
          val expected = (fetch + n - i) % n
          val got = dut.io.stageThreads(i).peek().litValue.toInt
          assert(got == expected, s"Stage $i expected $expected got $got")
        }

        dut.clock.step()
      }

      val expectedSeq = Seq(0,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7)
      assert(seen == expectedSeq, s"Unexpected fetch sequence: $seen")
    }
  }
}
