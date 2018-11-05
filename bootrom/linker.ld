SECTIONS
{
    ROM_BASE = 0x10000; /* ... but actually position independent */

    . = ROM_BASE;
    .text.hang : { *(.text.hang) }
    . = ROM_BASE + 0x40;
    .text.start : { *(.text.start) }
    . = ROM_BASE + 0x80;
    .rodata.dtb : { *(.rodata.dtb) }
}
