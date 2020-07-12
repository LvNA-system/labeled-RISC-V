// See LICENSE.SiFive for license details.

package freechips.rocketchip.system

import Chisel._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.subsystem._
import lvna._
import sifive.blocks.devices.uart._


class LvNABoomEmuTop(implicit p: Parameters) extends ExampleBoomSystem
    with HasPeripheryUART
  with HasBoomControlPlane
{
  override lazy val module = new LvNABoomEmuTopModule(this)
}

class LvNABoomEmuTopModule[+L <: LvNABoomEmuTop](_outer: L) extends ExampleBoomSystemModuleImp(_outer)
    with HasPeripheryUARTModuleImp
  with HasControlPlaneBoomModuleImpl

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
    with HasChiplinkPort
    with BindL2WayMask
{
  override lazy val module = new LvNAFPGATopModule(this)
}

class LvNAFPGATopModule[+L <: LvNAFPGATop](_outer: L) extends ExampleRocketSystemModuleImp(_outer)
    with HasControlPlaneModuleImpl
    with HasChiplinkPortImpl
    with BindL2WayMaskModuleImp

//class LvNAFPGATopAHB(implicit p: Parameters) extends ExampleRocketSystemAHB
//
//class LvNAFPGATopAHBModule[+L <: LvNAFPGATopAHB](_outer: L) extends ExampleRocketSystemModuleAHBImp(_outer)

class LvNABoomFPGATopModule[+L <: LvNABoomFPGATop](_outer: L) extends ExampleBoomSystemModuleImp(_outer)
  with HasControlPlaneBoomModuleImpl

class LvNABoomFPGATop(implicit p: Parameters) extends ExampleBoomSystem
    with HasBoomControlPlane
{
  override lazy val module = new LvNABoomFPGATopModule(this)
}

