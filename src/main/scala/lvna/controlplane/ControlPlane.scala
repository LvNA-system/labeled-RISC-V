package lvna

import Chisel._
import chisel3.core.{IO, Input, Output}
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.system.{ExampleRocketSystem, ExampleRocketSystemModuleImp, NohypeDefault, UseEmu}
import freechips.rocketchip.tile.XLen

case object ProcDSidWidth extends Field[Int](3)

trait HasControlPlaneParameters {
  implicit val p: Parameters
  val nTiles = p(NTiles)
  val ldomDSidWidth = log2Up(nTiles)
  val procDSidWidth = p(ProcDSidWidth)
  val dsidWidth = ldomDSidWidth + procDSidWidth
  val cacheCapacityWidth = log2Ceil(p(NL2CacheCapacity) * 1024 / 64)
}

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  private val indexWidth = 32
  val dsid          = UInt(OUTPUT, ldomDSidWidth)
  val updateData    = UInt(INPUT, 32)
  val traffic       = UInt(OUTPUT, 32)
  val capacity      = UInt(OUTPUT, cacheCapacityWidth)
  val dsidWen       = Bool(INPUT)
  val memBase       = UInt(OUTPUT, p(XLen))
  val memBaseLoWen  = Bool(INPUT)
  val memBaseHiWen  = Bool(INPUT)
  val memMask       = UInt(OUTPUT, p(XLen))
  val memMaskLoWen  = Bool(INPUT)
  val memMaskHiWen  = Bool(INPUT)
  val bucket        = new BucketBundle().asOutput
  val bktFreqWen    = Bool(INPUT)
  val bktSizeWen    = Bool(INPUT)
  val bktIncWen     = Bool(INPUT)
  val waymask       = UInt(OUTPUT, p(NL2CacheWays))
  val waymaskWen    = Bool(INPUT)
  val sel           = UInt(OUTPUT, indexWidth)
  val selUpdate     = UInt(INPUT, indexWidth)
  val selWen        = Bool(INPUT)
}

/* From ControlPlane's View */
class CPToL2CacheIO(implicit val p: Parameters) extends Bundle with HasControlPlaneParameters {
  val waymask = Output(UInt(p(NL2CacheWays).W))  // waymask returned to L2cache (1 cycle delayed)
  val dsid = Input(UInt(dsidWidth.W))  // DSID from requests L2 cache received
  val capacity = Input(UInt(cacheCapacityWidth.W))  // Count on way numbers
  val capacity_dsid = Output(UInt(dsidWidth.W))  // Capacity query dsid
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
  with HasControlPlaneParameters
  with HasTokenBucketParameters
{
  private val memAddrWidth = p(XLen)

  override lazy val module = new LazyModuleImp(this) {
    val io = IO(new Bundle {
      val dsids = Vec(nTiles, UInt(ldomDSidWidth.W)).asOutput
      val memBases = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val memMasks = Vec(nTiles, UInt(memAddrWidth.W)).asOutput
      val bucketParams = Vec(nTiles, new BucketBundle()).asOutput
      val traffics = Vec(nTiles, UInt(32.W)).asInput
      val l2 = new CPToL2CacheIO()
      val cp = new ControlPlaneIO()
      val mem_part_en = Bool().asInput
    })

    def gen_table[T <: Data](init: => T): Vec[T] = RegInit(Vec(Seq.fill(nTiles){ init }))
    val dsids = RegInit(Vec(Seq.tabulate(nTiles)(_.U(ldomDSidWidth.W))))
    val dsidSel = RegInit(0.U(ldomDSidWidth.W))
    val memBases = RegInit(Vec(Seq.tabulate(nTiles){ i =>
      val memSize: BigInt = p(ExtMem).map { m => m.size }.getOrElse(0x80000000)
      Mux(io.mem_part_en, (i * memSize / nTiles).U(memAddrWidth.W), 0.U(memAddrWidth.W))
    }))
    val memMasks = RegInit(Vec(Seq.fill(nTiles)(~0.U(memAddrWidth.W))))
    val bucketParams = RegInit(Vec(Seq.fill(nTiles){
      Cat(256.U(tokenBucketSizeWidth.W), 0.U(tokenBucketFreqWidth.W), 256.U(tokenBucketSizeWidth.W)).asTypeOf(new BucketBundle)
    }))
    val waymasks = gen_table(((1L << p(NL2CacheWays)) - 1).U)
    io.cp.waymask := waymasks(dsidSel)
    val l2dsid_reg = RegNext(io.l2.dsid)  // 1 cycle delay
    io.l2.waymask := waymasks(l2dsid_reg)

    val currDsid = dsids(dsidSel)

    io.cp.traffic := io.traffics(dsidSel)
    io.cp.capacity := io.l2.capacity
    io.l2.capacity_dsid := currDsid

    io.cp.dsid := currDsid
    io.cp.sel := dsidSel
    io.cp.memBase := memBases(dsidSel)
    io.cp.memMask := memMasks(dsidSel)
    io.cp.bucket := bucketParams(dsidSel)
    io.dsids := dsids
    io.memBases := memBases
    io.memMasks := memMasks
    io.bucketParams := bucketParams

    when (io.cp.selWen) {
      dsidSel := io.cp.selUpdate
    }

    when (io.cp.dsidWen) {
      dsids(dsidSel) := io.cp.updateData
    }

    val mem_base_lo_tmp = RegInit(0.U(32.W))
    val mem_mask_lo_tmp = RegInit(~0.U(32.W))

    when (io.cp.memBaseLoWen) {
      mem_base_lo_tmp := io.cp.updateData
    }

    when (io.cp.memBaseHiWen) {
      memBases(dsidSel) := Cat(io.cp.updateData, mem_base_lo_tmp)
    }

    when (io.cp.memMaskLoWen) {
      mem_mask_lo_tmp := io.cp.updateData
    }

    when (io.cp.memMaskHiWen) {
      memMasks(dsidSel) := Cat(io.cp.updateData, mem_mask_lo_tmp)
    }

    when (io.cp.bktFreqWen) {
      bucketParams(dsidSel).freq := io.cp.updateData
    }

    when (io.cp.bktSizeWen) {
      bucketParams(dsidSel).size := io.cp.updateData
    }

    when (io.cp.bktIncWen) {
      bucketParams(dsidSel).inc := io.cp.updateData
    }

    when (io.cp.waymaskWen) {
      waymasks(dsidSel) := io.cp.updateData
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

  (outer.rocketTiles zip outer.tokenBuckets).zipWithIndex.foreach { case((tile, token), i) =>
    val cpio = outer.controlPlane.module.io
    tile.module.dsid := cpio.dsids(i.U)
    tile.module.memBase := cpio.memBases(i.U)
    tile.module.memMask := cpio.memMasks(i.U)
    token.module.bucketParam := cpio.bucketParams(i.U)
    cpio.traffics(i) := token.module.traffic
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
  outer.controlPlane.module.io.mem_part_en := mem_part_en
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
