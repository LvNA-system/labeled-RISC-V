/**
 * Configs for PARD components
 */

package uncore.pard

import config._

object MigConfig extends Config(new MigBaseConfig
  ++ new BucketConfig)

case object TagBits extends Field[Int]
case object AddrBits extends Field[Int]
case object DataBits extends Field[Int]
case object CmdBits extends Field[Int]
case object NEntries extends Field[Int]

class MigBaseConfig extends Config((site, here, next) => {
  case TagBits => 16
  case AddrBits => 32
  case DataBits => 64
  case CmdBits => 128
  case NEntries => 3
})

case class BucketBitsParams(data: Int, size: Int, freq: Int)
case object BucketBits extends Field[BucketBitsParams]

class BucketConfig extends Config((site, here, next) => {
  case BucketBits => BucketBitsParams(data = 32, size = 32, freq = 32)
})
