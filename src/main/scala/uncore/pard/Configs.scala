/**
 * Configs for PARD components
 */

package uncore.pard

import config._

case class BucketBitsParams(data: Int, size: Int, freq: Int)
case object BucketBits extends Field[BucketBitsParams]

class BucketConfig extends Config((site, here, next) => {
  case BucketBits => BucketBitsParams(data = 32, size = 32, freq = 32)
})
