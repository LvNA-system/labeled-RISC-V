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


module   cache_cp_detect_logic
#(
    parameter integer DSID_WIDTH = 16,
    parameter integer CACHE_ASSOCIATIVITY = 16,
    parameter integer ENTRY_SIZE  = 64,
    parameter integer NUM_ENTRIES = 4
)
(
    input          SYS_CLK,
    input          RST,
    input          COMM_VALID,
    input  [127:0] COMM_DATA,

    output        DATA_VALID,
    output [63:0] DATA_RBACK,
    output [63:0] DATA_MASK,
    output [1:0]  DATA_OFFSET,

    //Cache Statistic
    input                                              lookup_valid_to_calc,
    input [DSID_WIDTH - 1 : 0]                         lookup_DSid_to_calc,
    input                                              lookup_hit_to_calc,
    input                                              lookup_miss_to_calc,
    input                                              update_tag_en_to_calc,
    input [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_to_calc,
    input [DSID_WIDTH * CACHE_ASSOCIATIVITY - 1 : 0]   update_tag_old_DSid_vec_to_calc,
    input [DSID_WIDTH * CACHE_ASSOCIATIVITY - 1 : 0]   update_tag_new_DSid_vec_to_calc,
    input                                              lru_history_en_to_ptab,
    input                                              lru_dsid_valid_to_ptab,
    input [DSID_WIDTH - 1 : 0]                         lru_dsid_to_ptab,
    output[CACHE_ASSOCIATIVITY - 1 : 0]                way_mask_to_cache,

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

  wire                                              lookup_valid_from_calc_to_stab;
  wire [DSID_WIDTH - 1 : 0]                         lookup_DSid_from_calc_to_stab;
  wire                                              lookup_hit_from_calc_to_stab;
  wire                                              lookup_miss_from_calc_to_stab;
  wire                                              update_tag_en_from_calc_to_stab;
  wire [CACHE_ASSOCIATIVITY - 1 : 0]                update_tag_we_from_calc_to_stab;
  wire [DSID_WIDTH - 1 : 0]                         update_tag_old_DSid_from_calc_to_stab;
  wire [DSID_WIDTH - 1 : 0]                         update_tag_new_DSid_from_calc_to_stab;

  // store all of the DSids
  reg  [DSID_WIDTH - 1 : 0]      DSid1;
  reg  [DSID_WIDTH - 1 : 0]      DSid2;
  reg  [DSID_WIDTH - 1 : 0]      DSid3;
  reg  [DSID_WIDTH - 1 : 0]      DSid4;
  reg  [DSID_WIDTH - 1 : 0]      DSid5;

  always@(posedge RST)
  begin
    DSid1 <= 16'd1;
    DSid2 <= 16'd2;
    DSid3 <= 16'd3;
    DSid4 <= 16'd4;
    DSid5 <= 16'd0;
  end

  wire [15:0] trigger_dsid;
  reg [14:0] trigger_row;
  wire [2:0] trigger_metric;
  wire [31:0] trigger_rdata;

  wire [3:0] trigger_dsid_match;
  reg trigger_dsid_valid;

  assign trigger_dsid_match[0] = (trigger_dsid == DSid1);
  assign trigger_dsid_match[1] = (trigger_dsid == DSid2);
  assign trigger_dsid_match[2] = (trigger_dsid == DSid3);
  assign trigger_dsid_match[3] = (trigger_dsid == DSid4);

  always@(*) begin
    casex(trigger_dsid_match)
    4'b1000: begin trigger_row = 14'd3; trigger_dsid_valid = 1'b1; end
    4'b0100: begin trigger_row = 14'd2; trigger_dsid_valid = 1'b1; end
    4'b0010: begin trigger_row = 14'd1; trigger_dsid_valid = 1'b1; end
    4'b0001: begin trigger_row = 14'd0; trigger_dsid_valid = 1'b1; end
    default: begin trigger_row = 14'd0; trigger_dsid_valid = 1'b0; end
    endcase
  end

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

  cache_cp_ptab
  #(
    .DSID_WIDTH(DSID_WIDTH),
    .CACHE_ASSOCIATIVITY(CACHE_ASSOCIATIVITY),
    .ENTRY_SIZE(CACHE_ASSOCIATIVITY),  // CACHE_ASSOCIATIVITY = entry_size for ptab
    .NUM_ENTRIES(NUM_ENTRIES + 1)
  )
  cache_cp_ptab
  (
    .SYS_CLK(SYS_CLK),
    .DETECT_RST(RST),

    .is_this_table(is_parameter_table),
    .col(col),
    .row(row),
    .wdata(wdata),
    .wen(wen),
    .rdata(parameter_table_rdata),

    .DSid_storage({DSid5,DSid4,DSid3,DSid2,DSid1}),
    .lru_history_en_to_ptab(lru_history_en_to_ptab),
    .lru_dsid_valid_to_ptab(lru_dsid_valid_to_ptab),
    .lru_dsid_to_ptab(lru_dsid_to_ptab),
    .way_mask_to_cache(way_mask_to_cache)
  );

  cache_cp_calc
  #(
    .DSID_WIDTH(DSID_WIDTH),
    .CACHE_ASSOCIATIVITY(CACHE_ASSOCIATIVITY)
  )
  cache_cp_calc
  (
    .SYS_CLK(SYS_CLK),
    .DETECT_RST(RST),

    .lookup_valid_from_cache_to_calc(lookup_valid_to_calc),
    .lookup_DSid_from_cache_to_calc(lookup_DSid_to_calc),
    .lookup_hit_from_cache_to_calc(lookup_hit_to_calc),
    .lookup_miss_from_cache_to_calc(lookup_miss_to_calc),

    .update_tag_en_from_cache_to_calc(update_tag_en_to_calc),
    .update_tag_we_from_cache_to_calc(update_tag_we_to_calc),
    .update_tag_old_DSid_vec_from_cache_to_calc(update_tag_old_DSid_vec_to_calc),
    .update_tag_new_DSid_vec_from_cache_to_calc(update_tag_new_DSid_vec_to_calc),

    .lookup_valid_from_calc_to_stab(lookup_valid_from_calc_to_stab),
    .lookup_DSid_from_calc_to_stab(lookup_DSid_from_calc_to_stab),
    .lookup_hit_from_calc_to_stab(lookup_hit_from_calc_to_stab),
    .lookup_miss_from_calc_to_stab(lookup_miss_from_calc_to_stab),

    .update_tag_en_from_calc_to_stab(update_tag_en_from_calc_to_stab),
    .update_tag_we_from_calc_to_stab(update_tag_we_from_calc_to_stab),
    .update_tag_old_DSid_from_calc_to_stab(update_tag_old_DSid_from_calc_to_stab),
    .update_tag_new_DSid_from_calc_to_stab(update_tag_new_DSid_from_calc_to_stab)
  );

  cache_cp_stab
  #(
    .DSID_WIDTH(DSID_WIDTH),
    .CACHE_ASSOCIATIVITY(CACHE_ASSOCIATIVITY),
    .ENTRY_SIZE(32),
    .NUM_ENTRIES(NUM_ENTRIES + 1)
  )
  cache_cp_stab
  (
    .SYS_CLK(SYS_CLK),
    .DETECT_RST(RST),
    .is_this_table(is_statistic_table),

    .col(col),
    .row(row),
    .rdata(statistic_table_rdata),
    .wdata(wdata),
    .wen(wen),

    .trigger_row(trigger_row),
    .trigger_metric(trigger_metric),
    .trigger_rdata(trigger_rdata),

    .DSid_storage({DSid5,DSid4,DSid3,DSid2,DSid1}),

    .lookup_valid_from_calc_to_stab(lookup_valid_from_calc_to_stab),
    .lookup_DSid_from_calc_to_stab(lookup_DSid_from_calc_to_stab),
    .lookup_hit_from_calc_to_stab(lookup_hit_from_calc_to_stab),
    .lookup_miss_from_calc_to_stab(lookup_miss_from_calc_to_stab),

    .update_tag_en_from_calc_to_stab(update_tag_en_from_calc_to_stab),
    .update_tag_we_from_calc_to_stab(update_tag_we_from_calc_to_stab),
    .update_tag_old_DSid_from_calc_to_stab(update_tag_old_DSid_from_calc_to_stab),
    .update_tag_new_DSid_from_calc_to_stab(update_tag_new_DSid_from_calc_to_stab)
  );

  ttab # (
    .CP_ID(8'd1)
  ) cache_cp_ttab (
    .SYS_CLK(SYS_CLK),
    .DETECT_RST(RST),
    .rdata(trigger_table_rdata),
    .is_this_table(is_trigger_table),
    .col(col),
    .row(row),
    .wdata(wdata),
    .wen(wen),

    .trigger_dsid(trigger_dsid),
    .trigger_metric(trigger_metric),
    .trigger_rdata(trigger_rdata),
    .trigger_dsid_valid(trigger_dsid_valid),

    .fifo_wready(trigger_axis_tready),
    .fifo_wvalid(trigger_axis_tvalid),
    .fifo_wdata(trigger_axis_tdata)
  );

endmodule
