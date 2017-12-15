# 对 `Config` 类的理解
`config` 模块的设计需求是：

 1.  通过 `Parameters(Key)` 获得 Key 所对应的数据；
 2.  通过 `++` 操作将多份配置合并。

`PartialParameters` 是执行搜索操作的最小单位。
只有它持有偏函数，如果没有找到需要的字段，则进一步去 `tail` 里寻找。

`View` 类只提供搜索语义，参数集合间的拓扑信息由其子类 `Parameters` 维护。
`Parameters` 类通过 `chain` 方法同时描述搜索和拓扑语义。`find` 成为了顶级的 `chain`.

偏函数本身是不能被合并的，所以只能通过链表将各个持有偏函数的 `PartialParameters` 链接起来。
这就是 `ChainParameters` 的作用。
任意两个 `Parameters` 类型的实例，都可以通过 `++` 操作变成一颗以 `ChainParameters` 为根的二叉树。

当 `chain` 操作执行到 `ChainParameters` 实例时，它有一个 `tail` 参数，用于自己以及子女都搜索失败时继续搜索。
那么，很自然地，先递归搜索左子女，然后递归搜索右子女，最后递归搜索 `tail`.
但是，作者希望左子女搜索完后自动搜索右子女，右子女搜索完后自动搜索 `tail`,
让 `ChainParameters` 执行一个函数调用后就当甩手掌柜。
此时自然不能直接把右子女直接当做左子女的 `tail`, 否则根节点自己的 `tail` 信息就丢失了。
而且传进去的 `tail` 是 `View` 实例，只提供搜索语义。
迭代语义是 `Parameters` 派生系的私货。
于是 `ChainView` 出现了。它将右节点和 `tail` 结合成一颗新树，先调用右节点的 `chain`,
让右节点把父节点的 `tail` 当做自己的 `tail`, 然后让自己成为左节点的 `tail`,
这样一切都自动串联了。

然后需要一个统一的容器抽象 `PartialParameters` 和 `ChainParameters`,
不过为什么要用一个新的类 `Config` 而不是直接用 `Parameters` 呢？
`Config` 以形同的类名，提供不同构造接口的方式使代码统一化。
不过感觉 `Parameters` 类自己也提供两种构造接口不就行了？

