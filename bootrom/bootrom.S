.text
.global _start
_start:
  // This boot ROM doesn't know about any boot devices, so it just spins,
  // waiting for the debugger to load a program and change the PC.
  j here
  .word 0 // reserved
  .word 0 // reserved
  .word 0 // pointer to config string
  .word 0 // default trap vector
  .word 0
  .word 0
  .word 0
here:
  li a2, 0x80000000
  lh a1, 0(a2)
  li a0, 0x006f
  bne a0, a1, loop
  tail 0x80000000
loop:
  wfi
  j loop
