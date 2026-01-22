import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class PlicTargetTest extends AnyFlatSpec with ChiselScalatestTester {
  "PlicTarget" should "select highest priority id and respect threshold" in {
    test(new plic.PlicTarget(sources = 4, priorities = 8)) { c =>
      // reset (active-low)
      c.io.rst_n.poke(false.B)
      c.clock.step()
      c.io.rst_n.poke(true.B)
      c.clock.step()

      // setup priorities and ids
      c.io.id_i(0).poke(1.U)
      c.io.priority_i(0).poke(2.U)
      c.io.id_i(1).poke(2.U)
      c.io.priority_i(1).poke(5.U)
      c.io.id_i(2).poke(3.U)
      c.io.priority_i(2).poke(3.U)
      c.io.id_i(3).poke(4.U)
      c.io.priority_i(3).poke(1.U)

      // threshold lower than highest priority
      c.io.threshold_i.poke(4.U)
      c.clock.step()

      c.io.ireq_o.expect(true.B)
      c.io.id_o.expect(2.U)

      // increase threshold above top priority
      c.io.threshold_i.poke(6.U)
      c.clock.step()
      c.io.ireq_o.expect(false.B)
    }
  }
}
