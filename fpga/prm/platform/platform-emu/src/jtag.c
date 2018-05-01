#include "common.h"
#include "util.h"
#include "vpi.h"
#include "jtag.h"

#define DEBUG_INFO 0

ssize_t server_send(const void *buf, size_t len, int flags);
int server_recv(char *buf, int size);

// ********************* jtag related functions ******************************
// do tms_seq
// used for modify tap state
static void seq(const char *str) {
  if (DEBUG_INFO)
    printf("CMD_TMS_SEQ\n");

  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_TMS_SEQ;
  str_to_bits(str, &command.length, &command.nb_bits, command.buffer_out);
  server_send(&command, sizeof(command), 0);
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
      &command.length, &command.nb_bits, command.buffer_out);
  server_send(&command, sizeof(command), 0);

  int ret = server_recv((char *)&command, sizeof(command));
  assert(ret);
  // since we are shift in and out bits from a single chain
  // so the number of bits shifted out == number of bits shifted in
  assert(command.nb_bits == nb_bits);
  return shift_bits_outof_buffer(command.nb_bits, command.buffer_in);
}

// goto test logic reset state
void reset_soft(void) {
  if (DEBUG_INFO)
    printf("CMD_RESET\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET_SOFT;
  server_send(&command, sizeof(command), 0);
}

static inline void reset_hard(void) {
  if (DEBUG_INFO)
    printf("CMD_RESET_HARD\n");
  struct vpi_cmd command;
  memset(&command, 0, sizeof(command));
  command.cmd = CMD_RESET;
  server_send(&command, sizeof(command), 0);
}



// write value to ir, and return the old value of ir
static void write_ir(uint64_t value) {
  // first, we need to move from test logic reset to shift ir state
  seq("1100");

  // shift in the new ir values
  uint64_t ret_value = scan(value, IR_BITS);
  // JTAG spec only says that the initial value of ir must end with 'b01.
//  assert(ret_value & 0x1);
  if (!(ret_value & 0x1)) {
    printf("warning: JTAG spec only says that the initial value of ir must end with 'b01.\n");
  }

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

