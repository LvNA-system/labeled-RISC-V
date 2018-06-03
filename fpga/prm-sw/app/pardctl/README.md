# Control Plane

这篇文档介绍rocketchip现在提供的control plane寄存器以及相应的功能，并提供使用controller进行操控的案例。

This document introduce the details of control plane,
and provide some examples to use `pardctl` to access control plane.

包括了三类寄存器，分别控制我们在rocketchip中加入的三个模块。

## Core Control Plane

### Parameter Table

#### Label Register

Label寄存器是用来在硬件上标识每个tile的不同的软件实体.

| 列号 | 寄存器名 | 长度(bit) | 读写 | reset后初值| 用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | dsid   | `p(LDomDsidBits)` | R/W | 0 | 对应的tile发出的总线请求上的标签 |
| 3 | hartid | `p(LDomDsidBits)` | R/W | tile ID | 虚拟hartid |

说明: 目前bbl和linux通过`mhartid`来支持多核操作系统.
为了支持多核的分区, 我们修改了硬件, 添加了通过控制平面可编程的虚拟`hartid`寄存器,
并使软件访问标准`mhartid`时返回该寄存器的值.


Label Registers are used to let the hardware identify different software entities running on different tiles.

| column NO. | register name | length (bit) | read/write | reset value | description |
| --- | --- | --- | --- | --- | --- |
| 0 | dsid   | `p(LDomDsidBits)` | R/W | 0 | label attached to the bus requests send by the corresponding tile |
| 3 | hartid | `p(LDomDsidBits)` | R/W | tile ID | virtual hartid |

NOTE: Currently bbl and linux support SMP by using `mhartid` register.
To support SMP in a partition, we modify the hardware design.
We add virtual `hartid` registers programmable by control plane,
and modify the CSR module to let it retrun the value of virtual `hartid` register
when software read the standard `hartid` register.

#### Address Mapper Register

Address Mapper寄存器是用来控制每个tile所能访问到的物理内存的基地址以及大小。

| 列号| 寄存器名 | 长度(bit) | 读写 | reset后初值 | 用途 |
| --- | --- | --- | --- | --- | --- |
| 1 | | base  | `p(PAddrBits)` | R/W | 0 | 物理地址空间基地址 |
| 2 | | size  | `p(PAddrBits)` | R/W | p(ExtMemSize) | 物理地址空间大小 |


Address Mapper Registers are used to control the physical address space of each tile.

| column NO.| register name | length (bit) | read/write | reset value | description |
| ---| --- | --- | --- | --- | --- |
| 1 | base  | `p(PAddrBits)` | R/W | 0 | base of the physical address space |
| 2 | size  | `p(PAddrBits)` | R/W | p(ExtMemSize) | size of the physical address space |

### Statistic Table

目前CoreCP没有统计表.

Currently Core Control Plane does not have a statistic table.


## Memory Control Plane

### Parameter Table

#### Token Bucket Register

令牌桶主要用来控制某个tile的访存带宽。一个令牌桶对应有三个寄存器。分别是：

| 列号| 寄存器名 | 长度(bit) | 读写 | reset后初值 | 用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | | size  | 16 | R/W | Undefined | 令牌桶的大小, 单位为TileLink请求 |
| 1 | | freq  | 16 | R/W | 0 | 添加令牌的速率, 单位为uncore时钟周期|
| 2 | | inc  | 16 | R/W | Undefined | 每次添加的令牌数目 |

说明:
* 令牌桶模块位于L1toL2 Network前, 每个tile单独分配一个令牌桶, 其UncachedTL通道和CachedTL通道共享一个令牌桶
* 如果想降低某个tile的带宽，则可以增加`freq`或者降低`inc`
* `freq`为`0`表示bypass掉令牌桶，不接受流量控制 


Token Bucket is used to control the memory bandwidth of a tile.
There are three registers to configure a token bucket.

| column NO.| register name | length (bit) | read/write | reset value | description |
| --- | --- | --- | --- | --- | --- |
| 0 | | size  | 16 | R/W | Undefined | the size of the token bucket, one TileLink request per unit |
| 1 | | freq  | 16 | R/W | 0 | the uncore clock cycle to add tokens into the bucket |
| 2 | | inc  | 16 | R/W | Undefined | the number of tokens added each time |

NOTE:
* The token bucket module is located before L1toL2 Network.
Every tile has its own token bucket.
The UncachedTL channel and cachedTL channel share the same bucket.
* To reduce the memory bandwidth of a tile, one can increase `freq` or decrease `inc`.
* When `freq` is `0`, the token bucket is disabled.
All the memory requests will bypass the token bucket module.

### Statistic Table

#### L1toL2 Bandwidth Counter

MemCP中的统计表会统计各个tile的访问L2的请求个数.

| 列号| 寄存器名 | 长度(bit) | 读写 | reset后初值 | 用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | | cached  | 32 | R/W | Undefined | CachedTL中经过的acquire请求数目 |
| 1 | | uncached  | 32 | R/W | Undefined | UncachedTL中经过的acquire请求数目 |

说明: 在TileLink协议中, acquire请求是一次主动读写事务的开始, 类似于AXI中的AR和AW请求.
具体细节请查阅TileLink文档.


Statistic table in Memory Control Plane will count the number of requests sent to L2 for each tile.

| column NO.| register name | length (bit) | read/write | reset value | description |
| --- | --- | --- | --- | --- | --- |
| 0 | | cached  | 32 | R/W | Undefined | the number of acquire request passes the CachedTL channel|
| 1 | | uncached  | 32 | R/W | Undefined | the number of acquire request passes the UncachedTL channel |

NOTE: In the TileLink Protocol, acquire request is the start of a active read/write transcation.
It is similar with the AR/AW request in AXI Protocol.
For more information, please refer to the TileLink Protocol specification


## Cache Control Plane

### Parameter Table

#### Cache Partition Register

Cache Partition Register主要用来进行控制某个DSID能够替换的L2 Cache路。每个DSID对应的寄存器有:

| 列号| 寄存器名 | 长度(bit) | 读写 | reset后初值 | 用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | | mask | 16 | R/W | 0 | 使用掩码来指示对应DSID的请求能替换的L2 cache路 |

说明: `mask`为`0`表示能进入所有的路.


Cache Partition Registers are used to control which ways can be replaced by a particular DSID.
Every DSID has the following registers.

| column NO.| register name | length (bit) | read/write | reset value | description |
| --- | --- | --- | --- | --- | --- |
| 0 | | mask | 16 | R/W | 0 | indicate which ways can be replaced by the corresponding DSID |

NOTE: When `mask` is `0`, all ways can be replaced.

### Statistic Table

#### L2 Cache Counter

CacheCP中的统计表会统计各个DSID对L2的访问情况.

| 列号| 寄存器名 | 长度(bit) | 读写 | reset后初值 | 用途 |
| --- | --- | --- | --- | --- | --- |
| 0 | | access  | 32 | R/W | Undefined | L2 cache的访问次数 |
| 1 | | miss  | 32 | R/W | Undefined | L2 cache的缺失次数 |
| 2 | | usage  | 32 | R | 0 | 占用L2 cache的容量, 单位为cache block数目 |


Statistic table in Cache Control Plane will record the access situation of L2 cache for each DSID.

| column NO.| register name | length (bit) | read/write | reset value | description |
| --- | --- | --- | --- | --- | --- |
| 0 | | access  | 32 | R/W | Undefined | the number of L2 cache access |
| 1 | | miss  | 32 | R/W | Undefined | the number of L2 cache miss |
| 2 | | usage  | 32 | R | 0 | the occupied capacity of L2 cache, a cache block per unit |
