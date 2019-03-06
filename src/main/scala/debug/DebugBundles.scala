
package freechips.rocketchip.debug

import chisel3._
import chisel3.util._
import freechips.rocketchip.config.Parameters
import freechips.rocketchip.tile.{CoreBundle, HasCoreParameters}


class DebugCSRIntIO extends Bundle() {
  // from CSR/core's perspective
  val dmiInterrupt = Input(Bool())
  val ndmiInterrupts = Output(UInt(16.W))
  val eipOutstanding = Output(Bool())
  val csrOutInt = Output(Bool())
  val reg_mip = Output(UInt(64.W))
}

