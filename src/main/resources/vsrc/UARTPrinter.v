module UARTPrinter
#(
  parameter FILENAME = "serial"
)(
  input       clock,
  input       valid,
  input [7:0] data   // Always expect an ASCII character
);

integer fd;

initial begin
  fd = $fopen(FILENAME, "w");
end

always @(posedge clock) begin
  if (valid) begin
    $fwrite(fd, "%c", data);
    $fflush(fd);
  end
end

endmodule
