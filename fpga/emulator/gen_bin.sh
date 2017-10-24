# file=../../../sw/riscv_bbl/build/bbl
file=bbl
riscv64-unknown-linux-gnu-objcopy -O binary $file bbl.bin
truncate -s %8 bbl.bin
hexdump -ve '2/ "%08x " "\n"' bbl.bin | awk '{print $2$1}' > ../build/bin.txt
