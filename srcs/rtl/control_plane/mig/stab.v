`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2015 05:16:28 PM
// Design Name: 
// Module Name: mig_stable
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


module mig_cp_stab(
    input wire aclk,
    input wire areset,
/* TypeS access: by address */
    input  wire [14 : 0]     col,
    input  wire [14 : 0]     row,
    input  wire [31 : 0]     wdata,
    input  wire              wen,
    input  wire              is_this_table ,
    output [63 : 0]      rdata,

	input [14:0] trigger_row,
	input [2:0] trigger_metric,
	output [31:0] trigger_rdata,
    
    input  wire [31 : 0]     apm_axi_araddr
    );

	wire [4:0] de_addr = (apm_axi_araddr[10] ? 12 : 0) + apm_axi_araddr[7:4];
	wire de_addr_valid = (apm_axi_araddr[31:8] == 24'h02 || apm_axi_araddr[31:8] == 24'h06)
		&& (apm_axi_araddr[7:6] != 2'b11) && (apm_axi_araddr[3:0] == 4'b0);

    reg [31:0] apm_data[23:0] ;  
	integer i;
	always @ (posedge aclk or posedge areset) begin
		if (areset) begin
			for(i = 0; i < 24; i = i + 1) begin
				apm_data[i] <= 32'd0;
			end
		end
		else if (wen & de_addr_valid) begin
			apm_data[de_addr] <= wdata ;  
		end
	end
    
	wire [4:0] cp_addr = row * 6 + col;
	wire cp_addr_valid = (row < 4) && (col < 6);
	assign rdata = (cp_addr_valid ? apm_data[cp_addr] : 64'b0);

	wire [4:0] trigger_addr = trigger_row * 6 + trigger_metric;
	wire trigger_addr_valid = (trigger_row < 4) && (trigger_metric < 6);
	assign trigger_rdata = (trigger_addr_valid ? apm_data[trigger_addr] : 32'b0);
endmodule
