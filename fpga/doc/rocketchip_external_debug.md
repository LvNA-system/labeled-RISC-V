# Rocketchip External Debug介绍

## 什么是External Debug
External Debug是RISCV对外的调试接口，主要是用来帮助调试软件的（尤其是在没有OS支撑的时候，硬件上要能提供基础的调试能力），而不是用来调试硬件的。
因此External Debug是硬件实现的特性。下面讲External Spec版本，也是指硬件实现所遵循的版本。

## 版本问题
我们现在用的这个rocketchip是有L2 cache的老rocketchip，External Debug的实现上大致遵从[External Debug Spec 0.11](https://www.sifive.com/documentation/risc-v/risc-v-external-debug-support-0-11/)。
我们之前用的那个没有L2 cache的新rocketchip，实现的版本大致遵从[Externel Debug Spec 0.13](https://www.sifive.com/documentation/risc-v/risc-v-external-debug-support/)。
之所以说大致遵从，是因为实现中没有提及它遵循的版本，我们只是对照实现与Spec进行了猜测。

## 大致组成部分
具体请看Debug Spec开始的System Overview章节，我们这里只简单介绍。

Debugger(eg. gdb) <-> Debug Translator(eg. OpenOCD) <-> Debug Transport Hardware(eg. JTAG debug probe) <-> Debug Transport Module(DTM)<-> Debug Module Interface(DMI) <-> Debug Module(DM)

其中Debugger，Debug Translator一般是运行在调试用主机上的软件，Debug Transport Hardware是硬件上的接口设备。
Debug Transport Module及DM是实现在rocketchip上的模块。

其中每处连接之间都有一套对应的协议，链路上的每个部分都要做协议的对接工作。
gdb到openocd有一套调试协议，openocd到jtag之间有一套协议，我们现在用的是jtag vpi。
jtag到DTM之间是jtag协议，DTM到DM之间是Debug Bus协议。

## 调试通路上的若干协议

### gdb到OpenOCD
暂时没有研究，幸亏官方已将实现好了，暂时用了没有问题。

### OpenOCD到jtag
OpenOCD后端有不同的device driver将OpenOCD的命令映射到具体的接口设备信号。
但是我们在仿真时，还是将这个流程给分成两段：
OpenOCD <-> jtag vpi <-> jtag signal。
其中OpenOCD自带了jtag vpi的后端，而jtag vpi到jtag signal的转换，我们在仿真时是通过verilog或者C来做的。
Rocketchip原先是通过csrc/jtag_vpi.c以及vsrc/jtag_vpi.v来做的，其中C程序用于创建socket，接受来自OpenOCD的jtag vpi command，
verilog用来在仿真时把jtag vpi command转成jtag信号，并与rocketchip的jtag口连接起来。
但是它vsrc/jtag_vpi.v中的某些语法是verilator所不支持的，必须用VCS才能跑。
所以我把它拿C++重新实现了一遍，在csrc/JTAGDTM.cc中，这个C++程序负责创建socket，接受jtag vpi command，并转成jtag信号。
这个C++程序通过DPI-C接口，将jtag信号送进rocketchip中。

### jtag vpi简介
jtag vpi的命令包括了主要有如下几条：

| 命令 | 参数 | 动作 | 目的 |
| ----- | ------ | ------ | ----- |
| CMD_RESET | 无 | reset jtag | reset jtag |
| CMD_TMS_SEQ | 一串TMS值 | 在每个jtag clock时，将TMS引脚依次赋值为串中的值 | 主要用来驱动jtag状态机 |
| CMD_SCAN_CHAIN | 一串TDI值 | 在每个jtag clock，依次将值赋到TDI引脚上，并将TDO引脚的值返回 | 主要用来读写jtag寄存器 |
| CMD_SCAN_CHAIN_FLIP_TMS | 一串TDI值 | 与CMD_SCAN_CHAIN基本一致，除了在移入最后一个bit时，将TMS置为1 | 读写jtag寄存器，并在写完之后自动退出SHIFT_DR状态 |
| CMD_STOP_SIMU | 无 | 终止仿真 | 终止仿真 |
| CMD_RESET_SOFT | 无 | 将状态转移到TEST LOGIC RESET | 这个是我自己加的 |

**CMD_RESET与CMD_SOFT_RESET的差异**
CMD_RESET是通过TRST信号来reset，会reset内部寄存器；而CMD_RESET_SOFT只是将状态转移到TEST LOGIC RESET，并不reset内部寄存器。
可以认为CMD_RESET是hard reset，而CMD_RESET_SOFT是soft reset。
事实上，debugger如果全程自己准确track住了jtag状态机，则只需要再最开始用CMD_RESET进行reset，后面直接用CMD_TMS_SEQ来手动准到TEST LOGIC RESET状态。OpenOCD就是这么干的。
如果没有精确track住jtag状态机，则可以用CMD_RESET_SOFT回到TEST LOGIC RESET状态。例如我们自己写的csrc/client.cc就是这么干的。

**有了CMD_SCAN_CHAIN为什么还要有CMD_SCAN_CHAIN_FLIP_TMS**
其实是这样子的，如果要写一个很长的chain，我们可以将其拆分成若干个CMF_SCAN_CHAIN请求，但是最后一个请求必须是CMD_SCAN_CHAIN_FLIP_TMS。
如果最后的请求是CMD_SCAN_CHAIN，我们在shift完数据之后，再用CMD_SEQ退出，则会导致多shift进一个数据。
因为你此时设置了TMS，同时TDO里面也有值（虽然是垃圾值），所以根据状态机指定的动作，
在这个时钟周期，我们会shift进TDO，同时更新状态机，退出SHIFT_IR/SHIFT_DR状态。
CMD_SCAN_CHAIN_FLIP_TMS通过在传输最后一个bit时设置TMS，实现了传输完最后一个bit时，就退出SHIFT状态，解决了这个问题。

#### jtag简介
jtag的简单介绍见[这里](https://www.xjtag.com/about-jtag/what-is-jtag/)和[这里](https://www.xjtag.com/about-jtag/jtag-a-technical-overview/)。
jtag既以用来做boundary scan用来扫出物理引脚的信号，也可以用来置寄存器。我们就是通过它的置寄存器的能力，来发出DMI请求的。
jtag是串行接口，输入输出的数据都是串行的，其中boundary scan以及jtag寄存器都是被称为chain，一个boundary scan和一个jtag寄存器就是一条chain。
之所以被称为chain，是因为我们将boundary scan以及jtag寄存器看做被链在一起的bit。
在SHIFT模式下，tdi信号被移入chain尾部，同时从chain的头部的bit被移出到tdo信号中。
所以通过移位，我们就可以根据tdo信号，知道这条chain上的每一位是什么值，也就知道了bondary scan对应的每个物理引脚的信号值或者jtag寄存器的值。
我们通过移位将旧值移出，将新值移入。在UPDATE模式下，移入的新值将被用来更新物理引脚信号（假如是boundary scan）或者jtag寄存器的值。

jtag中的模式其实是由其内部的状态机来控制的，状态机在tck以及tms信号作用下改变状态。
[这里](https://www.xjtag.com/wp-content/uploads/tap_state_machine.gif)是jtag的状态机。

具体在不同的状态下，jtag的行为请见[这里]()。

具体到rocketchip中，我们不是用boundary scan，我们只用了jtag寄存器。
对照状态机图，我们首先通过TCK以及TMS信号，移动到SHIFT_IR状态。并写入irReg（指令寄存器），根据irReg的不同，我们能访问到的数据寄存器是不同的。
我们再走到CAPTURE_DR状态，在CAPTURE_DR状态，我们选中的data register的值会被更新到shift register上，然后到了SHIFT_DR状态，我们可以将数据读出来，将新值移入。

### jtag to DMI
具体的实现请看vsrc/DebugTransportModule.v。
设置irReg为REG_DTM_INFO，我们在SHIFT_DR状态可以读出DTM的信息，调试器可以用这个来确定版本。
设置irReg为REG_DEBUG_ACCESS，我们在SHIFT_DR状态时，我们将Debug Req写入data register，则发出了Debug Req请求。
若干个周期后，等到我们下一次进入CAPTURE_DR状态时，就可以将Debug Resp放到shift register中，并在SHIFT_DR状态下在移出，即获取了Debug Resp。

发出一个Debug Req的完整流程中，其实并不是每次都需要置irReg，只需要一开始置一下irReg，接下来就可以直接读写data寄存器了。
假设我们发出的Debug请求总是能被迅速处理，则在移入新的Debug Req到data寄存器时，就同时移出了上一个请求的Debug Resp。
则理想情况下，在连续发出Debug请求时，一个Debug请求需要50多个jtag clock。

### jtag TRST的问题
jtag的TRST是optional的引脚。根据jtag的spec，它是异步reset的。
在原来的实现中并没有用到，网上也说reset并不需要用到TRST信号，只要用连续五个TCK TMS为1即可。
连续五个TCK TMS为1，只是保证将状态机置成TEST LOGIC RESET状态，从状态转换图上看，不管从什么状态出发，连续五个TMS的确能将状态机变到TEST LOGIC RESET状态。
但是这在现在的jtag controller实现中有问题的，因为现在的controller（在DebugTransportModule.v中实现），只是在TRST时，才reset内部寄存器，在TEST LOGIC RESET状态时没有reset内部寄存器。
所以我们现在的RESET还是用的TRST信号。另外，按照注释中的说法，他们实现的TRST似乎不能是异步的（我还没确认），所以我们在用的时候，是把它和TCK同步的。

### 同步的问题
jtag各个引脚信号同步的问题，根据jtag标准，TMS，TDI，TDO必须与TCK同步，TRST是异步的（按照上面的说法，我们当前是当做同步用的）。
所以在给引脚赋值时，要注意同步的问题，例如在csrc/JTAGDTM.cc中，jtag各引脚的赋值是用lock来lock住的。
将来如果到了板子上，最好是将这几个引脚的值pack到同一个byte里面，保证可以用一条load/store指令处理好所有引脚的值。

### 跨时钟域的问题
jtag到的转换是在DTM中完成的，值得注意的是，这中间涉及到跨时钟域，即跨jtag时钟域和uncore时钟域。
由于跨时钟域需要过同步器，需要多消耗若干个clock，所以jtag以及uncore clock不能停下。
虽然jtag协议好像没对jtag的TCK做什么规定，但是在写完jtag的data register发出Debug请求后，建议在多给几十个TCK，以确保能跨过时钟域。


## 通过client发出Debug请求

### client简介
client在csrc/client.cc中，client使用jtag vpi接口连接上仿真中的rocketchip。
client提供了一个命令行接口，我们可以通过命令直接读写Debug Module中的寄存器。
client主要用于协助硬件调试。

client命令格式如下：
read/write debug_module_register_name field_1=value_1 field_2=value_2
其中field必须是指定寄存器有的field，value是16进制的数。
退出client用quit命令。

例如我们如果要给hart0发送一个debug interrupt。则我们可以用这样一条命令:
write dmcontrol hartid=0 interrupt=1

### 编译及运行
1. 编译
g++ -Wall client.cc common.cc
生成的可执行文件为a.out。
2. 运行
启动emu：./emu +verbose 2\>emu.log
启动client：./a.out
然后直接输入命令即可发出debug读写请求。

## ControlPlane Register
我们现在访问ControlPlane Register也是通过Debug Module。
具体来说，读写命令及地址占用了原有的SBUSADDR0寄存器的地址，读的data以及写的data占用原有的SBUSDATA0的地址。
在速度上，读写一个控制平面寄存器需要两个Debug请求，大概需要100个jtag clock。

具体的寄存器格式如下：

命令寄存器：

|  域  | 宽度  |   位置   | 读写                      | 说明 |
| ---- | ---- | -------- | ------------------------ | ---- |
| busy |  1   | [33, 33] | read only, write ignored |  indicate whether there are inflight write |
| rw   |  1   | [32, 32] | read 0, write only       | write 1 for read, write 0 for write |
| addr |  32  | [31, 0]  | read write               |  control plane register    |

数据寄存器：

|  域      | 宽度  |   位置   | 读写                      | 说明 |
| -------- | ---  | -------- | -----------------------  | ---- |
| reserved |  2   | [33, 32] | read 0, write ignored    |  无  |
| data     |  32  | [31, 0]  | read write               |  read data and write data reside here |

说明：
我们这个假设控制平面寄存器都是单周期读写。所以对于读请求，一个周期数据就可以读出到data寄存器中。
而对于写请求，第一步是写命令寄存器，写完命令寄存器之后，busy被置1，提示有还在进行中的write请求。
第二部是把要写的data写进数据寄存器中，此时busy被置1，完成对控制平面寄存器的写。

具体的读写步骤如下，我们按照client的命令格式，进行说明：
写地址为1的控制平面寄存器
```
write sbaddr0 rw=0 addr=1
```
写入data为0x3456789
```
write sbdata0 data=3456789
```

读地址为1的控制平面寄存器
```
write sbaddr0 rw=1 addr=1
read sbdata0
```
另外，我们现在在DebugModule里面实现的接到的ControlPlane的逻辑实现得比较简单，ControlPlaneModule的接口也比较简单。
对于寄存器读写我们都假设是单周期完成的，寄存器读基本是能做到单周期的，寄存器写如果是用Reg（Vec）就可以单周期写，如果是Vec（Reg）就无法单周期写，具体原因未知。
