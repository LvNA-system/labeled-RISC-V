package lvna

import Chisel._
import chisel3.core.{IO, Input, Output}
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.system.{ExampleRocketSystem, ExampleRocketSystemModuleImp, NohypeDefault, UseEmu}
import freechips.rocketchip.tile.XLen
import freechips.rocketchip.util.GTimer

case object ProcDSidWidth extends Field[Int](3)

trait HasControlPlaneParameters {
  implicit val p: Parameters
  val nTiles = p(NTiles)
  val ldomDSidWidth = log2Up(nTiles)
  val procDSidWidth = p(ProcDSidWidth)
  val dsidWidth = ldomDSidWidth + procDSidWidth
  val nDSID = 1 << dsidWidth
  val cacheCapacityWidth = log2Ceil(p(NL2CacheCapacity) * 1024 / 64)
  val cycle_counter_width = 64
}

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  private val indexWidth = 32
  val updateData   = UInt(INPUT, 32)
  val traffic      = UInt(OUTPUT, 32)
  val cycle        = UInt(OUTPUT, cycle_counter_width)
  val capacity     = UInt(OUTPUT, cacheCapacityWidth)
  val hartDsid     = UInt(OUTPUT, ldomDSidWidth)
  val hartDsidWen  = Bool(INPUT)
  val memBase      = UInt(OUTPUT, p(XLen))
  val memBaseLoWen = Bool(INPUT)
  val memBaseHiWen = Bool(INPUT)
  val memMask      = UInt(OUTPUT, p(XLen))
  val memMaskLoWen = Bool(INPUT)
  val memMaskHiWen = Bool(INPUT)
  val bucket       = new BucketBundle().asOutput
  val bktFreqWen   = Bool(INPUT)
  val bktSizeWen   = Bool(INPUT)
  val bktIncWen    = Bool(INPUT)
  val waymask      = UInt(OUTPUT, p(NL2CacheWays))
  val waymaskWen   = Bool(INPUT)
  val hartSel      = UInt(OUTPUT, indexWidth)
  val hartSelWen   = Bool(INPUT)
  val dsidSel      = UInt(OUTPUT, dsidWidth)
  val dsidSelWen   = Bool(INPUT)
  val progHartId   = UInt(OUTPUT, log2Ceil(nTiles))
  val progHartIdWen = Bool(INPUT)
}

/* From ControlPlane's View */
class CPToL2CacheIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  val waymask = Output(UInt(p(NL2CacheWays).W))  // waymask returned to L2cache (1 cycle delayed)
  val dsid = Input(UInt(dsidWidth.W))  // DSID from requests L2 cache received
  val capacity = Input(UInt(cacheCapacityWidth.W))  // Count on way numbers
  val capacity_dsid = Output(UInt(dsidWidth.W))  // Capacity query dsid
}

class BucketState(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters with HasTokenBucketParameters {
  val nToken = UInt(tokenBucketSizeWidth.W)
  val traffic = UInt(tokenBucketSizeWidth.W)
  val counter = UInt(32.W)
  val enable = Bool()
}

class BucketIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters with HasTokenBucketParameters {
  val dsid = Input(UInt(dsidWidth.W))
  val size = Input(UInt(tokenBucketSizeWidth.W))
  val fire = Input(Bool())
  val enable = Output(Bool())
}

trait HasTokenBucketPlane extends HasControlPlaneParameters with HasTokenBucketParameters {
  private val bucket_debug = false

  val bucketParams = RegInit(Vec(Seq.fill(nDSID){
    Cat(100.U(tokenBucketSizeWidth.W), 100.U(tokenBucketFreqWidth.W), 100.U(tokenBucketSizeWidth.W)).asTypeOf(new BucketBundle)
  }))

  val bucketState = RegInit(Vec(Seq.fill(nDSID){
    Cat(0.U(tokenBucketSizeWidth.W), 0.U(tokenBucketSizeWidth.W), 0.U(32.W), true.B).asTypeOf(new BucketState)
  }))

  val bucketIO = IO(Vec(nTiles, new BucketIO()))

  val timer = RegInit(0.U(cycle_counter_width.W))
  timer := Mux(timer === (~0.U(timer.getWidth.W)).asUInt, 0.U, timer + 1.U)

  bucketState.zipWithIndex.foreach { case (state, i) =>
    state.counter := Mux(state.counter >= bucketParams(i).freq, 0.U, state.counter + 1.U)
    val req_sizes = bucketIO.map{bio => Mux(bio.dsid === i.U && bio.fire, bio.size, 0.U) }
    val req_all = req_sizes.reduce(_ + _)
    val updating = state.counter >= bucketParams(i).freq
    val inc_size = Mux(updating, bucketParams(i).inc, 0.U)
    val enable_next = state.nToken + inc_size > req_all
    val calc_next = state.nToken + inc_size - req_all
    val limit_next = Mux(calc_next < bucketParams(i).size, calc_next, bucketParams(i).size)

    val has_requester = bucketIO.map{bio => bio.dsid === i.U && bio.fire}.reduce(_ || _)
    when (has_requester) {
      state.traffic := state.traffic + req_all
    }

    when (has_requester || updating) {
      state.nToken := Mux(enable_next, limit_next, 0.U)
      state.enable := enable_next
    }

    if (bucket_debug) {
      printf(s"cycle: %d bucket %d req_all %d tokens %d inc %d enable_next %b counter %d traffic %d\n", GTimer(), i.U(dsidWidth.W), req_all, state.nToken, inc_size, enable_next, state.counter, state.traffic)
    }
  }

  bucketIO.foreach { bio =>
    bio.enable := bucketState(bio.dsid).enable
  }
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
  with HasControlPlaneParameters
  with HasTokenBucketParameters
{
  private val memAddrWidth = p(XLen)

  override lazy val module = new LazyModuleImp(this) with HasTokenBucketPlane {
    val io = IO(new Bundle {
      val hartDsids = Vec(nTiles, UInt(ldomDSidWidth.W)).asOutput
      val memBases  = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val memMasks  = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val l2        = new CPToL2CacheIO()
      val cp        = new ControlPlaneIO()
      val mem_part_en = Bool().asInput
      val distinct_hart_dsid_en = Bool().asInput
      val progHartIds = Vec(nTiles, UInt(log2Ceil(nTiles).W)).asOutput
    })

    val hartSel   = RegInit(0.U(ldomDSidWidth.W))
    val hartDsids = RegInit(Vec(Seq.tabulate(nTiles){ i =>
      Mux(io.distinct_hart_dsid_en, i.U(ldomDSidWidth.W), 0.U(ldomDSidWidth.W))
    }))
    val memBases  = RegInit(Vec(Seq.tabulate(nTiles){ i =>
      val memSize: BigInt = p(ExtMem).map { m => m.size }.getOrElse(0x80000000)
      Mux(io.mem_part_en, (i * memSize / nTiles).U(memAddrWidth.W), 0.U(memAddrWidth.W))
    }))
    val memMasks  = RegInit(Vec(Seq.fill(nTiles)(~0.U(memAddrWidth.W))))
    val waymasks  = RegInit(Vec(Seq.fill(nTiles){ ((1L << p(NL2CacheWays)) - 1).U }))
    /**
      * Programmable hartid.
      */
    val progHartIds = RegInit(Vec(Seq.fill(nTiles){ 0.U(log2Ceil(nTiles).W) }))
    io.progHartIds := progHartIds
    val l2dsid_reg = RegNext(io.l2.dsid)  // 1 cycle delay
    io.l2.waymask := waymasks(l2dsid_reg)

    val currDsid = RegEnable(io.cp.updateData, 0.U, io.cp.dsidSelWen)
    io.cp.dsidSel := currDsid
    io.cp.waymask := waymasks(currDsid)
    io.cp.traffic := bucketState(currDsid).traffic
    io.cp.cycle := timer
    io.cp.capacity := io.l2.capacity
    io.l2.capacity_dsid := currDsid

    io.cp.hartDsid := hartDsids(hartSel)
    io.cp.hartSel := hartSel
    io.cp.memBase := memBases(hartSel)
    io.cp.memMask := memMasks(hartSel)
    io.cp.bucket := bucketParams(currDsid)
    io.hartDsids := hartDsids
    io.memBases := memBases
    io.memMasks := memMasks

    when (io.cp.hartSelWen) {
      hartSel := io.cp.updateData
    }

    when (io.cp.hartDsidWen) {
      hartDsids(hartSel) := io.cp.updateData
    }

    val mem_base_lo_tmp = RegInit(0.U(32.W))
    val mem_mask_lo_tmp = RegInit(~0.U(32.W))

    when (io.cp.memBaseLoWen) {
      mem_base_lo_tmp := io.cp.updateData
    }

    when (io.cp.memBaseHiWen) {
      memBases(hartSel) := Cat(io.cp.updateData, mem_base_lo_tmp)
    }

    when (io.cp.memMaskLoWen) {
      mem_mask_lo_tmp := io.cp.updateData
    }

    when (io.cp.memMaskHiWen) {
      memMasks(hartSel) := Cat(io.cp.updateData, mem_mask_lo_tmp)
    }

    when (io.cp.progHartIdWen) {
      progHartIds(hartSel) := io.cp.updateData
    }

    when (io.cp.bktFreqWen) {
      bucketParams(currDsid).freq := io.cp.updateData
    }

    when (io.cp.bktSizeWen) {
      bucketParams(currDsid).size := io.cp.updateData
    }

    when (io.cp.bktIncWen) {
      bucketParams(currDsid).inc := io.cp.updateData
    }

    when (io.cp.waymaskWen) {
      waymasks(currDsid) := io.cp.updateData
    }
  }
}

trait HasControlPlane extends HasRocketTiles {
  this: BaseSubsystem =>
  val controlPlane = LazyModule(new ControlPlane())
}

trait HasControlPlaneModuleImpl extends HasRocketTilesModuleImp {
  val outer: HasControlPlane
  val mem_part_en = IO(Input(Bool()))
  val distinct_hart_dsid_en = IO(Input(Bool()))

  (outer.rocketTiles zip outer.tokenBuckets).zipWithIndex.foreach { case((tile, token), i) =>
    val cpio = outer.controlPlane.module.io
    tile.module.dsid := cpio.hartDsids(i.U)
    tile.module.memBase := cpio.memBases(i.U)
    tile.module.memMask := cpio.memMasks(i.U)
    tile.module.progHartId := cpio.progHartIds(i)
    token.module.bucketIO <> outer.controlPlane.module.bucketIO(i)
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
  outer.controlPlane.module.io.mem_part_en := mem_part_en
  outer.controlPlane.module.io.distinct_hart_dsid_en := distinct_hart_dsid_en
}

trait BindL2WayMask extends HasRocketTiles {
  this: BaseSubsystem with HasControlPlane with CanHaveMasterAXI4MemPort =>
  val _cp = controlPlane
  val _l2 = l2cache
}

trait BindL2WayMaskModuleImp extends HasRocketTilesModuleImp {
  val outer: BindL2WayMask
  outer._l2.module.cp <> outer._cp.module.io.l2
}
