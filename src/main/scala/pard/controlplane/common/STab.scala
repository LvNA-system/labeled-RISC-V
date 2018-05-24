package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._


/**
 * A STabIO must have some inputs to auto-update the table.
 */
abstract class STabIO(implicit p: Parameters) extends TableBundle {
  val trigger_row = Input(UInt(15.W))
  val trigger_metric = Input(UInt(p(TriggerMetricBits).W))
  val trigger_rdata = Output(UInt(p(TriggerRDataBits).W))
}


abstract class STab[+B <: STabIO](_io: => B)(implicit p: Parameters)
  extends Module with HasTable {
  val io = IO(_io)
  override val params = p
}
