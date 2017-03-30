package uncore.pard

import chisel3.core._
import chisel3.util._

class BucketBundle(bucketSizeBits: Int, bucketFreqBits: Int) extends Bundle {
  val size = UInt(bucketSizeBits.W)
  val freq = UInt(bucketFreqBits.W)
  val inc = UInt(bucketSizeBits.W)

  override def cloneType = new BucketBundle(bucketSizeBits, bucketFreqBits).asInstanceOf[this.type]
}

/**
  * @param tagBits The bit width of tag (dsid).
  * @param dataBits The width of do_a and do_b.
  * @param nEntries The number of entries.
  * @param bucketSizeBits The bit width of bucket size and inc data.
  * @param bucketFreqBits The bit width of bucket update freq data.
  */
class MigDetectLogic(
                      val addrBits: Int = 32,
                      val tagBits: Int = 16,
                      val dataBits: Int = 128,
                      val nEntries: Int = 3,
                      val bucketSizeBits: Int = 32,
                      val bucketFreqBits: Int = 32
                    ) extends Module {
  val commDataBits = 128
  val rbackBits = 64

  val io = IO(new Bundle {
    val COMM_VALID = Input(Bool())  // TODO Bundle COMM
    val COMM_DATA = Input(UInt(commDataBits.W))
    val DATA_VALID = Output(Bool())
    val DATA_RBACK = Output(UInt(rbackBits.W))
    val DATA_MASK = Output(UInt(rbackBits.W))
    val DATA_OFFSET = Output(UInt(2.W))
    val TAG_A = Input(UInt(tagBits.W))  // TODO Bundle A and B
    val DO_A = Output(UInt(dataBits.W))
    val TAG_MATCH_A = Output(Bool())
    val TAG_B = Input(UInt(tagBits.W))
    val DO_B = Output(UInt(dataBits.W))
    val TAG_MATCH_B = Output(Bool())
    val APM_DATA = Input(UInt(32.W))  // TODO Bundle APM
    val APM_ADDR = Input(UInt(32.W))
    val APM_VALID = Input(Bool())
    val dsids = Output(Vec(Seq.tabulate(nEntries){ i => i.U(tagBits.W) }))
    val l1enables = Output(Vec(nEntries, Bool()))
    val buckets = Output(Vec(nEntries, new BucketBundle(bucketSizeBits, bucketFreqBits)))
    val trigger_axis_tready = Input(Bool())  // TODO Bundle this using ReadyValidIO
    val trigger_axis_tvalid = Output(Bool())
    val trigger_axis_tdata = Output(UInt(16.W))
  })

  val common = Module(new detect_logic_common())
  val ptab = Module(new mig_cp_ptab(
    C_BUCKET_SIZE_WIDTH = bucketSizeBits,
    C_BUCKET_FREQ_WIDTH = bucketFreqBits,
    C_TAG_WIDTH = tagBits,
    C_DATA_WIDTH = dataBits,
    C_NUM_ENTRIES = nEntries,
    C_DSID_LENTH = nEntries * tagBits
  ))
  val stab = Module(new mig_cp_stab)
  val ttab = Module(new ttab(CP_ID = 2))

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
  common.io.is_parameter_table <> ptab.io.is_this_table
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
  ptab.io.aclk := clock
  ptab.io.areset := reset
  for (i <- 0 until nEntries) {
    io.l1enables(i) := ptab.io.L1enable(i)
  }
  ptab.io.DSID := Cat(io.dsids.reverse)
  ptab.io.TAG_A := io.TAG_A
  io.DO_A := ptab.io.DO_A
  io.TAG_MATCH_A := ptab.io.TAG_MATCH_A
  ptab.io.TAG_B := io.TAG_B
  io.DO_B := ptab.io.DO_B
  io.TAG_MATCH_B := ptab.io.TAG_MATCH_B

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
  val triggerDsidMatch = io.dsids.map{_ === ttab.io.trigger_dsid}
  val triggerRow = Mux1H(triggerDsidMatch, io.dsids.indices.map(_.U))
  val triggerDsidValid = triggerDsidMatch.map(_.asUInt).reduce(_ + _) === 1.U  // Naive one-hot check
  stab.io.trigger_row := triggerRow
  ttab.io.trigger_dsid_valid := triggerDsidValid
}

object Detect extends App {
  chisel3.Driver.execute(args, () => new MigDetectLogic(32, 16, 128, 3, 32, 32))
}
