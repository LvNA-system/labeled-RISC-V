#include "common.h"
#include "util.h"
#include "jtag.h"
#include "map.h"
#include "rl.h"
#include "cp.h"
#include "dtm-loader.h"
#include <stdlib.h>

void help() {
  fprintf(stderr, "Command format:\n"
      "\trw=r/w,cp=%%s,tab=%%s,col=%%s,row=%%x[,val=%%x]\n"
      "Example:\n"
      "\t1. read cache miss counter of dsid 1:\n"
      "\t   rw=r,cp=cache,tab=s,col=miss,row=1\n"
      "\t2. change waymask of dsid 1:\n"
      "\t   rw=w,cp=cache,tab=p,col=mask,row=1,val=0xf\n");
}

void invalid_command() {
  fprintf(stderr, "Invalid command, use \"help\" to see the command format\n");
}

int main(int argc, char *argv[]) {
  bool automatic_test = false;
  for (int i = 1; i < argc; i++) {
    if (!strcmp(argv[i], "-a"))
      automatic_test = true;
  }

  /* map some devices into the address space of this program */
  init_map();

  resetn(0);
  resetn(3);
  reset_soft();
  goto_run_test_idle_from_reset();


  // get dtm info
  uint64_t dtminfo = rw_jtag_reg(REG_DTM_INFO, 0, REG_DTM_INFO_WIDTH);

  int dbusIdleCycles = get_bits(dtminfo, 12, 10);
  int dbusStatus = get_bits(dtminfo, 9, 8);
  int debugAddrBits = get_bits(dtminfo, 7, 4);
  int debugVersion = get_bits(dtminfo, 3, 0);

  printf("dbusIdleCycles: %d\ndbusStatus: %d\ndebugAddrBits: %d\ndebugVersion: %d\n",
      dbusIdleCycles, dbusStatus, debugAddrBits, debugVersion);

  srand(time(NULL));

  // first, you have to manually set up addr map cp regs!
  while (1) {
    if (!automatic_test) {
      fflush(stdout);
      char *line = NULL;
      if(!(line = rl_gets()))
        break;

      int rw = -1;
      int cpIdx = -1;
      int tabIdx = -1;
      int col = -1;
      int row = -1;
      int val = -1;

      char *s = line;
      if (!strcmp(s, "help")) {
        help();
        continue;
      }

      if (!strcmp(s, "quit")) {
        break;
      }

      while (s != NULL) {
        char *eq = strchr(s, '=');
        if (!eq) {
          invalid_command();
          break;
        }
        *eq = '\0';

        char *field = s;
        char *value = eq + 1;

        s = strchr(eq + 1, ',');
        if (s != NULL) {
          *s = '\0';
          s++;
        }

        bool incorrect_order = false;

        if (!strcmp(field, "rw")) {
          incorrect_order = rw != -1 || cpIdx != -1 || tabIdx != -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order || (rw = query_rw_tables(value)) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "cp")) {
          incorrect_order = rw == -1 || cpIdx != -1 || tabIdx != -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order || (cpIdx = query_cp_tables(value)) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "tab")) {
          incorrect_order = rw == -1 || cpIdx == -1 || tabIdx != -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order || (tabIdx = query_tab_tables(value, cpIdx)) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "col")) {
          incorrect_order = rw == -1 || cpIdx == -1 || tabIdx == -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order || (col = query_col_tables(value, cpIdx, tabIdx)) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "row")) {
          incorrect_order = rw == -1 || cpIdx == -1 || tabIdx == -1 ||
            col == -1 || row != -1 || val != -1;
          if (incorrect_order) {
            invalid_command();
            break;
          }
          row = (int)strtol(value, NULL, 16);
          // read
          if(rw == 0)
            read_cp_reg(get_cp_addr(cpIdx, tabIdx, col, row));
        } else if(!strcmp(field, "val")) {
          // only write needs val
          incorrect_order = rw != 1 || cpIdx == -1 || tabIdx == -1 ||
            col == -1 || row == -1 || val != -1;
          if (incorrect_order) {
            invalid_command();
            break;
          }
          val = (uint32_t)strtoll(value, NULL, 16);
          // execute the command
          write_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row), val);
        } else {
          printf("invalid field\n");
        }
      }
    } else {
      int rw = rand() % 2;
      int cpIdx = rand() % 3;
      int tabIdx = rand() % 2;
      int col =  rand() % 3;
      int row = rand() % 32;
      int val = rand();
      if (rw)
        write_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row), val);
      else
        read_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row));
    }
  }

  clock_t start;

  start = Times(NULL);
  load_program("/root/pard/cachesizetest-riscv64-rocket.bin", 0, 0x80000000);
  printf("load program use time: %.6fs\n", get_timestamp(start));

  start_program(0);

  start = Times(NULL);
  load_program("/root/pard/cachesizetest-riscv64-rocket.bin", 1, 0x80000000);
  printf("load program use time: %.6fs\n", get_timestamp(start));

  start = Times(NULL);
  check_loaded_program("/root/pard/cachesizetest-riscv64-rocket.bin", 1, 0x80000000);
  printf("check loaded program use time: %.6fs\n", get_timestamp(start));

  start_program(1);

  finish_map();
  return 0;
}
