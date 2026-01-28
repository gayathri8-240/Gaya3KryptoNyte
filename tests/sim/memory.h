#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>

class Memory {
 public:
  Memory(uint32_t base_addr, uint32_t size_bytes);

  uint8_t read8(uint32_t addr) const;
  uint32_t read32(uint32_t addr) const;

  void write8(uint32_t addr, uint8_t data);
  void write32(uint32_t addr, uint32_t data);

  void dumpSignature(uint32_t begin, uint32_t end, const std::string& path) const;

 private:
  uint32_t base_;
  uint32_t size_;
  std::unordered_map<uint32_t, uint8_t> data_;
};
