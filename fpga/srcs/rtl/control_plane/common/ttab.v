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

module ttab #(
	parameter CP_ID = 8'd0,
	parameter NR_ENTRY_WIDTH = 2,
	parameter NR_ENTRY = 2 ** NR_ENTRY_WIDTH
) (
	input          SYS_CLK          ,
	input          DETECT_RST       ,
	input is_this_table,
	input [14:0] col,
	input [14:0] row,
	input [63:0] wdata,
	input wen,
	output reg [63:0] rdata,

	output [15:0] trigger_dsid,
	output [2:0] trigger_metric,
	input [31:0] trigger_rdata,
	input trigger_dsid_valid,

	// to trigger logic
	input fifo_wready,
	output fifo_wvalid,
	output [15:0] fifo_wdata
);

	localparam OP_LE = 2'b00;
	localparam OP_GE = 2'b01;

	reg [NR_ENTRY_WIDTH - 1:0] trigger_idx;
         
	// col 0
	reg [7:0] trigger_id [NR_ENTRY - 1:0];
	// col 1
	reg [NR_ENTRY - 1:0] valid;
	// col 2
	reg [15:0] dsid [NR_ENTRY - 1:0];
	// col 3
	reg [2:0] metric [NR_ENTRY - 1:0];
	// col 4
	reg [31:0] val [NR_ENTRY - 1:0];
	// col 5
	reg [1:0] op [NR_ENTRY - 1:0];

	always @(posedge SYS_CLK) begin
		if(wen & is_this_table) begin
			case(col)
				15'd0: trigger_id[row] <= wdata[7:0];
				15'd2: dsid[row] <= wdata[15:0];
				15'd3: metric[row] <= wdata[2:0];
				15'd4: val[row] <= wdata[31:0];
				15'd5: op[row] <= wdata[1:0];
			endcase
		end
	end

	always @(*) begin
		case(col)
			15'd0: rdata = {56'b0, trigger_id[row]};
			15'd1: rdata = {63'b0, valid[row]};
			15'd2: rdata = {48'b0, dsid[row]};
			15'd3: rdata = {61'b0, metric[row]};
			15'd4: rdata = {32'b0, val[row]};
			15'd5: rdata = {62'b0, op[row]};
			default: rdata = 64'b0;
		endcase
	end

	wire trigger_ok;

	// insert pipeline
	reg [31:0] trigger_rdata_latch;
	reg [NR_ENTRY_WIDTH - 1:0] trigger_idx_latch;
	reg trigger_dsid_valid_latch;
	wire stall = trigger_ok & ~fifo_wready;

	always@(posedge SYS_CLK or posedge DETECT_RST) begin
		if(DETECT_RST) begin
			trigger_dsid_valid_latch <= 1'b0;
		end
		else begin
			if(~stall) begin
				trigger_rdata_latch <= trigger_rdata;
				trigger_idx_latch <= trigger_idx;
				trigger_dsid_valid_latch <= trigger_dsid_valid;
			end
		end
	end

	integer i;
	always @(posedge SYS_CLK or posedge DETECT_RST) begin
		if(DETECT_RST) begin
			for(i = 0; i < NR_ENTRY; i = i + 1) begin
				valid[i] <= 1'b0;
			end
		end
		else if(fifo_wvalid & fifo_wready) begin
			valid[trigger_idx_latch] <= 1'b0;
		end
		else if((wen & is_this_table) && col == 15'd1) begin
			valid[row] <= wdata[0:0];
		end
	end

	// trigger logic

	reg compare_result;
	always@(*) begin
		case(op[trigger_idx_latch])
			OP_GE: compare_result = (trigger_rdata_latch > val[trigger_idx_latch]);
			OP_LE: compare_result = (trigger_rdata_latch < val[trigger_idx_latch]);
			default: compare_result = 1'b0;
		endcase
	end

	assign trigger_ok = valid[trigger_idx_latch] && compare_result && trigger_dsid_valid_latch;

	always@(posedge SYS_CLK or posedge DETECT_RST) begin
		if(DETECT_RST) begin
			trigger_idx <= {NR_ENTRY_WIDTH{1'b0}};
		end
		else begin
			if(~stall) begin
				trigger_idx <= trigger_idx + 1'b1;
			end
		end
	end

	assign trigger_dsid = dsid[trigger_idx];
	assign trigger_metric = metric[trigger_idx];

	assign fifo_wvalid = trigger_ok;
	assign fifo_wdata = {CP_ID, trigger_id[trigger_idx_latch]};

endmodule
