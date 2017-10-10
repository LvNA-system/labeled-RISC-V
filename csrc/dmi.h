/*
 * Debug Module Interface
 */
#include <stdint.h>

#define DMCONTROL_FIELDS \
  FIELD(dmactive, 1) \
  FIELD(ndmreset, 1) \
  FIELD(_1, 14) \
  FIELD(hartsel, 10) \
  FIELD(hasel, 1) \
  FIELD(_2, 2) \
  FIELD(hartreset, 1) \
  FIELD(resumereq, 1) \
  FIELD(haltreq, 1)

#define DMSTATUS_FIELDS \
  FIELD(version, 4) \
  FIELD(cfgstrvalid, 1) \
  FIELD(_1, 1) \
  FIELD(authbusy, 1) \
  FIELD(authenticated, 1) \
  FIELD(anyhalted, 1) \
  FIELD(allhalted, 1) \
  FIELD(anyrunning, 1) \
  FIELD(allrunning, 1) \
  FIELD(anyunavail, 1) \
  FIELD(allunavail, 1) \
  FIELD(anynonexistent, 1) \
  FIELD(allnonexistent, 1) \
  FIELD(anyresumeack, 1) \
  FIELD(allresumeack, 1) \
  FIELD(_2, 14)

#define ABSTRACTS_FIELDS \
  FIELD(datacount, 5) \
  FIELD(_1, 3) \
  FIELD(cmderr, 3) \
  FIELD(_2, 1) \
  FIELD(busy, 1) \
  FIELD(_3, 11) \
  FIELD(progsize, 5) \
  FIELD(_4, 3)

#define COMMAND_FIELDS \
  FIELD(regno, 16) \
  FIELD(write, 1) \
  FIELD(transfer, 1) \
  FIELD(postexec, 1) \
  FIELD(_1, 1) \
  FIELD(size, 3) \
  FIELD(_2, 1) \
  FIELD(cmdtype, 8)

#define SBCS_FIELDS \
  FIELD(sbaccess8, 1) \
  FIELD(sbaccess16, 1) \
  FIELD(sbaccess32, 1) \
  FIELD(sbaccess64, 1) \
  FIELD(sbaccess128, 1) \
  FIELD(sbasize, 7) \
  FIELD(sberror, 3) \
  FIELD(sbautoread, 1) \
  FIELD(sbautoincrement, 1) \
  FIELD(sbaccess, 3) \
  FIELD(sbsingleread, 1) \
  FIELD(_1, 11)

struct DMI_Req {
  int opcode;
  int addr;
  int data;
};

struct DMI_Resp {
  int state;
  int data;
};

#define OP_NONE 0
#define OP_READ 1
#define OP_WRITE 2

#define RESP_SUCCESS 0

#define FIELD(name, bits) uint32_t name : bits;

#define DEF(name) struct name { name ## _FIELDS }

DEF(DMCONTROL);
DEF(DMSTATUS);
DEF(ABSTRACTS);
DEF(COMMAND);
DEF(SBCS);

#undef FIELD
