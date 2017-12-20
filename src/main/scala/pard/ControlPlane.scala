// See LICENSE for license details.

package rocketchip

import chisel3._

object ControlPlaneConsts {
  def cpAddrSize = 32
  def cpDataSize = 32

  def cpRead = Bool(true)
  def cpWrite = Bool(false)
}

class ControlPlaneIO extends Bundle {
  // read
  val ren = Input(Bool())
  val raddr = Input(UInt(width = ControlPlaneConsts.cpAddrSize))
  val rdata = Output(UInt(width = ControlPlaneConsts.cpDataSize))

  // write
  val wen = Input(Bool())
  val waddr = Input(UInt(width = ControlPlaneConsts.cpAddrSize))
  val wdata = Input(UInt(width = ControlPlaneConsts.cpDataSize))
}

class ControlPlaneModule extends Module {
  val io = IO(new ControlPlaneIO)
  // 128 32bit registers
  // register read/write should be single cycle
  val cpRegs = Reg(init = Vec.fill(128){UInt(0, width = 32)})
  when (io.ren) { io.rdata := cpRegs(io.raddr) }
  when (io.wen) { cpRegs(io.waddr) := io.wdata }
}
