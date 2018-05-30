// See LICENSE for license details.

package rocketchip

import Chisel._
import cde.{Parameters, Field}
import junctions._
import coreplex._
import rocketchip._

/** PARDFPGATop */
class PARDFPGATop(q: Parameters) extends ExampleTop(q)
    {
  override lazy val module = Module(new PARDFPGATopModule(p, this, new PARDFPGATopBundle(p)))
}

class PARDFPGATopBundle(p: Parameters) extends ExampleTopBundle(p)

class PARDFPGATopModule[+L <: PARDFPGATop, +B <: PARDFPGATopBundle](p: Parameters, l: L, b: => B) extends ExampleTopModule(p, l, b)
