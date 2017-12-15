## 为什么既有 AXI Interconnect 又有 AXI Crossbar

AXI Interconnect 的地址映射信息在专门的 Address Editor 里，是给当前 block design 做路由的。
而 AXI Crossbar 则是在 IP 核设定中指定地址映射进行路由的。

为什么要有这两种划分，为什么在两种在工程里同时出现？这是因为工程中有多个地址映射域。
一个是 PRM, 另一个是 ldom, 这两个是隔离的，视角不同，所以不能只使用一个全局的 AXI Interconnect.

## Rocket Chip 是如何输出字符的？

### Hart 是如何访问自己对应的 UART 设备的？

`PARDSimTop` 有 UART 接口，模拟器直接提供 UART 设备； 而 `PARDFPGATop` 则直接通过 MMIO 将串口输出送给 PRM.

在 FPGA 配置的 Rocket Chip 的 Device Tree 里， MMIO 的内存映射地址为 0x60000000 ~ 0x7fffffff. 再往上就是常规代码数据的地址空间了。

在 BBL 阶段，核心会查询 DTB 找到 UART 的相关描述，设置 MMIO 的基地址。 之后，出于 NoHype 的定制需求，UART 的内存映射基地址会以 0x10000B 为单位按 hartid 进行偏移。 最后，每个 hart 与 UART 地址的对应关系如下：

 | HART ID | UART BASE ADDR |
 | ------- | -------------- |
 | 0       | `0x60000000`   |
 | 1       | `0x60010000`   |
 | ...     | ...            |

不同 hart 向自己对应的 UART 内存映射空间发送数据时，都从 Rocket Chip 的同一个 MMIO 端口送出。 之后，会经过一个 AXI Crossbar. 在 Crossbar 中，会根据基地址的不同，路由到对应的 UART 总线上。

### 为什么进入 riscv-linux 后也能继续隔离 UART 地址空间？

UART 地址空间的隔离在 BBL 阶段完成后，使用这一信息的代码驻留于 machine mode 的代码区。 操作系统内核（riscv-linux）处于 supervisor mode, 它使用 ecall(environment call) 陷入 machine mode, 以类似系统调用的方式执行 UART 相关的操作。 从 supervisor mode 陷入 machine mode 使用的是 9 号中断，在 BBL 里只有这个位置被设置成了 `mcall_trap`.

## DMA 传输镜像是如何工作的？

[yzh 的文档](http://10.30.7.141/pard/riscv_pard_fpga/issues/33)

SG 是 Scatter Gather 的缩写，是用来自动维护多个传输的模块，可以减少 CPU 用于控制 DMA 的时间。

DMA 从 PRM 的内存取数据，通过 AXI4 总线将数据发送给 rocket chip.
在 rocket chip 里，这条总线通往 l2 frontside bus.

之后可能有这样两种情况：

 1.  直接写到 cache 里，发生替换后写回到 rocket chip 的内存中，走内存控制平面做内存隔离；
 2.  绕过核心，直接把请求转发给访存端口，走内存控制平面写到内存里。
