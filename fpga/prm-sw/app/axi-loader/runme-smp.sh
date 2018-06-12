#!/bin/bash

# Usage: bash runme-smp.sh [board]

board=$1

axi_loader=./build/axi-loader-fpga
pardctl=../pardctl/build/pardctl-fpga

case $board in
  zedboard)
    nr_core=2
    mem_size=0x10000000
    ;;
  zcu102)
    nr_core=4
    mem_size=0x80000000
    ;;
  sidewinder)
    nr_core=4
    mem_size=0x80000000
    ;;
  ultraZ)
    nr_core=2
    mem_size=0x40000000
    ;;
  *)
    echo "unsupported board $board"
    exit
    ;;
esac

i=0
for (( i=0 ; i < $nr_core ; i=i+1 )) ;
do 
  $axi_loader reset start $i
  echo "rw=w,cp=core,tab=p,col=hartid,row=$i,val=$i" | $pardctl
  echo "rw=w,cp=core,tab=p,col=dsid,row=$i,val=$i" | $pardctl
  echo "rw=w,cp=core,tab=p,col=base,row=$i,val=0x100000000" | $pardctl
  echo "rw=w,cp=core,tab=p,col=size,row=$i,val=$mem_size" | $pardctl
done

$axi_loader $board linux-smp.bin ../../misc/configstr/smp/$board 0

for (( i=0 ; i < $nr_core ; i=i+1 )) ;
do 
  $axi_loader reset end $i
done
