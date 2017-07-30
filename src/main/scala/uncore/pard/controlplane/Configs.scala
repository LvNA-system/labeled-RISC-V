/**
 * Configs for PARD components
 */

package uncore.pard

import config._
import uncore.devices.{DMKey, DefaultDebugModuleConfig}

object TopConfig extends Config(new MigConfig
  ++ new CacheConfig
  ++ new TriggerConfig
  ++ new BucketConfig
  ++ new DebugConfig)

case object TriggerRDataBits extends Field[Int]
case object TriggerMetricBits extends Field[Int]

class TriggerConfig extends Config((site, here, next) => {
  case TriggerRDataBits => 32
  case TriggerMetricBits => 3
})

case object TagBits extends Field[Int]
case object AddrBits extends Field[Int]
case object DataBits extends Field[Int]
case object CmdBits extends Field[Int]
case object NEntries extends Field[Int]

class MigConfig extends Config((site, here, next) => {
  case TagBits => 16
  case AddrBits => 32
  case DataBits => 64
  case CmdBits => 128
  case NEntries => 4
})

case object CacheAssoc extends Field[Int]
case object CacheBlockSize extends Field[Int]

class CacheConfig extends Config((site, here, next) => {
  case CacheAssoc => 16
  case CacheBlockSize => 64
})

case class BucketBitsParams(data: Int, size: Int, freq: Int)
case object BucketBits extends Field[BucketBitsParams]

class BucketConfig extends Config((site, here, next) => {
  case BucketBits => BucketBitsParams(data = 32, size = 32, freq = 32)
})

class DebugConfig extends Config((site, here, next) => {
  case DMKey => DefaultDebugModuleConfig(64)
})