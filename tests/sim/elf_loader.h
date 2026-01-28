#pragma once

#include <cstdint>
#include <string>

#include "memory.h"

struct ElfSymbols {
  uint32_t tohost = 0;
  uint32_t fromhost = 0;
  uint32_t begin_signature = 0;
  uint32_t end_signature = 0;
};

void loadElfIntoMemory(const std::string& path, Memory& memory, ElfSymbols& symbols);
