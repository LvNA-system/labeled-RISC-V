`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2015 10:07:01 PM
// Design Name: 
// Module Name: detec_logic
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


module   core_cp_detect_logic(
	input          SYS_CLK,
	input          RST,
	input          COMM_VALID,
	input  [127:0] COMM_DATA,

	output        DATA_VALID,
	output [63:0] DATA_RBACK,
	output [63:0] DATA_MASK,
	output [1:0]  DATA_OFFSET,

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

	wire [63:0] parameter_table_rdata;
	wire [63:0] statistic_table_rdata;
	wire [63:0] trigger_table_rdata;
	wire is_parameter_table;
	wire is_statistic_table;
	wire is_trigger_table;
	wire [14:0] col;
	wire [14:0] row;
	wire [63:0] wdata;
	wire wen;

	detect_logic_common common(
		.SYS_CLK(SYS_CLK),
		.DETECT_RST(RST),
		.COMM_VALID(COMM_VALID),
		.COMM_DATA(COMM_DATA),
		.DATA_VALID(DATA_VALID),
		.DATA_RBACK(DATA_RBACK),
		.DATA_MASK(DATA_MASK),
		.DATA_OFFSET(DATA_OFFSET),

		.parameter_table_rdata(parameter_table_rdata),
		.statistic_table_rdata(statistic_table_rdata),
		.trigger_table_rdata(trigger_table_rdata),
		.is_parameter_table(is_parameter_table),
		.is_statistic_table(is_statistic_table),
		.is_trigger_table(is_trigger_table),
		.col(col),
		.row(row),
		.wdata(wdata),
		.wen(wen)
	);

	core_cp_ptab ptab(
		.SYS_CLK(SYS_CLK),
		.DETECT_RST(RST),
		.DS_ID_CORE0(DS_ID_CORE0),
		.DS_ID_CORE1(DS_ID_CORE1),
		.DS_ID_CORE2(DS_ID_CORE2),
		.DS_ID_CORE3(DS_ID_CORE3),
		.EXT_RESET_IN_CORE0(EXT_RESET_IN_CORE0),
		.EXT_RESET_IN_CORE1(EXT_RESET_IN_CORE1),
		.EXT_RESET_IN_CORE2(EXT_RESET_IN_CORE2),
		.EXT_RESET_IN_CORE3(EXT_RESET_IN_CORE3),
		.rdata(parameter_table_rdata),
		.is_this_table(is_parameter_table),
		.col(col),
		.row(row),
		.wdata(wdata),
		.wen(wen)
	);

endmodule
