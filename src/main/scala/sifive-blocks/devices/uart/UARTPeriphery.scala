// See LICENSE for license details.
package sifive.blocks.devices.uart

import Chisel._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.config.Field
import freechips.rocketchip.coreplex._
import freechips.rocketchip.diplomacy.{LazyModule, LazyModuleImp}

//case object PeripheryUARTKey extends Field[Seq[UARTParams]]

trait HasPeripheryUART extends HasPeripheryBus {
  val uartParams = Seq.tabulate(p(NTiles)) { i => //p(PeripheryUARTKey)
    UARTParams(address = BigInt(0x1000L + i * 0x1000L))
  }
  val uarts = uartParams map { params =>
    val uart = LazyModule(new TLUART(pbusBeatBytes, params))

    uart.node := pbus.toVariableWidthSlaves
    ibus.fromSync := uart.intnode
    uart
  }
}

trait HasPeripheryUARTModuleImp extends LazyModuleImp {
  val outer: HasPeripheryUART
  val io = IO(new Bundle {
    val uarts = Vec(outer.uartParams.size, new UARTPortIO)
  })
  (io.uarts zip outer.uarts).foreach { case (io, device) =>
    io <> device.module.io.port
  }
}
