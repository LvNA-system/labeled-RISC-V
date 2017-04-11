// See LICENSE.SiFive for license details.

package util

import Chisel._
import config._

class ILA extends BlackBox {
  val io = new Bundle {
    val clk = Clock(INPUT)
    val hartid = UInt(INPUT, 32)

    val csr_time = UInt(INPUT, 32)
    val pc = UInt(INPUT, 64)
    val instr_valid = Bool(INPUT)
    val instr = UInt(INPUT, 32)

    val rd_wen = Bool(INPUT)
    val rd_waddr = UInt(INPUT, 5)
    val rd_wdata = UInt(INPUT, 64)

    val rs_raddr = UInt(INPUT, 5)
    val rs_rdata = UInt(INPUT, 64)
    val rt_raddr = UInt(INPUT, 5)
    val rt_rdata = UInt(INPUT, 64)
  }
}
