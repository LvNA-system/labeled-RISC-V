## 如何烧板子

1. 进入 `riscv_fpga_pard/fpga` 执行 `make vivado`
2. 在 Vivado 里按提示 refresh changed modules, 然后在左侧边栏下方点 *Generate Bistream*, 一路确认。
3. 完成后在左侧边栏下方点 *Open Hardware Manager*, 在新界面点 *Open target -> Open New Target*, 一路确认，选 Remote Server, 选个 FPGA 芯片（486、945）。
4. 在更新的界面里对着 FPGA 芯片（XADC 上面）右键点击 *Program Device*, 一路确认。

## 如何启动 PRM

```
ssh 10.30.6.123
minicom -D /dev/ttyUSB0  # 0, 1, ...
setenv kernel_img image-risc.ub && run netboot
```

1. 先登录对应的 uart 口（猜一个），然后在 Vivado 里 poogram bitstream。一 program 完就开始 5s 倒计时，不回车打断的话会从 flash 里加载旧镜像。
2. `netboot` 其实就是记录了一条命令的环境变量，`run` 命令以环境变量所存储的字符串为命令进行执行。
3. `netboot = tftp ${netstart} ${kernel_img} && fdt addr ${netstart} && fdt get addr dtbnetstart /images/fdt@1 data && fdt addr ${dt}`
4. `netstart = 0x84000000`
5. `dt =`
6. tftp 即 tftpboot, 通过 tftp 协议传输镜像并启动。
7. tftp 服务器在 10.30.6.123 的 `/tftpboot` 目录，这个目录所有用户都能够访问。
8. 其他 PRM 镜像：whz-image.ub, 加了 System Cache 和 MIGCP 参数表项的，不兼容。no-l2-image.ub, 没 System Cache 的，可兼容启动。
9. 用户名和密码都是 root

## 如何让 rocket-chip 运行 riscv-linux

在 PRM 上执行下面的命令：

```
wget 10.30.6.123/yzh/ksrisc
wget 10.30.6.123:8000/traffic.sh
sh traffic.sh 0 4096 1 4096
sh ksrisc 1
```

要与 rocket-chip 进行交互，在任意一台可以通过网络访问 PRM 的主机上执行下面的命令：

```
telnet 10.30.6.<prm> <rocket-port>
```

1. `<prm>` 是 PRM 对应的子网地址。对于 486, 它是 61; 对于 945, 它是 60.
2. `<rocket-port>` 是访问 uart 的端口号，对于 core0 它是 3000, 对于 core1 它是 3001.

## 如何修改 PRM 表项

TODO

## 如何编译 PRM

```
cd pard_fpga_vc709_sw/prm_core_bd/
petalinux-build
```

在已经有一次完整编译的情况下，若只想更新一部分，则

```
petalinux-build -c <your-package>
petalinux-build -x package
```
## 如何进行 Verilator 模拟

编译最好在 `bash` 环境下完成。

```
source ~/gcc.sh  # 获取最新版本的 GCC 以满足编译需求
cd riscv_pard_fpga/fpga
make emu -j32
cd emulator
sh gen.sh your-bbl  #=> bin.txt, bin.size
cp bin.txt bin.size ../build
cd build
./emu +verbose . 2>&1 | tee log
```

`emu` 使用 `bin.txt` 和 `bin.size` 作为负载模拟执行，重新编译 bbl 记得更新这两个文件。

## 如何进行 groundtest

```
PROJECT=groundtest SIM_CONFIG=Memtest make emu -j32
```

具体有哪些测试配置，请参考 `src/main/scala/groundtest/Configs.scala`.

