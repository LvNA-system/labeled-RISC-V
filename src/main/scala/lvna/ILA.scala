// See LICENSE.SiFive for license details.

package ila

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

class BoomCSRILABundle extends Bundle {
  val trigger = Bool(OUTPUT)
  val reg_mip = UInt(OUTPUT, 64)
  val csr_rw_cmd = UInt(OUTPUT, 3)
  val csr_rw_wdata = UInt(OUTPUT, 64)
  val wr_mip = Bool(OUTPUT)
  val reg_mbadaddr = UInt(OUTPUT, 64)
}

class FPGATraceBaseBundle(val commWidth: Int) extends Bundle {
  val traces = Vec(commWidth, new Bundle {
    val valid = Bool()
    val commPriv = UInt(OUTPUT, 2)
    val commPC = UInt(OUTPUT, 40)
    val commInst = UInt(OUTPUT, 32)

    val isFloat = Bool()
    val wbValueValid = Bool()
    val wbARFN = UInt(OUTPUT, 6)
    val wbValue = UInt(OUTPUT, 64)

  })
}

class FPGATraceExtraBundle extends Bundle { // For rocket's delayed wb
  val delayedWbValid = Bool()
  val wbARFN = UInt(OUTPUT, 6)
  val wbValue = UInt(OUTPUT, 64)
}
