## 如何运行模拟

1. 进入 `riscv_fpga_pard/fpga/emulator` 执行 `make run-emu`最终生成的可执行文件是build/emu，输出到串口的内容在serial1000或者serial2000中。在运行hello时，可能输出的串口中内容有两份，这是正常的，因为有两个核，他们都在运行hello，且都输出到了串口中。
2. 在修改之后，建议先运行AM里面的hello程序。再运行bbl。运行的程序需要被objcopy成bin文件，并dump成bin.txt放到build目录下。
这个过程建议你看一下Makefile，手动hack一下。在生成bbl时要注意，由于busybox太大了，而我们仿真的ram太小了，所以需要把程序改成hello，记得改一改initramfs.txt以及若干文件。
3. 我们这个加载程序不是用的rocket原有的dmi接口，而是直接用的readmemh，把bin.txt给copy到仿真出来的内存中。readmemh是在sram init verilog中。这个verilog是有某个python文件生成的。
