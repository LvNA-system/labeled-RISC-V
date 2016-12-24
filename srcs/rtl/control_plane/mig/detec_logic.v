`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Frontier System Group, ICT
// Engineer: Jin Xin
// 
// Create Date: 04/16/2015 10:07:01 PM
// Design Name: pardsys
// Module Name: detec_logic
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
module mig_cp_detec_logic # (
   parameter integer C_ADDR_WIDTH = 32,
   parameter integer C_TAG_WIDTH = 16,
   parameter integer C_DATA_WIDTH = 128,
   parameter integer C_NUM_ENTRIES = 5
)(
    SYS_CLK,
    DETECT_RST,
    COMM_VALID,
    COMM_DATA,
    DATA_VALID,
    DATA_RBACK,
    DATA_MASK,
    DATA_OFFSET,
    
    TAG_A,
    DO_A,
    TAG_MATCH_A,
    
    TAG_B,
    DO_B,
    TAG_MATCH_B,
    APM_DATA,
    APM_ADDR,
    APM_VALID,

	trigger_axis_tready,
	trigger_axis_tvalid,
	trigger_axis_tdata
);

    input          SYS_CLK     ;
    input          DETECT_RST  ;
    input          COMM_VALID  ;
    input  [127:0] COMM_DATA   ;
    
    output         DATA_VALID  ;
    output [63:0]  DATA_RBACK  ;
    output [63:0]  DATA_MASK   ;
    output [1:0]   DATA_OFFSET ;

   /* TypeA access: by tag */
   input   [C_TAG_WIDTH-1    : 0]     TAG_A;
   output  [C_DATA_WIDTH-1   : 0]     DO_A;
   output                             TAG_MATCH_A;
   
   /* TypeB access: by tag */
   input   [C_TAG_WIDTH-1    : 0]     TAG_B;
   output  [C_DATA_WIDTH-1   : 0]     DO_B;
   output                             TAG_MATCH_B;
    
    input  [31:0]                     APM_DATA  ;
    input  [31:0]                     APM_ADDR  ;
    input                             APM_VALID ;

	input trigger_axis_tready;
	output trigger_axis_tvalid;
	output [15:0] trigger_axis_tdata;

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

    reg  [15:0] DSid [4:1];

    always@(posedge DETECT_RST) begin
        DSid[1] <= 16'd1;
        DSid[2] <= 16'd2;
        DSid[3] <= 16'd3;
        DSid[4] <= 16'd4;
    end

	wire [15:0] trigger_dsid;
	reg [14:0] trigger_row;
	wire [2:0] trigger_metric;
	wire [31:0] trigger_rdata;

	wire [3:0] trigger_dsid_match;
	reg trigger_dsid_valid;

	assign trigger_dsid_match[0] = (trigger_dsid == DSid[1]);
	assign trigger_dsid_match[1] = (trigger_dsid == DSid[2]);
	assign trigger_dsid_match[2] = (trigger_dsid == DSid[3]);
	assign trigger_dsid_match[3] = (trigger_dsid == DSid[4]);

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
        .DETECT_RST(DETECT_RST),
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

    mig_cp_ptab # (
        // Interface parameter
        .C_TAG_WIDTH    (C_TAG_WIDTH),
        .C_DATA_WIDTH   (C_DATA_WIDTH),
        .C_NUM_ENTRIES  (C_NUM_ENTRIES)
    ) ptab(
        .aclk(SYS_CLK),
        .areset(DETECT_RST),
        /* For I2C Interface */
        .col(col),
        .row(row),
        .wdata(wdata),
        .wen(wen),
        .rdata(parameter_table_rdata),
        .is_this_table(is_parameter_table),
        .DSID({DSid[4],DSid[3],DSid[2],DSid[1]}),
        /* AW channel */
        .TAG_A(TAG_A),
        .DO_A(DO_A ),
        .TAG_MATCH_A(TAG_MATCH_A),

        /* AR channel */
        .TAG_B(TAG_B),
        .DO_B(DO_B),
        .TAG_MATCH_B(TAG_MATCH_B)
    );


    mig_cp_stab stab(
        .aclk(SYS_CLK),
        .areset(DETECT_RST),
        .is_this_table(is_statistic_table),
        .col(col),
        .row(row),
        .wdata(APM_DATA),
        .wen(APM_VALID),

		.trigger_row(trigger_row),
		.trigger_metric(trigger_metric),
		.trigger_rdata(trigger_rdata),

        .rdata(statistic_table_rdata),
        .apm_axi_araddr(APM_ADDR)
    );

    ttab # (
		.CP_ID(8'd2)
	) mig_cp_ttab (
		.SYS_CLK(SYS_CLK),
		.DETECT_RST(DETECT_RST),
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
