# get a2

#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
sd a2, (DEBUG_RAM + 8)(zero)
j RESUME
data: .dword 0
