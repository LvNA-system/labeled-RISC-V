# get a1

#define DEBUG_RAM 0x400
#define RESUME 0x804
.text
.global _start
_start:
sd a1, (DEBUG_RAM + 8)(zero)
j RESUME
data: .dword 0
