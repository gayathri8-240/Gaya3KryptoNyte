package ZeroNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import ZeroNyte.ZeroNyteRV32ICore

class ZeroNyteRV32ICoreTest extends AnyFlatSpec {

  "ZeroNyteCore" should "fetch and execute instructions correctly" in {
    simulate(new ZeroNyteRV32ICore) { dut =>
      val printDebugInfo = true
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

      // Apply reset to ensure deterministic starting state
      dut.reset.poke(true.B)
      dut.io.imem_rdata.poke(0.U)
      driveTLIdle()
      dut.clock.step()
      dut.reset.poke(false.B)

      val basePC = dut.io.pc_out.peek().litValue.toLong & mask32
      var cycle = 0

      // Helper to test a single instruction, providing instruction memory stimulus
      def testInstruction(expectedInstr: Long, idx: Int): Unit = {
        val expectedPC = (basePC + idx * 4L) & mask32
        val pc = dut.io.pc_out.peek().litValue.toLong & mask32

        // Drive instruction memory with expected word for the current PC
        dut.io.imem_rdata.poke((expectedInstr & mask32).U(32.W))
        driveTLIdle()

        val instr = dut.io.instr_out.peek().litValue.toLong & mask32

        if (printDebugInfo) {
          val pcHex = java.lang.Long.toHexString(pc)
          val instrHex = java.lang.Long.toHexString(instr)
          println(f"[Cycle $cycle%02d] PC: 0x$pcHex, Instr: 0x$instrHex")
        }

        // Assertions
        assert(pc == expectedPC, s"Expected PC 0x${java.lang.Long.toHexString(expectedPC)}, got 0x${java.lang.Long.toHexString(pc)}")
        assert(instr == (expectedInstr & mask32), s"Expected instruction 0x${java.lang.Long.toHexString(expectedInstr)}, got 0x${java.lang.Long.toHexString(instr)}")

        dut.clock.step(1)
        cycle += 1
      }

      // Sequence of instructions to exercise basic fetch/execute path
      val program = Seq(
        0x00000013L, // NOP
        0x00100093L, // ADDI
        0x00208133L  // ADD
      )

      program.zipWithIndex.foreach { case (instr, idx) =>
        testInstruction(instr, idx)
      }
    }
  }
}
