/*
 * Debug Module Interface
 */
struct DMI_Req {
  int opcode;
  int addr;
  int data;
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
