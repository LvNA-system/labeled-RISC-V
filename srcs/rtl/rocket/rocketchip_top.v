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

`include "../include/axi.vh"

module rocketchip_top(
  input coreclk,
  input corerst,
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 uncoreclk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI_MEM:M_AXI_MMIO:M_AXI_CDMA, ASSOCIATED_RESET uncorerst, FREQ_HZ 80000000" *)
  input   uncoreclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 uncorerst RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input   uncorerst,

  `axi_out_interface(M_AXI_MEM, io_mem_axi_0, 4),
  `axi_out_interface(M_AXI_MMIO, axi_uart, 4),
  `axi_in_interface(M_AXI_CDMA, axi_cdma, 4),
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

ExampleRocketTop top(
   .clock(uncoreclk),
   .reset(uncorerst),
   .io_coreclk(coreclk),
   .io_corerst(corerst),
   .io_interrupts_0_0(io_interrupts_0),
   .io_interrupts_0_1(io_interrupts_1),

   `axi_connect_interface(io_mem_axi4_0, io_mem_axi_0),
   `axi_connect_interface(io_mmio_axi4_0, axi_uart),
   `axi_connect_interface(io_l2_axi4_0, axi_cdma),

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
