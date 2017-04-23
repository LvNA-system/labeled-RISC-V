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
  common.io.ptab <> ptab.io.table
  common.io.cmd  <> ptab.io.cmd

  // ptab <> outer
  ptab.io.extReset <> io.extReset
  ptab.io.dsid     <> io.dsid
}
