`include "axi.vh"

module system_top (
  output C0_DDR4_act_n,
  output [16:0]C0_DDR4_adr,
  output [1:0]C0_DDR4_ba,
  output C0_DDR4_bg,
  output C0_DDR4_ck_c,
  output C0_DDR4_ck_t,
  output C0_DDR4_cke,
  output C0_DDR4_cs_n,
  inout [1:0]C0_DDR4_dm_n,
  inout [15:0]C0_DDR4_dq,
  inout [1:0]C0_DDR4_dqs_c,
  inout [1:0]C0_DDR4_dqs_t,
  output C0_DDR4_odt,
  output C0_DDR4_reset_n,
  input C0_SYS_CLK_clk_n,
  input C0_SYS_CLK_clk_p
);

  `axi_wire(AXI_MEM, 64, 4);

  wire pardcore_coreclk;
  wire [1:0] pardcore_corerstn;
  wire pardcore_uncoreclk;
  wire pardcore_uncorerstn;
  wire SYS_UART0_rxd;
  wire SYS_UART0_txd;
  wire SYS_UART1_rxd;
  wire SYS_UART1_txd;

  zynq_soc zynq_soc_i (
    .C0_DDR4_act_n(C0_DDR4_act_n),
    .C0_DDR4_adr(C0_DDR4_adr),
    .C0_DDR4_ba(C0_DDR4_ba),
    .C0_DDR4_bg(C0_DDR4_bg),
    .C0_DDR4_ck_c(C0_DDR4_ck_c),
    .C0_DDR4_ck_t(C0_DDR4_ck_t),
    .C0_DDR4_cke(C0_DDR4_cke),
    .C0_DDR4_cs_n(C0_DDR4_cs_n),
    .C0_DDR4_dm_n(C0_DDR4_dm_n),
    .C0_DDR4_dq(C0_DDR4_dq),
    .C0_DDR4_dqs_c(C0_DDR4_dqs_c),
    .C0_DDR4_dqs_t(C0_DDR4_dqs_t),
    .C0_DDR4_odt(C0_DDR4_odt),
    .C0_DDR4_reset_n(C0_DDR4_reset_n),
    .C0_SYS_CLK_clk_n(C0_SYS_CLK_clk_n),
    .C0_SYS_CLK_clk_p(C0_SYS_CLK_clk_p),

    `axi_connect_if(S_AXI_MEM, AXI_MEM),

    .UART_0_txd(SYS_UART0_txd),
    .UART_0_rxd(SYS_UART0_rxd),
    .UART_1_txd(SYS_UART1_txd),
    .UART_1_rxd(SYS_UART1_rxd),

    .pardcore_coreclk(pardcore_coreclk),
    .pardcore_corerstn(pardcore_corerstn),
    .pardcore_uncoreclk(pardcore_uncoreclk),
    .pardcore_uncorerstn(pardcore_uncorerstn)
  );

  pardcore pardcore_i(
    .coreclk(pardcore_coreclk),
    .corersts(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk),
    .uncore_rstn(pardcore_uncorerstn),
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
//    `axi_connect_if(S_AXI_CDMA, AXI_CDMA),
    .UART0_rxd(SYS_UART0_txd),
    .UART0_txd(SYS_UART0_rxd),
    .UART1_rxd(SYS_UART1_txd),
    .UART1_txd(SYS_UART1_rxd)
  );

endmodule
