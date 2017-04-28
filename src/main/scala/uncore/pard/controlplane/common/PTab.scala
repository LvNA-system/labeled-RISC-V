package uncore.pard

import chisel3._
import chisel3.util._

import config._


abstract class PTab[+TB <: TableBundle](_io: => TB)(implicit p: Parameters)
  extends Module with HasTable {
  val io = IO(_io)
  val params = p
}
