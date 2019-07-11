
package freechips.rocketchip.config


case object MemInitAddr extends Field[BigInt]

class LvNADirtyConfig extends Config ((site, here, up) => {
  case MemInitAddr => BigInt(0x80000000L)
})
