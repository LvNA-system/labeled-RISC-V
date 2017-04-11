// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import config._
import junctions._
import rocketchip._

import sifive.blocks.devices.uart._

class PARDSimTop(implicit p: Parameters) extends ExampleRocketTop
    with HasPeripheryUART

class PARDSimTopBundle[+L <: PARDSimTop](_outer: L) extends ExampleRocketTopBundle(_outer)
    with HasPeripheryUARTBundle

class PARDSimTopModule[+L <: PARDSimTop, +B <: PARDSimTopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)
    with HasPeripheryUARTModule

class PARDFPGATop(implicit p: Parameters) extends ExampleRocketTop

class PARDFPGATopBundle[+L <: PARDFPGATop](_outer: L) extends ExampleRocketTopBundle(_outer)

class PARDFPGATopModule[+L <: PARDFPGATop, +B <: PARDFPGATopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)

