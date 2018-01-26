// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters}

class TokenBucketConfigIO(implicit val p: Parameters) extends ControlPlaneBundle {
  val sizes = Vec(p(NDsids), UInt(OUTPUT, width = cpDataSize))
  val freqs = Vec(p(NDsids), UInt(OUTPUT, width = cpDataSize))
  val incs  = Vec(p(NDsids), UInt(OUTPUT, width = cpDataSize))
  override def cloneType = (new TokenBucketConfigIO).asInstanceOf[this.type]
}
