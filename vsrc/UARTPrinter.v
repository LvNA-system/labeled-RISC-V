// See LICENSE for license details.

import "DPI-C" function void uart_tick
(
  input  byte       data,
  input  int        addr
);


module UARTPrinter
(
  input       clock,
  input       valid,
  input [7:0] data,   // Always expect an ASCII character
  input [31:0] addr
);

wire [7:0] #0.1 __data = data;
wire [31:0] #0.1 __addr = addr;

always @(posedge clock) begin
  if (valid) begin
    uart_tick(
    __data,
    __addr
  );
  end
end

endmodule
