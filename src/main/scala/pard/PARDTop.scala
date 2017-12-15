// See LICENSE for license details.

package rocketchip

import Chisel._
import cde.{Parameters, Field}
import junctions._
import coreplex._
import rocketchip._

import sifive.blocks.devices.uart.{UARTConfig, PeripheryUART, PeripheryUARTBundle, PeripheryUARTModule, UARTGPIOPort}

trait PARDSimTopConfigs {
  val uartConfigs = List(
    UARTConfig(address = 0x60000000),
    UARTConfig(address = 0x60010000))
}

/** PARDSimTop */
class PARDSimTop[+C <: BaseCoreplex](_coreplex: Parameters => C)(implicit p: Parameters) extends ExampleTop(_coreplex)
    with PARDSimTopConfigs
    with PeripheryUART {
  override lazy val module = new PARDSimTopModule(this, () => new PARDSimTopBundle(this))
}

class PARDSimTopBundle[+L <: PARDSimTop[BaseCoreplex]](_outer: L) extends ExampleTopBundle(_outer)
    with PARDSimTopConfigs
    with PeripheryUARTBundle

class PARDSimTopModule[+L <: PARDSimTop[BaseCoreplex], +B <: PARDSimTopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)
    with PARDSimTopConfigs
    with PeripheryUARTModule


/** PARDFPGATop */
class PARDFPGATop[+C <: BaseCoreplex](_coreplex: Parameters => C)(implicit p: Parameters) extends ExampleTop(_coreplex)
    with PeripheryMasterAXI4MMIO {
  override lazy val module = new PARDFPGATopModule(this, () => new PARDFPGATopBundle(this))
}

class PARDFPGATopBundle[+L <: PARDFPGATop[BaseCoreplex]](_outer: L) extends ExampleTopBundle(_outer)
    with PeripheryMasterAXI4MMIOBundle

class PARDFPGATopModule[+L <: PARDFPGATop[BaseCoreplex], +B <: PARDFPGATopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)
    with PeripheryMasterAXI4MMIOModule
