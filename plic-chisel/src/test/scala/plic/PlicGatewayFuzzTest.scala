import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec

import scala.util.Random

class XplicGatewayFuzzTest extends AnyFlatSpec with ChiselScalatestTester {
  "PlicGateway" should "match a cycle-accurate reference model under random stimuli" in {
    val rnd = new Random(67890L)
    val maxPending = 3
    test(new plic.PlicGateway(maxPendingCount = maxPending)) { c =>
      // reset sequence (active-low rst_n, async reset)
      c.io.rst_n.poke(false.B); c.clock.step(); c.io.rst_n.poke(true.B); c.clock.step()

      // cycle-accurate reference model state (matches PlicGateway.scala update ordering)
      var src_dly = false
      var src_edge_reg = false // models the Reg that holds edge detect in DUT
      var pending_cnt = 0
      var decr_pending = false
      var ip_state = 0 // 0 idle, 1 pending, 2 claimed

      def stepModel(src: Boolean, edge_lvl: Boolean, claim: Boolean, complete: Boolean): Unit = {
        // compute new src_edge (what the reg will be next cycle), but use current src_edge_reg
        val new_src_edge = src && !src_dly

        // compute nxt_pending_cnt based on current pending_cnt, current decr_pending, and current src_edge_reg
        val src_edge = src_edge_reg
        val nxt_pending = if (edge_lvl) {
          if (decr_pending && !src_edge) {
            math.max(pending_cnt - 1, 0)
          } else if (!decr_pending && src_edge) {
            math.min(pending_cnt + 1, maxPending)
          } else {
            pending_cnt
          }
        } else {
          0
        }

        // FSM uses nxt_pending to decide entering pending; this matches DUT where nxt_pending is
        // computed combinationally and consulted by FSM in the same cycle.
        var next_ip_state = ip_state
        var next_decr_pending = false
        ip_state match {
          case 0 =>
            if ((edge_lvl && nxt_pending != 0) || (!edge_lvl && src)) {
              next_ip_state = 1
              next_decr_pending = true
            }
          case 1 =>
            if (claim) next_ip_state = 2
          case 2 =>
            if (complete) next_ip_state = 0
        }

        // commit registers at end of cycle (src_dly, src_edge_reg, pending_cnt, decr_pending, ip_state)
        src_dly = src
        src_edge_reg = new_src_edge
        pending_cnt = nxt_pending
        decr_pending = next_decr_pending
        ip_state = next_ip_state
      }

      // run random stimulus and check DUT vs model each cycle
      for (_ <- 0 until 1000) {
        val src = rnd.nextBoolean()
        val claim = rnd.nextBoolean()
        val complete = rnd.nextBoolean()
        val edge_mode = true

        // drive DUT inputs
        c.io.src.poke((if (src) 1 else 0).U)
        c.io.edge_lvl.poke((if (edge_mode) 1 else 0).U)
        c.io.claim.poke((if (claim) 1 else 0).U)
        c.io.complete.poke((if (complete) 1 else 0).U)

        // step reference model for this cycle (it models combinational nxt and then register commit)
        stepModel(src, edge_mode, claim, complete)

        // step DUT clock (registers update at clock edge)
        c.clock.step()

        // compare DUT outputs to model
        val dut_ip = c.io.ip.peek().litToBoolean
        val model_ip = (ip_state == 1)
        assert(dut_ip == model_ip, s"Mismatch ip: dut=$dut_ip model=$model_ip src=$src pending=$pending_cnt decr=$decr_pending claim=$claim complete=$complete")
      }
    }
  }
}
