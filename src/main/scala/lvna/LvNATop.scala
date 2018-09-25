// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import lvna.{HasControlPlaneModuleImpl, HasControlPlane}
import sifive.blocks.devices.uart._

class LvNAEmuTop(implicit p: Parameters) extends ExampleRocketSystem
    with HasPeripheryUART
    with HasControlPlane
{
  override lazy val module = new LvNAEmuTopModule(this)
}

class LvNAEmuTopModule[+L <: LvNAEmuTop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasPeripheryUARTModuleImp
    with HasControlPlaneModuleImpl

class LvNAFPGATop(implicit p: Parameters) extends ExampleRocketSystem
    with HasControlPlane
{
  override lazy val module = new LvNAFPGATopModule(this)
}

class LvNAFPGATopModule[+L <: LvNAFPGATop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasControlPlaneModuleImpl

class LvNAFPGATopAHB(implicit p: Parameters) extends ExampleRocketSystemAHB

class LvNAFPGATopAHBModule[+L <: LvNAFPGATopAHB](_outer: L) extends ExampleRocketSystemModuleAHBImp(_outer)

