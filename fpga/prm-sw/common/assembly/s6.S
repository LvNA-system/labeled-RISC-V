#define DEBUG_RAM 0x400
#define DPC 0x7b1
#define RESUME 0x804
.text
.global _start
_start:
lwu s0, (DEBUG_RAM + 12)(zero)
csrw DPC, s0
j RESUME
data: .word  0
