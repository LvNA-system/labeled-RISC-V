#include "jtag.h"
#include <sys/file.h>

#define LEN_IDX 0
#define TMS_IDX 1
#define TDI_IDX 2
#define TDO_IDX 3
#define CTRL_IDX 4

extern volatile uint32_t *jtag_base;
static int fd;

static inline void jtag_lock(void) {
  int ret;
  while ((ret = flock(fd, LOCK_EX | LOCK_NB)) != 0) {
    perror("flock");
  }
}

static inline void jtag_unlock(void) {
  int ret;
  while ((ret = flock(fd, LOCK_UN)) != 0) {
    perror("flock");
  }
}

static inline void set_tms(uint32_t val) {
  Debug("write tms = 0x%x", val);
  jtag_base[TMS_IDX] = val;
}

static inline void set_len(uint32_t val) {
  Debug("write len = %d bit", val);
  jtag_base[LEN_IDX] = val;
}

static inline void set_tdi(uint32_t val) {
  Debug("write tdi = 0x%x", val);
  jtag_base[TDI_IDX] = val;
}

static inline uint32_t get_tdo() {
  uint32_t val = jtag_base[TDO_IDX];
  Debug("read tdo = 0x%x", val);
  return val;
}

static inline void send_cmd() {
  Debug("sending cmd...");
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
  Debug("@@@@@@@@@@@@ ret = 0x%lx", ret);
  return ret;
}

void goto_run_test_idle_from_reset() {
  jtag_lock();
  seq_tms("0");
  jtag_unlock();
}


void reset_soft() {
  // change the state machine to test logic reset
  // does not clear any internal registers
  jtag_lock();
  seq_tms("11111");
  jtag_unlock();

  goto_run_test_idle_from_reset();
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

uint64_t rw_jtag_reg(uint64_t ir_val, uint64_t dr_val, int nb_bits) {
  jtag_lock();
  write_ir(ir_val);
  uint64_t ret = write_dr(dr_val, nb_bits);
  jtag_unlock();
  return ret;
}

void init_jtag(void) {
  fd = open("/tmp/.jtaglock", O_RDONLY | O_CREAT);
  assert(fd != -1);
}
