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
    UARTConfig(address = 0x60001000))
}

/** PARDSimTop */
class PARDSimTop(q: Parameters) extends ExampleTop(q)
    with PARDSimTopConfigs
    with PeripheryUART
    {
  override lazy val module = Module(new PARDSimTopModule(p, this, new PARDSimTopBundle(p)))
}

class PARDSimTopBundle(p: Parameters) extends ExampleTopBundle(p)
    with PARDSimTopConfigs
    with PeripheryUARTBundle

    class PARDSimTopModule[+L <: PARDSimTop, +B <: PARDSimTopBundle](p: Parameters, l: L, b: => B) extends ExampleTopModule(p, l, b)
    with PARDSimTopConfigs
    with PeripheryUARTModule


/** PARDFPGATop */
class PARDFPGATop(q: Parameters) extends ExampleTop(q)
    with PeripheryMasterMMIO {
  override lazy val module = Module(new PARDFPGATopModule(p, this, new PARDFPGATopBundle(p)))
}

class PARDFPGATopBundle(p: Parameters) extends ExampleTopBundle(p)
    with PeripheryMasterMMIOBundle

class PARDFPGATopModule[+L <: PARDFPGATop, +B <: PARDFPGATopBundle](p: Parameters, l: L, b: => B) extends ExampleTopModule(p, l, b)
    with PeripheryMasterMMIOModule
