#include "common.h"
#include "client_common.h"

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

