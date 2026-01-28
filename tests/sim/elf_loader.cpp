#include "elf_loader.h"

#include <cstring>
#include <fstream>
#include <stdexcept>
#include <vector>

namespace {

constexpr uint32_t kElfMagic0 = 0x7f;
constexpr uint32_t kElfMagic1 = 'E';
constexpr uint32_t kElfMagic2 = 'L';
constexpr uint32_t kElfMagic3 = 'F';

struct Elf32_Ehdr {
  unsigned char e_ident[16];
  uint16_t e_type;
  uint16_t e_machine;
  uint32_t e_version;
  uint32_t e_entry;
  uint32_t e_phoff;
  uint32_t e_shoff;
  uint32_t e_flags;
  uint16_t e_ehsize;
  uint16_t e_phentsize;
  uint16_t e_phnum;
  uint16_t e_shentsize;
  uint16_t e_shnum;
  uint16_t e_shstrndx;
};

struct Elf32_Phdr {
  uint32_t p_type;
  uint32_t p_offset;
  uint32_t p_vaddr;
  uint32_t p_paddr;
  uint32_t p_filesz;
  uint32_t p_memsz;
  uint32_t p_flags;
  uint32_t p_align;
};

struct Elf32_Shdr {
  uint32_t sh_name;
  uint32_t sh_type;
  uint32_t sh_flags;
  uint32_t sh_addr;
  uint32_t sh_offset;
  uint32_t sh_size;
  uint32_t sh_link;
  uint32_t sh_info;
  uint32_t sh_addralign;
  uint32_t sh_entsize;
};

struct Elf32_Sym {
  uint32_t st_name;
  uint32_t st_value;
  uint32_t st_size;
  unsigned char st_info;
  unsigned char st_other;
  uint16_t st_shndx;
};

enum : uint32_t {
  PT_LOAD = 1,
  SHT_SYMTAB = 2,
};

std::vector<uint8_t> readFile(const std::string& path) {
  std::ifstream file(path, std::ios::binary);
  if (!file.is_open()) {
    throw std::runtime_error("failed to open ELF: " + path);
  }
  std::vector<uint8_t> buffer((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
  return buffer;
}

template <typename T>
T readStruct(const std::vector<uint8_t>& data, uint32_t offset) {
  if (offset + sizeof(T) > data.size()) {
    throw std::runtime_error("ELF parse error: truncated file");
  }
  T value{};
  std::memcpy(&value, data.data() + offset, sizeof(T));
  return value;
}

}  // namespace

void loadElfIntoMemory(const std::string& path, Memory& memory, ElfSymbols& symbols) {
  const auto image = readFile(path);
  const Elf32_Ehdr ehdr = readStruct<Elf32_Ehdr>(image, 0);

  if (ehdr.e_ident[0] != kElfMagic0 || ehdr.e_ident[1] != kElfMagic1 ||
      ehdr.e_ident[2] != kElfMagic2 || ehdr.e_ident[3] != kElfMagic3) {
    throw std::runtime_error("invalid ELF magic");
  }
  if (ehdr.e_ident[4] != 1 || ehdr.e_ident[5] != 1) {
    throw std::runtime_error("unsupported ELF format");
  }

  for (uint16_t i = 0; i < ehdr.e_phnum; ++i) {
    const uint32_t offset = ehdr.e_phoff + i * ehdr.e_phentsize;
    const Elf32_Phdr phdr = readStruct<Elf32_Phdr>(image, offset);
    if (phdr.p_type != PT_LOAD) {
      continue;
    }
    for (uint32_t byte = 0; byte < phdr.p_filesz; ++byte) {
      const uint32_t src_index = phdr.p_offset + byte;
      if (src_index >= image.size()) {
        throw std::runtime_error("ELF segment exceeds file size");
      }
      memory.write8(phdr.p_paddr + byte, image[src_index]);
    }
    for (uint32_t byte = phdr.p_filesz; byte < phdr.p_memsz; ++byte) {
      memory.write8(phdr.p_paddr + byte, 0);
    }
  }

  const Elf32_Shdr shdr_symtab = [&]() -> Elf32_Shdr {
    for (uint16_t i = 0; i < ehdr.e_shnum; ++i) {
      const uint32_t off = ehdr.e_shoff + i * ehdr.e_shentsize;
      const Elf32_Shdr shdr = readStruct<Elf32_Shdr>(image, off);
      if (shdr.sh_type == SHT_SYMTAB) {
        return shdr;
      }
    }
    throw std::runtime_error("ELF missing symbol table");
  }();

  const Elf32_Shdr shdr_strtab = readStruct<Elf32_Shdr>(image, ehdr.e_shoff + shdr_symtab.sh_link * ehdr.e_shentsize);
  const uint32_t sym_count = shdr_symtab.sh_size / shdr_symtab.sh_entsize;

  for (uint32_t idx = 0; idx < sym_count; ++idx) {
    const uint32_t sym_off = shdr_symtab.sh_offset + idx * shdr_symtab.sh_entsize;
    const Elf32_Sym sym = readStruct<Elf32_Sym>(image, sym_off);
    const uint32_t name_off = shdr_strtab.sh_offset + sym.st_name;
    if (name_off >= image.size()) {
      continue;
    }

    const char* name = reinterpret_cast<const char*>(image.data() + name_off);
    if (std::strcmp(name, "tohost") == 0) {
      symbols.tohost = sym.st_value;
    } else if (std::strcmp(name, "fromhost") == 0) {
      symbols.fromhost = sym.st_value;
    } else if (std::strcmp(name, "begin_signature") == 0) {
      symbols.begin_signature = sym.st_value;
    } else if (std::strcmp(name, "end_signature") == 0) {
      symbols.end_signature = sym.st_value;
    }
  }

  if (symbols.tohost == 0 || symbols.begin_signature == 0 || symbols.end_signature == 0) {
    throw std::runtime_error("required ELF symbols missing");
  }
}
