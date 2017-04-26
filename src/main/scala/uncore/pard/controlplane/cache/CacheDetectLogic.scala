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
  val calc = Module(new CacheCalc)
  val ttab = Module(new TTab)

  val dsids = Vec((1 to p(NEntries)).map(_.U(p(TagBits).W)))

  // TODO Common parts!
  // detect <> ptab
  common.io.ptab <> ptab.io.table
  common.io.cmd <> ptab.io.cmd

  // detect <> stab
  common.io.stab <> stab.io.table
  common.io.cmd <> stab.io.cmd

  // detect <> ttab
  common.io.ttab <> ttab.io.table
  common.io.cmd <> ttab.io.cmd


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


  // TODO Copied from MigDetectLogic!
  // stab <> ttab
  ttab.io.trigger_rdata := stab.io.trigger_rdata
  stab.io.trigger_metric := ttab.io.trigger_metric

  // ttab <> outer
  ttab.io.fifo <> io.trigger_axis

  // Look up dsid
  val triggerDsidMatch = dsids.map{_ === ttab.io.trigger_dsid}
  val triggerRow = Mux1H(triggerDsidMatch, dsids.indices.map(_.U))
  val triggerDsidValid = triggerDsidMatch.map(_.asUInt).reduce(_ + _) === 1.U  // Naive one-hot check
  stab.io.trigger_row := triggerRow
  ttab.io.trigger_dsid_valid := triggerDsidValid
}
