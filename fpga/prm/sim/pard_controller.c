#include "common.h"
#include "dmi.h"
#include "client_common.h"
#include "dtm-loader.h"
#include "cp.h"
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
  char *ip = NULL;
  int port = 0;
  bool automatic_test = false;
  for (int i = 1; i < argc; i++) {
    char *arg = argv[i];
    if (strncmp(arg, "-p", 2) == 0)
      port = atoi(argv[i] + 2);
    else if (strncmp(arg, "-ip", 3) == 0)
      ip = argv[i] + 3;
    else if (strncmp(arg, "-a", 2) == 0)
      automatic_test = true;
  }

  connect_server(ip == NULL ? "127.0.0.1" : ip, port == 0 ? 8080 : port);
  init_dtm();
  /*
  clock_t start;

  const char *bin_file = "cachesizetest-riscv64-rocket.bin";
  start = Times(NULL);
  load_program(bin_file, 0, 0x80000000);
  printf("load program use time: %.6fs\n", get_timestamp(start));

  start_program(0);

  start = Times(NULL);
  load_program(bin_file, 1, 0x80000000);
  printf("load program use time: %.6fs\n", get_timestamp(start));

  start = Times(NULL);
  check_loaded_program(bin_file, 1, 0x80000000);
  printf("check loaded program use time: %.6fs\n", get_timestamp(start));

  start_program(1);
  */

  srand(time(NULL));

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
      /*
         sleep(0);
         int dsid = rand() % NDsids;
         int size = rand() % 1000;
         int freq = rand() % 1000;
         int inc = rand() % 10;
         int mask = rand();
         change_size(dsid, size);
         change_freq(dsid, freq);
         change_inc(dsid, inc);
         change_mask(dsid, mask);
         */
    }
  }

  disconnect_server();
  return 0;
}
