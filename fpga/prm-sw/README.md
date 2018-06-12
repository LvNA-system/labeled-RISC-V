## PRM Software

```
.
├── app                  # platform-independent applications
│   ├── axi-loader       # loader to loader image and reset for the RISC-V subsystem
│   ├── dbg              # simple external debugger for RISC-V subsystem
│   ├── pardctl          # control plane access tools
│   ├── pardweb          # unused
│   ├── server           # unused
│   ├── stab             # control plane statistic table dumper
│   └── tgctl            # hardware traffic generator controller
├── common               # platform-independent codes shared by `app`
├── Makefile.app
├── Makefile.check
├── Makefile.compile
├── Makefile.lib
├── misc
│   ├── configstr        # configure string for RISC-V subsystem
│   ├── linux-config     # Linux config for PS of zynq and zynqmp
│   └── scripts
├── platform             # platform-dependent code
│   ├── platform-emu
│   └── platform-fpga
└── README.md            # this file
```

jtag硬件以上层次的软件都放在本目录下, 包括jtag驱动, DTM驱动, 控制平面访问等. 目录组织类似AM, 分3部分:
* `platform/` - 包括平台相关的代码, 如jtag访问方式, 平台初始化等工作.
目前平台包括`emu`和`fpga`, 其中`emu`用于仿真, `fpga`用于上板
* `app/` - 平台无关的应用
* `common/` - 平台无关但可以被`app`共享的代码

注意:
* 将本目录拷贝到ARM核上编译, 即可得到ARM上运行的可执行文件
* 关于DTM, jtag等模块的关系, 请查阅riscv debug specification

This directory contains functions above the jtag hardware,
including jtag driver, DTM driver, control plane accessing.
* `platform/` - platform-dependent code, including jtag accessing, platform initialization.
Currently, there are two platforms. `emu` is used for running over emulation, and `fpga` is used for running over FPGA
* `app/` - platform-independent applications
* `common/` - platform-independent codes shared by `app`

NOTE:
* Copying this directory to the ARM system and compile will get the ARM executables
* For details about the relationship between DTM and jtag, please refer to riscv debug specification

## Compile

在`app/xxx`目录下运行`make`, 默认将程序编译到`emu`平台, 编译结果位于`app/xxx/build/xxx-emu`. 可以通过`make PLATFORM=fpga`将程序编译到`fpga`平台.

Running `make` under `app/[app name]/` will compile the application to `emu` platform by default.
Executable will be generated as `app/[app name]/build/[app name]-emu`.
To compile the application to FPGA platform, run `make PLATFORM=fpga` under the application directory.
