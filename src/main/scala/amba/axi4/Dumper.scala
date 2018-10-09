// See LICENSE.SiFive for license details.

package freechips.rocketchip.amba.axi4

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._

class AXI4Dumper()(implicit p: Parameters) extends LazyModule
{
  val node = AXI4AdapterNode()

  lazy val module = new LazyModuleImp(this) {
    (node.in zip node.out) foreach { case ((in, edgeIn), (out, edgeOut)) =>
      out <> in
      when (in.ar.fire()) {
//        printf("dumper: ar[len] = %d [addr] = 0x%x\n", in.ar.bits.len, in.ar.bits.addr)
      }
    }
  }
}

object AXI4Dumper
{
  def apply()(implicit p: Parameters): AXI4Node =
  {
    val axi4dump = LazyModule(new AXI4Dumper())
    axi4dump.node
  }
}

