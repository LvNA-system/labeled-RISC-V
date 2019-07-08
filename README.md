# Labeled RISC-V based on Rocketchip

We build our labeled RISC-V prototype based on rocketchip.

# Quick Start Guide

>Ubuntu 16 recommend.（Don't use Ubunt 19.）

## Get source code

···bash
sudo apt install git vim
cd ~/Downloads
git clone https://github.com/LvNA-system/labeled-RISC-V.git
···

## Sub-directories
```
.
├── board              # supported FPGA boards and files to build a Vivado project
├── boot               # PS boot flow of zynq and zynqmp
├── doc                # some development documents (but in Chinese...)
├── emu                # wrapper of the original rocketchip/emulator to support fast memory initializaion
├── lib                # HDL sources shared by different boards
├── Makefile
├── Makefile.check
├── Makefile.sw
├── pardcore           # wrapper of rocketchip in the Vivado project
└── README.md          # this file
```

## Before Install
Ubuntu Packages needed
···bash
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
···

java needed
···bash
sudo apt-get install openjdk-8-jdk
···

## Get Tool-Chains
If you are using ICT' network such as ICT_Guest or ICT_WLAN, you can download tool-chains from [http://10.30.6.127:8000/riscv-toolchain-2018.05.24.tar.gz](http://10.30.6.127:8000/riscv-toolchain-2018.05.24.tar.gz)

Extract the `tar.gz` to `~/Downloads`

Now your `~/Downloads` Directory looks like this:
```
.
├── labeld-RISC-V             
└── riscv-toolchain-2018.05.24         
```

## Set Envelopment Variables - PATH

## Build
···bash
cd 
