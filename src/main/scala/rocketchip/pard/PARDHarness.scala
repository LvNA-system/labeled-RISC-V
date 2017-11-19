// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.coreplex._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.util.DontTouch

class PARDFPGAHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }
  val dut = Module(LazyModule(new PARDFPGATop).module)

  dut.dontTouchPorts()
  dut.connectDebug(clock, reset, io.success)
  dut.connectSimAXIMem()
  dut.connectSimAXIMMIO()
  dut.tieOffAXI4SlavePort()
}

class TestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
    val en = Bool(INPUT)
  }
  val dut = Module(LazyModule(new PARDSimTop).module)

  dut.connectDebug(clock, reset, io.success)

  for (tcr <- dut.tcrs) {
    tcr.reset := reset
    tcr.clock := clock
  }

  // Make cores always runnable
  dut.trafficGeneratorEnable := Bool(false)

  val mmio_axi4 = dut.mmio_axi4(0)
  mmio_axi4.r.valid := Bool(false)
  mmio_axi4.b.valid := Bool(false)
  mmio_axi4.ar.ready := Bool(true)
  mmio_axi4.aw.ready := Bool(true)
  mmio_axi4.w.ready := Bool(true)

  dut.tieOffInterrupts()
  dut.connectSimAXIMem()
  dut.tieOffAXI4SlavePort()
}
