package sifive.blocks.devices.uart

import chisel3._

/*
class UARTPrinter(filename: String) extends BlackBox(
  Map("FILENAME" -> chisel3.core.StringParam(filename))) {
    */
class UARTPrinter(filename: String) extends BlackBox {
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val valid = Input(Bool())
    val data = Input(UInt(width=8))  // Always expect an ASCII character
  })
}
