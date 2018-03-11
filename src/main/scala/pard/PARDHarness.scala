// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import diplomacy._
import cde.{Parameters, Field}
import coreplex._
import rocketchip._

case object BuildFPGATop extends Field[Parameters => ExampleTop]

class PARDFPGAHarness(q: Parameters) extends Module {
  val io = new Bundle {
    val success = Bool(OUTPUT)
  }
  val dut = q(BuildFPGATop)(q).module
}
