// See LICENSE for license details.

package pard.cp

import Chisel._
import uncore.agents.{NWays}
import cde.{Parameters}

class CachePartitionConfigIO(implicit p: Parameters) extends ControlPlaneBundle {
  val nWays = Vec(NDsids, UInt(OUTPUT, width = cpDataSize))
  val dsidMaps = Vec(NDsids, Vec(p(NWays), UInt(OUTPUT, width = cpDataSize)))
  val dsidMasks = Vec(NDsids, UInt(OUTPUT, width = cpDataSize))
  override def cloneType = (new CachePartitionConfigIO).asInstanceOf[this.type]
}
