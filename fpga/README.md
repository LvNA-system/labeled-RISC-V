## Quick Start Guide

### Build RISC-V image

* Build riscv-tools according to the instructions of [README.md under the root directory of this repo](../README.md).
* Build riscv-bbl (bootloader) and riscv-linux with the following command
```
make sw
```
If it is the first time you run this command, you will ask to pull the bbl and linux repo.
After that, `linux.bin` will be generated under `build/`.

### Run with emulator

Build and run emulator by
```
cd emulator
make run-emu
```
See `build/serial@60000000` for the output of UART.

### Run with FPGA

#### Build a vivado project

* Install Vivado 2017.4, and source the setting of Vivado and SDK
* Run the following command to build a vivado project
```
make project PRJ=myproject BOARD=zedboard
```
Change `zedboard` to the target board you want. Supported boards are listed under `board/`.
The project will be created under `build/myproject-zedboard`.
* Open the project with Vivado and generate bitstream.

#### Prepare SD card

Refer to the instructions of `board/your-target-board/boot/README.md` [(take zedboard as an example)](board/zedboard/boot/README.md).

NOTE: Remember to put the bitstream into BOOT.BIN, since the guide is going to boot everything from SD card.

#### Set your board to SD boot mode

Please refer to the user guide of your board.
* [zedboard](http://www.zedboard.org/sites/default/files/ZedBoard_HW_UG_v1_1.pdf)
* [zcu102](https://www.xilinx.com/support/documentation/boards_and_kits/zcu102/ug1182-zcu102-eval-bd.pdf)

#### Boot linux in PRM

NOTE: PRM is short for Platform Resource Manager, which is acted by PS part of the board.

* Insert the SD card into the board, open a serial terminal and powerup the board.
* Press any key to interrupt the default action in u-boot, and run the following commands to boot linux
```
load mmc 0:auto 0x3000000 Image
load mmc 0:auto 0x2a00000 system.dtb
booti 0x3000000 - 0x2a00000
```

#### Boot RISC-V subsystem

* Send the following files to PRM. This can be achieved by either copying the file to SD card, or by sending the file with `scp` if you have your board connected to your host by network.
  * `board/your-target-board/prm-loader/loader.c` [(take zedboard as an example)](board/zedboard/prm-loader/loader.c)
  * `board/your-target-board/prm-loader/configstr` [(take zedboard as an example)](board/zedboard/prm-loader/configstr)
  * `build/linux.bin`
* Compile the loader on PRM.
```
gcc -o loader loader.c
```
* Open minicom on PRM to connect to the UART of RISC-V subsystem. Note that you can connect to PRM via `ssh` and use `tmux` to get multiple terminals.
```
minicom -D /dev/ttyUL1
```
* Run loader to boot RISC-V subsystem.
```
./loader linux.bin configstr
```
It may cost about 100s for zedboard to boot the RISC-V subsystem. Most of the time is spent in unpacking ramdisk image.

### To Be Continued
