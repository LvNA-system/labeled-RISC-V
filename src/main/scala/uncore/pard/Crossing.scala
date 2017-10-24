package uncore.pard

import chisel3._
import chisel3.internal.sourceinfo.SourceInfo
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._

class ControlledCrossing(implicit p: Parameters) extends LazyModule
{
  val node = new IdentityNode(TLImp)()

  lazy val module = new LazyModuleImp(this) {
    val (bundleIn, _) = node.in.unzip
    val (bundleOut, _) = node.out.unzip

    val io = new Bundle {
      val enable = Input(Bool())
      val in = bundleIn
      val out = bundleOut
    }

    (io.in zip io.out) foreach { case (in, out) =>
      out.a <> in.a
      in.d <> out.d
      in.b <> out.b
      out.c <> in.c
      out.e <> in.e
      // If we controlled Acquire's valid bit, it will not be accepted by the following nodes.
      // Ready signal from the other side should also be masked. Then the master will not go
      // to the next Acquire.
      out.a.valid := in.a.valid && io.enable
      in.a.ready := out.a.ready && io.enable
    }
  }
}
