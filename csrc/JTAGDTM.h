#ifndef JTAG_VPI_H
#define JTAG_VPI_H
#include <assert.h>

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

const char *cmd_to_string(int cmd) {
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
#endif
