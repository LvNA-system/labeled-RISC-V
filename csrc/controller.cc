#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <assert.h>
#include <string>

#include "JTAGDTM.h"
#include "dmi.h"
#include "common.h"

#define DEBUG_INFO 0

using std::string;

// server fd
int sfd;

// ********************* jtag related functions ******************************
// do tms_seq
// used for modify tap state
void seq(const char *str) {
  if (DEBUG_INFO)
	printf("CMD_TMS_SEQ\n");

  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_TMS_SEQ;
  str_to_bits(str, command.length, command.nb_bits, command.buffer_out);
  send(sfd, &command, sizeof(command), 0);
}

uint64_t scan(uint64_t value, int nb_bits) {
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

  assert(recv(sfd, &command, sizeof(command), 0) > 0);
  // since we are shift in and out bits from a single chain
  // so the number of bits shifted out == number of bits shifted in
  assert(command.nb_bits == nb_bits);
  // printf("nb_bits: %d\n", nb_bits);
  return shift_bits_outof_buffer(command.nb_bits, command.buffer_in);
}

// // goto test logic reset state
// goto test logic reset state
void reset_soft() {
  if (DEBUG_INFO)
	printf("CMD_RESET\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET_SOFT;
  send(sfd, &command, sizeof(command), 0);
}

void reset_hard() {
  if (DEBUG_INFO)
	printf("CMD_RESET_HARD\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET;
  send(sfd, &command, sizeof(command), 0);
}

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



// write value to ir, and return the old value of ir
void write_ir(uint64_t value) {
  // first, we need to move from test logic reset to shift ir state
  seq("01100");

  // printf("value: %lx\n", value);
  // shift in the new ir values
  uint64_t ret_value = scan(value, IR_BITS);
  // JTAG spec only says that the initial value of ir must end with 'b01.
  // printf("ret_value: %lx\n", ret_value);
  assert(ret_value & 0x1);

  // update ir and advance to run test idle state
  seq("0110");
}

// write value to dr, and return the old value of dr
uint64_t write_dr(uint64_t value, int nb_bits) {
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
  reset_soft();
  write_ir(ir_val);
  return write_dr(dr_val, nb_bits);
}


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
	printf("%s: %x\n", s, msg->name); \
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

void default_req(struct DMI_Req *req, char *msg)
{
  req->data = strtoll(msg, NULL, 16);
}

void default_resp(struct DMI_Resp *resp)
{
  printf("%lx\n", resp->data);
}

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


uint64_t req_to_bits(struct DMI_Req req) {
  uint64_t opcode = get_bits(req.opcode, DEBUG_OP_BITS - 1, 0);
  uint64_t addr = get_bits(req.addr, DEBUG_ADDR_BITS - 1, 0);
  uint64_t data = get_bits(req.data, DEBUG_DATA_BITS - 1, 0);
  uint64_t req_bits = (addr << (DEBUG_OP_BITS + DEBUG_DATA_BITS)) |
	(data << DEBUG_OP_BITS) | opcode;
  return req_bits;
}

struct DMI_Resp bits_to_resp(uint64_t val) {
  struct DMI_Resp resp;
  resp.state = get_bits(val, DEBUG_OP_BITS - 1, 0);
  resp.data = get_bits(val, DEBUG_DATA_BITS + DEBUG_OP_BITS - 1, DEBUG_OP_BITS);
  return resp;
}

struct DMI_Resp send_debug_request(struct DMI_Req req) {
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

void handle_debug_request(char *command, char *reg, char *values) {
  struct DMI_Req req;
  struct DMI_Resp resp;
  char *msg;
  if (DEBUG_INFO)
	printf("%s %s %s\n", command, reg, values);
  fflush(stdout);
  memset(&req, 0, sizeof(req));
  memset(&resp, 0xff, sizeof(resp));

  msg = command;
  if      (strcmp(msg, "read")  == 0) req.opcode = OP_READ;
  else if (strcmp(msg, "write") == 0) req.opcode = OP_WRITE;

  msg = reg;
  int i = 0;
  for (; i < sizeof(entries) / sizeof(entries[0]); i++) {
	if (strcmp(entries[i].name, msg) == 0) {
	  break;
	}
  }
  if (i == sizeof(entries) / sizeof(entries[0])) {
	printf("not found %s\n", msg);
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
	msg = values;
	entries[i].req_builder(&req, msg);

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

// control plane address space
int cpAddrSize = 32;
int cpDataSize = 32;

// control plane register address space;
// 31     23        21     11       0;
// +-------+--------+-------+-------+;
// | cpIdx | tabIdx |  col  |  row  |;
// +-------+--------+-------+-------+;
//  \- 8 -/ \-  2 -/ \- 10-/ \- 12 -/;
int rowIdxLen = 12;
int colIdxLen = 10;
int tabIdxLen = 2;
int cpIdxLen = 8;

int rowIdxLow = 0;
int colIdxLow = rowIdxLow + rowIdxLen;
int tabIdxLow = colIdxLow + colIdxLen;
int cpIdxLow  = tabIdxLow + tabIdxLen;

int rowIdxHigh = colIdxLow - 1;
int colIdxHigh = tabIdxLow - 1;
int tabIdxHigh = cpIdxLow  - 1;
int cpIdxHigh  = 31;

// control plane index;
int coreCpIdx = 0;
int memCpIdx = 1;
int cacheCpIdx = 2;
int ioCpIdx = 3;

// tables;
int ptabIdx = 0;
int stabIdx = 1;
int ttabIdx = 2;

int get_cp_addr(int cpIdx, int tabIdx, int col, int row) {
  int addr = cpIdx << cpIdxLow | tabIdx << tabIdxLow | col << colIdxLow | row << rowIdxLow;
  printf("cpIdx: %d, tabIdx: %d, col: %d, row: %d addr: %x\n", cpIdx, tabIdx, col, row, addr);
  return addr;
}

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

void help() {
  fprintf(stderr, "Command format:\n"
	  "\trw=r/w,cp=%%s,tab=%%s,col=%%s,row=%%x[,val=%%x]\n"
	  "Example:\n"
	  "\t1. read cache miss counter of dsid 1:\n"
	  "\t   rw=r,cp=cache,tab=s,col=miss,row=1\n"
	  "\t2. change waymask of dsid 1:\n"
	  "\t   rw=r,cp=cache,tab=p,col=mask,row=1,val=0xf\n");
}

void invalid_command() {
  fprintf(stderr, "Invalid command, use \"help\" to see the command format\n");
}

int string_to_idx(char *name, char **table, int size) {
  for (int i = 0; i < size; i++)
	if (!strcmp(name, table[i]))
	  return i;
  return -1;
}

char *rw_tables[] = {"r","w"};
char *cp_tables[] = {"core", "mem", "cache","io"};

char *tab_tables[3][3] = {
  {"p"},
  {"p"},
  {"p", "s"},
};

char *col_tables[3][3][4] = {
  {{"dsid", "base", "size", "hartid"}},
  {{"size", "freq", "inc"}},
  {{"mask"}, {"access", "miss"}},
};

int main(int argc, char *argv[]) {
  srand(time(NULL));
  int port;
  bool automatic_test = false;
  for (int i = 1; i < argc; i++) {
	std::string arg = argv[i];
	if (arg.substr(0, 2) == "-p")
	  port = atoi(argv[i]+2);
	else if (arg.substr(0, 2) == "-a")
	  automatic_test = true;
  }

  // Socket
  sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd == -1) {
	perror("Failed to create socket");
	exit(-1);
  }

  // Config server
  struct sockaddr_in server;
  server.sin_addr.s_addr = inet_addr("127.0.0.1");
  server.sin_family = AF_INET;
  server.sin_port = htons(port == 0 ? 8080 : port);

  // Connect
  if (connect(sfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
	perror("Connect failed");
	exit(-1);
  }

  puts("Connected\n");

  reset_hard();

  // get dtm info
  uint64_t dtminfo = rw_jtag_reg(REG_DTM_INFO, 0, REG_DTM_INFO_WIDTH);

  int dbusIdleCycles = get_bits(dtminfo, 12, 10);
  int dbusStatus = get_bits(dtminfo, 9, 8);
  int debugAddrBits = get_bits(dtminfo, 7, 4);
  int debugVersion = get_bits(dtminfo, 3, 0);

  printf("dbusIdleCycles: %d\ndbusStatus: %d\ndebugAddrBits: %d\ndebugVersion: %d\n",
	  dbusIdleCycles, dbusStatus, debugAddrBits, debugVersion);

  while (1) {
	if (!automatic_test) {
	  printf("> ");
	  fflush(stdout);
	  char buf[1024];
	  if(!fgets(buf, 1024, stdin))
		break;

	  int rw = -1;
	  int cpIdx = -1;
	  int tabIdx = -1;
	  int col = -1;
	  int row = -1;
	  int val = -1;

	  char *s = buf;
	  if (!strcmp(s, "help\n")) {
		help();
		continue;
	  }

	  while (s != NULL) {
		char *eq = strchr(s, '='); 
		if (!eq) {
		  invalid_command();
		  break;
		}
		*eq = '\0';

		char *field = s;
		char *value = eq + 1;

		s = strchr(eq + 1, ',');
		if (s != NULL) {
		  *s = '\0';
		  s++;
		}

		bool incorrect_order = false;

		if (!strcmp(field, "rw")) {
		  incorrect_order = rw != -1 || cpIdx != -1 || tabIdx != -1 ||
			col != -1 || row != -1 || val != -1;
		  if (incorrect_order ||
			  (rw = string_to_idx(value, rw_tables,sizeof(rw_tables) / sizeof(char *))) == -1) {
			invalid_command();
			break;
		  }
		} else if(!strcmp(field, "cp")) {
		  incorrect_order = rw == -1 || cpIdx != -1 || tabIdx != -1 ||
			col != -1 || row != -1 || val != -1;
		  if (incorrect_order ||
			  (cpIdx = string_to_idx(value, cp_tables,sizeof(cp_tables) / sizeof(char *))) == -1) {
			invalid_command();
			break;
		  }
		} else if(!strcmp(field, "tab")) {
		  incorrect_order = rw == -1 || cpIdx == -1 || tabIdx != -1 ||
			col != -1 || row != -1 || val != -1;
		  if (incorrect_order ||
			  (tabIdx = string_to_idx(value, tab_tables[cpIdx],sizeof(tab_tables[cpIdx]) / sizeof(char *))) == -1) {
			invalid_command();
			break;
		  }
		} else if(!strcmp(field, "col")) {
		  incorrect_order = rw == -1 || cpIdx == -1 || tabIdx == -1 ||
			col != -1 || row != -1 || val != -1;
		  if (incorrect_order ||
			  (col = string_to_idx(value, col_tables[cpIdx][tabIdx],sizeof(col_tables[cpIdx][tabIdx]) / sizeof(char *))) == -1) {
			invalid_command();
			break;
		  }
		} else if(!strcmp(field, "row")) {
		  incorrect_order = rw == -1 || cpIdx == -1 || tabIdx == -1 ||
			col == -1 || row != -1 || val != -1;
		  if (incorrect_order) {
			invalid_command();
			break;
		  }
		  row = (int)strtol(value, NULL, 16);
		  // read
		  if(rw == 0)
			read_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row));
		} else if(!strcmp(field, "val")) {
		  // only write needs val
		  incorrect_order = rw != 1 || cpIdx == -1 || tabIdx == -1 ||
			col == -1 || row == -1 || val != -1;
		  if (incorrect_order) {
			invalid_command();
			break;
		  }
		  val = (int)strtol(value, NULL, 16);
		  // execute the command
		  write_cp_reg(get_cp_addr(cpIdx, tabIdx,col, row), val);
		} else {
		  printf("invalid field\n");
		}
	  }
	} else {
	  /*
		 sleep(0);
		 int dsid = rand() % NDsids;
		 int size = rand() % 1000;
		 int freq = rand() % 1000;
		 int inc = rand() % 10;
		 int mask = rand();
		 change_size(dsid, size);
		 change_freq(dsid, freq);
		 change_inc(dsid, inc);
		 change_mask(dsid, mask);
		 */
	}
  }

  close(sfd);
  return 0;
}
