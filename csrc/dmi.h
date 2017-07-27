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

#define FIELD(name, bits) uint32_t name : bits;
struct DMControl {
  DMCONTROL_FIELDS
};
#undef FIELD

struct DMI_Req {
  int opcode;
  int addr;
  union {
    int data;
    struct DMControl dmcontrol;
  };
};

struct DMI_Resp {
  int state;
  int data;
};

#define OP_EXIT -1
#define OP_NONE 0
#define OP_READ 1
#define OP_WRITE 2

#define RESP_SUCCESS 0
