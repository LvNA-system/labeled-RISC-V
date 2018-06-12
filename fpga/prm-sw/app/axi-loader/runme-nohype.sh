#!/bin/bash

# Usage: bash runme-nohype.sh [board] [hartid]

board=$1
hartid=$2
dsid=$hartid

axi_loader=./build/axi-loader-fpga
pardctl=../pardctl/build/pardctl-fpga

if [ $board = "zedboard" ];
then
  base=(0x00000000 0x08000000)
  size=(0x08000000 0x08000000);
else
  base=(0x00000000 0x20000000 0x40000000 0x60000000)
  size=(0x20000000 0x20000000 0x20000000 0x20000000);
fi


echo "rw=w,cp=core,tab=p,col=hartid,row=$hartid,val=0" | $pardctl
$axi_loader reset start $hartid
echo "rw=w,cp=core,tab=p,col=dsid,row=$hartid,val=$dsid" | $pardctl
echo "rw=w,cp=core,tab=p,col=base,row=$hartid,val=${base[$hartid]}" | $pardctl
echo "rw=w,cp=core,tab=p,col=size,row=$hartid,val=${size[$hartid]}" | $pardctl
$axi_loader $board linux.bin ../../misc/configstr/nohype/$board/core$hartid ${base[$hartid]}
$axi_loader reset end $hartid
