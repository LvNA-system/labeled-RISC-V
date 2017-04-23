package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CorePTabIO(implicit val p: Parameters)
  extends TableBundle
  with HasCoreIO


class CorePTab(implicit p: Parameters) extends PTab(new CorePTabIO) {
  val nRows = p(NEntries)

  val dsids = RegInit(Vec(Seq.fill(nRows)(0.U(p(TagBits).W))))
  val states = RegInit(Vec(Seq.fill(nRows)(false.B)))

  io.dsid := dsids
  io.extReset := states

  makeTable(dsids, states)
}
