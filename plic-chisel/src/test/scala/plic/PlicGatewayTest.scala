import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class PlicGatewayTest extends AnyFlatSpec with ChiselScalatestTester {
  "PlicGateway" should "assert ip on rising edge and clear on claim/complete" in {
    test(new plic.PlicGateway(maxPendingCount = 4)) { c =>
      // apply reset (active low)
      c.io.rst_n.poke(false.B)
      c.clock.step()
      c.io.rst_n.poke(true.B)
      c.clock.step()

      // initially src low
      c.io.src.poke(false.B)
      c.io.edge_lvl.poke(true.B) // edge mode
      c.clock.step()

      // pulse src high then low -> rising edge
      c.io.src.poke(true.B)
      c.clock.step()
      c.io.src.poke(false.B)
      c.clock.step()

      // ip should assert (pending)
      c.io.ip.expect(true.B)

      // claim
      c.io.claim.poke(true.B)
      c.clock.step()
      c.io.claim.poke(false.B)
      c.clock.step()

      // now ip should be in claimed state (not pending)
      c.io.ip.expect(false.B)

      // complete
      c.io.complete.poke(true.B)
      c.clock.step()
      c.io.complete.poke(false.B)
      c.clock.step()

      // ip should be cleared and able to assert again
      c.io.src.poke(true.B)
      c.clock.step()
      c.io.src.poke(false.B)
      c.clock.step()
      c.io.ip.expect(true.B)
    }
  }
}
