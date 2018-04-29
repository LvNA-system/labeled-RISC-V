#ifndef __DMI_H__
#define __DMI_H__

/*
 * Debug Module Interface
 * This tracks rocketchip commit 87cbd5c89391763d42a8ffbdcf48548f68de0bb1
 * I do not know which version of debug spec it complies with
 */
#include "common.h"
#include "util.h"
#include "jtag.h"

// ia32 and x86-64 cpus are little ending
// be careful about the fields ordering here
// higher bits(such as the interrupt field) should
// follow the lower bits(such as fullreset) in the structure definition
#define DMCONTROL_FIELDS \
  FIELD(fullreset, 1) \
  FIELD(ndreset, 1) \
  FIELD(hartid, 10) \
  FIELD(access, 3) \
  FIELD(autoincrement, 1) \
  FIELD(serial, 3) \
  FIELD(buserror, 3) \
  FIELD(reserved0, 10) \
  FIELD(haltnot, 1) \
  FIELD(interrupt, 1)

#define DMINFO_FIELDS \
  FIELD(version, 2) \
  FIELD(authtype, 2) \
  FIELD(authbusy, 1) \
  FIELD(authenticated, 1) \
  FIELD(reserved1, 3) \
  FIELD(haltsum, 1) \
  FIELD(dramsize, 6) \
  FIELD(accesss8, 1) \
  FIELD(access16, 1) \
  FIELD(access32, 1) \
  FIELD(access64, 1) \
  FIELD(access128, 1) \
  FIELD(serialcount, 4) \
  FIELD(abussize, 7) \
  FIELD(reserved0, 2)

#define SBADDR0_FIELDS \
  FIELD(addr, 32) \
  FIELD(rw, 1) \
  FIELD(busy, 1)

#define SBDATA0_FIELDS \
  FIELD(data, 32) \
  FIELD(reserved0, 2)

struct DMI_Req {
  int opcode;
  int addr;
  // data width is 34bits
  uint64_t data;
};

struct DMI_Resp {
  int state;
  uint64_t data;
};

#define OP_NONE 0
#define OP_READ 1
#define OP_WRITE 2

#define RESP_SUCCESS 0

#define FIELD(name, bits) uint32_t name : bits;

#define DEF(name) struct name { name ## _FIELDS }__attribute__((packed))

DEF(DMCONTROL);
DEF(DMINFO);
DEF(SBADDR0);
DEF(SBDATA0);

#undef FIELD

static inline uint64_t req_to_bits(struct DMI_Req req) {
  uint64_t opcode = get_bits(req.opcode, DEBUG_OP_BITS - 1, 0);
  uint64_t addr = get_bits(req.addr, DEBUG_ADDR_BITS - 1, 0);
  uint64_t data = get_bits(req.data, DEBUG_DATA_BITS - 1, 0);
  uint64_t req_bits = (addr << (DEBUG_OP_BITS + DEBUG_DATA_BITS)) |
    (data << DEBUG_OP_BITS) | opcode;
  return req_bits;
}

static inline struct DMI_Resp bits_to_resp(uint64_t val) {
  struct DMI_Resp resp;
  resp.state = get_bits(val, DEBUG_OP_BITS - 1, 0);
  resp.data = get_bits(val, DEBUG_DATA_BITS + DEBUG_OP_BITS - 1, DEBUG_OP_BITS);
  return resp;
}

static inline struct DMI_Resp send_debug_request(struct DMI_Req req) {
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
  return d_resp;
}

static inline uint64_t rw_debug_reg(int opcode, uint32_t addr, uint64_t data) {
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

#endif
