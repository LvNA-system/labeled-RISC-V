#include <cstdio>
#include <cstring>
#include <cassert>
#include <string>

#include "dmi.h"
#include "common.h"
#include "client_common.h"


using std::string;

// control plane address space
static const int cpAddrSize = 32;
static const int cpDataSize = 32;

// control plane register address space;
// 31     23        21     11       0;
// +-------+--------+-------+-------+;
// | cpIdx | tabIdx |  col  |  row  |;
// +-------+--------+-------+-------+;
//  \- 8 -/ \-  2 -/ \- 10-/ \- 12 -/;
static const int rowIdxLen = 12;
static const int colIdxLen = 10;
static const int tabIdxLen = 2;
static const int cpIdxLen = 8;

static const int rowIdxLow = 0;
static const int colIdxLow = rowIdxLow + rowIdxLen;
static const int tabIdxLow = colIdxLow + colIdxLen;
static const int cpIdxLow  = tabIdxLow + tabIdxLen;

static const int rowIdxHigh = colIdxLow - 1;
static const int colIdxHigh = tabIdxLow - 1;
static const int tabIdxHigh = cpIdxLow  - 1;
static const int cpIdxHigh  = 31;

// control plane index;
static const int coreCpIdx = 0;
static const int memCpIdx = 1;
static const int cacheCpIdx = 2;
static const int ioCpIdx = 3;

// tables;
static const int ptabIdx = 0;
static const int stabIdx = 1;
static const int ttabIdx = 2;

const char *rw_tables[] = {"r","w"};
const char *cp_tables[] = {"core", "mem", "cache","io"};

const char *tab_tables[3][3] = {
  {"p"},
  {"p", "s"},
  {"p", "s"}
};

const char *col_tables[3][3][4] = {
  {{"dsid", "base", "size", "hartid"}},
  {{"size", "freq", "inc"}, {"read", "write"}},
  {{"mask"}, {"access", "miss", "usage"}}
};

int get_cp_addr(int cpIdx, int tabIdx, int col, int row) {
  int addr = cpIdx << cpIdxLow | tabIdx << tabIdxLow |
    col << colIdxLow | row << rowIdxLow;
  return addr;
}

void read_cp_reg(int addr) {
  char buf[1024];
  sprintf(buf, "rw=1 addr=%x", addr);
  handle_debug_request("write", "sbaddr0", buf);
  handle_debug_request("read", "sbdata0", buf);
}

void write_cp_reg(int addr, int value) {
  char buf[1024];
  sprintf(buf, "rw=0 addr=%x", addr);
  handle_debug_request("write", "sbaddr0", buf);
  sprintf(buf, "data=%x", value);
  handle_debug_request("write", "sbdata0", buf);
}

void help() {
  fprintf(stderr, "Command format:\n"
      "\trw=r/w,cp=%%s,tab=%%s,col=%%s,row=%%x[,val=%%x]\n"
      "Example:\n"
      "\t1. read cache miss counter of dsid 1:\n"
      "\t   rw=r,cp=cache,tab=s,col=miss,row=1\n"
      "\t2. change waymask of dsid 1:\n"
      "\t   rw=r,cp=cache,tab=p,col=mask,row=1,val=0xf\n");
}

void invalid_command() {
  fprintf(stderr, "Invalid command, use \"help\" to see the command format\n");
}

int string_to_idx(const char *name, const char **table, int size) {
  for (int i = 0; i < size; i++)
    if (!strcmp(name, table[i]))
      return i;
  return -1;
}

#define DEBUG_RAM 0x400

/* load bin file stage 1, store base address in t0
 * assembly source
 *
 * #define DEBUG_RAM 0x400
 * #define RESUME 0x804
 * .text
 * .global _start
 * _start:
 * // during program loading, the core is runing a loop in bootrom
 * // no one needs t0(bootrom + debug rom)
 * // we can safely override it
 * lwu t0, (DEBUG_RAM + 8)(zero)
 * j RESUME
 * address:.word 0
 */
int address_idx = 2; 
uint32_t stage_1_machine_code[] = {
  0x40806283, 0x4000006f, 0x00000000
};

/* load bin file stage 2, store one word to address t0
 * assembly source
 *
 * #define DEBUG_RAM 0x400
 * #define RESUME 0x804
 * .text
 * .global _start
 * _start:
 * lwu s0, (DEBUG_RAM + 16)(zero)
 * sw s0, 0(t0)
 * addi t0, t0, 4
 * j RESUME
 * data: .word 0
 */
int data_idx = 4;
uint32_t stage_2_machine_code[] = {
  0x41006403, 0x0082a023, 0x00428293, 0x3f80006f, 0x00000000
};

/* load bin file stage 3, set pc to entry address
 * assembly source
 *
 * #define ENTRY 0x80000000
 * #define DPC 0x7b1
 * #define RESUME 0x804
 * .text
 * .global _start
 * _start:
 * li t0, ENTRY
 * csrw DPC, t0
 * j RESUME
 */
uint32_t stage_3_machine_code[] = {
  0x0010029b, 0x01f29293, 0x7b129073, 0x3f80006f
};

void load_program(const char *bin_file, uint64_t hartid, uint32_t base) {
  // load base address to t0
  stage_1_machine_code[address_idx] = base;
  // write debug ram
  for (unsigned i = 0; i < sizeof(stage_1_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_1_machine_code[i]);
  // send debug request to hart 0, let it execute code we just written
  rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33 | hartid << 2);

  // wait for hart to clear debug interrupt
  while((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 33) & 1ULL);

  for (unsigned i = 0; i < sizeof(stage_2_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_2_machine_code[i]);

  FILE *f = fopen(bin_file, "r");
  assert(f);
  uint32_t code;
  while(fread(&code, sizeof(uint32_t), 1, f) == 1) {
    rw_debug_reg(OP_WRITE, DEBUG_RAM + data_idx, code);
    // send a debug interrupt to hart 0, let it store one word for us
    rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33 | hartid << 2);
    while((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 33) & 1ULL);
  }

  fclose(f);
}

void start_program(uint64_t hartid) {
  // bin file loading finished, write entry address to dpc
  for (unsigned i = 0; i < sizeof(stage_3_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_3_machine_code[i]);
  rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33 | hartid << 2);
  while((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 33) & 1ULL);
}


/* load bin file stage 4, read memory to make sure it's correctly loaded
 * assembly source
 *
 * #define DEBUG_RAM 0x400
 * #define RESUME 0x804
 * .text
 * .global _start
 * _start:
 * lwu s1, (DEBUG_RAM + 16)(zero)
 * lwu s0, 0(s1)
 * sw s0, (DEBUG_RAM + 20)(zero)
 * j RESUME
 * address: .word 0
 * data: .word 0
 */
int s4_addr_idx = 4;
int s4_data_idx = 5;
uint32_t stage_4_machine_code[] = {
  0x41006483, 0x0004e403, 0x40802a23, 0x3f80006f, 0x00000000, 0x00000000
};

void check_loaded_program(const char *bin_file, uint64_t hartid, uint32_t base) {
  for (unsigned i = 0; i < sizeof(stage_4_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_4_machine_code[i]);

  FILE *f = fopen(bin_file, "r");
  assert(f);
  uint32_t code;
  while(fread(&code, sizeof(uint32_t), 1, f) == 1) {
    rw_debug_reg(OP_WRITE, DEBUG_RAM + s4_addr_idx, base);
    // send a debug interrupt to hart, let it store one word for us
    rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33 | hartid << 2);
    while((rw_debug_reg(OP_READ, 0x10, 0ULL) >> 33) & 1ULL);
    uint32_t loaded_code = rw_debug_reg(OP_READ, DEBUG_RAM + s4_data_idx, hartid << 2);
    if (code != loaded_code) {
      printf("addr: %x code: %x loaded_code: %x\n", base, code, loaded_code);
    }
    base += 4;
  }
  fclose(f);
}


int main(int argc, char *argv[]) {
  char *ip = NULL;
  int port = 0;
  bool automatic_test = false;
  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg.substr(0, 2) == "-p")
      port = atoi(argv[i] + 2);
    else if (arg.substr(0, 3) == "-ip")
      ip = argv[i] + 3;
    else if (arg.substr(0, 2) == "-a")
      automatic_test = true;
  }

  connect_server(ip == NULL ? "127.0.0.1" : ip, port == 0 ? 8080 : port);
  init_dtm();
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
          if (incorrect_order ||
              (rw = string_to_idx(value, rw_tables,sizeof(rw_tables) / sizeof(char *))) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "cp")) {
          incorrect_order = rw == -1 || cpIdx != -1 || tabIdx != -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order ||
              (cpIdx = string_to_idx(value, cp_tables,sizeof(cp_tables) / sizeof(char *))) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "tab")) {
          incorrect_order = rw == -1 || cpIdx == -1 || tabIdx != -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order ||
              (tabIdx = string_to_idx(value, tab_tables[cpIdx],sizeof(tab_tables[cpIdx]) / sizeof(char *))) == -1) {
            invalid_command();
            break;
          }
        } else if(!strcmp(field, "col")) {
          incorrect_order = rw == -1 || cpIdx == -1 || tabIdx == -1 ||
            col != -1 || row != -1 || val != -1;
          if (incorrect_order ||
              (col = string_to_idx(value, col_tables[cpIdx][tabIdx],sizeof(col_tables[cpIdx][tabIdx]) / sizeof(char *))) == -1) {
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
            read_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row));
        } else if(!strcmp(field, "val")) {
          // only write needs val
          incorrect_order = rw != 1 || cpIdx == -1 || tabIdx == -1 ||
            col == -1 || row == -1 || val != -1;
          if (incorrect_order) {
            invalid_command();
            break;
          }
          val = (int)strtol(value, NULL, 16);
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
