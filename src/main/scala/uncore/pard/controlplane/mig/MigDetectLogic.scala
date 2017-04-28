package uncore.pard

import chisel3._
import chisel3.util._

import config._


class MigDetectLogicIO(implicit p: Parameters) extends DetectLogicIO {
  private val nEntries = p(NEntries)
  val rTag = new TagBundle
  val wTag = new TagBundle
  val apm = new APMBundle
  val dsids = Output(Vec(nEntries, UInt(p(TagBits).W)))
  val l1enables = Output(Vec(nEntries, Bool()))
  val buckets = Output(Vec(nEntries, new BucketBundle))
}


class MigDetectLogic(implicit p: Parameters) extends DetectLogic(new MigDetectLogicIO) {

  val ptab = Module(new MigPTab)
  val stab = Module(new MigSTab)
  val ttab = Module(new TTab(2))

  // The source of static dsids!
  val dsids = Vec((1 to p(NEntries)).map(_.U(p(TagBits).W)))
  io.dsids := dsids

  // TODO Bundle this common interface

  // detect <> ptab
  common.io.ptab <> ptab.io.table
  common.io.cmd  <> ptab.io.cmd

  // detect <> stab
  common.io.stab <> stab.io.table
  common.io.cmd  <> stab.io.cmd    // read only

  // detect <> ttab
  common.io.ttab <> ttab.io.table
  common.io.cmd <> ttab.io.cmd

  // ptab <> outer
  io.l1enables := ptab.io.l1enables
  ptab.io.dsids := dsids
  io.rTag <> ptab.io.rTag
  io.wTag <> ptab.io.wTag
  io.buckets := ptab.io.buckets

  // stab <> outer
  stab.io.apm <> io.apm

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
