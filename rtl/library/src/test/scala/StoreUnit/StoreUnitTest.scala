// Licensed under the BSD 3-Clause License. 
// See https://opensource.org/licenses/BSD-3-Clause for details.

package StoreUnit   // must match module’s package

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers

class StoreUnitTest extends AnyFlatSpec with Matchers {

  "StoreUnit" should "correctly store data" in {
    // Test Case 1: SB (store byte, storeType=0)
    simulate(new StoreUnit()) { c =>
      c.io.addr.poke(0x1000.U)
      c.io.data.poke("h00FF00FF".U)
      c.io.storeType.poke(0.U)  // SB
      c.clock.step(1)
      c.io.memWrite.expect("h000000FF".U) // lowest byte stored
    }

    // Test Case 2: SH (store halfword, storeType=1)
    simulate(new StoreUnit()) { c =>
        c.io.addr.poke(0x1004.U)       
        c.io.data.poke("h00FF00FF".U)
        c.io.storeType.poke(1.U)  // SH
        c.clock.step(1)
        c.io.memWrite.expect("h000000FF".U) // ✅ only low halfword, matches module
        }

    // Test Case 3: SW (store word, storeType=2)
    simulate(new StoreUnit()) { c =>
      c.io.addr.poke(0x1008.U)
      c.io.data.poke("h12345678".U)
      c.io.storeType.poke(2.U)  // SW
      c.clock.step(1)
      c.io.memWrite.expect("h12345678".U) // full word stored
    }

    // Test Case 4: Invalid storeType (default case)
    simulate(new StoreUnit()) { c =>
      c.io.addr.poke(0x1010.U)
      c.io.data.poke("hDEADBEEF".U)
      c.io.storeType.poke(3.U)  // invalid
      c.clock.step(1)
      c.io.memWrite.expect("h00000000".U) // no data written
    }
  }
}