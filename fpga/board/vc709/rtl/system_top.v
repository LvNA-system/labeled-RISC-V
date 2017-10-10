//Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2016.2 (lin64) Build 1577090 Thu Jun  2 16:32:35 MDT 2016
//Date        : Wed Sep  6 18:50:01 2017
//Host        : fsg-eda running 64-bit Debian GNU/Linux 9.1 (stretch)
//Command     : generate_target system_top_wrapper.bd
//Design      : system_top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

//`include "include/axi.vh"

module system_top (
  output [15:0]C0_DDR3_addr,
  output [2:0]C0_DDR3_ba,
  output C0_DDR3_cas_n,
  output [0:0]C0_DDR3_ck_n,
  output [0:0]C0_DDR3_ck_p,
  output [0:0]C0_DDR3_cke,
  output [0:0]C0_DDR3_cs_n,
  output [7:0]C0_DDR3_dm,
  inout [63:0]C0_DDR3_dq,
  inout [7:0]C0_DDR3_dqs_n,
  inout [7:0]C0_DDR3_dqs_p,
  output [0:0]C0_DDR3_odt,
  output C0_DDR3_ras_n,
  output C0_DDR3_reset_n,
  output C0_DDR3_we_n,
  input C0_SYS_CLK_clk_n,
  input C0_SYS_CLK_clk_p,
  output [15:0]C1_DDR3_addr,
  output [2:0]C1_DDR3_ba,
  output C1_DDR3_cas_n,
  output [0:0]C1_DDR3_ck_n,
  output [0:0]C1_DDR3_ck_p,
  output [0:0]C1_DDR3_cke,
  output [0:0]C1_DDR3_cs_n,
  output [7:0]C1_DDR3_dm,
  inout [63:0]C1_DDR3_dq,
  inout [7:0]C1_DDR3_dqs_n,
  inout [7:0]C1_DDR3_dqs_p,
  output [0:0]C1_DDR3_odt,
  output C1_DDR3_ras_n,
  output C1_DDR3_reset_n,
  output C1_DDR3_we_n,
  input [3:0]SFP_LOS,
  input [3:0]SFP_MOD_DETECT,
  output [3:0]SFP_RS0,
  output [3:0]SFP_TX_DISABLE,
  input UART_rxd,
  output UART_txd,
  input [2:0]buttons,
  inout i2c_clk,
  inout i2c_data,
  output i2c_mux_rst_n,
  output [7:0]leds,
  output [26:1]linear_flash_addr,
  output linear_flash_adv_ldn,
  output linear_flash_ce_n,
  inout [15:0]linear_flash_dq_io,
  output linear_flash_oen,
  output linear_flash_wen,
  input sfp_mgt_clk_clk_n,
  input sfp_mgt_clk_clk_p,
  input sfp_rxn,
  input sfp_rxp,
  output sfp_txn,
  output sfp_txp,
  output si5324_rst_n,
  input sys_rst
);

  wire [0:0]linear_flash_dq_i_0;
  wire [1:1]linear_flash_dq_i_1;
  wire [10:10]linear_flash_dq_i_10;
  wire [11:11]linear_flash_dq_i_11;
  wire [12:12]linear_flash_dq_i_12;
  wire [13:13]linear_flash_dq_i_13;
  wire [14:14]linear_flash_dq_i_14;
  wire [15:15]linear_flash_dq_i_15;
  wire [2:2]linear_flash_dq_i_2;
  wire [3:3]linear_flash_dq_i_3;
  wire [4:4]linear_flash_dq_i_4;
  wire [5:5]linear_flash_dq_i_5;
  wire [6:6]linear_flash_dq_i_6;
  wire [7:7]linear_flash_dq_i_7;
  wire [8:8]linear_flash_dq_i_8;
  wire [9:9]linear_flash_dq_i_9;
  wire [0:0]linear_flash_dq_io_0;
  wire [1:1]linear_flash_dq_io_1;
  wire [10:10]linear_flash_dq_io_10;
  wire [11:11]linear_flash_dq_io_11;
  wire [12:12]linear_flash_dq_io_12;
  wire [13:13]linear_flash_dq_io_13;
  wire [14:14]linear_flash_dq_io_14;
  wire [15:15]linear_flash_dq_io_15;
  wire [2:2]linear_flash_dq_io_2;
  wire [3:3]linear_flash_dq_io_3;
  wire [4:4]linear_flash_dq_io_4;
  wire [5:5]linear_flash_dq_io_5;
  wire [6:6]linear_flash_dq_io_6;
  wire [7:7]linear_flash_dq_io_7;
  wire [8:8]linear_flash_dq_io_8;
  wire [9:9]linear_flash_dq_io_9;
  wire [0:0]linear_flash_dq_o_0;
  wire [1:1]linear_flash_dq_o_1;
  wire [10:10]linear_flash_dq_o_10;
  wire [11:11]linear_flash_dq_o_11;
  wire [12:12]linear_flash_dq_o_12;
  wire [13:13]linear_flash_dq_o_13;
  wire [14:14]linear_flash_dq_o_14;
  wire [15:15]linear_flash_dq_o_15;
  wire [2:2]linear_flash_dq_o_2;
  wire [3:3]linear_flash_dq_o_3;
  wire [4:4]linear_flash_dq_o_4;
  wire [5:5]linear_flash_dq_o_5;
  wire [6:6]linear_flash_dq_o_6;
  wire [7:7]linear_flash_dq_o_7;
  wire [8:8]linear_flash_dq_o_8;
  wire [9:9]linear_flash_dq_o_9;
  wire [0:0]linear_flash_dq_t_0;
  wire [1:1]linear_flash_dq_t_1;
  wire [10:10]linear_flash_dq_t_10;
  wire [11:11]linear_flash_dq_t_11;
  wire [12:12]linear_flash_dq_t_12;
  wire [13:13]linear_flash_dq_t_13;
  wire [14:14]linear_flash_dq_t_14;
  wire [15:15]linear_flash_dq_t_15;
  wire [2:2]linear_flash_dq_t_2;
  wire [3:3]linear_flash_dq_t_3;
  wire [4:4]linear_flash_dq_t_4;
  wire [5:5]linear_flash_dq_t_5;
  wire [6:6]linear_flash_dq_t_6;
  wire [7:7]linear_flash_dq_t_7;
  wire [8:8]linear_flash_dq_t_8;
  wire [9:9]linear_flash_dq_t_9;

  IOBUF linear_flash_dq_iobuf_0
       (.I(linear_flash_dq_o_0),
        .IO(linear_flash_dq_io[0]),
        .O(linear_flash_dq_i_0),
        .T(linear_flash_dq_t_0));
  IOBUF linear_flash_dq_iobuf_1
       (.I(linear_flash_dq_o_1),
        .IO(linear_flash_dq_io[1]),
        .O(linear_flash_dq_i_1),
        .T(linear_flash_dq_t_1));
  IOBUF linear_flash_dq_iobuf_10
       (.I(linear_flash_dq_o_10),
        .IO(linear_flash_dq_io[10]),
        .O(linear_flash_dq_i_10),
        .T(linear_flash_dq_t_10));
  IOBUF linear_flash_dq_iobuf_11
       (.I(linear_flash_dq_o_11),
        .IO(linear_flash_dq_io[11]),
        .O(linear_flash_dq_i_11),
        .T(linear_flash_dq_t_11));
  IOBUF linear_flash_dq_iobuf_12
       (.I(linear_flash_dq_o_12),
        .IO(linear_flash_dq_io[12]),
        .O(linear_flash_dq_i_12),
        .T(linear_flash_dq_t_12));
  IOBUF linear_flash_dq_iobuf_13
       (.I(linear_flash_dq_o_13),
        .IO(linear_flash_dq_io[13]),
        .O(linear_flash_dq_i_13),
        .T(linear_flash_dq_t_13));
  IOBUF linear_flash_dq_iobuf_14
       (.I(linear_flash_dq_o_14),
        .IO(linear_flash_dq_io[14]),
        .O(linear_flash_dq_i_14),
        .T(linear_flash_dq_t_14));
  IOBUF linear_flash_dq_iobuf_15
       (.I(linear_flash_dq_o_15),
        .IO(linear_flash_dq_io[15]),
        .O(linear_flash_dq_i_15),
        .T(linear_flash_dq_t_15));
  IOBUF linear_flash_dq_iobuf_2
       (.I(linear_flash_dq_o_2),
        .IO(linear_flash_dq_io[2]),
        .O(linear_flash_dq_i_2),
        .T(linear_flash_dq_t_2));
  IOBUF linear_flash_dq_iobuf_3
       (.I(linear_flash_dq_o_3),
        .IO(linear_flash_dq_io[3]),
        .O(linear_flash_dq_i_3),
        .T(linear_flash_dq_t_3));
  IOBUF linear_flash_dq_iobuf_4
       (.I(linear_flash_dq_o_4),
        .IO(linear_flash_dq_io[4]),
        .O(linear_flash_dq_i_4),
        .T(linear_flash_dq_t_4));
  IOBUF linear_flash_dq_iobuf_5
       (.I(linear_flash_dq_o_5),
        .IO(linear_flash_dq_io[5]),
        .O(linear_flash_dq_i_5),
        .T(linear_flash_dq_t_5));
  IOBUF linear_flash_dq_iobuf_6
       (.I(linear_flash_dq_o_6),
        .IO(linear_flash_dq_io[6]),
        .O(linear_flash_dq_i_6),
        .T(linear_flash_dq_t_6));
  IOBUF linear_flash_dq_iobuf_7
       (.I(linear_flash_dq_o_7),
        .IO(linear_flash_dq_io[7]),
        .O(linear_flash_dq_i_7),
        .T(linear_flash_dq_t_7));
  IOBUF linear_flash_dq_iobuf_8
       (.I(linear_flash_dq_o_8),
        .IO(linear_flash_dq_io[8]),
        .O(linear_flash_dq_i_8),
        .T(linear_flash_dq_t_8));
  IOBUF linear_flash_dq_iobuf_9
       (.I(linear_flash_dq_o_9),
        .IO(linear_flash_dq_io[9]),
        .O(linear_flash_dq_i_9),
        .T(linear_flash_dq_t_9));

  `axi_wire(AXI_MEM, 64, 4);
//  `axi_wire(AXI_CDMA, 64, 1);

  wire SYS_UART0_rxd;
  wire SYS_UART0_txd;

  wire pardcore_coreclk;
  wire pardcore_corerstn;
  wire pardcore_uncoreclk;
  wire pardcore_uncore_rstn;
  wire pardcore_interconnect_rstn;

  prm prm_i
       (.C0_DDR3_addr(C0_DDR3_addr),
        .C0_DDR3_ba(C0_DDR3_ba),
        .C0_DDR3_cas_n(C0_DDR3_cas_n),
        .C0_DDR3_ck_n(C0_DDR3_ck_n),
        .C0_DDR3_ck_p(C0_DDR3_ck_p),
        .C0_DDR3_cke(C0_DDR3_cke),
        .C0_DDR3_cs_n(C0_DDR3_cs_n),
        .C0_DDR3_dm(C0_DDR3_dm),
        .C0_DDR3_dq(C0_DDR3_dq),
        .C0_DDR3_dqs_n(C0_DDR3_dqs_n),
        .C0_DDR3_dqs_p(C0_DDR3_dqs_p),
        .C0_DDR3_odt(C0_DDR3_odt),
        .C0_DDR3_ras_n(C0_DDR3_ras_n),
        .C0_DDR3_reset_n(C0_DDR3_reset_n),
        .C0_DDR3_we_n(C0_DDR3_we_n),
        .C0_SYS_CLK_clk_n(C0_SYS_CLK_clk_n),
        .C0_SYS_CLK_clk_p(C0_SYS_CLK_clk_p),
        .C1_DDR3_addr(C1_DDR3_addr),
        .C1_DDR3_ba(C1_DDR3_ba),
        .C1_DDR3_cas_n(C1_DDR3_cas_n),
        .C1_DDR3_ck_n(C1_DDR3_ck_n),
        .C1_DDR3_ck_p(C1_DDR3_ck_p),
        .C1_DDR3_cke(C1_DDR3_cke),
        .C1_DDR3_cs_n(C1_DDR3_cs_n),
        .C1_DDR3_dm(C1_DDR3_dm),
        .C1_DDR3_dq(C1_DDR3_dq),
        .C1_DDR3_dqs_n(C1_DDR3_dqs_n),
        .C1_DDR3_dqs_p(C1_DDR3_dqs_p),
        .C1_DDR3_odt(C1_DDR3_odt),
        .C1_DDR3_ras_n(C1_DDR3_ras_n),
        .C1_DDR3_reset_n(C1_DDR3_reset_n),
        .C1_DDR3_we_n(C1_DDR3_we_n),
        .SFP_LOS(SFP_LOS),
        .SFP_MOD_DETECT(SFP_MOD_DETECT),
        .SFP_RS0(SFP_RS0),
        .SFP_TX_DISABLE(SFP_TX_DISABLE),
        .SYS_UART0_rxd(SYS_UART0_rxd),
        .SYS_UART0_txd(SYS_UART0_txd),
        `axi_connect_if(S_AXI_MEM, AXI_MEM),
//        `axi_connect_if(M_AXI_CDMA, AXI_CDMA),
        .UART_rxd(UART_rxd),
        .UART_txd(UART_txd),
        .buttons(buttons),
        .i2c_clk(i2c_clk),
        .i2c_data(i2c_data),
        .i2c_mux_rst_n(i2c_mux_rst_n),
        .leds(leds),
        .linear_flash_addr(linear_flash_addr),
        .linear_flash_adv_ldn(linear_flash_adv_ldn),
        .linear_flash_ce_n(linear_flash_ce_n),
        .linear_flash_dq_i({linear_flash_dq_i_15,linear_flash_dq_i_14,linear_flash_dq_i_13,linear_flash_dq_i_12,linear_flash_dq_i_11,linear_flash_dq_i_10,linear_flash_dq_i_9,linear_flash_dq_i_8,linear_flash_dq_i_7,linear_flash_dq_i_6,linear_flash_dq_i_5,linear_flash_dq_i_4,linear_flash_dq_i_3,linear_flash_dq_i_2,linear_flash_dq_i_1,linear_flash_dq_i_0}),
        .linear_flash_dq_o({linear_flash_dq_o_15,linear_flash_dq_o_14,linear_flash_dq_o_13,linear_flash_dq_o_12,linear_flash_dq_o_11,linear_flash_dq_o_10,linear_flash_dq_o_9,linear_flash_dq_o_8,linear_flash_dq_o_7,linear_flash_dq_o_6,linear_flash_dq_o_5,linear_flash_dq_o_4,linear_flash_dq_o_3,linear_flash_dq_o_2,linear_flash_dq_o_1,linear_flash_dq_o_0}),
        .linear_flash_dq_t({linear_flash_dq_t_15,linear_flash_dq_t_14,linear_flash_dq_t_13,linear_flash_dq_t_12,linear_flash_dq_t_11,linear_flash_dq_t_10,linear_flash_dq_t_9,linear_flash_dq_t_8,linear_flash_dq_t_7,linear_flash_dq_t_6,linear_flash_dq_t_5,linear_flash_dq_t_4,linear_flash_dq_t_3,linear_flash_dq_t_2,linear_flash_dq_t_1,linear_flash_dq_t_0}),
        .linear_flash_oen(linear_flash_oen),
        .linear_flash_wen(linear_flash_wen),
        .sfp_mgt_clk_clk_n(sfp_mgt_clk_clk_n),
        .sfp_mgt_clk_clk_p(sfp_mgt_clk_clk_p),
        .sfp_rxn(sfp_rxn),
        .sfp_rxp(sfp_rxp),
        .sfp_txn(sfp_txn),
        .sfp_txp(sfp_txp),
        .pardcore_coreclk(pardcore_coreclk),
        .pardcore_corerstn(pardcore_corerstn),
        .pardcore_uncoreclk(pardcore_uncoreclk),
        .pardcore_uncore_rstn(pardcore_uncore_rstn),
        .pardcore_interconnect_rstn(pardcore_interconnect_rstn),
        .si5324_rst_n(si5324_rst_n),
        .sys_rst(sys_rst));


  pardcore pardcore_i(
    .coreclk(pardcore_coreclk),
    .corerst0(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk),
    .interconnect_rstn(pardcore_interconnect_rstn),
    .uncore_rstn(pardcore_uncore_rstn),
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
//    `axi_connect_if(S_AXI_CDMA, AXI_CDMA),
    .UART0_rxd(SYS_UART0_txd),
    .UART0_txd(SYS_UART0_rxd),
    .UART1_rxd(),
    .UART1_txd()
  );
endmodule
