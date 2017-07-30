package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CoreDetectLogicIO(implicit val p: Parameters)
  extends DetectLogicIO
  with HasCoreIO


class CoreDetectLogic(implicit p: Parameters)
  extends DetectLogic(new CoreDetectLogicIO) {
  val ptab = createPTab(new CorePTab)
  ptab.io.extReset <> io.extReset
  ptab.io.dsid     <> io.dsid
  ptab.io.debug    <> io.debug
}
