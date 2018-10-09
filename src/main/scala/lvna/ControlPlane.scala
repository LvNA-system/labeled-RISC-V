package lvna

import chisel3._
import chisel3.util.Cat
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}
import freechips.rocketchip.subsystem.{BaseSubsystem, HasRocketTiles, HasRocketTilesModuleImp, NTiles}
import freechips.rocketchip.tile.XLen

case object DsidWidth extends Field[Int](5)

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle {
  private val dsidWidth = p(DsidWidth).W
  private val indexWidth = 32.W
  val dsid          = Output(UInt(dsidWidth))
  val dsidUpdate    = Input(UInt(dsidWidth))
  val dsidWen       = Input(Bool())
  val memBase       = Output(UInt(p(XLen).W))
  val memBaseUpdate = Input(UInt(32.W))
  val memBaseLoWen  = Input(Bool())
  val memBaseHiWen  = Input(Bool())
  val memMask       = Output(UInt(p(XLen).W))
  val memMaskUpdate = Input(UInt(32.W))
  val memMaskLoWen  = Input(Bool())
  val memMaskHiWen  = Input(Bool())
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
      val cp = new ControlPlaneIO()
    })

    val dsids = RegInit(VecInit(Seq.fill(nTiles)(1.U(dsidWidth.W))))
    val dsidSel = RegInit(0.U(dsidWidth.W))
    val memBases = RegInit(VecInit(Seq.fill(nTiles)(0.U(memAddrWidth.W))))
    val memMasks = RegInit(VecInit(Seq.fill(nTiles)(~0.U(memAddrWidth.W))))
    val dsidCnt = WireInit(nTiles.U(dsidWidth.W))
    val currDsid = WireInit(dsids(dsidSel))

    io.cp.dsid := currDsid
    io.cp.sel := dsidSel
    io.cp.count := dsidCnt
    io.cp.memBase := memBases(dsidSel)
    io.cp.memMask := memMasks(dsidSel)
    io.dsids := dsids
    io.memBases := memBases
    io.memMasks := memMasks

    when (io.cp.selWen) {
      dsidSel := io.cp.selUpdate
    }

    when (io.cp.dsidWen) {
      dsids(dsidSel) := io.cp.dsidUpdate
    }

    val mem_base_lo_tmp = RegInit(0.U(32.W))
    val mem_mask_lo_tmp = RegInit(~0.U(32.W))

    when (io.cp.memBaseLoWen) {
      mem_base_lo_tmp := io.cp.memBaseUpdate
    }

    when (io.cp.memBaseHiWen) {
      memBases(dsidSel) := Cat(io.cp.memBaseUpdate, mem_base_lo_tmp)
    }

    when (io.cp.memMaskLoWen) {
      mem_mask_lo_tmp := io.cp.memMaskUpdate
    }

    when (io.cp.memMaskHiWen) {
      memMasks(dsidSel) := Cat(io.cp.memMaskUpdate, mem_mask_lo_tmp)
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
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
}
