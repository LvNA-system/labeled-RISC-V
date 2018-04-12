# get a0

#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
sd a0, (DEBUG_RAM + 8)(zero)
j RESUME
data: .dword 0
