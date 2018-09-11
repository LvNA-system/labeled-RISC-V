package lvna

import chisel3._
import freechips.rocketchip.config.{Config, Field, Parameters}
import freechips.rocketchip.devices.debug.RWNotify
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

class ControlPlane(beatBytes: Int)(implicit p: Parameters) extends LazyModule
{
  val device = new SimpleDevice("control-plane", Seq("pard,test","pard,test"))

  val base = p(CtrlCpAddrBase)
  val mask = p(CtrlCpAddrSize) - 1
  require((mask & (mask + 1)) == 0, s"CtrlCpAddrSize(${p(CtrlCpAddrSize)}) must be power of 2")

  val tlNode = TLRegisterNode(
    address=Seq(AddressSet(base, mask)),
    device=device,
    beatBytes = beatBytes
  )

  val dsidWidth = p(DsidWidth)

  override lazy val module = new LazyModuleImp(this) {
    private val nTiles = p(NTiles)

    val dsids = RegInit(Vec(Seq.fill(nTiles)(1.U(dsidWidth.W))))
    val dsidRen = WireInit(false.B)
    val dsidIn = WireInit(0.U(dsidWidth.W))
    val dsidWen = WireInit(false.B)

    val dsidSel = RegInit(0.U(dsidWidth.W))
    val dsidSelRen = WireInit(false.B)
    val dsidSelIn = WireInit(0.U(dsidWidth.W))
    val dsidSelWen = WireInit(false.B)

    val dsidCnt = WireInit(nTiles.U(dsidWidth.W))

    val io = IO(new Bundle {
      val dsids = Output(Vec(nTiles, UInt(dsidWidth.W)))
    })

    val currDsid = WireInit(dsids(dsidSel))

    tlNode.regmap(
      0x00 -> Seq(RWNotify(dsidWidth, currDsid, dsidIn, dsidRen, dsidWen, Some(RegFieldDesc("dsid", "LvNA label for the selected hart")))),
      0x04 -> Seq(RWNotify(32, dsidSel, dsidSelIn, dsidSelRen, dsidSelWen, Some(RegFieldDesc("dsid-sel", "Hart index")))),
      0x08 -> Seq(RegField.r(32, dsidCnt, RegFieldDesc("dsid-count", "The total number of dsid registers")))
    )

    when (dsidSelWen) {
      dsidSel := dsidSelIn
    }

    when(dsidWen) {
      dsids(dsidSel) := dsidIn
    }

    io.dsids := dsids
  }
}

trait HasControlPlane extends HasRocketTiles {
  this: BaseSubsystem =>

  val controlPlane = LazyModule(new ControlPlane(sbus.control_bus.beatBytes))
  sbus.control_bus.toVariableWidthSlave(Some("ControlPlane")) {
    controlPlane.tlNode
  }
}

trait HasControlPlaneModuleImpl extends HasRocketTilesModuleImp {
  val outer: HasControlPlane

  outer.rocketTiles.zipWithIndex.foreach { case(tile, i) =>
    tile.module.dsid := outer.controlPlane.module.io.dsids(i.U)
  }
}