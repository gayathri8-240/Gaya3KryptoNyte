package ALUs

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import ALUs.ALU32.Opcode

class ALU_LogicTest extends AnyFlatSpec {

  "ALU32" should "correctly perform logical operations (AND, OR, XOR)" in {
    simulate(new ALU32) { dut =>
      val printDebugInfo = false

      def testOperation(a: BigInt, b: BigInt, opcode: UInt, expected: BigInt): Unit = {
        dut.io.a.poke(a.U(32.W))
        dut.io.b.poke(b.U(32.W))
        dut.io.opcode.poke(opcode)
        dut.clock.step()

        val result = dut.io.result.peek().litValue & 0xFFFFFFFFL

        if (printDebugInfo)
          println(f"[ALU_LogicTest] a=$a%08x b=$b%08x opcode=$opcode -> result=$result%08x expected=$expected%08x")

        assert(result == (expected & 0xFFFFFFFFL),
          s"[ALU_LogicTest] Expected 0x${(expected & 0xFFFFFFFFL).toString(16)} but got 0x${result.toString(16)} for opcode $opcode")
      }

      def testAnd(): Unit = {
        testOperation(0xF0F0F0F0L, 0x0FF00FF0L, Opcode.AND, 0x00F000F0L)
      }

      def testOr(): Unit = {
        testOperation(0xF0F0F0F0L, 0x0FF00FF0L, Opcode.OR, 0xFFF0FFF0L)
      }

      def testXor(): Unit = {
        testOperation(0xAAAA5555L, 0xFFFF0000L, Opcode.XOR, 0x55555555L)
      }

      testAnd()
      testOr()
      testXor()
    }
  }
}