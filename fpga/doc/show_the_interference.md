# 重现多核下多进程性能干扰的过程：

启动好linux

1. 进入 `/root/redis` 目录，修改run-redis.sh 并执行，让server运行在核3上

        -./redis-server redis.conf
        +taskset 0x8 ./redis-server redis.conf

2. 进入 `/root/benchmark` 目录，执行下面的命令，将sort运行并绑定在0,1核：

        taskset 0x3 ./sort_multi data.txt mm 2 &

3. 打开top，等观察到0 1两核均高负载的时候 进入下一步
    
4. 回到 `/root/redis` 目录,执行下面的命令，将benchmark运行并绑定在2核：

        taskset 0x4 ./redis-benchmark -t set -n 10000
    
如果要观察无性能干扰时的状态，就略去步骤 2,3 

# 利用prm消除干扰的方法：

1. 将`csrc/fpga`目录传到板子上，编译好目录下面的程序

2. 在加载好linux内核之后，启动后打开`jtag`程序

3. 在上面步骤3，观察到高负载的时候，在`jtag`程序下输入以下2组命令：

        rw=w,cp=cache,tab=p,col=mask,row=0,val=0x1
        rw=w,cp=cache,tab=p,col=mask,row=1,val=0x1
        rw=w,cp=cache,tab=p,col=mask,row=2,val=0xfffe
        rw=w,cp=cache,tab=p,col=mask,row=3,val=0xfffe

    这组命令将cache中的1路划分给01两核，将剩下的15路划分给23两核
    
    可以在这个时候观察一下benchmark的运行结果，会发现干扰更加严重了
    
    这是因为调整了cache的waymask之后，sort会有更多的访存请求，会和redis在访存处的竞争更严重

        rw=w,cp=mem,tab=p,col=size,row=0,val=0x100
        rw=w,cp=mem,tab=p,col=size,row=1,val=0x100
        rw=w,cp=mem,tab=p,col=inc,row=0,val=0x4
        rw=w,cp=mem,tab=p,col=inc,row=1,val=0x4
        rw=w,cp=mem,tab=p,col=freq,row=0,val=0x80
        rw=w,cp=mem,tab=p,col=freq,row=1,val=0x80

    这组命令设置内存控制处令牌桶的相关的参数，控制0 1核的访存带宽

    其中`size`为令牌桶最大的容量，`inc`为每次增加令牌数，`freq`为添加令牌的间隔周期数，令牌以字节为单位
    
    这样将访存也控制下来，就能够看到redis的性能基本恢复到原来无干扰的水平

# redis-benchmark 的性能指标：

- 平均吞吐量：会在benchmark的最后直接输出

- 尾延迟：benchmark也会输出请求延迟的累积分布，可以取 95% 处和 99% 处的延迟来进行观测