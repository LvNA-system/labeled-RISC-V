package uncore.pard

import chisel3._
import config._


class ControlPlanes(implicit p: Parameters) extends Module {
  val io = IO(new Bundle)
  val mig = Module(new MigControlPlane)
  val core = Module(new CoreControlPlane)
}


object CP extends App {
  Driver.execute(args, () => new ControlPlanes()(TopConfig))
}
