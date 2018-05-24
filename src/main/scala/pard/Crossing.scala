package freechips.rocketchip.pard

import chisel3._
import chisel3.internal.sourceinfo.SourceInfo
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._

class ControlledCrossing(implicit p: Parameters) extends LazyModule {
  val node = new IdentityNode(TLImp)()
  lazy val module = new ControlledCrossingModule(this)
}

class ControlledCrossingIO(outer: ControlledCrossing)(implicit p: Parameters) extends Bundle {
  val enable = Input(Bool())
}

class ControlledCrossingModule(outer: ControlledCrossing) extends LazyModuleImp(outer) {
  val io = IO(new ControlledCrossingIO(outer))

  val (bundleIn, _) = outer.node.in.unzip
  val (bundleOut, _) = outer.node.out.unzip

  (bundleIn zip bundleOut) foreach { case (in, out) =>
    // Now IdentityNode automatically connects bundleIn to bundleOut
    // So we do need to connect each channel manually
    //
    // If we controlled Acquire's valid bit, it will not be accepted by the following nodes.
    // Ready signal from the other side should also be masked. Then the master will not go
    // to the next Acquire.
    out.a.valid := in.a.valid && io.enable
    in.a.ready := out.a.ready && io.enable
  }
}
