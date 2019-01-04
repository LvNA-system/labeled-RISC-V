// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import lvna.{BindL2WayMask, BindL2WayMaskModuleImp, HasControlPlane, HasControlPlaneModuleImpl}
import sifive.blocks.devices.uart._


class LvNAEmuTop(implicit p: Parameters) extends ExampleBoomSystem
    with HasPeripheryUART
{
  override lazy val module = new LvNAEmuTopModule(this)
}

class LvNAEmuTopModule[+L <: LvNAEmuTop](_outer: L) extends ExampleBoomSystemModuleImp(_outer)
    with HasPeripheryUARTModuleImp

//class LvNAEmuTop(implicit p: Parameters) extends ExampleRocketSystem
//    with HasPeripheryUART
//    with HasControlPlane
//    with BindL2WayMask
//{
//  override lazy val module = new LvNAEmuTopModule(this)
//}
//
//class LvNAEmuTopModule[+L <: LvNAEmuTop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
//    with HasPeripheryUARTModuleImp
//    with HasControlPlaneModuleImpl
//    with BindL2WayMaskModuleImp


class LvNAFPGATop(implicit p: Parameters) extends ExampleRocketSystem
    with HasControlPlane
    with BindL2WayMask
{
  override lazy val module = new LvNAFPGATopModule(this)
}

class LvNAFPGATopModule[+L <: LvNAFPGATop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasControlPlaneModuleImpl
    with BindL2WayMaskModuleImp

class LvNAFPGATopAHB(implicit p: Parameters) extends ExampleRocketSystemAHB

class LvNAFPGATopAHBModule[+L <: LvNAFPGATopAHB](_outer: L) extends ExampleRocketSystemModuleAHBImp(_outer)

