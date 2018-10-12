package uncore.pard

import chisel3._

import freechips.rocketchip.config._


class BucketBundle(implicit p: Parameters) extends Bundle {
  val size = UInt(p(BucketBits).size.W)
  val freq = UInt(p(BucketBits).freq.W)
  val inc = UInt(p(BucketBits).size.W)

  override def cloneType = (new BucketBundle).asInstanceOf[this.type]
}


/** Only view the ReadyValidIO protocol */
class ReadyValidMonitor[+T <: Data](gen: T) extends Bundle {
  val valid = Input(Bool())
  val ready = Input(Bool())
  val bits  = Input(gen.cloneType)
}


class TokenBucket(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val read  = new ReadyValidMonitor(UInt(p(BucketBits).data.W))
    val write = new ReadyValidMonitor(UInt(p(BucketBits).data.W))
    val bucket = Input(new BucketBundle)
    val enable = Output(Bool())
  })

  val bucketSize = io.bucket.size
  val bucketFreq = io.bucket.freq
  val bucketInc = io.bucket.inc
  // val bucketSize = 32.U
  // we bypass tokenBucket by default
  // val bucketFreq = 0.U
  // val bucketInc = 32.U

  val nTokensNext = Wire(UInt())
  val nTokens = RegNext(
    Mux(nTokensNext < bucketSize, nTokensNext, bucketSize),
    bucketSize)

  val counterNext = Wire(UInt())
  val counter = RegNext(counterNext, 0.U(p(BucketBits).freq.W))
  counterNext := Mux(counter >= bucketFreq, 1.U, counter + 1.U)

  val tokenAdd = Mux(counter === 1.U, bucketInc, 0.U)

  val bypass = bucketFreq === 0.U
  val channelEnables = List(io.read, io.write).map { ch => ch.valid && ch.ready }
  val rTokenSub :: wTokenSub :: _ = List(io.read, io.write).zip(channelEnables).map {
    case (ch, en) => Mux(en && !bypass, ch.bits, 0.U)
  }
  val tokenSub = rTokenSub + wTokenSub
  val consumeUp = (rTokenSub + wTokenSub) >= nTokens

  // Read is prior to write
  val rTokenSubReal = Mux(rTokenSub <= nTokens, rTokenSub, nTokens)
  val wTokenSubReal = Mux(!consumeUp, wTokenSub, nTokens - rTokenSubReal)
  nTokensNext := nTokens + tokenAdd - rTokenSubReal - wTokenSubReal

  // Throttle logic
  val threshold = RegInit(0.U)
  val enable = RegInit(false.B)
  when (channelEnables.reduce(_ || _) && consumeUp) {
    enable := false.B
    threshold := tokenSub
  } .elsewhen((nTokens >= threshold || nTokens === bucketSize) && nTokens =/= 0.U) {
    enable := true.B
    threshold := 0.U
  }
  io.enable := enable

  val logToken = false
  if (logToken) {
    when(counter === 1.U) {
      printf("tokenAdd inc %d nTokens %d, enable %d r(%d,%d), w(%d,%d)\n", bucketInc, RegNext(nTokens), RegNext(enable),
        RegNext(io.read.ready), RegNext(io.read.valid), RegNext(io.write.ready), RegNext(io.write.valid)
      )
    }
  }
}
