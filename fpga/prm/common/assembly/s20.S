# set step
#define DEBUG_RAM 0x400
#define DCSR 0x7b0
#define STEP_MASK 0x4
#define HALT_MASK 0x8
#define RESUME 0x804
.text
.global _start
_start:
lwu s0, (DEBUG_RAM + 12)(zero)
csrs DCSR, s0
j RESUME
data: .word  0
