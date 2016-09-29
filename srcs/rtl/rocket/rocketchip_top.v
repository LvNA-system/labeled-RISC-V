`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/29/2016 02:59:10 PM
// Design Name: 
// Module Name: FPGAtop
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


module rocketchip_top(
  input coreclk,
  input corerst,
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 uncoreclk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI_MEM:M_AXI_MMIO, ASSOCIATED_RESET reset, FREQ_HZ 80000000" *)
  input   uncoreclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 uncorerst RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input   uncorerst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWREADY" *)
  input   io_mem_axi_0_aw_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWVALID" *)
  output  io_mem_axi_0_aw_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWADDR" *)
  output [31:0] io_mem_axi_0_aw_bits_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWLEN" *)
  output [7:0] io_mem_axi_0_aw_bits_len,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWSIZE" *)
  output [2:0] io_mem_axi_0_aw_bits_size,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWBURST" *)
  output [1:0] io_mem_axi_0_aw_bits_burst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWLOCK" *)
  output  io_mem_axi_0_aw_bits_lock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWCACHE" *)
  output [3:0] io_mem_axi_0_aw_bits_cache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWPROT" *)
  output [2:0] io_mem_axi_0_aw_bits_prot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWQOS" *)
  output [3:0] io_mem_axi_0_aw_bits_qos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWREGION" *)
  output [3:0] io_mem_axi_0_aw_bits_region,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWID" *)
  output [4:0] io_mem_axi_0_aw_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM AWUSER" *)
  output  io_mem_axi_0_aw_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WREADY" *)
  input   io_mem_axi_0_w_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WVALID" *)
  output  io_mem_axi_0_w_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WDATA" *)
  output [63:0] io_mem_axi_0_w_bits_data,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WLAST" *)
  output  io_mem_axi_0_w_bits_last,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WID" *)
  output [4:0] io_mem_axi_0_w_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WSTRB" *)
  output [7:0] io_mem_axi_0_w_bits_strb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM WUSER" *)
  output  io_mem_axi_0_w_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM BREADY" *)
  output  io_mem_axi_0_b_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM BVALID" *)
  input   io_mem_axi_0_b_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM BRESP" *)
  input  [1:0] io_mem_axi_0_b_bits_resp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM BID" *)
  input  [4:0] io_mem_axi_0_b_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM BUSER" *)
  input   io_mem_axi_0_b_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARREADY" *)
  input   io_mem_axi_0_ar_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARVALID" *)
  output  io_mem_axi_0_ar_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARADDR" *)
  output [31:0] io_mem_axi_0_ar_bits_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARLEN" *)
  output [7:0] io_mem_axi_0_ar_bits_len,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARSIZE" *)
  output [2:0] io_mem_axi_0_ar_bits_size,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARBURST" *)
  output [1:0] io_mem_axi_0_ar_bits_burst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARLOCK" *)
  output  io_mem_axi_0_ar_bits_lock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARCACHE" *)
  output [3:0] io_mem_axi_0_ar_bits_cache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARPROT" *)
  output [2:0] io_mem_axi_0_ar_bits_prot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARQOS" *)
  output [3:0] io_mem_axi_0_ar_bits_qos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARREGION" *)
  output [3:0] io_mem_axi_0_ar_bits_region,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARID" *)
  output [4:0] io_mem_axi_0_ar_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM ARUSER" *)
  output  io_mem_axi_0_ar_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RREADY" *)
  output  io_mem_axi_0_r_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RVALID" *)
  input   io_mem_axi_0_r_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RRESP" *)
  input  [1:0] io_mem_axi_0_r_bits_resp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RDATA" *)
  input  [63:0] io_mem_axi_0_r_bits_data,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RLAST" *)
  input   io_mem_axi_0_r_bits_last,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RID" *)
  input  [4:0] io_mem_axi_0_r_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MEM RUSER" *)
  input   io_mem_axi_0_r_bits_user,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWREADY" *)
  input   io_mmio_axi_0_aw_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWVALID" *)
  output  io_mmio_axi_0_aw_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWADDR" *)
  output [31:0] io_mmio_axi_0_aw_bits_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWLEN" *)
  output [7:0] io_mmio_axi_0_aw_bits_len,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWSIZE" *)
  output [2:0] io_mmio_axi_0_aw_bits_size,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWBURST" *)
  output [1:0] io_mmio_axi_0_aw_bits_burst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWLOCK" *)
  output  io_mmio_axi_0_aw_bits_lock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWCACHE" *)
  output [3:0] io_mmio_axi_0_aw_bits_cache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWPROT" *)
  output [2:0] io_mmio_axi_0_aw_bits_prot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWQOS" *)
  output [3:0] io_mmio_axi_0_aw_bits_qos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWREGION" *)
  output [3:0] io_mmio_axi_0_aw_bits_region,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWID" *)
  output [4:0] io_mmio_axi_0_aw_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO AWUSER" *)
  output  io_mmio_axi_0_aw_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WREADY" *)
  input   io_mmio_axi_0_w_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WVALID" *)
  output  io_mmio_axi_0_w_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WDATA" *)
  output [63:0] io_mmio_axi_0_w_bits_data,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WLAST" *)
  output  io_mmio_axi_0_w_bits_last,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WID" *)
  output [4:0] io_mmio_axi_0_w_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WSTRB" *)
  output [7:0] io_mmio_axi_0_w_bits_strb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO WUSER" *)
  output  io_mmio_axi_0_w_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO BREADY" *)
  output  io_mmio_axi_0_b_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO BVALID" *)
  input   io_mmio_axi_0_b_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO BRESP" *)
  input  [1:0] io_mmio_axi_0_b_bits_resp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO BID" *)
  input  [4:0] io_mmio_axi_0_b_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO BUSER" *)
  input   io_mmio_axi_0_b_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARREADY" *)
  input   io_mmio_axi_0_ar_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARVALID" *)
  output  io_mmio_axi_0_ar_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARADDR" *)
  output [31:0] io_mmio_axi_0_ar_bits_addr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARLEN" *)
  output [7:0] io_mmio_axi_0_ar_bits_len,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARSIZE" *)
  output [2:0] io_mmio_axi_0_ar_bits_size,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARBURST" *)
  output [1:0] io_mmio_axi_0_ar_bits_burst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARLOCK" *)
  output  io_mmio_axi_0_ar_bits_lock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARCACHE" *)
  output [3:0] io_mmio_axi_0_ar_bits_cache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARPROT" *)
  output [2:0] io_mmio_axi_0_ar_bits_prot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARQOS" *)
  output [3:0] io_mmio_axi_0_ar_bits_qos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARREGION" *)
  output [3:0] io_mmio_axi_0_ar_bits_region,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARID" *)
  output [4:0] io_mmio_axi_0_ar_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO ARUSER" *)
  output  io_mmio_axi_0_ar_bits_user,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RREADY" *)
  output  io_mmio_axi_0_r_ready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RVALID" *)
  input   io_mmio_axi_0_r_valid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RRESP" *)
  input  [1:0] io_mmio_axi_0_r_bits_resp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RDATA" *)
  input  [63:0] io_mmio_axi_0_r_bits_data,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RLAST" *)
  input   io_mmio_axi_0_r_bits_last,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RID" *)
  input  [4:0] io_mmio_axi_0_r_bits_id,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI_MMIO RUSER" *)
  input   io_mmio_axi_0_r_bits_user,

  input   io_interrupts_0,
  input   io_interrupts_1,
  output  io_debug_req_ready,
  input   io_debug_req_valid,
  input  [4:0] io_debug_req_bits_addr,
  input  [1:0] io_debug_req_bits_op,
  input  [33:0] io_debug_req_bits_data,
  input   io_debug_resp_ready,
  output  io_debug_resp_valid,
  output [1:0] io_debug_resp_bits_resp,
  output [33:0] io_debug_resp_bits_data
);

ExampleMultiClockTop top(
   .clock(uncoreclk),
   .reset(uncorerst),
   .io_coreclk(coreclk),
   .io_corerst(corerst),
   .io_mem_axi_0_aw_ready(io_mem_axi_0_aw_ready),
   .io_mem_axi_0_aw_valid(io_mem_axi_0_aw_valid),
   .io_mem_axi_0_aw_bits_addr(io_mem_axi_0_aw_bits_addr),
   .io_mem_axi_0_aw_bits_len(io_mem_axi_0_aw_bits_len),
   .io_mem_axi_0_aw_bits_size(io_mem_axi_0_aw_bits_size),
   .io_mem_axi_0_aw_bits_burst(io_mem_axi_0_aw_bits_burst),
   .io_mem_axi_0_aw_bits_lock(io_mem_axi_0_aw_bits_lock),
   .io_mem_axi_0_aw_bits_cache(io_mem_axi_0_aw_bits_cache),
   .io_mem_axi_0_aw_bits_prot(io_mem_axi_0_aw_bits_prot),
   .io_mem_axi_0_aw_bits_qos(io_mem_axi_0_aw_bits_qos),
   .io_mem_axi_0_aw_bits_region(io_mem_axi_0_aw_bits_region),
   .io_mem_axi_0_aw_bits_id(io_mem_axi_0_aw_bits_id),
   .io_mem_axi_0_aw_bits_user(io_mem_axi_0_aw_bits_user),
   .io_mem_axi_0_w_ready(io_mem_axi_0_w_ready),
   .io_mem_axi_0_w_valid(io_mem_axi_0_w_valid),
   .io_mem_axi_0_w_bits_data(io_mem_axi_0_w_bits_data),
   .io_mem_axi_0_w_bits_last(io_mem_axi_0_w_bits_last),
   .io_mem_axi_0_w_bits_id(io_mem_axi_0_w_bits_id),
   .io_mem_axi_0_w_bits_strb(io_mem_axi_0_w_bits_strb),
   .io_mem_axi_0_w_bits_user(io_mem_axi_0_w_bits_user),
   .io_mem_axi_0_b_ready(io_mem_axi_0_b_ready),
   .io_mem_axi_0_b_valid(io_mem_axi_0_b_valid),
   .io_mem_axi_0_b_bits_resp(io_mem_axi_0_b_bits_resp),
   .io_mem_axi_0_b_bits_id(io_mem_axi_0_b_bits_id),
   .io_mem_axi_0_b_bits_user(io_mem_axi_0_b_bits_user),
   .io_mem_axi_0_ar_ready(io_mem_axi_0_ar_ready),
   .io_mem_axi_0_ar_valid(io_mem_axi_0_ar_valid),
   .io_mem_axi_0_ar_bits_addr(io_mem_axi_0_ar_bits_addr),
   .io_mem_axi_0_ar_bits_len(io_mem_axi_0_ar_bits_len),
   .io_mem_axi_0_ar_bits_size(io_mem_axi_0_ar_bits_size),
   .io_mem_axi_0_ar_bits_burst(io_mem_axi_0_ar_bits_burst),
   .io_mem_axi_0_ar_bits_lock(io_mem_axi_0_ar_bits_lock),
   .io_mem_axi_0_ar_bits_cache(io_mem_axi_0_ar_bits_cache),
   .io_mem_axi_0_ar_bits_prot(io_mem_axi_0_ar_bits_prot),
   .io_mem_axi_0_ar_bits_qos(io_mem_axi_0_ar_bits_qos),
   .io_mem_axi_0_ar_bits_region(io_mem_axi_0_ar_bits_region),
   .io_mem_axi_0_ar_bits_id(io_mem_axi_0_ar_bits_id),
   .io_mem_axi_0_ar_bits_user(io_mem_axi_0_ar_bits_user),
   .io_mem_axi_0_r_ready(io_mem_axi_0_r_ready),
   .io_mem_axi_0_r_valid(io_mem_axi_0_r_valid),
   .io_mem_axi_0_r_bits_resp(io_mem_axi_0_r_bits_resp),
   .io_mem_axi_0_r_bits_data(io_mem_axi_0_r_bits_data),
   .io_mem_axi_0_r_bits_last(io_mem_axi_0_r_bits_last),
   .io_mem_axi_0_r_bits_id(io_mem_axi_0_r_bits_id),
   .io_mem_axi_0_r_bits_user(io_mem_axi_0_r_bits_user),
   .io_interrupts_0(io_interrupts_0),
   .io_interrupts_1(io_interrupts_1),

   .io_mmio_axi_0_aw_ready(io_mmio_axi_0_aw_ready),
   .io_mmio_axi_0_aw_valid(io_mmio_axi_0_aw_valid),
   .io_mmio_axi_0_aw_bits_addr(io_mmio_axi_0_aw_bits_addr),
   .io_mmio_axi_0_aw_bits_len(io_mmio_axi_0_aw_bits_len),
   .io_mmio_axi_0_aw_bits_size(io_mmio_axi_0_aw_bits_size),
   .io_mmio_axi_0_aw_bits_burst(io_mmio_axi_0_aw_bits_burst),
   .io_mmio_axi_0_aw_bits_lock(io_mmio_axi_0_aw_bits_lock),
   .io_mmio_axi_0_aw_bits_cache(io_mmio_axi_0_aw_bits_cache),
   .io_mmio_axi_0_aw_bits_prot(io_mmio_axi_0_aw_bits_prot),
   .io_mmio_axi_0_aw_bits_qos(io_mmio_axi_0_aw_bits_qos),
   .io_mmio_axi_0_aw_bits_region(io_mmio_axi_0_aw_bits_region),
   .io_mmio_axi_0_aw_bits_id(io_mmio_axi_0_aw_bits_id),
   .io_mmio_axi_0_aw_bits_user(io_mmio_axi_0_aw_bits_user),
   .io_mmio_axi_0_w_ready(io_mmio_axi_0_w_ready),
   .io_mmio_axi_0_w_valid(io_mmio_axi_0_w_valid),
   .io_mmio_axi_0_w_bits_data(io_mmio_axi_0_w_bits_data),
   .io_mmio_axi_0_w_bits_last(io_mmio_axi_0_w_bits_last),
   .io_mmio_axi_0_w_bits_id(io_mmio_axi_0_w_bits_id),
   .io_mmio_axi_0_w_bits_strb(io_mmio_axi_0_w_bits_strb),
   .io_mmio_axi_0_w_bits_user(io_mmio_axi_0_w_bits_user),
   .io_mmio_axi_0_b_ready(io_mmio_axi_0_b_ready),
   .io_mmio_axi_0_b_valid(io_mmio_axi_0_b_valid),
   .io_mmio_axi_0_b_bits_resp(io_mmio_axi_0_b_bits_resp),
   .io_mmio_axi_0_b_bits_id(io_mmio_axi_0_b_bits_id),
   .io_mmio_axi_0_b_bits_user(io_mmio_axi_0_b_bits_user),
   .io_mmio_axi_0_ar_ready(io_mmio_axi_0_ar_ready),
   .io_mmio_axi_0_ar_valid(io_mmio_axi_0_ar_valid),
   .io_mmio_axi_0_ar_bits_addr(io_mmio_axi_0_ar_bits_addr),
   .io_mmio_axi_0_ar_bits_len(io_mmio_axi_0_ar_bits_len),
   .io_mmio_axi_0_ar_bits_size(io_mmio_axi_0_ar_bits_size),
   .io_mmio_axi_0_ar_bits_burst(io_mmio_axi_0_ar_bits_burst),
   .io_mmio_axi_0_ar_bits_lock(io_mmio_axi_0_ar_bits_lock),
   .io_mmio_axi_0_ar_bits_cache(io_mmio_axi_0_ar_bits_cache),
   .io_mmio_axi_0_ar_bits_prot(io_mmio_axi_0_ar_bits_prot),
   .io_mmio_axi_0_ar_bits_qos(io_mmio_axi_0_ar_bits_qos),
   .io_mmio_axi_0_ar_bits_region(io_mmio_axi_0_ar_bits_region),
   .io_mmio_axi_0_ar_bits_id(io_mmio_axi_0_ar_bits_id),
   .io_mmio_axi_0_ar_bits_user(io_mmio_axi_0_ar_bits_user),
   .io_mmio_axi_0_r_ready(io_mmio_axi_0_r_ready),
   .io_mmio_axi_0_r_valid(io_mmio_axi_0_r_valid),
   .io_mmio_axi_0_r_bits_resp(io_mmio_axi_0_r_bits_resp),
   .io_mmio_axi_0_r_bits_data(io_mmio_axi_0_r_bits_data),
   .io_mmio_axi_0_r_bits_last(io_mmio_axi_0_r_bits_last),
   .io_mmio_axi_0_r_bits_id(io_mmio_axi_0_r_bits_id),
   .io_mmio_axi_0_r_bits_user(io_mmio_axi_0_r_bits_user),

   .io_debug_req_ready(io_debug_req_ready),
   .io_debug_req_valid(io_debug_req_valid),
   .io_debug_req_bits_addr(io_debug_req_bits_addr),
   .io_debug_req_bits_op(io_debug_req_bits_op),
   .io_debug_req_bits_data(io_debug_req_bits_data),
   .io_debug_resp_ready(io_debug_resp_ready),
   .io_debug_resp_valid(io_debug_resp_valid),
   .io_debug_resp_bits_resp(io_debug_resp_bits_resp),
   .io_debug_resp_bits_data(io_debug_resp_bits_data)
);

endmodule
