package plic

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

class PlicCellTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior of "PlicCell"
  
  it should "output priority and ID when interrupt is pending and enabled" in {
    test(new PlicCell(id = 5, sources = 8, priorities = 7)) { dut =>
      // reset
      dut.io.rst_n.poke(false.B)
      dut.clock.step()
      dut.io.rst_n.poke(true.B)
      dut.clock.step()

      dut.io.priority.poke(3.U)
      dut.io.ie.poke(true.B)
      dut.io.ip.poke(true.B)
      dut.clock.step(1)
      dut.io.priorityOut.expect(3.U)
      dut.io.id.expect(5.U)
    }
  }
}
