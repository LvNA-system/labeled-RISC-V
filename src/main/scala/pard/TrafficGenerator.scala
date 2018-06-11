package pard

import Chisel._
import uncore.tilelink._
import cde.{Parameters, Field}
import rocketchip.ExtMemBase
import uncore.tilelink2.LFSRNoiseMaker

case object HasTrafficGenerator extends Field[Boolean]

class UncachedTileLinkTrafficGenerator(implicit p: Parameters) extends TLModule()(p) {
  val io = IO(new Bundle {
    val out = new ClientUncachedTileLinkIO
    val traffic_enable = Bool().asInput
  })

  io.out.acquire.valid := io.traffic_enable
  io.out.acquire.bits := GetBlock(addr_block = (UInt(p(ExtMemBase)) + LFSRNoiseMaker(28)) >> p(CacheBlockOffsetBits)) 
  io.out.grant.ready := Bool(true)
}

class TileLinkTrafficGenerator(implicit p: Parameters) extends TLModule()(p) {
  val io = IO(new Bundle {
    val out = new ClientTileLinkIO
    val traffic_enable = Bool().asInput
  })

  io.out.acquire.valid := io.traffic_enable
  io.out.acquire.bits := GetBlock(addr_block = (UInt(p(ExtMemBase)) + LFSRNoiseMaker(28)) >> p(CacheBlockOffsetBits)) 
  io.out.probe.ready := Bool(true)
  io.out.release.valid := Bool(false)
  io.out.grant.ready := Bool(true)

  val grantIsRefill = io.out.grant.bits.hasMultibeatData()
  val refillCycles = 8
  val (refillCount, refillDone) = Counter(io.out.grant.fire() && grantIsRefill, refillCycles)
  io.out.finish.valid := io.out.grant.fire() && io.out.grant.bits.requiresAck() && (!grantIsRefill || refillDone)
  io.out.finish.bits := io.out.grant.bits.makeFinish()

  assert(!io.out.probe.valid)
}
