import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

import scala.util.Random

class PlicTargetFuzzTest extends AnyFlatSpec with ChiselScalatestTester {
  "PlicTarget" should "match combinational priority selection across random inputs" in {
    val rnd = new Random(12345)
    val sources = 6
    val priorities = 16

    test(new plic.PlicTarget(sources = sources, priorities = priorities)) { c =>
      // reset
      c.io.rst_n.poke(false.B); c.clock.step(); c.io.rst_n.poke(true.B); c.clock.step()

      for (_ <- 0 until 200) {
        // random priorities and ids
        val pr = Array.fill(sources)(rnd.nextInt(priorities))
        val ids = Array.fill(sources)(rnd.nextInt(sources) + 1) // id in 1..sources
        val threshold = rnd.nextInt(priorities)

        for (i <- 0 until sources) {
          c.io.priority_i(i).poke(pr(i).U)
          c.io.id_i(i).poke(ids(i).U)
        }
        c.io.threshold_i.poke(threshold.U)
        c.clock.step()

        // reference: first occurrence of max priority (leftmost) wins
        var bestP = -1
        var bestI = 0
        for (i <- 0 until sources) {
          if (pr(i) > bestP) { bestP = pr(i); bestI = ids(i) }
        }
        val refIreq = bestP > threshold

        c.io.ireq_o.expect((if (refIreq) 1 else 0).U)
        c.io.id_o.expect(bestI.U)
      }
    }
  }
}
