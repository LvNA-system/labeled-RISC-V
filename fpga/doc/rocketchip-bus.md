
系统中有不少总线, 本文档对这些总线的功能和结构进行简单梳理.
可以将这些总线想象为crossbar, 其in和out分别连接其它模块.

## ibus

Interrupt Bus, 可以认为是中断网络.
* in
 * external interrupts (async)
 * sifive-blocks中的uart中断 (sync)
* out
 * plic

## sbus

System Bus, 是连接其它所有总线的总线.
* in
 * fbus
 * ICache和DCache的masterNode
* out
 * cbus
 * coherence manager的in, 最终连到mbus
 * 各个mmio channel, 它们会转换成MasterAXI4MMIO端口, 从rocketchip的顶层出去

## fbus

Front Bus, 不清楚为何采用这个命名.
* in
 * Debug Module
 * rocketchip的SlaveAXI4端口
* out
 * sbus

## mbus

Memory Bus, 是连接各个memory channel的总线.
* in
 * coherence manager的out
* out
 * 各个memory channel, 它们会转换成MasterAXI4Mem端口, 从rocketchip的顶层出去

## cbus

Control Bus, 是连接内部MMIO设备的总线.
在2016年9月21日5bb575的commit中从internal MMIO network改名为cbus.
* in
 * sbus
* out
 * pbus
 * error device
 * controlplane
 * plic
 * clint
 * bootrom
 * debug module
 * bus blocker, 最终连到ICache.slaveNode和dtim.slavePort, 但我们生成的verilog代码里面好像没有bus blocker相关的代码, 暂时不清楚为什么cbus要连到ICache和dtim

## pbus

Periphery Bus, 是连接外部MMIO设备的总线.
在2016年9月21日5bb575的commit中从external MMIO network改名为pbus.
* in
 * cbus
* out
 * 连接的设备例子有: sifive-blocks中的uart
