// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import coreplex.RocketPlex
import diplomacy.{LazyModule, LazyMultiIOModuleImp}

/** Add a RocketPlex to the system */
trait HasRocketPlexMaster extends HasSystemNetworks with HasCoreplexRISCVPlatform {
  val module: HasRocketPlexMasterModuleImp

  val coreplex = LazyModule(new RocketPlex)

  coreplex.l2in :=* fsb.node
  bsb.node :*= coreplex.l2out
  socBus.node := coreplex.mmio
  coreplex.mmioInt := intBus.intnode

  require (mem.size == coreplex.mem.size)
  (mem zip coreplex.mem) foreach { case (xbar, channel) => xbar.node :=* channel }
}


trait HasRocketPlexMasterModuleImp extends LazyMultiIOModuleImp {
  val outer: HasRocketPlexMaster

  val io = IO(new Bundle {
    val tcrs = Vec(p(RocketTilesKey).size, new Bundle {
      val clock = Clock(INPUT)
      val reset = Bool(INPUT)
    })
    val L1enable = Vec(p(RocketTilesKey).size, Bool()).asInput
    val trafficGeneratorEnable = Bool(INPUT)
    val ila = Vec(p(RocketTilesKey).size, new ILABundle())
  })

  outer.coreplex.module.io.tcrs.zipWithIndex.map { case (tcr, i) =>
    tcr.clock := io.tcrs(i).clock
    tcr.reset := io.tcrs(i).reset
  }
  outer.coreplex.module.io.trafficEnables := io.L1enable
  outer.coreplex.module.io.trafficGeneratorEnable := io.trafficGeneratorEnable
  outer.coreplex.module.io.ila.zipWithIndex.foreach { case (ila, i) =>
    io.ila(i) <> ila
  }
}
