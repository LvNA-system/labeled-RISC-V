#重现多核下多进程性能干扰的过程：

启动好linux

1.进入 `/root/redis` 目录，修改run-redis.sh 并执行，让server运行在核3上

    -./redis-server redis.conf
    +taskset 0x8 ./redis-server redis.conf

2.进入 `/root/benchmark` 目录，执行下面的命令，将sort运行并绑定在0,1核：

    taskset 0x3 ./sort_multi data.txt mm 2 &

3.打开top，等观察到0 1两核均高负载的时候 进入下一步
    
4.回到 `/root/redis` 目录,执行下面的命令，将benchmark运行并绑定在2核：

    taskset 0x4 ./redis-benchmark -t set -l
    
如果要观察无性能干扰时的状态，就略去步骤 2,3 

