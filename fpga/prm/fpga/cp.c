#include "dmi.h"

uint32_t read_cp_reg(int addr) {
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
  return resp.data;
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
