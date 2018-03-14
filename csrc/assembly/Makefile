GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy

all: s1.img s2.img s3.img s4.img

s1.img: s1.elf
	$(OBJCOPY) -O binary --change-addresses=-0x400 --only-section .text $< $@

s1.elf: s1.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -o $@
	riscv64-unknown-elf-objdump -d $@ >assembly_s1.S

s2.img: s2.elf
	$(OBJCOPY) -O binary --change-addresses=-0x400 --only-section .text $< $@

s2.elf: s2.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -o $@
	riscv64-unknown-elf-objdump -d $@ >assembly_s2.S

s3.img: s3.elf
	$(OBJCOPY) -O binary --change-addresses=-0x400 --only-section .text $< $@

s3.elf: s3.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -o $@
	riscv64-unknown-elf-objdump -d $@ >assembly_s3.S

s4.img: s4.elf
	$(OBJCOPY) -O binary --change-addresses=-0x400 --only-section .text $< $@

s4.elf: s4.S linker.ld
	$(GCC) -Tlinker.ld $< -nostdlib -static -o $@
	riscv64-unknown-elf-objdump -d $@ >assembly_s4.S
