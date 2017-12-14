#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <assert.h>

#include "JTAGDTM.h"
#include "dmi.h"

#define DEBUG_INFO 0

// server fd
int sfd;

// ********************* utility functions ******************************

// get bits in range [high, low]
uint64_t get_bits(uint64_t data, int high, int low) {
  assert(high >= low && high <= 63 && low >= 0);
  int left_shift = 63 - high;
  // firstly, remove the higher bits, then remove the lower bits
  return ((data << left_shift) >> left_shift) >> low;
}

int get_bit(unsigned char value, int index) {
  assert(index >= 0 && index <= 7);
  return (value >> index) & 0x1;
}

void set_bit(unsigned char &value, int index, int bit) {
  assert(index >= 0 && index <= 7 && (bit == 0 || bit == 1));
  unsigned char mask = 1 << index;
  if (bit) {
	// set bit
	value |= mask;
  } else {
	// clear bit
	value &= ~mask;
  }
}

void str_to_bits(const char *str, int &length,
	int &nb_bits, unsigned char *buffer) {
  nb_bits = 0;
  while (*str) {
	assert(*str == '0' || *str == '1');
	// which byte are we handling?
	int index = nb_bits / 8;
	set_bit(buffer[index], nb_bits % 8, *str - '0');
	str++;
	nb_bits++;
	assert(nb_bits <= XFERT_MAX_SIZE * 8);
  }
  length = (nb_bits + 7) / 8;
}

char *bits_to_str(int length,
	int nb_bits, unsigned char *buffer) {
  assert(nb_bits <= XFERT_MAX_SIZE * 8);
  char *str = (char *)malloc(sizeof(char) * (nb_bits + 1));
  assert(str);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	int bit = get_bit(buffer[index], i % 8);
	str[i] = '0' + bit;
  }
  str[nb_bits] = '\0';
  return str;
}

// shift a uint64_t value into a buffer
void shift_bits_into_buffer(uint64_t value, int nb_bits,int &ret_length,
	int &ret_nb_bits, unsigned char *buffer) {
  assert(nb_bits > 0 && nb_bits <= 64);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	set_bit(buffer[index], i % 8, value & 0x1);
	value >>= 1;
  }
  ret_nb_bits = nb_bits;
  ret_length = (nb_bits + 7) / 8;
}

// shift a uint64_t value out of a buffer
uint64_t shift_bits_outof_buffer(int nb_bits, 
	unsigned char *buffer) {
  assert(nb_bits > 0 && nb_bits <= 64);
  uint64_t value = 0;
  // 1 should be unsigned long long
  // if we simply write 1
  // it will be int32_t and sign extended to 64bit, which means mask will be 0xffffffff80000000
  uint64_t mask = 1ULL << (nb_bits - 1);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	int bit = get_bit(buffer[index], i % 8);
	// be careful about the bit order here
	value >>= 1;
	if (bit)
	  value |= mask;
	// printf("bit: %d valud: %lx\n", bit, value);
  }
  return value;
}


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
void reset() {
  if (DEBUG_INFO)
	printf("CMD_RESET\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET;
  send(sfd, &command, sizeof(command), 0);
}

void reset_hard() {
  if (DEBUG_INFO)
	printf("CMD_RESET_HARD\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET_HARD;
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
  reset();
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
  { "data0",     0x04, NULL,           default_resp   },
  { "data1",     0x05, NULL,           default_resp   },
  { "dmcontrol", 0x10, DMCONTROL_REQ,  DMCONTROL_RESP },
  { "dminfo",  0x11, NULL,             DMINFO_RESP  },
  { "hartinfo",  0x12, NULL,           NULL           },
  { "haltsum",   0x13, NULL,           NULL           },
  { "sbaddress0", 0x39, default_req, default_resp },
  { "sbaddress1", 0x3a, default_req, default_resp },
  { "sbaddress2", 0x3b, default_req, default_resp },
  { "sbdata0", 0x3c, default_req, default_resp },
};


uint64_t req_to_bits(struct DMI_Req req) {
  uint64_t opcode = get_bits(req.opcode, DEBUG_OP_BITS - 1, 0);
  uint64_t addr = get_bits(req.addr, DEBUG_ADDR_BITS - 1, 0);
  uint64_t data = get_bits(req.data, DEBUG_DATA_BITS - 1, 0);
  // printf("opcode: %lx addr: %lx data: %lx\n", opcode, addr, data);
  uint64_t req_bits = (addr << (DEBUG_OP_BITS + DEBUG_DATA_BITS)) |
	(data << DEBUG_OP_BITS) | opcode;
  // printf("bits: %lx\n", req_bits);
  return req_bits;
}

struct DMI_Resp bits_to_resp(uint64_t val) {
  struct DMI_Resp resp;
  resp.state = get_bits(val, DEBUG_OP_BITS - 1, 0);
  // printf("state: %lx\n", get_bits(val, DEBUG_OP_BITS - 1, 0));
  resp.data = get_bits(val, DEBUG_DATA_BITS + DEBUG_OP_BITS - 1, DEBUG_OP_BITS);
  // printf("data: %lx\n", get_bits(val, DEBUG_DATA_BITS + DEBUG_OP_BITS - 1, DEBUG_OP_BITS));
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
  // printf("resp: %lx\n", resp);
  struct DMI_Resp d_resp = bits_to_resp(resp);
  // printf("state: %x data: %x\n", d_resp.state, d_resp.data);
  return d_resp;
}

int main(int argc, char *argv[]) {
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
  server.sin_port = htons(8080);

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

  struct DMI_Req req;
  struct DMI_Resp resp;
  char msg[1024];
  while (1) {
	printf("> ");
	fflush(stdout);
	memset(&req, 0, sizeof(req));
	memset(&resp, 0xff, sizeof(resp));

	scanf("%s", msg);
	if      (strcmp(msg, "read")  == 0) req.opcode = OP_READ;
	else if (strcmp(msg, "write") == 0) req.opcode = OP_WRITE;
	else if (strcmp(msg, "quit")  == 0) break;

	scanf("%s", msg);
	int i = 0;
	for (; i < sizeof(entries) / sizeof(entries[0]); i++) {
	  if (strcmp(entries[i].name, msg) == 0) {
		break;
	  }
	}
	if (i == sizeof(entries) / sizeof(entries[0])) {
	  printf("not found %s\n", msg);
	  continue;
	}

	req.addr = entries[i].addr;

	if (req.opcode == OP_WRITE) {
	  req.opcode = OP_READ;
	  resp = send_debug_request(req);
	  if (resp.state != 0) {
		puts("access failed");
		continue;
	  }
	  req.opcode = OP_WRITE;
	  req.data = resp.data;
	  fgets(msg, sizeof(msg), stdin);
	  entries[i].req_builder(&req, msg);
      // printf("bits: %lx\n", req.data);

	  resp = send_debug_request(req);
	  if (resp.state != 0) {
		puts("access failed");
		continue;
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

  close(sfd);
  return 0;
}
