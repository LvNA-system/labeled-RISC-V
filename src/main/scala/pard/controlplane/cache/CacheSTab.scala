package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._


class CacheSTabIO(implicit p: Parameters) extends STabIO {
  val lookup = Input(new LookupBundle)
  val update_tag = Input(new UpdateTagSelectedBundle)
  val dsids = Input(Vec(p(NEntries), UInt(p(TagBits).W)))
}


class CacheSTab(implicit p: Parameters) extends STab(new CacheSTabIO)
  with HasPipeline {
  /**
   * Return the index of the first dsid that
   * satisfies given predication.
   * If none, the last index is returned.
   */
  def matchId(check: UInt => Bool) = {
    val sel = io.dsids.map(check(_))
    val index = OHToUInt(PriorityEncoderOH(sel))
    Mux(sel.reduce(_ || _), index, (sel.size - 1).U)
  }

  val lookup_hit    = pipelined(io.lookup.hit, 1)
  val lookup_miss   = pipelined(io.lookup.miss, 1)
  val update_tag_en = pipelined(io.update_tag.enable, 1)
  val update_tag_we = pipelined(io.update_tag.write_enable, 1)
  val sel_old       = pipelined(matchId(_ === io.update_tag.old_dsid), 1)
  val sel_new       = pipelined(matchId(_ === io.update_tag.new_dsid), 1)
  val sel_lookup    = pipelined(matchId(_ === io.lookup.dsid && io.lookup.valid), 1)

  val total_update_en = lookup_hit || lookup_miss
  val capacity_update_en = (sel_old =/= sel_new) && (update_tag_en && (update_tag_we =/= 0.U))

  // Hit rate
  val win_hit_counters = RegInit(Vec(Seq.fill(p(NEntries)){ 0.U(32.W) }))
  val win_total_counters = RegInit(Vec(Seq.fill(p(NEntries)){ 0.U(32.W) }))

  // Field declarations
  // hit_counters
  makeField(0.U(32.W), lookup_hit) { vec =>
    vec(sel_lookup) := vec(sel_lookup) + 1.U
  }
  // total_counters
  makeField(0.U(32.W), lookup_hit || lookup_miss) { vec =>
    vec(sel_lookup) := vec(sel_lookup) - 1.U
  }
  // capacity_counters
  makeField(0.U(32.W), capacity_update_en) { vec =>
    vec(sel_old) := vec(sel_old) - 1.U
    vec(sel_new) := vec(sel_new) + 1.U
  }
  // win_hit_rate_in_percent
  makeField(0.U(32.W), lookup_miss || lookup_hit, NoSet) { vec =>
    val win_hit_counter = win_hit_counters(sel_lookup)
    val win_total_counter = win_total_counters(sel_lookup)
    val win_hit_rate_in_percent = vec(sel_lookup)
    when (win_total_counter === (1600 - 1).U) {
      win_hit_counter := 0.U
      win_total_counter := 0.U
      win_hit_rate_in_percent := Cat(0.U(4.W), win_hit_counter(31, 4))  // hit_counter / 16
    }
    .otherwise {
      win_total_counters(sel_lookup) := win_total_counters(sel_lookup) + 1.U
      when (lookup_hit) {
        win_hit_counters(sel_lookup) := win_hit_counters(sel_lookup) + 1.U
      }
    }
  }

  io.table.data    := makeRead(io.cmd.row, io.cmd.col)
  io.trigger_rdata := makeRead(io.trigger_row, io.trigger_metric)
}
