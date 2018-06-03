#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <memory.h>
#include <unistd.h>  
#include <sys/mman.h>  
#include <sys/types.h>  
#include <sys/stat.h>  
#include <fcntl.h>
#include <elf.h>

#include <assert.h>
#include <sys/time.h>
#include <time.h>

#include "platform.h"
#include "dtm.h"

enum { BOARD_ultraZ, BOARD_zedboard, BOARD_zcu102, BOARD_sidewinder };
static const struct BoardConfig {
  char *name;
  uintptr_t ddr_size;
  uintptr_t ddr_base;
  uintptr_t gpio_reset_base;
} board_config [] = {
  [BOARD_ultraZ] = {"ultraZ", 0x40000000, 0x40000000, 0x80010000},
  [BOARD_zedboard] = {"zedboard", 0x10000000, 0x100000000, 0x41200000},
  [BOARD_zcu102] = {"zcu102", 0x80000000, 0x800000000, 0x80010000},
  [BOARD_sidewinder] = {"sidewinder", 0x80000000, 0x800000000, 0x80010000}
};

#define NR_BOARD (sizeof(board_config) / sizeof(board_config[0]))

const struct BoardConfig *bc;

#define GPIO_RESET_TOTAL_SIZE	0x1000

void *ddr_base;
volatile uint32_t *gpio_reset_base;
int	fd;

static inline void my_fread(char *filename, uint64_t *addr) {
  FILE *fp = fopen(filename, "rb");
  assert(fp);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);
  printf("sizeof(%s) = %ld\n", filename, size);

  fseek(fp, 0, SEEK_SET);

  uint64_t v;
  long i;
  size = (size + 7) / 8;
  for (i = 0; i < size; i ++) {
    fread(&v, 8, 1, fp);
    addr[i] = v;
  }

  fclose(fp);
}

void loader(char *imgfile, char *dtbfile, uintptr_t offset) {
  my_fread(imgfile, ddr_base + offset);
  my_fread(dtbfile, ddr_base + offset + 0x8);
}

void* create_map(size_t size, int fd, off_t offset) {
  void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);

  if (base == MAP_FAILED) {
    perror("init_mem mmap failed:");
    close(fd);
    exit(1);
  }

  printf("mapping paddr 0x%lx to vaddr 0x%lx\n", offset, (uintptr_t)base);

  return base;
}

void init_ddr_map() {
  fd = open("/dev/mem", O_RDWR|O_SYNC);  
  if (fd == -1)  {  
    perror("init_map open failed:");
    exit(1);
  } 

  printf("board = %s, ddr_size = %lx, ddr_base = %lx\n", bc->name, bc->ddr_size, bc->ddr_base);
  ddr_base = create_map(bc->ddr_size, fd, bc->ddr_base);
}

void finish_ddr_map() {
  munmap((void *)ddr_base, bc->ddr_size);
  close(fd);
}

void help() {
  printf("Usage: axi-loader reset hard\n");
  printf("       axi-loader reset start [hardid]\n");
  printf("       axi-loader reset end [hardid]\n");
  printf("       axi-loader [board] [bin] [configstr] [ddr_offset]\n");
  printf("Supported boards:\n");
  int i;
  for (i = 0; i < NR_BOARD; i ++) {
    printf("%s ", board_config[i].name);
  }
}

int main(int argc, char *argv[]) {
  init_platform(NULL, 0);

  if (argc > 1 && strcmp(argv[1], "-h") == 0) {
    help();
    return 0;
  }

  if (argc > 1 && strcmp(argv[1], "reset") == 0) {
    if (argc > 2) {
      if (strcmp(argv[2], "hard") == 0) {
        resetn(0);
        resetn(1);
      }
      else if (argc > 3) {
        char *p;
        uint64_t addr;
        int hartid = strtoll(argv[3], &p, 0);
        if (!(argv[3][0] != '\0' && *p == '\0')) {
          printf("invalid hartid = %s\n", argv[3]);
          help();
          exit(1);
        }

        if (strcmp(argv[2], "start") == 0) {
          addr = 0x1000;
        }
        else if (strcmp(argv[2], "end") == 0) {
          addr = 0x100000000;
        }
        else {
          printf("invalid reset command = %s\n", argv[2]);
          help();
          exit(1);
        }

        start_program(hartid, addr);
      }
      else {
        help();
      }
    }
  }
  else {
    uintptr_t offset = 0;
    if (argc > 4) {
      char *p;
      offset = strtoll(argv[4], &p, 0);
      if (!(argv[4][0] != '\0' && *p == '\0')) {
        printf("invalid offset = %s, set offset = 0\n", argv[4]);
        offset = 0;
      }
    }

    int j;
    for (j = 0; j < NR_BOARD; j ++) {
      if (strcmp(argv[1], board_config[j].name) == 0) {
        bc = &board_config[j];
        break;
      }
    }
    if (j == NR_BOARD) {
      printf("invalid board = %s\n", argv[1]);
      help();
      exit(1);
    }

    init_ddr_map();
    Log("loading %s and %s to offset = 0x%lx", argv[2], argv[3], offset);
    loader(argv[2], argv[3], offset);
    finish_ddr_map();
  }

  finish_platform();

  return 0; 
} 
