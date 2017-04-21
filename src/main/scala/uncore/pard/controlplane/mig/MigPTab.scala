package uncore.pard

import chisel3.util._
import chisel3.core._

import config._

/**
  * The common bundle to describe both read and write channel.
  * The default direction is in the view of ptab itself.
  */
class TagBundle(implicit p: Parameters) extends Bundle {
  val tag = Input(UInt(p(TagBits).W))
  val base = Output(UInt(p(AddrBits).W))
  val mask = Output(UInt(p(AddrBits).W))
  val matched = Output(Bool())
}

/**
  * MIG Control Plane Parameter Table
  */
class MigPTab(implicit p: Parameters) extends Module {
  private val sizeBits = p(BucketBits).size
  private val freqBits = p(BucketBits).freq
  private val posBits = 15  // Bit-width for position signals
  private val nRows = p(NEntries)

  val io = IO(new Bundle {
    // PRM interface
    val table = Flipped(new TableIO)
    val col = Input(UInt(posBits.W))
    val row = Input(UInt(posBits.W))
    val wdata = Input(UInt(p(DataBits).W))
    val wen = Input(Bool())
    // Control plane interface
    val l1enables = Output(Vec(nRows, Bool()))
    val buckets = Output(Vec(nRows, new BucketBundle))
    val dsids = Input(Vec(nRows, UInt(p(TagBits).W)))
    val rTag = new TagBundle
    val wTag = new TagBundle
  })

  val dsids   = RegNext(io.dsids, Vec(Seq.fill(nRows){ 0.U(p(TagBits).W) }))
  val bases   = RegInit(Vec(Seq.fill(nRows){ 0.U(p(AddrBits).W) }))
  val masks   = RegInit(Vec(Seq.fill(nRows){ 0.U(p(AddrBits).W) }))
  val enables = RegInit(Vec(Seq.fill(nRows){ true.B }))
  val sizes   = RegInit(Vec(Seq.fill(nRows){ 0.U(sizeBits.W) }))
  val freqs   = RegInit(Vec(Seq.fill(nRows){ 0.U(freqBits.W) }))
  val incs    = RegInit(Vec(Seq.fill(nRows){ 0.U(sizeBits.W) }))

  io.l1enables := enables

  (io.buckets zip sizes zip freqs zip incs).foreach { case (((bkt, size), freq), inc) =>
    bkt.size := size
    bkt.freq := freq
    bkt.inc := inc
  }

  // Tag matching
  List(io.rTag, io.wTag) foreach { tag =>
    val oneHot = dsids.map(_ === tag.tag)
    val index = OHToUInt(oneHot)
    tag.matched := oneHot.reduce(_ || _)
    tag.base := bases(index)
    tag.mask := masks(index)
  }

  val fields = List(bases, masks, enables, sizes, freqs, incs)

  // Write table
  fields.zipWithIndex.foreach { case (field, c) =>
    when (io.table.enable && io.wen && io.col === c.U) {
      field(io.row) := io.wdata
    }
  }

  // Read table
  io.table.data := MuxLookup(io.col, 0.U, fields.indices.map(_.U) zip fields.map(_(io.row)))
}
