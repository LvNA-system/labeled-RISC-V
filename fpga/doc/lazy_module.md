# LazyModule简介

在阅读代码时，我们经常会遇到LazyModule，LazyModuleImp，Node等东西，非常得难懂。下面根据使用经验来简单介绍一下。

首先对比一下我们常用的module写法与LazyModule的写法。
这里的A、B是Module，LA、LB是LazyModule。

我们在写的时候，都是直接自己手动指定参数，然后硬件上模块的层次结构也是Module包住Module形成的instance结构来体现的。
DummyIO extends Bundle {
}

Dummy extends Module {
  val io = IO(new DummyIO(this))
  val a = Module(new A)
  val b = Module(new B)
}

而Rocket中最常见的模块层次结构是这样子的：
Dummy extends LazyModule {
  val la = LazyModule(new LA)
  val lb = LazyModule(new LB)
  val module = new DummyModule(this)
}

DummyBundle/DummyIO(outer: Dummy) extends Bundle {
}

DummyModule/DummyImp(outer: Dummy) extends LazyModuleImp {
  val io = IO(new DummyIO(this))
  val a = Module(new A)
  val b = Module(new B)
}

可以看到在rocket中模块层次变成了两层：LazyModule以及LazyModuleImp。并且硬件上的层次结构通过LazyModule及LazyModuleImp来体现出来。

LazyModule以及Node都是diplomacy文件夹下的东西，根据cook-diplomacy这篇文章的说法，这些都是用来支持two phase elaborate的。
所谓的two phase elaborate是指elaborate分为两个阶段:
第一阶段是参数的negotiation，各个node根据自己相邻的node的信息，来negotiate出node的一些参数，例如线宽。
第二阶段才是真正地把Module的架构映射到硬件架构，转成Firrtl。

如果我们大致的看一下LazyModule及LazyModuleImp的实现，就会发现LazyModule只是一个scala的虚基类，
而LazyModuleImp是从chisel的BaseModule派生出来的类。

因此我们可以这样理解：LazyModuleImp才是最终的硬件Module实现，LazyModule只是建构在其上的scala wrapper。
对应于two phase elaborate的概念，第一个阶段是运行LazyModule进行negotiation等任务，第二个阶段运行LazyModuleImp，真正地生成Firrtl。

结合代码，如果模块之间的连接涉及到negotiation（尤其是有node）时，则模块组织需要放在LazyModule中进行，如上面的la，lb。
如果模块组织不涉及到negotiation，则可以将子模块在LazyModuleImp中引入，如上面的a和b模块。

在rocket中在tile层次最常见的是模块的层次组织通过LazyModule来体现，而模块之间的连接等其他硬件逻辑则是在LazyModuleImp中来实现。
这主要是因为tile之间的通信都使用tilelink，而tilelink有许多参数，手动配置是比较繁琐的，需要进行negotiation，因此必须要有LazyModule这一层。

而到了core里面，并没有太多参数需要negotiation，因此就不需要使用LazyModule了，模块层次直接通过Module来组织即可。

知道了上面的这些，对我们修改rocket代码的启示是：

1. 如果模块参数需要negotiation，或者模块中的子模块需要negotiation（如各种Tilelink/node），则要实现成LazyModule + LazyModuleImp形式。例如AddressMapper。
如果模块不需要第一个negotiation的phase，则可以直接实现成Module的形式，例如TokenBucket.
2. 第一个phase是在第二个phase之前进行的，所以LazyModuleImp可以访问LazyModule中的变量，反之则不行，不然你会遇到XXX was used before LazyModule was called on XXX之类的错误。
3. LazyModuleImp其实就是硬件上的Module（准确地说是BaseModule），所以如果我们自己的Module不是Lazy的，直接加到LazyModuleImp中就行了。参考TokenBucket/RocketCore。
4. 如果需要extend Lazy模块，务必还使用LazyModule + LazyModueImp的形式。
