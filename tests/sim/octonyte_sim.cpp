#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

#include "VOctoNyteRV32ICore.h"
#include "elf_loader.h"
#include "memory.h"
#include "verilated.h"

namespace {
struct Options {
  std::string elf;
  std::string signature;
  std::string log;
  uint64_t max_cycles = 1'000'000;
  bool trace_stage = false;
  uint32_t thread_mask = 0x1;  // enable only thread 0 by default
};

Options parseArgs(int argc, char** argv) {
  Options opts;
  for (int i = 1; i < argc; ++i) {
    const std::string arg(argv[i]);
    if (arg == "--elf" && i + 1 < argc) {
      opts.elf = argv[++i];
    } else if (arg == "--signature" && i + 1 < argc) {
      opts.signature = argv[++i];
    } else if (arg == "--log" && i + 1 < argc) {
      opts.log = argv[++i];
    } else if (arg == "--max-cycles" && i + 1 < argc) {
      opts.max_cycles = std::stoull(argv[++i]);
    } else if (arg == "--thread-mask" && i + 1 < argc) {
      opts.thread_mask = static_cast<uint32_t>(std::stoul(argv[++i], nullptr, 0));
    } else if (arg == "--trace-stage") {
      opts.trace_stage = true;
    } else {
      throw std::invalid_argument("unknown or incomplete argument: " + arg);
    }
  }
  if (opts.elf.empty() || opts.signature.empty()) {
    throw std::invalid_argument("--elf and --signature are required");
  }
  return opts;
}

constexpr uint32_t kMemBase = 0x80000000u;
constexpr uint32_t kMemSize = 16 * 1024 * 1024;
constexpr int kResetCycles = 5;
constexpr int kNumThreads = 8;

void writeMasked(Memory& memory, uint32_t addr, uint32_t data, uint32_t mask) {
  for (int byte = 0; byte < 4; ++byte) {
    if ((mask >> byte) & 0x1) {
      memory.write8(addr + byte, static_cast<uint8_t>((data >> (8 * byte)) & 0xFFu));
    }
  }
}

}  // namespace

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  Options options;
  try {
    options = parseArgs(argc, argv);
  } catch (const std::exception& e) {
    std::cerr << "Argument error: " << e.what() << std::endl;
    return 1;
  }

  std::ofstream log;
  if (!options.log.empty()) {
    log.open(options.log);
  }

  Memory memory(kMemBase, kMemSize);
  ElfSymbols symbols;

  try {
    loadElfIntoMemory(options.elf, memory, symbols);
  } catch (const std::exception& e) {
    std::cerr << "ELF load failed: " << e.what() << std::endl;
    return 1;
  }

  VOctoNyteRV32ICore dut;

  std::array<uint32_t, kNumThreads> thread_pcs{};
  thread_pcs.fill(kMemBase);

  auto captureThreadPcs = [&]() {
    thread_pcs[0] = dut.io_debugPC_0;
    thread_pcs[1] = dut.io_debugPC_1;
    thread_pcs[2] = dut.io_debugPC_2;
    thread_pcs[3] = dut.io_debugPC_3;
    thread_pcs[4] = dut.io_debugPC_4;
    thread_pcs[5] = dut.io_debugPC_5;
    thread_pcs[6] = dut.io_debugPC_6;
    thread_pcs[7] = dut.io_debugPC_7;
  };

  auto driveThreadMask = [&]() {
    dut.io_threadEnable_0 = (options.thread_mask >> 0) & 0x1;
    dut.io_threadEnable_1 = (options.thread_mask >> 1) & 0x1;
    dut.io_threadEnable_2 = (options.thread_mask >> 2) & 0x1;
    dut.io_threadEnable_3 = (options.thread_mask >> 3) & 0x1;
    dut.io_threadEnable_4 = (options.thread_mask >> 4) & 0x1;
    dut.io_threadEnable_5 = (options.thread_mask >> 5) & 0x1;
    dut.io_threadEnable_6 = (options.thread_mask >> 6) & 0x1;
    dut.io_threadEnable_7 = (options.thread_mask >> 7) & 0x1;
  };

  uint32_t lastFetchThread = 0;
  bool lastFetchValid = false;
  auto driveInterfaces = [&]() {
    driveThreadMask();
    lastFetchThread = dut.io_debugStageThreads_0 & 0x7;
    lastFetchValid = dut.io_debugStageValids_0;

    uint32_t instr = 0x00000013;  // NOP
    if (lastFetchValid && ((options.thread_mask >> lastFetchThread) & 0x1)) {
      instr = memory.read32(thread_pcs[lastFetchThread]);
    }
    dut.io_instrMem[0U] = instr;
    dut.io_instrMem[1U] = 0;
    dut.io_instrMem[2U] = 0;
    dut.io_instrMem[3U] = 0;

    dut.io_dataMemResp = memory.read32(dut.io_memAddr);
  };

  // Reset
  dut.reset = 1;
  for (int cycle = 0; cycle < kResetCycles; ++cycle) {
    dut.clock = 0;
    driveInterfaces();
    dut.eval();
    captureThreadPcs();

    dut.clock = 1;
    driveInterfaces();
    dut.eval();
    captureThreadPcs();
  }
  dut.reset = 0;

  bool completed = false;
  uint32_t tohost_value = 0;

  for (uint64_t cycle = 0; cycle < options.max_cycles; ++cycle) {
    dut.clock = 0;
    driveInterfaces();
    dut.eval();
    captureThreadPcs();

    dut.clock = 1;
    driveInterfaces();
    dut.eval();
    captureThreadPcs();

    const uint32_t addr = dut.io_memAddr;
    const uint32_t data = dut.io_memWrite;
    const uint32_t mask = dut.io_memMask;
    if (mask != 0) {
      writeMasked(memory, addr, data, mask);
      if (addr == symbols.tohost && data != 0) {
        tohost_value = data;
        completed = true;
      }
    }

    if (log.is_open()) {
      log << std::hex
          << "cycle=0x" << cycle
          << " fetchThread=0x" << lastFetchThread
          << " fetchValid=" << lastFetchValid
          << " pc0=0x" << thread_pcs[0]
          << " pc1=0x" << thread_pcs[1]
          << " pc2=0x" << thread_pcs[2]
          << " pc3=0x" << thread_pcs[3]
          << " pc4=0x" << thread_pcs[4]
          << " pc5=0x" << thread_pcs[5]
          << " pc6=0x" << thread_pcs[6]
          << " pc7=0x" << thread_pcs[7]
          << " memAddr=0x" << addr
          << " memMask=0x" << mask
          << std::dec << '\n';

      if (dut.io_debugExecValid &&
          (dut.io_debugExecIsBranch || dut.io_debugExecIsJal || dut.io_debugExecIsJalr)) {
        log << std::hex << "exec1: thread=0x" << static_cast<unsigned>(dut.io_debugExecThread)
            << " pc=0x" << dut.io_debugExecPC
            << " instr=0x" << dut.io_debugExecInstr
            << " rs1=0x" << dut.io_debugExecRs1
            << " rs2=0x" << dut.io_debugExecRs2
            << " op=0x" << static_cast<unsigned>(dut.io_debugExecBranchOp)
            << " taken=" << static_cast<unsigned>(dut.io_debugExecCtrlTaken)
            << " target=0x" << dut.io_debugExecCtrlTarget
            << " branch=" << static_cast<unsigned>(dut.io_debugExecIsBranch)
            << " jal=" << static_cast<unsigned>(dut.io_debugExecIsJal)
            << " jalr=" << static_cast<unsigned>(dut.io_debugExecIsJalr)
            << std::dec << '\n';
      }

      if (dut.io_debugCtrlValid &&
          (dut.io_debugCtrlIsBranch || dut.io_debugCtrlIsJal || dut.io_debugCtrlIsJalr)) {
        log << std::hex << "wb: thread=0x" << static_cast<unsigned>(dut.io_debugCtrlThread)
            << " from=0x" << dut.io_debugCtrlFromPC
            << " instr=0x" << dut.io_debugCtrlInstr
            << " taken=" << static_cast<unsigned>(dut.io_debugCtrlTaken)
            << " target=0x" << dut.io_debugCtrlTarget
            << " branch=" << static_cast<unsigned>(dut.io_debugCtrlIsBranch)
            << " jal=" << static_cast<unsigned>(dut.io_debugCtrlIsJal)
            << " jalr=" << static_cast<unsigned>(dut.io_debugCtrlIsJalr)
            << std::dec << '\n';
      }
    }

    if (completed) {
      break;
    }
  }

  if (!completed) {
    std::cerr << "Simulation terminated: max cycles reached" << std::endl;
    return 3;
  }

  if (tohost_value != 1) {
    std::cerr << "Test reported failure, tohost=0x" << std::hex << tohost_value << std::dec << std::endl;
  }

  try {
    memory.dumpSignature(symbols.begin_signature, symbols.end_signature, options.signature);
  } catch (const std::exception& e) {
    std::cerr << "Signature dump failed: " << e.what() << std::endl;
    return 4;
  }

  return tohost_value == 1 ? 0 : 5;
}
