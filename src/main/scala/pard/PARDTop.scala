// See LICENSE.SiFive for license details.

package freechips.rocketchip.pard

import Chisel._
import freechips.rocketchip.config._
import freechips.rocketchip.subsystem._
import freechips.rocketchip.system._

import sifive.blocks.devices.uart._

class PARDSimTop(implicit p: Parameters) extends ExampleRocketSystem
    with HasPeripheryUART

class PARDSimTopModule[+L <: PARDSimTop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasPeripheryUARTModuleImp

class PARDFPGATop(implicit p: Parameters) extends ExampleRocketSystem

class PARDFPGATopModule[+L <: PARDFPGATop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)

