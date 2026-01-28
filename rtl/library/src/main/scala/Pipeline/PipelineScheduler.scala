package Pipeline

import chisel3._
import chisel3.util._

/**
  * Barrel scheduler that assigns threads to each pipeline stage in a round-robin fashion.
  *
  * @param numThreads Number of hardware threads supported.
  * @param stageCount Number of pipeline stages participating in the barrel (default 8).
  */
class PipelineScheduler(numThreads: Int, stageCount: Int = 8) extends Module {
  private val threadBits = log2Ceil(numThreads)

  val io = IO(new Bundle {
    val threadEnable = Input(Vec(numThreads, Bool()))
    val advance      = Input(Bool())
    val stageThreads = Output(Vec(stageCount, UInt(threadBits.W)))
    val stageValids  = Output(Vec(stageCount, Bool()))
    val threadSelect = Output(UInt(threadBits.W)) // fetch stage owner for convenience
  })

  val offset = RegInit(0.U(threadBits.W))
  when(io.advance) {
    offset := Mux(offset === (numThreads - 1).U, 0.U, offset + 1.U)
  }

  val extended = offset + numThreads.U((threadBits + 1).W)
  for (stage <- 0 until stageCount) {
    val owner = (extended - stage.U)((threadBits + 1) - 1, 0)
    val threadId = owner(threadBits - 1, 0)
    io.stageThreads(stage) := threadId
    io.stageValids(stage) := io.threadEnable(threadId)
  }

  io.threadSelect := io.stageThreads(0)
}
