package uncore.pard

import chisel3.util._
import chisel3.core._

import freechips.rocketchip.config._

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

class MigPTabIO(implicit p: Parameters) extends PTabIO {
  private val nRows = p(NEntries)
  val l1enables = Output(Vec(nRows, Bool()))
  val buckets = Output(Vec(nRows, new BucketBundle))
  val dsids = Input(Vec(nRows, UInt(p(TagBits).W)))
  val rTag = new TagBundle
  val wTag = new TagBundle
}

/**
  * MIG Control Plane Parameter Table
  */
class MigPTab(implicit p: Parameters) extends PTab(new MigPTabIO) {
  private val sizeBits = p(BucketBits).size
  private val freqBits = p(BucketBits).freq
  private val nRows = p(NEntries)

  val dsids   = RegNext(io.dsids, Vec(nRows, 0.U(p(TagBits).W)))
  val bases   = makeField(0.U(p(AddrBits).W))()
  val masks   = makeField(0.U(p(AddrBits).W))()
  val enables = makeField(true.B)()
  val sizes   = makeField(0.U(sizeBits.W))()
  val freqs   = makeField(0.U(freqBits.W))()
  val incs    = makeField(0.U(sizeBits.W))()

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

  io.table.data := makeRead(io.cmd.row, io.cmd.col)
}
