package uncore.pard

import chisel3._
import chisel3.internal.sourceinfo.SourceInfo
import config._
import diplomacy._
import uncore.tilelink2._

case class ControlledCrossingNode() extends MixedNode(TLImp, TLImp)(
  dFn = { case (1, s) => s },
  uFn = { case (1, s) => s },
  numPO = 1 to 1,
  numPI = 1 to 1)

class ControlledCrossing(implicit p: Parameters) extends LazyModule
{
  val node = ControlledCrossingNode()

  val trafficEnable = Wire(true.B)

  lazy val module = new LazyModuleImp(this) {
    val io = new Bundle {
      val enable: Bool          = Input(trafficEnable)
      val in:     Vec[TLBundle] = node.bundleIn
      val out:    Vec[TLBundle] = node.bundleOut
    }

    (io.in zip io.out) foreach { case (in, out) =>
      out.a <> in.a
      in.d <> out.d
      in.b <> out.b
      out.c <> in.c
      out.e <> in.e
      // If we controlled Acquire's valid bit, it will not be accepted by the following nodes.
      // Therefore the Acquire's ready signal will stay inactive, and the following requests
      // from the master will be blocked.
      out.a.valid := in.a.valid && io.enable
    }
  }
}

object ControlledCrossing
{
  // applied to the TL source node; y.node := ControlledCrossing(x.node)
  def apply(x: TLOutwardNode)(implicit p: Parameters, sourceInfo: SourceInfo): ControlledCrossing = {
    val cross = LazyModule(new ControlledCrossing)
    cross.node := x
    cross
  }
}
