// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import coreplex.RocketPlex
import diplomacy.{LazyModule, LazyMultiIOModuleImp}
import util._

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

  val tcrs = IO(Vec(p(coreplex.NTiles), new Bundle {
      val clock = Clock(INPUT)
        val reset = Bool(INPUT)
      }))
  val L1enable = IO(Vec(p(coreplex.NTiles), Bool()).asInput)
    val trafficGeneratorEnable = IO(Bool(INPUT))
    val ila = IO(Vec(p(coreplex.NTiles), new ILABundle()))

  outer.coreplex.module.io.tcrs.zipWithIndex.map { case (_tcr, i) =>
    _tcr.clock := tcrs(i).clock
    _tcr.reset := tcrs(i).reset
  }
  outer.coreplex.module.io.trafficEnables := L1enable
  outer.coreplex.module.io.trafficGeneratorEnable := trafficGeneratorEnable
  outer.coreplex.module.io.ila.zipWithIndex.foreach { case (_ila, i) =>
    ila(i) <> _ila
  }
}
