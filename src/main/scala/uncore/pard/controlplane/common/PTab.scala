package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._

class PTabIO(implicit p: Parameters) extends TableBundle

class PTab[+B <: PTabIO](_io: => B)(implicit p: Parameters)
  extends Module with HasTable {
  val io = IO(_io)
  override val params = p
}
