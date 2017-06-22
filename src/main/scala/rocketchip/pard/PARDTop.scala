// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import config._
import junctions._
import rocketchip._

import sifive.blocks.devices.uart._

class PARDSimTop(implicit p: Parameters) extends ExampleRocketTop
    with HasPeripheryUART

class PARDSimTopModule[+L <: PARDSimTop](_outer: L) extends ExampleRocketTopModule(_outer)
    with HasPeripheryUARTModuleImp

class PARDFPGATop(implicit p: Parameters) extends ExampleRocketTop

class PARDFPGATopModule[+L <: PARDFPGATop](_outer: L) extends ExampleRocketTopModule(_outer)

