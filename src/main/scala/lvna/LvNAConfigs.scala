// See LICENSE for license details.

package freechips.rocketchip.system

import freechips.rocketchip.config.{Config, Field}
import freechips.rocketchip.devices.tilelink.WithRocketTests
import freechips.rocketchip.subsystem._
import boom.common.{DefaultBoomConfig, WithMediumBooms, WithRVC, WithSmallBooms}
import boom.system.WithNBoomCores
import boom.lsu.pref.WithPrefetcher

case object UseEmu extends Field[Boolean](false)
case object NohypeDefault extends Field[Boolean](true)

class WithEmu extends Config ((site, here, up) => {
  case UseEmu => true
})

case object UseBoom extends Field[Boolean](false)

class WithBoom extends Config ((site, here, up) => {
  case UseBoom => true
})

// Boom

class LvNABoomConfig extends Config(
  new WithBoomNBL1(4)
    // ++ new WithPrefetcher
    ++ new WithRVC
    ++ new WithSmallBooms
    ++ new DefaultBoomConfig
    ++ new WithNBoomCores(1)
    ++ new WithNL2CacheCapacity(0)
    ++ new WithEmu
    ++ new WithBoom
    ++ new WithRationalRocketTiles
    ++ new WithExtMemSize(0x8000000L) // 32MB
    ++ new WithNoMMIOPort
    ++ new WithJtagDTM
    ++ new WithDebugSBA
    ++ new BaseBoomConfig)



class LvNABoomPrefConfig extends Config(
  new WithPrefetcher ++
  new WithBoomNBL1(4) ++
  new WithRVC
    ++ new WithSmallBooms
    ++ new DefaultBoomConfig
    ++ new WithNBoomCores(1)
    ++ new WithNL2CacheCapacity(0)
    ++ new WithEmu
    ++ new WithBoom
    ++ new WithRationalRocketTiles
    ++ new WithExtMemSize(0x8000000L) // 32MB
    ++ new WithNoMMIOPort
    ++ new WithJtagDTM
    ++ new WithDebugSBA
    ++ new BaseBoomConfig)


class LvNABoomTestConfig extends Config(
  new WithPrefetcher ++
  new WithBoomNBL1(4) ++
  new WithRVC
    ++ new WithMediumBooms
    ++ new DefaultBoomConfig
    ++ new WithNBoomCores(1)
    ++ new WithNL2CacheCapacity(0)
    ++ new WithEmu
    ++ new WithBoom
    ++ new WithRationalRocketTiles
    //    ++ new WithJtagDTM : // remove JtagDTM for rocket tests
    ++ new WithExtMemBase(0x80000000L) // for rocket tests
    ++ new WithExtMemSize(0x1000000L) // 4MB
    ++ new WithNoMMIOPort
    ++ new WithDebugSBA
    ++ new WithRocketTests
    ++ new BaseBoomConfig)


class LvNARocketTestConfig extends Config(
  new WithoutFPU
    ++ new WithNBigCores(1)
    ++ new WithNonblockingL1(8)
    ++ new WithNL2CacheCapacity(0)
    ++ new WithNoMMIOPort
    ++ new WithEmu
    ++ new WithRationalRocketTiles
    // ++ new WithJtagDTM // remove JtagDTM for rocket tests
    ++ new WithExtMemBase(0x80000000L) // for rocket tests
    ++ new WithExtMemSize(0x8000000L) // 32MB
    ++ new WithRocketTests
    ++ new BaseConfig)


class LvNABoomFPGAConfigzcu102 extends Config(
  new WithPrefetcher ++
  new WithBoomNBL1(4) ++
  new WithRVC
  ++ new WithSmallBooms
  ++ new DefaultBoomConfig
  ++ new WithNL2CacheCapacity(0)
  ++ new WithBoom
  ++ new WithNBoomCores(1)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x100000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseBoomFPGAConfig)


// Rocket

class LvNAConfigemu extends Config(
  new WithoutFPU
  ++ new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(256)
  ++ new WithNBigCores(1)
  ++ new WithEmu
  ++ new WithRationalRocketTiles
  ++ new WithExtMemSize(0x8000000L) // 32MB
  ++ new WithNoMMIOPort
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseConfig)

class LvNAFPGAConfigzedboard extends Config(
  new WithoutFPU
  ++ new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(256)
  ++ new WithNZedboardCores(2)
  ++ new WithTimebase(BigInt(20000000)) // 20 MHz
  ++ new WithExtMemSize(0x100000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class LvNAFPGAConfigzcu102 extends Config(
  new WithoutFPU
  ++ new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(2048)
  ++ new WithNBigCores(4)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x80000000L)  // 2GB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class LvNAFPGAConfigsidewinder extends Config(
  new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(2048)
  ++ new WithNBigCores(4)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x80000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class LvNAFPGAConfigrv32 extends Config(
  new WithoutFPU
  //++ new WithNonblockingL1(8)
  ++ new WithRV32
  ++ new WithNBigCores(1)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemBase(0x80000000L)
  ++ new WithExtMemSize(0x80000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)
