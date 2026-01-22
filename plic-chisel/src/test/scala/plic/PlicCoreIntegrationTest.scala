import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class PlicCoreIntegrationTest extends AnyFlatSpec with ChiselScalatestTester {
  "PlicCore" should "route highest priority from sources to target and handle claim/complete" in {
    test(new plic.PlicCore(sources = 4, targets = 1, priorities = 8, maxPendingCount = 4)) { c =>
      // reset
      c.io.rst_n.poke(false.B)
      c.clock.step()
      c.io.rst_n.poke(true.B)
      c.clock.step()

      // set priorities (index -> priority): 0->2, 1->6, 2->4, 3->1
      c.io.ipriority(0).poke(2.U)
      c.io.ipriority(1).poke(6.U)
      c.io.ipriority(2).poke(4.U)
      c.io.ipriority(3).poke(1.U)

      // enable all sources for target 0
      for (i <- 0 until 4) c.io.ie(0)(i).poke(true.B)

      // low threshold
      c.io.threshold(0).poke(0.U)

      // set all to edge mode
      for (i <- 0 until 4) c.io.el(i).poke(true.B)

      // pulse source 0 (lower priority)
      c.io.src(0).poke(true.B); c.clock.step(); c.io.src(0).poke(false.B); c.clock.step()

      // pulse source 1 (higher priority)
      c.io.src(1).poke(true.B); c.clock.step(); c.io.src(1).poke(false.B); c.clock.step()

      // allow signals to settle and ensure both gateways show pending
      c.clock.step()
      c.io.ip(0).expect(true.B)
      c.io.ip(1).expect(true.B)

      // target should see source 1 (id = index+1 -> 2)
      c.clock.step()
      c.io.ireq(0).expect(true.B)
      c.io.id(0).expect(2.U)

      // claim the interrupt (allow extra settle cycle)
      c.io.claim(0).poke(true.B); c.clock.step(); c.io.claim(0).poke(false.B); c.clock.step(); c.clock.step()

      // complete handling
      c.io.complete(0).poke(true.B); c.clock.step(); c.io.complete(0).poke(false.B); c.clock.step()

      // now pulse source 0 again and expect it to be served
      c.io.src(0).poke(true.B); c.clock.step(); c.io.src(0).poke(false.B); c.clock.step()
      c.io.ireq(0).expect(true.B)
      c.io.id(0).expect(1.U)
    }
  }

  it should "respect per-target interrupt enable masks" in {
    test(new plic.PlicCore(sources = 3, targets = 2, priorities = 8, maxPendingCount = 2)) { c =>
      c.io.rst_n.poke(false.B); c.clock.step(); c.io.rst_n.poke(true.B); c.clock.step()

      // priorities: 0->1, 1->7, 2->3
      c.io.ipriority(0).poke(1.U); c.io.ipriority(1).poke(7.U); c.io.ipriority(2).poke(3.U)

      // target 0 enables only source 1
      c.io.ie(0)(0).poke(false.B); c.io.ie(0)(1).poke(true.B); c.io.ie(0)(2).poke(false.B)
      // target 1 enables source 0 and 2
      c.io.ie(1)(0).poke(true.B); c.io.ie(1)(1).poke(false.B); c.io.ie(1)(2).poke(true.B)

      // thresholds low
      c.io.threshold(0).poke(0.U); c.io.threshold(1).poke(0.U)

      // edge mode
      for (i <- 0 until 3) c.io.el(i).poke(true.B)

      // pulse source 1 (id=2)
      c.io.src(1).poke(true.B); c.clock.step(); c.io.src(1).poke(false.B); c.clock.step()
      c.clock.step()

      // ensure gateway pending and then check targets
      c.io.ip(1).expect(true.B)
      c.clock.step()
      c.io.ireq(0).expect(true.B); c.io.id(0).expect(2.U)
      c.io.ireq(1).expect(false.B)
    }
  }
}
