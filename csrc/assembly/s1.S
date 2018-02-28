.text
.global _start
_start:
#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
// during program loading, the core is runing a loop in bootrom
// no one needs t0(bootrom + debug rom)
// we can safely override it
lwu t0, (DEBUG_RAM + 8)(zero)
j RESUME
address:.word 0
