package freechips.rocketchip.util

import Chisel._

object GTimer {
  def apply(): UInt = {
    val (t, c) = Counter(Bool(true), 0x7fffffff)
    t
  }
}
