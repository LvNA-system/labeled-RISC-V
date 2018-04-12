# set halt

#define DCSR 0x7b0
#define HALT_MASK 0x8
#define RESUME 0x804
.text
.global _start
_start:
csrsi DCSR, HALT_MASK
j RESUME
