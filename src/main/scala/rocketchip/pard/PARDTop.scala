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
    with PeripheryExtInterrupts
    with PeripheryMasterAXI4Mem
    with PeripherySlaveAXI4
    with PeripheryBootROM
    with PeripheryDebug
    with PeripheryCounter
    with HardwiredResetVector
    {
      override lazy val module = new PARDTopModule(this, () => new PARDTopBundle(this))
    }

class PARDTopBundle[+L <: PARDTop](_outer: L) extends BaseTopBundle(_outer)
    with PeripheryExtInterruptsBundle
    with PeripheryMasterAXI4MemBundle
    with PeripherySlaveAXI4Bundle
    with PeripheryBootROMBundle
    with PeripheryDebugBundle
    with PeripheryCounterBundle
    with HardwiredResetVectorBundle

class PARDTopModule[+L <: PARDTop, +B <: PARDTopBundle[L]](_outer: L, _io: () => B) extends BaseTopModule(_outer, _io)
    with PeripheryExtInterruptsModule
    with PeripheryMasterAXI4MemModule
    with PeripherySlaveAXI4Module
    with PeripheryBootROMModule
    with PeripheryDebugModule
    with PeripheryCounterModule
    with HardwiredResetVectorModule



class PARDSimTop(implicit p: Parameters) extends PARDTop
    with UARTConfigs
    with PeripheryUART
    with MultiClockRocketPlexMaster
    {
      override lazy val module = new PARDSimTopModule(this, () => new PARDSimTopBundle(this))
      {
        coreplex.module.io.tcrs foreach { tcr =>
          tcr.clock := io.coreclk
          tcr.reset := io.corerst
        }
      }
    }

class PARDSimTopBundle[+L <: PARDSimTop](_outer: L) extends PARDTopBundle(_outer)
    with UARTConfigs
    with PeripheryUARTBundle
    with MultiClockRocketPlexMasterBundle
    {
      val coreclk = Clock(INPUT)
      val corerst= Bool(INPUT)
    }

class PARDSimTopModule[+L <: PARDSimTop, +B <: PARDSimTopBundle[L]](_outer: L, _io: () => B) extends PARDTopModule(_outer, _io)
    with UARTConfigs
    with PeripheryUARTModule
    with MultiClockRocketPlexMasterModule


class PARDFPGATop(implicit p: Parameters) extends PARDTop
    with PeripheryMasterAXI4MMIO
    with MultiClockRocketPlexMaster
    {
      override lazy val module = new PARDFPGATopModule(this, () => new PARDFPGATopBundle(this))
      {
        coreplex.module.io.tcrs foreach { tcr =>
          tcr.clock := io.coreclk
          tcr.reset := io.corerst
        }
      }
    }

class PARDFPGATopBundle[+L <: PARDFPGATop](_outer: L) extends PARDTopBundle(_outer)
    with PeripheryMasterAXI4MMIOBundle
    with MultiClockRocketPlexMasterBundle
    {
      val coreclk = Clock(INPUT)
      val corerst= Bool(INPUT)
    }

class PARDFPGATopModule[+L <: PARDFPGATop, +B <: PARDFPGATopBundle[L]](_outer: L, _io: () => B) extends PARDTopModule(_outer, _io)
    with PeripheryMasterAXI4MMIOModule
    with MultiClockRocketPlexMasterModule
