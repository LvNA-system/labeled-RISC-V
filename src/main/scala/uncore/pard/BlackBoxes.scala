package uncore.pard

import chisel3.core._
import scala.collection.immutable.Map
import scala.Predef.ArrowAssoc

class mig_cp_detec_logic(C_ADDR_WIDTH: Int = 32, C_TAG_WIDTH: Int = 16, val C_DATA_WIDTH: Int = 128, C_BUCKET_SIZE_WIDTH: Int = 32, C_BUCKET_FREQ_WIDTH: Int = 32, C_NUM_ENTRIES: Int = 5) extends BlackBox(Map("C_ADDR_WIDTH" -> IntParam(C_ADDR_WIDTH), "C_TAG_WIDTH" -> IntParam(C_TAG_WIDTH), "C_DATA_WIDTH" -> IntParam(C_DATA_WIDTH), "C_BUCKET_SIZE_WIDTH" -> IntParam(C_BUCKET_SIZE_WIDTH), "C_BUCKET_FREQ_WIDTH" -> IntParam(C_BUCKET_FREQ_WIDTH), "C_NUM_ENTRIES" -> IntParam(C_NUM_ENTRIES))) {
  val io = IO(new Bundle {
    val SYS_CLK = Input(Clock())
    val DETECT_RST = Input(Bool())
    val COMM_VALID = Input(Bool())
    val COMM_DATA = Input(UInt((128).W))
    val DATA_VALID = Output(Bool())
    val DATA_RBACK = Output(UInt((64).W))
    val DATA_MASK = Output(UInt((64).W))
    val DATA_OFFSET = Output(UInt((2).W))
    val TAG_A = Input(UInt((C_TAG_WIDTH-1 + 1).W))
    val DO_A = Output(UInt((C_DATA_WIDTH-1 + 1).W))
    val TAG_MATCH_A = Output(Bool())
    val TAG_B = Input(UInt((C_TAG_WIDTH-1 + 1).W))
    val DO_B = Output(UInt((C_DATA_WIDTH-1 + 1).W))
    val TAG_MATCH_B = Output(Bool())
    val APM_DATA = Input(UInt((32).W))
    val APM_ADDR = Input(UInt((32).W))
    val APM_VALID = Input(Bool())
    val dsid_bundle = Output(UInt((C_TAG_WIDTH*C_NUM_ENTRIES-1 + 1).W))
    val L1enable = Output(UInt((C_NUM_ENTRIES-1 + 1).W))
    val bucket_size_bundle = Output(UInt((C_BUCKET_SIZE_WIDTH*C_NUM_ENTRIES-1 + 1).W))
    val bucket_freq_bundle = Output(UInt((C_BUCKET_FREQ_WIDTH*C_NUM_ENTRIES-1 + 1).W))
    val bucket_inc_bundle = Output(UInt((C_BUCKET_SIZE_WIDTH*C_NUM_ENTRIES-1 + 1).W))
    val trigger_axis_tready = Input(Bool())
    val trigger_axis_tvalid = Output(Bool())
    val trigger_axis_tdata = Output(UInt((16).W))
  })
}

class I2CInterface extends BlackBox {
  val io = IO(new Bundle {
    val RST = Input(Bool())
    val SYS_CLK = Input(Clock())
    val ADDR = Input(UInt((7).W))
    val SCL_ext_i = Input(Bool())
    val SCL_o = Output(Bool())
    val SCL_t = Output(Bool())
    val SDA_ext_i = Input(Bool())
    val SDA_o = Output(Bool())
    val SDA_t = Output(Bool())
    val STOP_DETECT_o = Output(Bool())
    val INDEX_POINTER_o = Output(UInt((8).W))
    val WRITE_ENABLE_o = Output(Bool())
    val RECEIVE_BUFFER = Output(UInt((8).W))
    val SEND_BUFFER = Input(UInt((8).W))
  })
}

class RegisterInterface(TYPE: Int, IDENT_LOW: String, IDENT_HIGH: String) extends BlackBox(Map("TYPE" -> IntParam(TYPE), "IDENT_LOW" -> StringParam(IDENT_LOW), "IDENT_HIGH" -> StringParam(IDENT_HIGH))) {
  val io = IO(new Bundle {
    val RST = Input(Bool())
    val SYS_CLK = Input(Clock())
    val SCL_i = Input(Bool())
    val STOP_DETECT = Input(Bool())
    val INDEX_POINTER = Input(UInt((8).W))
    val WRITE_ENABLE = Input(Bool())
    val RECEIVE_BUFFER = Input(UInt((8).W))
    val DATA_VALID = Input(Bool())
    val DATA_RBACK = Input(UInt((64).W))
    val DATA_MASK = Input(UInt((64).W))
    val DATA_OFFSET = Input(UInt((2).W))
    val COMM_VALID = Output(Bool())
    val COMM_DATA = Output(UInt((128).W))
    val SEND_BUFFER = Output(UInt((8).W))
  })
}

class token_bucket extends BlackBox {
  val io = IO(new Bundle {
    val aclk = Input(Clock())
    val aresetn = Input(Bool())
    val is_reading = Input(Bool())
    val is_writing = Input(Bool())
    val can_read = Input(Bool())
    val can_write = Input(Bool())
    val nr_rbyte = Input(UInt((32).W))
    val nr_wbyte = Input(UInt((32).W))
    val bucket_size = Input(UInt((32).W))
    val bucket_freq = Input(UInt((32).W))
    val bucket_inc = Input(UInt((32).W))
    val enable = Output(Bool())
  })
}

class detect_logic_common(val CMD_READ: BigInt = BigInt("0", 2), val CMD_WRITE: BigInt = BigInt("1", 2)) extends BlackBox(Map("CMD_READ" -> IntParam(CMD_READ), "CMD_WRITE" -> IntParam(CMD_WRITE))) {
  val io = IO(new Bundle {
    val SYS_CLK = Input(Clock())
    val DETECT_RST = Input(Bool())
    val COMM_VALID = Input(Bool())
    val COMM_DATA = Input(UInt((128).W))
    val parameter_table_rdata = Input(UInt((64).W))
    val statistic_table_rdata = Input(UInt((64).W))
    val trigger_table_rdata = Input(UInt((64).W))
    val DATA_VALID = Output(Bool())
    val DATA_RBACK = Output(UInt((64).W))
    val DATA_MASK = Output(UInt((64).W))
    val DATA_OFFSET = Output(UInt((2).W))
    val is_parameter_table = Output(Bool())
    val is_statistic_table = Output(Bool())
    val is_trigger_table = Output(Bool())
    val col = Output(UInt((15).W))
    val row = Output(UInt((15).W))
    val wdata = Output(UInt((64).W))
    val wen = Output(Bool())
  })
}

class mig_cp_ptab(val C_TAG_WIDTH: BigInt = BigInt("16", 10), val C_DATA_WIDTH: BigInt = BigInt("128", 10), val C_BASE_WIDTH: BigInt = BigInt("32", 10), val C_LENGTH_WIDTH: BigInt = BigInt("32", 10), val C_DSID_LENTH: BigInt = BigInt("64", 10), val C_BUCKET_SIZE_WIDTH: BigInt = BigInt("32", 10), val C_BUCKET_FREQ_WIDTH: BigInt = BigInt("32", 10), val C_NUM_ENTRIES: BigInt = BigInt("5", 10)) extends BlackBox(Map("C_TAG_WIDTH" -> IntParam(C_TAG_WIDTH), "C_DATA_WIDTH" -> IntParam(C_DATA_WIDTH), "C_BASE_WIDTH" -> IntParam(C_BASE_WIDTH), "C_LENGTH_WIDTH" -> IntParam(C_LENGTH_WIDTH), "C_DSID_LENTH" -> IntParam(C_DSID_LENTH), "C_BUCKET_SIZE_WIDTH" -> IntParam(C_BUCKET_SIZE_WIDTH), "C_BUCKET_FREQ_WIDTH" -> IntParam(C_BUCKET_FREQ_WIDTH), "C_NUM_ENTRIES" -> IntParam(C_NUM_ENTRIES))) {
  val io = IO(new Bundle {
    val aclk = Input(Clock())
    val areset = Input(Bool())
    val is_this_table = Input(Bool())
    val col = Input(UInt((15).W))
    val row = Input(UInt((15).W))
    val wdata = Input(UInt((64).W))
    val wen = Input(Bool())
    val rdata = Output(UInt((64).W))
    val DSID = Input(UInt((C_DSID_LENTH-1 + 1).toInt.W))
    val L1enable = Output(UInt((C_NUM_ENTRIES-1 + 1).toInt.W))
    val bucket_size_bundle = Output(UInt((C_NUM_ENTRIES*C_BUCKET_SIZE_WIDTH-1 + 1).toInt.W))
    val bucket_freq_bundle = Output(UInt((C_NUM_ENTRIES*C_BUCKET_FREQ_WIDTH-1 + 1).toInt.W))
    val bucket_inc_bundle = Output(UInt((C_NUM_ENTRIES*C_BUCKET_SIZE_WIDTH-1 + 1).toInt.W))
    val TAG_A = Input(UInt((C_TAG_WIDTH-1 + 1).toInt.W))
    val DO_A = Output(UInt((C_DATA_WIDTH-1 + 1).toInt.W))
    val TAG_MATCH_A = Output(Bool())
    val TAG_B = Input(UInt((C_TAG_WIDTH-1 + 1).toInt.W))
    val DO_B = Output(UInt((C_DATA_WIDTH-1 + 1).toInt.W))
    val TAG_MATCH_B = Output(Bool())
  })
}

class mig_cp_stab extends BlackBox {
  val io = IO(new Bundle {
    val aclk = Input(Clock())
    val areset = Input(Bool())
    val col = Input(UInt((15).W))
    val row = Input(UInt((15).W))
    val wdata = Input(UInt((32).W))
    val wen = Input(Bool())
    val is_this_table = Input(Bool())
    val rdata = Output(UInt((64).W))
    val trigger_row = Input(UInt((15).W))
    val trigger_metric = Input(UInt((3).W))
    val trigger_rdata = Output(UInt((32).W))
    val apm_axi_araddr = Input(UInt((32).W))
  })
}

class ttab(val CP_ID: BigInt = BigInt("0", 10), val NR_ENTRY_WIDTH: BigInt = BigInt("2", 10)) extends BlackBox(Map("CP_ID" -> IntParam(CP_ID), "NR_ENTRY_WIDTH" -> IntParam(NR_ENTRY_WIDTH))) {
  val io = IO(new Bundle {
    val SYS_CLK = Input(Clock())
    val DETECT_RST = Input(Bool())
    val is_this_table = Input(Bool())
    val col = Input(UInt((15).W))
    val row = Input(UInt((15).W))
    val wdata = Input(UInt((64).W))
    val wen = Input(Bool())
    val rdata = Output(UInt((64).W))
    val trigger_dsid = Output(UInt((16).W))
    val trigger_metric = Output(UInt((3).W))
    val trigger_rdata = Input(UInt((32).W))
    val trigger_dsid_valid = Input(Bool())
    val fifo_wready = Input(Bool())
    val fifo_wvalid = Output(Bool())
    val fifo_wdata = Output(UInt((16).W))
  })
}