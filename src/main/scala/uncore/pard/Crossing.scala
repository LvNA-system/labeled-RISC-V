package uncore.pard

import Chisel._
import chisel3.internal.sourceinfo.SourceInfo
import config._
import diplomacy._
import uncore.tilelink2._

case class ControlledCrossingNode() extends MixedNode(TLImp, TLImp)(
  dFn = { case (1, s) => s },
  uFn = { case (1, s) => s },
  numPO = 1 to 1,
  numPI = 1 to 1)

class ControlledCrossing()(implicit p: Parameters) extends LazyModule
{
  val node = ControlledCrossingNode()

  lazy val module = new LazyModuleImp(this) {
    val io = new Bundle {
      val in:  Vec[TLBundle] = node.bundleIn
      val out: Vec[TLBundle] = node.bundleOut
    }

    (io.in zip io.out) foreach { case (in, out) =>
      out.a <> in.a
      in.d <> out.d
      in.b <> out.b
      out.c <> in.c
      out.e <> in.e
      out.a.valid := Bool(false)
    }
  }
}

object ControlledCrossing
{
  // applied to the TL source node; y.node := ControlledCrossing(x.node)
  def apply(x: TLOutwardNode)(implicit p: Parameters, sourceInfo: SourceInfo): TLOutwardNode = {
    val cross = LazyModule(new ControlledCrossing())
    cross.node := x
    cross.node
  }
}