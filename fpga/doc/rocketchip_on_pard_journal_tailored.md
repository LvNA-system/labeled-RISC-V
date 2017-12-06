# Rocket Chip on PARD 开发日志


## 2016-02-03

今天在 zedboard 上跑编译过的 Linux 了。 使用的 boot.bin 是旧的，刚换成新的，但是缺少浮点单元，所以要重新编译工具链。

 1.  要给 glibc 的 configure 传入 --without-fp 选项。
 2.  要用 -msoft-float 编译 riscv-pk/bbl, vmlinux, busybox 等内容。

## 2016-02-04

riscv64-elf- 是用 newlib 的，riscv64-gnu-linux- 才是用 glibc 的。 我一直在改 glibc 的编译配置以支持 -msoft-float。 但是实际出货的是 elf 前缀的，与它不相干。

手动修改 Makefile.in 以正确地添加 soft-float 的编译支持有些混乱。按照 riscv-gnu-toolchains 的说法：

> Supported ABIs are ilp32 (32-bit soft-float), ilp32d (32-bit hard-float), ilp32f (32-bit with single-precision in registers and double in memory, niche use only), lp64 lp64f lp64d (same but with 64-bit long and pointers).

我似乎只需要指定 configure 的 abi 是 lp64 就行了。 但是它也只是在一条 rule 下加了 --without-fp, 与我之前的工作相差不大，但是似乎没有效果啊？

abi 只管调用规约，实际上，还需要设置 arch 为不支持 fp 的版本。即


	--with-arch=rv64i --with-abi=lp64

用新生成的工具链编译浮点指令失败， 估计是 SMP 的 Linux 遇到了不支持原子指令的编译器。 试试用 a 后缀的 arch. 应该使用 rv64ima.

## 2017-02-07

class Top 以及 Top.`<Config>`.v 是逻辑上的顶层。但是为了和板子交互，还需要加一层 wrapper. 这就是 `rocketchip_wrapper.v` 的作用，它是手写的。原始版本是 `fpga-zynq/commom/rocketchip_wrapper.v`. 在 `<board>` 目录下执行 `make` 时，会将其复制到 `board/src/verilog/` 下。

rocket 自己有记录 tile id, 在 rocket.scala 的 HasCoreParameters 类下。 （TODO: 不如先考虑把 tile 1 的 id 连接到 LED 上看看效果？）

了解了如何生成 verilog，不过 rocket-chip 封装的很好了。 http://stackoverflow.com/questions/40470153/is-there-a-simple-example-of-how-to-generate-verilog-from-chisel3-module

core 在 config 的时候匿名实例化，似乎是存储在 `BuildTile` 这个 `Filed` 类里的。 `Parameter` 类的 `apply` 方法的 `Field` 类版本似乎能把本体的引用取出？ `case object BuildTile = Filed[Seq[(Bool, Parameters) => Tile]]` 是 `Field[T]` 的实例。 这个 `Field` 是一个空白的类：`class Field[T]`. 看样子只是为了模式匹配而定义的。

注意 `BuildTile` 本身是一个 lambda 函数的序列，每个 lambda 函数都是相同的内容，接收 reset 信号和 parameters, 然后在 `BaseCoreComplexConfig` 被实装，但是只是函数，这时候还没有调用，所以 core 并没有被实例化。 真正实例化的地方在 `BaseCoreplexModule` 的 `val tiles = p(BuildTiles) map { _(reset, p) }` 处。 这行代码将每个 lambda 函数映射到 `RocketTile` 对象，变换方法是执行它自己。 所以我们以后可以使用 `tiles` 来访问 core 的内容。

`Seq` 和 `Vec` 有什么区别？似乎后者可以动态索引，而前者只能在编译期索引。(https://github.com/ucb-bar/chisel3/issues/336)

逐层向上暴露到 `BaseTopModule` 了，之后的使用者是很出戏的 `ExampleTopModule`, 是时候看看 `fpga-zynq` 了。 在 `fpga-zynq/common/src/main/Top.scala` 中，`FPGAZynqTopModule` 继承自 `BaseTopModule`, 最终成文 `Top` 的 `module` 成员。

看来 Chisel2 不能通过 `UInt()` 这样的来自动推演宽度。

## 2017-02-09

总结一下核心的层次。

`Rocket` 是流水线核心， `RocketTile` 直接集成 `Rocket`. 然后在 `BaseCorePlexModule` 里，用配置的 `BuildTiles` 存储的 lambda 函数来生成若干个 `RocketTile` 存放于 `tiles: Seq` 中。 之后的逻辑关系比较复杂，`BaseCoreplexConfig` 被 `DefaultCoreplexModule` 继承。 它有一个类型参数是 `DefaultCorePlex`, 继承自 `BaseCorePlex`, 只重载了一个 `moudle` 的惰性 `DefaultCoreplexModule` 对象。 这也是 `DefaultCoreplexModule` 唯一使用的地方， `xxxModule` 基本是作为内部设计而存在的（？）。

之后在 `BaseTopModule` 里通过存储在 `BuildCoreplex` 的 lambda 函数构造 `DefaultCorePlex`.

## 2017-02-10

在 `rocket.scala@Rocket` 下，`io` 里有 `imem` 和 `dmem` 这两个用于地址访问的端口对象。 在 `Rocket` 类里它们主要是和逻辑部件互联，我需要关心的是一个核心对公共内存的访问情况。 `io.imem` 和 `io.dmem` 除了 `Rocket` 类里使用外，只在 `RocketTile` 类里使用。

在 `RocketTile` 里:


	val icache = Module(new Frontend()(p.alterPartial({ case CacheName => "L1I" })))
	// ...
	val dcPorts = collection.mutable.ArrayBuffer(core.io.dmem)
	// ...
	icache.io.cpu `<>` core.io.imem

看来要转去关注 `icache` 和 `dcPorts` 的使用情况，所幸它们只在内部使用。

`Rocket.io.imem` 的类型是 `FrontendIO`, 其中，与地址相关的成员是 `val npc = UInt(INPUT, width = vaddrBitsExtended)`. `npc` 应该是 `next pc` 的意思。我们应该对这个做一下映射。但是为什么是 `INPUT` 呢？ `npc` 可以是不对齐地址，`npc -> s1_pc_ -> s1_pc` 会将其对齐。

icache 在哪边实例化的？ICache 是在 `Frontend` 类中实例化的，在`frontend.scala@42`. 送到 icache 里的是 `io.cpu.npc`:


	icache.io.req.bits.addr := io.cpu.npc

前段的 pc 连线还是比较复杂的，退回到 tile 层面观察。 一个 tile 有 cached 和 uncached 两个端口向量，每个按对应端口数实例化若干个 `ClientUncachedTileLinkIO`.

`rocc` 是与加速器接口相关的内容。

frontend 是在 `RocketTile` 里实例化的……

A +=: As 把 A 加到 As 的头部，As += A 把 A 加到 As 的尾部。

rocket 的 `io.dmem` 被 `dcPort` 接收，最后和其他 port 一起统一塞给 `dcArb.io.requestor` 。 `Arb` 是 `Arbiter` 缩写，即仲裁者。

DCache 在哪实例化？在 `tile.scala#66(RocketTile)`. 这里 `dcache` 只是反回了一个 io bundle，但是里面是实例化了一个新的。

`Arb.io.mem` 是发出的内存请求。`dcache.io.cpu` 是与之直连的接收请求的端口。最后接到 `cached` 上。

core.io.imem -> uncachedArbPorts[i] -> uncachedArb.io.in -> uncachedArb.io.out -> uncachedPorts[j] -> io.uncached.

core.io.dmem -> dcPorts[i] -> dcArb.io.requestor -> dcArb.io.mem -> dcache.cpu -> cachedPorts[j] -> io.cached.

## 2017-02-13

DecoupledIO 将数据封装起来，提供 ready(in), valid(out), bits(out) 接口. DecoupledIO 和 ValidIO 的 bits 即封装的 Bundle. 所以它默认是全部 OUTPUT 的，于是被封装的 bundle 往往不会指定 IO 方向。

TODO: 调研 L2 cache 是否实装。

L2 的实装取决于 `BuildL2CoherenceManager` 的函数体，其只在 `coreplex/BaseCoreplex.scala` 下被赋值，提供的 Module 有如下几种：

 1.  L2BroadcastHub (BaseCoreplexConfig)
 2.  L2HellaCacheBank (WithL2Cache)
 3.  BufferlessBroadcastHub (WithBufferlessBroadcastHub)
 4.  ManagerToClientStatelessBridge (WithStatelessBridge)

话说回来，L1I 在 tile link 层是不缓存的？

对 Config 的理解：若 someCaseClass(...) => expr, 则 someCaseClass extends Field[type of expr]. 这似乎是个现象，但是 topDefs 的类型并没有用类型参数严格规范这一点？

Config 是如何合并多个配置的？它定义了 `++` 运算符用于合并，内部构造了一个新的 `topDefinitions` 函数： 如果前一个匹配抛出了异常，捕获并尝试下一个。所以使用左边的覆盖右边的。

我使用 `class ZynqSmallConfig extends Config(new WithL2Cache ++ new WithSmallCores ++ new ZynqConfig)` 配置来编译 `boot.bin`. 首先观察是否能完成综合，然后，编写简单的应用来进行压力测试。 我已经知道什么时候 `bbl` 会挂掉，而且也不需要进入内核，直接在 machine 层面写一些测试 L2 性能的代码就行了。 两个 core 运行同样的任务，如果有 L2 cache, 那么可以期望整体性能会有提高。

## 2017-02-16

riscv-pard-fpga 由 PRM 通过 CDMA 将镜像喂给 rocket-chip. 那么问题是：

 1.  如何做到 core 间的内存映射（隔离）的？
 2.  如何将不同镜像送给不同的 core ？

暂时不考虑 CDMA 的原理，已有的接口有一个 DMA 描述符口和一个数据端口。应该是直接读写内存的。 [PRM的CDMA如何工作](http://10.30.7.141/pard/riscv_pard_fpga/issues/33)

`PRM(=programmable resource manager?)` 似乎是运行在 MicroBlaze 上的一个软件系统而非纯硬件设施。 (一直看到的 `petalinux` 似乎是 MicroBlaze 专用的 Linux 版本？) 不过查阅相关描述，PRM 跟 MicroBlaze 的语境很紧密，难道 PRM 其实是 Xilinx 的东西：partial reconfigurable module？ PRM 的本体是这个吗？ `bram_data/prmcore-fsboot-dtb.elf`

CDMA 与 AXI4 总线直接连接。PRM 语境的 dsid 与 AXI4 语境的 user 表示同一存在（http://10.30.7.141/pard/riscv_pard_fpga/commit/b82a4ffdc2b182d6d0da6cec1ccdcd7b062f4ec3） 在这个 commit 里遇到了新词 migcp，它是什么含义？（migcp 大概 = fpga/srcs/rtl/control_plane/mig/control_plane.v） 即便相连也无法知道 dsid memory mapping 的工作方式。

在 riscv_pard_fpga repo 中，fpga 目录下是旧的 PARD FPGA 相关的代码，以及适配用的 rocketchip-top.v.

阅读 riscv_pard_fpga 项目代码，在 src/main/scala 目录，即 rocket-chip 核心代码下用 `grep -rn dsid` 观察标签机制的传播和利用方式。 发现基本只有传播的代码，即从底层向上暴露，并传递给 TileLink2 协议，最终传递给 AXI4 总线协议。 那么要实现内存隔离，实际上是在 AXI4 总线和内存控制器之间插入了一个代理者(control plane?)来进行内存的映射？

在 fpga/srcs/rtl/control_plane/mig/control_plane.v 里看到了 `IIC(I2C)` 以及 `APM`. 它们是什么意思？(TODO)

看来需要理解 AXI4 协议的内容。fpga-zynq 肯定是直接挂在总线上的，看看它和 riscv_pard_fpga 连接 AXI4 方式的区别。

## 2017-02-24

CDMA 不是网络的 CDMA, 而是 C??? Direct Memory Access.

PRM 就是 PARD 里的概念（Programmable Resource Manager），Xilinx 也有个 PRM 术语，但是是另一个东西。它是运行在 MicroBlaze 上的。

I2C 或者 IIC 是一种串行总线协议，是 PARD 内部机构之间通信用的，使用它是出于高效（？）、引脚少的考量。

Rocket 和 Microblaze 都使用 AXI4 总线进行通信，有部件将其转换成 I2C。

Memory Controller 就是我们接触过的 Memory Interface Generator，不是使用的是 AXI4 协议而不是 User Interface。

## 2017-02-25

查找 Xilinx Memory Interface 的手册，总是会被导向 UG086, 但是那是 2010 年的文档了。在 [IP 资料页](https///www.xilinx.com/products/intellectual-property/mig.html)可以找到 [7 Series Memory Interface IP Design Checklist](https///www.xilinx.com/support/documentation/ip_documentation/mig_7series/xtp306-MIG-IP-7-Series-Design-Checklist.zip), 在里面可以明确地看到 7series 对应的文档应该是 UG586. 里面还是其他一些话题与资料链接的对应。

在 `mig_7series_0` 看到一个端口 `c0_mmcm_blocked`，其中 MMCM = Mixed-Mode Clock Manager, 用来分频的。换个语境就不认识了。

### 阅读 UG586 (MIG 文档)

看到一个词 `AXI Shim`, 查阅[维基百科](https://en.wikipedia.org/wiki/Shim_(computing)，shim 似乎是一个计算机术语，通常是一个库，用于透明地将一个 API 转换成另一个 API。在 MIG 的语境下，就是将 User Interface 协议与 AXI4 协议进行转换。

MIG IP 核实例 mig_7series_0 在 hdl 代码中是找不到使用场景的。根据 Project Manager 显示的层次结构，它在 system_top_wrapper.v 下的 system_top.bd 里。这个文件如果直接打开，则是一个 xml 文件，在 Vivado 打开，则显示 Block Design 界面。显然 **bd** 是 **block design** 的缩写。

在 Block Design 中没有看到 User Interface 的 app 前缀的端口名，而是以 AXI4 为主。 查阅 UG586, 在 AXI4 Slave Interface Block 一节开头有这样一段描述：

> The AXI4 slave interface block maps AXI4 transactions to the UI interface to provide an industry-standard bus protocol interface to the Memory Controller. The AXI4 slave interface is optional in designs provided through the MIG tool.

根据 UG586 和工程的 IP 核设定，在 MIG Output Options 这一页里选中 AXI Interface 即可开启。

另外发现一段与当前内存带宽调控相关的一段描述：

> Read and write commands to the UI rely on a simple round-robin arbiter to handle simultaneous requests.

翻译一段：

> The address read/address write modules are responsible for chopping the AXI4 burst/wrap requests into smaller memory size burst lengths of either four or eight, and also conveying the smaller burst lengths to the read/write data modules so they can interact with the user interface.

address read 和 address write 模块负责将 AXI4 突发和 wrap(这是什么) 请求切割成更小内 存大小的 4 或 8 倍的突发长度(注：可能是由于字长不一致，突发长度也无法对齐，所以要按 user interface 的字长重新裁定突发长度？)，并将更小的突发长度传递到读写数据模块，使之能与 user interface 进行交互。

MIG 实例有 S0_AXI, S1_AXI, C0, C1 这样的端口名，在 IP Customization 里可以发现设定的 控制器数量是 2。C0 和 C1 分别代表 Controller 0 和 Controller 1. S0_AXI 和 S1_AXI 分 别是以 c0 和 c1 为前缀的端口集合。第一个控制器总线(S0_AXI)连接到 PRM 上，用于传输 workload. 第二个控制器总线(S1_AXI)连接到 control plane 上，用于正常的访存行为。

### 跑起整个系统

要跑起整个系统，要弄明白以下几点：

 1.  VC709 连接在哪台服务器上？（10.30.6.123）
 2.  MicroBlaze 如何启动 PRM. ([pard fpga vc709 wiki Home](http://10.30.7.141/pard/pard_fpga_vc709/wikis/home)?)
 3.  要发送给 rocket chip 的 workload 存储在哪 (从网上下到 PRM 的文件系统中)
 4.  如何通过 PRM 发送 workload 到对应的内存空间（[PRM的CDMA如何工作](http://10.30.7.141/pard/riscv_pard_fpga/issues/33)？）
 5.  如何让 rocket chip 在发送 workload 后开始启动（core control plane 列 1 从 STATE_SLEEP(0) 到 STATE_RUNNING(1)）
 6.  如何获取不同核心的输出（通过 SBI 以及 UART）
 7.  如何向不同核心发送输入（通过 SBI 以及 UART）

> yzh: 1. 10.30.6.123 2. 開板子就會啟動, PRM的reset和板子的reset相連的 3. 在 10.30.6.123 上, PRM啟動后通過wget下載鏡像文件 4. 通過cdma把鏡像從PRM的地址空間傳到rocketchip的地址空間, 具體看issues33 5. 傳完后PRM會寫core control plane的一個表項(寄存器), 表項的值和rocketchip的reset相連 6, 7. rocketchip的uart 和 PRM 的 uart相連, PRM 上的 ttywatch 工具會把 uart 的輸出連到 telnet, 外面就可以用 telnet 來操作 rocketchip 了. 具體看http://10.30.7.141/pard/riscv_pard_fpga/issues/32 3, 4, 5這3個步驟可以在PRM上執行 wget 10.30.6.123/yzh/ksrisc sh ksrisc 來完成, 所以可以去看ksrisc

启动板子后，并非使用 ssh 登录，而是通过串口 (minicom) 登录到 PRM 上。 fsboot = first step boot, 这个程序启动后，从网络下载 PRM 的内核镜像进行 net boot.


	ssh 10.30.6.123

	# poogram bitstream 后要立即登录 uart 串口，一 program 完就开始 5s 倒计时，不回车打断的话会从 flash 里加载旧镜像。
	# 或者先登录，然后再 program bitstream.
	minicom -D /dev/ttyUSB0

	setenv kernel_img image-risc.ub && run netboot
	# netboot 其实就是记录了一条命令的环境变量，run 命令以环境变量所存储的字符串为命令进行执行。
	# netboot = tftp ${netstart} ${kernel_img} && fdt addr ${netstart} && fdt get addr dtbnetstart /images/fdt@1 data && fdt addr ${dt}
	# netstart = 0x84000000
	# dt =
	# tftp 即 tftpboot, 通过 tftp 协议传输镜像并启动
	# tftp 服务器在 10.30.6.123 的 /tftpboot 目录，这个目录所有用户都能够访问。
	# setenv kernel_img whz-image.ub && run netboot
	# 用户名和密码都是 root

	# 用 ifconfig 观察可以发现 PRM 启动 Linux 后是有 ip 地址 10.30.6.60 的。
	telnet 10.30.6.60 3000
	telnet 10.30.6.60 3001

	# 这个脚本会往启动 ldom(rocket chip) 并传入镜像。
	wget 10.30.6.123/yzh/ksrisc
	sh ksrisc

ldom = logic domain.

### 疑问

 1.  如何做到将 rocket 写入屏幕的输出通过 uart 和 telnet 传出来？
 2.  rocket 如何能够根据控制平面设置分别启动？

SFP 是什么东西？

总结，今天主要熟悉了整个启动流程，之后就可以开始修改代码玩了。

## 2017-02-26

今天计划在 vc709 上跑自己的 benchmark. 为此我需要：

- RISC-V 工具链
- Linux 4.6.2 内核源码，支持 initramfs, 关闭 block device
- 直接工作环境没有 sudo, 无法 mount root.bin 进行修改，有些不方便。（直接修改 initramfs.txt 是更优雅的方法）
- 找到 SPEC2006 benchmark 的独立运行方法。（[各 benchmakr 的命令行](http://kejo.be/ELIS/spec_cpu2006/spec_cpu2006_command_lines.html)）
- 交叉编译独立的 benchmark 放到 initramfs 中

自己编译的，能在 spike 下启动的 bbl 无法让 vc709 的 rocket 正确启动，而 risc-boot.bin 也不能在 spike 下运行。 如果先启动 risc-boot.bin, 再尝试启动 bbl, 则会发现依然执行的是 risc-boot.bin 的镜像（编译器主机名不一样）。 为什么会无法执行？如果能够观察到 PC 的变化就再好不过了。考虑到 bbl 与外界交互需要使用 htif, 不知道这个功能在 pard 里是否实装。 可能是我错误地使用了 bbl 导致看不到效果。应该使用一种能进行端口通信的 bootloader. 在项目里搜索了 htif, 在 Comments 里发现 PARD 使用的可能是 SBI 进行通信。 使用计算所的 bbl repo 成功输出了信息，但是架构不匹配，我本来打算自己重新编译工具链，但是没想到 g 版本的工具链可以指定精简架构版本。 另外在 fpga 目录下 `make sw` 就可以一键解决了。

### 理解 PARD FPGA

ksrisc:


	echo 0 > /sys/cpa/corecp/ptab/row0/col1
	echo 1 > /sys/cpa/corecp/ptab/row0/col1

`row0` 代表第一个核心，`col1` 代表核心的状态寄存器。`0` 的语义是 `STATE_SLEEP`, `1` 的语义是 `STATE_RUNNING`. 当发现状态从 `STATE_SLEEP` 变成 `STATE_RUNNING` 后，`corecp` 会向对应的核心发送 `WAKE_UP` 信号。


	echo 1   > /sys/class/gpio/gpio240/value
	echo 2   > /sys/class/gpio/gpio240/value

按《PARM详细设计文档》的说法，这两行代码是为了「设置PRM中CDMA模块的DS-id为ldom的DS-id, 以便正确传送镜像」。

为了整合 PARD, rocket 使用的配置是 `PARDFPGAConfig`, 相关的代码在 riscv_pard_fpga/src/main/scala/rocketchip/pard 中。 重要的是，它没有 FPU!

### 理解 RISC-V Tools

Spike 模拟器依赖于 fesvr, 而 fesvr 所使用的 htif 的 tohost 和 fromhost 这两个信息在来自于 riscv-pk 项目的 bbl 和 pk. 所以执行普通的程序也需要用 pk.

### make

make 的 order-only prerequisite 主要的应用场景是这样的：一堆文件要生成/更新后要放到一个生成的目录中，所以要先生成目录。 如果目录是一个前置条件，则每次目录内的文件发生改动，则目录的时间戳被更新，所有依赖目录的文件都要被更新，这显然是不必要的。 不过这个更新特性在内核编译的场景又变得尤为有用。如果 Linux 需要 initramfs, 则每次更新 initramfs 对应的目录里的内容时，都应该重新编译 Linux. 不过现在 initramfs 都是用配置文件来描述的。

## 2017-02-27

跑按 `make sw` 编译的 bbl.bin, 结果出现了下面的错误：


	/home/wanghuizhe/sw/riscv_bbl/machine/configstring.c:10: assertion failed: res.start

此外，第二个核心依然没有任何输出。当我使用标准的 risc-boot.bin 后，第一个核心出 现了第二个一模一样的断言，这可能是第二个核心的。标准的 risc-boot.bin 能正常启动， 且两个核心都有输出。

关于 configstring 的解析，yzh 已经在官方仓库上发出过 [issue](https///github.com/ucb-bar/rocket-chip/issues/516) 了， 所以，risc-boot.bin 能够正确运行，说明这个问题在本地已经被回避或解决掉了。 而官方那边的 [fix issue](https///github.com/ucb-bar/rocket-chip/issues/474) 还是处于 open 状态，说明这个问题在官方源没有被解决。所以首先观察一下所里的仓库里 有没有相关问题的 commit.

更新 bbl 后，第一次 CDMA 传输不会产生变化，第二次才能看到更新后的程序行为。

Makefile.sw 里会自动切换到指定的 commit 下对 bbl 进行构建，如果修改之后没有 commit, 那么是会反映到最终的二进制里的，但是一旦提交了，则修改无法反应到最终的二 进制文件中，需要注意。

这之后通过了 configstring 的 parsing. 但是首先遇到了一个无法处理的 6 号中断，之后 陷入了 kernel panic. 之后我使用自己配置并编译的 vmlinux 作为 bbl 的负载，成功地 进入了内核。并且也没有遇到 6 号中断。

第二个核心没有输出的问题，是由于 bbl 代码版本较旧，uart 没有被区分，且 ram 的 base 和 mask 也没有跳过错误的 parsing 进行硬编码。 从分支 [nohype](http://10.30.7.141/pard/riscv_bbl/tree/nohype) 更新 bbl 后， 问题解决。

riscv-linux 在 arch/riscv/kernel/head.S 里会 `call sbi_hart_id` 以检查是否是第一个 hart, 其他 hart 不应该通过 sbi 输出，但是我们这里的情况有所不同。

用 `make sw` 编译的带动态链接库的 riscv-linux 会遇到 /init 无法执行的问题。 原因在于 /init 所连接的 busybox 所依赖的动态库 ld.so.1 的路径在 initramfs.txt 里 的配置是 /lib/ld.so.1, 而通过 readelf 观察到的 busybox 的动态库搜索目录则是 /lib64/lp64d/ld.so.1, 所以无法执行。之后修改 initramfs.txt, 生成对应的两级目录， 把 ld.so.1 放到正确的位置后，再次运行会出现 2.25 版本的 libc.so.6 和 libm.so.6 找不到的问题，它们被放在了 /lib/ 下，似乎是没有问题的。如果把这两个动态库同时放 在 /lib/ 和 /lib64/lp64d/ 下的话，启动内核时会有如下 kernel panic:


	Kernel panic - not syncing: write error
	CPU: 0 PID: 1 Comm: swapper Not tainted 4.6.2-g28e36ba-dirty #9
	Call Trace:
	[`<ffffffff80b41fb8>`] walk_stackframe+0x0/0xc8
	[`<ffffffff80b83f34>`] panic+0xec/0x20c
	[`<ffffffff80002410>`] maybe_link.part.2+0x144/0x148
	[`<ffffffff8000244c>`] populate_rootfs+0x38/0xc8
	[`<ffffffff80002410>`] maybe_link.part.2+0x144/0x148
	[`<ffffffff80000be0>`] do_one_initcall+0x114/0x1d4
	[`<ffffffff80000df4>`] kernel_init_freeable+0x154/0x220
	[`<ffffffff80ca9644>`] rest_init+0x80/0x84
	[`<ffffffff80ca9658>`] kernel_init+0x10/0x118
	[`<ffffffff80ca9644>`] rest_init+0x80/0x84
	[`<ffffffff80b40bfc>`] ret_from_syscall+0x10/0x14
	---[ end Kernel panic - not syncing: write error

这可能是由于把同一个动态库在两个不同了路径各放置了一份造成的。

动态库的问题，经过搜索与尝试，发现在本机 /opt/riscv-toolchains/sysroot/lib64/lp64d/ 下有需要的 GLIBC 2.25 版本的动态库，然后将它们在 initramfs 里的位置也设置成 /lib64/lp64d/ 就可以顺利地登录内核了。

我一开始以为如此特别的路径是因为编译时指定了 arch 和 abi 造成的，但是我用不指定 arch 和 abi 的编译命令编译出来的 ELF 文件也依赖 2.25 版本的动态库。

### SBI 与 SMP

计划将来同时支持 nohype 内存隔离与 SMP. 所以 SBI 协议检查 hart id 这件事不能忽略。 问题是，**什么是 SBI**……观察了下代码，像 `sbi_hart_id` 这种，明明只有一个符号定义， 却是通过 `call` 命令来使用的（`call` 是一条伪指令，用于以偏移量进行不受范围限制的跳转）。

*riscv-privileged-v1.9.1* 说：SBI 即 Supervisor Binary Interface. 在内核里只能看到 SBI 相关的符号定义，实际上 bbl 和 pk 有具体的实现，它们会通过 ELF 符号表将符号与实现进行绑定。

### 为什么要写两次 /row0/col1

PRM 通过 CDMA 将 workload 送往内存时会因为一致性协议的要求，在总线上等待 rocket 的 L1 cache 的响应。如果 rocket 不启动的话， cache 无法工作，则传输会被卡住。

### TODO

#### reset 信号分离（已完成）

现在 core control plane 的 /row0/col1 从 0 到 1 的上升沿会同时导致 rocket 的两个 核心被复位。这是因为 rocket 本身是用同一个 reset 信号来管理的。现在的目标是将 reset 信号分离，从而使 /row0/col1 控制 core 0, /row1/col1 控制 core 1.

#### 内存带宽控制

总线上的内存请求需要等待内存控制器准备好了才能被响应，否则它会一直待在总线上。 所以要想做到内存带宽调控，只需要根据调控策略，对需要控制的内存请求来源持续回复 “没有准备好”就行了。

#### 通过检查 SMP 支持绕过 hart id 检查

如前面所说，现在要想两个核心隔离执行就要注释掉 sbi_hart_id 相关的语句， 这很不方便，其实可以通过软件行为来检测是否开启 SMP 从而检查 hart id. 这样就不用 特意准备两份镜像了。

### reset 信号分离

rocket 的 corereset 信号连接着 pardcore_reset1: Processor System Reset 唯一的输出 mb_reset.

设计思路是增设 id 口。reset 有效的时候，内部检查 id 是否一致，一致或者广播的情况下， 才真正地对着核心 reset.

DCM = Digital Clock Manager.

## 2017-02-28

今天烧录发现系统不工作。

用 telnet 观察 rocket 的行为，没有输出。用 ILA 观察 reset 信号时候发出，结果是捕捉到了上升沿，符合预期。现在尝试将 `corerst0` 和 `corerst1` 连接到一根线上，观察行为。

观察代码，发现 `PARDFPGATop` 的端口 `io_corerst_0/1` 的类型是 `OUTPUT`, 这并不符合预期。

Chisel2 对如下的表达的编译存在问题：


	val reset = Vec(n, Bool(false, INPUT))

即便是很简单的测试样例，Chisel2 也会将其翻译成 OUTPUT 类型的端口。 但是 Chisel3 的写法是没有问题的：


	val reset = Vec(n, Input(Bool()))

Vivado 在完成 synthesis 后，一直卡在 launch_impl 步骤无法前进。等等就好了。主要是在等 mig_7series 完成综合，由于是并发的，所以 impl 卡住的时候没有见到它。

这次成功启动了，但是两个核心都启动了，这不是期望的结果，并且会出现 bbl 执行两次的情况。 首先是我自己连错线了……

再次上板测试后，发现 kloader0 无法访问 `dd: writing '/dev/kloader0': Invalid argument`。 修改脚本，CDMA 之前同时启动两个核心，再执行脚本，则出现 kernel panic (prm).

如果同时启动两个核并且传入镜像能够正常工作。这时候如果 reset 一个核，另一个核不会 出现重启的输出，因为内存里已经有镜像了，所以 reset 多少还是能执行一段的。但是无法 通过 telnet 进行交互，没有反应。不知道是不是 sbi 和 uart 的问题，还是说依然被 reset 了， 只是因为没有传镜像而没看出来？

## 2017-03-01

### pard 架构中有关令牌桶的部分


	git clone git@10.30.7.141:pard/pard_fpga_vc709.git --branch token_bucket

token_bucket 模块只在 axi_gen_ar 模块里实例化。对 axi_gen_ar 这个模块名字，我是 这样理解的：

 1.  axi: 表示这个模块与 AXI4 总线协议相关；
 2.  gen: 表示这个模块有信号生成；
 3.  ar: 怀疑是 arbiter 的缩写，表示仲裁，与内嵌令牌桶也是一致的。

axi_gen_ar 由两部分组成，一个是读请求生成代码块，一个是令牌桶。它只是递增地发送 访存请求给 mig controller plane 并受令牌桶的控制。

mig 的 ptab 结构是这样的：

 |        | reg files base | reg files len | bucket size | bucket freq | bucket inc cnt |
 |        | -------------- | ------------- | ----------- | ----------- | -------------- |
 | core 0 |                |               |             |             |                |
 | core 1 |                |               |             |             |                |

那么要设置 bucket, 只需要执行命令 `echo n > /sys/cpa/migcp/row`<x>`/col[234]`

在 `token_bucket` 里计算一次访存请求读取的字节时，公式是这样的：


	nr_xbyte = (s_axi_axlen + 1) << s_axi_axsize;

其中，`x` 可以是 `r` 或 `w`, 分别代表读和写两种情况。 为什么是这样一个式子呢？首先，明确下变量的含义，`axlen` 表示的是 **burst length**, `axsize` 表示的是 **burst size**. Burst length 表示这次访存请求进行几次数据传输， burst size 表示这次访存请求每次传输的数据大小（单位为字节）。根据 AXI4 协议的描述， 实际的 burst length 是在该总线的基础上加上 1, 而 burst size 代表的字节数是以它的 值为指数的 2 的幂次。所以这里可以用移位来快速计算出总字节大小。

Token bucket 的代理流程：

 1.  core -> s_axi_axvalid -> bucket
 2.  bucket -> m_axi_axvalid -> mig
 3.  mig -> m_axi_axready -> bucket
 4.  bucket -> s_axi_axready -> core

现在我认为 token bucket 每个 master 都需要一个（毕竟每个 token bucket 里只有一个 reg）。这样每个核心都需要连接一个 token bucket 实例，并且 ptab 需要将整个 token bucket 相关的表暴露出来。但是问题来了，token bucket 连的是总线，**总线是不会每个 核心单独连的**。

rocketchip 只有一个 AXI 总线，两个核心是如何分享这个总线的呢？

在当前工程下，`x_axi_aw_bits_user` 和 `x_axi_ar_bits_user` 包含 dsid.

## 2017-03-02

据说 TileLink 一次只能把一个核的请求发送到 AXI4 上，如果在 AXI4 上用 control plane 堵它，则另一个核心也会卡住。


	/** A concrete subclass of ReadyValidIO signaling that the user expects a

	  * "decoupled" interface: 'valid' indicates that the producer has
	  * put valid data in 'bits', and 'ready' indicates that the consumer is ready
	  * to accept the data this cycle. No requirements are placed on the signaling
	  * of ready or valid.
	  */
	class DecoupledIO


	PARDFPGATopBundle with PeripheryMasterAXI4MMIOBundle

	trait PeripheryMasterAXI4MMIOBundle {
	  this: TopNetworkBundle {
	    val outer: PeripheryMasterAXI4MMIO
	  } =>
	  val mmio_axi4 = outer.mmio_axi4.bundleOut
	}

	PeripheryMasterAXI4MMIOBundle.mmio_axi4 = (outer: PeripheryMasterAXI4MMIO).mmio_axi4.bundleOut

	// PeripheryMasterAXI4MMIO is an example, make your own cake pattern like this one.
	trait PeripheryMasterAXI4MMIO {
	  this: TopNetwork =>

	  private val config = p(ExtBus)
	  val mmio_axi4 = AXI4BlindOutputNode(Seq(AXI4SlavePortParameters(
	    slaves = Seq(AXI4SlaveParameters(
	      address       = List(AddressSet(BigInt(config.base), config.size-1)),
	      executable    = true,                  // Can we run programs on this memory?
	      supportsWrite = TransferSizes(1, 256), // The slave supports 1-256 byte transfers
	      supportsRead  = TransferSizes(1, 256),
	      interleavedId = Some(0))),             // slave does not interleave read responses
	    beatBytes = config.beatBytes)))

	  mmio_axi4 :=
	    AXI4Buffer()(
	    // AXI4Fragmenter(lite=false, maxInFlight = 20)( // beef device up to support awlen = 0xff
	    TLToAXI4(idBits = config.idBits)(      // use idBits = 0 for AXI4-Lite
	    TLWidthWidget(socBusConfig.beatBytes)( // convert width before attaching to socBus
	    socBus.node)))
	}

### Scala 学习

在 rocket-chip 里发现这样一段代码：


	trait PeripheryMasterAXI4MMIO {
	  this: TopNetwork =>

	  //...
	}

根据[这里](http://stackoverflow.com/q/1990948/5164297) 的说法， 这里称 TopNetwork 是 PeripheryMasterAXI4MMIO 的 self-type. 所以要拓展 PeripheryMasterAXI4MMIO 的 class 或 trait, 有一定要拓展 TopNetwork.

依赖注入（Dependency Injection）就是依赖的对象要动态指定。使用者通过公共接口来使 用这些被注入的依赖对象，但是为什么不直接提供一个构造器让用户自己传入呢？从看到的 解释来理解，就是最底层的实现者不希望改变，最外层的使用者也不希望看到具体实现，就 是中间的人希望能够灵活地改变，而这种改变最好不需要经过编译器。终端用户往往只会安 装运行环境而不会安装工具链，为了给它们提供动态可配置性，不能经过编译，只能通过配 置文本，但是从配置文本到具体的代码变更是有一定距离的，这就是依赖注入诞生的背景？

（题外话：据说 gem5 用 Policy Pattern 是为了规避虚函数表的性能损耗）

Self-type 描述了 trait 间的依赖关系。要描述多个依赖，可以这么写：


	this: Foo with Bar with Baz =>

很重要的一点是，如果用单例衔接了这些 trait, 那么可以从中提取出绑定好的一部分直接 使用([ref](http://jonasboner.com/real-world-scala-dependency-injection-di/))：


	object ComponentRegistry extends
	  UserServiceComponent with
	  UserRepositoryComponent
	val userService = ComponentRegistry.userService
	val user = userService.authenticate(..)

如果 component 里的对象放到 `ComponentRegistry` 再实例化，可以提供灵活的实例化配置，另外如果 `ComponentRegistry` 如果定义成 trait 可以进一步提高它的可修改性。

测试的时候一直忘记写 `=>` 导致总是出错。 另外多个 self type 要用 `with` 连接，但是 structural type 不需要，不过 structural type 只能写一个而且只能写在末尾。

## 2017-03-03

现在 coreplex 是在哪里实例化的？在 `MultiClockRocketPlexMaster` 里。

Scala 里 trait 同名的变量会合并？应该是 overriding 机制。另外 `with` 序列的第一个 才能是 `class`

在 `MultiClockRocketPlexMaster` 里声明的 `mem` 的类型是 `Seq[TLInwardNode]`. 在 `PeripheryMasterAXI4Mem` 里声明并实例化的 `mem` 的类型是 `Seq[TLToAXI4Node]`. 根据二者的父类，他们应该也是继承关系的。`TLInwardNode` 只关心进来的是 `TileLink` 协议的数据，在 `MultiClockRocketPlexMaster` 这个层面，它也并不能知道外部使用什么 样的总线协议，而 `TLToAXI4Node` 则明确了外部的总线协议是 `AXI4`.

直觉上，不认为在 `TLToAXI4` 里会对多个 TileLink 的来源进行判断。实际的仲裁在 `TLXbar` 那边应该已经完成了。在 `MultiClockRocketPlexMaster` mix-in 的 `HasAsynchronousRocketTiles` 里，可以看到 `rocketTiles` 被声明并实例化，并且使用 遍历方法进行了连线：


	rocketTiles.foreach { r =>
	  r.masterNodes.foreach { l1tol2.node := TLAsyncCrossingSink()(_) }
	  r.slaveNode.foreach { _ := TLAsyncCrossingSource()(cbus.node) }
	}

	val rocketTileIntNodes = rocketTiles.map { _ => IntInternalOutputNode() }
	rocketTileIntNodes.foreach { _ := plic.intnode }

`TLAsyncCrossingSink` 和 `TLAsyncCrossingSource` 是什么意思呢？只是在提供缓冲吗？ 准备重点理解 `l1tol2`. 它来自 `CoreplexNetwork`, 是 `TLXbar` 的实例。 `TLXbar` 的构造参数里有 `TLArbiter.Policy`, 可能是我们需要的。

现在主要阅读 `TLToAXI4` 和 `TLXbar` 的代码，主要的困难在于不理解协议的含义，大量 的端口名，以及层层包装的容器。

题外话：所以我只要能在不修改客户端代码的情况下替换掉具体的服务端， 就等于完成了依赖注入的任务了。

### AXI4 学习

在 rocket-chip 关于 TileLink2 的[代码](https///github.com/ucb-bar/rocket-chip/blob/972953868cd100d22f8e2513d72ad562bb496af7/src/main/scala/uncore/tilelink2/Xbar.scala#L135)里看到了 `numBeats1` 这个方法，感觉 `beat` 似乎是一个总线上的概念。通过搜索，找到了 AXI4 关于 `beat` 的定义，虽然二者不是同一个协议，但是一些基本概念应该是相通的。

> Beat: An individual data transfer within an AXI burst

感觉 beat 的数量就是 burst length, 而 burst size 表示的就是一个 data beat 的大小。

术语：DUT = device under test

Width of dshl shift amount cannot be larger than 20 bits

术语：OH = One Hot\\
`OHToUInt` 返回一个独热码（只有一个 1）中 1 的位置。对应的拟操作 `UIntToOH` 则 把一个二进制编码转换成独热码。

术语：fanout = replicate an input port to many output port.

### Chisel3 的 Vec 和 Input, Ouput, Reg, Wire 的顺序关系。

在 chisel3 中，要想创建一组寄存器，可以有以下两种写法：


	val regs = Reg(Vec(n, UInt()))
	val regs = Seq.fill(n)(Reg(UInt()))

第二种写法只是创建了一组不关联的寄存器，如果要对它们进行进行 `:=` 这样的连线操作， 必须使用容器的相关方法。第一种写法实质上是将一组 `UInt` 整体看作是寄存器，并可以 进行下标访问。不过这两种方法在 `Module` 中生成的代码基本是一样的。

在 io bundle 里，只能使用第一种方法定义一组可以下标访问的端口。因为 `Vec` 是 chisel 定义的类型，在生成 Verilog 代码时，会按照端口名和下标生成对应的 verilog 模块端口。而 `Seq` 只是编译 chisel 时运行的容器，它本身不会在生成的 Verilog 代码 中出现。这样一来，它所包含的部件就是匿名的了，这在 `Module` 内没有问题，但是在对 外开放的端口里，则是不容许的。

受 StackOverflow [一篇问答](http://stackoverflow.com/questions/40816397/syntax-about-chisel-vec-wire)的启发， 我认为，`Vec`, `Bundle` 只是一种数据组织形式，与 `UInt`, `Bool` 一样，是数据类型。 而 `Wire`, `Reg`, `Mem` 在我看来，则是具体的数字电路元器件。现有数据类型，再有基 于此实现的元器件。不过 Chisel 以 Scala 为基础，其概念划分在 Scala 语法层面是不存 在的，所以可以凭借 Scala 的语法，用有别于 Chisel 的方式，定义一组寄存器（似乎 相比 Chisel2, Chisel3 更加强化了这种概念划分）。

不过，`Input` 和 `Output` 似乎不受这种限制，下面两种写法都是可以的：


	val io = IO(new Bundle{ val in = Input(Vec(n, UInt()))})
	val io = IO(new Bundle{ val in = Vec(n, Input(UInt()))})

大概是因为 `Input` 和 `Output` 只是处理端口方向这一属性的，所以写起来位置比较自由？

### 在 Arbiter 的 Policy 里实现令牌桶的可能性

用 `numBeats` 和 `beatBytes` 我们可以轻松地知道消耗的流量。 但是 `Policy` 这个函数只能接收 `Seq[Bool]`. 虽然可以用有状态的 `Policy` 替换默认的先来先得。但是现在还不清楚这个 `Seq[Bool]` 下标与 core id 之间是否有关联。而且 `Policy` 如何以最小代价看到 `numBeats` 和 core id, 也是需要一番考量的（`beatBytes` 是配置）。

## 2017-03-04

要理解 TlieLink2 转成 AXI4 后，会不会出现一个卡另一个的现象，可以观察 `Xbar` 的 abriter 的行为。

术语 probe: In telecommunications generally, a probe is an action taken or an object used for the purpose of learning something about the state of the network. For example, an empty message can be sent simply to see whether the destination actually exists. Ping is a common utility for sending such a probe. A probe is a program or other device inserted at a key juncture in a network for the purpose of monitoring or collecting data about network activity.

简单描述下 `TLArbiter` 的行为：

不看 `Policy` 的话，决出 `winner` 的逻辑是纯组合的。所以这个周期如果有请求， 则 `initBeats` 非零，这个周期由于 `leftBeats` 和 `sink.ready` 都有效，所以 `latch` 有效，这样下个周期 `leftBeats` 会被选择更新成 `initBeats`. 同理还有， `muxState` 当周期选择成 `winner`, 下个周期 `state` 会被更新成 `winner` 的值， 而 `muxState` 维持不变，这是在保持 `winner` 序列。 这样下个周期里， `idle` 和 `latch` 接连失效，`sink.valid` 会接上成 `winner` 的 `valid`. `sink` 再次 `ready` 有效的时候，说明完成了一个 `beat`, 则会减去 `leftBeats`.

结论，在 `TLXbar` 里，`TLArbiter` 会将依据 `Policy` 产生的 `winner` 完全服务完， 即所有 `beat` 都被处理之后，才会去选择并服务下一个 `source`. 也就是说，在 `l1tol2` 这个接口上，core 之间是排队关系，

### L2 与 AXI4 的连接

`l1tol2` 只是 L1 到 L2 的传输，AXI4 是 L2 对外的传输。

在 `MultiClockRocketPlexMaster` 里实例化了 `MultiClockCoreplex`, 其 `mem` 端口 与外界相连。它的类型层次是这样的：


	BaseCoreplex (coreplex)
	    BareCoreplex (coreplex)
	    CoreplexNetwork (coreplex)
	    BankedL2CoherenceManagers (coreplex)
	        CoreplexNetwork (coreplex)
	CoreplexRISCVPlatform (coreplex)
	    CoreplexNetwork (coreplex)
	HasL2MasterPort (coreplex)
	    CoreplexNetwork (coreplex)
	HasAsynchronousRocketTiles (coreplex)
	    CoreplexRISCVPlatform (coreplex)
	        CoreplexNetwork (coreplex)

可以看到很多类都继承了 `CoreplexNetwork`, 但是由于 `val` 是常量， 而且都来自于同 一个 trait, 所以是不会冲突的。但是如果两个不同的 trait 里定义了同名的具体 `val`, 则无法编译。

`HasL2MasterPort` 里创建了 `l2in`. `CoreplexRISCVPlatform` 里将 `l1tol2` 与 `managers` 相连。 `BankedL2CoherenceManagers` 里创建了 `mem`, 这就是将来要和 `MultiClockRocketPlexMaster` 里的 `mem: Seq[TLInwardNode]` 相连接的。 这里的连接关系是:


	BankedL2CoherenceManagers:
	mem <- node . bankBar: TLXbar . node <- out . l2Config.coherenceManager . in <- node . l1tol2

`mem` 本体在 `PeripheryMasterAXI4Mem` 中创建，继承路径为： `PARDFPGATop -> PARDTop -> PeripheryMasterAXI4Mem`. `mem` 实际上是 `TLToAXI4` 的 `node`. 这里的 `:=` 运算符被重载了。原来是 `input := output`. 现在则是自动从参与运算的 `node` 里取出 `input` 和 `output` 部分。 于是，连线是这样的：


	mem_axi4 <- mem (node . TLToAXI4 . node) <- ...

`mem_axi4` 作为端口的定义在 `PeripheryMasterAXI4MemBundle` 中。

阅读 rocketchip_top.v, 发现 rocketchip 的端口族的对应关系：


	PARD `<->` rocketchip
	cdma `<->` l2
	uart `<->` mmio
	mem `<->` mem

`l2_axi4` 来自 `PeripherySlaveAXI4`, 继承路径 `PARDFPGATop -> PARDTop -> PeripherySlaveAXI4`.

### TODO

 1.  在 L1 末端加源控制
 2.  暴露 token bucket parameter 给 rocket.

### 在 L1 末端加源控制

在 trait `HasAsynchronousRocketTiles` 里，`rocketTiles` 被创建并进行了基本的连线：


	rocketTiles.foreach { r =>
	  r.masterNodes.foreach { l1tol2.node := TLAsyncCrossingSink()(_) }
	  r.slaveNode.foreach { _ := TLAsyncCrossingSource()(cbus.node) }

暂时还不太理解 `cbus` 的语义是什么。


	l1tol2.node := TLAsyncCrossingSink()(AsyncRocketTile.masterNodes)
	AsyncRocketTile.masterNodes := TLAsyncCrossingSource()(RocketTile.masterNodes)
	RocketTile.masterNodes.head := l1backend.node := (frontend.node, dcache.node, rocc.node)

`Node` 里的 `edge` 概念一直很模糊，姑且认为是连线的意思吧，毕竟 `bundle` 里只有端口。

### 理解 Node

`Node` 似乎可以理解为多层二分图中的节点，每个节点可以连接任意多个输入和任意多个输出， 只不过使用一个 `Vec` 来进行具体的连接和管理。不过不太清楚为什么要知道自己这个连接点 在对方 `Vec` 中的下标。

在 `TLAsyncCrossingSink` 和 `TLAsyncCrossingSource` 中 有 `ToAsyncBundle` 和 `FromAsyncBundle` 的应用。 它们并不是对称的操作，都只能作用于同一类数据，故由参与连线的两个数据的类型决定 顺序，把 From 换成 To 是会报错的。

`ToAsyncBundle` 由于要塞东西进去，所以是有 `depth` 的，而 `FromAsyncBundle` 则没有这个参数。

`bundleIn` 和 `bundleOut` 由于在编译过程中积累连接的 `Node`, 所以要最后才能访问。

现在计划在 `AsyncRocketTile` 里转换 `masterNodes` 时加一层做控制，这里也很容易知道 `dsid`.

无论怎么加层失败，不如先在 SyncNode 上加层。

## 2017-03-05

如果在 `TL` 这一层做控制，那么被掩盖的信号会被送入 `TLAsyncCrossing`, 很可能就无法恢复了。如果在 `TLAsyncCrossing` 里做这一层， 那么就是在出口处掩盖信号。但是，现在还是缺少相关的信息。

今天首先来思考下 `sink` 的 `depth` 是如何起作用的。

从 `class TLAsyncCrossingSink` 开始看起，构造参数 `depth` 作为参数传递给 `TLAsyncSinkNode`, `ToAsyncBundle` 和 `FromAsyncBundle`. 在 `case class TLAsyncSinkNode` 里，`depth` 作为参数传递给 `TLAsyncManagerPortParameters`. 在 `case class TLAsyncManagerPortParameters` 的定义里，只是对 `depth` 进行了检查。 但是这里并不是终点，`case class` 本质上不过是一个带名字的元组而已，所以对着定义 里的 `dpeth` 搜索它的使用情况。主要有两个使用的场景：

 1.  在 `class TLAsyncCrossingSource` 里，从 `edgeOut.manager` 里取出 `depth` 参数， 传递给 `ToAsyncBundle` 和 `FromAsyncBundle`.
 2.  在 `case class TLAsyncEdgeParameters` 里，作为参数传给 `case class TLAsyncBundleParameters`. `TLAsyncBundleParameters` 有 `dpeth` 和 `base` 两个参数，所以 `Async` 之名只值一个 `depth` 而已，而这个 `dpeth` 只由 `TLAsyncManagerPortParameters` 持有（源头）， `TLAsyncClientPortParameters` 则只用 `base` 参数记录 `TLClientPortParameters` 而已。

总而言之，在 `ToAsyncBundle` 和 `FromAsyncBundle` 里 `depth` 才是有实际意义的。 它们都是函数单例，首先看 `object ToAsyncBundle`. 在 `ToAsyncBundle` 的表层， 进行了几个端口的连线。它的输入参数是 `ReadyValidIO`, 这是一个同步的 io 端口。 首先将 `ReadyValidIO` 接到 `AsyncQueueSource` 的输入端，再将 `AsyncQueueSource` 的输出端接到 `AsyncBundle` 上。最后返回的是 `AsyncBundle`, 它将作为一个公共界面， 进一步连接到 `FromAsyncBundle` 上。在 `FromAsyncBundle` 里，则是接收一个 `AsyncBundle`, 将其输出连到 `AsyncQueueSink` 的输入上，再把 `AsyncQueueSink` 的输出连接到 `DecoupledIO` 上， 这里可以看出 `ToAsync` 和 `FromAsync` 的语义，即从同步端口变成异步端口，再从异步端口变成同步端口。 简单描述的话，是这样的：


	DecoupledIO := AsyncQueueSink := AsyncBundle := AsyncQueueSource := ReadyValidIO

在 `AsyncQueueSource` 中有 `val mem = Reg(Vec(depth, gen))`, 所以队列实体在 `AsyncQueueSource` 这边. `io.ridx*` 是输入，而 `io.widx*` 是输出，由 sink 指定读的进度，由 source 指定可以写的位置。 内部 `widx` 好像是用格雷码生成(`GrayCounter`)的，每次 `io.enq.fire()` 就前进一次。 在异步传输中，用格雷码是比较安全的，学习到了。 有异步复位的 `widx_reg` 来寄存 `widx` 并输出到 `io.widx`. 内部 `ridx` 就是多拍同步 `io.ridx`。 如果输入的 `ReadyValidIO` 一直不 `valid`, 那么这里 `io.enq.fire()` 也不会有效， 导致 `widx` 不会前进，所以不 `valid` 的请求是不会进入队列的。

`AsyncQueueSink` 是与 `AsyncQueueSource` 对称的存在。

它们生成的格雷码多一位，通过下面的算式将其还原为正确的下标：


	val index = io.widx(bits-1, 0) ^ (io.widx(bits, bits) << (bits-1))


----

为什么 node 之间的 `:=` 操作要记录对方的下标呢？

在 MixNode 里，有这样两行代码：


	lazy val edgesOut = (oPorts zip oParams).map { case ((i, n), o) => outer.edgeO(o, n.iParams(i)) }
	lazy val edgesIn  = (iPorts zip iParams).map { case ((o, n), i) => inner.edgeI(n.oParams(o), i) }

为了知道对面的端口参数以构造 edge. 每个 edge 实例会提供代表协议行为的方法以构造 一个 message bundle. 但是这个 message bundle 要怎么连上去还是要用户自己决定的。


----

在把 node 连到 `AsyncBundle` 之前进行屏蔽，仔细观察 `AsyncBundle` 里的入队列逻辑。

### 理解 Node 和 Edge

总线连接时，edge 这个概念算是最为生疏的了。为了理解 edge 的作用，我从一个具体的 实例 `TLEdgeIn/Out` 开始分析，观察它的组成和使用场合。

`TLEdgeIn/Out` 的构造块里，干了非常重要的一件事，那就是实例化了 TileLink2 各个 channel 的 bundle.

`TLEdgeIn/Out` 都继承自 `TLEdge`. `TLEdge` 里主要定义了一些属性的 getter 方法， 重要有 `numBeats` 等。它还有个参数 `TLEdgeParameters`. 这个参数又含有另外两个参数 `TLClientPortPrameters` 和 `TLManagerPortParameters`. 这两个参数一起组成 `TLBundleParameters`. 其中定义了一些重要的数据宽度， 而其定义的 `union` 操作就是将相同的参数取较宽的那个。

`TLEdgeIn/Out` 里定义了一些类似协议行为的方法，它们会根据输入参数，返回一个配置 好的 channel bundle. 这些方法看似构造了一个消息，实际上以电路的视角来看，只是构造 了一个消息通道。这些通道通过 Mux 被送入总线的 `bits` 域。

`Node` 提供了方法，以根据传入的 manager/client 参数信息返回 edge 实例。

### 总线架构


	digraph G {
	  L11toL2_node -> l2Config_CoherenceManager
	  l2Config_CoherenceManager -> bankBar -> mem
	  coreplex -> mmio -> socBus_node
	  intBus_intNode -> mmioInt -> coreplex
	  L2_node -> l2in -> coreplex
	  coreplex -> mem -> TLToAXI4_node -> mem_axi4
	}

总线架构暂时理解成这样，似乎有些模糊的地方，比如 `l1tol2` 不应该和 `coreplex` 关系这么疏远。还需要进一步调整。

### 有没有可以直接连的 node

`TLOutput` 连 `TLoutput` 会跪掉，找不到符号，生成的中间代码自己连自己…… 试试 `TLOutput -> TLInput -> TLOutput` 的组合……这个组合也不行，顺便在 `:=` 那里 打了 log, 观察了可行的 node 连接例子。 实在不行就听 yzh 的直接在 L1cache 上做。

`node` 的连线必须要在 lazy module 外面做，不然会认为输入与输出数量不匹配。

## 2017-03-06

### 尝试解决 ControlledCrossing 编译错误的问题

从 `:=` 的日志里发现，`AdapterNode` 似乎是一个很好的中间节点，既有 `TLOutputNode` 作为输入，又有 `TLOutputNode` 作为输出。但是 `AdapterNode` 的使用有些麻烦， 要显示地提供参数变换的函数。依然出现同样的错误。

现在还原 `TileNetwork` 的写法，并额外增加 node 来应用 `ControlledCrossing`, 观察其行为。

直接报错的地方是 `AsyncRocketTile` 创建 `rocket` 的地方。所以 undeclare 问题是 与 `rocket` 相关的。

没有办法找到其他可以使用的 `Crossing` 的例子，要想做 node 之间的传输实在是太困难了。 使用 `TLXbar` 作为中介，虽然通过了 Scala 和 Chisel 的检查，但是 Firttl 还是以 找不到变量定义为理由挂掉了。

找不到符号的具体问题是我的 `ControlledCrossing` 里具体绑定了一个 `rocket` 引用， 很神奇。

可能是 `OutputNode` 的定义导致的：


	class OutputNode[PO, PI, EO, EI, B <: Data](imp: NodeImp[PO, PI, EO, EI, B]) extends IdentityNode(imp)
	{
	  override lazy val bundleIn = bundleOut
	}

由于 `OutputNode` 的定义，其 `bundleIn` 和 `bundleOut` 指向同一个对象。所以对其 进行输入到输出的连线是容易产生问题的。最好还是使用 `MixNode` 这种没有限制的来做 中介。

### 理解 Node

`gci` 表示 greatest common inner. `gco` 表示 greatest common outer. 在 `MixNode` 里有唯一的具体实现：


	def gco: Option[BaseNode] = if (iParams.size != 1) None else inner.getO(iParams.head)
	def gci: Option[BaseNode] = if (oParams.size != 1) None else outer.getI(oParams.head)

看着比较绕，为了理解 `inner` 和 `outer` 的概念，以 `TLAsyncSourceNode` 为例。 它是 `MixNode(inner = TLImp, outer = TLAsyncImp)` 的子类。 `TLAsyncSourceNode` 接受 `TLImp` 实现的节点输入，输出为 `TLAsyncImp` 实现的节点输出。

感觉这些东西都是用来画图的……

### 新的问题：Chisel 生成了未定义内部变量

照抄了 `TLAsyncCrossingSink` 并把 `node` 替换为基于 `MixNode` 拓展的中介节点，现 在不会说把 `rocket` 的定义给直接绑到 crossing 模块里了。但是出现了新的问题，就是 在 `trait TileNetwork` 里用来中转的节点变量被生成了匿名的 `_T_188`, 被用来进行连 线，但是 `_T_188` 却没有定义……

#### 解决方法

没有探究到问题的根本原因，我尝试了 `TLAdapterNode -> TLXbar -> TLOutputNode` 这种 看起来很合理的连线，但是依然不行。似乎只要 `masterNodes.head` 和 `l1backend.node` 之间有任何间接实体，都会产生这种未定义内部变量的错误。机缘巧合，我观察到 `trait HasSynchronousRocketTiles` 里这样一段连线：


	l1tol2.node := TLBuffer()(_)

`TLBuffer()` 接受一个 `OutwardNode`, 输出一个 `OutwardNode`, 接口合适，而且也没有 额外的过多的语义信息，很适合用来测试。我测试了如下的连线：


	masterNodes.node := TLBuffer()(l1backend.node)

发现可以成功编译。于是赶紧将其应用于自己的连线：


	masterNodes.node := TLCrossing(l1backend.node)

这样就没有问题了，可以顺利地被 Firttl 编译。

#### 小问题

观察生成的 Verilog 代码，我发现 `TLCrossing` 里屏蔽 `a.valid` 的语句比较诡异， 它从一个没有初始化的寄存器变量里读取值进行连续赋值。这时我的掩码使用的是 `Wire(false.B)` 这个写法，考虑到当前文件主要以 Chisel2 的代码为主，我换回 `Bool(false)` 后，发现确实赋值成 0 了。

### 理解 LazyModule

Rocket-chip 的 LazyModule, 或者说 Chisel 所开放的 Scala 的类型体系破坏了 Verilog 中纯粹的 module 包换的概念。一个普通的类，或者说 LazyModule 类里定义了一个 module 实例，只是将这个 module 在电路世界中实例化而已。其所处的 Scala 位面的类型体系与其 在电路世界中的嵌套结构毫无关系。要与其他 module 产生联系，需要：

 1.  通过 module.io 进行连接，或
 2.  在 module 内实例化。

Chisel 是要求所有的 `:=` 以及器件的实例化都在 module 内完成的。在 LazyModule 的 module 对象里，引用外部的 module 并进行连线，由于那是 Scala 的类构造器，所以在 实例化的时候就会去执行，实际上与 module 外部的连线操作别无二致。当然，若是 module 被复数次实例化的话，那么构造器里的连线操作可以让外部不必在构造时遍历并连线。

[据说](https///github.com/ucb-bar/chisel3/issues/350#issuecomment-258077010) 使用 `import Chisel._` 的兼容层会关闭语法检查，容易生成非法的 firttl 代码。

## 2017-03-07

使用 yEditor 打开 rocket-chip 生成的 graphML 文件后，会看到所有的节点都重叠在一起，可以在 Layout 里选择布局策略平铺节点。黄色的是独立节点，淡蓝紫色的是组框，独立节点可以自由移动，组框移动时组内所有节点跟着平移。一开始的标签文本是竖着的。选中标签文本，ctrl-a 选中所有标签，在 Properties view 里修改 Placement 和 Rotation Angle 即可调整。yEditor 的 graphML 画面简练，缩放流畅，操作自然，只可惜 graphML 似乎不能加引脚，但是用于画关系图是非常好的选择。

为什么 Scala 里 `zipWithIndex` 后要用 `case` (partial function)? 因为 `zipWithIndex` 后对其用 `foreach` 进行遍历，回调函数要接受的是一个二元组, 而要想拆开来，需要用 `case` 进行模式匹配.

### rocket-chip

虽然在 rocket-chip 的 lazy module 架构里，chisel 层面的 module 只是 lazy module 的一个成员，但是 lazy module 实例的嵌套关系是会体现成电路的嵌套关系的（？）。我们只能够通过端口来访问直接子模块，所以内部变量还是需要一层一层地将接口网上暴露。但是 node 系列的连接看起来十分的行云流水，研究一下它的端口暴露到底是怎么处理的。

如果我仿照 `TLAsyncCrossingSource/Sink` 那样，将 `ControlledCrossing` 引用留在工厂函数里 ，只传出需要连线的端口，则会在 module 内连线 `outer.enable := io.enable` 上出现问题，这 不合理，这个模块本身是 LazyModule `RocketTile` 的本体，而 `ControlledCrossing` 是它的一 个内部模块，这样的写法不就是在说“把输入连给子模块的输入”吗？但是 chisel3 的报错分析下来 原因是 `outer.enable` 在模块内不可获取。别无他发，我只能在将 `ControlledCrossing` 彻底暴 露给 `RocketTile` 了。原来的连线变成了这样（大意）：`outer.module.io.enalbe := io.enable`. 这与 module 里其他对 `outer` 的使用是一致的。但是为什么 `node` 就可以传出来连呢？莫非是 因为它们重载了 `:=` 导致的？

## 2017-03-08

### 重新编译 PRM

为了测试硬件上的 ptab, 还需要重新编译 PRM. PRM 的项目在 [pard_fpga_vc709_sw](http://10.30.7.141/pard/pard_fpga_vc709_sw)

 1.  修改 PRM 表项
 2.  构建 RPM
 3.  部署 PRM 到服务器

#### PetaLinux 工作流程

准备环境：

	:::bash
	source /path/to/petalinux/install/dir/setting.sh

创建项目：


	petalinux-create -t project -n `<PROJECT-NAME>` --template zynq

这样会在当前目录下新建一个 ``<PROJECT-NAME>`` 目录，这个就是 PetaLinux 项目的根目录。

创建应用，进入项目根目录后，执行以下命令：


	petalinux-create -t apps -n `<APP-NAME>`

这样便会在 `components/apps/` 目录下新建一个 ``<APP-NAME>`` 项目。

#### 修改 PRM 表项

几个已有的修改例子：

 1.  http://10.30.7.141/pard/pard_fpga_vc709_sw/commit/bd490f29c9366b18d8cb8a847fc16753bee43f30
 2.  http://10.30.7.141/pard/pard_fpga_vc709_sw/commit/e148b088f223ebfb4481c6d000047ff40f83f217

一个对应配置，一个对应驱动。

PRM 对应的文件在 `prm_core_bd/components/apps/pard/` 下。

#### 构建 PRM

> 构建命令： ~~petalinux-build -c package~~ `petalinux-build` -- pobu

> 编译 PRM 的时候记得把 `prm_core_bd/subsystems/linux/configs/device-tree/cpa-conf.dtsi` 里面的 `cachecp` 和 `iocp` 注释掉，现在 vc709 的工程里还没加这两个 cp, 不注释它们的话访 问 I2C 会一直报错。 -- yzh

`petalinux-build -c` 是用来指定 `package` 的，即 `rootfs`, `u-boot` 这类独立的编译对象。 `petalinux-build -x` 用来执行构建命令。一般情况下，不带参数地使用 `petalinux-build` 即可 完成构建。以上是在纯晶的样例工程下测试的结果。

在 PRM 工程里遇到的问题是：工程基于 Vivado 2014.4 的 SDK, 而环境默认的 SDK 以及硬件使用 的 SDK 都是 2016.2 版本的。在版本不匹配的情况下，执行任何构建相关的操作，都会得到 `UWEB` 无法发现的错误。

将环境变量里的 SDK 从 2016.2 改成 2014.4 后，各个组件能够编译，但是最后生成 Linux 内核文 件的时候，会报错，原因是想要连接 libc.a 等标准库时失败。进一步的原因可能有标准库的架构不 兼容，没有访问权限等。

使用 `petalinux-build -v` 观察详细的编译过程，发现第一次错误是在执行 build 目录下一个 libtool 脚本，与 `/usr/lib/` 这个搞事的目录有关的是一个 `-rpath` 的选项。虽然 libtool 的 参数很长，但是 `-rpath` 是在其 `--help-all` 文本里搜到的。其行为是将生成的文件放置到 `-rpath` 指定的目录下。这与读并没有关系，但是将 `-rpath` 这个选项注释后，单独执行这个 `libtool` 命令，使用原来的参数，就能正常结束。如果不注释，同样的错误也会在这个独立的运行里复现。 但是如果 `-rpath` 指定了其他目录，则依然是在 `/usr/lib/libc.a` 上报错。这个错误可能是由 ld 命令发出的。`-rpath` 这个选项会启动 ld, 然后 ld 会去读取 `/usr/lib/libc.a`?

这个问题暂时搁置，服务器 172.16.250.2 虽然有 Vivado 等 Xiliinx 的工具，但是在这里 PetaLinux 一直没有成功编译过，应该去服务器 172.18.11.211 编译，这是旧的 EDA 开发服务器。

以后修改完 pard 相关内容后，只需要：


	petalinux-build -c rootfs/pard
	petalinux-build -x package

即可最小化重新构建。

#### 部署 PRM 到服务器

从 172.18.211 可以访问 10.30.6.123. 在 Program File 后启动的 u-boot 系统里，`run netboot` 会从 10.30.6.123 的 `/tftpboot` 目录下载 `kernel_image` 指定的镜像文件。 `petalinux-build` 生成了许多的镜像文件，我们需要的是带 `.ub` 后缀的。 要启动自己的 PRM 镜像，只需要将镜像文件上传到 10.30.6.123 服务器的 `/tftpboot` 目录下即可， 注意不要覆盖已有的文件。然后将 `kernel_image` 设置成自己的镜像的名字即可。

快速上手 tftp:


	$ tftp
	(to) 10.30.6.123 # a.k.a tftp> connect 10.30.6.123
	tftp> get image-risc.ub
	tftp> put my-image.ub
	tftp> quit

在没有注释掉 `cachecp` 和 `iocp` 的 i2c 表项的情况下，启动后没有看到 `migcp`. 注释后依然出错，原因是只重新编译了 pard 就进行 package, 可能内核没有被更新。 device tree 相关的内容可能要重新编译内核。完整地重新编译整个工程后，成功看到了 `migcp`.

#### PRM 问题

已经设置 migcp/ptab 的 col 为更大的数了，并且能在 PRM 里看到新的 col 了，但是往里面写东西 没有效果。rocket 那边应该已经是新的 bitstream 了，因为连第一个核心都不能写镜像了，说明 默认关闭的使能起作用了（L1 的 icache 和 dcache 自己的一致性回复也给屏蔽了）？

写入逻辑是一视同仁的，感觉问题只可能出在硬件这边了，一个被忽视的问题是大小端。我赋值 `wdata[0]` 很可能用了逻辑上的高位？但是我用 `0xffffffff` 和 `0xffffffffffffffff` 去写， 都没有效果。

任何对 cpa 的读写请求，都是通过调用 `llt_read/write` 来完成的。我在那里添加日志，输出更新 的行和列，并检查 `i2c_transfer` 的返回值，发现可以更新的列（0, 1）和不能更新的列的返回值 都是 1. 初步判断软件这边没有问题。

我修改了一番代码，主要是使用 `[row:row]` 这一更为保险的写法，并且修正了读取值多出一位的 问题，并准备为 col 和 L1enable 添加 probe. 放一晚上综合，明天来解决。

单独综合准备设 probe 的时候，发现综合失败了，原因是有长度的变量类型不能用非常数的下标去 访问，这个问题以前貌似也遇到过的？但是为什么生成 bitstream 的时候不报这个错呢？

### 自动化流程（期望）

250.2 上完成修改后，推送到 GitLab, 然后 GitLab 用 Webhook 通知 11.211 进行重构，并上传镜 像到 10.30.6.123, 10.30.6.123 进一步将镜像拷贝到 `/tftpboot` 目录下。

## 2017-03-09

### kloader0 访问超时

虽然看到 entry 更新了，但是 /dev/kloader0 一直访问超时，可能是访存一致性协议的问题？ 如果我的使能没有正常地传给 rocket 的 L1 backend 的话，可能导致一致性响应无法回复？ 虽然我只控制了 Acquire 通道……

原因是 i2c 的数据是 64 位的，而下下来的工程里 device tree 定义的 dma 的宽度是 32 位， 不匹配导致的。

http://10.30.7.141/pard/riscv_pard_fpga/issues/44

### L1enable 有效后无法恢复运行。

http://10.30.7.141/pard/riscv_pard_fpga/issues/45

现在计划使用仿真器测试 enable 的行为。仿真器的入口文件是 `csrc/emulator.cc`. 描述仿真环境的 Chisel 代码在 `src/main/scala/rocketchip/pard/PARDHarness.scala`. 里面的 `TESTHarness` 会被被编译成 `VTESTHarness` C++ 类。

Emulator 拥有 `tile: VTESTHarness`. 可以直接访问端口，自己定义在 `TESTHarness.io` 中的要 加上 `io_` 前缀。仿真器的周期模拟是通过时钟置零进行一次 `eval()`, 时钟置一再进行一次 `eval()` 完成的。

修改仿真器，初始关闭使能，在固定周期数后开启使能，若是在 DMA 完成前使能有效，则可以 启动，否则，不能启动。

在 `ControlledCrossing` 里在 `a.valid` 有效时输出信息，发现有两拨集中的输出，但是之后并不会 输出了。

可能我应该屏蔽 `out.a.ready`, 实装后大概率启动 bbl, 但是依然存在不能启动的情况。可能是时序问题？

## 2017-03-10

将 `token_bucket` 整合进 `migcp` 里。由于现在是直接控制 L1, 所以不再拦截 AXI4 上的流量。 在这种情况下，可能会出现已经拦截了 L1, 但是由于尚未结束的请求仍然存在，会继续消耗 token. 此时 token 已经不够用了，那么 `rpass` 或 `wpass` 会无效，它们都能阻塞 L1 的请求。

为了体现 `token_bucket` 的通用性，我将计算流量、判断读写请求以及判定身份都放到了端口上。 我发现 `migcp` 里 `dsid` 是在 `detect_logic` 里写死的，可能需要后需改进。

另外，我发现 `genvar` 是可以定义在 `generate` 语句块里面的。

要测试令牌桶，首先令 L1 使能有效，桶容量为 0, 增长率不为 0. 这样不会 bypass, 但是能阻塞 L1.

上板测试，能写入 ptab, 但是无法体现控制效果。通过 ILA 观察发现是 `is_reading/writing` 没有拉高导致的。还是能观察到 `rpass` 和 `wpass` 下降的，但是它们下降之后，会升高，因为 我让这个 AXI4 请求通过了，当然也必须让他通过，不然 `valid & ready` 一直无效，后面的就过 不来了。对 TileLink2 的 crossbar 的 arbiter 的行为的理解应该是这样的：单独的 channel 发 请求，单独的 channel 响应，arbiter 把请求发出去就没事了，但是 token bucket 实际上卡的就是 crossbar 的这个发的动作，所以从 L1 那边阻塞还是有道理的！

但是恢复的逻辑就不知道怎么办好了，因为在 L1 那边阻塞，所以没有办法知道它想要过来的流量.

## 2017-03-11

Token bucket 抑制源头后，如何处理尚未结束的 (outstanding) 的流量呢？ 目前，一旦发现 `nr_token` 无法满足读写请求，会放行请求，但是导致使能无效。 但是 `nr_toen` 不会减少，因为旧代码逻辑认为这边不会发出请求了。

写了仿真文件并不断调整判定条件，以获得期望的行为。为了介绍 32 位数的运算，检查了数值与 使能之间的关系，最后使用端口使能来表达“大于 0”这样的判断，当然这是基于读写请求流量必定 不为 0 的假设。

接下来要实装一个 traffic generator 来干扰核心。如何 generate traffic? 现在我的思路是参考 `Fuzzer`, 使用一个 `TLClientNode`, 将其 `out.a.valid` 和 `out.d.ready` 一直有效。但是其他内容没有设定，不知道会不会被当做一个合法的请求？ 比如说，d channel 是怎么找到这个 node 返回过来的呢？

现在在 `CoreplexNetwork` 的 `l1tol2` 定义的地方实例化了一个 traffic generator 并 连线，已经通过了编译，生成了仿真器。由于要准备 bbl (bbl.bin, bin.txt, bin.???)

突然想到这样空着请求内容不写容易，岂不是 AXI4 那边看到请求流量为 0 吗？ 而且 dsid 也没有设置，到时候肯定不起作用，还得再精耕细作一下。再看看 `Fuzzer` 和 cache 怎么构造请求的吧！

没有指定的端口默认连 0 吗？编译完跑了一下，没看到 bbl 的内容，也没有看到 tg 的内 容。给 `PARDTop` 端口指定了默认值后，可以看到 bbl 的输出了。但是似乎还是随机的哈。 看来还是要在 `PARDHarness` 里显式绑定才行，端口默认随机送值，还值随机送一次……

不过现在问题比较大的是看不道 tg 的 log. 也就是说没人理它。还是得再看看 `Fuzzer` 之类的是怎么构造请求的。先试试看直接用 Fuzzer 是个什么效果？

在 `PARDHarness` 里，AXI4 要求 user 也就是 TL2 的 dsid 一定是 1, 这应该是出于单核 的考虑吧。

Fuzzer 的随机请求有出现，但是没有输出的语句！果然 `println` 在 chisel 编译期执行了！ 使用 `printf`.

现在问题是 `Fuzzer` 是有次数限制的。当然改改就没了，然后看了一下发送频率也不是很 快的样子，而且比较尴尬的是开始地太早了，甚至和 dma 混在一起。不过在实际环境下， 我们可以先将其卡死，准备测试了再将其使能。

## 2017-03-12

控制流速主要是看 `valid` 什么时候有效，`TLFuzzer` 的 A channel 的 `valid` 有效条件是这样 的：


	out.a.valid := legal && alloc.valid && num_reqs =/= UInt(0)

`legal` 则会根据随机生成的地址来判定有效性，导致很多周期产生的都是无法送出的非法请求。现在我通过输出来观察地址特征，并且，考虑根据 edge 信息来修正生成的地址，而不只是去判断它是否合法。另外虽然 traffic generator 要干扰 memory controller, 但是不能产生副作用，如果要用 `TLFuzzer` 的话，要仔细剔除有副作用的请求。

基于 `mask` 和 `base` 描述的地址空间的包含判定：


	// diplomacy.AddressSet
	def contains(x: UInt) = ((x ^ UInt(base)).zext() & SInt(~mask)) === SInt(0)

`TLFuzzer` 展示了 `Edge` 一个实际用途：


	// Actually generate specific TL messages when it is legal to do so
	   val (glegal,  gbits)  = edge.Get(src, addr, size)

也就是将高层语义的请求描述转换成实际的通信报文。

在 `uncore/tilelink2/Bundle.scala` 里，有一些对 TileLink2 解释性的内容，比如说， ABCDE 五个通道是什么意思呢？


	def isA(x: UInt) = x <= Acquire
	def isB(x: UInt) = x <= Probe
	def isC(x: UInt) = x <= ReleaseData
	def isD(x: UInt) = x <= ReleaseAck

`Get` 请求返回的 `legal` 是 `GetFast` 提供的，与 `manager` 的 `containsSafe` 应该都是检查地址空间用的？但是二者并不总是相等。区别就是 fast 的 `AddressSet` 会经过一个 `map(_.widen(~routingMask))` 的映射（`tilelink2/Parameters.scala`），感觉就是取消了掩码检查？

什么是 `inFlight`? 送出去的请求没有收到响应，就是 `inFlight` 的。`IDGenerator` 会在收到响应时回收 `sourceId`, 并用一个深度为 1 的队列送出新 `sourceId`。

在 trait 里依赖 `implicit val p: Parameters` 的例子非常少，但是在 trait 里实例化 `LazyModule` 必须要有 `p`. 实际上很多实例化 `LazyModule` 的 trait 都会混入(mix-in)一些类型 `HasXXX` 的 trait, 这些 `HasXXX` 追根溯源，都会声明 `implicit val p: Parameters`.

(scala) 不带 `val` 的构造器参数是可以被自己，拥有者访问的，但是不能被子类访问……

只有重载过的 `:=` 才能在 `LazyModule` 里面连。Chisel3 原生的器件在 `LazyModuleImpl` 里连。

Block design 的 parameter 设置会覆盖代码的默认设置。如果修改了 Verilog 代码的参数，要重新用 `system_top.tcl` 来生成才有效果。

BUG: `freq == 0` 并不会 bypass, 而是卡死了。

开启 traffic generator 后，核心还能操作，但是重启就不行了！出现了没有见过的核心同时重启的情况！感觉是 traffic generator 干扰了核心的内存？但是重启都无济于事是为什么呢？

将 traffic generator 的地址空间与 core 0 的地址空间隔离（使用的 core 1 的地址空间） ，令牌桶无限制，内核启动时间由 15s 升至 58s. 卡住 tg 后恢复到正常水平。stream.int 无法 启动，故暂时看不到。这之后关了 tg 再启动 core 1, 依然启动不了。

偶尔会蹦出这个：`ttyUL2: <n> input overrun(s)`.

重启之后有遇到空指针。

又蹦出了这个：


	libphy: 40c00000:01 - Link is Up - 1000/Full
	libphy: 40c00000:01 - Link is Down

DMA time out 的话，可能是没有响应缓存一致性请求？如果把它连接在 `socBus.node` 上，不在 L1 级的话，是不是可行呢？但是 `socBus` 也是 `TLXbar`, `l1tol2` 会做的事情，它应该也会做？

稳定重现：

 1.  将 tg 与 core 0 处于同一地址空间
 2.  启动 tg
 3.  启动 core 0
 4.  重启 core 0, 这次能写完镜像，但是 core 0 卡住，在 `boot_loader()` 处
 5.  重启 core 0, 这次 `/dev/kloader0` 超时

可能不是 tg 不响应一致性，是 core 0 卡住没响应？

### 实际运行时的内存映射是怎样的？

虽然看编译期的生成的映射地址，两个核心是在可写区域是分成了两个连续但独立的部分，但是在我们的 bbl 中，直接放弃了读取 config string, 而是直接设定成 `0x80000000` 起始的。此外 vc709 的一块 DDR3 有 4GB, 所以看起来分配得很像虚拟地址。

## 2017-03-13

### Traffic Generator 共享空间导致无法重启

昨天追踪代码发现是卡在 `load_kernel_elf()` 函数里了，首先在这个函数里插 log, 进一步寻找出问题的地方。

卡住的地方，是载入内核代码的 `memcpy` 操作， 感觉基本可以确定是写数据时一致性得不到响应造成的了？

我注意到即便在 DMA 传输前将对应核心重置，也没有效果。

现在 `TrafficGenerator` 是挂在 `l1tol2` 的后面的，和其他 `l1backend` 处于同一级别。 而 `l1tol2` 通过 `l2Config.coherenceManager` 连接到 `mem` 上， `mem` 再连接到 `TLToAXI4` 的 converter 上，最后再连接到最外面的 `mem_axi4` 的。 `l2Config.coherenceManager` 实际上实例化的是 `TLBroadcast`.

要连的话，就要连到 `bankBar.node` 上，这是一个单出口，多入口的 `TLXbar`. 所有的 bank 都连相同的 `l1tol2.node`, 但是会按下标和 cache block 大小做划分，以达到并行访问的目的。 如果我直接将 `TrafficGenerator.node` 连接到 `bankBar.node`, 并用 `TLFilter` 过滤地址的话，应该没有问题，它本身就是个 Xbar, 做仲裁应该是没问题的。但是地址划分的标准是 cache block 的大小，这个参数对 traffic generator 没有意义，或许可以考虑从 data sheet 里找到需要的参数，暂时先不过滤地址，直接连多份输出。

每个 channel 一个 `bankBar`, 一个 `bankBar` 有 bank 数个地址隔离的输入。

`BankedL2CoherenceManagers` 和 `CoreplexNetwork` 是同一级的，端口 io 不需要改动。

将 traffic generator 绕过 coherenceManager 直接挂在 mem 上后，一旦使能，核心无法交互，DMA 无法完成传输，而且不会超时，同时核心无法重启，依然是在执行拷贝内核代码的 `memcpy` 时阻塞。

（术语）nack = Negative ACKnowledgment, 否定回答。

尝试通过响应 Probe 消息来解决阻塞问题。依然存在问题，但是 Probe 的响应是否正确也无从得知。可以考虑给 trafficGenerator 加探针，观察它是否真的接收到了来自 coherence manager 的请求。

使用 `groundtest` 测试，在 `BroadcastRegressionTestConfig` 配置下，没有引入 `TrafficGenerator` 的情况下，能成功通过测试。但是引入激活的 `TrafficGenerator` 则会在第一个测试时因超时触发断言。目前为止的表现与预期相符，不过 B channel valid 时的日志没有输出，说明对一致性协议的理解还有错误，没有伪装出预期的效果。

接入 `TrafficGenerator` 但是不让其工作，也能顺利通过测试，但是依然没有看到日志，说明其在系统中是透明的存在。使用 `inFlight = 1` 的 `TrafficGenerator`, 依然能通过测试，有输出，但是没有一致性协议方面的行为。此外， `BroadcastRegressionTestConfig` 设置的 time out 仅有 5000 个周期，并非什么严谨的约束。

使用 `inFlight = 1` 的版本进行硬件测试，发现对系统带宽没有影响。两个核心都可以正常重启。使能是连在外面的，只有 `groundtest` 里是绑定字面值的，应该不会是使能无效导致的不起作用。但是如果是因为流量太大干扰太强，为什么第一次能够启动，而第二次却会卡住？

今晚实验的结论：跑了若干配置的 groundtest, 都没有出现 B channel 有效的情况，也就是 `TrafficGenerator` 并没有参与一致性协议，这可能是通过 `TLClientNode` 的参数配置的。此外，`groundtest` 失败的情况，都是由于访存请求过于密集导致超时。使用请求并发度为 1 的 `TrafficGenerator` 并不会对系统产生任何影响。那么理论上，只要 `TrafficGenerator` 关闭使能，就一定能让系统恢复运行，且用令牌桶限流应该能保证系统处于一个可用的状态。明天进行这方面的测试。

作为参照，`ICache` 的 `node` 初始化方式如下：


	val node = TLClientNode(TLClientParameters(sourceId = IdRange(0,1)))

而 `Dcache extends HellaCache` 的 `node` 则是这样的：


	val node = TLClientNode(TLClientParameters(
	  sourceId = IdRange(0, cfg.nMSHRs + cfg.nMMIOs),
	  supportsProbe = TransferSizes(p(CacheBlockBytes))))

`ICache` 要从 `DCache` 那探测可能的脏代码数据，而 `ICache` 自己由于是只读的，所以不需要被探测。

### Rocket-chip 的一致性协议

按照旧的 [TileLink](https///docs.google.com/document/d/1Iczcjigc-LUi8QmDPwnAu1kH4Rrt6Kqi1_EUaCrfrk8/pub) 的说法，一个基本的通信流程如下：

 1.  一个 client 向 manager 发送 Acquire
 2.  Manager 向 client 们发送必要的 Probe
 3.  Manager 等待每个 Probe 的 Release
 4.  Manager 在需要的时候与后端内存通信
 5.  获取 data 或 permission 后，manager 用 Grant 回复最初的 client
 6.  一收到 Grant, client 向 Manager 发送 Finish

## 2017-03-14

如果一开始把 traffic generator 启动但是流量限制得比较死，那么核心也是可以自由地重启的。 但是，以 (1024, 500, 128) 的限制，则已经影响了核心的启动，此时再将使能关掉，核心也只能前进一小段，然后继续不响应。

也就是说，性能不能下降？考虑扩大 `io.enale` 控制的内容。 假的一致性回复被测试认定为非法的：


	Assertion failed: 'C' channel ProbeAck carries unmanaged address (connected at TrafficGenerator.scala:120:15)
	    at Monitor.scala:174 assert (address_ok, "'C' channel ProbeAck carries unmanaged address" + extra)

但是感觉不对啊，难道 `Probe` 有效了？

让 `io.enable` 在 10000 个周期后无效，通过测试，但是在实际系统中通过手动设置依然不行。


----

在 kloader0 以 `time out` 为理由退出后，想要关掉 tg 的使能，就会因为自旋锁错误导致内核恐慌。 根据[这里](http://blog.sina.com.cn/s/blog_55ac4a8001010uzq.html)的说法，这个问题可能是自旋锁未初始化即使用导致的.

根据 call trace, 是在 `kloader_dma_callback` 的处理路径里因为 `do_raw_spin_lock` 挂掉的。 但是此时 kloader0 已经因为超时而退出了。所以可能不是写 0 导致的问题，而是写 0 导致系统重新运作后，本来以为死透的请求又被响应了，产生了不一致的上下文。

经过测试，先关 tg 再开 DMA 则可以，启动后开关 tg 不会产生运行问题。开了 tg 后用 time find 测试，能观察到 7 倍的性能下降。 可以在 DMA 开始前关闭 tg, DMA 结束，重置 core 前开启 tg, 核心可以正常启动。

现在的结论是 DMA 方面可能有正确性问题，但是对于 rocket 来说，只是因为干扰过大导致无法正常工作？

DMA 传输完、核心重置前开启 traffic generator, 核心无法启动，关闭 traffic generator 也无法继续启动，重启也无法继续启动。如果关了使能，那么肯定可以保证 traffic generator 停止工作，之后就不应该有流量干扰，核心被阻塞的操作也应该继续执行下去才对。

现在在启动阻塞时关闭 TG 可以继续执行，而且中途打开再关闭也能恢复执行。但有时候还是不行，并且会导致 DMA 超时，已经确保 TG 关了。 现在关了还是能恢复的，但是干扰太强，可能都没法进入计时环节。还是要考察一下合适的令牌桶参数，此外，还要看一下 crossbar 的逻辑，感觉太过优待 TG 了。比如看下 Policy 的最小下标优先到底是什么的下标，如果是连接顺序就太有问题了。

使用自己完全重新编译的 riscv-linux 可以跑 streamint, 但是我用新工具链编译的 stream.int 放到 initramfs 里更新内核，即会在启动过程中 kernel panic 挂掉。

## 2017-03-15

`uncore/tilelink2/Xbar.scala#TLXbar@assignRanges`: 根据输入的 size 序列，按原来的顺序重新分配连续不重叠的 source id.

通过编译期的输出，我发现 `TrafficGenerator` 是第一个连到 `l1tol2` 的。而 `l1tol2` 的仲裁策略是最小下标优先。`TrafficGenerator` 一直有效可以将两个核心的请求给饿死。使用高下标优先的策略后，`BroadcastRegressionTestConfig` 在开启 32 路并发的 `TrafficGenerator` 下变得可以通过测试，而且也能看到干扰的现象，即原来需要 865 个周期完成的测试，现在需要 1107 个周期，而低下标优先时，第一个测试直接 3000 个周期超时了。

通过 ILA 观察到，traffic generator 有一段时间是完全不消耗令牌桶的，即令牌数量没有下降，但是此时系统不能交互，说明还是被干扰了。说明系统里还有一个阻塞源，同时阻塞了 DMA, 核心以及 traffic generator.

桶 size 和增长率都是 0 的情况下，使能竟然不是一直无效的！

如果令牌桶不加限制，则使能不会降低，则 traffic generator 只要不耗尽 source id, 就可以一直发送请求。但是如何统计这个值呢？

现在关了 tg 所有核心重启都会卡在这一步，也是：


	[    0.020000] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes)

如果开启 tg 则在 BBL 里就卡住了，说明 tg 也是工作的，但是此时看令牌消耗，一点没有，说明 tg 也被阻塞住了。 可能是特定的地址空间被阻塞住了，用 ILA 进一步观察情况。

program 完登录 PRM 后，直接启动 traffic generator 是不会看到请求的，要 `echo 1 > /sys/cpa/corecp/ptab/rowX/col1` 重置内核，让其中的 DCache 响应探测报文，才能放行。

但是在 tg 开启的情况下启动核心，会发现无论是 tg 还是核心都无法发送请求到总线上。此时关闭 tg 的使能，核心的请求就能发送到总线上。然后关闭核心使能，打开 tg 使能，则看不到 tg 流量，但是开着 tg 依然会影响核心的运作。第一次启动的核心和 tg 能和谐共存，都能抓到流量。

## 2017-03-16

### 修补 token bucket 细节

 1.  `freq` 为 0 时 bypass 起作用；
 2.  `size` 为 0 时应该限制流量。

昨晚综合的 bitstream 来不及指定 probe 了，现在也用不了 ILA, 先下载一份进行行为测试，然后并发地综合一个有 debug core 的版本。

Traffic generator 以参数 `size = 0, freq = 1, inc = 4096` 运行，内核启动过程没有被干扰，说明 `size = 0` 的限流效果达到了。

Traffic generator 以参数 `size = 0, freq = 0, inc = 0` 和 `size = 4096, freq = 0, inc = 0` 运行，内核启动过程没有被干扰，说明 `freq = 0` 没有起到放流的作用。如果使用 ILA 观察，希望看到的结果是令牌数量不下降。没有效果的原因是 bypass 时令牌数量不增长，可能停留在令牌数为 0 的场合，此时 `size = 0` 的效果优先体现？现在保证令牌足够的情况下，开启 traffic generator 的 bypass, 发现内核在 bbl 阶段阻塞。但是不知道此时是流量干扰的结果，还是出现了大家一起阻塞的情况。这之后再重启内核，即便关了 traffic generator 也会中途阻塞。

从 `pard_fpga_vc709` 项目里将 `designs/pardsys/srcs/rtl/xlnx_cache_pard` 和 `designs/pardsys/srcs/rtl/control_plane/cache` 移植到 `riscv_pard_fpga/fpga/srcs/rtl/` 下，`xlnx_cache_pard` 作为 L2 cache 接在 rocket 和 migcp 之间，工作在 rocket 的 uncore 时终域。同时可能需要修改 PRM 启动 cachecp 的文件抽象。

cachecp 和 xlnx_cache_pard 如何协同工作，还需要进一步了解。（把同名的端口连起来就行了，cachecp 基本就剩下 trigger 的端口没有用了。）

xlnx_cache_pard 的复位端口是低位有效的，而一般情况下，chisel 的复位端口是高位有效的，需要经过一个非门进行转换。在 block design 里，可以使用 Utility Vector Logic 来构造基本的门电路。

xlnx_cache_pard 的总线宽度与其他的不符，甚至干扰到了其他部件。无论怎么修改代码配置，validate 都认为 xlnx_cache_pard 的 `ID_WIDTH` 是 1, 与其他的不符从而报错。

## 2017-03-17

在 block design 里，rocketchip 的 AXI4 端口的 BID 显示的宽度是 1, 但是，它与 AWID, ARID, WID, RID 一样使用相同的 `idlen`, 也就是是 4. 将 `xlnx_cache_pard` 里的 BID 也设置成宽度 4, 则可以通过设计验证(validate design).

综合 `xlnx_cache_pard` 时报错说在 `system_cache_v3_1` 库里找不到 `system_cache_pkg` 和 `system_cache_queue_pkg`. 本地代码里已经有这两个 package 了，只是编译系统会去系统库里寻找。 不过 `system cache` 的版本是一样的，不知道为什么在系统库里会找不到 package. 本地代码的 package 默认包含在 `work` 库中，只要将本地代码中的 `system_cache_v3_1` 替换为 `work` 就可以消除一部分的语法错误提示。 此外，还需要将引用 `work` 库的代码在 Properties 里也设置成位于 `work` 库下，这样子才能通过综合。

修改了若干宽度不一致的问题，终于完成了 `xlnx_cache_pard` 的综合。 在使用正则表达式批量替换宽度时，有时候会把宽度数字匹配到变量的编号上，导致多驱动(multi driven)的问题。

System cache 加 cache control plane 在默认情况下可以正常工作，但是 riscv-linux 启动时间平均增加 1s. 考察 cache control plane 的 ptab, 发现 way mask 的默认值是 0, 访存请求可能绕过 L2 直接送往 MIG, 导致性能下降。

现在要在 PRM 里实现对 cachecp 的控制。我简单地将 device tree 里关于 cachecp 的注释去掉， 但是并没有在 PRM 看到看到 cachecp 文件。去掉的注释可能只是给 I2C 搜索用的。

观察 PRM 的启动日志，没有 cachecp 文件的原因可能是搜索失败导致的：


	[27,cpa_probe] pardcorecp@0x78
	[36,cpa_probe] type: 0x43, IDENT: PARDCoreCP
	i2c i2c-0: Added multiplexed i2c bus 1
	[27,cpa_probe] pardcachecp@0x79
	[31,cpa_probe] i2c_master_recv failed(ret = -5)
	i2c i2c-0: Added multiplexed i2c bus 2
	[27,cpa_probe] pardmigcp@0x7a
	[36,cpa_probe] type: 0x4d, IDENT: PARDMig7CP
	CPA: found control plane processor ID='EDFE0DD0'
	CPA: found control plane processor ID='28000000'
	CPA: found control plane processor ID='79130000'

错误码 -5 表示 EIO, 即 Input/Output Error. 按 http://stackoverflow.com/a/953131/5164297 的说法，我的 cachecp 没有连到 i2c 上。

每个 control plane 都有一个 addr 端口，在 block design 里连接着一个常量模块，里面的值和 `cpa-conf.dtsi` 的 `reg` 值是一致的。可能是我没有给 cachecp 指定正确的地址值，导致它没有被 I2C 发现。在 `cpa-conf.dtsi` 里，其值为 `0x79`.

加上地址常量后还是 i2c prober 还是返回 -5.

Control plane 共同的 `RegisterInterface` 的 RST 是高位有效的，从 migcp 的 aresetn 在内部反转可以看出。 但是我把 cachecp 和 migcp 连在一个 RST 信号上了。

### VIM 的正则表达式

VIM 有更简洁的方法来描述一个匹配的前驱和后继模式， 那就是用 `\zs` 和 `\ze` 标记捕捉文本的在正则表达式中的开始和结束位置。

## 2017-03-18

PRM 的 cachecp/ptab 只有一列，应该只能设置 dsid, 设置 0xffffffff 给这个列没有任何加速系统运行的效果。 在 Verilog 代码里，确实是第 0 列设置 way mask. 那么怎么匹配 dsid 呢？写死的。

	:::tcl
	reset_run synth_1
	update_module_reference system_top_CacheControlPlane_0_0
	launch_runs synth_1 -jobs 40
	set_property STEPS.WRITE_BITSTREAM.TCL.POST /home/wanghuizhe/riscv_pard_fpga/fpga/bitstream_notify.tcl [get_runs impl_1]
	set_property STEPS.WRITE_BITSTREAM.TCL.POST /home/wanghuizhe/riscv_pard_fpga/fpga/implement_notify.tcl [get_runs impl_1]
	reset_run impl_1 -noclean_dir
	launch_runs impl_1 -to_step write_bitstream -jobs 40

使用 ILA 观察了下信号，感觉都是正常的，设定的 way mask 也确实被送出去了。如果没有效果的话，只能说 system cache 那边有问题。不过已经确定过 reset 的正负没有接错了。

另外发现 cachecp/stab 里的表现比较奇怪，只有 col1 是有数据的，其他几列都是 0.

现在地址空间的隔离是在 mig 那边做的，靠近 ram, 但是中间有一致性协议和 L2 Cache (现在是 system cache) 需要比较两个核心的地址，不知道这个问题是怎么解决的？

测试组:

 1.  在 migcp 和 mig 间插入原版 system cache (已生成，虽然提示引用过期，但是不要怕尽管烧！) 这个也是平均慢一秒的。
 2.  使用 32 位数据宽度的 pard system cache, 使用 AXI DATA WIDTH CONVERTER 进行转换

在 migcp 和 mig 之间的普通 system cache 的 stream 结果:


	Function    Best Rate MB/s  Avg time     Min time     Max time
	Copy:              23.3     0.343424     0.343249     0.343878
	Scale:             21.2     0.395343     0.377800     0.417368
	Add:               27.0     0.444999     0.444788     0.445182
	Triad:             23.8     0.525975     0.504774     0.545308

设置这组对照组的目的是考察 system cache 正常工作的时候的性能指标.

这是没有 l2 cache 时 stream.int 的结果：


	Function    Best Rate MB/s  Avg time     Min time     Max time
	Copy:              23.8     0.336398     0.336202     0.336804
	Scale:             21.7     0.387202     0.368636     0.410192
	Add:               27.6     0.435692     0.435498     0.435833
	Triad:             24.2     0.517528     0.495357     0.535277

可见性能的拖慢是正常的，并非因为 waymask 没有发挥总用导致只有一路造成的。

使用数据宽度转换器的版本不能工作！这个 cache 与 cachecp 交互，他俩本身就是跨时钟域的！换个比较像 rocket 这边的 reset 试试。

现在把 mig 的 system cache 换成带标签的，不知为什么 ID_WIDTH 突然变成 5 了。看看能不能用过 way mask 起到限制作用。

## 2017-03-19

Data width converter 的方案依然跑不起来，而在 migcp 和 mig 之间插入的 pard system cache 也没有看到 way mask 的效果，而且 stab 里只有 total counter 有计数，其他的都没有。

way mask 无效和一直没有 hit 互为表里。

cache size: 32768, assoc: 16, block size: 64?

观察波形，发现一直没有允许 tag 写入，读 tag 的使能也一直没有有效.

`update_tag_we[i]` 和 `update_tag_en` 同时有效的那一路，是要被替换的。


	// sc_update.vhdl
	update_tag_en_i <= update_tag_write_raw or update_readback_available or update_readback_tag_en
	update_tag_write_raw <= ( update_need_tag_write and not update_done_tag_write and not update_stall_tag_write )

	// sc_lookup.vhdl
	update_need_tag_write <= update_need_tag_write_i
	update_need_tag_write_i <= update_need_tag_write_cmb
	update_need_tag_write_cmb <= ... and lu_check_keep_allocate
	lu_check_keep_allocate <= lu_check_info.Allocate and not lookup_true_locked_read and not lookup_block_reuse
	lu_check_info.Allocate // this one is always zero in ILA, 但是不是 C_NULL_ACCESS, 因为其他域有时候会变
	lu_check_info <= lu_mem_info

	// sc_cache_core
	lu_mem_info <= access_info

	// system_cache.vhdl
	sc_cache_core.access_info <= sc_frontend.access_info

	// sc_frontend.vhdl
	sc_frontend.access_info <= sc_access.access_info

	// sc_access.vhdl
	access_info.Allocate <= access_info_i.Allocate and not access_evict_1st_cycle
	access_info_i.Allocate <= arb_access.Allocate and not arb_access.Evict  // NO COHERENCE

	// sc_frontend
	arb_access from sc_arbiter

	// sc_arbiter
	arb_access.Allocate <= rd_port_access(port_ready_num).Allocate

	// sc_frontend.vhdl
	rd_port_access => rd_port_access(i) by sc_s_axi_gen_interface

	// sc_s_axi_gen_interface.vhdl
	rd_port_access => rd_port_access by sc_s_axi_a_channel

	// sc_s_axi_a_channel
	rd_port_access.Allocate <= port_access_q.Allocate
	port_access_q.Allocate <= allocate_i
	allocate_i  <= '1' when C_S_AXI_FORCE_ALLOCATE    /= 0 else
	               '0' when C_S_AXI_PROHIBIT_ALLOCATE /= 0 else
	               S_AXI_ACACHE_q(sel(C_IS_READ = 0, C_AWCACHE_WRITE_ALLOCATE_POS, C_ARCACHE_READ_ALLOCATE_POS));
	S_AXI_ACACHE_q <= S_AXI_ACACHE // [3:0]

	// system_cache_pkg.vhd
	C_ARCACHE_READ_ALLOCATE_POS = 2
	C_AWCACHE_WRITE_ALLOCATE_POS = 3

	// sc_s_axi_gen_interface
	S_AXI_ACACHE => S_AXI_AWCACHE
	S_AXI_ACACHE => S_AXI_ARCACHE

	// sc_front_end
	S_AXI_A[RW]CACHE => S\d\+_AXI_A[RW]CACHE

	// system_cache, xlnx_cache_pard
	S\d\+_AXI_A[RW]CACHE => S\d\+_AXI_A[RW]CACHE

说明不更新 tag 是因为 AXI4 流量不可缓存，考虑到插在 mig 前也不能缓存，估计是 rocket 搞的鬼（确实是它）。 实在不行可以搞强制缓存。

目前方案，LLC 放在 mig 前，强制缓存。

强制缓存后，第一个核心的启动时间是 15.32s, 第二个核心的启动时间是 14.33s 两个核心同时重启大概是由于互相替换，导致启动时间第一个 19.3s, 第二个 18.5s

注意，现在的 system cache 只有 32K 大小。

先用这个小的观察信号，然后再花一晚上综合各大的。不过从严重的互相干扰的情况来看，system cache 应该确实起作用了。

ILA 触发了，tag 更新了，不写 0 反而能快一点。

Tagged system cache 放在 migcp 前不会因为地址空间重叠导致干扰的，因为除了比较地址 tag 还要比较 dsid.

### UART

UART 一个通道只有一根线，它怎么区分 start bit, data bits 和 stop bit 呢？ 没法区分，只能期待有一个很长的 stop bit idle 序列，这样可以判断出 start bit. 或者让 stop bit 保持 1.5 个周期，这样也能区分出来。

### vhdl

vhdl 的 `entity` 只描述端口, `architecture` 基于端口进一步描述内部逻辑，所有的信号必须提前声明。要实例化的模块也要以 `component` 在信号声明处一并声明，并且要把端口再写一遍，之后实例化的时候，使用 `port map` 还要再写一遍端口名。

`process` 与 Verilog 中的 `always` 基本一致，用过程语句描述组合逻辑或时序逻辑。

## 2017-03-20

使用 512KB 的 system cache 后，riscv-linux 的启动时间由 14 多秒减少到 12.47s

动态链接程序放到 initramfs 里执行时，提示 not found. 这是因为没有找到对应的链接库。
使用 `readelf -a <proc>` 并搜索 `program interpreter` 来确认要使用哪个链接库。

http://stackoverflow.com/questions/31385121/elf-file-exists-in-usr-bin-but-turns-out-ash-file-not-found

http://stackoverflow.com/questions/36387516/size-constraints-of-initramfs-on-arm

http://stackoverflow.com/questions/8832114/what-does-init-mean-in-the-linux-kernel-code

将 specint 加入 initramfs 后，在解压 initramfs 时，出现 kernel panic, 提示信息 write error.所有相关的代码逻辑都在 `init/initramfs.c` 中。 在 `xwrite` 里，会调用 `sys_write`, 而 `sys_write` 在中途返回了负值的错误码，为 -28, 即 `ENOSPC`, no space left on device.

实际大小是 772_6291 B, 是写的地方空间不够了。每次写的 `fd` 对应的是 `initramfs.txt` 里描述的一个文件。 1152744 14828672 2653072 1246736 1818056 1086192 `__initramfs_size` 应该是压缩文件的大小。

就是通过 configstring 指定的物理内存太小了，导致无法写入。

## 2017-03-22

发现第二个核心跑各类 benchmark 会因为 SIGABRT 挂掉。重启后就没问题了！ 首次启动没有观察到 reset 干扰的情况（已经注意打开流量使能）。

## 2017-03-23

`MuxCase` 是里面只要 key 有效就选择，而 `MuxLookup` 则是用指定数据去匹配。

`riscv_pard_fpga` 最新的 `pard` 分支适配了 2016.2 版本的 petalnux, 如果之后要用这个分支，需要去 `pard_fpga_vc709_sw` 的 `2016.2` 分支下构建最新的 PetaLinux, 注意 DMA 宽度、Cache 和 IO cp 的 device tree 设定。

## 2017-03-24

接下来的工作是测试 cache 干扰和在 rocket 内部实现地址映射、令牌桶等 migcp 的功能， 为了能够读写 migcp, 需要暴露 IIC 接口给 PRM, 以及用于匹配的 ADDR.

ptab 的 `do_a`, `do_b` 表示的应该是 data output read, data output write.

另外为什么要有三条 I2C 线？双向传输两条就够了吧，而且 o 口基本是固定的。

## 2017-03-27

使用 rocket 里的 `AXI4Bundle` 进行 bulk connection 结果出现了 gender 不对的情况。 然后发现对于 diplomacy 具体何时决定方向一点头绪都没有。首先在 `AXI4Bundle` 的构造器里输出日志，发现确实没有被确定。 进一步日志输出发一直都是没确定的，应该不太可能。

总 bundle 那里已经确认方向了，但是子 bundle 里没有确定方向，估计是 `Irrevocable` 搞的鬼。

只能对 `Irrevocable` 用 `Flipped` 了，不能再指定方向，而且要猜对，不翻转是 master 视角的。

## 2017-03-29

`IDENT` 参数是用 64 位串表示的字符，这个数字不能够用 `BigInt` 来计算，因为即便 Scala 能计算，到了 Verilog 那里，已经变成没有宽度的十进制了，所以无法计算。 一个解决方法是使用 `RawParam`, 虽然没有文档说明，但是注释上说它是没有引号的 `StringParam`, 相当于可以传任意参数。 但是这个参数不能处理单引号，因为 firrtl 表示 `RawParam` 时，就是用单引号包含的。 不过可能是因为我的 chisel 版本有点过时导致的，因为相关的 issue 已经 close 了。

## 2017-03-30

改写了 migcp 顶层和 detect_logic 的代码，现在 prm 无法向 ptab 写入数据。

还是应该先看一下只替换了 migcp 顶层会不会导致一样的问题。

## 2017-03-31

测试了只重写了 migcp top level 的 bitstream, 发现同样不能写入参数表，说明问题一开始就存在了。

观察了一下，现在的代码有两处与原版有出入：

 1.  `IDENT` 的 `00` 使用的空格字符，即 `20`.
 2.  `TAG_A` 和 `TAG_B` 的读写语义搞反了。

尝试在生成的 Verilog 代码里，手工填入原版的 `IDENT` 值，但是没有效果。

考虑到 prm 能够识别出 migcp 的存在，并且 type 和 ident 能够正确传输出去，说明 i2c 和 register interface 是能够正常工作的。 那么问题很可能出在与 detect logic 的连线上。

经过观察，发现 detect logic 的 `COMM_DATA` 端口没有被连上。这样自然完成不了写入请求。 在 Vivado 的 Elaborating Design 阶段可以看到相关的警告. 旧版本的 chisel 是支持检查未连接的端口的。但是 chisel3 取消了相关的 API （现在非常寒碜地只有一个命令行选项）。 官方正在讨论解决方案，他们计划给端口增加 `isInvalid` 方法。 如果一个端口不被使用，必须显式地用这个方法声明。 不过这个功能还没有实装。总的讨论在[这里](https///github.com/ucb-bar/chisel3/issues/413)。

上面的讨论提到了一件事：Firrtl 可以检查端口有没有悬空，但是 chisel3 在生成 firrtl 代码时，显式地将所有端口标注为 invalid 的， 这样 firrtl 就不会检查悬空了。所以在 firrtl 代码里能看到 `io is invalid`.

连接 `COMM_DATA` 端口后，生成 bitstream 结束, 上板测试，现在可以成功写入 parameter table. 但是第二个核心不能正常启动，启动日志比较诡异。或者能够启动，但是会让第一个核心挂掉。猜测是内存空间出现了干扰。

观察生成的 Verilog 代码，发现 base 和 mask 都是 64 位的。不过感觉这不是很致命的问题。 对比了原来的代码，发现问题是这样的： `DO_A` 和 `DO_B` 都是 128 位的数据线，但是 `base` 和 `mask` 是从低 64 位里对半截取的， 而我则是直接在 128 位上对半截取，这样 `base` 能够拿到，但是 `mask` 是错误的数据。

虽然正确的 `base` 部分是不一样的，但是在软件里设定的 `base` 也是 `0x80000000`, 通过按位或运算，两个 base 就是一样的了。

关于 chisel 的注意事项：端口是电路实体，不能直接将一个 Reg 包裹个 Input/Output 作为端口。 否则只会绑定初始值。要用 `:=` 手工连线才行。

不知道 `Reg(Vec)` 和 `Mem` 有什么关系。

## 2017-04-01

正确性验证思路：可不可以将 chisel 生成的 verilog 和黑盒一起编译成仿真程序，与原来正确的模块一起对跑？ 只要看黑盒端口的信号值是不是一样的，就可以进行验证，但是覆盖面是个问题。

初步掌握了 Verilator 的使用方法。顶层的 C++ 入口的行为可以我们自己控制，但是顶层模块应该是一个仿真模块，用 `$finish` 来结束仿真。 整体流程和用 Vivado 进行仿真是没有区别的。

重写过 `MigPTab` 后，参数表可以被更新，但是地址空间隔离似乎又出问题了。

通过单元测试发现，只有第一个 entry 的 base 和 mask 是可以读出来的。

Chisel 的 Module 内不能用 `%b` 来格式化输出非布尔值！

内存空间映射失败的原因是我初始化 `dsid` 源头时的表达式是这样的：


	val dsids = Vec(Seq.tabulate(nEntries)(_.U(tagBits.W)))

当 `nEntries` 为 3 时，生成的 `dsid` 序列是 0, 1, 2. 而两个核心的 dsid 分别是 1 和 2. 然后问题来了，我在 PRM 里设置参数表的时候，使用的是行号而不是 dsid. 所以当我给第一行和第二行配置内存映射参数时，实际上两个核心取得的参数是

row 0: dsid = 0, base = 0x00000000, mask = 0x80000000 row 1: dsid = 1, base = 0x80000000, mask = 0x80000000 row 2: dsid = 2, base = 0x00000000, maks = 0x00000000

core0: dsid = 1, base = 0x80000000, mask = 0x80000000 core1: dsid = 2, base = 0x00000000, mask = 0x00000000

core0 和 core1 机器所看到的虚拟地址都是 0x80000000 开始的。 但是 core0 的高位会被 mask 给抹掉，然后用 base 重新拉高，变回原样。 core1 取出的是全 0 的参数，对它的地址不会有影响，所以两个核心的地址空间就重合了！

在综合期间，为了优化服务器上的开发环境，我进行了如下配置：

 1.  安装 courier: 人性化 sbt 依赖安装过程
 2.  安装 ensime: Scala parser 后端
 3.  [安装 pip](https///pip.pypa.io/en/stable/installing/): 为了安装 ensime vim 插件所需要的 Python 库，由于没有 root 权限，所以使用 `--user` 安装
 4.  python -m pip.**main** install --user websocket-client sexpdata
 5.  安装 ensime vim 插件等（在 .vimrc 的 Vundle 配置区域里）：
    - `Plugin 'ensime/ensime-vim'`
    - `Plugin 'derekwyatt/vim-scala'` （已经有了，用来语法高亮）
    - `Plugin 'vim-syntastic/syntastic` （语法检查？）

## 2017-04-09

为了测试我们的代码是否能和官方较新的代码整合，我首先将 ucb 的 master 分支拖到本地的 ucb-master 上。 接着，回退到 update_official 所指示的那个最新 commit. 然后，用 `git submodule update` 更新依赖。 我们的 master 分支果然就是 ucb 的 master 分支。可以直接 merge. 在整合过程中遇到了困难：

 1.  引入 Device Table Tree, 如何支持？
 2.  很多模块换了名字或者架构，如何调整？

Rocket 是如何启动的？ 启动逻辑由 bootrom 控制。 就 PARD 现在的设计来说，每次通过 reset 启动后， rocket 会去 `0x80000000` 检查是不是有效的 BBL 镜像，就像检查 ELF 文件头那样。 如果是，则跳转执行，如果不是，则陷入死循环。 这个死循环无法靠自己跳出，只能是传输完镜像后进行重启。

官方代码经过重构，现在 ICache 和 DCache 都与 `HasTileLinkMasterPort` 的 `masterNode` 相连， 这个 `masterNode` 直接与外部向量，原来用 `l1backend` 做中转的办法行不通了， 现在要想加入控制势必会影响到多处。

考古：commit f2e438833c3023b31d30bc32616de2e9e5e5790f

tilelink2 Nodes: generalize a node into inner and outer halves. This lets us create nodes which **transform from one bus to another**

要想理解 `diplomacy` 里的东西，首先要理解什么是一个 node 的 inner side 和 outer side。 或许我不应该把 node 理解成一个总线端口，而是要把它理解成一个独立的个体？ 一个个体可以在 master 和 slave 间转换，它当 master 的时候，就考虑 node 的 outer side, 它当 slave 的时候，就考虑 node 的 inner side. 在 diplomacy 的语境里，I/O 表示的 Inner/Outer, 即 Slave/Master 属性。 而 Downward/Upward 则表示逻辑意义上的输入输出。

但是在 `NodeImp` 里，`bundleI` 和 `bundleO` 是相同的方向，如果将它们理解成 master 和 slave 端口， 那么就应该是不同的方向才对。在使用 `NodeImp` 的 `MixedNode` 的定义的最后，我发现了我所期望的答案：


	val flip = false // needed for blind nodes
	private def flipO(b: HeterogeneousBag[BO]) = if (flip) b.flip else b
	private def flipI(b: HeterogeneousBag[BI]) = if (flip) b      else b.flip
	/* ... */
	lazy val bundleOut = wireO(flipO(HeterogeneousBag(edgesOut.map(outer.bundleO(_)))))
	lazy val bundleIn  = wireI(flipI(HeterogeneousBag(edgesIn .map(inner.bundleI(_)))))

从这段代码可以看出，在最后生成原始的输入输出端口时， 通过 `flipO` 和 `flipI` 这两个函数，master 和 slave 端口的方向总是能保持镜像关系。 而且可以看出，默认情况下，端口束的默认方向总是设定为 slave 的视角。

## 2017-04-10

Downward 可以理解成主动通道，而 upward 则可以理解成被动通道。 Downward 路径都是由 master 身份的 node 发起通信， 而 upward 路径则都是由 slave 身份的 node 发起通信。

TLManager 是 slave, TLClient 是 master.

遇到问题：`ControlledCrossing` 无论怎么重写 `mapParamsD` 都会遇到无限递归调用导致栈溢出的错误。 原因是 `masterNode` 通过 `ControlledCrossing` 连接到了自身。

`:=*` 和 `:*=` 是 1 月份引入的一个比较重要的功能， 在 https://github.com/ucb-bar/rocket-chip/pull/536 里有详细的语义描述。


*  `A :=* B` 会在每次 `B := xxx` 时执行一次 `A := B`.

*  `A :*= B` 会在每次 `xxx := A` 时执行一次 `A := B`.

靠近 `=` 的一端起着 crossbar 的作用，这两个操作符相当于透明地将远处不明数量的节点直接挂载到 crossbar 上，不需要搞多级 crossbar. 一个 node 最多只能使用一次 `:=*` 或 `:*=` （二者择一）。

使用 `MixedAdapterNode`, 虽然通过了 chisel 编译，但是它又输出了没有定义的 wire 了。

考察官方代码里，有没有 `:=*` 或 `:*=` 级联使用的情况： 在 `AsyncRocketTile` 和 `RationalRocketTile` 里，就有级联使用的情况，而且也是使用 `MixedAdapterNode` 做中介的。 如果我级联使用不对的话，那么增加平凡的一层级联会出现什么状况：两个 `TLOutputNode` 连也会出现问题。

尝试 `RocketTile.masterNode :=* MixedAdapterNode(TLImp,TLImp)... :=* dcache / frontend` 失败。

或者说，一个 module 最好不要有内部中继的两个 node ? 一个 module 内部不能有节点只在 LazyModule 层连线，一定要暴露端口出去，否则会被意外删除？ 但是我以引用的形式代理 `MixedAdapterNode`, `bundleOut` 按理说应该暴露出去了才对？

原版的连线是这样的：上方为 master

 1.  TLClientNode # frontend, dcache, SourceNode(TLImp)(portParams)
 2.  TLOutputNode # RocketTile.masterNode, OutputNode(TLImp)
 3.  TLXXXSourceNode # XXXRocketTile.source.node, MixedAdapterNode(TLImp, TLAsyncImp)(dFn, uFn)
 4.  TLXXXOutputNode # XXXRocketTile.masterNode, OutputNode(TLAsyncImp)

如果在 2 和 3 之间增加 `MixedAdapterNode` 和 `TLOuptutNode`, 则 `Frontend` 和 `HellaCache` 那里会出现没有定义的 wire. 尝试在 `AsyncRocketTile` 里绑控制，感觉比较安全的样子。这个方案通过了编译。


	control.node :=* rocket.masterNode
	source.node :=* control.node
	masterNode :=* source.node

可以把 `control.node` 封装到 `RocketTile` 里面去。 无论怎样，将中介控制这部分逻辑放在 `RocketTile` 里实装的话，就会出现未定义 wire 的问题。 这两种方案乍一看之下只有控制逻辑实装的位置不同而已。感觉根本的原因在于 `masterNode` 被用来取过 `bundleOut`。 因为无论是我自己的中间节点还是其他的，与 `masterNode` 组合都会出现这样的问题，说明不是我的中间节点的问题。 `val master = masterNode.bundleOut` 虽然无用，但是它的连接逻辑是靠 `masterNode` 体现的。 出现这种未定义 wire 的情况一定是我没有想清楚模块的包含关系。

现在 `AsyncRocketTile` 的 `rocket` 引用泄露到 `ControlledCrossing` 中了。 换个思路，能出现在端口的一定是 `TLOutputNode`, `MixedAdapterNode` 是不能用的？ 再或者，是 `masterNodeIn` 是 `TLOutputNode` 但是没有体现 Output 语义的锅？

还是那个老问题，在 `Module` 之外，node 之间通过 `:=`, `:*=`, `:=*` 进行连接，在 `Module` 层面到底是怎么体现的呢？ node 整个类型体系是与 `Module` 无关的。

每个 `LazyModule` 实例化的时候，会把自己压入 `object LazyModule` 的 `stack`. 接着里面的各种 `BaseNode` 实例化的时候，从 `object LazyModule` 里取出所属的那个 `LazyModule`. 然后把自己压入那个 `LazyModule` 的 `nodes` 栈。

在我令 `val masterNode = controlledCrossing.node` 后， 在 `ControlledCrossing` 对应的 Firrtl 代码里本来应该是 `io.out` 的位置出现了对 `rocket` 的引用。 大概是因为 `HasTileLinkMasterPortBundle` 里有 `val master = masterNode.bundleOut`. 原本，`masterNode` 是属于 `RocketTile` 这个 `LazyModule` 的， 而 `controlledCrossing.node` 是属于 `ControlledCrossing` 这个 `LazyModule` 的。 但是我却把 `ControlledCrossing` 的 node 拿去当上层模块的端口，这样是不行的。

Node 们只是在描述关系，最后不在 io bundle 上有所体现的话，大概是没有任何作用的吧。

新的 top module 的端口名变了： `io_l2_frontend_bus_axi4_0_`

## 2017-04-11

整合后的 rocket 直接启动 riscv-linux 果然起不来。 表现是完成 CDMA 传输后并发送重置信号后，核心 1 没有任何反应。 猜测原因之一是我的 `bootrom.S` 写的有问题。

新环境的问题出现了，我现在无法编译 BBL 了。 工具链的目录结构发生了改变，然而如何使用最新的配置的记录找不到了。

检查了一下，感觉 enable 的连接确实传递过去了。 还有就是要看下 bootrom 的行为，但是怎么观察 PC 呢？

现在这个情况其实可以用仿真来观察下。

编译仿真器时，出现了编译错误。直接原因是 UART 的 `interrupts` 设置成 0 就没有输出参数了， `diplomacy` 里连线的时候 `require` 出错。而我看官方的 UART 实现里已经把 `interrupts` 设置成 1 了。 所以如法炮制。 之后出现了另一个错误，初始化 `DebugModuleConfig` 的时候，由于 `nComponents` 为 0 而 `require` 出错。 这是因为没有用 `WithNXXXCores(n)` 给 `PARDSimConfig` 指定核心数量导致的。 这算是代码更新过程中出现的不一致现象吧，可能以前 `NTiles` 是隐式指定为 1 的。

观察 rocket 里与 bootrom 有关的代码，发现它和 dtb 的关系是：

 | boot rom | device table binary |
 | -------- | ------------------- |

而在 boot rom 代码的最后就是 dtb 的符号定义，这样就能直接访问到了。

带了动态库的 bbl.bin 太大了，仿真器断言退出了。刚好现在工具链废了。 等等，我一直以为找不到库是编译器的原因，实际上应该是 initramfs 的问题！

通过仿真初步观察，感觉是 `corerst` 信号没有传过去？ 仿真 + 日志，发现只能按到 `PARDSimTop` 层的信号。 结果是 `PARDSimConfig` 忘记用 `AsyncRocketTile` 的配置了。 但是 `reset` 没有传到最后还是有些问题的？ 修正配置后，能看到 `rocketWires` 里有输出了，但是依然没有进一步传到核心内。 在 `AsyncRocketTile` 里，`rocket` 是它的子模块，按道理来说是继承 `reset` 信号的。 虽然同一个对象的 `wrapper` 能看到 `reset` 变化，但是在 `AsyncRocketTile` 里面就不行了！ 观察 Verilog 代码，发现要输出日志时，除了眼看 `reset` 的值，还与了一个 `_T_1152` 外面的 reset 信号都不是原生的，而是有特殊语义的。 大概是为了不在系统 reset 的时候输出日志吧 好吧，`reset` 确实是传达到了。

结果是我草率地修改 bootrom, 删掉了开头 padding 的字节，导致复位 PC 刚好指向了自旋跳转指令。 不对，为什么是写死地跳到 `0x10040` 这个奇怪的地址？看官方的链接脚本是故意这样的， 但是我们这边以前跑的是没按照这个来的。

修改成 `0x10000` 后跑旧的 bbl, 能进去，触发断言挂掉了。但是重新编译了 bbl 还有 emu 后， 无论用新的还是旧的都无法进入，DMA 也一直停不下来。

## 2017-04-12

使用 nohype-1.10 分支的 bbl 后，能够正常输出， 但是在 `csrw scounteren, -1` 这个操作上出现了非法指令异常（Illegal Instruction, exception code 2）。 按照 *riscv-privileged-v1.9.1* 的说法：

> Attemps to access a non-existent CSR rasie an illegal instruction exception. Attemps to access a CSR without appropriate privilege level or to write a readl-onlly register also raise illegal instruction exceptions.

考察 rocket chip 的代码后，发现 `scounteren` 是有的，而且地址也都是 `0x106`.

注释掉后，确实没有出现这个异常，然后在 `csrwi sptbr,0` 这个操作上出现了相同的问题。

不做任何修改地跑 `update_official2` 这个分支的仿真，会在一开始因为 D 通道的地址没有对齐而挂掉。 不知道为什么，在这个分支下构建仿真器非常地慢。 注释掉这个断言后，接下来的断言也会报错，D 通道的问题看起来很大。 难道是因为 dsid?

具体讨论放到 http://10.30.7.141/pard/riscv_pard_fpga/issues/54 了

看样子除了地址对齐的问题外，另一个主要的问题就是 source id 了。


	assert((a_set | inflight)(bundle.d.bits.source), "'D' channel acknowledged for nothing inflight" + extra)

这个 `WithNSmallCores(1)` 触发的断言的意思是，d channel 里发现的这个 source id 要么正在被 A 通道请求，要么在 D 里正在处理？

## 2017-04-13

如果在仿真里出错的话，感觉在 groundtest 里也有很大概率会出错。 Groundtest 的 MemtestConfig 没有问题，那么原因可能是出在 DMA 上面？ 如果 DMA 相关的模块是我们写的，那么很可能因为没有适配而出现问题。

Groundtest 里顶层有暴露 `mem_axi4`, 所以可以认为内部连接的节点都没有问题。 Groundtest 的 `TestHarness` 和 `PARDTestHarness` 对 `mem_axi4` 的使用方法是一样的， 并且都只有一个内存通道。

不过 DMA 是从外面往里面传数据，这个行为 groundtest 应该没有覆盖到，可能会有问题。

不过回头看出错路径连接是与 `mmio` 这个结点相关的，而它最终对外暴露 `mmio_axi4` 这个端口束。 似乎所有的测试里都没有连接它，于是它会被随机化？所以仿真时出错具有随机性？ 但是 groundtest 也没搞它，为什么就没问题？

`<del>`世界的扭曲点，发现了！`</del>`Groundtest 为什么不会挂？因为它根本没有生成 `mmio_axi4` 和 `l2_frontend_bus_axi4` 的端口！ 为什么我测试的 3 月 26 日的工程不会蹦？因为它也没有把 `mmio_axi4` 给悬空！

为什么 3 月 26 日的旧代码不会暴露 `mmio` 的端口，而最近的代码会暴露？ 原因在于定义 `mmio` 结点的 trait 混入的位置发生了变化，原来只有 `PARDFPGAConfig` 有，现在都有了。

## 2017-04-15

今天将晚上综合好的 bitstream 跑了一下。 出现了一个爆出 kernel trace 的错误，但是没有导致系统崩溃。 不过，第二个核心没有起来，复位信号不知道为什么给发到第二个核心上。

计划先检查编译出来的 Verilog 代码。 感觉 reset 并没有被混用。直到送进相同模块的不同实例为止都是分离的。

晚上又测试了一下，发现 hartid 变了，感觉是 uart 方面内存映射有问题。

## 2017-04-16

现有工程里，PRM 应该是利用 SFP 实现网络连接的。 跟踪 block design, 发现与 SFP 相关的一个关键的 IP 核： AXI 1G/2.5G Ethernet Subsystem.

SFP 分为 cage 和 module 两部分。Cage 即笼子，用来固定插入的 module. module 是可以拔插的长条状模块。

1000BASE-X 是 IEEE 802.3.z 标准规定的一组以太网物理层标准，主要面向光纤传输。 所以在 IP 手册里，SFP 总是和 1000BASE-X 相关联。

根据描述，interconnect ip core 用于内存映射的场景，crossbar 则没有相关描述。 interconnect 的地址是在 address editor 里编辑的，但是 crossbar 好像是在 ip 核设定里编辑的。 这种互联应该是先仲裁一个 master, 然后路由到对应的 slave 上？

## 2017-04-18

重构了 `uncore/pard` 下各个改写模块的传参数手段，复用 rocketchip 的 `Config` 包。

重写了 `DetectCommonLogic`. Vivado 说生成的几个 `reg` 信号没有被使用所以删掉了，但是测试下来感觉没有功能性的问题。

## 2017-04-19

`uart_inverter` 其实没什么用，也就是主设备的 'rx/tx' 对应的是从设备的 'tx/rx' 这样的相对转换而已。

观察发现 `RegisterInterface` 并没有和 I2C 模块高度耦合，所以准备先把这个改写了。
`RegisterInterface` 里存储了按字节编制的寄存器组，读写是按照 8 个一组一共 64 位进行的。
这也就是为什么 `IDENT` 要被拆成两段的原因了。
如何用 Chisel 的构件来优雅地实现这一组织形式，是个问题。
`RegisterInterface` 与 `DetectLogic` 交互时，都是使用的 64 位数据，
但是与 `I2C` 通信时，是按字节寻址的。
可以用函数封装与 `DetectLogic` 通信时的大范围写。

## 2017-04-20

上午继续完成 `RegisterInterface` 的改写。中午到下午一直在怼对标仿真。
Verilator 期望使用正常的 Verilog 代码进行仿真，而不是像 Vivado 那样写专门的仿真 Verilog 代码。
但是 `$random` 不支持位截取，写得相当难受。

Chisel 生成的 Verilog 代码里，有些测试变量不会被宏定义覆盖，导致未使用变量总是 warning, 很恼人。

之后一直综合不过，是因为模块重名了，旧 Verilog 代码引用我的新生成模块，综合不过去。
幸好综合不过去，主要是因为有 parameters 要设，不然上板子才发现就死翘翘了。

## 2017-04-21

要想理解网卡是怎么加入的，可以先观察 PRM 的地址映射关系，并将于网卡相关的映射和中断与 Device Tree 对照起来看。

发现控制平面可以进一步封装。首先 I2C 和 RegisterInterface 就可以封装起来，然后 DetectLogic 才是决定性质的关键。

重构了控制平面代码，通用的内容全部用基类处理。仅仅是为了求同存异，竟然都要把泛型、协变、named parameter 都用上……


## 2017-04-22

在 chisel3 里，`RegInit(Vec(...))` 必须显示地给每个元素指定初始值，即使用 `Seq` 构造初始化列表。
如果使用 `Vec(n, init.T)` 这种，则会报错，说在无法综合的节点上构造元器件。

## 2017-04-24

`RegInit` 会丢失宽度信息，要用 `Reg` 并手动写初始化逻辑。

`A.asTypeOf(B)` 似乎是比 `B.fromBits(A)` 更好的选择。

## 2017-04-25

完成了对标测试代码的生成脚本，用了 erb 才发现 stringtemplate4 里复用模板的概念很重要。
下面准备试试 liquid, 应该能提供更好的抽象，不像现在这样把小的渲染代码写在类里。

对跑 `CacheCalc` 果然出错了。
首先是 sel 的选择逻辑上有问题。
似乎改写后的模块比改写前算 `sel` 慢了一个周期。
原来的代码里，虽然 `sel` 是使用 `<=` 的，但是激励却是 `*`, 不知道这样会不会有什么问题。
为了避免 verilator 的警告崩溃，我给改成 `=` 了，然而改写的代码里却是用寄存器的，出错可以说是必然的。

保持原代码写法，关掉警告，似乎还是生成组合式代码了，也就是我的还是慢它一个周期。

这个讲义阻塞和非阻塞赋值介绍得比较好。时序逻辑用非阻塞赋值并不是什么特殊规定，只是基于这两种赋值行为产生的一种实践。
也即，阻塞与非阻塞与激励表的内容没有关系。

`CachePTab` 在 reset 时输出不一样挂掉了，这是因为我不想像原版那样在读写表的时候进行取反，这样会破坏我的封装。
所以我对输出进行取反。但是忘记考虑复位时的情况了。

改写统计表，在正常的输入上没有问题，但是两份代码对非法情况的处理有些不同。

## 2017-04-26

测试统计表，发现掩码全无效也能命中，好像是 system cache 必须分配一列的样子。姑且就这样吧。

今天写了 stab 的一部分，剩下的一个计算值没概念，明天再想。另外完善下 VerilogChecker, 让它不要对着数组报错，顺便提示下未使用的变量。

## 2017-04-27

Chisel 里，Reg 构造器返回的结果的宽度是不可知的，因为会根据写口的宽度进行推算。如果要明确宽度，用 RegInit 显示指定类型。

Vec 会构造一个组合选择电路做读口，再构造一个 always 块做写口。读口没用上就闲置了。

Trait 用 self-type 依赖了 Module 后，在 trait 里指定 io 的类型是不被识别的，依然用 Record.
这是要依赖 Module 的使用了需要的 io 类型的匿名子类。

策略模式的依赖注入方式，同 Scala 里传个参数的子类还要用泛型一样，大概是为了让父类使用这个对象的父类接口的同时，
子类能够看到这个对象的子类接口。
毕竟继承只是在代码复用，它只描述了成员的聚集增量以及替换了方法实现，它没办法让一个成员的类型发生变化。

统计表里是用户写入优先于统计写入，而触发表则是触发写入优先于用户写入。为了设计上的统一，我想让用户写入一直是优先的。
既然已经主观上想改变规则了，那么瞬时的旧事件也就不关心了吧。
不过触发事件的时序应该比较关键，而统计表最多也就是复位而已，怎么看都应该让用户更新逻辑靠后？

## 2017-05-22

TileLink2 的 E 通道是对外输出的。一个节点的 in 端口里的 E 通道的 bits 是输出端口。

通过日志发现，在拥有 4 个 tracker 的 TLBroadcast 里，in.e.bits 的大小是 4. 似乎存在着某种对应关系？
在 TLBroadcast 的构造过程中，managerFn 里将输入的 TLManagerPortParameters 里的 endSinkId 换成了 numTrackers.
TLBundleParameters 的 apply 方法接收的 TLManagerPortParameters 的 endSinkId 转换成自己的 sinkBits.

TLBundleParameters 的 apply 方法由 TLEdgeParameters, TLAsyncEdgeParameters 和 TLRationalEdgeParameters 三者调用。
不是一般性地，下面主要关注 TLEdgeParameters.

TLEdgeParameters 派生出 TLEdge, TLManagerParameters 也由 TLEdge 作为参数接收并传递给基类。
进而派生出 TLEdgeIn 和 TLEdgeOut. TLEdgeIn 和 TLEdgeOut 成为了 TLImp 的类型参数，与 Node 系建立了联系？？？

按照 tracker 里对 e_last 的用法，一旦发出对应 bit 的 E 通道消息，就会进入空闲（idle）状态。

## 2017-05-23

fsb 一路连到 l1tol2 上，而 l1tol2 通过 coherence manager 输出一个 coreplex 的 mem 节点。
这个 mem 连接到 CoreplexNetwork 的 mem 节点，之后转换成 AXI4 协议变成 mem_axi4.

从以上分析可以得出的结论是，DMA 请求通过前端总线传出到 l1tol2 这个 crossbar 后，通过一致性协议通知其他设备，
然后从 mem 口直接出来。

	:::scala
	// TLBroadcast
	val probe_todo = RegInit(UInt(0, width = max(1, caches.size)))
	val probe_next = probe_todo & ~(leftOR(probe_todo) << 1)
	when (in.b.fire()) { probe_todo := probe_todo & ~probe_next }


这里 probe_todo 就是所有挂载的缓存设备的 bit 向量。leftOR 从低到高，遇到第一个 1 后，后面的高位全部变成 1.
probe_next 的语义就是生成从低到高第一个 1 bit 的独热码，用来做索引吧。
probe_todo 的次态逻辑就是消除当前这个独热的 cache 目标。

TLBroadcastTracker 读取 TLBroadcast 提供的 B, C, D, E 通道的消息，中继 A 通道的消息。
它的具体行为是这样的：

 1.  初始状态：空闲，o_data 队列为空，TLBroadcast 输入请求和探测计数。
 2.  在空闲状态下看到新的请求，转为忙碌；请求消息存入 o_data 队列中。如果之后到来的消息是同一个请求的后继 beat, 则逐周期尽可能多地存入 o_data 队列中。否则等待 tracker 转为空闲状态。
 3.  每当 TLBroadcast 告诉 tracker 一个探测请求完成，tracker 将探测计数减一。探测计数为 0 表明探测完成。
 4.  探测完成后，o_data 队列开始流动，将一个请求以及可能的多拍转发出去。
 5.  当 TLBroadcast 告知 tracker 从设备的响应消息发送完毕后，tracker 变成空闲状态，重新回到初始状态。

一眼以概之，tracker 的作用就是卡着请求不让它发出去，等探测完成后再发。但是为什么要等到整个事物完成后才能空闲？

Acquire 消息的通信流程：


	M -- A: Acquire ------> S
	S -- D: Grant[Data] --> M
	M -- E: GrantAck -----> M


TLMessage 中 D 通道的 Grant 与 GrantData 的区别，我猜测可能前者只是修改授权，而后者则携带数据。

**ICache 是如何获取 DCache 中的脏数据的？**

如果 ICache 里面有脏数据，那么 DCache 请求数据块的时候，由于 ICache 不支持 probe, 所以不能对 DCache 的行为作出反应。

但是 ICache 有一个 invalidate 接口，在流水线的逻辑了，与 DCache 相关的是 s2_nack 可以让其被冲刷，不知道这是为什么？

## 2017-05-24

ICache 里只使用了 TileLink2 里 A 通道的 Get 请求。

观察 DCache 的行为，发现被 probe 的路是要被释放的。ClientMetadata 的 shrinkHelper 方法根据 probe 和当前状态决定具体的操作。

抓取 tracker 的日志，发现 DMA 阶段 A 通道请求的操作码是 1, 即 PutPartial, 根源是在 AXI4ToTL 的这段代码：

	:::scala
	w_out.bits := edgeOut.Put(in.aw.bits.id << 1, w_addr, w_size, in.w.bits.data, in.w.bits.strb)._2


观察 DMA 之后的日志。对 BootROM 的请求不会记录在这里，BootROM 中第一条访存请求是获取 0x80000000 处的 magic number.
在日志中，这个请求的来源编号是 36, 操作是 Acquire, 不探测其他设备（ICache 不支持探测）。
param 字段是权限变化编码，其值为 0, 应该是 NtoB.

之后来源编码为 38 的 ICache 的请求，操作是 Get, 权限变化也是 NtoB.
有唯一的一处 BtoT, 是写 0x80012040 这个地址，语义是 htif_console_buf, 不过我们并不用这个东西。

在 DCache 里，如果 cache line 的状态是 Dirty, 则返回 ProbeAckData, 并且降格到 Branch 状态。
（Dirty 和 Trunk 的区别是什么？）

在 TLBroadcast 中，每个 tracker 代理访存请求，同时还要有一个通路用来发送写回或释放用的访存请求。
这部分对应的代码是这样的：

	:::scala
	TLArbiter.lowestFromSeq(edgeOut, out.a, putfull +: trackers.map(_.out_a))


TileLink2 一致性协议的内容：

 1.  当一个 cache 获得了数据块的唯一拷贝时，其状态为 trunk.
    - 第一个缓存数据块
    - 第一个把数据块弄脏
 2.  别的 cache 请求数据块时，会嗅探其他 cache 请求降格为 branch.
 3.  多处拷贝但一致的数据块状态为 branch.
 4.  在 branch 状态下执行写操作，即便命中也算作 miss. Acquire 命令带 BtoT 权限变化标识。

这样的话，在不支持 probe 的情况下，如果 ICache 里没有指令，它可以从 DCache 里取得最新的数据。
但是若 ICache 里已经有旧指令，则虽然 DCache 里相应数据被改写时会向 coherence manager 发送消息，但是对应的 probe 消息不会送达 ICache 使其变成 Nothing.

通过 probe 返回或替换写回的数据在 TLBroadcast 中占据专门的一个通道，并构造成写请求，与 tracker 并列，通过仲裁决定谁的请求先送出。

由于非一致的数据块都是直接写回次级存储的，所以 nohype 场景下不会出现一个 LDom 的数据块被转发给另一个 LDom 的情况。

DMA 传输时会给两个 LDom 的 DCache 发无效数据块的 probe. 如果 DMA 超时，那么很可能是 tracker 将 DMA 劫持过久了。
tracker 劫持过久的原因是 probe 通信没有完成。probe 通信没有完成的原因是什么？

感觉需要把 TLBroadcast 里的握手信号抓出来看一下？

## 2017-07-01

开发环境的系统更换成了 debian 9.0，更新后项目的 pard 分支无法编译仿真代码（1），并且 hexdump 无法以 8 个字节为单位进行分组打印（2）。

着手处理（1），最好先拉一份全新的代码。部分仿真的修改被直接提交到上游的 master 了，要将上游 master 和 pard 分支合并才行。

下一个目标是，仿真两个核心，实例化两个 UART 外设，并让它们输出到不同的文件（就像 PARD 实机运行那样），然后考虑将地址映射移入 L1 端。

向 FIRRTL 传入 `--repl-seq-mem` 参数，可以将 sequential memory 转换成 conf 文件，这些 conf 文件可以用 vsim/vlsi_mem_gen 转换成 sram 的 verilog 文件。但是目前该配置只在生成综合代码的 target 下采用，需要仿照 vsim/Makefrag-verilog 来修改 emulator/Makefrag-verilator 使得仿真代码也可以使用这个配置。

通过获得 sram 的 verilog 文件，我们可以将 payload 通过 `$readmem` 直接初始化，而不需要通过模拟 DMA 来缓慢地传输。

Makefile 的自动变量 `$<` 表示第一个依赖。需要注意的是如果依赖列表的第一个元素是 archive（比如 `$(verilog)` 这样），那么 `$<` 表示的是 archive 展开后的第一个元素，而不是 archive 全体！

## 2017-07-02

今天用 `$readmemh` 替换了 sram 的随机初始化代码，在移除 DMA 模块后，可以借助仿真器的接口快速地载入载荷了，bin.txt 的格式也不需要变，仿真器的二进制也和载荷的内容解耦。修改脚本是用 Python 写的，感觉 Python 实在是别扭。那 `self` 真是让人觉得要 `class` 有何用，而且这些高级语言往往没有 enum 真是心烦（Python 3.4 有 enum 了）。

在写 makefile 时遇到了一些问题。有一个语句同时产生了两个目标文件，它们都被别的目标依赖。但是，下面的写法会重复执行：

	:::makefile
	A B: C; recipe


相当于

	:::makefile
	A: C; recipe
	B: C; recipe


但是如果目标列表里的是多个匹配模式的话，make 会认为这几个匹配是该 recipe 同时产生的：

	:::makefile
	%.c %.d: C; recipe


接下来的一个任务是将 emu 和上游的 master 分支合并到 pard 里。不过**现在仿真器启动是随机的，有时候会卡住不动**，不知道为什么。

正常情况下，PC 应该从 `0x0000010000` 启动进入 bootrom. 但是卡死时，则是从 `0x0000000800` 启动，陷入死循环。
搜索与 800 有关的代码，发现 CSR 寄存器部分有如下代码：

	:::scala
	val debugTVec = Mux(reg_debug, Mux(insn_break, UInt(0x800), UInt(0x808)), UInt(0x800))


通过日志发现，确实 `reg_debug` 有效了，导致初始 PC 变化。没有观察到 `TestHarness` 和 `PARDSimTop` 有随机连线的内容，**要从 `reg_debug` 开始逆向追踪一下。

在开启 `enableCommitLog` 时 Firrtl 会出现编译错误，提示 `wb_reg_pc` 不能与一个中间变量相连。

## 2017-07-03

光看 `reg_debug` 是不行的，它只是决定了使用何种 PC，而我们其实不希望使用这个 PC，所以先观察导致 PC 变化的原因。
0x800 这个 PC 值由 CSRFile 的 debugTVec 信号提供。从 0x800 开始运行时，相比正常启动已知如下差异：
CSRFile 里 reg_debug 有效；
Rocket 里 wb_xcpt 有效。

对 wb_xcpt 有效的原因进行追踪，发现 `wb_ctrl.mem` 和 `wb_reg_valid` 分别会在不同的周期内有效，与正常启动时不一致。但是决定性的是某个周期 `wb_reg_xcpt` 有效了。

排除了下，基本可以认为不是我引入的问题，merge 后也有这种现象。进一步的信号因果变化如下所示：


	mem_xcpt: 1, take_pc_wb: 0
	reg_debug: 0, insn_break: 0

	mem_xcpt: 1, take_pc_wb: 1
	reg_debug: 0, insn_break: 0

	mem_xcpt: 0, take_pc_wb: 0
	reg_debug: 1, insn_break: 0


进一步确认原因是 `mem_reg_xcpt_interrupt` 有效，`mem_reg_cause` 为 `0x800000000000000e`

进一步追踪可以看出这是从 id 段一路传下来的。

根据 0xe 即 14 判断，应该是 `bpu.io.debug_if` 有效了，其对应 cause 为 `CSR.debugTriggerCause`.

bpu 竟然是 `BreakPointUnit` 的缩写！

实际上不是 breakpoint 的问题，是 `csr.io.interrupt` 的问题。正常情况下，其 cause 为 `0x80000...`.

将问题锁定在 csr 的 `reg_mip` 没有完全初始化上，不过 `mip` 只是使用了 `reg_mip` 的一些变量，不知道实际影响如何。

## 2017-07-04

`TLDebugModule` 的子模块都无法输出日志，因为它们的 `reset` 信号是被其他信号接管了，也说明它们一直处于复位状态，按道理来说是不应该工作的，但是输出却是随机的！

最后的结论是 `TLDebugModule` 没有被时钟驱动！

## 2017-07-05

在 TileLink2 转 AXI4 之前做了地址映射，忘记加上 `ExtMem.base` 了，结果 monitor 报错，说 manager 不支持 Get 请求的类型。这里已经完成路由了，那么地址高位是什么时候去掉的呢？答案是 `SimAXIMem` 给 `AXI4RAM` 配置的地址空间是从 0 开始的，而 `AXI4RAM` 会用这个地址空间对输入地址进行掩码处理！

但是进入内核启动阶段，会依据 device tree 尽可能占据内存，这样按 device tree 的来划分会发生冲突。device tree 的内存大小应该是欺骗性质的。为此，首先在 `SimAXIMem` 里私自扩大内存大小。但是这样映射后，会比原地址范围大，沿途的 monitor 会断言干掉。

经过观察，`AdapterNode` 的 `clientFn` 是向 slave 传播的映射函数，`managerFn` 是向 master 传播的映射函数。

地址映射完工，最重要的是实际地址边界检查不是 AXI4RAM 做的，而是 mem_axi4 这个 node 配置的。

## 2017-07-08

char 是不是有符号的原来是平台相关的，以后一定记得要用 int8_t, uint8_t.

今晚的批处理任务：

 1.  用单核带日志的跑 coremark, 写一个日志 limiter 防止容量爆炸。
 2.  用双核不带日志的跑 microbench

## 2017-07-10

启动 Linux 时突然从一个 add 指令跳到了一个 wfi 指令。通过 log，显示来源是 `csr.io.evec` 确认是发生异常导致的。

那个死循环地址确实是 Linux 主动设置给 csr 的。现在需要判断发生了什么异常？

（已被 yzh 解决，是 Linux 地址越界的问题）

## 2017-07-13

TileLink2 里，A 通道的 acquire 请求用来提权，get 请求用来获取数据。在 DCache 中，如果是已经缓存的，那么首先发送 acquire, 之后再看是 get 还是 put.

如以前所说的，如果 block 是 branch 状态，相当于一个 miss, 要提权（XtoT）。

## 2017-07-14

Nohype 下一致性协议带来的问题是 A 有脏块，B 写这个块，A 的脏块会不会丢失？

	:::scala
	(wanted, am now)  -> (hasDirtyData resp, next)
	Cat(toN, Dirty)   -> (Bool(true),  TtoN, Nothing)


当前的代码，无论被 probe 的是否是脏数据，probe 响应自身都不携带数据。
但是 probe 到脏数据才会使能 inWriteBack 从而写回。

## 2017-07-17

yzh 展示了目录式一致性协议在 no-hype 环境下存在的问题：一个核重置了，它存储在目录里的数据不会被重置，但是在广播环境下不存在这种问题。广播的问题是发出探测请求后，如果一个核被重置了，那么 tracker 就一直等不到请求的回复，导致卡死。

但是现在卡死是发生在启动中途，这时候不会出现请求和重置的竞争问题，那么是什么原因导致卡死呢？

要想烧连着另一台主机的开发板，需要那台主机启动 `hw_server` 而不是 `vivado`, 并且两边 vivado 的版本要一致。

实现了一致性协议隔离，性能有所提升。

## 2017-07-20

在一致性隔离的情况下，依然出现了同时启动卡死的现象。

在 LDom1 启动过程中，重启 LDom0，根据 ILA 的信息，LDom0 的 write back pc 固定在 `0x1000c` 的 bootrom 空间，而 LDom1 的 write back pc 则固定在 `0xff819ac860`。（正常启动也是这个现象，此时 `instr_valid` 无效，所以不能认真对待。但是之后 `instr_valid` 一直是无效的，这才是问题所在。）

令人惊讶的是，`0x1000c` 对应的指令是纯寄存器传输的 `li a1,111`。它的下一条指令是 `beq`，不太可能在 mem 段导致流水线阻塞。

在阻塞状态下重启 LDom0，发现 `instr_valid` 只在前两条指令上有效。重启 LDom1，也是一样的现象。

但是阻塞现象还是集中于访存行为，所以先尝试 L1 内部保持应用一致性，L2 直接 crossbar。

TODO: 实现随机 reset，在仿真中观察 tracker 在 reset 场景下有没有被释放。

重要：只重启一个核心也遇到了卡死现象，所以目前 tracker 不释放假说是闭环的。由于一个 tracker 负责一片地址，那么一个核干掉了自己，这片地址就废了，另一个核也别想跑。

## 2017-07-24

现在准备手动控制 debug module，又遇到了 A 通道 ID 重复的问题，和 yzh 提的这个 issue 应该也有点像（https://github.com/freechipsproject/rocket-chip/issues/505）。不过注释掉对应的断言后发现还有其他断言被触发，说是“'A' and 'D' concurrent, despite minlatency 4”，我调整代码让读请求只发出一次，就没有触发断言了。

至于为什么 `minLatency` 会是 4，代码里没有直接的赋值，应该是各个部件的 latency 累加得到的。

## 2017-07-28

让 dmcontrol 的 dmactive 为 1 后，通过 hartsel 和 haltreq 就可以让程序陷入 debug rom, 之后通过 resumereq 就可以让其恢复。修改 dpc，即可指定恢复的位置。

现在需要思考的是，如何在仿真环境下完成多次 dma 操作，需要通过一致性协议冲刷 cache。
