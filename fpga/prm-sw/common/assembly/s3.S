#define ENTRY 0x100000000
#define DCSR 0x7b0
#define DPC 0x7b1
#define RESUME 0x804
.text
.global _start
_start:
ld t0, addr
csrw DPC, t0
csrsi DCSR, 3   # set dcsr.prv to machine mode
j RESUME

.align 3
addr:
.quad 0
