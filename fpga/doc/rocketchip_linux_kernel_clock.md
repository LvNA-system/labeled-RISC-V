# RISCV-Linux中的时钟源的问题。

在linux kernel中时钟是叫时钟源（clock source）。现代的系统上，有很多不同的时钟源，他们性质，包括访问的latency，精确度各不相同，在内核中的作用也各不相同。在内核中，内核需要自己维护时间，这个时间当然是越精确越好，最好是直接从RTC读，但是由于从RTC读非常慢，所以内核只是在启动的时候，把自己的时间根据RTC校准，然后再根据timer interrupt来维护时间。

所以我们在看riscv-linux代码关于时间相关的问题时，也要考虑两个问题，wall clock是从哪里来的，timer interrupt又是怎么来的。

根据riscv-spec的定义，CSR中有mtime寄存器，是wall clock，但是具体的单位需要环境来指定。另外，有一些counter，可以设置成当mtime寄存器大于counter值时，触发时钟中断。在riscv-kernel中，获取wall clock是要通过rdtime指令来读取mtime寄存器，设置中断就是通过写入time counter。

但是在看rocketchip的代码时，我们会看到HasRTCModuleImp这个东西，会以为RTC是一个单独的定时设备，搞不清RTC和上述两种计时工具的关系。但实际上这个RTC仅仅是一个简单的计数器，负责驱动mtime寄存器的更新。

mtime以及counter都是CSR寄存器，但是他们不是在CSR模块中实现的，他们是在Clint中实现的，Clint可能是clock interrupt的缩写。

HasRTCModuleImp实例化了一个计数器，并连接到Clint中，驱动mtime的更新，compare counter以及raise timer interrupt是在Clint中完成的。

接下来还要考虑wall clock的单位的问题，wall clock的单位在rocketchip代码中是通过DTSTimebase来指定的，这个决定了RTC模块以多高的频率更新mtime。这个配置最终会进入DTB中，内核在启动时可以查询到这个参数。
