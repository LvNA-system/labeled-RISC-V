package uncore.pard

import chisel3._
import chisel3.util._

import config._

class TokenBucket(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val read  = new ReadyValidMonitor(UInt(p(BucketBits).data.W))
    val write = new ReadyValidMonitor(UInt(p(BucketBits).data.W))
    val bucket = Input(new BucketBundle)
    val enable = Output(Bool())
  })

  val sizeBits = p(BucketBits).size
  val freqBits = p(BucketBits).freq

  val nTokensNext = Wire(UInt(sizeBits.W))
  val nTokens = RegNext(
    Mux(nTokensNext < io.bucket.size, nTokensNext, io.bucket.size),
    io.bucket.size)

  val counterNext = Wire(UInt(freqBits.W))
  val counter = RegNext(counterNext, 0.U(freqBits.W))
  counterNext := Mux(counter >= io.bucket.freq, 1.U(freqBits.W), counter + 1.U)

  val tokenAdd = Mux(counter === 1.U(freqBits.W), io.bucket.inc, 0.U)

  val bypass = io.bucket.freq === 0.U(freqBits.W)
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
  val threshold = RegInit(0.U(sizeBits.W))
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
