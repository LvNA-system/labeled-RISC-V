// See LICENSE.SiFive for license details.

package freechips.rocketchip.tilelink

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._

class TLDumper()(implicit p: Parameters) extends LazyModule
{
  val node = TLAdapterNode()

  lazy val module = new LazyModuleImp(this) {
    (node.in zip node.out) foreach { case ((in, edgeIn), (out, edgeOut)) =>
      out <> in
    }
  }
}

object TLDumper
{
  def apply()(implicit p: Parameters): TLNode =
  {
    val tldump = LazyModule(new TLDumper())
    tldump.node
  }
}

