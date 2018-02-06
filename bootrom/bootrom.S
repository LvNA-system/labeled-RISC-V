.text
.global _start
_start:
// wait for external controller to load prgram and bring us up
1:
  j 1b
  .word 0 // reserved
  .word 0 // reserved
  .word 0 // pointer to config string
  .word 0 // default trap vector
  .word 0
  .word 0
  .word 0
