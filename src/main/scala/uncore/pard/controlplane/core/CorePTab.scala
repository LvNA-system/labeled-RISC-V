package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CorePTabIO(implicit val p: Parameters)
  extends PTabIO
  with HasCoreIO


class CorePTab(implicit p: Parameters) extends PTab(new CorePTabIO) {
  val dsids = makeField(0.U(p(TagBits).W))()
  val states = makeField(false.B)()
  io.dsid := dsids
  io.extReset := states
  io.table.data := makeRead(io.cmd.row, io.cmd.col)
}
