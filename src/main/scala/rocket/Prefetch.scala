package freechips.rocketchip.rocket

import Chisel._
import freechips.rocketchip.config.{Field, MemInitAddr, Parameters}
import freechips.rocketchip.tile._
import freechips.rocketchip.util._

trait PrefetchPolicy {
  def enablePrefetch = false
  def debug = false
}

class PrefetchPolicyIO extends Bundle {
  val in = new Bundle {
    val block = UInt(INPUT, width = 40)
    val fire = Bool(INPUT)
    }
  val out = Decoupled(UInt(INPUT, width = 40))
}

class NoPrefetcher(io: PrefetchPolicyIO) extends PrefetchPolicy {
  io.out.valid := Bool(false)
}

class NextLinePrefetcher(io: PrefetchPolicyIO) extends PrefetchPolicy {
  // generate next-line address
  val nextlineBlock = io.in.block + UInt(1)

  val isSameBlock = io.out.bits === nextlineBlock
  val isPrefetch = io.in.fire && !isSameBlock

  io.out.bits := RegEnable(nextlineBlock, isPrefetch)

  val reqValid = Reg(init = Bool(false))
  when (isPrefetch) { reqValid := Bool(true) }
  .elsewhen (io.out.fire()) { reqValid := Bool(false) }
  io.out.valid := reqValid
}

class PrefetcherIO(implicit p: Parameters) extends CoreBundle()(p) {
  val in = new Bundle {
    val bits = (new HellaCacheReq).flip
    val fire = Bool(INPUT)
    }
  val out = new HellaCacheIO
  val enablePrefetch = Bool(INPUT)
}

class Prefetcher(implicit p: Parameters) extends L1HellaCacheModule()(p) 
  with PrefetchPolicy {
  val io = new PrefetcherIO

  //def blockOffBits = lgCacheBlockBytes
  def addrToBlock(addr: UInt) : UInt = addr >> blockOffBits

  val isMMIO = io.in.bits.addr < p(MemInitAddr).U
  val isTypeOk = isRead(io.in.bits.cmd)

  val policyIO = Wire(new PrefetchPolicyIO())
  policyIO.in.block := addrToBlock(io.in.bits.addr)
  policyIO.in.fire := io.in.fire && !isMMIO && isTypeOk && io.enablePrefetch
  policyIO.out.ready := io.out.req.ready

  if (!enablePrefetch || tileParams.dcache.get.nMSHRs == 0) new NoPrefetcher(policyIO)
  else new NextLinePrefetcher(policyIO)

  io.out.req.valid := policyIO.out.valid
  val req = io.out.req.bits
  req.addr := policyIO.out.bits << blockOffBits

  // used as ID bits, since it will go through the arbiter
  req.tag := UInt(0)

  // prefetch command
  req.cmd := M_PFR

  // prefetch requests are always double-word
  req.typ := MT_D

  io.out.s1_kill := Bool(false)
  io.out.s2_kill := Bool(false)

  when (io.in.fire) {
    if (debug) printf("%d: demand block = %x, addr = %x, write = %d\n", GTimer(), addrToBlock(io.in.bits.addr), io.in.bits.addr, io.in.bits.cmd === M_XWR)
  }

  when (io.out.req.fire()) {
    if (debug) printf("%d: prefetch block = %x\n", GTimer(), addrToBlock(io.out.req.bits.addr))
  }
}
