package uncore.pard

import chisel3._
import chisel3.util._

import freechips.rocketchip.config._

/** Register Interface
 *  Field layout described as XXOffset below.
 */
class RegInterface(regType: Int, ident: String)(implicit p: Parameters) extends Module {
  private val regSpaceSize   = 32
  private val typeOffset     = 0
  private val reservedOffset = 1
  private val identOffset    = 4
  private val commnadOffset  = 16
  private val addrOffset     = 20
  private val dataOffset     = 24

  private val regBits = 8

  val io = IO(new Bundle {
    // io <> I2C
    val STOP_DETECT = Input(Bool())
    val INDEX_POINTER = Input(UInt(8.W))
    val WRITE_ENABLE = Input(Bool())
    val RECEIVE_BUFFER = Input(UInt(regBits.W))
    val SEND_BUFFER = Output(UInt(regBits.W))
    // io <> DetectLogicCommon
    val detect = Flipped(new RegisterInterfaceIO)
  })

  val index = io.INDEX_POINTER
  val regs = Mem(regSpaceSize, UInt(regBits.W))

  private def rangeGet(rng: Range) = Cat(rng.reverse.map(regs(_)))
  private def rangeSet(rng: Range, input: UInt) = {
    require(rng.length * regBits == input.getWidth, "Width mismatch")
    rng.zipWithIndex.foreach { case (i, j) => regs(i) := input((j + 1) * regBits - 1, j * regBits) }
  }

  // Output to I2C
  io.SEND_BUFFER := RegNext(init = 0.U(regBits.W),
    next = Mux(index < regSpaceSize.U, regs(index), 0.U))

  // Write data to register
  when (reset.toBool) {
    // Type field
    regs(typeOffset) := regType.U
    // Reserved field
    (reservedOffset until identOffset).foreach(regs(_) := 0.U)
    // Idnent field
    require(ident.length <= commnadOffset - identOffset, s"Ident '${ident}' is too long")
    (identOffset until commnadOffset).zipAll(ident, 0, 0.toChar).foreach {
      case (i, ch: Char) => regs(i) := ch.toInt.U
    }
    // Comnad, addr, data field
    (commnadOffset until regSpaceSize).foreach(regs(_) := 0.U)
  }
  .elsewhen (io.detect.DATA_VALID) {
    // Data offset on 8 bytes
    (0 to 3).foreach { i =>
      when (io.detect.DATA_OFFSET === i.U) {
        val rng = (i * 8) until ((i + 1) * 8)
        val mask = io.detect.DATA_MASK
        rangeSet(rng, (io.detect.DATA_RBACK & mask) | (rangeGet(rng) & ~mask))
      }
    }
  }
  .elsewhen (io.WRITE_ENABLE && index < regSpaceSize.U) {
    regs(index) := io.RECEIVE_BUFFER
  }

  val commDataEnable = RegInit(false.B)
  when (index > 15.U && index < 20.U && io.WRITE_ENABLE) {
    commDataEnable := true.B
  }
  .elsewhen (index === 0.U) {
    commDataEnable := false.B
  }

  io.detect.COMM_VALID := commDataEnable && io.STOP_DETECT
  io.detect.COMM_DATA := rangeGet(16 until 32)
}
