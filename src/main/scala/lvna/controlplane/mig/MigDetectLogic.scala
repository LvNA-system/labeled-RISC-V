package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._


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
  val dsids = Vec((1 to p(NEntries)).map(_.U(p(TagBits).W)))
  val ptab = createPTab(new MigPTab)
  val stab = createSTab(new MigSTab)
  val ttab = createTTab(2, stab, dsids)

  // The source of static dsids!
  io.dsids := dsids

  // TODO Bundle this common interface

  // detect <> ptab
  // ptab <> outer
  io.l1enables := ptab.io.l1enables
  ptab.io.dsids := dsids
  io.rTag <> ptab.io.rTag
  io.wTag <> ptab.io.wTag
  io.buckets := ptab.io.buckets

  // stab <> outer
  stab.io.apm <> io.apm
}
