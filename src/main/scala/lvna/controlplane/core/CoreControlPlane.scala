package uncore.pard

import chisel3._
import chisel3.util._
import freechips.rocketchip.config._
import freechips.rocketchip.devices.debug.DMIIO

trait HasCoreIO { this: Bundle =>
  implicit val p: Parameters  // Want trait parameter ...
  val extReset = Output(Vec(p(NEntries), Bool()))
  val dsid = Output(Vec(p(NEntries), UInt(p(TagBits).W)))
  val debug = new DMIIO()
}


class CoreControlPlaneIO(implicit val p: Parameters)
  extends ControlPlaneIO
  with HasCoreIO


class CoreControlPlane(implicit p: Parameters)
  extends ControlPlane(new CoreControlPlaneIO, new CoreDetectLogic)('C', "PARDCoreCP") {
  // detect <> outer
  detect.io.extReset <> io.extReset
  detect.io.dsid <> io.dsid
  detect.io.debug <> io.debug
}
