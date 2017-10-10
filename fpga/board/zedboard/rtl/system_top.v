`include "axi.vh"

module system_top (
  inout [14:0] DDR_addr,
  inout [2:0] DDR_ba,
  inout DDR_cas_n,
  inout DDR_ck_n,
  inout DDR_ck_p,
  inout DDR_cke,
  inout DDR_cs_n,
  inout [3:0] DDR_dm,
  inout [31:0] DDR_dq,
  inout [3:0] DDR_dqs_n,
  inout [3:0] DDR_dqs_p,
  inout DDR_odt,
  inout DDR_ras_n,
  inout DDR_reset_n,
  inout DDR_we_n,
  inout FIXED_IO_ddr_vrn,
  inout FIXED_IO_ddr_vrp,
  inout [53:0] FIXED_IO_mio,
  inout FIXED_IO_ps_clk,
  inout FIXED_IO_ps_porb,
  inout FIXED_IO_ps_srstb
);

  `axi_wire(AXI_MEM_MAPPED, 64, 4);
  `axi_wire(AXI_MEM, 64, 4);

  wire pardcore_coreclk;
  wire pardcore_corerstn;
  wire pardcore_uncoreclk;
  wire pardcore_interconnect_rstn;
  wire pardcore_uncorerstn;
  wire SYS_UART0_rxd;
  wire SYS_UART0_txd;

  zynq_soc zynq_soc_i (
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),

    `axi_connect_if(S_AXI_MEM, AXI_MEM_MAPPED),

    .UART_0_txd(SYS_UART0_txd),
    .UART_0_rxd(SYS_UART0_rxd),

    .pardcore_coreclk(pardcore_coreclk),
    .pardcore_corerstn(pardcore_corerstn),
    .pardcore_uncoreclk(pardcore_uncoreclk),
    .pardcore_interconnect_rstn(pardcore_interconnect_rstn),
    .pardcore_uncorerstn(pardcore_uncorerstn)
  );

  addr_mapper addr_mapper_i(
    `axi_connect_if(s_axi, AXI_MEM),
    `axi_connect_if(m_axi, AXI_MEM_MAPPED)
  );

  pardcore pardcore_i(
    .coreclk(pardcore_coreclk),
    .corerst0(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk),
    .interconnect_rstn(pardcore_interconnect_rstn),
    .uncore_rstn(pardcore_uncorerstn),
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
//    `axi_connect_if(S_AXI_CDMA, AXI_CDMA),
    .UART0_rxd(SYS_UART0_txd),
    .UART0_txd(SYS_UART0_rxd),
    .UART1_rxd(),
    .UART1_txd()
  );

endmodule
