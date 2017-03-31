package uncore.pard

import chisel3.util._
import chisel3.core._

/**
  * The common bundle to describe both read and write channel.
  * The default direction is in the view of ptab itself.
  */
class TagBundle(tagWidth: Int, dataWidth: Int) extends Bundle {
  val tag = Input(UInt(tagWidth.W))
  val base = Output(UInt(dataWidth.W))
  val mask = Output(UInt(dataWidth.W))
  val matched = Output(Bool())
}

/**
  * MIG Control Plane Parameter Table
  */
class MigPTab(nRows: Int, tagWidth: Int, addrBits: Int, sizeBits: Int, freqBits: Int) extends Module {
  val dataBits = 64
  val posBits = 15  // Bit-width for position signals
  val io = IO(new Bundle {
    // PRM interface
    val isThisTable = Input(Bool())
    val col = Input(UInt(posBits.W))
    val row = Input(UInt(posBits.W))
    val wdata = Input(UInt(dataBits.W))
    val wen = Input(Bool())
    val rdata = Output(UInt(dataBits.W))
    // Control plane interface
    val l1enables = Output(Vec(nRows, Bool()))
    val buckets = Output(Vec(nRows, new BucketBundle(sizeBits, freqBits)))
    val dsids = Input(Vec(nRows, UInt(tagWidth.W)))
    val rTag = new TagBundle(tagWidth, addrBits)
    val wTag = new TagBundle(tagWidth, addrBits)
  })

  val dsids   = RegNext(io.dsids, Vec(Seq.fill(nRows){ 0.U(tagWidth.W) }))
  val bases   = RegInit(Vec(Seq.fill(nRows){ 0.U(addrBits.W) }))
  val masks   = RegInit(Vec(Seq.fill(nRows){ 0.U(addrBits.W) }))
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
    when (io.isThisTable && io.wen && io.col === c.U) {
      field(io.row) := io.wdata
    }
  }

  // Read table
  io.rdata := MuxLookup(io.col, 0.U, fields.indices.map(_.U) zip fields.map(_(io.row)))
}