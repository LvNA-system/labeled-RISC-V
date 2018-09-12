package lvna

import chisel3._
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.devices.debug.{HasPeripheryDebug, RWNotify}
import freechips.rocketchip.regmapper.{RegField, RegFieldDesc}
import freechips.rocketchip.diplomacy.{AddressSet, LazyModule, LazyModuleImp, SimpleDevice}
import freechips.rocketchip.subsystem.{BaseSubsystem, HasRocketTiles, HasRocketTilesModuleImp, NTiles}
import freechips.rocketchip.tilelink.TLRegisterNode

case object CtrlCpAddrBase extends Field[Int]
case object CtrlCpAddrSize extends Field[Int]
case object DsidWidth extends Field[Int]

class WithControlPlane extends Config((site, here, up) => {
  case CtrlCpAddrBase => 0x20000
  case CtrlCpAddrSize => 0x100
  case DsidWidth => 16
})

/**
  * From ControlPlane's side of view.
  */
class ControlPlaneIO(implicit val p: Parameters) extends Bundle {
  private val dsidWidth = p(DsidWidth).W
  private val indexWidth = 32.W
  val dsid = Output(UInt(dsidWidth))
  val dsidUpdate = Input(UInt(dsidWidth))
  val dsidWen = Input(Bool())
  val sel = Output(UInt(indexWidth))
  val selUpdate = Input(UInt(indexWidth))
  val selWen = Input(Bool())
  val count = Output(UInt(indexWidth))
}

class ControlPlane()(implicit p: Parameters) extends LazyModule
{
  private val dsidWidth = p(DsidWidth)

  override lazy val module = new LazyModuleImp(this) {
    private val nTiles = p(NTiles)

    val io = IO(new Bundle {
      val dsids = Output(Vec(nTiles, UInt(dsidWidth.W)))
      val cp = new ControlPlaneIO()
    })

    val dsids = RegInit(Vec(Seq.fill(nTiles)(1.U(dsidWidth.W))))
    val dsidSel = RegInit(0.U(dsidWidth.W))
    val dsidCnt = WireInit(nTiles.U(dsidWidth.W))
    val currDsid = WireInit(dsids(dsidSel))

    io.cp.dsid := currDsid
    io.cp.sel := dsidSel
    io.cp.count := dsidCnt
    io.dsids := dsids

    when (io.cp.selWen) {
      dsidSel := io.cp.selUpdate
    }

    when (io.cp.dsidWen) {
      dsids(dsidSel) := io.cp.dsidUpdate
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
    tile.module.dsid := outer.controlPlane.module.io.dsids(i.U)
  }

  outer.debug.module.io.cp <> outer.controlPlane.module.io.cp
}