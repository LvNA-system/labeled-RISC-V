// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import config._
import junctions._
import diplomacy._
import coreplex._
import uncore.axi4._

class PARDFPGAHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }
  val dut = Module(LazyModule(new PARDFPGATop).module)

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

  // Make cores always runnable
  dut.L1enable.foreach(_ := Bool(true))
  dut.trafficGeneratorEnable := Bool(false)


  for (tcr <- dut.tcrs) {
    tcr.reset := reset
    tcr.clock := clock
  }

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
