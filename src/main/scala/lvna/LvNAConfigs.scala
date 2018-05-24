// See LICENSE for license details.

package freechips.rocketchip.system

import freechips.rocketchip.config.{Field, Config}
import freechips.rocketchip.subsystem._

case object UseEmu extends Field[Boolean](false)

class WithEmu extends Config ((site, here, up) => {
  case UseEmu => true
})

class LvNAConfigemu extends Config(
  new WithNBigCores(2)
  ++ new WithEmu
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x800000L) // 8MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseConfig)

class LvNAFPGAConfigzedboard extends Config(
  new WithNBigCores(2)
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x4000000L) // 64MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)

class LvNAFPGAConfigzcu102 extends Config(
  new WithNBigCores(4)
  ++ new WithoutFPU
//  ++ new WithAsynchronousRocketTiles(8, 3)
  ++ new WithExtMemSize(0x10000000L) // 256MB
  ++ new WithJtagDTM
  ++ new WithDebugSBA
  ++ new BaseFPGAConfig)
