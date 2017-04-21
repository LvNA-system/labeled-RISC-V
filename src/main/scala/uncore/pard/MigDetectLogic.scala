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
  val stab = Module(new mig_cp_stab)
  val ttab = Module(new ttab(CP_ID = 2))

  // The source of static dsids!
  val dsids = Vec((1 to p(NEntries)).map(_.U(p(TagBits).W)))
  io.dsids := dsids

  // TODO Bundle this common interface

  // detect <> ptab
  common.io.ptab <> ptab.io.table
  common.io.col <> ptab.io.col
  common.io.row <> ptab.io.row
  common.io.wdata <> ptab.io.wdata
  common.io.wen <> ptab.io.wen

  // detect <> stab
  common.io.stab.enable <> stab.io.is_this_table
  common.io.stab.data <> stab.io.rdata
  common.io.col <> stab.io.col
  common.io.row <> stab.io.row

  // detect <> ttab
  common.io.ttab.enable <> ttab.io.is_this_table
  common.io.ttab.data <> ttab.io.rdata
  common.io.col <> ttab.io.col
  common.io.row <> ttab.io.row
  common.io.wdata <> ttab.io.wdata
  common.io.wen <> ttab.io.wen

  // ptab <> outer
  io.l1enables := ptab.io.l1enables
  ptab.io.dsids := dsids
  io.rTag <> ptab.io.rTag
  io.wTag <> ptab.io.wTag
  io.buckets := ptab.io.buckets

  // stab <> outer
  stab.io.aclk := clock
  stab.io.areset := reset
  stab.io.wdata := io.apm.data
  stab.io.wen := io.apm.valid
  stab.io.apm_axi_araddr := io.apm.addr

  // stab <> ttab
  ttab.io.trigger_rdata := stab.io.trigger_rdata
  stab.io.trigger_metric := ttab.io.trigger_metric

  // ttab <> outer
  ttab.io.SYS_CLK := clock
  ttab.io.DETECT_RST := reset
  ttab.io.fifo_wready <> io.trigger_axis.ready
  ttab.io.fifo_wvalid <> io.trigger_axis.valid
  ttab.io.fifo_wdata <> io.trigger_axis.bits

  // Look up dsid
  val triggerDsidMatch = dsids.map{_ === ttab.io.trigger_dsid}
  val triggerRow = Mux1H(triggerDsidMatch, dsids.indices.map(_.U))
  val triggerDsidValid = triggerDsidMatch.map(_.asUInt).reduce(_ + _) === 1.U  // Naive one-hot check
  stab.io.trigger_row := triggerRow
  ttab.io.trigger_dsid_valid := triggerDsidValid
}
