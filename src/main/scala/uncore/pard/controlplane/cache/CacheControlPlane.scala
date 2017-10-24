package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._


class LookupBundle(implicit p: Parameters) extends Bundle {
  val valid = Bool()
  val dsid  = UInt(p(TagBits).W)
  val hit   = Bool()
  val miss  = Bool()
  override def cloneType = (new LookupBundle).asInstanceOf[this.type]
}


class UpdateTagRawBundle(implicit p: Parameters) extends Bundle {
  val enable       = Bool()
  val write_enable = UInt(p(CacheAssoc).W)
  val old_dsids    = Vec(p(CacheAssoc), UInt(p(TagBits).W))
  val new_dsids    = Vec(p(CacheAssoc), UInt(p(TagBits).W))
  override def cloneType = (new UpdateTagRawBundle).asInstanceOf[this.type]
}


class UpdateTagSelectedBundle(implicit p: Parameters) extends Bundle {
  val enable       = Bool()
  val write_enable = UInt(p(CacheAssoc).W)
  val old_dsid     = UInt(p(TagBits).W)
  val new_dsid     = UInt(p(TagBits).W)
  override def cloneType = (new UpdateTagSelectedBundle).asInstanceOf[this.type]
}


class LRUBundle(implicit p: Parameters) extends Bundle {
  val history_enable = Bool()
  val dsid_valid     = Bool()
  val dsid           = UInt(p(TagBits).W)
  override def cloneType = (new LRUBundle).asInstanceOf[this.type]
}


class CacheControlPlaneIO(implicit p: Parameters) extends ControlPlaneIO {
  val lookup = Input(new LookupBundle)
  val update_tag = Input(new UpdateTagRawBundle)
  val lru = Input(new LRUBundle)
  val waymask = Output(UInt(p(CacheAssoc).W))
}


class CacheControlPlane(implicit p: Parameters)
  extends ControlPlane(new CacheControlPlaneIO, new CacheDetectLogic)('$', "PARDCacheCP") {
  detect.io.lookup <> io.lookup
  detect.io.update_tag <> io.update_tag
  detect.io.lru <> io.lru
  detect.io.waymask <> io.waymask
}
