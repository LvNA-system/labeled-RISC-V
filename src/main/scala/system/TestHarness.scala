// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.devices.debug.Debug
import freechips.rocketchip.diplomacy.LazyModule
import freechips.rocketchip.amba.axi4._

class SimFront()(implicit p: Parameters) extends Module {
  val io = new Bundle {
  }
}
class BoomTestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }

  // Weird compilation failure...
  // val dut = Module(LazyModule(if (p(UseEmu)) new LvNAEmuTop else new LvNAFPGATop).module)
  val dut = Module(LazyModule(new LvNABoomEmuTop).module)
  dut.reset := reset | dut.debug.ndreset

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  dut.connectSimAXIMem()
  dut.connectSimAXIMMIO()
  Debug.connectDebug(dut.debug, clock, reset, io.success)

  val enableFrontBusTraffic = false
  val frontBusAccessAddr = 0x10000fc00L

  if (!enableFrontBusTraffic) {
    dut.l2_frontend_bus_axi4.foreach(_.tieoff)
  }
  else {
    val axi = dut.l2_frontend_bus_axi4.head
    axi.r.ready := Bool(true)
    axi.b.ready := Bool(true)
    axi.ar.valid := Bool(false)

    val IDLE = 0
    val WADDR = 1
    val state = RegInit(IDLE.U)
    val awvalid = RegInit(false.B)
    val wvalid = RegInit(false.B)
    val wlast = RegInit(false.B)
    val next_state = Wire(state.cloneType)
    state := next_state
    val (value, timeout) = Counter(state === IDLE.U, 300)
    when(state === IDLE.U) {
      next_state := Mux(timeout, WADDR.U, IDLE.U)
    }.elsewhen(state === WADDR.U) {
      awvalid := true.B
      wvalid := true.B
      wlast := true.B
      when(axi.aw.fire()) {
        awvalid := false.B
        wvalid := false.B
        wlast := false.B
        next_state := IDLE.U
      }.otherwise {
        next_state := WADDR.U
      }
    }.otherwise {
      printf("Unexpected frontend axi state: %d", state)
    }

    axi.w.valid := wvalid
    axi.aw.valid := awvalid
    axi.w.bits.last := wlast
    axi.aw.bits.id := 111.U
    axi.aw.bits.addr := frontBusAccessAddr.U
    axi.aw.bits.len := 0.U // Curr cycle data?
    axi.aw.bits.size := 2.U // 2^2 = 4 bytes
    axi.aw.bits.burst := AXI4Parameters.BURST_INCR
    axi.aw.bits.lock := UInt(0)
    axi.aw.bits.cache := UInt(0)
    axi.aw.bits.prot := AXI4Parameters.PROT_PRIVILEDGED
    axi.aw.bits.qos := UInt(0)
    axi.w.bits.data := UInt(0xdeadbeefL)
    axi.w.bits.strb := UInt(0xf) // only lower 4 bits is allowed to be 1.
  }
}

class TestHarness()(implicit p: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }

  // Weird compilation failure...
  // val dut = Module(LazyModule(if (p(UseEmu)) new LvNAEmuTop else new LvNAFPGATop).module)
  val dut = if (p(UseEmu)) Module(LazyModule(new LvNAEmuTop).module) else Module(LazyModule(new LvNAFPGATop).module)
  dut.reset := reset | dut.debug.ndreset
  if (!p(UseBoom)) {
    dut.corerst := dut.reset
    dut.coreclk := dut.clock
  }

  dut.dontTouchPorts()
  dut.tieOffInterrupts()
  dut.connectSimAXIMem()
  dut.connectSimAXIMMIO()
  Debug.connectDebug(dut.debug, clock, reset, io.success)

  val enableFrontBusTraffic = false
  val frontBusAccessAddr = 0x10000fc00L

  if (!enableFrontBusTraffic) {
    dut.l2_frontend_bus_axi4.foreach(_.tieoff)
  }
  else {
    val axi = dut.l2_frontend_bus_axi4.head
    axi.r.ready := Bool(true)
    axi.b.ready := Bool(true)
    axi.ar.valid := Bool(false)

    val IDLE = 0
    val WADDR = 1
    val state = RegInit(IDLE.U)
    val awvalid = RegInit(false.B)
    val wvalid = RegInit(false.B)
    val wlast = RegInit(false.B)
    val next_state = Wire(state.cloneType)
    state := next_state
    val (value, timeout) = Counter(state === IDLE.U, 300)
    when(state === IDLE.U) {
      next_state := Mux(timeout, WADDR.U, IDLE.U)
    }.elsewhen(state === WADDR.U) {
      awvalid := true.B
      wvalid := true.B
      wlast := true.B
      when(axi.aw.fire()) {
        awvalid := false.B
        wvalid := false.B
        wlast := false.B
        next_state := IDLE.U
      }.otherwise {
        next_state := WADDR.U
      }
    }.otherwise {
      printf("Unexpected frontend axi state: %d", state)
    }

    axi.w.valid := wvalid
    axi.aw.valid := awvalid
    axi.w.bits.last := wlast
    axi.aw.bits.id := 111.U
    axi.aw.bits.addr := frontBusAccessAddr.U
    axi.aw.bits.len := 0.U // Curr cycle data?
    axi.aw.bits.size := 2.U // 2^2 = 4 bytes
    axi.aw.bits.burst := AXI4Parameters.BURST_INCR
    axi.aw.bits.lock := UInt(0)
    axi.aw.bits.cache := UInt(0)
    axi.aw.bits.prot := AXI4Parameters.PROT_PRIVILEDGED
    axi.aw.bits.qos := UInt(0)
    axi.w.bits.data := UInt(0xdeadbeefL)
    axi.w.bits.strb := UInt(0xf) // only lower 4 bits is allowed to be 1.
  }
}
