`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICT, CAS
// Engineer: Jiuyue Ma
// 
// Create Date: 05/06/2015 09:00:55 AM
// Design Name: Control plane for memory controller
// Module Name: mig_control_plane
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
`include "../../include/axi.vh"
module mig_control_plane # (
    parameter C_DSID_WIDTH = 16,
    parameter C_NUM_ENTRIES = 2,
    parameter C_ADDR_WIDTH = 32
)(
    input  wire       aclk,
    input  wire       aresetn,
    /* I2C Interface */
    input [6:0] ADDR,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_I" *)
    input SCL_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_O" *)
    output SCL_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_T" *)
    output SCL_t,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_I" *)
    input SDA_i,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_O" *)
    output SDA_o,
	(* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_T" *)
    output SDA_t,
    /* APM Interface */
    input wire                          APM_VALID,
    input wire  [31:0]                  APM_ADDR ,
    input wire  [31:0]                  APM_DATA,

    /* Enables for cores' L1 traffic */
    output [C_NUM_ENTRIES - 1 : 0] L1enable,
	input trigger_axis_tready,
	output trigger_axis_tvalid,
	output [15:0] trigger_axis_tdata,

   `axi_in_interface(S_AXI, s_axi, 5),
   `axi_out_interface(M_AXI, m_axi, 5)
);

  localparam P_DATA_WIDTH = 64;

  localparam [1:0] DECODE_IDLE  = 2'b00 ;
  localparam [1:0] DECODE_BASE  = 2'b01 ;
  localparam [1:0] DECODE_LIMIT = 2'b11 ;
  

    //
    // Local Wire
    //
    wire       areset;
    
    // I2CIntf <=> RegIntf
    wire       stop_detect;
    wire [7:0] index_pointer;
    wire       write_enable;
    wire [7:0] receive_buffer;
    wire [7:0] send_buffer;

    // RegIntf <=> MigCPLogic
    wire [127:0] COMM_DATA ;
    wire         COMM_VALID ;
    wire         DATA_VALID ;
    wire [63:0]  DATA_RBACK;
    wire [63:0]  DATA_MASK;
    wire [1:0]   DATA_OFFSET;

    wire         table_cp_cmd_valid;

    assign areset = ~aresetn;

    I2CInterface i2c_intf_i (
        .RST(areset),
        .SYS_CLK(aclk),
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
    
    RegisterInterface # (
        .TYPE(8'h4D),                               // Type: 'M'
        .IDENT_LOW(32'h44524150),                   // IDENT: PARDMig7CP
        .IDENT_HIGH(64'h000050433767694D)
    )reg_intf_i (
        .RST(areset),
        .SYS_CLK(aclk),
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
        .COMM_VALID(COMM_VALID)
    );


    assign table_cp_cmd_valid = COMM_VALID & (~COMM_DATA[31]);
    
    wire [127:0] ptable_do_a;
    wire [127:0] ptable_do_b;
    
    mig_cp_detec_logic # (
        .C_ADDR_WIDTH(C_ADDR_WIDTH),
        .C_NUM_ENTRIES(C_NUM_ENTRIES)
    ) detc_logic_i(
        .SYS_CLK(aclk),
        .DETECT_RST(areset),
        .COMM_VALID(table_cp_cmd_valid),
        .COMM_DATA(COMM_DATA),
        .DATA_VALID(DATA_VALID),
        .DATA_RBACK(DATA_RBACK),
        .DATA_MASK(DATA_MASK),
        .DATA_OFFSET(DATA_OFFSET),
       
        .TAG_A    (s_axi_aw_bits_user),
        .DO_A     (ptable_do_a),
        .TAG_MATCH_A(w_match),

        /* AR channel */
        .TAG_B    (s_axi_ar_bits_user),
        .DO_B     (ptable_do_b),
        .TAG_MATCH_B(r_match),
        .APM_DATA(APM_DATA),
        .APM_VALID(APM_VALID),
        .APM_ADDR(APM_ADDR),

        .L1enable(L1enable),

		.trigger_axis_tready(trigger_axis_tready),
		.trigger_axis_tvalid(trigger_axis_tvalid),
		.trigger_axis_tdata(trigger_axis_tdata)
    );

    wire [31:0] w_base = ptable_do_a[31:0];
    wire [31:0] r_base = ptable_do_b[31:0];
    wire [31:0] w_limit = ptable_do_a[63:32];
    wire [31:0] r_limit = ptable_do_b[63:32];
    
    assign  m_axi_aw_bits_addr = {32{w_match}} & ((s_axi_aw_bits_addr & ~w_limit) | w_base);
    assign  m_axi_ar_bits_addr = {32{r_match}} & ((s_axi_ar_bits_addr & ~r_limit) | r_base);
    assign  m_axi_ar_bits_burst = s_axi_ar_bits_burst;
    assign  m_axi_ar_bits_cache = s_axi_ar_bits_cache;
    assign  m_axi_ar_bits_id    = s_axi_ar_bits_id   ;
    assign  m_axi_ar_bits_len   = s_axi_ar_bits_len  ;
    assign  m_axi_ar_bits_lock  = s_axi_ar_bits_lock ;
    assign  m_axi_ar_bits_prot  = s_axi_ar_bits_prot ;
    assign  s_axi_ar_ready = m_axi_ar_ready;
    assign  m_axi_ar_bits_size  = s_axi_ar_bits_size ;
    assign  m_axi_ar_valid = s_axi_ar_valid;
    assign  m_axi_aw_bits_burst = s_axi_aw_bits_burst;
    assign  m_axi_aw_bits_cache = s_axi_aw_bits_cache;
    assign  m_axi_aw_bits_id    = s_axi_aw_bits_id   ;
    assign  m_axi_aw_bits_len   = s_axi_aw_bits_len  ;
    assign  m_axi_aw_bits_lock  = s_axi_aw_bits_lock ;
    assign  m_axi_aw_bits_prot  = s_axi_aw_bits_prot ;
    assign  s_axi_aw_ready = m_axi_aw_ready;
    assign  m_axi_aw_bits_size  = s_axi_aw_bits_size ;
    assign  m_axi_aw_valid = s_axi_aw_valid;
    assign  s_axi_b_bits_id     = m_axi_b_bits_id    ;
    assign  m_axi_b_ready  = s_axi_b_ready ;
    assign  s_axi_b_bits_resp   = m_axi_b_bits_resp  ;
    assign  s_axi_b_valid  = m_axi_b_valid ;
    assign  s_axi_r_bits_data   = m_axi_r_bits_data  ;
    assign  s_axi_r_bits_id     = m_axi_r_bits_id    ;
    assign  s_axi_r_bits_last   = m_axi_r_bits_last  ;
    assign  m_axi_r_ready  = s_axi_r_ready ;
    assign  s_axi_r_bits_resp   = m_axi_r_bits_resp  ;
    assign  s_axi_r_valid  = m_axi_r_valid ;
    assign  m_axi_w_bits_data   = s_axi_w_bits_data  ;
    assign  m_axi_w_bits_last   = s_axi_w_bits_last  ;
    assign  s_axi_w_ready  = m_axi_w_ready ;
    assign  m_axi_w_bits_strb   = s_axi_w_bits_strb  ;
    assign  m_axi_w_valid  = s_axi_w_valid ;
    assign  m_axi_ar_bits_qos   = s_axi_ar_bits_qos  ;
    assign  m_axi_ar_bits_user  = s_axi_ar_bits_user ;
    assign  m_axi_aw_bits_qos   = s_axi_aw_bits_qos  ;
    assign  m_axi_aw_bits_user  = s_axi_aw_bits_user ;

endmodule
