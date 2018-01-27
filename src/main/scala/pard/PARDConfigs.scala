// See LICENSE for license details.

package rocketchip

import Chisel._
import coreplex._
import cde.{Parameters, Field, Config, Dump, Knob, CDEMatchError}

// To correctly override the RTCPeriod in BaseConfig
// WithRTCPeriod should be put in front of BaseConfig
class PARDSimConfig extends Config(
  new WithBlockingL1
  ++ new WithJtagDTM 
  ++ new WithoutFPU
  ++ new WithNoHype
  ++ new WithNCores(2)
//  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x2000000L) // 32MB
  ++ new WithL2Capacity(128)
  ++ new WithNL2Ways(16)
//  ++ new WithRTCPeriod(5)
//  ++ new DefaultConfig)
  ++ new DefaultL2Config)

class PARDFPGAConfigzedboard extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  ++ new WithJtagDTM
  ++ new WithExtMemSize(0x80000000L)
//  ++ new WithAddressMapperBase(0x10000000L) // 256MB
  ++ new WithNCores(4)
  ++ new WithNBtbEntry(0)
  ++ new WithL1ICacheWays(1)
  ++ new WithL1DCacheWays(1)
//  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithRTCPeriod(4) // gives 10 MHz RTC assuming 40 MHz uncore clock
//  ++ new BucketConfig
  ++ new WithL2Capacity(256)
  ++ new WithNL2Ways(16)
  ++ new WithPLRU
  ++ new DefaultL2FPGAConfig
)

class PARDFPGAConfigzcu102 extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  ++ new WithJtagDTM
  ++ new WithExtMemSize(0x80000000L)
//  ++ new WithAddressMapperBase(0x0L)
  ++ new WithNCores(1)
//  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithRTCPeriod(8) // gives 10 MHz RTC assuming 80 MHz uncore clock
//  ++ new BucketConfig
  ++ new WithL2Capacity(2048)
  ++ new WithNL2Ways(16)
  ++ new WithPLRU
  ++ new DefaultL2FPGAConfig
)
