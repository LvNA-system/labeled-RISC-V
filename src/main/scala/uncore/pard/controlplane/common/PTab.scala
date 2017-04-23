package uncore.pard

import chisel3._
import chisel3.util._

import config._


abstract class PTab[+TB <: TableBundle](_io: => TB) extends Module {
  val io = IO(_io)

  // Due to type system limitations, you should
  // explicitly call this method to assign fields
  // to instantiate table accessing functionality.
  def makeTable(fields: Vec[_ <: UInt]*) {
    // Write table
    fields.zipWithIndex.foreach { case (field, c) =>
      when (io.table.sel && io.cmd.wen && io.cmd.col === c.U) {
        field(io.cmd.row) := io.cmd.wdata
      }
    }

    // Read table
    io.table.data := MuxLookup(io.cmd.col, 0.U, fields.indices.map(_.U) zip fields.map(_(io.cmd.row)))
  }
}
