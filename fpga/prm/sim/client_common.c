#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>

#include "JTAGDTM.h"
#include "common.h"
#include "client_common.h"
#include "util.h"
#include <stdlib.h>

#define DEBUG_INFO 0


// server fd
static int sfd;

// ********************* jtag related functions ******************************
// do tms_seq
// used for modify tap state
static void seq(const char *str) {
  if (DEBUG_INFO)
    printf("CMD_TMS_SEQ\n");

  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_TMS_SEQ;
  str_to_bits(str, command.length, command.nb_bits, command.buffer_out);
  send(sfd, &command, sizeof(command), 0);
}

static uint64_t scan(uint64_t value, int nb_bits) {
  if (DEBUG_INFO)
    printf("CMD_SCAN_CHAIN\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  // if we do not use flip tms and do not take care of the last bit
  // we will transmit one more bit!
  command.cmd = CMD_SCAN_CHAIN_FLIP_TMS;
  shift_bits_into_buffer(value, nb_bits, 
      command.length, command.nb_bits, command.buffer_out);
  send(sfd, &command, sizeof(command), 0);

  assert(myrecv(sfd, (char *)&command, sizeof(command)));
  // since we are shift in and out bits from a single chain
  // so the number of bits shifted out == number of bits shifted in
  assert(command.nb_bits == nb_bits);
  return shift_bits_outof_buffer(command.nb_bits, command.buffer_in);
}

// goto test logic reset state
static inline void reset_soft(void) {
  if (DEBUG_INFO)
    printf("CMD_RESET\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET_SOFT;
  send(sfd, &command, sizeof(command), 0);
}

static void reset_hard(void) {
  if (DEBUG_INFO)
    printf("CMD_RESET_HARD\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET;
  send(sfd, &command, sizeof(command), 0);
}



// write value to ir, and return the old value of ir
static void write_ir(uint64_t value) {
  // first, we need to move from test logic reset to shift ir state
  seq("1100");

  // shift in the new ir values
  uint64_t ret_value = scan(value, IR_BITS);
  // JTAG spec only says that the initial value of ir must end with 'b01.
  assert(ret_value & 0x1);

  // update ir and advance to run test idle state
  seq("0110");
}

// write value to dr, and return the old value of dr
static uint64_t write_dr(uint64_t value, int nb_bits) {
  // advance to shift DR state
  seq("100");

  // shift in the new ir values
  uint64_t ret_value = scan(value, nb_bits);
  // printf("write_dr ret_value: %lx\n", ret_value);

  // update dr and advance to run test idle state
  seq("10");

  // when tms == 0, it will stay in test idle state
  // but still provides jtag tck clock
  // so that we can get everything in the jtag clock domain running
  for (int i = 0; i < 20; i++)
    seq("0");
  return ret_value;
}

uint64_t rw_jtag_reg(uint64_t ir_val, uint64_t dr_val, int nb_bits) {
//  reset_soft();
  write_ir(ir_val);
  return write_dr(dr_val, nb_bits);
}

#include "dmi.h"

// ********************* debug protocol related functions ******************************

#define STR(x) #x

#define CONCAT(x, y) x ## y

// Request builder definitions
#define FIELD(name, bits) if (strcmp(STR(name), s) == 0) { msg->name = value; continue; }

#define REQ(x) void CONCAT(x, _REQ)(struct DMI_Req *req, char *options) { \
  struct x *msg = (struct x *)&req->data; \
  for (char *s = strtok(options, " "); s != NULL; s = strtok(NULL, " ")) { \
    char *eq = strchr(s, '='); \
    *eq = '\0'; \
    uint32_t value = (uint32_t)strtol(eq + 1, NULL, 16); \
    CONCAT(x, _FIELDS) \
  } \
}

REQ(DMCONTROL);
REQ(SBADDR0);
REQ(SBDATA0);


#undef FIELD


// Response handler definitions
#define FIELD(name, bits) do { \
  const char *s = STR(name); \
  if (s[0] != '_') { \
    printf("%s: 0x%x\n", s, msg->name); \
  } \
} while(0);

#define RESP(x) void CONCAT(x, _RESP)(struct DMI_Resp *resp) { \
  struct x *msg = (struct x *)&resp->data; \
  CONCAT(x, _FIELDS) \
}

RESP(DMCONTROL);
RESP(DMINFO);
RESP(SBADDR0);
RESP(SBDATA0);


#undef FIELD

struct Entry {
  char name[20];
  uint32_t addr;
  void (*req_builder)(struct DMI_Req *, char *);
  void (*resp_handler)(struct DMI_Resp *);
};


struct Entry entries[] = {
  { "dmcontrol", 0x10, DMCONTROL_REQ, DMCONTROL_RESP },
  { "dminfo",  0x11, NULL, DMINFO_RESP  },
  { "sbaddr0", 0x16, SBADDR0_REQ, SBADDR0_RESP },
  { "sbdata0", 0x18, SBDATA0_REQ, SBDATA0_RESP }
};


// handle debug bus request
void handle_debug_request(const char *cmd, const char *reg, char *values) {
  struct DMI_Req req;
  struct DMI_Resp resp;
  if (DEBUG_INFO)
    printf("%s %s %s\n", cmd, reg, values);
  fflush(stdout);
  memset(&req, 0, sizeof(req));
  memset(&resp, 0xff, sizeof(resp));

  if      (strcmp(cmd, "read")  == 0) req.opcode = OP_READ;
  else if (strcmp(cmd, "write") == 0) req.opcode = OP_WRITE;

  unsigned int i = 0;
  for (; i < sizeof(entries) / sizeof(entries[0]); i++) {
    if (strcmp(entries[i].name, reg) == 0) {
      break;
    }
  }
  if (i == sizeof(entries) / sizeof(entries[0])) {
    printf("not found %s\n", reg);
  }

  req.addr = entries[i].addr;

  if (req.opcode == OP_WRITE) {
    req.opcode = OP_READ;
    resp = send_debug_request(req);
    if (resp.state != 0) {
      puts("access failed");
    }
    req.opcode = OP_WRITE;
    req.data = resp.data;
    entries[i].req_builder(&req, values);

    resp = send_debug_request(req);
    if (resp.state != 0) {
      puts("access failed");
    }
  }
  else if (req.opcode == OP_READ) {
    resp = send_debug_request(req);
    if (resp.state == 0) {
      entries[i].resp_handler(&resp);
    }
    else {
      puts("access failed");
    }
  }
}

// ********************* connection and initialization functions ******************************
void connect_server(const char *ip_addr, int port) {
  // Socket
  sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd == -1) {
    perror("Failed to create socket");
    exit(-1);
  }

  // Config server
  struct sockaddr_in server;
  server.sin_addr.s_addr = inet_addr(ip_addr);
  server.sin_family = AF_INET;
  server.sin_port = htons(port);

  // Connect
  if (connect(sfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect failed");
    exit(-1);
  }

  puts("Connected\n");
}

void disconnect_server(void) {
  close(sfd);
}

void init_dtm(void) {
  reset_hard();

  // get dtm info
  uint64_t dtminfo = rw_jtag_reg(REG_DTM_INFO, 0, REG_DTM_INFO_WIDTH);

  int dbusIdleCycles = get_bits(dtminfo, 12, 10);
  int dbusStatus = get_bits(dtminfo, 9, 8);
  int debugAddrBits = get_bits(dtminfo, 7, 4);
  int debugVersion = get_bits(dtminfo, 3, 0);

  printf("dbusIdleCycles: %d\ndbusStatus: %d\ndebugAddrBits: %d\ndebugVersion: %d\n",
      dbusIdleCycles, dbusStatus, debugAddrBits, debugVersion);
}

/* We use the ``readline'' library to provide more flexibility to read from stdin. */
char* rl_gets(void) {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }   

  line_read = readline("> ");

  if (line_read && *line_read) {
    add_history(line_read);
  }   

  return line_read;
}
