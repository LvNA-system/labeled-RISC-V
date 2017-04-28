package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CacheDetectLogicIO(implicit p: Parameters) extends DetectLogicIO {
  val lookup = Input(new LookupBundle)
  val update_tag = Input(new UpdateTagRawBundle)
  val lru = Input(new LRUBundle)
  val waymask = Output(UInt(p(CacheAssoc).W))
}


class CacheDetectLogic(implicit p: Parameters) extends DetectLogic(new CacheDetectLogicIO) {
  val ptab = Module(new CachePTab)
  val stab = Module(new CacheSTab)
  val ttab = Module(new TTab(1))
  val calc = Module(new CacheCalc)
  val dsids = Vec((1 to p(NEntries)).map(_.U(p(TagBits).W)))

  bindPTab(ptab)
  bindSTab(stab)
  bindTTab(ttab)(stab, dsids)

  ptab.io.dsids := dsids
  ptab.io.lru := io.lru
  io.waymask := ptab.io.waymask

  stab.io.dsids := dsids
  stab.io.lookup := calc.io.to_stab.lookup

  stab.io.lookup                  := calc.io.to_stab.lookup
  stab.io.update_tag.enable       := calc.io.to_stab.update_tag.enable
  stab.io.update_tag.write_enable := calc.io.to_stab.update_tag.write_enable

  calc.io.from_outer.lookup                  := io.lookup
  calc.io.from_outer.update_tag.enable       := io.update_tag.enable
  calc.io.from_outer.update_tag.write_enable := io.update_tag.write_enable

  stab.io.update_tag.old_dsid  := calc.io.to_stab.update_tag.old_dsid
  stab.io.update_tag.new_dsid  := calc.io.to_stab.update_tag.new_dsid
  calc.io.from_outer.update_tag.old_dsids := io.update_tag.old_dsids
  calc.io.from_outer.update_tag.new_dsids := io.update_tag.new_dsids
}
