package ZeroNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class ZeroNyteRV32IAndTest extends AnyFlatSpec {

  behavior of "ZeroNyteCore (AND instructions)"

  it should "produce correct results for AND/ANDI sequences" in {
    simulate(new ZeroNyteRV32ICore) { dut =>
      val mask32 = 0xFFFFFFFFL

      def driveTLIdle(): Unit = {
        dut.io.tl.a.ready.poke(true.B)
        dut.io.tl.d.valid.poke(false.B)
        dut.io.tl.d.bits.opcode.poke(0.U)
        dut.io.tl.d.bits.param.poke(0.U)
        dut.io.tl.d.bits.size.poke(0.U)
        dut.io.tl.d.bits.source.poke(0.U)
        dut.io.tl.d.bits.denied.poke(false.B)
        dut.io.tl.d.bits.data.poke(0.U)
        dut.io.tl.d.bits.corrupt.poke(false.B)
      }

      // Reset core to a known state
      dut.reset.poke(true.B)
      dut.io.imem_rdata.poke(0.U)
      dut.io.dmem_rdata.poke(0.U)
      driveTLIdle()
      dut.clock.step()
      dut.reset.poke(false.B)

      case class StepExpectation(
          pc: Long,
          instr: Long,
          expectedResult: Option[Long],
          label: String
      )

      val expectations = Seq(
        StepExpectation(0x80000000L, 0x0ff00093L, Some(0x000000FFL), "ADDI x1, x0, 0x0FF"),
        StepExpectation(0x80000004L, 0x0f000113L, Some(0x000000F0L), "ADDI x2, x0, 0x0F0"),
        StepExpectation(0x80000008L, 0x0020f1b3L, Some(0x000000F0L), "AND x3, x1, x2"),
        StepExpectation(0x8000000CL, 0x0f00f213L, Some(0x000000F0L), "ANDI x4, x1, 0x0F0"),
        StepExpectation(0x80000010L, 0x00000013L, None, "NOP (park)")
      )

      expectations.foreach { step =>
        val pc = dut.io.pc_out.peek().litValue.toLong & mask32
        assert(
          pc == (step.pc & mask32),
          s"[${step.label}] Expected PC 0x${step.pc.toHexString}, got 0x${pc.toHexString}"
        )

        dut.io.imem_rdata.poke((step.instr & mask32).U(32.W))
        dut.io.dmem_rdata.poke(0.U)
        driveTLIdle()

        val observedInstr = dut.io.instr_out.peek().litValue.toLong & mask32
        assert(
          observedInstr == (step.instr & mask32),
          s"[${step.label}] Expected instruction 0x${java.lang.Long.toHexString(step.instr)}, got 0x${java.lang.Long.toHexString(observedInstr)}"
        )

        step.expectedResult.foreach { expected =>
          val observedResult = dut.io.result.peek().litValue.toLong & mask32
          assert(
            observedResult == (expected & mask32),
            f"[${step.label}] Expected result 0x${expected.toHexString}, got 0x${observedResult.toHexString}"
          )
        }

        dut.clock.step()
      }
    }
  }
}
