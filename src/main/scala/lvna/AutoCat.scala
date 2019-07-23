package lvna

import chisel3._

class AutoCatIOInternal extends Bundle {
  val access_valid_in = Input(Bool())
  val hit_vec_in = Input(UInt(16.W))
  val suggested_waymask_out = Output(UInt(16.W))
}

class autocat extends BlackBox {
  val io = IO(new AutoCatIOInternal {
    val clk_in = Input(Clock())
    val reset_in = Input(Bool())
  })
}
