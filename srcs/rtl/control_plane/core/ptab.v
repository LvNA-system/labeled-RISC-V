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

	// FIXED: counters should be large enough to let the EXT_RESET_IN_COREx
	// signal active for more than 4 cycles, only after which the reset
	// signal will be sampled by the Processor System Reset IP core
	reg [3:0] reset_counter [3:0];

	reg last_state [3:0];
	always@(posedge SYS_CLK) begin
		last_state[0] <= state[0];
		last_state[1] <= state[1];
		last_state[2] <= state[2];
		last_state[3] <= state[3];
	end

	wire [3:0] state_posedge;
	wire [3:0] state_negedge;

	assign state_posedge[0] = (~last_state[0] & state[0]);
	assign state_negedge[0] = (last_state[0] & ~state[0]);
	assign state_posedge[1] = (~last_state[1] & state[1]);
	assign state_negedge[1] = (last_state[1] & ~state[1]);
	assign state_posedge[2] = (~last_state[2] & state[2]);
	assign state_negedge[2] = (last_state[2] & ~state[2]);
	assign state_posedge[3] = (~last_state[3] & state[3]);
	assign state_negedge[3] = (last_state[3] & ~state[3]);

	integer i;

	always@(posedge SYS_CLK or posedge DETECT_RST) begin
		for(i = 0; i < 4; i = i + 1) begin
			if(DETECT_RST) begin
				reset_counter[i] <= 4'b0000;
			end
			else begin
				if(state_posedge[i]) begin
					reset_counter[i] <= 4'b0001;
				end
				else if(reset_counter[i] != 4'b0000) begin
					// the counter will wrap around to 4'b0000
					reset_counter[i] = reset_counter[i] + 4'b0001;
				end
			end
		end
	end

	// active low
	assign EXT_RESET_IN_CORE0 = (reset_counter[0] == 2'b00);
	assign EXT_RESET_IN_CORE1 = (reset_counter[1] == 2'b00);
	assign EXT_RESET_IN_CORE2 = (reset_counter[2] == 2'b00);
	assign EXT_RESET_IN_CORE3 = (reset_counter[3] == 2'b00);

endmodule
