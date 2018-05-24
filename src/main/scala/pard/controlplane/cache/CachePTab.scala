package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._

class CachePTabIO(implicit p: Parameters) extends PTabIO {
  val dsids   = Input(Vec(p(NEntries), UInt(p(TagBits).W)))
  val lru     = Input(new LRUBundle)
  val waymask = Output(UInt(p(CacheAssoc).W))
}

class CachePTab(implicit p: Parameters) extends PTab(new CachePTabIO) {
  val waymasks = makeField((-1).S(p(CacheAssoc).W).asTypeOf(UInt(p(CacheAssoc).W)))()
  io.table.data := makeRead(io.cmd.row, io.cmd.col)

  // We consider that echo row has a distinguished dsid.
  val sel = io.dsids.map{dsid => io.lru.dsid_valid && (io.lru.dsid === dsid)}
  // If all matching failed, the last one will be returned.
  val waymask = RegInit((-1).S(p(CacheAssoc).W).asTypeOf(UInt(p(CacheAssoc).W)))
  when (io.lru.history_enable) {
    waymask := PriorityMux(sel, waymasks)
  }
  io.waymask := ~waymask
}
