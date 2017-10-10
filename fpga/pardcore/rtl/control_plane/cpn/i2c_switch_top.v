`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2015/04/06 14:03:57
// Design Name: 
// Module Name: i2c_switch_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_switch_top(
    /* upstream */
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SCL_I" *)
    output SCL_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SCL_O" *)
    input SCL_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SCL_T" *)
    input SCL_t,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SDA_I" *)
    output SDA_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SDA_O" *)
    input SDA_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 M SDA_T" *)
    input SDA_t,

    /* downstream */

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SCL_I" *)
	output scl0_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SCL_O" *)
	input scl0_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SCL_T" *)
	input scl0_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SDA_I" *)
	output sda0_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SDA_O" *)
	input sda0_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S0 SDA_T" *)
	input sda0_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SCL_I" *)
	output scl1_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SCL_O" *)
	input scl1_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SCL_T" *)
	input scl1_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SDA_I" *)
	output sda1_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SDA_O" *)
	input sda1_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S1 SDA_T" *)
	input sda1_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SCL_I" *)
	output scl2_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SCL_O" *)
	input scl2_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SCL_T" *)
	input scl2_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SDA_I" *)
	output sda2_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SDA_O" *)
	input sda2_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S2 SDA_T" *)
	input sda2_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SCL_I" *)
	output scl3_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SCL_O" *)
	input scl3_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SCL_T" *)
	input scl3_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SDA_I" *)
	output sda3_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SDA_O" *)
	input sda3_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S3 SDA_T" *)
	input sda3_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SCL_I" *)
	output scl4_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SCL_O" *)
	input scl4_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SCL_T" *)
	input scl4_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SDA_I" *)
	output sda4_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SDA_O" *)
	input sda4_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S4 SDA_T" *)
	input sda4_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SCL_I" *)
	output scl5_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SCL_O" *)
	input scl5_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SCL_T" *)
	input scl5_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SDA_I" *)
	output sda5_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SDA_O" *)
	input sda5_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S5 SDA_T" *)
	input sda5_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SCL_I" *)
	output scl6_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SCL_O" *)
	input scl6_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SCL_T" *)
	input scl6_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SDA_I" *)
	output sda6_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SDA_O" *)
	input sda6_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S6 SDA_T" *)
	input sda6_t, // IIC Serial Data Output Enable to 3-state buffer (required)

	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SCL_I" *)
	output scl7_i, // IIC Serial Clock Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SCL_O" *)
	input scl7_o, // IIC Serial Clock Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SCL_T" *)
	input scl7_t, // IIC Serial Clock Output Enable to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SDA_I" *)
	output sda7_i, // IIC Serial Data Input from 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SDA_O" *)
	input sda7_o, // IIC Serial Data Output to 3-state buffer (required)
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 S7 SDA_T" *)
	input sda7_t, // IIC Serial Data Output Enable to 3-state buffer (required)

    input aclk,
    input aresetn,
    input [2:0] addr
);
    i2c_switch inst (                      
        .aclk(aclk),
        .aresetn(aresetn),
        .addr(addr),                          
        /* upstream */
        .SCL_i(SCL_i),
        .SCL_o(SCL_o),
        .SCL_t(SCL_t),
        .SDA_i(SDA_i),
        .SDA_o(SDA_o),
        .SDA_t(SDA_t),
        /* downstream */                        
        .SC_i({scl7_i, scl6_i, scl5_i, scl4_i, scl3_i, scl2_i, scl1_i, scl0_i}),
        .SC_o({scl7_o, scl6_o, scl5_o, scl4_o, scl3_o, scl2_o, scl1_o, scl0_o}),
        .SC_t({scl7_t, scl6_t, scl5_t, scl4_t, scl3_t, scl2_t, scl1_t, scl0_t}),
        .SD_i({sda7_i, sda6_i, sda5_i, sda4_i, sda3_i, sda2_i, sda1_i, sda0_i}),
        .SD_o({sda7_o, sda6_o, sda5_o, sda4_o, sda3_o, sda2_o, sda1_o, sda0_o}),
        .SD_t({sda7_t, sda6_t, sda5_t, sda4_t, sda3_t, sda2_t, sda1_t, sda0_t})
    );
endmodule
