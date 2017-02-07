// See LICENSE for license details.
package sifive.blocks.devices.uart

import Chisel._
import config._
import diplomacy._
import uncore.tilelink2._
import rocketchip._

trait PeripheryUART {
  this: TopNetwork {
    val uartConfigs: Seq[UARTConfig]
  } =>
  val uartDevices = uartConfigs.zipWithIndex.map { case (c, i) =>
    val uart = LazyModule(new UART(c) { override lazy val valName = Some(s"uart$i") } )
    uart.node := TLFragmenter(peripheryBusConfig.beatBytes, cacheBlockBytes)(peripheryBus.node)
    intBus.intnode := uart.intnode
    uart
  }
}

trait PeripheryUARTBundle {
  this: { val uartConfigs: Seq[UARTConfig] } =>
  val uarts = Vec(uartConfigs.size, new UARTPortIO)
}

trait PeripheryUARTModule {
  this: TopNetworkModule {
    val outer: PeripheryUART
    val io: PeripheryUARTBundle
  } =>
  (io.uarts zip outer.uartDevices).foreach { case (io, device) =>
    io <> device.module.io.port
  }
}
