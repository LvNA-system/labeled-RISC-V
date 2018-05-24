package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._

class Command(implicit p: Parameters) extends Bundle {
  val wdata = UInt(p(DataBits).W)
  val row = UInt(15.W)
  val col = UInt(15.W)
  val table_sel = UInt(2.W)
  val command = UInt(32.W)

  override def cloneType = (new Command).asInstanceOf[this.type]
}

/**
 * IO bundle to wrap exclusive ports for each table.
 */
class ExclusiveTableBundle(implicit p: Parameters) extends Bundle {
  val data = Input(UInt(p(DataBits).W))  // Data from table
  val sel  = Output(Bool())              // Table write enable

  override def cloneType = (new ExclusiveTableBundle).asInstanceOf[this.type]
}

/**
 * IO bundle to wrap common ports for tables.
 */
class CommonTableBundle(implicit p: Parameters) extends Bundle {
  val col = Output(UInt(15.W))
  val row = Output(UInt(15.W))
  val wdata = Output(UInt(p(DataBits).W))
  val wen = Output(Bool())

  override def cloneType = (new CommonTableBundle).asInstanceOf[this.type]
}

/**
 * IO bundle used by individual tables,
 * combining common ports and exclusive ports.
 */
class TableBundle(implicit p: Parameters) extends Bundle {
  val cmd   = Flipped(new CommonTableBundle)
  val table = Flipped(new ExclusiveTableBundle)
}

class RegisterInterfaceIO(implicit p: Parameters) extends Bundle {
  val COMM_VALID = Input(Bool())
  val COMM_DATA = Input(UInt(p(CmdBits).W))
  val DATA_VALID = Output(Bool())
  val DATA_RBACK = Output(UInt(p(DataBits).W))
  val DATA_MASK = Output(UInt(p(DataBits).W))
  val DATA_OFFSET = Output(UInt(2.W))

  override def cloneType = (new RegisterInterfaceIO).asInstanceOf[this.type]
}

class DetectLogicCommon(implicit p: Parameters) extends Module {
  private val CMD_READ = 0
  private val CMD_WRITE = 1

  val io = IO(new Bundle {
    val reg = new RegisterInterfaceIO
    // Table Interface
    val cmd = new CommonTableBundle
    val ptab = new ExclusiveTableBundle
    val stab = new ExclusiveTableBundle
    val ttab = new ExclusiveTableBundle
    // Helpers
    def tables = List(ptab, stab, ttab)
    def tables_en = tables.map(_.sel)
    def tables_data = tables.map(_.data)
  })

  val data_valid_flag = RegInit(false.B)
  val comm_data = RegInit(0.U(p(CmdBits).W))
  when (io.reg.COMM_VALID) {
    data_valid_flag := true.B
    comm_data := io.reg.COMM_DATA
  } .otherwise {
    data_valid_flag := false.B
  }

  val cmd = (new Command).fromBits(comm_data)
  val is_read_cmd = cmd.command(0) === CMD_READ.U
  val is_write_cmd = cmd.command(0) === CMD_WRITE.U

  val slave_wen = data_valid_flag && is_write_cmd
  val last_slave_wen = RegNext(slave_wen, true.B)
  io.cmd.col := cmd.col
  io.cmd.row := cmd.row
  io.cmd.wdata := cmd.wdata
  io.cmd.wen := !last_slave_wen && slave_wen

  io.tables_en.zipWithIndex.foreach { case (en, i) =>
    en := cmd.table_sel === i.U
  }

  io.reg.DATA_OFFSET := "b11".U
  io.reg.DATA_MASK := ~0.U(64.W)
  io.reg.DATA_VALID := data_valid_flag && is_read_cmd
  io.reg.DATA_RBACK := MuxLookup(cmd.table_sel, 0.U,
    io.tables_data.zipWithIndex.map { case (data, i) => i.U -> data })
}
