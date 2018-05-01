#define ENTRY 0x80000000
#define DPC 0x7b1
#define RESUME 0x804
.text
.global _start
_start:
li t0, ENTRY
csrw DPC, t0
j RESUME
