// See LICENSE.SiFive for license details.

package util

import Chisel._

class ILABundle extends Bundle {
  val hartid = UInt(OUTPUT, 2)

  val csr_time = UInt(OUTPUT, 32)
  val pc = UInt(OUTPUT, 40)
  val instr_valid = Bool(OUTPUT)
  val instr = UInt(OUTPUT, 32)

  val rd_wen = Bool(OUTPUT)
  val rd_waddr = UInt(OUTPUT, 5)
  val rd_wdata = UInt(OUTPUT, 64)

  val rs_raddr = UInt(OUTPUT, 5)
  val rs_rdata = UInt(OUTPUT, 64)
  val rt_raddr = UInt(OUTPUT, 5)
  val rt_rdata = UInt(OUTPUT, 64)
}
