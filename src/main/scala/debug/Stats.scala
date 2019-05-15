
package freechips.rocketchip.debug

import chisel3._
import chisel3.internal.naming.chiselName
import chisel3.util.experimental.BoringUtils

@chiselName
class Stats () {
  val counter = RegInit(0.U(48.W))
}

object Stats {
  @chiselName
  def apply(stat_name: String, hartId: Int): Stats = {
    val c = new freechips.rocketchip.debug.Stats()
    val dump_trigger = Wire(Bool())
    dump_trigger := false.B
    BoringUtils.addSink(dump_trigger, "DumpFlag" + hartId.toString)
    when (dump_trigger) {
      printf("Stats::")
      stat_name.foreach{c => printf(p"${Character(c.toInt.U)}")}
      printf(": %d\n", c.counter)
    }
    c
  }
}