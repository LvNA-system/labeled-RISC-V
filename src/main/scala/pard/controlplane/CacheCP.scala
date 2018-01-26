// See LICENSE for license details.

package pard.cp

import Chisel._
import uncore.agents.{NWays}
import cde.{Parameters}

class CachePartitionConfigIO(implicit val p: Parameters) extends ControlPlaneBundle {
  val nWays = Vec(p(NDsids), UInt(OUTPUT, width = cpDataSize))
  val dsidMaps = Vec(p(NDsids), Vec(p(NWays), UInt(OUTPUT, width = cpDataSize)))
  val dsidMasks = Vec(p(NDsids), UInt(OUTPUT, width = cpDataSize))
  override def cloneType = (new CachePartitionConfigIO).asInstanceOf[this.type]
}
