// See LICENSE for license details.

package freechips.rocketchip.system

import freechips.rocketchip.config.Config
import freechips.rocketchip.subsystem._

// To correctly override the RTCPeriod in BaseConfig
// WithRTCPeriod should be put in front of BaseConfig
class PARDSimConfig extends Config(
  new WithNBigCores(2)
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x800000L) // 8MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseConfig)

class PARDFPGAConfigzedboard extends Config(
  new WithNBigCores(2)
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x4000000L) // 64MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class PARDFPGAConfigzcu102 extends Config(
  new WithNBigCores(4)
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x10000000L) // 256MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)
