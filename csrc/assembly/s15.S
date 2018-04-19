# get s0

#define DEBUG_RAM 0x400
#define RESUME 0x804
#define DSCRATCH 0x7b2

.text
.global _start
_start:
ld t0, (DEBUG_RAM + 16)(zero)
csrw DSCRATCH, t0
j RESUME
padding: .word 0
data: .dword 0
