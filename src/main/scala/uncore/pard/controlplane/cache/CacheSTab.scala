package uncore.pard

import chisel3._

import config._


class CacheSTab(implicit p: Parameters) extends Module {
  val io = IO(new TableBundle {
    val lookup = Input(new LookupBundle)
    val update_tag = Input(new UpdateTagSelectedBundle)
    val trigger_rdata = Output(UInt(p(DataBits).W))
    val trigger_metric = Input(Bool())  // FIXME
    val trigger_row = Input(UInt())  // FIXME
    val dsids = Input(Vec(p(NEntries), UInt(p(TagBits).W)))
  })

  val stab = Module(new cache_cp_stab(DSID_WIDTH = p(TagBits), CACHE_ASSOCIATIVITY = p(CacheAssoc), ENTRY_SIZE = 32, NUM_ENTRIES = p(NEntries)))

  stab.io.SYS_CLK := clock
  stab.io.DETECT_RST := reset
  stab.io.is_this_table := io.table.sel
  stab.io.col := io.cmd.col
  stab.io.row := io.cmd.row
  stab.io.wdata := io.cmd.wdata
  stab.io.wen := io.cmd.wen
  stab.io.trigger_row := io.trigger_row
  stab.io.trigger_metric := io.trigger_metric
  stab.io.DSid_storage := io.dsids.asTypeOf(UInt(stab.io.DSid_storage.getWidth.W))
  stab.io.lookup_valid_from_calc_to_stab := io.lookup.valid
  stab.io.lookup_DSid_from_calc_to_stab := io.lookup.dsid
  stab.io.lookup_hit_from_calc_to_stab := io.lookup.hit
  stab.io.lookup_miss_from_calc_to_stab := io.lookup.miss
  stab.io.update_tag_en_from_calc_to_stab := io.update_tag.enable
  stab.io.update_tag_we_from_calc_to_stab := io.update_tag.write_enable
  stab.io.update_tag_old_DSid_from_calc_to_stab := io.update_tag.old_dsid
  stab.io.update_tag_new_DSid_from_calc_to_stab := io.update_tag.new_dsid

  io.trigger_rdata := stab.io.trigger_rdata
  io.table.data := stab.io.rdata
}
