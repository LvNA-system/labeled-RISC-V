package coreplex

import Chisel._
import cde.{Parameters, Field}
import uncore.tilelink._
import uncore.devices.{NTiles}
import rocketchip.{ExtMemSize}

class AddressMapper(implicit p: Parameters) extends TLModule()(p) {
  val io = IO(new Bundle {
    val in = Vec(p(NMemoryChannels), new ClientUncachedTileLinkIO).flip
    val out = Vec(p(NMemoryChannels), new ClientUncachedTileLinkIO)
  })

  val size = p(ExtMemSize) / p(NTiles)
  val bases = Vec(0.U +: Seq.tabulate(p(NTiles)) { i => (0x80000000L + size * i).U >> p(CacheBlockOffsetBits) })

  (io.in zip io.out) foreach { case (in, out) =>
    out <> in
    out.acquire.bits.addr_block := (in.acquire.bits.addr_block & (size - 1).U) | bases(in.acquire.bits.dsid)
    when (in.acquire.fire()) {
//      printf("addr = %x, addr_map = %x\n", in.acquire.bits.full_addr(), out.acquire.bits.full_addr())
      assert(in.acquire.bits.dsid === UInt(1) || in.acquire.bits.dsid === UInt(2))
    }
  }
}
