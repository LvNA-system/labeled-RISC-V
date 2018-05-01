#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
lwu s1, (DEBUG_RAM + 16)(zero)
lwu s0, 0(s1)
sw s0, (DEBUG_RAM + 20)(zero)
j RESUME
address: .word 0
data: .word 0
