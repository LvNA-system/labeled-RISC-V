// See LICENSE.SiFive for license details.

package rocketchip

import Chisel._
import cde.{Parameters, Field}
import junctions._
import coreplex._
import rocketchip._

class PARDSimTop[+C <: BaseCoreplex](_coreplex: Parameters => C)(implicit p: Parameters) extends ExampleTop(_coreplex)

class PARDSimTopBundle[+L <: PARDSimTop[BaseCoreplex]](_outer: L) extends ExampleTopBundle(_outer)

class PARDSimTopModule[+L <: PARDSimTop[BaseCoreplex], +B <: PARDSimTopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)


class PARDFPGATop[+C <: BaseCoreplex](_coreplex: Parameters => C)(implicit p: Parameters) extends ExampleTop(_coreplex)

class PARDFPGATopBundle[+L <: PARDFPGATop[BaseCoreplex]](_outer: L) extends ExampleTopBundle(_outer)

class PARDFPGATopModule[+L <: PARDFPGATop[BaseCoreplex], +B <: PARDFPGATopBundle[L]](_outer: L, _io: () => B) extends ExampleTopModule(_outer, _io)
