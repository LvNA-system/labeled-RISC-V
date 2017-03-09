`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Frontier System Group, ICT
// Engineer: Jiuyue Ma
// 
// Create Date: 2015/08/10 16:27:01
// Design Name: pardsys
// Module Name: triport_reg_files
// Project Name: pard_fpga_vc709
// Target Devices: xc7vx690tffg1761-2
// Tool Versions: Vivado 2014.4
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module mig_cp_ptab #
  (
   // Interface parameter
   parameter integer C_TAG_WIDTH = 16,
   parameter integer C_DATA_WIDTH = 128,
   parameter integer C_BASE_WIDTH = 32,
   parameter integer C_LENGTH_WIDTH = 32,
   parameter integer C_DSID_LENTH = 64 ,
   // Table Size
   parameter integer C_NUM_ENTRIES = 5
   )
  (
     input wire aclk,
     input wire areset,
     input wire is_this_table,
      /* TypeS access: by address */
     input  wire [14 : 0]     col,
     input  wire [14 : 0]     row,
     input  wire [63 : 0]     wdata,
     input  wire              wen,
     output reg [63 : 0]     rdata,
     input  wire [C_DSID_LENTH-1 :0]       DSID ,
     /* Always output info */
     output wire [C_NUM_ENTRIES - 1 : 0] L1enable,
      /* TypeA access: by tag */
     input  wire [C_TAG_WIDTH-1    : 0]     TAG_A,
     output wire [C_DATA_WIDTH-1   : 0]     DO_A,
     output wire                            TAG_MATCH_A,      
      /* TypeB access: by tag */
      input  wire [C_TAG_WIDTH-1    : 0]     TAG_B,
      output wire [C_DATA_WIDTH-1   : 0]     DO_B,
      output wire                            TAG_MATCH_B
  );
  localparam C_NUM_ENTRIES_LOG = f_ceil_log2(C_NUM_ENTRIES);
  localparam integer P_ENTRY_RANGES_BITS = f_ceil_log2(C_DATA_WIDTH/8);
  localparam [31:0] P_ENTRY_RANGES  = 2**P_ENTRY_RANGES_BITS;
  localparam [31:0] P_ENTRY_MASK    = P_ENTRY_RANGES-1;
  

  // Register Files

  reg  [C_DATA_WIDTH-1 : 0] reg_files [0 : C_NUM_ENTRIES-1];
  
  // Generate tag match one-hot & binary encoded index
  wire [C_NUM_ENTRIES - 1     : 0] tag_match_a;
  wire [C_NUM_ENTRIES - 1     : 0] tag_match_b;
  genvar i;
  reg [79:0 ]   reg_files_dsid ;
  reg [C_BASE_WIDTH-1 :0]   reg_files_base[C_NUM_ENTRIES-1 : 0] ;
  reg [C_LENGTH_WIDTH-1 :0] reg_files_len[C_NUM_ENTRIES-1 : 0] ;

  reg [0:0] L1EnableReg [C_NUM_ENTRIES - 1 : 0];



   generate
     for (i=0; i<C_NUM_ENTRIES; i=i+1) 
     begin: tag_match_blk
        assign L1enable[i] = L1EnableReg[i];
        assign tag_match_a[i] = ~|(reg_files_dsid[(i+1)*C_TAG_WIDTH-1 -: C_TAG_WIDTH] ^ TAG_A[C_TAG_WIDTH-1:0]);
        assign tag_match_b[i] = ~|(reg_files_dsid[(i+1)*C_TAG_WIDTH-1 -: C_TAG_WIDTH] ^ TAG_B[C_TAG_WIDTH-1:0]);
     end
     
     assign TAG_MATCH_A = |tag_match_a;

     assign DO_A = {reg_files_len[f_hot2enc(tag_match_a)],reg_files_base[f_hot2enc(tag_match_a)]};
     assign TAG_MATCH_B = |tag_match_b;
     assign DO_B = {reg_files_len[f_hot2enc(tag_match_b)],reg_files_base[f_hot2enc(tag_match_b)]};   
   endgenerate
   
     always @ (posedge areset or posedge aclk)
     begin
        if(areset) begin
            reg_files_dsid <=80'h00ff0004000300020001;
        end
        else 
            reg_files_dsid <= {16'h00ff,DSID} ; 
     end
    integer j ; 
     always @ ( posedge areset or posedge aclk)
     begin
          if (areset) begin
             for (j=0 ; j<C_NUM_ENTRIES;j=j+1 ) 
               begin
                 L1EnableReg[j] <= 0;
                 reg_files_base[j] <= {C_BASE_WIDTH{1'd0}};
                 reg_files_len[j] <=  {C_LENGTH_WIDTH{1'd0}};
               end
          end
          else if ((is_this_table) & (wen)) begin
              case(col)
                   15'd2: L1EnableReg[row]    <= wdata != 64'd0 ;
                   15'd1: reg_files_len[row]  <= wdata ;
                   15'd0: reg_files_base[row] <= wdata ;
               endcase   
          end
    end

  // PortS: Read
  always @(*)
   begin
        case(col)
	       15'd2:rdata = {63'd0,L1EnableReg[row]} ;
	       15'd1:rdata = {32'd0,reg_files_len[row]} ;
	       15'd0:rdata = {32'd0,reg_files_base[row]} ;
	       default: rdata = 64'b0;
        endcase	
   end
   
  // Functions
  // Translate one-hot to binary encoded
  function [C_NUM_ENTRIES_LOG-1:0] f_hot2enc
    (
      input [C_NUM_ENTRIES-1:0]  one_hot
    );
    integer i;
    integer j;
    begin
      for (i=0; i<C_NUM_ENTRIES_LOG; i=i+1) begin
        f_hot2enc[i] = 1'b0;
        for (j=0; j<C_NUM_ENTRIES; j=j+1) begin
          f_hot2enc[i] = f_hot2enc[i] | (j[i] & one_hot[j]);
        end
      end
    end
  endfunction 
  // Ceiling of log2(x)
  function integer f_ceil_log2
    (
     input integer x
     );
    integer acc;
    begin
      acc=0;
      while ((2**acc) < x)
        acc = acc + 1;
      f_ceil_log2 = acc;
    end
  endfunction
  
endmodule
 


