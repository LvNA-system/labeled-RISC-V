package freechips.rocketchip.subsystem

import chisel3._

import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util._
import freechips.rocketchip.devices.tilelink._

import sifive.blocks.devices.chiplink._


object ChiplinkParam {
  val addr_uh = AddressSet(0x80000000L, 0x10000000L - 1)
  // Must have a cacheable address sapce.
  val addr_c = AddressSet(0x90000000L, 0x10000000L - 1)
}


trait HasChiplinkPort { this: BaseSubsystem =>
  val chiplinkParam = ChipLinkParams(
    TLUH = List(ChiplinkParam.addr_uh),
    TLC  = List(ChiplinkParam.addr_c),
    syncTX = true
  )

  val chiplink = LazyModule(new ChipLink(chiplinkParam))
  val linksink = chiplink.ioNode.makeSink // Must call makeSink under LazyModule context.

  // Attach chiplink as a master to system bus.
  chiplink.node := sbus.coupleTo("chiplinkOut"){ o => TLFIFOFixer(TLFIFOFixer.all) := TLWidthWidget(8) := o }

  // Fake bus to serve chiplink's strict manager requirements.
  val chipbar = TLXbar()
  val chiperr = LazyModule(new TLError(DevNullParams(Seq(AddressSet(0x90000000L, 0x10000000L - 1)), 64, 64, region = RegionType.TRACKED)))
  chipbar := chiplink.node
  chiperr.node := chipbar
}

trait HasChiplinkPortImpl extends LazyModuleImp {
  val outer: HasChiplinkPort
  val io_chip = outer.linksink.makeIO()
}


class TLLogger(implicit p: Parameters) extends LazyModule {
  val node = TLAdapterNode()
  override lazy val module = new LazyModuleImp(this) {
    (node.in zip node.out) foreach { case ((in, _), (out, _)) =>
      out <> in
      // Log as soon as valid to detect potential unresponsive situation.
      // cnt & precnt to log only once.
      val cnt = RegInit(1.U(64.W))
      val precnt = RegInit(0.U(64.W))
      when (in.a.valid && cnt =/= precnt) {
        printf("A addr %x opcode %x param %x data %x\n", in.a.bits.address, in.a.bits.opcode, in.a.bits.param, in.a.bits.data)
        precnt := cnt
      }
      when (in.a.fire()) {
        printf("A fired\n")
        cnt := cnt + 1.U
      }
      when (in.d.fire()) {
        printf("D opcode %x data %x\n", in.d.bits.opcode, in.d.bits.data)
      }
    }
  }
}

/**
  * Dual top module against Rocketchip over rx/tx channel.
  */
class ChiplinkTop(implicit p: Parameters) extends LazyModule {
  // Dummy manager network
  val xbar = TLXbar()
  val ram = TLRAM(ChiplinkParam.addr_uh, cacheable = false, executable = false, beatBytes = 8, devName = Some("chiplinkSlave"))
  val err = LazyModule(new TLError(DevNullParams(Seq(AddressSet(0x90000000L, 0x10000000L - 1)), 64, 64, region = RegionType.TRACKED)))
  val lognode = LazyModule(new TLLogger())

  // Dummy client
  val client = TLClientNode(Seq(TLClientPortParameters(Seq(TLClientParameters("dummyMaster")))))

  val chiplinkParam = ChipLinkParams(
    TLUH = List(ChiplinkParam.addr_uh),
    TLC  = List(ChiplinkParam.addr_c),
    syncTX = true
  )

  val chiplink = LazyModule(new ChipLink(chiplinkParam))
  val sink = chiplink.ioNode.makeSink

  chiplink.node := client

  // Hint & Atomic augment
  xbar := TLFIFOFixer(TLFIFOFixer.all) := TLHintHandler() := chiplink.node
  err.node := xbar
  ram := lognode.node := TLAtomicAutomata(passthrough=false) := TLFragmenter(8, 64) := TLWidthWidget(4) := xbar

  override lazy val module = new LazyModuleImp(this) {
    val (client_out, _) = client.out(0)
    client_out.a.valid := false.B
    client_out.c.valid := false.B
    client_out.e.valid := false.B
    client_out.a.bits := 0.U.asTypeOf(client_out.a.bits)
    client_out.c.bits := 0.U.asTypeOf(client_out.c.bits)
    client_out.e.bits := 0.U.asTypeOf(client_out.e.bits)
    client_out.b.ready := false.B
    client_out.d.ready := false.B
    val fpga_io = sink.makeIO()
  }
}
