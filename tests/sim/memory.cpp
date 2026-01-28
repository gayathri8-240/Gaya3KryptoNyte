#include "memory.h"

#include <fstream>
#include <iomanip>
#include <stdexcept>

Memory::Memory(uint32_t base_addr, uint32_t size_bytes)
    : base_(base_addr), size_(size_bytes) {}

uint8_t Memory::read8(uint32_t addr) const {
  auto it = data_.find(addr);
  if (it == data_.end()) {
    return 0;
  }
  return it->second;
}

uint32_t Memory::read32(uint32_t addr) const {
  uint32_t value = 0;
  for (int i = 0; i < 4; ++i) {
    value |= static_cast<uint32_t>(read8(addr + i)) << (8 * i);
  }
  return value;
}

void Memory::write8(uint32_t addr, uint8_t data) {
  data_[addr] = data;
}

void Memory::write32(uint32_t addr, uint32_t data) {
  for (int i = 0; i < 4; ++i) {
    write8(addr + i, static_cast<uint8_t>((data >> (8 * i)) & 0xFFu));
  }
}

void Memory::dumpSignature(uint32_t begin, uint32_t end, const std::string& path) const {
  if (end <= begin) {
    throw std::runtime_error("invalid signature bounds");
  }
  std::ofstream out(path);
  if (!out.is_open()) {
    throw std::runtime_error("failed to open signature file");
  }
  out << std::hex;
  for (uint32_t addr = begin; addr < end; addr += 4) {
    const uint32_t value = read32(addr);
    out << std::setfill('0') << std::setw(8) << value << '\n';
  }
}
