//==========================================================
// MIPS CPU binary executable file loader
//
// Main Function:
// 1. Loads binary excutable file into distributed memory
// 2. Waits MIPS CPU for finishing program execution
//
// Author:
// Yisong Chang (changyisong@ict.ac.cn)
//
// Revision History:
// 14/06/2016	v0.0.1	Add cycle counte support
//==========================================================
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <memory.h>
#include <unistd.h>  
#include <sys/mman.h>  
#include <sys/stat.h>  
#include <fcntl.h>
#include <assert.h>
#include <readline/readline.h>
#include <readline/history.h>

#include "common.h"
#include "dmi.h"

// #define DEBUG

#ifdef DEBUG
# define Log(format, ...) printf("[%s,%d] " format "\n", __func__, __LINE__, ##__VA_ARGS__)
#else
# define Log(format, ...)
#endif

#define JTAG_TOTAL_SIZE		(1 << 16)
#define JTAG_BASE_ADDR		0x43c00000

#define LEN_IDX 0
#define TMS_IDX 1
#define TDI_IDX 2
#define TDO_IDX 3
#define CTRL_IDX 4

#define GPIO_RESET_TOTAL_SIZE	(1 << 16)
#define GPIO_RESET_BASE_ADDR	0x41200000

volatile uint32_t *gpio_reset_base;
volatile uint32_t *jtag_base;

void* create_map(size_t size, int fd, off_t offset) {
  void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);

  if (base == NULL) {
    perror("init_mem mmap failed:");
    close(fd);
    exit(1);
  }

  return base;
}

int fd;
void init_map() {
  fd = open("/dev/mem", O_RDWR|O_SYNC);  
  if (fd == -1)  {  
    perror("init_map open failed:");
    exit(1);
  } 

  jtag_base = (uint32_t *)create_map(JTAG_TOTAL_SIZE, fd, JTAG_BASE_ADDR);
  gpio_reset_base = (uint32_t *)create_map(GPIO_RESET_TOTAL_SIZE, fd, GPIO_RESET_BASE_ADDR);
}

void resetn(int val) {
  gpio_reset_base[0] = val;
}

void finish_map() {
  munmap((void *)jtag_base, JTAG_TOTAL_SIZE);
  munmap((void *)gpio_reset_base, GPIO_RESET_TOTAL_SIZE);
  close(fd);
}

static inline void set_tms(uint32_t val) {
  Log("write tms = 0x%x", val);
  jtag_base[TMS_IDX] = val;
}

static inline void set_len(uint32_t val) {
  Log("write len = %d bit", val);
  jtag_base[LEN_IDX] = val;
}

static inline void set_tdi(uint32_t val) {
  Log("write tdi = 0x%x", val);
  jtag_base[TDI_IDX] = val;
}

static inline uint32_t get_tdo() {
  uint32_t val = jtag_base[TDO_IDX];
  Log("read tdo = 0x%x", val);
  return val;
}

static inline void send_cmd() {
  Log("sending cmd...");
  jtag_base[CTRL_IDX] = 1;
  while (jtag_base[CTRL_IDX] & 0x1);
}

void set_trst(uint8_t val) {
  assert(0);
}

void seq_tms(const char *s) {
  // `s` must be a 0-1 sequence
  // LSB of `s` is sent first
  assert(s);
  uint32_t val = 0;
  const char *p = s;
  while (*p) {
    val <<= 1;
    switch (*p) {
      case '1': val ++;
      case '0': break;
      default: assert(0);
    }
    p ++;
  }
  set_tms(val);
  set_len(p - s);
  send_cmd();
}

static inline uint64_t scan(uint64_t val, int len) {
  assert(len <= 64 && len > 0);
  // first, send the lower 32bits
  uint64_t ret = 0;
  set_tms(len <= 32 ? 1 << (len - 1) : 0);
  set_tdi(val & 0xffffffffU);
  set_len(len <= 32 ? len : 32);
  send_cmd();
  ret = get_tdo();
  if (len > 32) {
    len -= 32;
    set_tms(1 << (len - 1));
    set_tdi(val >> 32);
    set_len(len);
    send_cmd();
    ret |= (uint64_t)get_tdo() << 32;
  }
  Log("@@@@@@@@@@@@ ret = 0x%llx", ret);
  return ret;
}

static inline void reset_soft() {
  // change the state machine to test logic reset
  // does not clear any internal registers
  seq_tms("11111");
}

static inline void goto_run_test_idle_from_reset() {
  seq_tms("0");
}


#define IR_BITS 5

//RISCV DTM Registers (see RISC-V Debug Specification)
// All others are treated as 'BYPASS'.
#define REG_BYPASS        0x1f
#define REG_IDCODE        0x1
#define REG_DEBUG_ACCESS  0x11
#define REG_DTM_INFO      0x10

#define DEBUG_DATA_BITS   34
// Spec allows values are 5-7
#define DEBUG_ADDR_BITS   5
// OP and RESP are the same size. 
#define DEBUG_OP_BITS     2

#define REG_BYPASS_WIDTH        1
#define REG_IDCODE_WIDTH        32
#define REG_DEBUG_ACCESS_WIDTH  (DEBUG_DATA_BITS + DEBUG_ADDR_BITS + DEBUG_OP_BITS)
#define REG_DTM_INFO_WIDTH      32



// write value to ir, and return the old value of ir
static inline void write_ir(uint64_t value) {
  // first, we need to move from run test idle to shift ir state
  seq_tms("0011");

  // shift in the new ir values
  scan(value, IR_BITS);

  // update ir and advance to run test idle state
  seq_tms("0110");
}

// write value to dr, and return the old value of dr
static inline uint64_t write_dr(uint64_t value, int len) {
  // advance to shift DR state
  seq_tms("001");

  // shift in the new ir values
  uint64_t ret = scan(value, len);

  // update dr and advance to run test idle state
  seq_tms("01");
  return ret;
}

static uint64_t rw_jtag_reg(uint64_t ir_val, uint64_t dr_val, int nb_bits) {
  write_ir(ir_val);
  return write_dr(dr_val, nb_bits);
}

static uint64_t req_to_bits(struct DMI_Req req) {
  uint64_t opcode = get_bits(req.opcode, DEBUG_OP_BITS - 1, 0);
  uint64_t addr = get_bits(req.addr, DEBUG_ADDR_BITS - 1, 0);
  uint64_t data = get_bits(req.data, DEBUG_DATA_BITS - 1, 0);
  uint64_t req_bits = (addr << (DEBUG_OP_BITS + DEBUG_DATA_BITS)) |
    (data << DEBUG_OP_BITS) | opcode;
  return req_bits;
}

static struct DMI_Resp bits_to_resp(uint64_t val) {
  struct DMI_Resp resp;
  resp.state = get_bits(val, DEBUG_OP_BITS - 1, 0);
  resp.data = get_bits(val, DEBUG_DATA_BITS + DEBUG_OP_BITS - 1, DEBUG_OP_BITS);
  return resp;
}

static struct DMI_Resp send_debug_request(struct DMI_Req req) {
  uint64_t req_bits = req_to_bits(req);
  uint64_t resp;
  // the value shifted out are old values
  resp = rw_jtag_reg(REG_DEBUG_ACCESS, req_bits, REG_DEBUG_ACCESS_WIDTH);

  // we need another nop request to shift out the new values
  struct DMI_Req nop_req;
  nop_req.opcode = OP_READ;
  nop_req.addr = 0x10;
  nop_req.data = 0x0;
  uint64_t nop_bits = req_to_bits(nop_req);
  resp = rw_jtag_reg(REG_DEBUG_ACCESS, nop_bits, REG_DEBUG_ACCESS_WIDTH);
  struct DMI_Resp d_resp = bits_to_resp(resp);
  if (d_resp.state != 0) {
    printf("state: %d\n", d_resp.state);
    assert(0);
  }
  return d_resp;
}

uint64_t rw_debug_reg(int opcode, uint32_t addr, uint64_t data) {
  struct DMI_Req req;
  req.opcode = opcode;
  req.addr = addr;
  req.data = data;
  uint64_t req_bits = req_to_bits(req);
  // the value shifted out are old values
  rw_jtag_reg(REG_DEBUG_ACCESS, req_bits, REG_DEBUG_ACCESS_WIDTH);

  // we need another nop request to shift out the new values
  struct DMI_Req nop_req;
  nop_req.opcode = OP_READ;
  nop_req.addr = 0x10;
  nop_req.data = 0x0;
  uint64_t nop_bits = req_to_bits(nop_req);
  uint64_t resp = rw_jtag_reg(REG_DEBUG_ACCESS, nop_bits, REG_DEBUG_ACCESS_WIDTH);
  struct DMI_Resp d_resp = bits_to_resp(resp);
  assert(d_resp.state == 0); 
  return d_resp.data;
}

/* We use the ``readline'' library to provide more flexibility to read from stdin. */
char* rl_gets(void) {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("> ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}


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
  {{"mask"}, {"access", "miss"}}
};

int get_cp_addr(int cpIdx, int tabIdx, int col, int row) {
  int addr = cpIdx << cpIdxLow | tabIdx << tabIdxLow |
    col << colIdxLow | row << rowIdxLow;
  return addr;
}

void read_cp_reg(int addr) {
  struct DMI_Req req;
  struct DMI_Resp resp;
  // write sbaddr0
  req.opcode = OP_WRITE;
  req.addr = 0x16;
  req.data = (uint32_t)addr;
  // set rw to 1(read)
  req.data |= (uint64_t)1 << 32;
  send_debug_request(req);
  // read sbdata0
  req.opcode = OP_READ;
  req.addr = 0x18;
  req.data = 0;
  resp = send_debug_request(req);
  printf("0x%llx\n", resp.data);
}

void write_cp_reg(int addr, int value) {
  struct DMI_Req req;
  // write sbaddr0
  req.opcode = OP_WRITE;
  req.addr = 0x16;
  req.data = (uint32_t)addr;
  send_debug_request(req);
  // write sbdata0
  req.opcode = OP_WRITE;
  req.addr = 0x18;
  req.data = (uint32_t)value;
  send_debug_request(req);
}

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

void load_program(const char *bin_file, uint32_t base) {
  // load base address to t0
  stage_1_machine_code[address_idx] = base;
  // write debug ram
  for (unsigned i = 0; i < sizeof(stage_1_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_1_machine_code[i]);
  // send debug request to hart 0, let it execute code we just written
  rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33);

  // wait for hart to clear debug interrupt
  while((rw_debug_reg(OP_READ, 0x10, 0ULL) >> 33) & 1ULL);

  for (unsigned i = 0; i < sizeof(stage_2_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_2_machine_code[i]);

  FILE *f = fopen(bin_file, "r");
  assert(f);
  uint32_t code;
  while(fread(&code, sizeof(uint32_t), 1, f) == 1) {
    rw_debug_reg(OP_WRITE, DEBUG_RAM + data_idx, code);
    // send a debug interrupt to hart 0, let it store one word for us
    rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33);
    while((rw_debug_reg(OP_READ, 0x10, 0ULL) >> 33) & 1ULL);
  }

  // bin file loading finished, write entry address to dpc
  for (unsigned i = 0; i < sizeof(stage_3_machine_code) / sizeof(uint32_t); i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, stage_3_machine_code[i]);
  rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33);
  while((rw_debug_reg(OP_READ, 0x10, 0ULL) >> 33) & 1ULL);
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

  clock_t start;

  start = Times(NULL);
  load_program("emu.bin", 0x80000000);
  printf("load program use time: %.6fs\n", get_timestamp(start));

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

  finish_map();
  return 0;
}
