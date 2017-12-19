* elaboration输出变量类型
```
def manOf[T: Manifest](t: T): Manifest[T] = manifest[T]
println(manOf(var))
```
