# Rocketchip OpenOCD GDB使用介绍

OpenOCD以及GDB使用rocketchip的external debug interface进行debug。

首先请确保Rocketchip已经启用了WithDTM。

## 安装OpenOCD
```
git clone https://github.com/riscv/riscv-openocd
cd riscv-openocd
./bootstrap
./configure --enable-jtag_vpi
make -j32
sudo make install 
```

说明：
我暂时还没找怎么改它的安装目录，使得不要用sudo权限也能安装。如果没有sudo权限，就别安装了，因为我们已经编译安装好了一份。

## OpenOCD配置脚本
将下面的内容拷贝到jtag_vpi.cfg文件中。
```
adapter_khz     1 # 请根据接口的速度，配置好这个参数

interface jtag_vpi

# Set the VPI JTAG server port
if { [info exists VPI_PORT] } {
   set _VPI_PORT $VPI_PORT
} else {
   set _VPI_PORT 8080
}

# Set the VPI JTAG server address
if { [info exists VPI_ADDRESS] } {
   set _VPI_ADDRESS $VPI_ADDRESS
} else {
   set _VPI_ADDRESS "127.0.0.1"
}

jtag_vpi_set_port $_VPI_PORT
jtag_vpi_set_address $_VPI_ADDRESS

set _CHIPNAME riscv
jtag newtap $_CHIPNAME cpu -irlen 5

set _TARGETNAME $_CHIPNAME.cpu
target create $_TARGETNAME riscv -chain-position $_TARGETNAME

riscv set_reset_timeout_sec 120  # 这两个或许也要根据接口的不同给调一调
riscv set_command_timeout_sec 120

init
halt
echo "Ready for Remote Connections"
```

## 启动调试

1. 启动emu
`./emu +verbose 2>emu.log`
2. 启动OpenOCD
`openocd -f ~/jtag_vpi.cfg`
3. 启动gdb
等到输出了`Info : Listening on port 3333 for gdb connections`，则可以启动gdb了
运行`riscv64-unknown-linux-gnu-gdb`启动gdb
4. 连接上openocd
`target remote localhost:3333`
5. 运行
运行si，info r确定是不是在正确运行。

## 速度问题
现在gdb运行一下ni，大概需要15s，速度很慢。这主要是由于我们在仿真时jtag速度很慢，以及ni需要的Debug Req请求比较多造成的。
一个ni大概需要110条Debug Req。

## 启动时调试的问题
如果想要程序启动时就开始single step，则需要对当前硬件做修改，使得他刚开始不直接运行而是等待到debug interrupt之后，才开始运行。
