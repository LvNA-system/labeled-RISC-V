`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/10/2015 10:40:42 AM
// Design Name: 
// Module Name: RegisterInterface
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
//  - Register Map
//    Offset   Usage
//    00h      Type
//    01h-03h  -- Reserved --
//    04h-07h  IDENT_LOW
//    08h-0Fh  IDENT_HIGH
//    10h-13h  Command
//    14h-18h  addr
//    18h-1Fh  data
//////////////////////////////////////////////////////////////////////////////////

`define REG_SPACE_SIZE 32

module RegisterInterface(
    RST, SYS_CLK,SCL_i, STOP_DETECT, INDEX_POINTER, WRITE_ENABLE,
    RECEIVE_BUFFER, SEND_BUFFER,
    DATA_VALID,DATA_RBACK,DATA_MASK,DATA_OFFSET,
    COMM_VALID,COMM_DATA
);
    parameter TYPE = 8'h41;
    parameter IDENT_LOW = 32'h41424344;
    parameter IDENT_HIGH = 64'h45464748494A4B4C;
    
    input          RST;
    input          SYS_CLK;
    input          SCL_i;
    input          STOP_DETECT;
	input  [7:0]   INDEX_POINTER;
	input          WRITE_ENABLE;
	input  [7:0]   RECEIVE_BUFFER;
	
	input          DATA_VALID ;
	input  [63:0]  DATA_RBACK;
	input  [63:0]  DATA_MASK ;
	input  [1:0]   DATA_OFFSET ;
	
	output         COMM_VALID;
	output [127:0] COMM_DATA;
	output [7:0]   SEND_BUFFER;

    reg    [7:0] registers[`REG_SPACE_SIZE-1:0];

    // Prepare data for output
    reg [7:0]       rSendBuffer;
    assign SEND_BUFFER = rSendBuffer;
    always @ (posedge RST or posedge SYS_CLK)
    begin
        if (RST) begin
            rSendBuffer <= 8'h00;
        end else begin
            if (INDEX_POINTER < `REG_SPACE_SIZE)
                rSendBuffer <= registers[INDEX_POINTER];
            else
                rSendBuffer <= 8'h00;
        end
    end
    
    // Write data to register
    integer i;
    reg comm_data_en;
//    always @ (posedge RST or posedge SCL_i)
    wire [63 :0] registers_offset0;
    wire [63 :0] registers_offset1;
    wire [63 :0] registers_offset2;
    wire [63 :0] registers_offset3;
    assign registers_offset0 = {registers[7] ,registers[6] ,registers[5] ,registers[4] ,registers[3] ,registers[2] ,registers[1] ,registers[0] };
    assign registers_offset1 = {registers[15],registers[14],registers[13],registers[12],registers[11],registers[10],registers[9] ,registers[8] };
    assign registers_offset2 = {registers[23],registers[22],registers[21],registers[20],registers[19],registers[18],registers[17],registers[16]};
    assign registers_offset3 = {registers[31],registers[30],registers[29],registers[28],registers[27],registers[26],registers[25],registers[24]};
   always @(posedge RST or posedge SYS_CLK)
    begin
        if (RST)
        begin
            registers[0]  <= TYPE;
            registers[1]  <= 8'h0;
            registers[2]  <= 8'h0;
            registers[3]  <= 8'h0;
            registers[4]  <= IDENT_LOW[7:0];
            registers[5]  <= IDENT_LOW[15:8];
            registers[6]  <= IDENT_LOW[23:16];
            registers[7]  <= IDENT_LOW[31:24];
            registers[8]  <= IDENT_HIGH[7:0];
            registers[9]  <= IDENT_HIGH[15:8];
            registers[10] <= IDENT_HIGH[23:16];
            registers[11] <= IDENT_HIGH[31:24];
            registers[12] <= IDENT_HIGH[39:32];
            registers[13] <= IDENT_HIGH[47:40];
            registers[14] <= IDENT_HIGH[55:48];
            registers[15] <= IDENT_HIGH[63:56];
            for (i=8'h10; i<`REG_SPACE_SIZE; i=i+1)
                registers[i] <= 8'h00;
        end
        else if(DATA_VALID) begin
            case(DATA_OFFSET) 
            2'b00 : begin {registers[7] ,registers[6] ,registers[5] ,registers[4] ,registers[3] ,registers[2] ,registers[1] ,registers[0]}         <= (DATA_RBACK & DATA_MASK) | (registers_offset0 & ~ DATA_MASK) ; end
            2'b01 : begin {registers[15],registers[14],registers[13],registers[12],registers[11],registers[10],registers[9] ,registers[8]}   <= (DATA_RBACK & DATA_MASK) | (registers_offset1 & ~ DATA_MASK) ; end
            2'b10 : begin {registers[23],registers[22],registers[21],registers[20],registers[19],registers[18],registers[17],registers[16]} <= (DATA_RBACK & DATA_MASK) | (registers_offset2 & ~ DATA_MASK) ; end
            2'b11 : begin {registers[31],registers[30],registers[29],registers[28],registers[27],registers[26],registers[25],registers[24]} <= (DATA_RBACK & DATA_MASK) | (registers_offset3 & ~ DATA_MASK) ; end
            endcase        
        end
        else if (WRITE_ENABLE && INDEX_POINTER < `REG_SPACE_SIZE) begin
            registers[INDEX_POINTER] <= RECEIVE_BUFFER;
        end
    end
    
    always @(posedge SYS_CLK or posedge RST)
    begin
        if (RST) begin
            comm_data_en <= 1'b0;
        end else begin
            if((INDEX_POINTER>8'd15) && (INDEX_POINTER<8'd20) && WRITE_ENABLE) begin
                comm_data_en <= 1'b1;
            end else if (INDEX_POINTER==8'd0) begin
                comm_data_en <= 1'b0;
            end
        end       
    end
    assign COMM_VALID = comm_data_en && STOP_DETECT ;
    assign COMM_DATA  = {registers[31],registers[30],registers[29],registers[28],registers[27],registers[26],registers[25],registers[24],
                         registers[23],registers[22],registers[21],registers[20],registers[19],registers[18],registers[17],registers[16]};
                         
endmodule
