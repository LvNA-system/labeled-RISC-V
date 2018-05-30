boot ?= JTAGBOOT

bootrom = bootrom_$(boot)
SRC = bootrom.S

ifeq ($(boot), MEMBOOT)
SRC += load_elf.c
endif

GCC=riscv64-unknown-linux-gnu-gcc
OBJCOPY=riscv64-unknown-linux-gnu-objcopy

all: $(bootrom).img

%.img: %.elf
	$(OBJCOPY) -O binary --change-addresses=-0x1000 --only-section .text $< $@

$(bootrom).elf: $(SRC)
	$(GCC) -D$(boot) -O2 -Tlinker.ld $^ -nostdlib -static -o $@
