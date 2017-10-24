// See LICENSE for license details.

package freechips.rocketchip.system

import freechips.rocketchip.coreplex._
import freechips.rocketchip.config._
import freechips.rocketchip.system._

class PARDSimConfig extends Config(new WithNBigCores(2)
  ++ new WithoutFPU
  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x800000L)
  ++ new BaseConfig)

class PARDFPGAConfig extends Config(new FPGAConfig
  //++ new WithJtagDTM
  ++ new WithoutFPU
  ++ new WithExtMemSize(0x40000000L)
  ++ new WithNBigCores(2)
  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithRTCPeriod(50) // gives 10 MHz RTC assuming 50 MHz uncore clock
  ++ new BaseConfig)
