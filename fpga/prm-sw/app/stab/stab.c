#include "common.h"
#include "util.h"
#include "rl.h"
#include "jtag.h"
#include "cp.h"
#include "dtm.h"
#include <stdlib.h>
#include "platform.h"

enum { BOARD_ultraZ, BOARD_zedboard, BOARD_zcu102, BOARD_sidewinder };
static const struct BoardConfig {
	char *name;
	int nr_core;
	uint32_t cache_size; // KB
	uint32_t mem_freq;   // Hz
} board_config [] = {
	[BOARD_ultraZ] = {"ultraZ", 2, 256, 8000000},
	[BOARD_zedboard] = {"zedboard", 3, 256, 8000000},
	[BOARD_zcu102] = {"zcu102", 4, 2048, 8000000},
	[BOARD_sidewinder] = {"sidewinder", 4, 2048, 8000000}
};

#define NR_BOARD (sizeof(board_config) / sizeof(board_config[0]))

void help() {
	printf("Usage: stab-fpga [board]\n");
	printf("Supported boards:\n");
	int i;
	for (i = 0; i < NR_BOARD; i ++) {
		printf("%s ", board_config[i].name);
	}
	printf("[default: %s]\n", board_config[0].name);
}

int main(int argc, char *argv[]) {
  int board_idx = 0;
  if (argc == 1) {
	  printf("No board is provided. Use ultraZ\n");
  }
  for (int i = 1; i < argc; i++) {
    char *arg = argv[i];
	if (strcmp(arg, "-h") == 0) {
		help();
		return 0;
	}
	for (int j = 0; j < NR_BOARD; j ++) {
		if (strcmp(arg, board_config[j].name) == 0) {
			board_idx = j;
			break;
		}
	}
  }

  init_platform(NULL, 0);

  reset_soft();

  init_dtm();

  uint32_t cache_usage_total_last = 0;
  const struct BoardConfig *bc = &board_config[board_idx];

  while (1) {
    int row;
	printf("==================================\n");
	uint32_t mem_read[4];    // 1 AXI transaction per unit
	uint32_t mem_write[4];
	uint32_t cache_access[4];
	uint32_t cache_miss[4];
	uint32_t cache_usage[4]; // 64Byte per unit

	const int stabIdx = 1;
	const int memCpIdx = 1;
	const int cacheCpIdx = 2;

    for (row = 0; row < bc->nr_core; row ++) {
      mem_read[row] = read_cp_reg(get_cp_addr(memCpIdx, stabIdx, 0, row));
      write_cp_reg(get_cp_addr(memCpIdx, stabIdx, 0, row), 0);
      mem_write[row] = read_cp_reg(get_cp_addr(memCpIdx, stabIdx, 1, row));
      write_cp_reg(get_cp_addr(memCpIdx, stabIdx, 1, row), 0);

      cache_access[row] = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 0, row));
      write_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 0, row), 0);
      cache_miss[row] = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 1, row));
      write_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 1, row), 0);

      cache_usage[row] = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 2, row));
    }

	uint32_t cache_usage_total = 0;
    for (row = 0; row < bc->nr_core; row ++) {
		uint32_t mem_total = mem_read[row] + mem_write[row];
      printf("[dsid = %d] # mem axi transaction: read = %d, write = %d, total = %d (%lf%%)\n"
			  "\t cache: access = %d, miss = %d (%lf%%), usage = %lfKB (%lf%%)\n", 
          row, mem_read[row], mem_write[row], mem_total, mem_total / (double)bc->mem_freq * 100,
		  cache_access[row], cache_miss[row],
		  (double)cache_miss[row] / (double)cache_access[row] * 100,
		  cache_usage[row] / 16.0, //  = * 64B / 1024.0
		  cache_usage[row] / 16.0 / bc->cache_size * 100
		  );
	  cache_usage_total += cache_usage[row];
    }
	printf("\t\t\ttotal cache usage = %lfKB\n", cache_usage_total / 16.0);
	if (cache_usage_total < cache_usage_total_last) {
		printf("Warning: total cache usage is decreasing, last = %lfKB\n",
				cache_usage_total_last / 16.0);
	}
	cache_usage_total_last = cache_usage_total;
    fflush(stdout);
    sleep(1);
  }

  finish_platform();
  return 0;
}
