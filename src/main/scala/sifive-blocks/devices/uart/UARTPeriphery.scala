// See LICENSE for license details.
package sifive.blocks.devices.uart

import Chisel._
import uncore.tilelink2._
import config.Field
import diplomacy.{LazyModule, LazyMultiIOModuleImp}
import rocketchip._

//case object PeripheryUARTKey extends Field[Seq[UARTParams]]

trait HasPeripheryUART extends HasSystemNetworks {
  val uartParams = Seq.tabulate(p(coreplex.NTiles)) { i => //p(PeripheryUARTKey)
    UARTParams(address = BigInt(0x1000L + i * 0x1000L))
  }
  val uarts = uartParams map { params =>
    val uart = LazyModule(new TLUART(peripheryBusBytes, params))
    uart.node := TLFragmenter(peripheryBusBytes, cacheBlockBytes)(peripheryBus.node)
    intBus.intnode := uart.intnode
    uart
  }
}

trait HasPeripheryUARTModuleImp extends LazyMultiIOModuleImp {
  val outer: HasPeripheryUART
  val io = IO(new Bundle {
    val uarts = Vec(outer.uartParams.size, new UARTPortIO)
  })
  (io.uarts zip outer.uarts).foreach { case (io, device) =>
    io <> device.module.io.port
  }
}
