## PRM 软件

通过与DTM交互实现的功能都放在本目录下. 目录组织类似AM, 分3部分:
* `platform/` - 包括平台相关的代码, 如jtag访问方式, server初始化等工作. 目前平台包括`emu`和`fpga`, 其中`emu`用于仿真, `fpga`用于上板: 将本文件夹拷贝到arm核上编译, 将得到arm的可执行文件.
* `app/` - 平台无关的应用
* `common/` - 平台无关但可以被`app`共享的代码

## 编译

在`app/xxx`目录下运行`make`, 默认将程序编译到`emu`平台, 编译结果位于`app/xxx/build/xxx-emu`. 可以通过`make PLATFORM=fpga`将程序编译到`fpga`平台.
