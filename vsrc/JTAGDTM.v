// See LICENSE.SiFive for license details.

import "DPI-C" function void jtag_tick
(
  output bit    jtag_TMS,
  output bit    jtag_TCK,
  output bit    jtag_TDI,
  input  bit    jtag_TDO,
  output bit    jtag_TRST
);

module JTAGDTM(
  input clk,
  input reset,
  output     jtag_TMS,
  output     jtag_TCK,
  output     jtag_TDI,
  input      jtag_TDO,
  output     jtag_TRST,
  input      enable,
  input      init_done
);
  bit r_reset;

  wire #0.1 __jtag_TDO = jtag_TDO;
  wire #0.1 __enable = enable;
  wire #0.1 __init_done = init_done;

  bit __jtag_TMS;
  bit __jtag_TCK;
  bit __jtag_TDI;
  bit __jtag_TRST;

  assign #0.1 jtag_TMS = __jtag_TMS;
  assign #0.1 jtag_TCK = __jtag_TCK;
  assign #0.1 jtag_TDI = __jtag_TDI;
  assign #0.1 jtag_TRST = __jtag_TRST;

  always @(posedge clk)
  begin
    r_reset <= reset;
    if (!reset && !r_reset && __enable && __init_done)
    begin
      jtag_tick(
		__jtag_TMS,
		__jtag_TCK,
		__jtag_TDI,
		__jtag_TDO,
		__jtag_TRST
      );
    end
    else
    begin
      __jtag_TRST = 1;
    end
  end
endmodule
