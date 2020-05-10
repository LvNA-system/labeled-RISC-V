package freechips.rocketchip.subsystem

import chisel3._

import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.amba.axi4._

import sifive.blocks.devices.chiplink._


object ChiplinkParam {
  val addr_uh = AddressSet(0x40000000L, 0x20000000L - 1)
  // Must have a cacheable address sapce.
  val addr_c = AddressSet(0x100000000L, 0x80000000L - 1)
}


trait HasChiplinkPort { this: BaseSubsystem =>
  val chiplinkParam = ChipLinkParams(
    TLUH = List(ChiplinkParam.addr_uh),
    TLC  = List(ChiplinkParam.addr_c),
    syncTX = true
  )

  val chiplink = LazyModule(new ChipLink(chiplinkParam))
  val linksink = chiplink.ioNode.makeSink // Must call makeSink under LazyModule context.

  val mchipBar = TLXbar()

  private def filtering_uh(m: TLManagerParameters) = {
    if (m.address.exists(a=>ChiplinkParam.addr_uh.overlaps(a))) Some(m) else None
  }
  private def filtering_mmio(c: TLClientParameters) = {
    if (!c.supportsProbe) Some(c) else None
  }
  val filter_uh = TLFilter(filtering_uh, filtering_mmio)

  private def filtering_c(m: TLManagerParameters) = {
    if (!m.address.exists(a=>ChiplinkParam.addr_uh.overlaps(a))) Some(m) else None
  }
  val filter_c = TLFilter(filtering_c)

  val l2cache: TLSimpleL2Cache = if (p(NL2CacheCapacity) != 0) TLSimpleL2CacheRef() else null
  private val l2node = if (p(NL2CacheCapacity) != 0) l2cache.node else TLSimpleL2Cache()
 
  mbus.toDRAMController(Some("chiplink_c")) {
    mchipBar := filter_c := l2node
  }

  // Attach chiplink as a master to system bus.
  sbus.coupleTo("chiplinkOut"){ o => mchipBar := filter_uh := o }

  chiplink.node := TLFIFOFixer(TLFIFOFixer.all) := TLWidthWidget(8) := mchipBar

  // Fake bus to serve chiplink's strict manager requirements.
  val chipbar = TLXbar()
  val chiperr = LazyModule(new TLError(DevNullParams(Seq(AddressSet(0x91000000L, 0x1000000L - 1)), 64, 64, region = RegionType.TRACKED)))
  chiperr.node := TLWidthWidget(8) := chipbar
  chipbar := TLFIFOFixer(TLFIFOFixer.all) := /*TLFragmenter(8, 64) := */ TLWidthWidget(4) := TLHintHandler() := chiplink.node
  //mbus.coupleFrom("chiplinkIn") { i => i := chipbar }
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

class LinkTopBase(implicit p: Parameters) extends LazyModule {
  val mbus = TLXbar()
  override lazy val module = new LinkTopBaseImpl(this)
}

class LinkTopBaseImpl[+L <: LinkTopBase](_outer: L) extends LazyModuleImp(_outer) {
  val outer = _outer
}

trait CanHaveMasterAXI4MemPortForLinkTop { this: LinkTopBase =>
  val module: CanHaveMasterAXI4MemPortModuleImpForLinkTop

  val memAXI4Node = p(ExtMem).map { case MemoryPortParams(memPortParams, nMemoryChannels) =>
    val portName = "axi4"
    val device = new MemoryDevice

    val cacheBlockBytes = 64
    val memAXI4Node = AXI4SlaveNode(Seq.tabulate(nMemoryChannels) { channel =>
      val base = AddressSet(memPortParams.base, memPortParams.size-1)
      val filter = AddressSet(channel * cacheBlockBytes, ~((nMemoryChannels-1) * cacheBlockBytes))

      AXI4SlavePortParameters(
        slaves = Seq(AXI4SlaveParameters(
          address       = base.intersect(filter).toList,
          resources     = device.reg,
          regionType    = RegionType.UNCACHED, // cacheable
          executable    = true,
          supportsWrite = TransferSizes(1, cacheBlockBytes),
          supportsRead  = TransferSizes(1, cacheBlockBytes),
          interleavedId = Some(0))), // slave does not interleave read responses
        beatBytes = memPortParams.beatBytes)
    })

    memAXI4Node := AXI4UserYanker() := AXI4IdIndexer(memPortParams.idBits) := TLToAXI4() := mbus

    memAXI4Node
  }
}

trait CanHaveMasterAXI4MemPortModuleImpForLinkTop extends LazyModuleImp {
  val outer: CanHaveMasterAXI4MemPortForLinkTop

  val mem_axi4 = outer.memAXI4Node.map(x => IO(HeterogeneousBag.fromNode(x.in)))
  (mem_axi4 zip outer.memAXI4Node) foreach { case (io, node) =>
    (io zip node.in).foreach { case (io, (bundle, _)) => io <> bundle }
  }

  def connectSimAXIMem() {
    (mem_axi4 zip outer.memAXI4Node).foreach { case (io, node) =>
      (io zip node.in).foreach { case (io, (_, edge)) =>
        val mem = LazyModule(new SimAXIMem(edge, size = p(ExtMem).get.master.size))
        Module(mem.module).io.axi4.head <> io
      }
    }
  }
}

/**
  * Dual top module against Rocketchip over rx/tx channel.
  */
class ChiplinkTop(implicit p: Parameters) extends LinkTopBase
  with CanHaveMasterAXI4MemPortForLinkTop
{
  // Dummy manager network
  //val xbar = TLXbar()
  // val ram = TLRAM(ChiplinkParam.addr_uh, cacheable = false, executable = false, beatBytes = 8, devName = Some("chiplinkSlave"))
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
  mbus := lognode.node := TLAtomicAutomata(passthrough=false) := TLFIFOFixer(TLFIFOFixer.all) := TLHintHandler() := TLWidthWidget(4) := chiplink.node
  err.node := TLWidthWidget(8) := mbus
  // ram := lognode.node := TLAtomicAutomata(passthrough=false) := TLFragmenter(8, 64) := TLWidthWidget(4) := xbar

  override lazy val module = new LinkTopBaseImpl(this) with CanHaveMasterAXI4MemPortModuleImpForLinkTop {
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
