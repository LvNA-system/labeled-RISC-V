#!/bin/bash

# Usage: bash runme-nohype.sh [board] [hartid]

board=$1

axi_loader=./build/axi-loader-fpga


case $board in
  zedboard)
    nr_core=2
    ;;
  zcu102)
    nr_core=4
    ;;
  sidewinder)
    nr_core=4
    ;;
  ultraZ)
    nr_core=2
    ;;
  *)
    echo "unsupported board $board"
    exit
    ;;
esac

i=0
for (( i=0 ; i < $nr_core ; i=i+1 )) ;
do 
  $axi_loader reset start $hartid;
done

$axi_loader $board linux-smp.bin ../../misc/configstr/smp/$board 0

for (( i=0 ; i < $nr_core ; i=i+1 )) ;
do 
  $axi_loader reset end $hartid
done
