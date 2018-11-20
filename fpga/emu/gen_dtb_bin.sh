#!/usr/bin/env bash

if [ ! $1 ]
then
    echo "Please specify the device tree source name (without extension)"
    exit
fi

SCRIPT=$(realpath $0)
BUILD_ROOT=$(dirname $SCRIPT)/../build
DTS=$BUILD_ROOT/$1.dts
DTB=$BUILD_ROOT/$1.dtb
TXT=$DTB.txt
dtc $DTS -o $DTB
sh gen_bin.sh $DTB $TXT
