package uncore.pard

import chisel3.core._
import scala.collection.immutable.Map
import scala.Predef.ArrowAssoc

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

class core_cp_detect_logic extends BlackBox {
  val io = IO(new Bundle {
    val SYS_CLK = Input(Clock())
    val RST = Input(UInt((1).W))
    val COMM_VALID = Input(UInt((1).W))
    val COMM_DATA = Input(UInt((0).W))
    val DATA_VALID = Output(UInt((1).W))
    val DATA_RBACK = Output(UInt((0).W))
    val DATA_MASK = Output(UInt((0).W))
    val DATA_OFFSET = Output(UInt((0).W))
    val EXT_RESET_IN_CORE0 = Output(UInt((1).W))
    val EXT_RESET_IN_CORE1 = Output(UInt((1).W))
    val EXT_RESET_IN_CORE2 = Output(UInt((1).W))
    val EXT_RESET_IN_CORE3 = Output(UInt((1).W))
    val DS_ID_CORE0 = Output(UInt((0).W))
    val DS_ID_CORE1 = Output(UInt((0).W))
    val DS_ID_CORE2 = Output(UInt((0).W))
    val DS_ID_CORE3 = Output(UInt((0).W))
    val trigger_axis_tready = Input(UInt((1).W))
    val trigger_axis_tvalid = Output(UInt((1).W))
    val trigger_axis_tdata = Output(UInt((0).W))
  })
}
