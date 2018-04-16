#ifndef JTAG_VPI_H
#define JTAG_VPI_H
#include <assert.h>

// VPI parts
#define	XFERT_MAX_SIZE	512

#define CMD_RESET		0
#define CMD_TMS_SEQ		1
#define CMD_SCAN_CHAIN		2
#define CMD_SCAN_CHAIN_FLIP_TMS	3
#define CMD_STOP_SIMU		4
#define CMD_RESET_SOFT    5

const char * cmd_to_string_table[] = {
  "CMD_RESET",
  "CMD_TMS_SEQ",
  "CMD_SCAN_CHAIN",
  "CMD_SCAN_CHAIN_FLIP_TMS",
  "CMD_STOP_SIMU",
  "CMD_RESET_SOFT"
};

static inline const char *cmd_to_string(int cmd) {
  assert(cmd >= 0 && cmd < 6);
  return cmd_to_string_table[cmd];
}

struct vpi_cmd {
	int cmd;
	unsigned char buffer_out[XFERT_MAX_SIZE];
	unsigned char buffer_in[XFERT_MAX_SIZE];
	int length;
	int nb_bits;
};

// Jtag parts
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

#endif
