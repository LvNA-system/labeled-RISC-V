// See LICENSE.SiFive for license details.

package freechips.rocketchip.subsystem

import Chisel._
import chisel3.util.experimental.BoringUtils
import freechips.rocketchip.config._
import freechips.rocketchip.diplomacy.{LazyModuleImp, DTSTimebase}
import freechips.rocketchip.devices.tilelink.CanHavePeripheryCLINT

case object RTCPeriod extends Field[Int]

trait HasRTCModuleImp extends LazyModuleImp {
  val outer: BaseSubsystem with CanHavePeripheryCLINT
  private val pbusFreq = outer.p(PeripheryBusKey).frequency
  private val rtcFreq = outer.p(DTSTimebase)
  private val internalPeriod: BigInt = pbusFreq / rtcFreq

  val regInternalPeriod = Wire(UInt(32.W))
  BoringUtils.addSink(regInternalPeriod, "lvnaRTC")

  // check whether pbusFreq >= rtcFreq
  require(internalPeriod > 0)
  // check wehther the integer division is within 5% of the real division
  require((pbusFreq - rtcFreq * internalPeriod) * 100 / pbusFreq <= 5)

  // Use the static period to toggle the RTC
  //val (_, int_rtc_tick) = Counter(true.B, internalPeriod.toIn)
  val counter = RegInit(0.U(32.W))
  counter := counter + 1.U
  val int_rtc_tick = (counter + 1.U) === regInternalPeriod
  when (int_rtc_tick) {
    counter := 0.U
  }
  //val (_, int_rtc_tick) = Counter(true.B, p(RTCPeriod))

  outer.clintOpt.foreach { clint =>
    clint.module.io.rtcTick := int_rtc_tick
  }
}
