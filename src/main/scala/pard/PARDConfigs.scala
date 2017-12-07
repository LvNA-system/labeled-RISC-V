// See LICENSE for license details.

package rocketchip

import Chisel._
import junctions._
import rocket._
import diplomacy._
import uncore.agents._
import uncore.tilelink._
import uncore.devices._
import uncore.converters._
import util._
import coreplex._
import scala.math.max
import scala.collection.mutable.{LinkedHashSet, ListBuffer}
import scala.collection.immutable.HashMap
import DefaultTestSuites._
import cde.{Parameters, Config, Dump, Knob, CDEMatchError}

// To correctly override the RTCPeriod in BaseConfig
// WithRTCPeriod should be put in front of BaseConfig
class PARDSimConfig extends Config(
  new WithBlockingL1
//  ++ new WithoutFPU
  ++ new WithoutDebugLog
//  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x2000000L) // 32MB
//  ++ new WithAddressMapperBase(0x80000000L)
  ++ new WithRTCPeriod(5)
//  ++ new BucketConfig
  ++ new BaseConfig)

class PARDFPGAConfigzedboard extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  //++ new WithJtagDTM
  ++ new WithExtMemSize(0x80000000L)
//  ++ new WithAddressMapperBase(0x10000000L) // 256MB
  ++ new WithNCores(1)
//  ++ new WithAynchronousRocketTiles(8, 3)
  ++ new WithRTCPeriod(4) // gives 10 MHz RTC assuming 40 MHz uncore clock
//  ++ new BucketConfig
  ++ new WithL2Capacity(128)
  ++ new WithNL2Ways(16)
  ++ new WithPLRU
  ++ new DefaultL2FPGAConfig
)

class PARDFPGAConfigzcu102 extends Config(
  new WithBlockingL1
  ++ new WithoutFPU
  //++ new WithJtagDTM
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
