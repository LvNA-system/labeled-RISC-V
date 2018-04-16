#ifndef __JTAG_H__
#define __JTAG_H__

#include "common.h"

#define LEN_IDX 0
#define TMS_IDX 1
#define TDI_IDX 2
#define TDO_IDX 3
#define CTRL_IDX 4


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


extern volatile uint32_t *jtag_base;

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

static inline void set_trst(uint8_t val) {
  assert(0);
}

static inline void seq_tms(const char *s) {
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

static inline uint64_t rw_jtag_reg(uint64_t ir_val, uint64_t dr_val, int nb_bits) {
  write_ir(ir_val);
  return write_dr(dr_val, nb_bits);
}


#endif
