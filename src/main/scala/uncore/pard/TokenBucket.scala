package uncore.pard

import chisel3._
import chisel3.util._

class TokenBucket(dataBits: Int, bucketSizeBits: Int, bucketFreqBits: Int) extends Module {
  val io = IO(new Bundle {
    val read  = new ReadyValidMonitor(UInt(dataBits.W))
    val write = new ReadyValidMonitor(UInt(dataBits.W))
    val bucket = Input(new BucketBundle(bucketSizeBits, bucketFreqBits))
    val enable = Output(Bool())
  })

  val nTokensNext = Wire(UInt(bucketSizeBits.W))
  val nTokens = RegNext(
    Mux(nTokensNext < io.bucket.size, nTokensNext, io.bucket.size),
    io.bucket.size)

  val counterNext = Wire(UInt(bucketFreqBits.W))
  val counter = RegNext(counterNext, 0.U(bucketFreqBits.W))
  counterNext := Mux(counter >= io.bucket.freq, 1.U(bucketFreqBits.W), counter + 1.U)

  val tokenAdd = Mux(counter === 1.U(bucketFreqBits.W), io.bucket.inc, 0.U)

  val bypass = io.bucket.freq === 0.U(bucketFreqBits.W)
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
  val threshold = RegInit(0.U(bucketSizeBits.W))
  val enable = RegInit(false.B)
  when (channelEnables.reduce(_ || _) && consumeUp) {
    enable := false.B
    threshold := tokenSub
  } .elsewhen((nTokens >= threshold || nTokens === io.bucket.size) && nTokens =/= 0.U) {
    enable := true.B
    threshold := 0.U
  }
  io.enable := enable
}

object TokenBucket extends App {
  Driver.execute(args, () => new TokenBucket(32, 32, 32))
}
