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
`include "../include/dmi.vh"

module rocketchip_top(
  input coreclk0,
  input corerst0,
  input coreclk1,
  input corerst1,
  input [2:0] L1enable,  // For nTiles = 2 and one traffic generator
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 uncoreclk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF M_AXI_MEM:M_AXI_MMIO:M_AXI_CDMA, ASSOCIATED_RESET uncorerst, FREQ_HZ 50000000" *)
  input   uncoreclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 uncorerst RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
  input   uncorerst,

  `axi_out_interface(M_AXI_MEM, io_mem_axi_0, 4),
  `axi_out_interface(M_AXI_MMIO, axi_uart, 4),
  `axi_in_interface(M_AXI_CDMA, axi_cdma, 4),
  input  [1:0] io_interrupts,

  output [1:0] io_ila_0_hartid,
  output [31:0] io_ila_0_csr_time,
  output [39:0] io_ila_0_pc,
  output        io_ila_0_instr_valid,
  output [31:0] io_ila_0_instr,
  output        io_ila_0_rd_wen,
  output [4:0]  io_ila_0_rd_waddr,
  output [63:0] io_ila_0_rd_wdata,
  output [4:0]  io_ila_0_rs_raddr,
  output [63:0] io_ila_0_rs_rdata,
  output [4:0]  io_ila_0_rt_raddr,
  output [63:0] io_ila_0_rt_rdata,
  output [1:0] io_ila_1_hartid,
  output [31:0] io_ila_1_csr_time,
  output [39:0] io_ila_1_pc,
  output        io_ila_1_instr_valid,
  output [31:0] io_ila_1_instr,
  output        io_ila_1_rd_wen,
  output [4:0]  io_ila_1_rd_waddr,
  output [63:0] io_ila_1_rd_wdata,
  output [4:0]  io_ila_1_rs_raddr,
  output [63:0] io_ila_1_rs_rdata,
  output [4:0]  io_ila_1_rt_raddr,
  output [63:0] io_ila_1_rt_rdata,

  input io_debug_clk0,
  input io_debug_rst0,
  `dmi_slave(DMI, io_debug)
);

PARDFPGATop top(
   .clock(uncoreclk),
   .reset(uncorerst),
   .io_tcrs_0_clock(coreclk0),
   .io_tcrs_1_clock(coreclk1),
   .io_tcrs_0_reset(corerst0),
   .io_tcrs_1_reset(corerst1),
   .io_interrupts(io_interrupts_0),
   .io_L1enable_0(L1enable[0]),
   .io_L1enable_1(L1enable[1]),
   .io_trafficGeneratorEnable(L1enable[2]),

   `axi_connect_interface(io_mem_axi4_0, io_mem_axi_0),
   `axi_connect_interface(io_mmio_axi4_0, axi_uart),
   `axi_connect_interface(io_l2_frontend_bus_axi4_0, axi_cdma),

   .io_ila_0_hartid(io_ila_0_hartid),
   .io_ila_0_csr_time(io_ila_0_csr_time),
   .io_ila_0_pc(io_ila_0_pc),
   .io_ila_0_instr_valid(io_ila_0_instr_valid),
   .io_ila_0_instr(io_ila_0_instr),
   .io_ila_0_rd_wen(io_ila_0_rd_wen),
   .io_ila_0_rd_waddr(io_ila_0_rd_waddr),
   .io_ila_0_rd_wdata(io_ila_0_rd_wdata),
   .io_ila_0_rs_raddr(io_ila_0_rs_raddr),
   .io_ila_0_rs_rdata(io_ila_0_rs_rdata),
   .io_ila_0_rt_raddr(io_ila_0_rt_raddr),
   .io_ila_0_rt_rdata(io_ila_0_rt_rdata),

   .io_ila_1_hartid(io_ila_1_hartid),
   .io_ila_1_csr_time(io_ila_1_csr_time),
   .io_ila_1_pc(io_ila_1_pc),
   .io_ila_1_instr_valid(io_ila_1_instr_valid),
   .io_ila_1_instr(io_ila_1_instr),
   .io_ila_1_rd_wen(io_ila_1_rd_wen),
   .io_ila_1_rd_waddr(io_ila_1_rd_waddr),
   .io_ila_1_rd_wdata(io_ila_1_rd_wdata),
   .io_ila_1_rs_raddr(io_ila_1_rs_raddr),
   .io_ila_1_rs_rdata(io_ila_1_rs_rdata),
   .io_ila_1_rt_raddr(io_ila_1_rt_raddr),
   .io_ila_1_rt_rdata(io_ila_1_rt_rdata),

   .io_debug_dmiClock(io_debug_clk0),
   .io_debug_dmiReset(io_debug_rst0),
   .`dmi_connect(io_debug_dmi, io_debug)
);

endmodule
