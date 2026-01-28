#include <array>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

#include "VTetraNyteRV32ICore.h"
#include "elf_loader.h"
#include "memory.h"
#include "verilated.h"

namespace {
struct Options {
  std::string elf;
  std::string signature;
  std::string log;
  uint64_t max_cycles = 1'000'000;
  bool trace_pc = false;
  uint32_t thread_mask = 0x1;  // bit per thread; default only thread 0 enabled
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
    } else if (arg == "--trace-pc") {
      opts.trace_pc = true;
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
constexpr int kNumThreads = 4;

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

  VTetraNyteRV32ICore dut;

  std::array<uint32_t, kNumThreads> thread_pcs{};
  thread_pcs.fill(kMemBase);

  // Apply thread mask to the DUT (bit i enables thread i)
  auto driveThreadMask = [&]() {
    dut.io_threadEnable_0 = (options.thread_mask >> 0) & 0x1;
    dut.io_threadEnable_1 = (options.thread_mask >> 1) & 0x1;
    dut.io_threadEnable_2 = (options.thread_mask >> 2) & 0x1;
    dut.io_threadEnable_3 = (options.thread_mask >> 3) & 0x1;
  };

  auto captureThreadPcs = [&]() {
    thread_pcs[0] = dut.io_if_pc_0;
    thread_pcs[1] = dut.io_if_pc_1;
    thread_pcs[2] = dut.io_if_pc_2;
    thread_pcs[3] = dut.io_if_pc_3;
  };

  auto driveMemory = [&]() {
    driveThreadMask();
    // Barrel fetch: feed each thread from its own PC if enabled; otherwise feed NOP.
    uint32_t ft = dut.io_fetchThread & 0x3;
    if ((options.thread_mask >> ft) & 0x1) {
      dut.io_instrMem = memory.read32(thread_pcs[ft]);
    } else {
      dut.io_instrMem = 0x00000013;  // NOP
    }
    dut.io_dataMemResp = memory.read32(dut.io_memAddr);
  };

  // Reset
  dut.reset = 1;
  captureThreadPcs();
  for (int cycle = 0; cycle < kResetCycles; ++cycle) {
    dut.clock = 0;
    driveMemory();
    dut.eval();
    captureThreadPcs();
    if (log.is_open() && dut.io_ctrlTaken) {
      log << std::hex << "ctrl: taken=1 "
          << "thread=" << static_cast<unsigned>(dut.io_ctrlThread)
          << " from=0x" << dut.io_ctrlFromPC
          << " target=0x" << dut.io_ctrlTarget
          << " branch=" << static_cast<unsigned>(dut.io_ctrlIsBranch)
          << " jal=" << static_cast<unsigned>(dut.io_ctrlIsJal)
          << " jalr=" << static_cast<unsigned>(dut.io_ctrlIsJalr)
          << std::dec << '\n';
    }
    dut.clock = 1;
    driveMemory();
    dut.eval();
    captureThreadPcs();
  }
  dut.reset = 0;

  bool completed = false;
  uint32_t tohost_value = 0;

  for (uint64_t cycle = 0; cycle < options.max_cycles; ++cycle) {
    dut.clock = 0;
    driveMemory();
    dut.eval();
    captureThreadPcs();

    dut.clock = 1;
    driveMemory();
    dut.eval();
    captureThreadPcs();
    if (log.is_open()) {
      log << std::hex << "pcs post-eval: "
          << "pc0=0x" << dut.io_if_pc_0 << " "
          << "pc1=0x" << dut.io_if_pc_1 << " "
          << "pc2=0x" << dut.io_if_pc_2 << " "
          << "pc3=0x" << dut.io_if_pc_3
          << " en=[" << static_cast<unsigned>(dut.io_threadEnable_0)
          << static_cast<unsigned>(dut.io_threadEnable_1)
          << static_cast<unsigned>(dut.io_threadEnable_2)
          << static_cast<unsigned>(dut.io_threadEnable_3) << "]"
          << std::dec << '\n';

      if (dut.io_ctrlTaken) {
        log << std::hex << "ctrl: taken=1 "
            << "thread=" << static_cast<unsigned>(dut.io_ctrlThread)
            << " from=0x" << dut.io_ctrlFromPC
            << " target=0x" << dut.io_ctrlTarget
            << " branch=" << static_cast<unsigned>(dut.io_ctrlIsBranch)
            << " jal=" << static_cast<unsigned>(dut.io_ctrlIsJal)
            << " jalr=" << static_cast<unsigned>(dut.io_ctrlIsJalr)
            << std::dec << '\n';
      }
    }

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
          << " memAddr=0x" << addr
          << " mask=0x" << mask
          << " tohost=0x" << symbols.tohost;
      if (options.trace_pc) {
      log << " pc0=0x" << thread_pcs[0]
          << " pc1=0x" << thread_pcs[1]
          << " pc2=0x" << thread_pcs[2]
          << " pc3=0x" << thread_pcs[3]
          << " instr0=0x" << dut.io_if_instr_0
          << " instr1=0x" << dut.io_if_instr_1
          << " instr2=0x" << dut.io_if_instr_2
          << " instr3=0x" << dut.io_if_instr_3
          << " ft=" << static_cast<unsigned>(dut.io_fetchThread);
      }
      log << std::dec << '\n';
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
