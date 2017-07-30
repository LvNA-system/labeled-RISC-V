package uncore.pard

import chisel3._
import config._


class ControlPlanes(implicit p: Parameters) extends Module {
  val io = IO(new Bundle {
    val mig = new MigControlPlaneIO
    val core = new CoreControlPlaneIO
    val cache = new CacheControlPlaneIO
  })
  val mig = Module(new MigControlPlane)
  val core = Module(new CoreControlPlane)
  val cache = Module(new CacheControlPlane)

  io.mig <> mig.io
  io.core <> core.io
  io.cache <> cache.io
}


object CP extends App {
  Driver.execute(args, () => new ControlPlanes()(TopConfig))
}
