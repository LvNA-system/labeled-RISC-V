package uncore.pard

import chisel3._
import chisel3.util._

import config._


class TTab(implicit p: Parameters) extends Module {
  val io = IO(new TableBundle {
    val trigger_dsid = Output(UInt(p(TagBits).W))
    val trigger_rdata = Input(UInt(p(DataBits).W))
    val trigger_metric = Output(Bool())  // FIXME
    val trigger_dsid_valid = Input(Bool())
    val fifo = new DecoupledIO(UInt(16.W))
  })

  val ttab = Module(new ttab(CP_ID = 1))
  // ttab <> outer
  ttab.io.SYS_CLK := clock
  ttab.io.DETECT_RST := reset
  ttab.io.fifo_wready := io.fifo.ready
  ttab.io.fifo_wvalid <> io.fifo.valid
  ttab.io.fifo_wdata <> io.fifo.bits
  ttab.io.trigger_dsid <> io.trigger_dsid
  ttab.io.trigger_dsid_valid <> io.trigger_dsid_valid
  ttab.io.trigger_metric <> io.trigger_metric
  ttab.io.trigger_rdata <> io.trigger_rdata
  ttab.io.col <> io.cmd.col
  ttab.io.row <> io.cmd.row
  ttab.io.is_this_table <> io.table.sel
  ttab.io.wdata <> io.cmd.wdata
  ttab.io.wen <> io.cmd.wen
  ttab.io.rdata <> io.table.data
}
