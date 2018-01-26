package pard.cp

import Chisel._
import cde.{Parameters}

class BucketBundle(implicit p: Parameters) extends Bundle {
  val size = UInt(width = 32)
  val freq = UInt(width = 32)
  val inc = UInt(width = 32)

  override def cloneType = (new BucketBundle).asInstanceOf[this.type]
}


/** Only view the ReadyValidIO protocol */
class ReadyValidMonitor[+T <: Data](gen: T) extends Bundle {
  val valid = Bool().asInput
  val ready = Bool().asInput
  val bits  = gen.cloneType.asInput
}


class TokenBucket(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
	// we enable counting, only when dsid matches
	val rmatch = Bool().asInput
	val wmatch = Bool().asInput
    val read  = new ReadyValidMonitor(UInt(width = 32))
    val write = new ReadyValidMonitor(UInt(width = 32))
    val bucket = (new BucketBundle).asInput
    val enable = Bool().asOutput
  })

  val bucketSize = io.bucket.size
  val bucketFreq = io.bucket.freq
  val bucketInc = io.bucket.inc

  val nTokensNext = Wire(UInt())
  val nTokens = RegNext(
    Mux(nTokensNext < bucketSize, nTokensNext, bucketSize),
    bucketSize)


  val counterNext = Wire(UInt())
  val counter = RegNext(counterNext, UInt(0, 32))
  counterNext := Mux(counter >= bucketFreq, 1.U, counter + 1.U)

  val tokenAdd = Mux(counter === 1.U, bucketInc, 0.U)

  val bypass = bucketFreq === 0.U
  val channels = List(io.read, io.write)
  val channelMatches = List(io.rmatch, io.wmatch)
  val channelEnables = (channels zip channelMatches).map { case(ch, matches) => ch.valid && ch.ready && matches }

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
}
