# PARD on FPGA

下面描述从chisel到上板运行的全流程。

## 编译



首先我们这里包含了三个目标对象：
vivado工程文件、由chisel生成的verilog、编译生成的bbl。
由于我们这里使用了Makefile调用tcl，tcl调用Makefile的方式，并没有正确地处理好make及clean时的依赖关系。导致在更新某一部分之后，无法正确地检查依赖，增量编译；clean时也无法正确clean。
直接生成三者使用如下命令：
```
make BOARD=zedboard
```

当某一部分发生变化之后，增量编译及单独清理一个目标，命令如下：

|目标对象|生成|清理方式|
|-----|-------|-----------------|
|vivado工程 | make BOARD=zedboard | make clean |
|bbl | make bbl -j32 | make sw-clean -j32 |
|generated verilog | make -C pardcore BOARD=zedboard| make -C pardcore BOARD=zedboard clean |

上述编译完成之后，得到的是一个vivado project以及bbl.bin文件。

接下来，我们打开vivado工程，单击refresh module。再单击generate bitstream。经过漫长的等待后，我们得到了bitstream文件system_top.bit。

## 运行

步骤太多，我都不知道该怎么分步了。

将板子开关打开，上电。

ssh上123服务器(10.30.6.123)
```
ssh liuzhigang@10.30.6.123
```

打开arm核的串口
```
minicom -D /dev/ttyACM0
```

烧板子及启动arm核
将刚编好的bitstream文件拷贝到123的pard目录下，拷贝时请这样用如下命令：
```
scp system_top.bit liuzhigang@10.30.6.123:~
```
注意:后面的":~"不能少，不然会拷贝到本机上。

运行xsdb
输入`source noop.tcl`。则arm核启动。

切换到arm的minicom窗口，窗口提示符为：zynq-uboot>
输入bootm 0x3000000 - 0x2a00000，则arm核开始启动Linux kernel。
如果莫名奇妙地挂住，请重新`source noop.tcl`。
若在启动时遇到错误"ARP Retry count exceeded"，请在 ZynqMP> 下输入命令： run netboot
此错误是因为网络原因，开发板不能正确获得IP地址所致，重启网络服务即可。

启动linux核之后，提示符为：`debian-airbook login:`，则说明成功启动linux。

用户名密码均为root，登录进去。

让zedboard上的linux获取ip地址
```
dhclient eth0
```

查看arm linux的ip地址
```
ifconfig
```

进入arm linux的pard目录下，从eda上将新编译的bbl.bin
scp过来（实际上是scp到了arm核用的sd卡上），将runme.sh更改，保证a.out后面跟的是刚传上去的bbl文件。

打开FPGA上rocket核的串口
在123服务器上，新开一个窗口，ssh到arm linux上，运行`minicom -D /dev/ttyUL1`。
如果显示locked，则用`ps aux | grep "minicom"`来看一下在运行的minicom进程，并杀死。

启动rocket核
切换到arm linux上，运行bash runme.sh，在minicom上即可看到riscv linux的输出。


重新烧板子时记得先把arm上的debian给poweroff，不要直接烧，直接运行bootm，因为arm上的debian需要正常关机以保证sd卡上的东西不会被写坏。

不用了，记得把zync给关机。
