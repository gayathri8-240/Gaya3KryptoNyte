#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

#include "VZeroNyteRV32ICore.h"
#include "elf_loader.h"
#include "memory.h"
#include "verilated.h"

namespace {
struct Options {
  std::string elf;
  std::string signature;
  std::string log;
  uint64_t max_cycles = 1000000;
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

  VZeroNyteRV32ICore dut;

  auto applyMemory = [&]() {
    dut.io_imem_rdata = memory.read32(dut.io_imem_addr);
    dut.io_dmem_rdata = memory.read32(dut.io_dmem_addr);
  };

  // Reset
  dut.reset = 1;
  for (int cycle = 0; cycle < kResetCycles; ++cycle) {
    dut.clock = 0;
    applyMemory();
    dut.eval();
    dut.clock = 1;
    applyMemory();
    dut.eval();
  }
  dut.reset = 0;

  bool completed = false;
  uint32_t tohost_value = 0;

  for (uint64_t cycle = 0; cycle < options.max_cycles; ++cycle) {
    dut.clock = 0;
    applyMemory();
    dut.eval();

    dut.clock = 1;
    applyMemory();
    dut.eval();

    if (dut.io_dmem_wen) {
      const uint32_t addr = dut.io_dmem_addr;
      const uint32_t data = dut.io_dmem_wdata;
      try {
        memory.write32(addr, data);
      } catch (const std::exception& e) {
        std::cerr << "Memory write failed at 0x" << std::hex << addr << ": " << e.what() << std::endl;
        return 2;
      }
      if (addr == symbols.tohost && data != 0) {
        tohost_value = data;
        completed = true;
      }
    }

    if (log.is_open()) {
      log << std::hex
          << "cycle=0x" << cycle
          << " pc=0x" << dut.io_pc_out
          << " instr=0x" << dut.io_instr_out
          << " result=0x" << dut.io_result
          << std::dec << '\n';
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
