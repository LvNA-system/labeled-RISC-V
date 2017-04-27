package uncore.pard

import chisel3._
import chisel3.util._
import scala.collection.mutable.ListBuffer


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
  def pipelined[D <: Data](from: D, deep: Int) = {
    val init = zeroInit(from)
    val regs = from +: Seq.fill(deep){ RegInit(from.cloneType, init) }
    for (i <- 1 until regs.size) {
      regs(i) := regs(i - 1)
    }
    regs.last
  }
}


/**
 * Provide helper method to abstract definition of table fields
 */
trait HasTable {
  this: Module {
    val io: TableBundle
  } =>

  val nEntries: Int

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
  def makeField[T >: Bool <: UInt](gen: T, update_en: Bool = null)(update_block: Vec[T] => Unit = null) = {
    require(!readGenerated, "Generate read ports before all fields declared!")
    val field = RegInit(Vec(Seq.fill(nEntries) {
      0.U(gen.getWidth.W).asTypeOf(gen)
    }))
    val context = when (io.cmd.wen && io.table.sel && (io.cmd.col === fields.size.U)) {
      field(io.cmd.row) := io.cmd.wdata
    }
    if (update_en != null) {
      context.elsewhen (update_en) {
        update_block.apply(field)
      }
    }
    fields += field
    field
  }
  
  /**
   * Bind fields to common read ports.
   */
  def makeRead(port: Data, row: UInt, col: UInt) = {
    readGenerated = true
    port := MuxLookup(col, 0.U, fields.zipWithIndex.map {
      case (field: Vec[_], i) => (i.U, field(row))
    })
  }
}
