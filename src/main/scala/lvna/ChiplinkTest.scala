package freechips.rocketchip.subsystem

import chisel3._
import chisel3.util._

import freechips.rocketchip.config.{Field, Parameters}
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util._
import freechips.rocketchip.devices.tilelink._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.system._

import sifive.blocks.devices.chiplink._


object ChiplinkParam {
  val addr_uh = AddressSet(0x40000000L, 0x40000000L - 1)
  // Must have a cacheable address sapce.
  val addr_c = AddressSet(0x100000000L, 0x100000000L - 1)
}


class NonProbeBridge()(implicit p: Parameters) extends LazyModule
{
  val node = TLAdapterNode(
    clientFn = (c) => {
      c.copy(clients = c.clients.map { cp =>
        cp.copy(
          supportsProbe = TransferSizes.none
        )
      })
    }
  )

  override lazy val module = new LazyModuleImp(this) {
    (node.out zip node.in) foreach { case ((io_out, edge_out), (io_in, edge_in)) =>
      io_out <> io_in
      io_in.b.valid := false.B
      io_out.b.ready := false.B
      io_out.c.valid := false.B
      io_in.c.ready := false.B

      assert(!io_out.b.valid, "Unexpected probe from frontbus to chiplink")
      assert(!io_in.c.valid, "Unexpected release from chiplink to frontbus")
    }
  }
}


class NonAtomicBridge()(implicit p: Parameters) extends LazyModule
{
  val node = TLAdapterNode(
    managerFn = (m) => {
      m.copy(managers = m.managers.map { mp =>
        mp.copy(
          supportsArithmetic = TransferSizes.none,
          supportsLogical = TransferSizes.none,
          supportsHint = TransferSizes.none)
      })
    })

  override lazy val module = new LazyModuleImp(this) {
    (node.out zip node.in) foreach { case ((io_out, edge_out), (io_in, edge_in)) =>
      io_out <> io_in
      io_in.b.valid := false.B
      io_out.b.ready := false.B
      io_out.c.valid := false.B
      io_in.c.ready := false.B

      assert(!io_out.b.valid, "Unexpected probe from frontbus to chiplink")
      assert(!io_in.c.valid, "Unexpected release from chiplink to frontbus")
    }
  }
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
  // [WHZ] TODO Test crossFrom / synchronousCrossing
  val nonProbeBridge = LazyModule(new NonProbeBridge())
  fbus.fromPort(Some("chipMaster")) { nonProbeBridge.node := chipbar }
}


trait HasChiplinkPortImpl extends LazyModuleImp {
  val outer: HasChiplinkPort
  val io_chip = outer.linksink.makeIO()
}


class TLLogger(prefix: String)(implicit p: Parameters) extends LazyModule {
  val node = TLAdapterNode()
  override lazy val module = new LazyModuleImp(this) {
    (node.in zip node.out) foreach { case ((in, _), (out, _)) =>
      out <> in
      // Log as soon as valid to detect potential unresponsive situation.
      // cnt & precnt to log only once.
      val cnt = RegInit(1.U(64.W))
      val precnt = RegInit(0.U(64.W))
      when (in.a.valid && cnt =/= precnt) {
        precnt := cnt
      }
      when (in.a.fire()) {
        printf(s"[$prefix] A addr %x opcode %x param %x data %x source %x mask %b\n", in.a.bits.address, in.a.bits.opcode, in.a.bits.param, in.a.bits.data, in.a.bits.source, in.a.bits.mask)
        cnt := cnt + 1.U
      }
      when (in.d.fire()) {
        printf(s"[$prefix] D opcode %x data %x source %x\n", in.d.bits.opcode, in.d.bits.data, in.d.bits.source)
      }
    }
  }
}

object TLLogger {
  def apply(prefix: String)(implicit p: Parameters) = {
    val logger = LazyModule(new TLLogger(prefix))
    logger.node
  }
}

class LinkTopBase(implicit p: Parameters) extends LazyModule {
  val mbus = TLXbar()
  val fxbar = TLXbar()
  val ferr = LazyModule(new TLError(DevNullParams(Seq(AddressSet(0x90000000L, 0x10000000L - 1)), 64, 64, region = RegionType.TRACKED)))

  val chiplinkParam = ChipLinkParams(
    TLUH = List(ChiplinkParam.addr_uh),
    TLC  = List(ChiplinkParam.addr_c),
    syncTX = true
  )

  val chiplink = LazyModule(new ChipLink(chiplinkParam))
  val sink = chiplink.ioNode.makeSink

  chiplink.node := fxbar
  ferr.node := fxbar

  override lazy val module = new LinkTopBaseImpl(this)
}

class LinkTopBaseImpl[+L <: LinkTopBase](_outer: L) extends LazyModuleImp(_outer) {
  val outer = _outer
  val fpga_io = outer.sink.makeIO()
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


/** Adds an AXI4 port to the system intended to be a slave on an MMIO device bus */
trait CanHaveSlaveAXI4PortForLinkTop { this: ChiplinkTop =>
  implicit val p: Parameters

  private val slavePortParamsOpt = p(ExtIn)
  private val portName = "slave_port_axi4"
  private val fifoBits = 1

  val l2FrontendAXI4Node = AXI4MasterNode(
    slavePortParamsOpt.map(params =>
      AXI4MasterPortParameters(
        masters = Seq(AXI4MasterParameters(
          name = portName.kebab,
          id   = IdRange(0, 1 << params.idBits))))).toSeq)

  slavePortParamsOpt.map { params =>
    fxbar := TLFIFOFixer(TLFIFOFixer.all) := (TLWidthWidget(params.beatBytes)
      := AXI4ToTL()
      := AXI4UserYanker(Some(1 << (params.sourceBits - fifoBits - 1)))
      := AXI4Fragmenter()
      := AXI4IdIndexer(fifoBits)
      := l2FrontendAXI4Node)
  }
}

/** Actually generates the corresponding IO in the concrete Module */
trait CanHaveSlaveAXI4PortModuleImpForLinkTop extends LazyModuleImp {
  val outer: CanHaveSlaveAXI4PortForLinkTop
  val l2_frontend_bus_axi4 = IO(Flipped(HeterogeneousBag.fromNode(outer.l2FrontendAXI4Node.out)))
  (outer.l2FrontendAXI4Node.out zip l2_frontend_bus_axi4) foreach { case ((bundle, _), io) => bundle <> io }
}


/** Adds a AXI4 port to the system intended to master an MMIO device bus */
trait CanHaveMasterAXI4MMIOPortForLinkTop { this: LinkTopBase =>
  implicit val p: Parameters

  private val mmioPortParamsOpt = p(ExtBus)
  private val portName = "mmio_port_axi4"
  private val device = new SimpleBus(portName.kebab, Nil)

  val mmioAXI4Node = AXI4SlaveNode(
    mmioPortParamsOpt.map(params =>
      AXI4SlavePortParameters(
        slaves = Seq(AXI4SlaveParameters(
          address       = AddressSet.misaligned(params.base, params.size),
          resources     = device.ranges,
          executable    = params.executable,
          supportsWrite = TransferSizes(1, params.maxXferBytes),
          supportsRead  = TransferSizes(1, params.maxXferBytes))),
        beatBytes = params.beatBytes)).toSeq)

  mmioPortParamsOpt.map { params =>
    mmioAXI4Node := (AXI4Buffer()
      := AXI4UserYanker()
      := AXI4Deinterleaver(64 /* blockBytes, literal OK? */)
      := AXI4IdIndexer(params.idBits)
      := TLToAXI4()) := mbus
  }
}


/** Actually generates the corresponding IO in the concrete Module */
trait CanHaveMasterAXI4MMIOPortModuleImpForLinkTop extends LazyModuleImp {
  val outer: CanHaveMasterAXI4MMIOPortForLinkTop
  val mmio_axi4 = IO(HeterogeneousBag.fromNode(outer.mmioAXI4Node.in))

  (mmio_axi4 zip outer.mmioAXI4Node.in) foreach { case (io, (bundle, _)) => io <> bundle }

  def connectSimAXIMMIO() {
    (mmio_axi4 zip outer.mmioAXI4Node.in) foreach { case (io, (_, edge)) =>
      // test harness size capped to 4KB (ignoring p(ExtMem).get.master.size)
      val mmio_mem = LazyModule(new SimAXIMem(edge, size = 4096))
      Module(mmio_mem.module).io.axi4.head <> io
    }
  }
}


class DummyMaster()(implicit p: Parameters) extends LazyModule {
  val node = TLClientNode(Seq(TLClientPortParameters(Seq(TLClientParameters("dummyMaster")))))

  override lazy val module = new LazyModuleImp(this) {
    val (client_out, e) = node.out(0)
    client_out.a.valid := false.B
    client_out.c.valid := false.B
    client_out.e.valid := false.B
    client_out.a.bits := 0.U.asTypeOf(client_out.a.bits)
    client_out.c.bits := 0.U.asTypeOf(client_out.c.bits)
    client_out.e.bits := 0.U.asTypeOf(client_out.e.bits)
    client_out.b.ready := false.B
    client_out.d.ready := false.B

    val s_init :: s_req :: s_wait_resp :: Nil = Enum(3)
    val state = RegInit(s_init)
    val (delay_cnt, overflow) = Counter(state === s_init, 300)
    val beat_cnt = RegInit(0.U)

    client_out.a.valid := state === s_req
    client_out.d.ready := state === s_wait_resp

    val tasks = List(
      (e.Put(0.U, 0x100000000L.U, 1.U, 0x0000a001L.U, 0x3.U), 1.U),  // half data width partial
      (e.Get(0.U, 0x100000000L.U, log2Ceil(8).U), 2.U),
      (e.Put(0.U, 0x100000003L.U, 0.U, 0xbb0000ccL.U, 0x8.U), 1.U),  // unaligned partial
    )

    val cmds_check = VecInit(tasks.map(_._1._1))
    val cmds_a = VecInit(tasks.map(_._1._2))
    val expected_resps = VecInit(tasks.map(_._2))

    val cmd_index = Counter(tasks.size)

    client_out.a.bits := cmds_a(cmd_index.value)
    val curr_check = cmds_check(cmd_index.value)
    val curr_expect_resps = expected_resps(cmd_index.value)

    when (state === s_init) {
      when (overflow) {
        printf("client to s_req, check = %x\n", curr_check)
        state := s_req
      }
    }
    when (state === s_req) {
      when (client_out.a.fire()) {
        printf("client to s_wait_resp, expect %d resp(s)\n", curr_expect_resps)
        state := s_wait_resp
        beat_cnt := curr_expect_resps
      }
    }
    when (state === s_wait_resp) {
      when (client_out.d.fire()) {
        printf("client get resp opcode %x data %x\n", client_out.d.bits.opcode, client_out.d.bits.data)
        beat_cnt := beat_cnt - 1.U
        when (beat_cnt === 1.U) {
          state := s_init
          printf("client to s_init\n")
          delay_cnt := 0.U
          cmd_index.inc() // Select next cmd
        }
      }
    }
  }
}


/**
  * Dual top module against Rocketchip over rx/tx channel.
  */
class ChiplinkTop(implicit p: Parameters) extends LinkTopBase
  with CanHaveMasterAXI4MemPortForLinkTop
  with CanHaveMasterAXI4MMIOPortForLinkTop
  with CanHaveSlaveAXI4PortForLinkTop
{
  // Dummy manager network
  val err = LazyModule(new TLError(DevNullParams(Seq(AddressSet(0x90000000L, 0x10000000L - 1)), 64, 64, region = RegionType.TRACKED)))

  // Hint & Atomic augment
  mbus := TLAtomicAutomata(passthrough=false) := TLFIFOFixer(TLFIFOFixer.all) := TLHintHandler() := TLWidthWidget(4) := chiplink.node
  err.node := TLWidthWidget(8) := mbus

  override lazy val module = new LinkTopBaseImpl(this)
    with CanHaveMasterAXI4MemPortModuleImpForLinkTop
	with CanHaveMasterAXI4MMIOPortModuleImpForLinkTop
    with CanHaveSlaveAXI4PortModuleImpForLinkTop
}


class DualTop(implicit p: Parameters) extends LazyModule
{
  val chip_top = LazyModule(new ChiplinkTop)

  val rocket_top = LazyModule(new LvNAFPGATop)


  override lazy val module = new LazyModuleImp(this) with DontTouch
  {
    val rocket = rocket_top.module
    val chip = chip_top.module
    rocket.reset := reset.toBool() | rocket.debug.ndreset
    chip.reset := reset.toBool() | rocket.debug.ndreset

    rocket.io_chip.b2c <> chip.fpga_io.c2b
    chip.fpga_io.b2c <> rocket.io_chip.c2b

    val debug = IO(chiselTypeOf(rocket.debug))
    debug <> rocket.debug
    val coreclk = IO(chiselTypeOf(rocket.coreclk))
    coreclk <> rocket.coreclk
    val corerst = IO(chiselTypeOf(rocket.corerst))
    corerst <> rocket.corerst
    val ila = IO(chiselTypeOf(rocket.ila))
    ila <> rocket.ila
    val fpga_trace = IO(chiselTypeOf(rocket.fpga_trace))
    fpga_trace <> rocket.fpga_trace
    val fpga_trace_ex = IO(chiselTypeOf(rocket.fpga_trace_ex))
    fpga_trace_ex <> rocket.fpga_trace_ex
    val interrupts = IO(chiselTypeOf(rocket.interrupts))
    interrupts <> rocket.interrupts
    val reset_to_hang_en = IO(chiselTypeOf(rocket.reset_to_hang_en))
    reset_to_hang_en <> rocket.reset_to_hang_en
    val mem_part_en = IO(chiselTypeOf(rocket.mem_part_en))
    mem_part_en <> rocket.mem_part_en
    val distinct_hart_dsid_en = IO(chiselTypeOf(rocket.distinct_hart_dsid_en))
    distinct_hart_dsid_en <> rocket.distinct_hart_dsid_en

    val mem_axi4 = chip.mem_axi4.map(e => IO(chiselTypeOf(e)))
    mem_axi4.foreach { outside => chip.mem_axi4.map { inside =>
      outside <> inside
    }}
    val mmio_axi4 = IO(chiselTypeOf(chip.mmio_axi4))
    mmio_axi4 <> chip.mmio_axi4
    val l2_frontend_bus_axi4 = IO(chiselTypeOf(chip.l2_frontend_bus_axi4))
    chip.l2_frontend_bus_axi4 <> l2_frontend_bus_axi4
    
    val mmio_apb = IO(chiselTypeOf(rocket.mmio_apb))
    mmio_apb <> rocket.mmio_apb
  }
}
