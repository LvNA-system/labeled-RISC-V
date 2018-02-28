boot ?= JTAGBOOT

bootrom = bootrom_$(boot)

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy

all: $(bootrom).img

%.img: %.elf
	$(OBJCOPY) -O binary --change-addresses=-0x1000 --only-section .text $< $@

$(bootrom).elf: bootrom.S linker.ld
	$(GCC) -D$(boot) -Tlinker.ld $< -nostdlib -static -o $@
