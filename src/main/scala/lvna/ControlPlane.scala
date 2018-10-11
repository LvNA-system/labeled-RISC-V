package lvna

import chisel3._
import chisel3.util.Cat
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem.{BaseSubsystem, HasRocketTiles, HasRocketTilesModuleImp, NTiles}
import freechips.rocketchip.tile.XLen
import uncore.pard.{BucketBits, BucketBitsParams, BucketBundle}

case object DsidWidth extends Field[Int](5)

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle {
  private val dsidWidth = p(DsidWidth).W
  private val indexWidth = 32.W
  val dsid          = Output(UInt(dsidWidth))
  val updateData    = Input(UInt(32.W))
  val dsidWen       = Input(Bool())
  val memBase       = Output(UInt(p(XLen).W))
  val memBaseLoWen  = Input(Bool())
  val memBaseHiWen  = Input(Bool())
  val memMask       = Output(UInt(p(XLen).W))
  val memMaskLoWen  = Input(Bool())
  val memMaskHiWen  = Input(Bool())
  val bucket        = Output(new BucketBundle)
  val bktFreqWen    = Input(Bool())
  val bktSizeWen    = Input(Bool())
  val bktIncWen     = Input(Bool())
  val sel           = Output(UInt(indexWidth))
  val selUpdate     = Input(UInt(indexWidth))
  val selWen        = Input(Bool())
  val count         = Output(UInt(indexWidth))
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
{
  private val dsidWidth = p(DsidWidth)
  private val memAddrWidth = p(XLen)

  override lazy val module = new LazyModuleImp(this) {
    private val nTiles = p(NTiles)

    val io = IO(new Bundle {
      val dsids = Output(Vec(nTiles, UInt(dsidWidth.W)))
      val memBases = Output(Vec(nTiles, UInt(memAddrWidth.W)))
      val memMasks = Output(Vec(nTiles, UInt(memAddrWidth.W)))
      val bucketParams = Output(Vec(nTiles, new BucketBundle()))
      val cp = new ControlPlaneIO()
    })

    val dsids = RegInit(VecInit(Seq.fill(nTiles)(1.U(dsidWidth.W))))
    val dsidSel = RegInit(0.U(dsidWidth.W))
    val memBases = RegInit(VecInit(Seq.fill(nTiles)(0.U(memAddrWidth.W))))
    val memMasks = RegInit(VecInit(Seq.fill(nTiles)(~0.U(memAddrWidth.W))))
    val bucketParams = RegInit(VecInit(Seq.fill(nTiles){
      val bkt = p(BucketBits)
      Cat(256.U(bkt.size.W), 0.U(bkt.freq.W), 256.U(bkt.size.W)).asTypeOf(new BucketBundle)
    }))
    val dsidCnt = WireInit(nTiles.U(dsidWidth.W))
    val currDsid = WireInit(dsids(dsidSel))

    io.cp.dsid := currDsid
    io.cp.sel := dsidSel
    io.cp.count := dsidCnt
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
  }
}

trait HasControlPlane extends HasRocketTiles {
  this: BaseSubsystem =>
  val controlPlane = LazyModule(new ControlPlane())
}

trait HasControlPlaneModuleImpl extends HasRocketTilesModuleImp {
  val outer: HasControlPlane

  outer.rocketTiles.zipWithIndex.foreach { case(tile, i) =>
    val cpio = outer.controlPlane.module.io
    tile.module.dsid := cpio.dsids(i.U)
    tile.module.memBase := cpio.memBases(i.U)
    tile.module.memMask := cpio.memMasks(i.U)
    tile.module.bucketParam := cpio.bucketParams(i.U)
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
}
