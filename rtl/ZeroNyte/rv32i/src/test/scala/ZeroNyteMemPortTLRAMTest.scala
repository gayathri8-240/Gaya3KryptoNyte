package ZeroNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import TileLink._
import org.scalatest.flatspec.AnyFlatSpec

class ZeroNyteMemPortTLRAMTest extends AnyFlatSpec {
  "ZeroNyteMemPort + TLRAM" should "store then load the same word via TL-UL" in {
    class Harness extends Module {
      val io = IO(new Bundle {
        val valid    = Input(Bool())
        val addr     = Input(UInt(32.W))
        val wdata    = Input(UInt(32.W))
        val wmask    = Input(UInt(4.W))
        val loadData = Output(UInt(32.W))
      })
      val mp = Module(new ZeroNyteMemPort())
      val ram = Module(new TLRAM())
      ram.io.tl <> mp.io.tl

      mp.io.passthroughMem.readData := 0.U
      mp.io.legacy.addr := io.addr
      mp.io.legacy.writeData := io.wdata
      mp.io.legacy.writeMask := io.wmask
      mp.io.legacy.valid := io.valid

      io.loadData := mp.io.legacy.readData
    }

    simulate(new Harness) { dut =>
      def stepIdle(): Unit = {
        dut.io.valid.poke(false.B)
        dut.io.wmask.poke(0.U)
        dut.io.wdata.poke(0.U)
        dut.io.addr.poke(0.U)
        dut.clock.step()
      }

      // Store word 0xdeadbeef to address 0
      dut.io.valid.poke(true.B)
      dut.io.addr.poke(0.U)
      dut.io.wdata.poke("hdeadbeef".U)
      dut.io.wmask.poke("b1111".U)
      dut.clock.step()

      // Let the AccessAck drain
      stepIdle()

      // Issue load from address 0
      dut.io.valid.poke(true.B)
      dut.io.addr.poke(0.U)
      dut.io.wdata.poke(0.U)
      dut.io.wmask.poke(0.U)
      dut.clock.step()

      // Allow the AccessAckData to return
      stepIdle()

      dut.io.loadData.expect("hdeadbeef".U)
    }
  }
}
