// See LICENSE for license details.
package sifive.blocks.devices.gpio

import Chisel._
import cde.{Parameters, Field}
import diplomacy._
import uncore.tilelink2._
import rocketchip._

trait PeripheryGPIO extends HasPeripheryParameters {
  val peripheryBus: TLXbar
  val gpioConfig: GPIOConfig
  val gpio = LazyModule(new TLGPIO(p, gpioConfig))
  gpio.node := TLFragmenter(peripheryBusConfig.beatBytes, cacheBlockBytes)(peripheryBus.node)
  //intBus.intnode := gpio.intnode
}

trait PeripheryGPIOBundle {
  val gpioConfig: GPIOConfig
  val gpio = new GPIOPortIO(gpioConfig)
}

trait PeripheryGPIOModule {
  val gpioConfig: GPIOConfig
  val outer: PeripheryGPIO
  val io: PeripheryGPIOBundle
  io.gpio <> outer.gpio.module.io.port
}
