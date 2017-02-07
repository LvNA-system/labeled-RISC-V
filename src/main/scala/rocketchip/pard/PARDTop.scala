// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import config._
import junctions._
import rocketchip._

import sifive.blocks.devices.uart._

trait UARTConfigs {
  val uartConfigs = List(UARTConfig(address = BigInt(0x60000000L)))
}

abstract class PARDTop(implicit p: Parameters) extends BaseTop
    with PeripheryBootROM
    with PeripheryDebug
    with PeripheryCounter
    with HardwiredResetVector
    with PeripheryExtInterrupts
    with PeripheryMasterAXI4Mem
    with PeripherySlaveAXI4
    with MultiClockRocketPlexMaster
    {
      override lazy val module = new PARDTopModule(this, () => new PARDTopBundle(this))
      {
        coreplex.module.io.tcrs foreach { tcr =>
          tcr.clock := io.coreclk
          tcr.reset := io.corerst
        }
      }
    }

class PARDTopBundle[+L <: PARDTop](_outer: L) extends BaseTopBundle(_outer)
    with PeripheryExtInterruptsBundle
    with PeripheryMasterAXI4MemBundle
    with PeripherySlaveAXI4Bundle
    with PeripheryBootROMBundle
    with PeripheryDebugBundle
    with PeripheryCounterBundle
    with HardwiredResetVectorBundle
    with MultiClockRocketPlexMasterBundle
    {
      val coreclk = Clock(INPUT)
      val corerst= Bool(INPUT)
    }

class PARDTopModule[+L <: PARDTop, +B <: PARDTopBundle[L]](_outer: L, _io: () => B) extends BaseTopModule(_outer, _io)
    with PeripheryExtInterruptsModule
    with PeripheryMasterAXI4MemModule
    with PeripherySlaveAXI4Module
    with PeripheryBootROMModule
    with PeripheryDebugModule
    with PeripheryCounterModule
    with HardwiredResetVectorModule
    with MultiClockRocketPlexMasterModule



class PARDSimTop(implicit p: Parameters) extends PARDTop
    with UARTConfigs
    with PeripheryUART

class PARDSimTopBundle[+L <: PARDSimTop](_outer: L) extends PARDTopBundle(_outer)
    with UARTConfigs
    with PeripheryUARTBundle

class PARDSimTopModule[+L <: PARDSimTop, +B <: PARDSimTopBundle[L]](_outer: L, _io: () => B) extends PARDTopModule(_outer, _io)
    with UARTConfigs
    with PeripheryUARTModule


class PARDFPGATop(implicit p: Parameters) extends PARDTop
    with PeripheryMasterAXI4MMIO

class PARDFPGATopBundle[+L <: PARDFPGATop](_outer: L) extends PARDTopBundle(_outer)
    with PeripheryMasterAXI4MMIOBundle

class PARDFPGATopModule[+L <: PARDFPGATop, +B <: PARDFPGATopBundle[L]](_outer: L, _io: () => B) extends PARDTopModule(_outer, _io)
    with PeripheryMasterAXI4MMIOModule
