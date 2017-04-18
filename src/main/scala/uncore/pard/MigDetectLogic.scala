package uncore.pard

import chisel3._
import chisel3.util._

import config._

class BucketBundle(implicit p: Parameters) extends Bundle {
  val size = UInt(p(BucketBits).size.W)
  val freq = UInt(p(BucketBits).freq.W)
  val inc = UInt(p(BucketBits).size.W)

  override def cloneType = (new BucketBundle).asInstanceOf[this.type]
}

/** Only view the ReadyValidIO protocol */
class ReadyValidMonitor[+T <: Data](gen: T) extends Bundle {
  val valid = Input(Bool())
  val ready = Input(Bool())
  val bits  = Input(gen.cloneType)
}

/**
  * @param tagBits The bit width of tag (dsid).
  * @param nEntries The number of entries.
  */
class MigDetectLogic(val addrBits: Int = 32, val tagBits: Int = 16, val nEntries: Int = 3)(implicit p: Parameters) extends Module {
  val commDataBits = 128
  val rbackBits = 64

  val io = IO(new Bundle {
    val COMM_VALID = Input(Bool())  // TODO Bundle COMM
    val COMM_DATA = Input(UInt(commDataBits.W))
    val DATA_VALID = Output(Bool())
    val DATA_RBACK = Output(UInt(rbackBits.W))
    val DATA_MASK = Output(UInt(rbackBits.W))
    val DATA_OFFSET = Output(UInt(2.W))
    val rTag = new TagBundle(tagBits, addrBits)
    val wTag = new TagBundle(tagBits, addrBits)
    val APM_DATA = Input(UInt(32.W))  // TODO Bundle APM
    val APM_ADDR = Input(UInt(32.W))
    val APM_VALID = Input(Bool())
    val dsids = Output(Vec(nEntries, UInt(tagBits.W)))
    val l1enables = Output(Vec(nEntries, Bool()))
    val buckets = Output(Vec(nEntries, new BucketBundle))
    val trigger_axis_tready = Input(Bool())  // TODO Bundle this using ReadyValidIO
    val trigger_axis_tvalid = Output(Bool())
    val trigger_axis_tdata = Output(UInt(16.W))
  })

  val common = Module(new detect_logic_common())
  val ptab = Module(new MigPTab(nEntries, tagBits, addrBits))
  val stab = Module(new mig_cp_stab)
  val ttab = Module(new ttab(CP_ID = 2))

  // The source of static dsids!
  val dsids = Vec(Seq.tabulate(nEntries){ i => (i + 1).U(tagBits.W) })
  io.dsids := dsids

  // TODO Bundle this common interface

  // detect <> outer
  (common.io, io) match { case (s, m) =>
    s.SYS_CLK := clock
    s.DETECT_RST := reset
    s.COMM_DATA <> m.COMM_DATA
    s.COMM_VALID <> m.COMM_VALID
    s.DATA_VALID <> m.DATA_VALID
    s.DATA_RBACK <> m.DATA_RBACK
    s.DATA_MASK <> m.DATA_MASK
    s.DATA_OFFSET <> m.DATA_OFFSET
  }

  // TODO Bundle this common interface

  // detect <> ptab
  common.io.is_parameter_table <> ptab.io.isThisTable
  common.io.parameter_table_rdata <> ptab.io.rdata
  common.io.col <> ptab.io.col
  common.io.row <> ptab.io.row
  common.io.wdata <> ptab.io.wdata
  common.io.wen <> ptab.io.wen

  // detect <> stab
  common.io.is_statistic_table <> stab.io.is_this_table
  common.io.statistic_table_rdata <> stab.io.rdata
  common.io.col <> stab.io.col
  common.io.row <> stab.io.row

  // detect <> ttab
  common.io.is_trigger_table <> ttab.io.is_this_table
  common.io.trigger_table_rdata <> ttab.io.rdata
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
  stab.io.wdata := io.APM_DATA
  stab.io.wen := io.APM_VALID
  stab.io.apm_axi_araddr := io.APM_ADDR

  // stab <> ttab
  ttab.io.trigger_rdata := stab.io.trigger_rdata
  stab.io.trigger_metric := ttab.io.trigger_metric

  // ttab <> outer
  ttab.io.SYS_CLK := clock
  ttab.io.DETECT_RST := reset
  ttab.io.fifo_wready <> io.trigger_axis_tready
  ttab.io.fifo_wvalid <> io.trigger_axis_tvalid
  ttab.io.fifo_wdata <> io.trigger_axis_tdata

  // Look up dsid
  val triggerDsidMatch = dsids.map{_ === ttab.io.trigger_dsid}
  val triggerRow = Mux1H(triggerDsidMatch, dsids.indices.map(_.U))
  val triggerDsidValid = triggerDsidMatch.map(_.asUInt).reduce(_ + _) === 1.U  // Naive one-hot check
  stab.io.trigger_row := triggerRow
  ttab.io.trigger_dsid_valid := triggerDsidValid
}
