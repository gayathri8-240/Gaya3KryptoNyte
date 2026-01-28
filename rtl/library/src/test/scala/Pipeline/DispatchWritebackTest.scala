package Pipeline

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class DispatchWritebackTest extends AnyFlatSpec {
  behavior of "DispatchUnit and WritebackUnit"

  private def mkSlot(valid: Boolean, rd: Int, rs1: Int, rs2: Int, isALU: Boolean = true): DispatchSlot = {
    val s = Wire(new DispatchSlot)
    s.valid := valid.B
    s.rd := rd.U
    s.rs1 := rs1.U
    s.rs2 := rs2.U
    s.isALU := isALU.B
    s.isLoad := false.B
    s.isStore := false.B
    s.isBranch := false.B
    s.isJAL := false.B
    s.isJALR := false.B
    s.isLUI := false.B
    s.isAUIPC := false.B
    s
  }

  it should "issue only two ALU ops when limited by structural cap" in {
    simulate(new DispatchUnit(issueWidth = 4)) { dut =>
      dut.io.threadEnable.poke(true.B)
      dut.io.flushThread.poke(false.B)
      dut.io.inFlightBusy.foreach(_.poke(false.B))

      dut.io.inSlots(0) := mkSlot(valid = true, rd = 1, rs1 = 0, rs2 = 0)
      dut.io.inSlots(1) := mkSlot(valid = true, rd = 2, rs1 = 0, rs2 = 0)
      dut.io.inSlots(2) := mkSlot(valid = true, rd = 3, rs1 = 0, rs2 = 0)
      dut.io.inSlots(3) := mkSlot(valid = true, rd = 4, rs1 = 0, rs2 = 0)

      dut.clock.step()
      val mask = dut.io.issueMask.map(_.peek().litToBoolean)
      dut.io.issuedCount.expect(2.U)
      assert(mask.take(2).forall(_ == true) && mask.drop(2).forall(_ == false),
        s"Expected first two to issue, got mask $mask")
    }
  }

  it should "respect RAW hazard and stall subsequent slots" in {
    simulate(new DispatchUnit(issueWidth = 4)) { dut =>
      dut.io.threadEnable.poke(true.B)
      dut.io.flushThread.poke(false.B)
      dut.io.inFlightBusy.foreach(_.poke(false.B))

      // slot1 depends on rd of slot0 -> should not issue slot1 this cycle
      dut.io.inSlots(0) := mkSlot(valid = true, rd = 5, rs1 = 0, rs2 = 0)
      dut.io.inSlots(1) := mkSlot(valid = true, rd = 6, rs1 = 5, rs2 = 0)
      dut.io.inSlots(2) := mkSlot(valid = true, rd = 7, rs1 = 0, rs2 = 0)
      dut.io.inSlots(3) := mkSlot(valid = false, rd = 0, rs1 = 0, rs2 = 0)

      dut.clock.step()
      val mask = dut.io.issueMask.map(_.peek().litToBoolean)
      dut.io.issuedCount.expect(1.U)
      assert(mask(0) && !mask(1) && !mask(2), s"Expected only slot0 to issue, mask $mask")
    }
  }

  it should "limit writeback to two writes per cycle" in {
    simulate(new WritebackUnit(threadBits = 3, issueWidth = 4, maxWrites = 2)) { dut =>
      for (i <- 0 until 4) { dut.io.threadEnable(i).poke(true.B) }
      def wb(valid: Boolean, rd: Int, data: Int, tid: Int): WritebackSlot = {
        val s = Wire(new WritebackSlot(3))
        s.valid := valid.B
        s.rd := rd.U
        s.data := data.U
        s.threadId := tid.U
        s.writeEn := valid.B
        s
      }
      dut.io.inSlots(0) := wb(true, 1, 0x11, 0)
      dut.io.inSlots(1) := wb(true, 2, 0x22, 0)
      dut.io.inSlots(2) := wb(true, 3, 0x33, 0)
      dut.io.inSlots(3) := wb(true, 4, 0x44, 0)

      dut.clock.step()
      val wen = dut.io.wen.map(_.peek().litToBoolean)
      assert(wen.count(_ == true) == 2, s"Expected 2 write enables, got $wen")
      assert(wen(0) && wen(1) && !wen(2) && !wen(3), s"Expected only first two writes to pass, got $wen")
    }
  }
}
