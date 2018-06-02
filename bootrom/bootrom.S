.text
.global _start
_start:
#if defined(DIRECTBOOT)
  li t0, 0x100000000
  jr t0
#elif defined(MEMBOOT)
  j test_ddr
#else
// wait for external controller to load prgram and bring us up
1:
  j 1b
#endif
  .word 0 // reserved
  .word 0 // reserved
  .word 0 // pointer to config string
  .word 0 // default trap vector
  .word 0
  .word 0
  .word 0

#ifdef MEMBOOT
test_ddr:
  csrwi 0x800, 1
  li sp, 0x40000000
  call load_elf
  csrwi 0x800, 0
  jr a0
#endif
