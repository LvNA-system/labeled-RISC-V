`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICT, CAS
// Engineer: Jiuyue Ma
// 
// Create Date: 04/13/2015 02:24:55 PM
// Design Name: Generic control plane
// Module Name: ControlPlane
// Project Name: pard_fpga_vc709
// Target Devices: VC709
// Tool Versions: 2014.4
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CoreControlPlane (
    input RST,
	input SYS_CLK,

    /* I2C Interface */
    input [6:0] ADDR,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_I" *)
    input SCL_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_O" *)
    output SCL_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_T" *)
    output SCL_t,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_I" *)
    input SDA_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_O" *)
    output SDA_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_T" *)
    output SDA_t,

    /*core control interface*/
	output EXT_RESET_IN_CORE0,
	output EXT_RESET_IN_CORE1,
	output EXT_RESET_IN_CORE2,
	output EXT_RESET_IN_CORE3,
	output [15:0] DS_ID_CORE0,
	output [15:0] DS_ID_CORE1,
	output [15:0] DS_ID_CORE2,
	output [15:0] DS_ID_CORE3,

	input trigger_axis_tready,
	output trigger_axis_tvalid,
	output [15:0] trigger_axis_tdata
);
    /* Local Wire */
    wire       stop_detect;
    wire [7:0] index_pointer;
    wire       write_enable;
    wire [7:0] receive_buffer;
    wire [7:0] send_buffer;
        
        
    I2CInterface i2c_intf_i (
        .RST(RST),
        .SYS_CLK(SYS_CLK),
        /* I2C Interface */
        .ADDR(ADDR), 
        .SCL_ext_i(SCL_i), .SCL_o(SCL_o), .SCL_t(SCL_t),
        .SDA_ext_i(SDA_i), .SDA_o(SDA_o), .SDA_t(SDA_t),
        /* Register Interface */
        .STOP_DETECT_o(stop_detect),
        .INDEX_POINTER_o(index_pointer),
        .WRITE_ENABLE_o(write_enable),
        .RECEIVE_BUFFER(receive_buffer),
        .SEND_BUFFER(send_buffer)
    );
    wire [127:0] COMM_DATA;
    wire         COMM_VALID;
    wire         DATA_VALID;
    wire [63:0]  DATA_RBACK;
    wire [63:0]  DATA_MASK;
    wire [1:0]   DATA_OFFSET;
    
    
    RegisterInterface # (
        .TYPE(8'h43),                               // Type: 'C'
        .IDENT_LOW(32'h44524150),                   // IDENT: PARDCoreCP
        .IDENT_HIGH(64'h0000504365726F43)
    ) reg_intf_i (
        .RST(RST),
        .SYS_CLK(SYS_CLK),
        .SCL_i(SCL_i),
        .STOP_DETECT(stop_detect),
        .INDEX_POINTER(index_pointer),
        .WRITE_ENABLE(write_enable),
        .RECEIVE_BUFFER(receive_buffer),
        .SEND_BUFFER(send_buffer),
        .DATA_VALID(DATA_VALID),
        .DATA_RBACK(DATA_RBACK),
        .DATA_MASK(DATA_MASK),
        .DATA_OFFSET(DATA_OFFSET),
        .COMM_DATA(COMM_DATA),
        .COMM_VALID(COMM_VALID));
        
    core_cp_detect_logic detc_logic_i(
		.SYS_CLK(SYS_CLK),
		.RST(RST),
		.COMM_VALID(COMM_VALID),
		.COMM_DATA(COMM_DATA),
		.DATA_VALID(DATA_VALID),
		.DATA_RBACK(DATA_RBACK),
		.DATA_MASK(DATA_MASK),
		.DATA_OFFSET(DATA_OFFSET),

		.EXT_RESET_IN_CORE0(EXT_RESET_IN_CORE0),
		.EXT_RESET_IN_CORE1(EXT_RESET_IN_CORE1),
		.EXT_RESET_IN_CORE2(EXT_RESET_IN_CORE2),
		.EXT_RESET_IN_CORE3(EXT_RESET_IN_CORE3),
		.DS_ID_CORE0(DS_ID_CORE0),
		.DS_ID_CORE1(DS_ID_CORE1),
		.DS_ID_CORE2(DS_ID_CORE2),
		.DS_ID_CORE3(DS_ID_CORE3),
		
		.trigger_axis_tready(trigger_axis_tready),
		.trigger_axis_tvalid(trigger_axis_tvalid),
		.trigger_axis_tdata(trigger_axis_tdata)
	);
    
endmodule
