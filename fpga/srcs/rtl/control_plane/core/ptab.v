module   core_cp_ptab(
	input          SYS_CLK          ,
	input          DETECT_RST       ,
	input is_this_table,
	input [14:0] col,
	input [14:0] row,
	input [63:0] wdata,
	input wen,
	output reg [63:0] rdata,

	output EXT_RESET_IN_CORE0,
	output EXT_RESET_IN_CORE1,
	output EXT_RESET_IN_CORE2,
	output EXT_RESET_IN_CORE3,
	output [15:0] DS_ID_CORE0,
	output [15:0] DS_ID_CORE1,
	output [15:0] DS_ID_CORE2,
	output [15:0] DS_ID_CORE3
);

	// col 0
	reg [15:0] dsid [3:0];
	// col 1
	reg  state [3:0];

	assign DS_ID_CORE0 = dsid[0];
	assign DS_ID_CORE1 = dsid[1];
	assign DS_ID_CORE2 = dsid[2];
	assign DS_ID_CORE3 = dsid[3];

	parameter STATE_SLEEP = 1'b0, STATE_RUNNING = 1'b1;

	always @(posedge SYS_CLK or posedge DETECT_RST) begin
		if(DETECT_RST)  begin
			state[0] <= STATE_SLEEP;
			state[1] <= STATE_SLEEP;
			state[2] <= STATE_SLEEP;
			state[3] <= STATE_SLEEP;
		end
		else if(wen & is_this_table) begin
			case(col)
				15'b0: dsid[row] <= wdata[15:0];
				15'b1: state[row] <= wdata[0];
			endcase
		end
	end

	always @(*) begin
		case(col)
			15'b0: rdata = {48'b0, dsid[row]};
			15'b1: rdata = {63'b0, state[row]};
			default: rdata = 64'b0;
		endcase
	end

	// active low
	assign EXT_RESET_IN_CORE0 = state[0];
	assign EXT_RESET_IN_CORE1 = state[1];
	assign EXT_RESET_IN_CORE2 = state[2];
	assign EXT_RESET_IN_CORE3 = state[3];

endmodule
