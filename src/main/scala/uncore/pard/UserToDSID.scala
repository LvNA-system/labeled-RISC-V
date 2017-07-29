package uncore.pard

import chisel3._
import config._
import diplomacy._
import uncore.axi4._

/**
  * As axi4 user bits is used for other purposes inside rocket-chip,
  * this module bypasses user bits' data to a in-house axi4 dsid bits.
  */
class UserToDSID(implicit p: Parameters) extends LazyModule {
  val node = AXI4AdapterNode(
    masterFn = { mp => mp.copy(dsidBits = mp.userBits) },
    slaveFn = { sp => sp }
  )

  lazy val module = new LazyModuleImp(this) {
    val io = new Bundle {
      val in = node.bundleIn
      val out = node.bundleOut
    }

    (io.in zip io.out) foreach { case (in, out) =>
      out <> in
      out.ar.bits.dsid.get := in.ar.bits.user.get
      out.aw.bits.dsid.get := in.aw.bits.user.get
    }
  }
}

object UserToDSID {
  def apply(axi: AXI4BlindInputNode)(implicit p: Parameters) = {
    val cross = LazyModule(new UserToDSID)
    cross.node := axi
    cross.node
  }
}
