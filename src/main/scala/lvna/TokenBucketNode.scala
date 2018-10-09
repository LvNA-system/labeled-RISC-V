package lvna

import chisel3._
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink._
import uncore.pard.{BucketBundle, TokenBucket}

class TokenBucketNode(implicit p: Parameters) extends LazyModule {
  val node = TLIdentityNode()
  lazy val module = new TokenBucketNodeImp(this)
}

class TokenBucketNodeImp(outer: TokenBucketNode) extends LazyModuleImp(outer) {
  val (bundleIn, _) = outer.node.in.unzip
  val (bundleOut, _) = outer.node.out.unzip

  val tokenBucket = Module(new TokenBucket())
  val read = tokenBucket.io.read
  val write = tokenBucket.io.write
  val param = tokenBucket.io.bucket
  val enable = tokenBucket.io.enable

  val bucketParam = IO(Input(new BucketBundle))
  param := bucketParam

  // require(bundleIn.size == 1, s"[TokenBucket] Only expect one link for a hart, current link count is ${bundleIn.size}")
  val (in, out) = (bundleIn zip bundleOut).head
  out.a.valid := in.a.valid && enable
  out.c.valid := in.c.valid && enable

  val (op_a, op_c) = (in.a.bits.opcode, in.c.bits.opcode)
  val (size_a, size_c) = (in.a.bits.size, in.c.bits.size)

  read.ready := out.a.ready
  read.valid := in.a.valid && (op_a === TLMessages.Get || op_a === TLMessages.AcquireBlock)
  read.bits := size_a

  // Both channel A and channel C can write data.
  // We give channel C a higher priority.
  val is_a_write = in.a.valid && (op_a === TLMessages.PutFullData || op_a === TLMessages.PutPartialData)
  val is_c_write = in.c.valid && op_c === TLMessages.ReleaseData
  write.ready := Mux(is_c_write, out.c.ready, out.a.ready)
  write.valid := is_c_write || is_a_write
  write.bits := Mux(is_c_write, size_c, size_a)
}
