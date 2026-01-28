package ALUs

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import ALUs.ALU32.Opcode

class ALU_CompareTest extends AnyFlatSpec {

  "ALU32" should "correctly perform signed and unsigned comparisons" in {
    simulate(new ALU32) { dut =>
      val printDebugInfo = false

      // Drop-in patch: handle signed vs unsigned pokes automatically
      def testOperation(a: BigInt, b: BigInt, opcode: UInt, expected: BigInt): Unit = {
        def pokeValue(x: BigInt): UInt = {
        val wrapped = if (x < 0) (BigInt(1) << 32) + x else x  // wrap negatives properly
        wrapped.U(32.W)
      }


        dut.io.a.poke(pokeValue(a))
        dut.io.b.poke(pokeValue(b))
        dut.io.opcode.poke(opcode)
        dut.clock.step()

        val result = dut.io.result.peek().litValue & 0xFFFFFFFFL

        if (printDebugInfo)
          println(f"[ALU_CompareTest] a=$a%08x b=$b%08x opcode=$opcode -> result=$result%08x expected=$expected%08x")

        assert(result == (expected & 0xFFFFFFFFL),
          s"[ALU_CompareTest] Expected 0x${(expected & 0xFFFFFFFFL).toString(16)} but got 0x${result.toString(16)} for opcode $opcode")
      }

      def testSignedComparison(): Unit = {
        // SLT (signed less than)
        testOperation(-5, 3, Opcode.SLT, 1)  // -5 < 3 → true
        testOperation(10, 2, Opcode.SLT, 0)  // 10 < 2 → false
      }

      def testUnsignedComparison(): Unit = {
        // SLTU (unsigned less than)
        testOperation(0xFFFFFFF0L, 1, Opcode.SLTU, 0)  // 0xFFFFFFF0 > 1 → false
        testOperation(4, 9, Opcode.SLTU, 1)            // 4 < 9 → true
      }

      testSignedComparison()
      testUnsignedComparison()
    }
  }
}