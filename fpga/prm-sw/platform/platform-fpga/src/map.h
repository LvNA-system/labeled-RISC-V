//FIXME: switch between zynq and zynqmp
#define GPIO_RESET_BASE_ADDR	0x80010000
#define JTAG_BASE_ADDR		0x80011000

void init_map();
void resetn(int val);
void finish_map();
