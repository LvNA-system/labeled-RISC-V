#ifndef DMI_H
#define DMI_H

/*
 * Debug Module Interface
 * This tracks rocketchip commit 87cbd5c89391763d42a8ffbdcf48548f68de0bb1
 * I do not know which version of debug spec it complies with
 */
#include <stdint.h>

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

#define SBDATA1_FIELDS \
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
DEF(SBDATA1);

#undef FIELD

#endif
