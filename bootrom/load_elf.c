#include "elf.h"

#define SIM_MEM_BASE 0x30000000
#define assert(cond) do { \
  if (!(cond)) while (1); \
} while (0)

static inline void my_memcpy(uint8_t *dst, uint8_t *src, uintptr_t len) {
  while ((uintptr_t)dst % 8 != 0) {
    *(dst ++) = *(src ++);
    len --;
  }

  len = (len + 7) / 8;
  uintptr_t i;
  for (i = 0; i < len; i ++) {
    ((uint64_t *)dst)[i] = ((uint64_t *)src)[i];
  }
}

static inline void memzero(uint8_t *dst, uintptr_t len) {
  while ((uintptr_t)dst % 8 != 0) {
    *(dst ++) = 0;
    len --;
  }

  len = (len + 7) / 8;
  uintptr_t i;
  for (i = 0; i < len; i ++) {
    ((uint64_t *)dst)[i] = 0;
  }
}

uintptr_t load_elf() {
  Elf64_Ehdr *elf = (void *)SIM_MEM_BASE;
  uint8_t *p = elf->e_ident;
  assert(p[0] == ELFMAG0 && p[1] == ELFMAG1 && p[2] == ELFMAG2 && p[3] == ELFMAG3);

  Elf64_Phdr *ph = (void *)SIM_MEM_BASE + elf->e_phoff;
  int i;
  for (i = 0; i < elf->e_phnum; i ++) {
    if (ph[i].p_type & PT_LOAD) {
      my_memcpy((void *)ph[i].p_vaddr, (void *)SIM_MEM_BASE + ph[i].p_offset, ph[i].p_filesz);
      memzero((void *)ph[i].p_vaddr + ph[i].p_filesz, ph[i].p_memsz - ph[i].p_filesz);
    }
  }

  return elf->e_entry;
}
