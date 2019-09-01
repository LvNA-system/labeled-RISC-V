# 在rocketchip中启动debian

## 准备

* sidewinder-100开发板
* M.2协议的SSD (我们使用三星V-NAND SSD 970 EVO NVMe M.2 500GB)
* 支持M.2转USB的硬盘盒

注意: zcu102由于FPGA封装引脚不带PCIe的I/O, 因此不支持在PL实例化PCIe控制器, 故无法采用此方法(需要使用扩展卡)

## 硬件工程

此处直接给出rocketchip的连接方式, 可考虑先接入到Zynqmp走通流程, 再接入到rocketchip.

首先在block design中实例化IP核`DMA/Bridge Subsystem for PCI Express (PCIe)`.

### IP核配置

#### Basic选卡

* Functional Mode: AXI Bridge
* Mode: Advanced
* Device /Port Type: Root Port of PCI Express Root Complex
* PCIe Block Location: X0Y2 (见下文说明1)
* 勾选Enable GT Quad Selection -> GT Quad: GTY Quad 128 (见下文说明1)
* Lane Witdh: X1
* Maximum Link Speed: 8.0 GT/s
* Reference Clock Frequency (MHz): 100MHz
* Reset Source: Phy Ready
* GT DRP Clock Selection: Internal
* AXI Address WIdth: 40 (够用即可)
* AXI Data Width: 64 bit
* AXI Clock Frequency: 125
* 勾选Enable AXI Slave Interface
* 勾选Enable AXI Master Interface
* Data Protection: None
* 其它选项保持默认

#### PCIe ID选卡

* Base Class Value: 06 (见下文说明2)
* Sub Class Value: 04 (见下文说明2)
* 其它选项保持默认

#### PCIe: BARs选卡

* 勾选64 Bit (见下文说明3)
* Size: 64 (见下文说明4)
* Scale: Megabytes (见下文说明4)
* PCIe to AXI Translation: 0x100000000 (见下文说明5)
* 其它选项保持默认

#### PCIe: MISC选卡

* 勾选Enable MSI Capabilite Structure
* MSI RX PIN EN: TRUE (见[xilinx的回答](https://www.xilinx.com/support/answers/71106.html))
* 其它选项保持默认

#### AXI: BARs选卡

* AXI Bar0的AXI to PCIe Translation: 需要与block design的address editor设置一致, 见下文
* 其它选项保持默认

#### 其它选卡保持默认

#### 说明

1. 细节可参考[sidewinder文档](https://solutions.inrevium.com/products/pdf/SW100_003_UserGuide_1_0e.pdf)
  * 第24页`SFF AND PCIE HOST EXCLUSIVITY`小节, 我们使用Figure26中所示的J110插槽
  * 根据Figure27, 可得知需要选择GTY Quad 128和X0Y2等位置
2. 据说是查阅PCIe文档得知
3. 我们的rocketchip的物理内存在4GB以上, 需要64 Bit才能访问
4. 不能太小, 否则不够给设备分配地址空间
5. 我们的rockethcip的物理内存从0x100000000开始, 这里的设置需要一致

### 连接IP核

* `S_AXI_B`和`S_AXI_LITE`接入rocketchip的MMIO
  * `S_AXI_B` 是访问 PCIe 内部空间的接口，其在 rocketchip 中的地址映射应与 AXI BAR (Base Address Register) 里的设置保持一致
  * `S_AXI_LITE` 是访问 PCIe 控制器的接口，只需要在 rocketchip 内分配地址映射，选项卡中无需配置
* `M_AXI_B`接入rocketchip的L2 frontend bus
* `axi_aclk`, `axi_aresetn`和`axi_ctl_aresetn`是相应AXI通道的时钟和复位, 连接AXI通道时需要使用Interconnect或Clock Converter进行时钟域的转换
* `sys_clk`和`sys_clk_gt`: 实例化IP核`Utility Buffer`, 其C Buf Type选择IBUFDSGTE, 然后连接如下:
  * `buf.IBUF_OUT[0:0] <> xdma.sys_clk_gt`
  * `buf.IBUF_DS_ODIV2[0:0] <> xdma.sys_clk`
  * 为`buf.CLK_IN_D`创建Interface Pin, 连出block design, 并连到顶层
* `sys_rst_n`可连接`zynqmp.pl_resetn0`
* 为`pcie_mgt`创建Interface Pin, 连出block design即可, 无需连到顶层
* `interrupt_out`, `interrupt_out_msi_vec0to31`和`interrupt_out_msi_vec32to63`是中断信号, 接入到rocketchip的中断输入
  * 按上述顺序从低位到高位排列，命名对应下文 dts 中的 misc, msi0, msi1.

### 分配地址空间

* `S_AXI_B`:
  * Range 256MB足够, 必须大于xdma.`PCIe: BARs`选卡中的Size和Scale
  * Offset Address需要与xdma.`AXI: BARs`选卡中的AXI Bar0的AXI to PCIe Translation保持一致
* `S_AXI_LITE`:
  * Range 不小于512MB, 见[Xilinx的解决方案](https://www.xilinx.com/Attachment/Xilinx_Answer_70854_LFAR_PL_Bridge_RP_IP_Setup.pdf)
* `M_AXI_B`, 可分配全地址空间, 因为rocketchip内部会对地址范围进行检查
* **必要时需要扩大rocketchip.MMIO的地址空间**

### 添加约束

```
create_clock -period 10.000 -name pcie_x86_refclk -waveform {0.000 5.000} [get_ports CLK_IN_D_clk_p]
set_property PACKAGE_PIN AB35 [get_ports {CLK_IN_D_clk_n[0]}]
set_property PACKAGE_PIN AB34 [get_ports {CLK_IN_D_clk_p[0]}]
```

`pcie_mgt`的约束已经体现在上文GT Quad的选择中, 故无需额外添加约束

## 内核驱动

* 打开`CONFIG_PCIE_XDMA_PL`, 具体地
  * 在arm中, Bus support -> PCI controller drivers -> 选中`Xilinx XDMA PL PCIe host bridge support`
  * riscv默认不提供该选项, 因为上述IP的驱动没有进入内核主线, 目前只在linux-xlnx中维护, 需要把`linux-xlnx/drivers/pci/controller/pcie-xdma-pl.c`拷到riscv-linux中, 并修改相应的Makefile和Kconfig来编译它. [这里](https://github.com/LvNA-system/riscv-linux/pull/4)已经完成了这些移植工作
* Device Drivers -> NVME Support -> 选中`NVM Express block device`

## Device Tree

* 若接入Zynqmp, 可以通过SDK的工具生成正确的dts, 具体操作见[BOOT.BIN的准备流程中的dts生成部分](../boot/README.md)
* 若接入riscv, 则需要手动在dts中添加xdma的设备节点:
```
/ {
  amba_pl: amba_pl@0 {
    xdma_0: axi-pcie@70000000 {
        #address-cells = <3>;
        #interrupt-cells = <1>;
        #size-cells = <2>;
        clock-names = "sys_clk", "sys_clk_gt";
        clocks = <&misc_clk_0>, <&misc_clk_0>;
        compatible = "xlnx,xdma-host-3.00";
        device_type = "pci";
        interrupt-map = <0 0 0 1 &pcie_intc_0 1>, <0 0 0 2 &pcie_intc_0 2>, <0 0 0 3 &pcie_intc_0 3>, <0 0 0 4 &pcie_intc_0 4>;
        interrupt-map-mask = <0 0 0 7>;
        interrupt-names = "misc", "msi0", "msi1";
        interrupt-parent = <&L0>;
        interrupts = <3 4 5>;
        ranges = <0x03000000 0x00000000 0x70000000 0x0 0x70000000 0x00000000 0x10000000>;
        reg = <0x00000000 0x40000000 0x0 0x20000000>;
        pcie_intc_0: interrupt-controller {
            #address-cells = <0>;
            #interrupt-cells = <1>;
            interrupt-controller ;
        };
    };
  };
};
```

关键属性（即对应的硬件配置）的说明如下：

1. `interrupt-parent` 指向系统的 `interrupt-controller`，在 rocketchip 中其通常位于 `/soc/interrupt-controller` 且标签为 `L0`；
2. `interrupt-names` 和 `interrupts` 的设置表示 PCIe IP 核的中断信号 `interrupt_out`, `interrupt_out_msi_vec0to31`和`interrupt_out_msi_vec32to63`
分别对应 rocketchip 外部中断的第 3、4、5 位（从 1 开始）；
3. `ranges` 表示 rocketchip 的 `{0x0, 0x70000000}` 起始地址到 PCIe 的 `{0x00000000, 0x70000000}`，长度 `{0x00000000 0x10000000}`，`0x03000000` 表示 PCIe 相关配置。
所以 `S_AXI_B` 起始地址和 PCIe 选项卡的 AXI BAR 要设置成 `0x70000000`；
4. `reg` 表示控制器的地址空间，所以 `S_AXI_LITE` 起始地址要设置成 `0x40000000`。

可以根据实际硬件连接情况更改对应的关键参数。

节点属性的介绍可以参考[这里](https://elinux.org/Device_Tree_Usage#PCI_Address_Translation)

## 安装debian

通过硬盘盒将SSD接入x86主机, 对SSD进行分区和格式化, 并将debian安装到SSD中.

* 安装和改动需要qemu-riscv64-static, 建议在debian 10或ubuntu 19.04的系统(可尝试使用docker)中进行操作.
* 创建好分区后，将其挂在到任意目录，比如 /tmp/ssd
  * 一些步骤可以参考[BOOT.BIN的准备流程中的SD卡部分](../boot/README.md).
* 安装并执行 debootstrap 即可：
  * 参考[debian社区的安装指南](https://wiki.debian.org/RISC-V#debootstrap).

```
sudo apt-get install debootstrap qemu-user-static binfmt-support debian-ports-archive-keyring
sudo debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring unstable /tmp/ssd http://deb.debian.org/debian-ports
```

* 安装后, 通过chroot进入, 进行修改root密码, 更新fstab文件等操作, 具体可以参考[BOOT.BIN的准备流程中的SD卡部分](../boot/README.md).

## 插入SSD

将SSD插入sidewinder-100的J110插槽, 具体安装方式可查阅SSD的说明书

## PCI扫描日志

可参考[这里](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842034/ZynqMP+Linux+PL+PCIe+Root+Port#ZynqMPLinuxPLPCIeRootPort-KernelConsoleOutput)

启动后, 可以通过`cat /proc/iomem`查看pci和nvme的地址映射分配情况, 通过`cat /proc/interrupts`查看pci和nvme的中断情况

## 在rocketchip上启动debian

* 修改内核配置, 不使用initramfs:
  * General setup -> 去掉`Initial RAM filesystem and RAM disk (initramfs/initrd) support`
* 在dts中添加bootargs, 指示从nvme分区(根据实际情况修改)中挂载文件系统:
```
/ {
  chosen {
    bootargs = "root=/dev/nvme0n1p1 rootfstype=ext4 rootwait earlycon";
  };
};
```

重新编译内核和dtb, 若成功, 则可从SSD中启动debian, 约3分钟后可登录debian
