#define GPIO_RESET_BASE_ADDR	0x41200000
#define JTAG_BASE_ADDR		0x43c00000

void init_map();
void resetn(int val);
void finish_map();
