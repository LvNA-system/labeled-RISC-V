#include "common.h"
#include "util.h"
#include "rl.h"
#include "jtag.h"
#include "cp.h"
#include "dtm.h"
#include <stdlib.h>
#include "platform.h"
#include <math.h>

enum { BOARD_ultraZ, BOARD_zedboard, BOARD_zcu102, BOARD_sidewinder };
static const struct BoardConfig {
  char *name;
  int nr_core;
  uint32_t cache_size; // KB
  uint32_t uncore_freq;// Hz
} board_config [] = {
  [BOARD_ultraZ] = {"ultraZ", 2, 256, 100000000},
  [BOARD_zedboard] = {"zedboard", 2, 256, 30000000},
  [BOARD_zcu102] = {"zcu102", 4, 2048, 100000000},
  [BOARD_sidewinder] = {"sidewinder", 4, 2048, 100000000}
};

#define NR_BOARD (sizeof(board_config) / sizeof(board_config[0]))

struct StabData {
  uint32_t cached_tl_bw;    // 1 TL transaction per unit
  uint32_t uncached_tl_bw;
  uint32_t cache_access;
  uint32_t cache_miss;
  uint32_t cache_usage; // 64Byte per unit
};

void help() {
  printf("Usage: stab-fpga [board]\n");
  printf("Supported boards:\n");
  int i;
  for (i = 0; i < NR_BOARD; i ++) {
    printf("%s ", board_config[i].name);
  }
  printf("[default: %s]\n", board_config[0].name);
}

void output_stdout(struct StabData *data, const struct BoardConfig *bc) {
  uint32_t cache_usage_total = 0;
  uint32_t cache_access_total = 0;
  uint32_t L1toL2_bw_total = 0;
  int row;
  for (row = 0; row < bc->nr_core; row ++) {
    struct StabData *d = &data[row];
    uint32_t tl_bw = d->cached_tl_bw + d->uncached_tl_bw;
    printf("[dsid = %d] # L1toL2 TL acquire transaction: cachedTL = %d, uncachedTL = %d, total = %d (%lf%%)\n"
        "\t cache: access = %d, miss = %d (%lf%%), usage = %lfKB (%lf%%)\n",
        row, d->cached_tl_bw, d->uncached_tl_bw, tl_bw, tl_bw / (double)bc->uncore_freq * 100,
        d->cache_access, d->cache_miss,
        (double)d->cache_miss / (double)d->cache_access * 100,
        d->cache_usage / 16.0, //  = * 64B / 1024.0
        d->cache_usage / 16.0 / bc->cache_size * 100
        );
    cache_usage_total  += d->cache_usage;
    cache_access_total += d->cache_access;
    L1toL2_bw_total += d->uncached_tl_bw + d->cached_tl_bw;
  }
  printf("\t\t\ttotal L1toL2 TL acquire transaction = %d (%lf%%)\n", L1toL2_bw_total,
      L1toL2_bw_total / (double)bc->uncore_freq * 100);
  printf("\t\t\ttotal L2 access = %d (%lf%%)\n", cache_access_total,
      cache_access_total / (double)bc->uncore_freq * 100);
  printf("\t\t\ttotal cache usage = %lfKB\n", cache_usage_total / 16.0);
  /*
  if (cache_usage_total < cache_usage_total_last) {
    printf("Warning: total cache usage is decreasing, last = %lfKB\n",
    cache_usage_total_last / 16.0);
  }
  cache_usage_total_last = cache_usage_total;
  */
  fflush(stdout);
}

void output_web(struct StabData *data, const struct BoardConfig *bc) {
  const char *json_format =
    "{ \n\
    \"cpu_switch\" : [%d, %d, %d, %d],\n\
    \"cache_usage\" : [%d, %d, %d, %d],\n\
    \"mem_usage\" : [%lf, %lf, %lf, %lf]\n}";

  int cache_cap[4];
  double bw[4];  // ktps
  int state[4];

  int unused_cache = 0;
  int row;
  for (row = 0; row < bc->nr_core; row ++) {
    struct StabData *d = &data[row];
    uint32_t total_bw = d->cached_tl_bw + d->uncached_tl_bw;
    bw[row] = total_bw / 1024.0 * 8 / 1024.0;
    state[row] = (total_bw != 0);
    cache_cap[row] = round(d->cache_usage / 16.0 / bc->cache_size * 100);
    unused_cache += cache_cap[row];
  }

  // fix approximation
  unused_cache -= 100;
  while (unused_cache > 0) {
    // find the max capacity
    int i;
    int max_idx = 0;
    for (i = 1; i < bc->nr_core; i ++) {
      if (cache_cap[i] > cache_cap[max_idx]) max_idx = i;
    }

    cache_cap[max_idx] --;
    unused_cache --;
  }

#define DATA_FILE ".stabdata.json"
  static int last_ok = 0;
  static int stuck = 0;
  int ok = (state[0] && state[1] && state[2] && state[3]);
  if (last_ok && !ok) { stuck = 1; }
  if (stuck) return;
  last_ok = ok;

  char buf[1024];
  sprintf(buf, json_format, state[0], state[1], state[2], state[3],
      cache_cap[0], cache_cap[1], cache_cap[2], cache_cap[3],
      bw[0], bw[1], bw[2], bw[3]);
  puts(buf);

  FILE *fp = fopen(DATA_FILE, "w");
  assert(fp != NULL);
  fputs(buf, fp);
  fclose(fp);

  system("cp " DATA_FILE " /root/pard_web/data.json > /dev/null");
  //system("scp " DATA_FILE " sdc@10.30.6.123:/home/sdc/5/apache-tomcat-7.0.79/webapps/sdcloud/WEB-INF/pages/monitor_1_data.json > /dev/null");
  system("scp " DATA_FILE " sdc@10.30.6.123:/home/sdc/1/czh/pard_web/pages/monitor_1_data.json > /dev/null");
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

  const struct BoardConfig *bc = &board_config[board_idx];

  while (1) {
    int row;
    printf("==================================\n");
    struct StabData data[4];

    const int stabIdx = 1;
    const int memCpIdx = 1;
    const int cacheCpIdx = 2;

    for (row = 0; row < bc->nr_core; row ++) {
      data[row].cached_tl_bw = read_cp_reg(get_cp_addr(memCpIdx, stabIdx, 0, row));
      write_cp_reg(get_cp_addr(memCpIdx, stabIdx, 0, row), 0);
      data[row].uncached_tl_bw = read_cp_reg(get_cp_addr(memCpIdx, stabIdx, 1, row));
      write_cp_reg(get_cp_addr(memCpIdx, stabIdx, 1, row), 0);

      data[row].cache_access = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 0, row));
      write_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 0, row), 0);
      data[row].cache_miss = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 1, row));
      write_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 1, row), 0);

      data[row].cache_usage = read_cp_reg(get_cp_addr(cacheCpIdx, stabIdx, 2, row));
    }

	output_stdout(data, bc);
//	output_web(data, bc);

    sleep(1);
  }

  finish_platform();
  return 0;
}
