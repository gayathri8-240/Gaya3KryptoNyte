package ALUs

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import ALUs.ALU32.Opcode

class ALU_ShiftTest extends AnyFlatSpec {

  "ALU32" should "correctly perform logical and arithmetic shift operations" in {
    simulate(new ALU32) { dut =>
      val printDebugInfo = false

      def testOperation(a: BigInt, b: BigInt, opcode: UInt, expected: BigInt): Unit = {
        dut.io.a.poke(a.U(32.W))
        dut.io.b.poke(b.U(32.W))
        dut.io.opcode.poke(opcode)
        dut.clock.step()

        val result = dut.io.result.peek().litValue & 0xFFFFFFFFL

        if (printDebugInfo)
          println(f"[ALU_ShiftTest] a=$a%08x b=$b%08x opcode=$opcode -> result=$result%08x expected=$expected%08x")

        assert(result == (expected & 0xFFFFFFFFL),
          s"[ALU_ShiftTest] Expected 0x${(expected & 0xFFFFFFFFL).toString(16)} but got 0x${result.toString(16)} for opcode $opcode")
      }

      def testSLL(): Unit = {
        testOperation(1, 4, Opcode.SLL, 16)
      }

      def testSRL(): Unit = {
        testOperation(0xF0000000L, 4, Opcode.SRL, 0x0F000000L)
      }

      def testSRA(): Unit = {
        testOperation(0xF0000000L, 4, Opcode.SRA, (0xF0000000L.toInt >> 4) & 0xFFFFFFFFL)
      }

      testSLL()
      testSRL()
      testSRA()
    }
  }
}