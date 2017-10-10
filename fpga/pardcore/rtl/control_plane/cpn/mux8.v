`timescale 1ns / 1ps

module Mux8(
    input [7:0] Vector_in,
    input [7:0] Sel_in,
    output Out
    );
    parameter DEFAULT_OUT = 1'b0;
    reg mux_out;

    assign Out = mux_out;

    always@(Vector_in, Sel_in)
    case(Sel_in)
        default     : mux_out <= DEFAULT_OUT; 
        8'b0000_0001: mux_out <= Vector_in[0];
        8'b0000_0010: mux_out <= Vector_in[1];
        8'b0000_0100: mux_out <= Vector_in[2];
        8'b0000_1000: mux_out <= Vector_in[3];
        8'b0001_0000: mux_out <= Vector_in[4];
        8'b0010_0000: mux_out <= Vector_in[5];
        8'b0100_0000: mux_out <= Vector_in[6];
        8'b1000_0000: mux_out <= Vector_in[7];
    endcase
    
endmodule
