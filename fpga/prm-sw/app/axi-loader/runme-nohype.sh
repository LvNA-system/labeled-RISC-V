#!/bin/bash

# Usage: bash runme-nohype.sh [board] [hartid]

base=(0x00000000 0x20000000 0x40000000 0x60000000)
size=(0x20000000 0x20000000 0x20000000 0x20000000)

board=$1
hartid=$2
dsid=$hartid

echo "rw=w,cp=core,tab=p,col=hartid,row=$hartid,val=0" | ../pardctl/build/pardctl-fpga
./build/axi-loader-fpga reset start $hartid
echo "rw=w,cp=core,tab=p,col=dsid,row=$hartid,val=$dsid" | ../pardctl/build/pardctl-fpga
echo "rw=w,cp=core,tab=p,col=base,row=$hartid,val=${base[$hartid]}" | ../pardctl/build/pardctl-fpga
echo "rw=w,cp=core,tab=p,col=size,row=$hartid,val=${size[$hartid]}" | ../pardctl/build/pardctl-fpga
./build/axi-loader-fpga $board linux-nosmp.bin ../../misc/configstr/configstr-nohype-core$hartid ${base[$hartid]}
./build/axi-loader-fpga reset end $hartid
