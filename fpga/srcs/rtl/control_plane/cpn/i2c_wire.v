`timescale 1ns / 1ps

/*
 * IOBUF Logic Table
 * Inputs Bidirectional Outputs
 *  T  I         IO          O
 *  1  X          Z         IO
 *  0  1          1          1
 *  0  0          0          0
 */
 
 /*
  * i2c_wire Logic Table
  *   T0   T1   I0/I1
  *   0    0      O0
  *   0    1      O0
  *   1    0      O1
  *   1    1      *1*
  */

module i2c_wire(
    SCL0_i, SCL0_o, SCL0_t, SDA0_i, SDA0_o, SDA0_t,
    SCL1_i, SCL1_o, SCL1_t, SDA1_i, SDA1_o, SDA1_t
);
output wire SCL0_i;
input  wire SCL0_o;
input  wire SCL0_t;
output wire SDA0_i;
input  wire SDA0_o;
input  wire SDA0_t;

output wire SCL1_i;
input  wire SCL1_o;
input  wire SCL1_t;
output wire SDA1_i;
input  wire SDA1_o;
input  wire SDA1_t;

assign SCL0_i = (!SCL0_t) ? SCL0_o : ((!SCL1_t) ? SCL1_o : 1'b1);
assign SCL1_i = (!SCL0_t) ? SCL0_o : ((!SCL1_t) ? SCL1_o : 1'b1);
assign SDA0_i = (!SDA0_t) ? SDA0_o : ((!SDA1_t) ? SDA1_o : 1'b1);
assign SDA1_i = (!SDA0_t) ? SDA0_o : ((!SDA1_t) ? SDA1_o : 1'b1);

endmodule
