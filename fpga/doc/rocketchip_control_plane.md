# Rocketchip Control Plane介绍

这篇文档介绍rocketchip现在提供的control plane寄存器以及相应的功能，并提供使用controller进行操控的案例。

## Control Plane Register
所有的Control Plane Register全部是32位的，包括了三类寄存器，分别控制我们在rocketchip中加入的三个模块。

### Address Mapper Register
Address Mapper寄存器是用来控制每个tile所能访问到的物理内存的基地址以及大小。

| 寄存器名 | 用途 |
| ----- | ------ |
| base  | 物理内存基地址 |
| size  | tile能访问到的内存的大小 |

注意，由于我们限制了ControlPlane寄存器的大小为32bit，所以内存基地址以及大小都被限制到了32bit。

### Token Bucket Register
令牌桶主要用来进行控制某个dsid的访存带宽。一个dsid对应有三个寄存器。分别是：

| 寄存器名 | 用途 |
| ----- | ------ |
| size  | 令牌桶的大小 |
| freq  | 每多少个周期向令牌桶中加入令牌，此处周期指uncore的时钟周期，0值表示bypass掉令牌桶，不接受流量控制 |
| inc   | 每次添加添加多少个令牌 |

例如如果要想降低某个dsid的访存带宽，则可以增加freq或者降低size和inc。

### Cache Partition Register
Cache Partition Register主要用来进行控制某个dsid能够占用的L2 Cache路的数量。
为了硬件上实现的方便，我们没有采用waymask的做法，而是采用如下的结构，软件需要填充如下的寄存器才能正确地控制它。
每个dsid对应的寄存器有:

| 寄存器名 | 用途 |
| ----- | ------ |
| nway  | 这个dsid能占用的way的数量 |
| dsidMap | 这是L2 Cache way个寄存器，里面依次存放的是这个dsid可以使用的cache way的index，只有前nway个有效 |

例如假设我们的L2 Cache有16个way，如果要设置dsid 1的waymask为0x000f。则软件需要一次干两件事情：
1、向dsid 1对应的dsidMap的前四个寄存器一次写入0至3。
2、向dsid 1对应的nway寄存器写入4。

#### 寄存器在control plane register地址空间的排布如下：

address mapper base register(NTile个), address mapper size register(NTile个), token bucket size register(NDsid个), token bucket freq register(NDsid个), token bucket inc register(NDsid个), cache partition nway register(NDsid个), cache partition dsidMap register(NDsid * NL2Way个)

## 使用controller操纵

### client简介
controller在csrc/controller.cc中，controller使用jtag vpi接口连接上仿真中的rocketchip。

controller命令格式如下：
dsid=dsid_number,reg_1=value_1,reg_2=value_2
其中reg必须是上面提到的寄存器，value是16进制的数。

例如我们如果要限制dsid 1可以使用cache line以及内存带宽。则我们可以用这样一条命令:
dsid=1,size=1,freq=10000,inc=1,mask=0xff

### 编译及运行
1. 编译
g++ -Wall -std=c++0x controller.cc common.cc -o controller
生成的可执行文件为controller。
2. 运行
启动emu：./emu +verbose 2\>emu.log
启动client：./controller
然后直接输入命令即可在线调节。
