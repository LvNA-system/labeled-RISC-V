// See LICENSE for license details.

package rocketchip

import Chisel._
import coreplex._
import cde.{Parameters, Field, Config, Dump, Knob, CDEMatchError}

// To correctly override the RTCPeriod in BaseConfig
// WithRTCPeriod should be put in front of BaseConfig
class PARDSimConfig extends Config(
  new WithBlockingL1
  ++ new WithSim
  ++ new WithJtagDTM 
  ++ new WithoutFPU
//  ++ new WithNoHype
  ++ new WithNCores(2)
  ++ new WithExtMemSize(0x2000000L) // 32MB
  ++ new WithL2Capacity(128)
  ++ new WithNL2Ways(16)
  ++ new DefaultL2Config)

class PARDFPGAConfigzedboard extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  ++ new WithJtagDTM
  ++ new WithExtMemSize(0x80000000L)
  ++ new WithNCores(4)
  ++ new WithNBtbEntry(0)
  ++ new WithL1ICacheWays(2)
  ++ new WithL1DCacheWays(2)
  ++ new WithRTCPeriod(4) // gives 10 MHz RTC assuming 40 MHz uncore clock
  ++ new WithL2Capacity(256)
  ++ new WithNL2Ways(16)
  ++ new DefaultL2FPGAConfig
)

class PARDFPGAConfigzcu102 extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  ++ new WithJtagDTM
  ++ new WithExtMemSize(0x80000000L)
  ++ new WithNCores(1)
  ++ new WithRTCPeriod(8) // gives 10 MHz RTC assuming 80 MHz uncore clock
  ++ new WithL2Capacity(2048)
  ++ new WithNL2Ways(16)
  ++ new DefaultL2FPGAConfig
)
