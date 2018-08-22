// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters

import sifive.blocks.devices.uart._

class LvNAEmuTop(implicit p: Parameters) extends ExampleRocketSystem
    with HasPeripheryUART

class LvNAEmuTopModule[+L <: LvNAEmuTop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasPeripheryUARTModuleImp

class LvNAFPGATop(implicit p: Parameters) extends ExampleRocketSystem

class LvNAFPGATopModule[+L <: LvNAFPGATop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)

class LvNAFPGATopAHB(implicit p: Parameters) extends ExampleRocketSystemAHB

class LvNAFPGATopAHBModule[+L <: LvNAFPGATopAHB](_outer: L) extends ExampleRocketSystemModuleAHBImp(_outer)

