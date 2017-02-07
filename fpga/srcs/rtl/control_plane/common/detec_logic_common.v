`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2015 10:07:01 PM
// Design Name: 
// Module Name: detec_logic_common
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

module   detect_logic_common(
	input          SYS_CLK,
	input          DETECT_RST,
	input          COMM_VALID,
	input  [127:0] COMM_DATA,
	input [63:0] parameter_table_rdata,
	input [63:0] statistic_table_rdata,
	input [63:0] trigger_table_rdata,

	output        DATA_VALID,
	output reg [63:0] DATA_RBACK,
	output [63:0] DATA_MASK,
	output [1:0]  DATA_OFFSET,
	output is_parameter_table,
	output is_statistic_table,
	output is_trigger_table,
	output [14:0] col,
	output [14:0] row,
	output [63:0] wdata,
	output wen
);

         reg [127:0] comm_data;
         reg         data_valid_flag1;
         wire         is_read_cmd;
         always @(posedge SYS_CLK or posedge DETECT_RST) begin
          if(DETECT_RST)  begin
            comm_data <= 128'd0 ;
            data_valid_flag1 <= 1'b0;
            end
          else if (COMM_VALID) begin
            comm_data <= COMM_DATA ;
            data_valid_flag1 <= 1'b1;
            end
          else if (~COMM_VALID) begin
            data_valid_flag1 <= 1'b0;
            end      
         end

		 // command data format, refer to the asplos paper
		 wire [31:0] command;
		 wire [1:0] table_sel;
         assign {wdata, row, col, table_sel, command} = comm_data;

		 parameter CMD_READ = 1'b0, CMD_WRITE = 1'b1;

		 wire is_write_cmd = (command[0] == CMD_WRITE);
		 assign slave_wen = data_valid_flag1 & is_write_cmd;

		 reg last_slave_wen;
		 always @(posedge SYS_CLK or posedge DETECT_RST) begin
			 if(DETECT_RST) begin
				 last_slave_wen <= 1'b1;
			 end
			 else begin
				 last_slave_wen <= slave_wen;
			 end
		 end

		 assign wen = ~last_slave_wen & slave_wen;

		 assign is_read_cmd = (command[0] == CMD_READ);
		 assign DATA_OFFSET = 2'b11;
		 assign DATA_MASK = 64'hffffffffffffffff;
		 assign DATA_VALID = data_valid_flag1 & is_read_cmd;

		 always @(*) begin
			 case(table_sel)
				 2'b00: DATA_RBACK = parameter_table_rdata;
				 2'b01: DATA_RBACK = statistic_table_rdata;
				 2'b10: DATA_RBACK = trigger_table_rdata;
				 default: DATA_RBACK = 64'b0;
			 endcase
		 end

		 assign is_parameter_table = (table_sel == 2'b00);
		 assign is_statistic_table = (table_sel == 2'b01);
		 assign is_trigger_table = (table_sel == 2'b10);

endmodule
