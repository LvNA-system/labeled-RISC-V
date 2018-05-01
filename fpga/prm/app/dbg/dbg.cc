#include <cstdio>
#include <cstring>
#include <cassert>
#include <string>
#include <vector>
#include <utility>

extern "C" {
#include "common.h"
#include "util.h"
#include "jtag.h"
#include "platform.h"
#include "dtm.h"
#include "dmi.h"
#include "rl.h"
}

#include "dbg.h"

using std::string;
using std::vector;
using std::pair;
using std::make_pair;

/***************************** Debugger ***********************************/
// tell us which hartid your are currently debugging
uint64_t hartid;

/***************************** Get/Set ***********************************/
void cmd_get_pc(vector<char *> args);
void cmd_set_pc(vector<char *> args);
void cmd_get_gpr(vector<char *> args);
void cmd_set_gpr(vector<char *> args);
void cmd_get_csr(vector<char *> args);
void cmd_set_csr(vector<char *> args);
void cmd_get_hart (vector<char *> args);
void cmd_set_hart(vector<char *> args);

struct {
  const char *name;
  void (*get) (vector<char *> args);
  void (*set) (vector<char *> args);
} get_set_table [] = {
  { "pc", cmd_get_pc, cmd_set_pc }, 
  { "reg", cmd_get_gpr, cmd_set_gpr }, 
  { "csr", cmd_get_csr, cmd_set_csr },
  { "hart", cmd_get_hart, cmd_set_hart }
};

#define NR_GET (sizeof(get_set_table) / sizeof(get_set_table[0]))

vector<char *> get_child_args(vector<char *> args) {
  vector<char *> ret;
  if (args.size() > 1)
    for (unsigned i = 1; i < args.size(); i++)
      ret.push_back(args[i]);
  return ret;
}

int cmd_get(vector<char *> args) {
  unsigned i;

  if (args.size() == 0) {
    for(i = 0; i < NR_GET; i++)
      printf("%s\n", get_set_table[i].name);
    return 0;
  }

  auto child_args = get_child_args(args);
  auto name = args[0];

  for(i = 0; i < NR_GET; i ++) {
    if(strcmp(name, get_set_table[i].name) == 0) {
      get_set_table[i].get(child_args);
      break;
    }
  }

  if(i == NR_GET)
    printf("Unknown get target '%s'\n", name);
  return 0;
}

int cmd_set(vector<char *> args) {
  unsigned i;

  if(args.size() == 0) {
    for(i = 0; i < NR_GET; i++)
      printf("%s\n", get_set_table[i].name);
    return 0;
  }

  auto child_args = get_child_args(args);
  auto name = args[0];

  for(i = 0; i < NR_GET; i ++) {
    if(strcmp(name, get_set_table[i].name) == 0) {
      get_set_table[i].set(child_args);
      break;
    }
  }

  if(i == NR_GET) { printf("Unknown set target '%s'\n", name); }
  return 0;
}

uint64_t get_pc(void);
uint64_t get_gpr(int idx);
int cmd_info(vector<char *> args) {
  printf("pc: %lx\n", get_pc());
  for(int i = 0; i < 8; i++) {
    for (int j = 0; j < 4; j++) {
      int idx = i * 4 + j;
      // use the abi name
      printf("%-4s: %16lx    ", reg_table[idx + 32].name, get_gpr(idx));
    }
    printf("\n");
  }
  return 0;
}

/***************************** Mem read/write ***********************************/
uint32_t read_mem(uint32_t addr);
void write_mem(uint32_t addr, uint32_t data);

int cmd_r(vector<char *> args) {
  if (args.size() == 0) {
    printf("x expected memory address in hex format\n");
    return 0;
  }
  uint32_t addr = (uint32_t)strtol(args[0], NULL, 16);
  printf("%08x\n", read_mem(addr));
  return 0;
}

int cmd_w(vector<char *> args) {
  if (args.size() < 2) {
    printf("x expected memory address and data in hex format\n");
    return 0;
  }
  uint32_t addr = (uint32_t)strtol(args[0], NULL, 16);
  uint32_t data = (uint32_t)strtol(args[1], NULL, 16);
  write_mem(addr, data);
  return 0;
}

/***************************** Execution Control ***********************************/
#define STEP_MASK 0x4
#define HALT_MASK 0x8

void load_debug_code(uint32_t *arr, uint32_t size);
void run_debug_code(void);

void set_dcsr(uint32_t mask) {
  uint32_t data_idx = 3;
  uint32_t set_dcsr_code[] = {
    0x40c06403, 0x7b042073, 0x3fc0006f, 0x00000000
  };
  set_dcsr_code[data_idx] = mask;
  load_debug_code(set_dcsr_code, sizeof(set_dcsr_code) / sizeof(uint32_t));
  run_debug_code();
}

void clear_dcsr(uint32_t mask) {
  uint32_t data_idx = 3;
  uint32_t clear_dcsr_code[] = {
    0x40c06403, 0x7b043073, 0x3fc0006f, 0x00000000 
  };
  clear_dcsr_code[data_idx] = mask;
  load_debug_code(clear_dcsr_code, sizeof(clear_dcsr_code) / sizeof(uint32_t));
  run_debug_code();
}

vector<pair<uint32_t, uint32_t> > breakpoints;

void start_program(void);
int cmd_start(vector<char *> args) {
  start_program();
  if (breakpoints.size() > 0) {
    // if user has set breakpoints, check for it
    while(((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 32) & 1ULL) == 0ULL);
    // clear halt notification
    rw_debug_reg(OP_WRITE, 0x10,  1ULL << 32 | hartid << 2);
    set_dcsr(HALT_MASK);
  }
  return 0;
}

// break expects an address
int cmd_break(vector<char *> args) {
  if (args.size() == 0) {
    printf("Break expects address in hex format\n");
    return 0;
  }
  uint32_t addr = (uint32_t)strtoll(args[0], NULL, 16);
  bool already_exist = false;
  for (auto b: breakpoints)
    if (b.first == addr) {
      already_exist = true;
      break;
    }
  if (already_exist) {
    printf("Breakpoints already exists\n");
    return 0;
  }
  // replace the original code with a trap instruction
  uint32_t code = read_mem(addr);
  breakpoints.push_back(make_pair(addr,code));
  write_mem(addr, 0x00100073);
  return 0;
}

bool in_step_mode = false;

// execute one instruction
// when we enter this functio, we assumed that the core is halted
void exec_one_instruction(void) {
  uint32_t addr = get_pc();
  int idx = -1;
  for (unsigned j = 0; j < breakpoints.size(); j++)
    if (breakpoints[j].first == addr) {
      idx = j;
      break;
    }
  auto hit_breakpoint = idx != -1;
  if (hit_breakpoint)
    // fill back the original code
    write_mem(addr, breakpoints[idx].second);

  // clear halt and set single step, execute the original code
  set_dcsr(STEP_MASK);
  clear_dcsr(HALT_MASK);

  // first, we wait for halt notification
  while(((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 32) & 1ULL) == 0ULL);
  // clear halt notification
  rw_debug_reg(OP_WRITE, 0x10,  1ULL << 32 | hartid << 2);
  // set halt, so that we can manipulate memory with no side effect
  set_dcsr(HALT_MASK);
  if (hit_breakpoint)
    // fill back the break code, so that next time, we will be break again
    write_mem(addr, 0x00100073);
}

int cmd_si(vector<char *> args) {
  unsigned steps = 1;
  if (args.size() > 0)
    steps = (unsigned)strtoll(args[0], NULL, 10);

  // when we enter this function, we assumed that the core is halted
  // so that we can run debug code as we wish, without worrying about debug interrupt get the core running.

  for (unsigned i = 0; i < steps; i++)
    exec_one_instruction();
  return 0;
}

int cmd_c(vector<char *> args) {
  // when we enter this function, we assumed that the core is halted
  // so that we can run debug code as we wish, without worrying about debug interrupt get the core running.

  // the first instruction may be an ebreak
  // we need to deal with care
  exec_one_instruction();

  // clear halt and step, resume running
  clear_dcsr(STEP_MASK);
  clear_dcsr(HALT_MASK);

  // wait for next break
  while(((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 32) & 1ULL) == 0ULL);
  // clear halt notification
  rw_debug_reg(OP_WRITE, 0x10,  1ULL << 32 | hartid << 2);
  set_dcsr(HALT_MASK);
  return 0;
}

/***************************** MISC  ***********************************/
int cmd_q(vector<char *> args) {
  return -1;
}

int cmd_help(vector<char *> args);

struct {
  const char *name;
  const char *description;
  int (*handler) (vector<char *>);
} cmd_table [] = {
  { "help", "Display informations about all supported commands", cmd_help },
  { "get", "Display the value of pc/reg/csr/hart", cmd_get },
  { "set", "Set the value of pc/reg/csr/hart", cmd_set },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si","Single step", cmd_si },
  { "b","break", cmd_break },
  { "info","Print information", cmd_info},
  { "start","Start core", cmd_start},
  { "r","Read memory", cmd_r},
  { "w","Write memory", cmd_w}
};

#define NR_CMD (sizeof(cmd_table) / sizeof(cmd_table[0]))

int cmd_help(vector<char *> args) {
  unsigned i;
  if(args.size() == 0) {
    /* no argument given */
    for(i = 0; i < NR_CMD; i ++) {
      printf("%-5s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for(i = 0; i < NR_CMD; i ++) {
      if(strcmp(args[0], cmd_table[i].name) == 0) {
        printf("%-5s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", args[0]);
  }
  return 0;
}

void ui_mainloop() {
  while(1) {
    char *str = rl_gets();
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if(cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if(args >= str_end) {
      args = NULL;
    }

    vector<char *> tokens;
    while (args) {
      char *token = strtok(NULL, " ");
      if(!token)
        break;
      tokens.push_back(token);
      args = token + strlen(token) + 1;
      if(args >= str_end)
        args = NULL;
    }

    unsigned i;
    for(i = 0; i < NR_CMD; i ++) {
      if(strcmp(cmd, cmd_table[i].name) == 0) {
        /*this is specially for cmd_q, 
          since only cmd_q returns a negative value*/
        if(cmd_table[i].handler(tokens) < 0) { return; }
        break;
      }
    }

    if(i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

int main(int argc, char *argv[]) {
  char *ip = NULL;
  int port = 0;
  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg.substr(0, 2) == "-p")
      port = atoi(argv[i] + 2);
    else if (arg.substr(0, 3) == "-ip")
      ip = argv[i] + 3;
  }

  init_platform(ip, port);
  init_dtm();

  ui_mainloop();

  finish_platform();
  return 0;
}

/***************************** GET/SET UI code ********************************/

/***************************** Hart Get/Set ***********************************/
void cmd_get_hart (vector<char *> args) {
  printf("%lx\n", hartid);
}

void cmd_set_hart(vector<char *> args) {
  if (args.size() == 0)
    printf("Expect hartid in hex format\n");
  else
    hartid = (uint64_t)strtoll(args[0], NULL, 16);
}

/***************************** GPR Get/Set ***********************************/
uint64_t get_gpr(int idx);
void cmd_get_gpr(vector<char *> args) {
  unsigned i;
  if (args.size() == 0) {
    for(i = 0; i < NR_REG; i++)
      printf("%s\n", reg_table[i].name);
    return;
  }

  char *reg_name = args[0];

  for(i = 0; i < NR_REG; i ++) {
    if (strcmp(reg_name, reg_table[i].name) == 0) {
      printf("%lx\n", get_gpr(reg_table[i].idx));
      return;
    }
  }
  printf("Unknown gpr '%s'\n", reg_name);
  return;
}

void set_gpr(int idx, uint64_t val);
void cmd_set_gpr(vector<char *> args) {
  unsigned i;
  if (args.size() == 0) {
    for(i = 0; i < NR_REG; i++)
      printf("%s\n", reg_table[i].name);
    return;
  }
  char *reg_name = args[0];

  if (args.size() == 2) {
    printf("Expect value in hex format\n");
    return;
  }
  char *val_str = args[1];
  uint64_t val = (uint64_t)strtoll(val_str, NULL, 16);

  for(i = 0; i < NR_REG; i ++) {
    if (strcmp(reg_name, reg_table[i].name) == 0) {
      set_gpr(reg_table[i].idx, val);
      return;
    }
  }
  printf("Unknown gpr '%s'\n", reg_name);
}

/***************************** PC Get/Set ***********************************/
uint64_t get_pc(void);
void cmd_get_pc(vector<char *> args) {
  printf("%lx\n", get_pc());
}

void set_pc(uint64_t val);
void cmd_set_pc(vector<char *> args) {
  if (args.size() == 0) {
    printf("Expect value in hex format\n");
    return;
  }
  char *val_str = args[0];
  uint64_t val = (uint64_t)strtoll(val_str, NULL, 16);
  set_pc(val);
}

/***************************** CSR Get/Set ***********************************/
uint64_t get_csr(int idx);
void cmd_get_csr(vector<char *> args) {
  unsigned i;
  if (args.size() == 0) {
    for(i = 0; i < NR_CSR; i++)
      printf("%s\n", csr_table[i].name);
    return;
  }
  char *csr_str = args[0];

  for(i = 0; i < NR_CSR; i ++) {
    if (strcmp(csr_str, csr_table[i].name) == 0) {
      printf("%lx\n", get_csr(csr_table[i].idx));
      return;
    }
  }
  printf("Unknown csr '%s'\n", csr_str);
  return;
}

void set_csr(int idx, uint64_t val);
void cmd_set_csr(vector<char *> args) {
  unsigned i;
  if (args.size() == 0) {
    for(i = 0; i < NR_CSR; i++)
      printf("%s\n", csr_table[i].name);
    return;
  }
  char *csr_str = args[0];

  if (args.size() == 1) {
    printf("Expect value in hex format\n");
    return;
  }
  char *val_str = args[1];

  uint64_t val = (uint64_t)strtoll(val_str, NULL, 16);

  for(i = 0; i < NR_CSR; i ++) {
    if (strcmp(csr_str, csr_table[i].name) == 0) {
      int csr = csr_table[i].idx;
      set_csr(csr, val);
      return;
    }
  }
  printf("Unknown csr '%s'\n", csr_str);
}


/****************************************************************************************************
 ***************************** RISCV Arch/Interface related code ************************************
 ****************************************************************************************************/
#define DEBUG_RAM 0x400

void load_debug_code(uint32_t *arr, uint32_t size) {
  for (unsigned i = 0; i < size; i++)
    rw_debug_reg(OP_WRITE, DEBUG_RAM + i, arr[i]);
}

void run_debug_code(void) {
  rw_debug_reg(OP_WRITE, 0x10, 1ULL << 33 | hartid << 2);
  while((rw_debug_reg(OP_READ, 0x10, hartid << 2) >> 33) & 1ULL);
}

// see assembly/s3.S
void start_program(void) {
  // set ebreakm in dcsr
  uint32_t set_ebreakm_code[] = {
    0x00008437, 0x7b042073, 0x3fc0006f
  };
  load_debug_code(set_ebreakm_code, sizeof(set_ebreakm_code) / sizeof(uint32_t));
  run_debug_code();

  uint32_t start_code[] = {
    0x0010029b, 0x01f29293, 0x7b129073, 0x3f80006f
  };
  load_debug_code(start_code, sizeof(start_code) / sizeof(uint32_t));
  run_debug_code();
}

uint32_t read_mem(uint32_t addr) {
  // see assembly/s4.S
  int addr_idx = 4;
  int data_idx = 5;
  uint32_t mem_read_code[] = {
    0x41006483, 0x0004e403, 0x40802a23, 0x3f80006f, 0x00000000, 0x00000000
  };
  mem_read_code[addr_idx] = addr;
  load_debug_code(mem_read_code, sizeof(mem_read_code) / sizeof(uint32_t));
  run_debug_code();
  return rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
}

void write_mem(uint32_t addr, uint32_t data) {
  // see assembly/s5.S
  int addr_idx = 4;
  int data_idx = 5;
  uint32_t mem_write_code[] = {
    0x41006483, 0x41406403, 0x0084a023, 0x3f80006f, 0x00000000, 0x00000000
  };
  mem_write_code[addr_idx] = addr;
  mem_write_code[data_idx] = data;
  load_debug_code(mem_write_code, sizeof(mem_write_code) / sizeof(uint32_t));
  run_debug_code();
}

/***************************** GPR Get/Set ***********************************/
uint64_t get_gpr(int idx) {
  // s0 and s1 use different debug code
  // s0
  if (idx == 8) {
    uint32_t data_idx = 4;
    // see assembly/s12.S
    uint32_t get_s0_code[] = {
      0x7b202473, 0x40803823, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000
    };
    load_debug_code(get_s0_code, sizeof(get_s0_code) / sizeof(uint32_t));
    run_debug_code();
    uint64_t s0_low_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
    uint64_t s0_high_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, 0);
    return s0_high_half << 32 | s0_low_half;
  }

  // s1
  if (idx == 9) {
    uint32_t data_idx = 14;
    // see assembly/s13.S
    uint32_t get_s1_code[] = {
      0x4040006f
    };
    load_debug_code(get_s1_code, sizeof(get_s1_code) / sizeof(uint32_t));
    run_debug_code();
    uint64_t s1_low_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
    uint64_t s1_high_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, 0);
    return s1_high_half << 32 | s1_low_half;
  }

  uint32_t data_idx = 2;
  // see assembly/s11.S
  uint32_t get_gpr_code[] = {
    0x40003423, 0x4000006f, 0x00000000, 0x00000000
  };
  get_gpr_code[0] |= idx << 20;
  load_debug_code(get_gpr_code, sizeof(get_gpr_code) / sizeof(uint32_t));
  run_debug_code();
  uint64_t a0_low_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
  uint64_t a0_high_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, 0);
  return a0_high_half << 32 | a0_low_half;
}

void set_gpr(int idx, uint64_t val) {
  // s0 and s1 use different debug code
  if (idx == 8) {
    // s0 resides in DSCRATCH
    uint32_t data_idx = 4;
    // see assembly/s15.S
    uint32_t set_s0_code[] = {
      0x41003403, 0x7b241073, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000
    };
    uint64_t *ptr = (uint64_t *)&set_s0_code[data_idx];
    *ptr = val;
    load_debug_code(set_s0_code, sizeof(set_s0_code) / sizeof(uint32_t));
    run_debug_code();
    return;
  }

  if (idx == 9) {
    // s1 resides on the top of debug ram
    uint32_t data_idx = 14;
    uint32_t set_s1_code[] = {
      0x4040006f
    };
    rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, val & 0xffffffff);
    rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, (val >> 32) & 0xffffffff);
    load_debug_code(set_s1_code, sizeof(set_s1_code) / sizeof(uint32_t));
    run_debug_code();
    return;
  }

  uint32_t data_idx = 2;
  uint32_t set_gpr_code[] = {
    0x40803003, 0x4000006f, 0x00000000, 0x00000000 
  };
  uint64_t *ptr = (uint64_t *)&set_gpr_code[data_idx];
  *ptr = val;
  set_gpr_code[0] |= idx << 7;
  load_debug_code(set_gpr_code, sizeof(set_gpr_code) / sizeof(uint32_t));
  run_debug_code();
}

/***************************** PC Get/Set ***********************************/
uint64_t get_pc(void) {
  uint32_t data_idx = 4;
  // see assembly/s5.S
  uint32_t get_pc_code[] = {
    0x7b102473, 0x40803823, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000
  };
  load_debug_code(get_pc_code, sizeof(get_pc_code) / sizeof(uint32_t));
  run_debug_code();
  uint64_t pc_low_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
  uint64_t pc_high_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, 0);
  return pc_high_half << 32 | pc_low_half;
}

void set_pc(uint64_t val) {
  uint32_t data_idx = 4;
  // see assembly/s6.S
  uint32_t set_pc_code[] = {
    0x41003403, 0x7b141073, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000,
  };
  uint64_t *ptr = (uint64_t *)&set_pc_code[data_idx];
  *ptr = val;
  load_debug_code(set_pc_code, sizeof(set_pc_code) / sizeof(uint32_t));
  run_debug_code();
}

/***************************** CSR Get/Set ***********************************/
uint64_t get_csr(int idx) {
  int csr = idx;
  uint32_t data_idx = 4;
  // see assembly/s17.S
  uint32_t get_csr_code[] = {
    0x00002473, 0x40803823, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000
  };
  get_csr_code[0] |= csr << 20;
  load_debug_code(get_csr_code, sizeof(get_csr_code) / sizeof(uint32_t));
  run_debug_code();
  uint64_t csr_low_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx, 0);
  uint64_t csr_high_half = rw_debug_reg(OP_READ, DEBUG_RAM + data_idx + 1, 0);
  return csr_high_half << 32 | csr_low_half;
}

void set_csr(int idx, uint64_t val) {
  int csr = idx;
  uint32_t data_idx = 4;
  // see assembly/s18.S
  uint32_t set_csr_code[] = {
    0x41003403, 0x00041073, 0x3fc0006f, 0x00000000, 0x00000000, 0x00000000
  };
  set_csr_code[1] |= csr << 20;
  uint64_t *ptr = (uint64_t *)&set_csr_code[data_idx];
  *ptr = val;
  load_debug_code(set_csr_code, sizeof(set_csr_code) / sizeof(uint32_t));
  run_debug_code();
}
