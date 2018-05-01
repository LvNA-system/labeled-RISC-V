# get s1

#define RESUME 0x804

.text
.global _start
_start:
csrr s0, mhartid
csrr a0, mhartid
csrr x0, mhartid
csrr x1, mhartid
csrr x2, mhartid
csrr a0, mimpid
j RESUME
