package ZeroNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import Bridges.{AXI4LiteToAHBLite, TLToAXI4Lite}
import AHB.AHBLiteRAM

class ZeroNyteMemPortAXIToAHBTest extends AnyFlatSpec {
  "ZeroNyteMemPort + TL->AXI4-Lite->AHB-Lite" should "store then load the same word" in {
    class Harness extends Module {
      val io = IO(new Bundle {
        val valid    = Input(Bool())
        val addr     = Input(UInt(32.W))
        val wdata    = Input(UInt(32.W))
        val wmask    = Input(UInt(4.W))
        val loadData = Output(UInt(32.W))
      })

      val mp = Module(new ZeroNyteMemPort())
      val tlToAxi = Module(new TLToAXI4Lite())
      val axiToAhb = Module(new AXI4LiteToAHBLite())
      val ram = Module(new AHBLiteRAM())

      mp.io.passthroughMem.readData := 0.U
      mp.io.legacy.valid := io.valid
      mp.io.legacy.addr := io.addr
      mp.io.legacy.writeData := io.wdata
      mp.io.legacy.writeMask := io.wmask

      tlToAxi.io.tl <> mp.io.tl
      axiToAhb.io.axi <> tlToAxi.io.axi
      ram.io.ahb <> axiToAhb.io.ahb

      io.loadData := mp.io.legacy.readData
    }

    simulate(new Harness) { dut =>
      def stepIdle(cycles: Int): Unit = {
        for (_ <- 0 until cycles) {
          dut.io.valid.poke(false.B)
          dut.io.addr.poke(0.U)
          dut.io.wdata.poke(0.U)
          dut.io.wmask.poke(0.U)
          dut.clock.step()
        }
      }

      // Store word
      dut.io.valid.poke(true.B)
      dut.io.addr.poke(0.U)
      dut.io.wdata.poke("hdeadbeef".U)
      dut.io.wmask.poke("b1111".U)
      dut.clock.step()

      stepIdle(4)

      // Load word
      dut.io.valid.poke(true.B)
      dut.io.addr.poke(0.U)
      dut.io.wdata.poke(0.U)
      dut.io.wmask.poke(0.U)
      dut.clock.step()

      stepIdle(4)

      dut.io.loadData.expect("hdeadbeef".U)
    }
  }
}
