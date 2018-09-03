package freechips.rocketchip.util

import Chisel._

object CheckOneHot {
  def apply(in: Seq[Bool]): Unit = {
    val value = Vec(in).asUInt
    val length = in.length
    def bitMap[T <: Data](f: Int => T) = Vec((0 until length).map(f))
    val bitOneHot = bitMap((w: Int) => value === (1 << w).asUInt(length.W)).asUInt
    val oneHot = bitOneHot.orR
    val noneHot = value === 0.U
    assert(oneHot || noneHot)
  }
}

// a and b must be both hot or none hot
object bothHotOrNoneHot {
  def apply(a: Bool, b: Bool, str: String): Unit = {
    val cond = (a === b)
      assert(cond, str)
  }
}
