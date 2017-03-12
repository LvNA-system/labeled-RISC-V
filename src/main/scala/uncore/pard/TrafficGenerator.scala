package uncore.pard

import chisel3._
import chisel3.util._
import diplomacy._
import config._
import uncore.tilelink2._

/** This module is a customized version of `TLFuzzer'.
  * It generates endless, randomized, and always-valid Get requests,
  * in order to disturb memory bandwidth in real hardware enviroment,
  * without side effects.
  * @param dsid is the tag that PARD will use to recognize this unit.
  * @param base is the start value of the randomized address.
  * @param mask is the mask of the address space.
  * @param inFlight is the number of requests that can be sent but not get responsed.
  * @param noiseMaker is a function that supplies a random UInt of a given width every time inc is true
  */
class TrafficGenerator(
    dsid: Int, base: String, mask: String, inFlight: Int = 32,
    noiseMaker: (Int, Bool, Int) => UInt = {
      (wide: Int, increment: Bool, abs_values: Int) =>
         LFSRNoiseMaker(wide=wide, increment=increment)
    }
  )(implicit p: Parameters) extends LazyModule
{
  val node = TLClientNode(TLClientParameters(sourceId = IdRange(0, inFlight)))

  lazy val module = new LazyModuleImp(this) {
    val io = new Bundle {
      val out = node.bundleOut
      val enable = Input(Bool())
    }

    val out = io.out(0)
    val edge = node.edgesOut(0)

    // Extract useful parameters from the TL edge
    val addressBits  = log2Up(edge.manager.maxAddress + 1)
    val sizeBits     = edge.bundle.sizeBits

    // Progress within each operation
    val a = out.a.bits
    val (a_first, a_last, req_done) = edge.firstlast(out.a)

    val d = out.d.bits
    val (d_first, d_last, resp_done) = edge.firstlast(out.d)

    // Source ID generation
    val idMap = Module(new IDMapGenerator(inFlight))
    val alloc = Queue.irrevocable(idMap.io.alloc, 1, pipe = true)
    val src = alloc.bits
    alloc.ready := req_done
    idMap.io.free.valid := resp_done
    idMap.io.free.bits := out.d.bits.source

    // Increment random number generation for the following subfields
    val inc = Wire(Bool())
    val size = noiseMaker(sizeBits, inc, 0)
    val addr = base.U | ((noiseMaker(addressBits, inc, 2) & ~UIntToOH1(size, addressBits)) & mask.U)

    // Actually generate specific TL messages when it is legal to do so
    val (getLegal,  getBits)  = edge.Get(src, addr, size)
    val addrLegal = edge.manager.containsSafe(addr)
    val legal = addrLegal && getLegal

    // Wire both the used and un-used channel signals
    out.a.valid := legal && alloc.valid && io.enable
    out.a.bits  := getBits
    out.a.bits.dsid := dsid.U(16.W)
    out.b.ready := true.B
    out.c.valid := false.B
    out.d.ready := true.B
    out.e.valid := false.B

    // Increment the various progress-tracking states
    inc := !legal || req_done
  }
}

object TrafficGenerator {
  def apply(dsid: Int, base: String, mask: String)(implicit p: Parameters) = {
    LazyModule(new TrafficGenerator(dsid, base, mask))
  }
}

trait HasTrafficGenerator extends coreplex.HasCoreplexParameters {
  val l1tol2: TLXbar
  // TODO Make it configured
  val trafficGenerator = TrafficGenerator(nTiles + 1, "h80000000", "h3ffffff")
  l1tol2.node := trafficGenerator.node
}

trait HasTrafficGeneratorBundle {
  val outer: HasTrafficGenerator
  val trafficGeneratorEnable = Input(Bool())
}

trait HasTrafficGeneratorModule {
  val outer: HasTrafficGenerator
  val io: HasTrafficGeneratorBundle
  outer.trafficGenerator.module.io.enable := io.trafficGeneratorEnable
}
