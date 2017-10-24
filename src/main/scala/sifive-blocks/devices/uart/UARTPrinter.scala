package sifive.blocks.devices.uart

import chisel3._

// if you have a clock
// use UARTPrinter
// if do not have a clock(eg: you can not extend Module)
// you can use UARTPrinterWrapper
class UARTPrinter(filename: String) extends BlackBox(
  Map("FILENAME" -> chisel3.core.StringParam(filename))) {
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val valid = Input(Bool())
    val data = Input(UInt(8.W))  // Always expect an ASCII character
  })
}

class UARTPrinterWrapper(filename: String) extends Module {
  val io = IO(new Bundle {
    val valid = Input(Bool())
    val data = Input(UInt(8.W))  // Always expect an ASCII character
  })

  val printer = Module(new UARTPrinter(filename))
  printer.io.clock := clock;
  printer.io.valid := io.valid;
  printer.io.data := io.data;
}
