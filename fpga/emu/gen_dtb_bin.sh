#!/usr/bin/env bash

BUILD_DIR=$1

for i in $(ls $1/c*.dtb)
do
    sh gen_bin.sh $i $i.txt
done
