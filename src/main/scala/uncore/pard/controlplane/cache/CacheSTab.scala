package uncore.pard

import chisel3._
import chisel3.util._
import scala.collection.mutable.ListBuffer

import config._


class CacheSTab(implicit p: Parameters) extends Module
  with HasPipeline {
  val io = IO(new TableBundle {
    val lookup = Input(new LookupBundle)
    val update_tag = Input(new UpdateTagSelectedBundle)
    val trigger_rdata = Output(UInt(p(DataBits).W))  // FIXME
    val trigger_metric = Input(Bool())  // FIXME
    val trigger_row = Input(UInt())  // FIXME
    val dsids = Input(Vec(p(NEntries), UInt(p(TagBits).W)))
  })

  // Prepare inputs
  val dsids = io.dsids

  /**
   * Return the index of the first dsid that
   * satisfies given predication.
   * If none, the last index is returned.
   */
  def matchId(check: UInt => Bool) = {
    val sel = dsids.map(check(_))
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

  val fields = ListBuffer[Vec[_]]()
  var readGenerated = false
  def makeField[T >: Bool <: UInt](gen: T, update_en: Bool)(update_block: Vec[T] => Unit) = {
    require(!readGenerated, "Generate read ports before all fields declared!")
    val field = RegInit(Vec(Seq.fill(p(NEntries)) {
      0.U(gen.getWidth.W).asTypeOf(gen)
    }))
    when (io.cmd.wen && io.table.sel && (io.cmd.col === fields.size.U)) {
      field(io.cmd.row) := io.cmd.wdata
    } .elsewhen (update_en) {
      update_block.apply(field)
    }
    fields += field
    field
  }
  
  def makeRead() = {
    readGenerated = true
    io.table.data := MuxLookup(io.cmd.col, 0.U,
      fields.zipWithIndex.map { case (field: Vec[_], i) =>
        nReadPorts += 1
        (i.U, field(io.cmd.row))
      })
  }

  val total_update_en = lookup_hit || lookup_miss
  val capacity_update_en = (sel_old =/= sel_new) && (update_tag_en && (update_tag_we =/= 0.U))

  // Field declarations
  val hit_counters = makeField(UInt(32.W), lookup_hit) { vec =>
    vec(sel_lookup) := vec(sel_lookup) + 1.U
  }
  val total_counters = makeField(UInt(32.W), lookup_hit || lookup_miss) { vec =>
    vec(sel_lookup) := vec(sel_lookup) - 1.U
  }
  val capacity_counters = makeField(UInt(32.W), capacity_update_en) { vec =>
    vec(sel_old) := vec(sel_old) - 1.U
    vec(sel_new) := vec(sel_new) + 1.U
  }

  makeRead()
}
