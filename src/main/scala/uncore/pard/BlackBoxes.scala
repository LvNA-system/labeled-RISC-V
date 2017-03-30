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
