// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import config._
import diplomacy._
import uncore.tilelink2._
import uncore.devices._
import util._
import coreplex._

trait MultiClockRocketPlexMaster extends L2Crossbar {
  val module: MultiClockRocketPlexMasterModule
  val mem: Seq[TLInwardNode]

  val coreplex = LazyModule(new MultiClockCoreplex)

  coreplex.l2in := l2.node
  socBus.node := coreplex.mmio
  coreplex.mmioInt := intBus.intnode
  mem.foreach { _ := coreplex.mem }
}

trait MultiClockRocketPlexMasterBundle extends L2CrossbarBundle {
  val outer: MultiClockRocketPlexMaster
}

trait MultiClockRocketPlexMasterModule extends L2CrossbarModule {
  val outer: MultiClockRocketPlexMaster
  val io: MultiClockRocketPlexMasterBundle
}
