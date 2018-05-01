#define DEBUG_RAM 0x400
#define DPC 0x7b1
#define RESUME 0x804
.text
.global _start
_start:
csrr  s0, DPC
sd s0, (DEBUG_RAM + 16)(zero)
j RESUME
padding: .word  0
data: .dword 0
