#define DRAM_BASE 0x100000000

.section .text.start, "ax", @progbits
.globl _start
_start:
  // csrwi 0x7c1, 0 // disable chicken bits
  li s0, DRAM_BASE
  csrr a0, mhartid
  la a1, _dtb
//   la a2, _real
//   jr a2
//   // mispred:
//   li a2, 0
//   div a1, a2, a2
// _real:
  jr s0

.section .text.hang, "ax", @progbits
.globl _hang
_hang:
  // csrwi 0x7c1, 0 // disable chicken bits
  csrr a0, mhartid
  la a1, _dtb
  // csrwi mie, 0
1:
  wfi
  j 1b

.section .rodata.dtb, "a", @progbits
.globl _dtb
.align 5, 0
_dtb:
.ascii "DTB goes here"
