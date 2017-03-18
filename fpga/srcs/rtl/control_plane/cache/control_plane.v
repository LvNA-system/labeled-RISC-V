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

module CacheControlPlane
#(
    parameter integer DSID_WIDTH = 16,
    parameter integer CACHE_ASSOCIATIVITY = 16,
    parameter integer ENTRY_SIZE = 64,
    parameter integer NUM_ENTRIES = 4
)(
    input  wire RST,
    input  wire SYS_CLK,
    /* I2C Interface */
    input  wire[6:0] ADDR,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_I" *) input  wire SCL_i,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_O" *) output wire SCL_o,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_T" *) output wire SCL_t,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_I" *) input  wire SDA_i,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_O" *) output wire SDA_o,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_T" *) output wire SDA_t,
    
    //Cache Statistic
    input wire                                              lookup_valid_to_stab,
    input wire [DSID_WIDTH - 1 : 0]                         lookup_DSid_to_stab,
    input wire                                              lookup_hit_to_stab,
    input wire                                              lookup_miss_to_stab,
    input wire                                              update_tag_en_to_stab,
    input wire [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_to_stab,
    input wire [DSID_WIDTH * CACHE_ASSOCIATIVITY - 1 : 0]   update_tag_old_DSid_vec_to_stab,
    input wire [DSID_WIDTH * CACHE_ASSOCIATIVITY - 1 : 0]   update_tag_new_DSid_vec_to_stab,
    input wire                                              lru_history_en_to_ptab,
    input wire                                              lru_dsid_valid_to_ptab,
    input wire [DSID_WIDTH - 1 : 0]                         lru_dsid_to_ptab,
    output     [CACHE_ASSOCIATIVITY - 1 : 0]                way_mask_to_cache,

    /* PRM trigger logic */
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


  I2CInterface i2c_intf_i
  (
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

  wire [127:0] COMM_DATA ;
  wire         COMM_VALID ;
  wire         DATA_VALID ;
  wire [63:0]  DATA_RBACK;
  wire [63:0]  DATA_MASK;
  wire [1:0]   DATA_OFFSET;

  RegisterInterface 
  #(
    .TYPE(8'h24),                               // Type: '$'
    .IDENT_LOW(32'h44524150),                   // IDENT: PARDCacheCP
    .IDENT_HIGH(64'h0050436568636143)
  )
  reg_intf_i 
  (
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

  assign RESET_MODE_CORE0 = 2'b01;
  assign RESET_MODE_CORE1 = 2'b01;
  assign RESET_MODE_CORE2 = 2'b01;
  assign RESET_MODE_CORE3 = 2'b01;

  cache_cp_detect_logic 
  #(
    .DSID_WIDTH(DSID_WIDTH),
    .CACHE_ASSOCIATIVITY(CACHE_ASSOCIATIVITY),
    .ENTRY_SIZE(ENTRY_SIZE),
    .NUM_ENTRIES(NUM_ENTRIES)
  )
  detc_logic_i
  (
    .SYS_CLK(SYS_CLK),
    .RST(RST),
    .COMM_VALID(COMM_VALID),
    .COMM_DATA(COMM_DATA),
    .DATA_VALID(DATA_VALID),
    .DATA_RBACK(DATA_RBACK),
    .DATA_MASK(DATA_MASK),
    .DATA_OFFSET(DATA_OFFSET),

    .lookup_valid_to_calc(lookup_valid_to_stab),
    .lookup_DSid_to_calc(lookup_DSid_to_stab),
    .lookup_hit_to_calc(lookup_hit_to_stab),
    .lookup_miss_to_calc(lookup_miss_to_stab),
    .update_tag_en_to_calc(update_tag_en_to_stab),
    .update_tag_we_to_calc(update_tag_we_to_stab),
    .update_tag_old_DSid_vec_to_calc(update_tag_old_DSid_vec_to_stab),
    .update_tag_new_DSid_vec_to_calc(update_tag_new_DSid_vec_to_stab),
    .lru_history_en_to_ptab(lru_history_en_to_ptab),
    .lru_dsid_valid_to_ptab(lru_dsid_valid_to_ptab),
    .lru_dsid_to_ptab(lru_dsid_to_ptab),
    .way_mask_to_cache(way_mask_to_cache),

    .trigger_axis_tready(trigger_axis_tready),
    .trigger_axis_tvalid(trigger_axis_tvalid),
    .trigger_axis_tdata(trigger_axis_tdata)
  );
endmodule
