package uncore.pard

import chisel3._
import chisel3.util._


import freechips.rocketchip.config._


/**
 * Pipeline lookup, update_tag, and lru from outer to stab.
 * And select the first matched dsid
 */
class CacheCalc(implicit p: Parameters) extends Module
  with HasPipeline {
  val io = IO(new Bundle {
    val from_outer = new Bundle {
      val lookup = Input(new LookupBundle)
      val update_tag = Input(new UpdateTagRawBundle)
    }
    val to_stab = new Bundle {
      val lookup = Output(new LookupBundle)
      val update_tag = Output(new UpdateTagSelectedBundle)
    }
  })

  val outer = io.from_outer
  val stab  = io.to_stab

  val old_dsids = pipelined(outer.update_tag.old_dsids, 1)
  val new_dsids = pipelined(outer.update_tag.new_dsids, 2)
  val en_middle = pipelined(outer.update_tag.enable,       2)
  val we_middle = pipelined(outer.update_tag.write_enable, 2)

  // Find the first matched
  val enables = (0 until we_middle.getWidth).map(we_middle(_)).map(_ && en_middle)
  // Only the first matched (from left to right) will be valid
  val oneHot = (enables.scanLeft(true.B)(_ && !_).init zip enables).map {
    case (filtered, origin) => filtered && origin
  }
  val sel = OHToUInt(oneHot)

  // Pipeline other signals and rest levels
  stab.lookup.valid            := pipelined(outer.lookup.valid, 3)
  stab.lookup.dsid             := pipelined(outer.lookup.dsid,  3)
  stab.lookup.hit              := pipelined(outer.lookup.hit,   2)
  stab.lookup.miss             := pipelined(outer.lookup.miss,  2)
  stab.update_tag.enable       := pipelined(en_middle,          1)
  stab.update_tag.write_enable := pipelined(we_middle,          1)
  stab.update_tag.old_dsid     := pipelined(old_dsids(sel),     1)
  stab.update_tag.new_dsid     := pipelined(new_dsids(sel),     1)
}
