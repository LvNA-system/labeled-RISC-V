// See LICENSE.SiFive for license details.

package freechips.rocketchip.amba.axi4

import Chisel._
import chisel3.core.{VecInit, WireInit}
import chisel3.util.IrrevocableIO
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.tilelink.LFSRNoiseMaker
import freechips.rocketchip.util.{GTimer, LatencyPipeIrrevocable}

// q is the probability to delay a request
class AXI4Delayer(q: Double, latency: Int = 0)(implicit p: Parameters) extends LazyModule
{
  val node = AXI4AdapterNode()
  require (0.0 <= q && q < 1)

  lazy val module = new LazyModuleImp(this) {
    def feed[T <: Data](sink: IrrevocableIO[T], source: IrrevocableIO[T], noise: T) {
      // irrevocable requires that we not lower valid
      val hold = RegInit(Bool(false))
      when (sink.valid)  { hold := Bool(true) }
      when (sink.fire()) { hold := Bool(false) }

      val allow = hold || UInt((q * 65535.0).toInt) <= LFSRNoiseMaker(16, source.valid)
      sink.valid := source.valid && allow
      source.ready := sink.ready && allow
      sink.bits := source.bits
      when (!sink.valid) { sink.bits := noise }
    }

    def anoise[T <: AXI4BundleA](bits: T) {
      bits.id    := LFSRNoiseMaker(bits.params.idBits)
      bits.addr  := LFSRNoiseMaker(bits.params.addrBits)
      bits.len   := LFSRNoiseMaker(bits.params.lenBits)
      bits.size  := LFSRNoiseMaker(bits.params.sizeBits)
      bits.burst := LFSRNoiseMaker(bits.params.burstBits)
      bits.lock  := LFSRNoiseMaker(bits.params.lockBits)
      bits.cache := LFSRNoiseMaker(bits.params.cacheBits)
      bits.prot  := LFSRNoiseMaker(bits.params.protBits)
      bits.qos   := LFSRNoiseMaker(bits.params.qosBits)
      if (bits.params.userBits > 0)
        bits.user.get := LFSRNoiseMaker(bits.params.userBits)
    }

    (node.in zip node.out) foreach { case ((in, _), (out, _)) =>
      val arnoise = Wire(in.ar.bits)
      val awnoise = Wire(in.aw.bits)
      val wnoise  = Wire(in.w .bits)
      val rnoise  = Wire(in.r .bits)
      val bnoise  = Wire(in.b .bits)

      anoise(arnoise)
      anoise(awnoise)

      wnoise.data := LFSRNoiseMaker(wnoise.params.dataBits)
      wnoise.strb := LFSRNoiseMaker(wnoise.params.dataBits/8)
      wnoise.last := LFSRNoiseMaker(1)(0)

      rnoise.id   := LFSRNoiseMaker(rnoise.params.idBits)
      rnoise.data := LFSRNoiseMaker(rnoise.params.dataBits)
      rnoise.resp := LFSRNoiseMaker(rnoise.params.respBits)
      rnoise.last := LFSRNoiseMaker(1)(0)
      if (rnoise.params.userBits > 0)
        rnoise.user.get := LFSRNoiseMaker(rnoise.params.userBits)

      bnoise.id   := LFSRNoiseMaker(bnoise.params.idBits)
      bnoise.resp := LFSRNoiseMaker(bnoise.params.respBits)
      if (bnoise.params.userBits > 0)
        bnoise.user.get := LFSRNoiseMaker(bnoise.params.userBits)

      feed(out.ar, LatencyPipeIrrevocable(in.ar, latency), arnoise)
      feed(out.aw, LatencyPipeIrrevocable(in.aw, latency), awnoise)
      feed(out.w,  in.w,   wnoise)
      feed(in.b,   out.b,  bnoise)
      feed(in.r,   out.r,  rnoise)
    }
  }
}

object AXI4Delayer
{
  def apply(q: Double, latency: Int = 0)(implicit p: Parameters): AXI4Node =
  {
    val axi4delay = LazyModule(new AXI4Delayer(q, latency))
    axi4delay.node
  }
}

class AXI4AmpDelayer(q: Double, latency: Int = 0)(implicit p: Parameters) extends LazyModule
{
  val node = AXI4AdapterNode()
  require (0.0 <= q && q < 1)

  val debug_en = false
  val scale_param = 3
  def debug(fmt: String, args: Bits*) = if (debug_en) {printf("delay %d: " + fmt + "\n", GTimer() +: args:_*)}

  lazy val module = new LazyModuleImp(this) {
    (node.in zip node.out) foreach {
      case ((in, _), (out, _)) =>
        val id_width = in.ar.bits.id.getWidth
        val timer = GTimer()
        val id_r_timers = RegInit(Vec(Seq.fill(1 << id_width){0.U(timer.getWidth.W)}))
        val id_b_timers = RegInit(Vec(Seq.fill(1 << id_width){0.U(timer.getWidth.W)}))

        out.ar := in.ar
        out.aw := in.aw
        out.w  := in.w
        in.r.bits := out.r.bits
        in.b.bits := out.b.bits

        def delay(dout: IrrevocableIO[AXI4BundleB], din: IrrevocableIO[AXI4BundleB], id: UInt) = {
          val counter = RegInit(0.U(32.W))
          val real_delay = RegInit(0.U(32.W))
          val idle :: delaying :: wait_fire :: Nil = Enum(UInt(), 3)
          val state = RegInit(idle)

          dout.ready := state === wait_fire && din.ready
          din.valid := state === wait_fire && dout.valid

          id_b_timers.foreach{i => when(state =/= delaying) {i := i + 1.U(timer.getWidth.W)}}

          when (state === idle) {
            when (dout.valid) {
              debug("idle fire id %d", id)
              real_delay := id_b_timers(id)
              counter := 0.U
              state := delaying
            }
          }.elsewhen(state === delaying) {
            counter := counter + 1.U
            when (counter === (real_delay << scale_param).asUInt()) {
              debug("delay end id %d", id)
              state := wait_fire
              counter := 0.U
            }
          }.elsewhen(state === wait_fire) {
            when (din.fire()) {
              state := idle
              debug("fire idle id %d", id)
            }
          }
        }

        def delayR(dout: IrrevocableIO[AXI4BundleR], din: IrrevocableIO[AXI4BundleR], id: UInt) = {
          val counter = RegInit(0.U(32.W))
          val real_delay = RegInit(0.U(32.W))
          val idle :: delaying :: wait_fire :: Nil = Enum(UInt(), 3)
          val state = RegInit(idle)

          dout.ready := state === wait_fire && din.ready
          din.valid := state === wait_fire && dout.valid

          id_r_timers.foreach{i => when(state =/= delaying) {i := i + 1.U(timer.getWidth.W)}}

          when (state === idle) {
            when (dout.valid) {
              debug("r idle fire id %d", id)
              real_delay := id_r_timers(id)
              counter := 0.U
              state := delaying
            }
          }.elsewhen(state === delaying) {
            counter := counter + 1.U
            debug("r real_delay %d", real_delay)
            when (counter === (real_delay << scale_param).asUInt()) {
              debug("r delay end id %d", id)
              state := wait_fire
              counter := 0.U
            }.otherwise{
              debug("r coutner %d", counter)
            }
          }.elsewhen(state === wait_fire) {
            when (din.fire() && din.bits.last) {
              state := idle
              debug("r fire idle id %d", id)
            }.elsewhen(din.fire()) {
              debug("r beat")
            }
          }
        }

        delay(out.b, in.b, out.b.bits.id)
        delayR(out.r, in.r, in.r.bits.id)

        when (out.ar.fire()) {
          debug("ar id %d get timestamp %d", out.ar.bits.id, timer)
          id_r_timers(out.ar.bits.id) := 0.U
        }

        when (out.aw.fire()) {
          debug("aw id %d get timestamp %d", out.aw.bits.id, timer)
          id_b_timers(out.aw.bits.id) := 0.U
        }
    }
  }
}

object AXI4AmpDelayer
{
  def apply(q: Double, latency: Int = 0)(implicit p: Parameters): AXI4Node =
  {
    val axi4delay = LazyModule(new AXI4AmpDelayer(q, latency))
    axi4delay.node
  }
}