package uncore.pard

import chisel3._
import chisel3.util._
import scala.collection.mutable.ListBuffer

import freechips.rocketchip.config._


/**
 * Provide generic method to construct
 * pipeline with given depth.
 */
trait HasPipeline {
  this: Module =>

  def zeroInit[D <: Data](data: D) = {
    val init = 0.U(data.getWidth.W).asTypeOf(data)
    require(init.isWidthKnown)
    init
  }

  // from_outer => ... => to_stab
  def pipelined[D <: Data](from: D, deep: Int, enable: Bool = null) = {
    val init = zeroInit(from)
    val regs = from +: Seq.fill(deep){ RegInit(from.cloneType, init) }
    for (i <- 1 until regs.size) {
      if (enable != null) {
        when (enable) {
          regs(i) := regs(i - 1)
        }
      } else {
        regs(i) := regs(i - 1)
      }
    }
    regs.last
  }
}


class FieldOption
case object NoSet extends FieldOption
case object SetFirst extends FieldOption
case object SetLast extends FieldOption

/**
 * Provide helper method to abstract definition of table fields
 */
trait HasTable {
  this: Module {
    val io: TableBundle
  } =>

  val params: Parameters

  /**
   * We use a mutable container to collect
   * fields during subclass construction.
   */
  val fields = ListBuffer[Vec[_]]()

  /**
   * Flag to promise no field defined after read ports bound.
   */
  var readGenerated = false

  /**
   * Create a field instance with write logic.
   */
  def makeField[T >: Bool <: UInt](gen: T, update_en: Bool = false.B, option: FieldOption = SetFirst)
       (update_block: Vec[T] => Unit = (vec: Vec[T]) => {}) = {
    require(!readGenerated, "Generate read ports before all fields declared!")
    val field = RegInit(Vec(Seq.fill(params(NEntries))(gen)))

    lazy val write_enable = io.cmd.wen && io.table.sel && (io.cmd.col === fields.size.U)
    option match {
      case SetFirst =>
        when(write_enable) {
          field(io.cmd.row) := io.cmd.wdata
        } .elsewhen(update_en) {
          update_block.apply(field)
        }
      case SetLast =>
        when(update_en) {
          update_block.apply(field)
        } .elsewhen(write_enable) {
          field(io.cmd.row) := io.cmd.wdata
        }
      case NoSet =>
        when(update_en) {
          update_block.apply(field)
        }
    }
    fields += field
    field
  }

  /**
   * Bind fields to common read ports.
   */
  def makeRead(row: UInt, col: UInt) = {
    readGenerated = true
    MuxLookup(col, 0.U, fields.zipWithIndex.map {
      case (field: Vec[_], i) => (i.U, field(row))
    })
  }
}
