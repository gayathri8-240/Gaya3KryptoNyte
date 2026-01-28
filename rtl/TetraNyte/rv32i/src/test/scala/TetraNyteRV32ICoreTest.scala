package TetraNyte

import chisel3._
import chisel3.simulator.EphemeralSimulator._
import org.scalatest.flatspec.AnyFlatSpec

class TetraNyteRV32ICoreTest extends AnyFlatSpec {
  "TetraNyteRV32ICore" should "simulate 4-threaded ALU, Load, Store, and Branch operations" in {
    simulate(new TetraNyteRV32ICore) { dut =>

      val numThreads = 4
      val threadPCs = Array.fill(numThreads)(0L)
      val nop = 0x00000013L

      // Enable all threads for this test
      dut.io.threadEnable.foreach(_.poke(true.B))

      val program = Seq[Long](
        0x00000013L, // NOP
        0x00100093L, // ADDI x1, x0, 1
        0x00208133L, // ADD  x2, x1, x2
        0x00310233L, // ADD  x4, x2, x3
        0x004182B3L, // ADD  x5, x3, x4
        0x00520333L, // ADD  x6, x4, x5
        0x006283B3L  // ADD  x7, x5, x6
      )
      val memResponses = Seq(0xAAAA0000L, 0x55550000L, 0xDEADBEAFL, 0xCAFEBABEL)

      var resetPC = 0L
      def instructionFor(pc: Long): Long = {
        val offset = pc - resetPC
        if (offset < 0 || offset % 4 != 0) nop
        else {
          val idx = (offset / 4).toInt
          if (idx >= 0 && idx < program.length) program(idx) else nop
        }
      }

      // Apply reset to get deterministic thread ordering and PC bases
      dut.reset.poke(true.B)
      dut.clock.step(2)
      dut.reset.poke(false.B)

      // Initialize PC view without advancing the scheduler
      for (t <- 0 until numThreads) {
        threadPCs(t) = dut.io.if_pc(t).peek().litValue.longValue
      }
      resetPC = threadPCs.head

      val pipelineLatency = 5
      // Run long enough to fetch and retire the full program for each thread
      val totalCycles = (program.length + pipelineLatency) * numThreads

      for (cycle <- 0 until totalCycles) {
        val fetchThread = dut.io.fetchThread.peek().litValue.toInt
        val instr = instructionFor(threadPCs(fetchThread))
        dut.io.instrMem.poke(instr.U)
        dut.io.dataMemResp.poke(memResponses(cycle % memResponses.length).U)

        dut.clock.step()

        for (t <- 0 until numThreads) {
          threadPCs(t) = dut.io.if_pc(t).peek().litValue.longValue
        }

        if (cycle >= pipelineLatency) {
          val if_pc    = dut.io.if_pc(fetchThread).peek().litValue
          val if_instr = dut.io.if_instr(fetchThread).peek().litValue
          val id_rs1   = dut.io.id_rs1Data(fetchThread).peek().litValue
          val id_rs2   = dut.io.id_rs2Data(fetchThread).peek().litValue
          val ex_alu   = dut.io.ex_aluResult(fetchThread).peek().litValue
          val mem_load = dut.io.mem_loadData(fetchThread).peek().litValue
          val mem_write= dut.io.memWrite.peek().litValue
          val mem_addr = dut.io.memAddr.peek().litValue

          println(f"[Cycle ${cycle - pipelineLatency}%02d][FetchT $fetchThread] " +
            f"PC: 0x$if_pc%08x instr: 0x$if_instr%08x RS1: 0x$id_rs1%08x RS2: 0x$id_rs2%08x " +
            f"ALU: 0x$ex_alu%08x Load: 0x$mem_load%08x Store: 0x$mem_write%08x MemAddr: 0x$mem_addr%08x")
        }
      }

      // Drain the pipeline so the last fetched instructions retire
      for (_ <- 0 until pipelineLatency) {
        dut.io.instrMem.poke(nop.U)
        dut.io.dataMemResp.poke(0.U)
        dut.clock.step()
        for (t <- 0 until numThreads) {
          threadPCs(t) = dut.io.if_pc(t).peek().litValue.longValue
        }
      }

      val expectedMinPC = resetPC + (program.length * 4)
      assert(threadPCs.forall(_ >= expectedMinPC), s"Each thread PC should advance at least program length; saw ${threadPCs.mkString(",")}")
    }
  }

  it should "branch on equal and take the correct path" in {
    simulate(new TetraNyteRV32ICore) { dut =>
      val numThreads = 4
      val threadPCs = Array.fill(numThreads)(0L)
      val nop = 0x00000013L

      // Enable all threads for this test
      dut.io.threadEnable.foreach(_.poke(true.B))

      // Simple branch program (thread 0)
      // 0x0  addi x1,x0,1
      // 0x4  addi x2,x0,1
      // 0x8  beq  x1,x2,+8 (to 0x10)
      // 0xc  addi x3,x0,0x00ad   (should be skipped)
      // 0x10 addi x3,x0,0x00be   (should execute)
      // 0x14 sw   x3,0(x0)       (store expected 0x000000be)
      // 0x18 nop
      val program = Seq[Long](
        0x00100093L, // addi x1,x0,1
        0x00100113L, // addi x2,x0,1
        0x00208263L, // beq x1,x2,+8 (to 0x10)
        0x0ad00193L, // addi x3,x0,0x00ad (skip)
        0x0be00193L, // addi x3,x0,0x00be (take)
        0x00302023L, // sw x3,0(x0)
        0x00000013L  // nop
      )

      var resetPC = 0L
      // Prime pipeline after reset to get stable PCs
      def instructionFor(pc: Long): Long = {
        val offset = pc - resetPC
        if (offset < 0 || offset % 4 != 0) nop
        else {
          val idx = (offset / 4).toInt
          if (idx >= 0 && idx < program.length) program(idx) else nop
        }
      }

      dut.reset.poke(true.B)
      dut.clock.step(2) // reset asserted
      dut.reset.poke(false.B)

      // Let the core run a few cycles with NOPs so that if_pc reflects the post-reset base.
      for (_ <- 0 until 4) {
        dut.io.instrMem.poke(nop.U)
        dut.io.dataMemResp.poke(0.U)
        dut.clock.step()
      }
      for (t <- 0 until numThreads) {
        threadPCs(t) = dut.io.if_pc(t).peek().litValue.longValue
      }
      resetPC = threadPCs.min

      val pipelineLatency = 6
      val totalCycles = 200
      var targetSeen = false
      var observedStore: Option[Long] = None
      var storeBeSeen = false

      for (_ <- 0 until totalCycles) {
        val fetchThread = dut.io.fetchThread.peek().litValue.toInt
        val instr = instructionFor(threadPCs(fetchThread))
        dut.io.instrMem.poke(instr.U)
        dut.io.dataMemResp.poke(0.U)

        dut.clock.step()

        // Update PC view
        for (t <- 0 until numThreads) {
          threadPCs(t) = dut.io.if_pc(t).peek().litValue.longValue
        }

        // Track whether we hit the branch target and capture the first store data
        val pc0 = threadPCs(0)
        if (pc0 == resetPC + 0x10) targetSeen = true

        val memMask = dut.io.memMask.peek().litValue
        if (memMask != 0) {
          val storeData = dut.io.memWrite.peek().litValue.longValue
          if (observedStore.isEmpty) observedStore = Some(storeData)
          if (storeData == 0xbeL) storeBeSeen = true
        }
      }

      val expectedMinPC = resetPC + 0x1c
      assert(threadPCs(0) >= expectedMinPC, s"Thread 0 PC should advance past branch block; saw ${threadPCs(0)}")
      assert(targetSeen, s"Branch target PC was not observed at 0x${(resetPC + 0x10).toHexString}")
      assert(storeBeSeen, s"Expected to observe a store of 0xbe when branch is taken; first store seen: ${observedStore}")
    }
  }
}
