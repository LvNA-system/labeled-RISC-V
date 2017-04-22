package uncore.pard

import chisel3._
import chisel3.util._

import config._


class CoreDetectLogicIO(implicit val p: Parameters)
  extends DetectLogicIO
  with HasCoreIO


class CoreDetectLogic(implicit p: Parameters)
  extends DetectLogic(new CoreDetectLogicIO) {

  val ptab = Module(new CorePTab)

  // TODO Abstract this common part
  // detect <> ptab
  common.io.ptab  <> ptab.io.table
  common.io.col   <> ptab.io.col
  common.io.row   <> ptab.io.row
  common.io.wdata <> ptab.io.wdata
  common.io.wen   <> ptab.io.wen

  // ptab <> outer
  ptab.io.extReset <> io.extReset
  ptab.io.dsid     <> io.dsid
}
