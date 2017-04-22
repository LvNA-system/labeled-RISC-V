package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CorePTabIO(implicit val p: Parameters) extends Bundle
  with HasCoreIO {
  // PRM interface, TODO Abstract this common part
  val posBits = 15
  val table = Flipped(new TableIO)
  val col = Input(UInt(posBits.W))
  val row = Input(UInt(posBits.W))
  val wdata = Input(UInt(p(DataBits).W))
  val wen = Input(Bool())
}
  

class CorePTab(implicit p: Parameters) extends Module {
  val nRows = p(NEntries)

  val io = IO(new CorePTabIO)
  val dsids = RegInit(Vec(Seq.fill(nRows)(0.U(p(TagBits).W))))
  val states = RegInit(Vec(Seq.fill(nRows)(false.B)))

  val fields = List(dsids, states)

  io.dsid := dsids
  io.extReset := states

  // Write table, TODO Abstract this common procedure
  fields.zipWithIndex.foreach { case (field, c) =>
    when (io.table.enable && io.wen && io.col === c.U) {
      field(io.row) := io.wdata
    }
  }

  io.table.data := MuxLookup(io.col, 0.U, fields.indices.map(_.U) zip fields.map(_(io.row)))
}
