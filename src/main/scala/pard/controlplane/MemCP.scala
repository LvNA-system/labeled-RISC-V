// See LICENSE for license details.

package pard.cp

import Chisel._
import cde.{Parameters}

class TokenBucketConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val sizes = Vec(NDsids, UInt(OUTPUT, width = cpDataSize))
  val freqs = Vec(NDsids, UInt(OUTPUT, width = cpDataSize))
  val incs  = Vec(NDsids, UInt(OUTPUT, width = cpDataSize))
  override def cloneType = (new TokenBucketConfigIO).asInstanceOf[this.type]
}
