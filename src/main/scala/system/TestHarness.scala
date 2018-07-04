// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy.LazyModule

class TestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }

  val dut = Module(LazyModule(if (p(UseEmu)) new LvNAEmuTop else new LvNAFPGATop).module)
  dut.reset := reset | dut.debug.ndreset
  dut.corerst := dut.reset
  dut.coreclk := dut.clock

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  dut.connectSimAXIMem()
  dut.connectSimAXIMMIO()
  dut.l2_frontend_bus_axi4.foreach(_.tieoff)
  dut.connectDebug(clock, reset, io.success)
}
