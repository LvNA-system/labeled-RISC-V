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
}

class TestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }
  val dut = Module(LazyModule(new PARDSimTop).module)

  for (int <- dut.io.interrupts(0))
    int := Bool(false)

  val channels = p(coreplex.BankedL2Config).nMemoryChannels
  if (channels > 0) Module(LazyModule(new SimAXIMem(channels)).module).io.axi4 <> dut.io.mem_axi4
    for (axi4 <- dut.io.mem_axi4) {
      when(axi4.ar.valid) {
  //      printf("axi4.ar.user = %x, axi4.ar.addr = %x\n", axi4.ar.bits.user, axi4.ar.bits.addr)
      }
      when(axi4.aw.valid) {
   //     printf("axi4.aw.user = %x, axi4.aw.addr = %x\n", axi4.aw.bits.user, axi4.aw.bits.addr)
      }
      assert(!axi4.ar.valid || axi4.ar.bits.user === UInt(0x1, width = 16))
      assert(!axi4.aw.valid || axi4.aw.bits.user === UInt(0x1, width = 16))
    }

  io.success := Bool(false)

  val dma = Module(new SimDMA)
  dma.io.clk := clock
  dma.io.reset := reset

  dut.io.coreclk := clock
  for (corerst <- dut.io.corerst) {
    corerst := reset || dma.io.intr
  }

  val l2_axi4 = dut.io.l2_axi4(0)
  l2_axi4.ar.valid := Bool(false)
  l2_axi4.r .ready := Bool(true)
  l2_axi4.b .ready := Bool(true)

  dma.io.axi_awready := l2_axi4.aw.ready
  l2_axi4.aw.valid := dma.io.axi_awvalid
  l2_axi4.aw.bits.id := UInt(0, width = 4)
  l2_axi4.aw.bits.addr := dma.io.axi_awaddr
  l2_axi4.aw.bits.len := UInt(0, width = 8)
  l2_axi4.aw.bits.size := UInt(3, width = 3)
  l2_axi4.aw.bits.burst := AXI4Parameters.BURST_INCR
  l2_axi4.aw.bits.lock := UInt(0, width = 1)
  l2_axi4.aw.bits.cache := UInt(0, width = 4)
  l2_axi4.aw.bits.prot := AXI4Parameters.PROT_PRIVILEDGED
  l2_axi4.aw.bits.qos := UInt(0, width = 4)
  l2_axi4.aw.bits.user := dma.io.axi_awuser

  dma.io.axi_wready := l2_axi4.w.ready
  l2_axi4.w .valid := dma.io.axi_wvalid
  l2_axi4.w .bits.data := dma.io.axi_wdata
  l2_axi4.w .bits.strb := UInt("h_ff", width = 8)
  l2_axi4.w .bits.last := Bool(true)
}

class SimDMA extends BlackBox {
  val io = new Bundle {
    val clk = Clock(INPUT)
    val reset = Bool(INPUT)
    val intr = Bool(OUTPUT)

    val axi_awready = Bool(INPUT)
    val axi_awvalid = Bool(OUTPUT)
    val axi_awaddr = UInt(OUTPUT, 32)
    val axi_awuser = UInt(OUTPUT, 16)

    val axi_wready = Bool(INPUT)
    val axi_wvalid = Bool(OUTPUT)
    val axi_wdata = UInt(OUTPUT, 64)
  }
}
