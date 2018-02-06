#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
lwu s0, (DEBUG_RAM + 16)(zero)
sw s0, 0(t0)
addi t0, t0, 4
j RESUME
data: .word 0
