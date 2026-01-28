package ZeroNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class ICacheSimpleTest extends AnyFlatSpec {

  behavior of "ICacheSimple"

  it should "return a word immediately when memory is combinational (fast path)" in {
    simulate(new ICacheSimple(new ICacheSimpleConfig(64, 16, 1))) { dut =>
      val mask32 = 0xFFFFFFFFL

      // reset
      dut.reset.poke(true.B)
      dut.clock.step()
      dut.reset.poke(false.B)

      // Drive a PC aligned to block base (wordOffset = 0)
      val pc = 0x80000000L
      val testWord = 0xdeadbeefL

      dut.io.pc.poke(pc.U)
      dut.io.pc_valid.poke(true.B)
      // combinational memory provides data immediately
      dut.io.mem_rvalid.poke(true.B)
      dut.io.mem_rdata.poke(testWord.U(32.W))

      // Because the cache supports a combinational fast path, the instruction
      // should be returned immediately without waiting for a fill.
      val observed = dut.io.instr.peek().litValue.toLong & mask32
      val valid = dut.io.instr_valid.peek().litValue == 1
      assert(valid, "instr_valid should be true on fast path")
      assert(observed == (testWord & mask32), f"Expected 0x${testWord.toHexString}, got 0x${observed.toHexString}")

      // step one cycle to advance internal state
      dut.clock.step()
    }
  }

  it should "perform a multi-cycle block fill and then hit on subsequent fetch" in {
    simulate(new ICacheSimple(new ICacheSimpleConfig(64, 16, 1))) { dut =>
      val mask32 = 0xFFFFFFFFL

      // reset
      dut.reset.poke(true.B)
      dut.clock.step()
      dut.reset.poke(false.B)

      val pc = 0x80000000L
      dut.io.pc.poke(pc.U)
      dut.io.pc_valid.poke(true.B)

      // Ensure memory does not provide combinational data so a miss occurs
      dut.io.mem_rvalid.poke(false.B)
      dut.io.mem_rdata.poke(0.U)

      // Request fetch -> will schedule a multi-cycle fill (state will become sMiss)
      dut.clock.step()

      // sMiss -> on next cycle the module will enter sFill
      dut.clock.step()

      // Now in sFill: provide words for the whole block (wordsPerLine = 4)
      val baseWord = 0x1000L
      val wordsPerLine = 4
      for (i <- 0 until wordsPerLine) {
        dut.io.mem_rvalid.poke(true.B)
        dut.io.mem_rdata.poke((baseWord + i).U(32.W))
        // advance one cycle to accept this word
        dut.clock.step()
      }

      // After the final word the cache should have completed the fill and
      // provided the requested instruction (wordOffset = 0 -> baseWord)
      val observed = dut.io.instr.peek().litValue.toLong & mask32
      val valid = dut.io.instr_valid.peek().litValue == 1
      assert(valid, "instr_valid should be true after block fill")
      assert(observed == (baseWord & mask32), f"Expected 0x${baseWord.toHexString}, got 0x${observed.toHexString}")

      // Advance one cycle so valid/tag registers are committed, then issue
      // another fetch to the same PC and ensure it's a cache hit (no mem_rvalid needed)
      dut.clock.step()
      dut.io.mem_rvalid.poke(false.B)
      dut.io.pc_valid.poke(true.B)
      // combinational hit path should return the same word
      val hitObserved = dut.io.instr.peek().litValue.toLong & mask32
      val hitValid = dut.io.instr_valid.peek().litValue == 1
      assert(hitValid, "instr_valid should be true on cache hit")
      assert(hitObserved == (baseWord & mask32), f"Expected 0x${baseWord.toHexString}, got 0x${hitObserved.toHexString}")
    }
  }
}