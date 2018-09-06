// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy.LazyModule
import freechips.rocketchip.amba.axi4._

class TestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }

  val dut = Module(LazyModule(if (p(UseEmu)) new LvNAEmuTop else new LvNAFPGATop).module)
  dut.reset := reset | dut.debug.ndreset
  dut.corerst := dut.reset
  dut.coreclk := dut.clock

  val ahbInst = Module(LazyModule(new LvNAFPGATopAHB).module)
  ahbInst.dontTouchPorts()

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  dut.connectSimAXIMem()
  dut.connectSimAXIMMIO()
  dut.connectDebug(clock, reset, io.success)

  //dut.l2_frontend_bus_axi4.foreach(_.tieoff)
  val axi = dut.l2_frontend_bus_axi4(0)
  axi.r.ready := Bool(true)
  axi.b.ready := Bool(true)

  //axi.ar.valid := Bool(false)
  axi.ar.valid := Bool(true)
  axi.ar.bits.id := UInt(0)
  val cnt = Counter(axi.ar.fire(), 0xff)._1
  axi.ar.bits.addr := (cnt << UInt(3))+ UInt(0x100700000L)
  when (axi.ar.fire()) {
    printf("cnt = %d\n", cnt)
  }
  axi.ar.bits.len := UInt(7)
  axi.ar.bits.size := UInt(3)
  axi.ar.bits.burst := AXI4Parameters.BURST_INCR
  axi.ar.bits.lock  := UInt(0)
  axi.ar.bits.cache := UInt(0)
  axi.ar.bits.prot  := AXI4Parameters.PROT_PRIVILEDGED
  axi.ar.bits.qos   := UInt(0)

  axi.w.valid := Bool(false)
  axi.aw.valid := Bool(false)
  //axi.aw.valid := Bool(true)
  //axi.aw.bits.id := UInt(0)
  //axi.aw.bits.addr := ((Counter(axi.aw.fire(), 0xff)._1) << UInt(3))+ UInt(0x100700000L)
  //axi.aw.bits.len := UInt(0)
  //axi.aw.bits.size := UInt(3)
  //axi.aw.bits.burst := AXI4Parameters.BURST_INCR
  //axi.aw.bits.lock  := UInt(0)
  //axi.aw.bits.cache := UInt(0)
  //axi.aw.bits.prot  := AXI4Parameters.PROT_PRIVILEDGED
  //axi.aw.bits.qos   := UInt(0)

  //axi.w.valid := Bool(true)
  //axi.w.bits.data := UInt(0xdeadbeefL)
  //axi.w.bits.strb := UInt(0xff)
  //axi.w.bits.last := (Counter(axi.w.fire(), 0x4)._2)
}
