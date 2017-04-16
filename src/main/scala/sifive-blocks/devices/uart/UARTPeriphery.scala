// See LICENSE for license details.
package sifive.blocks.devices.uart

import Chisel._
import uncore.tilelink2._
import config.Field
import diplomacy.LazyModule
import rocketchip._

//case object PeripheryUARTKey extends Field[Seq[UARTParams]]

trait HasPeripheryUART extends HasTopLevelNetworks {
  val uartParams = Seq(UARTParams(address = BigInt(0x1000L))) //p(PeripheryUARTKey)
  val uarts = uartParams map { params =>
    val uart = LazyModule(new TLUART(peripheryBusBytes, params))
    uart.node := TLFragmenter(peripheryBusBytes, cacheBlockBytes)(peripheryBus.node)
    intBus.intnode := uart.intnode
    uart
  }
}

trait HasPeripheryUARTBundle extends HasTopLevelNetworksBundle {
  val outer: HasPeripheryUART
  val uarts = Vec(outer.uartParams.size, new UARTPortIO)
}

trait HasPeripheryUARTModule extends HasTopLevelNetworksModule {
  val outer: HasPeripheryUART
  val io: HasPeripheryUARTBundle
  (io.uarts zip outer.uarts).foreach { case (io, device) =>
    io <> device.module.io.port
  }
}
