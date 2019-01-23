// See LICENSE for license details.

package freechips.rocketchip.system

import boom.common.{DefaultBoomConfig, WithSmallBooms, WithoutBoomFPU}
import boom.system.WithNBoomCores
import freechips.rocketchip.config.{Config, Field}
import freechips.rocketchip.subsystem._

case object UseEmu extends Field[Boolean](false)

class WithEmu extends Config ((site, here, up) => {
  case UseEmu => true
})

case object UseBoom extends Field[Boolean](false)

class WithBoom extends Config ((site, here, up) => {
  case UseBoom => true
})

// Boom
class LvNABoomConfigemu extends Config(
//  new WithoutBoomFPU
  new WithSmallBooms
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
    ++ new BaseConfig)

class LvNABoomFPGAConfigzcu102 extends Config(
  new WithSmallBooms
  ++ new DefaultBoomConfig
  ++ new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(0)
  ++ new WithBoom
  ++ new WithNBoomCores(1)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x100000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)


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
  ++ new WithNL2CacheCapacity(0)
  ++ new WithNBigCores(4)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x100000000L)
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class LvNAFPGAConfigsidewinder extends Config(
  new WithoutFPU
  ++ new WithNonblockingL1(8)
  ++ new WithNL2CacheCapacity(2048)
  ++ new WithNBigCores(4)
  ++ new WithRationalRocketTiles
  ++ new WithTimebase(BigInt(10000000)) // 10 MHz
  ++ new WithExtMemSize(0x100000000L)
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
