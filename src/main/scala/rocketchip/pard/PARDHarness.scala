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

  dut.interrupts := UInt(0)
  dut.debug.clockeddmi.get.dmi.req.valid := Bool(false)
  dut.debug.clockeddmi.get.dmi.resp.ready := Bool(true)

  // Make cores always runnable
  dut.L1enable.foreach(_ := io.en)
  dut.trafficGeneratorEnable := Bool(false)

  val channels = p(coreplex.BankedL2Config).nMemoryChannels
  if (channels > 0) Module(LazyModule(new SimAXIMem(channels)).module).io.axi4 <> dut.mem_axi4
    for (axi4 <- dut.mem_axi4) {
      when(axi4.ar.valid) {
  //      printf("axi4.ar.user = %x, axi4.ar.addr = %x\n", axi4.ar.bits.user, axi4.ar.bits.addr)
      }
      when(axi4.aw.valid) {
   //     printf("axi4.aw.user = %x, axi4.aw.addr = %x\n", axi4.aw.bits.user, axi4.aw.bits.addr)
      }
      // We can have traffic generator with different dsid here.
      // assert(!axi4.ar.valid || axi4.ar.bits.user === UInt(0x1, width = 16))
      // assert(!axi4.aw.valid || axi4.aw.bits.user === UInt(0x1, width = 16))
    }

  io.success := Bool(false)


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

  dut.tieOffAXI4SlavePort()
}
