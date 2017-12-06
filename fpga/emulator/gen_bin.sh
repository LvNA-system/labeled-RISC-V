# if you are running Linux, use this
file=../../../sw/riscv_bbl/build/bbl
# if you are running hello, move the exe to ../build and rename it to "bbl"
# and uncomment the following line
# file=../build/bbl
riscv64-unknown-linux-gnu-objcopy --set-section-flags .bss=alloc,contents --set-section-flags .sbss=alloc,contents -O binary $file bbl.bin
truncate -s %8 bbl.bin
hexdump -ve '2/ "%08x " "\n"' bbl.bin | awk '{print $2$1}' > ../build/bin.txt
