package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._


class MigSTabIO(implicit p: Parameters) extends STabIO {
  val apm = new APMBundle
}


class MigSTab(implicit p: Parameters) extends STab(new MigSTabIO) {
  val de_addr = Mux(io.apm.addr(10), 12.U, 0.U) + io.apm.addr(7, 4)
  val de_addr_valid =
    (io.apm.addr(31, 8) === "h02".U || io.apm.addr(31, 8) === "h06".U) && io.apm.addr(7, 6) =/= "b11".U && io.apm.addr(3, 0) === "b0000".U

  // Not common 2d accessing table but 1d array accessed by address.
  // Therefore we choose not to use the makeField, ... APIs.
  val apm_data = RegInit(Vec(Seq.fill(24)(0.U(32.W))))
  when(io.apm.valid && de_addr_valid) {
    apm_data(de_addr) := io.apm.data
  }

  val cp_addr = io.cmd.row * 6.U + io.cmd.col  // ???
  val cp_addr_valid = io.cmd.row < 4.U && io.cmd.col < 6.U
  io.table.data := Mux(cp_addr_valid, apm_data(cp_addr), 0.U)

  val trigger_addr = io.trigger_row * 6.U + io.trigger_metric  // ???
  val trigger_addr_valid = io.trigger_row < 4.U && io.trigger_metric < 6.U
  io.trigger_rdata := Mux(trigger_addr_valid, apm_data(trigger_addr), 0.U)
}
