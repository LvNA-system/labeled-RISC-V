`include "axi.vh"

module system_top (
  output [7:0] led,
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

  `axi_wire(AXI_MEM_MAPPED, 64, 1);
  `axi_wire(AXI_MEM, 64, 1);
  `axilite_wire(AXILITE_MMIO);
  `axi_wire(AXI_DMA, 64, 1);

  `axi_wire(AXI_SBUS_FROM_ZYNQ, 64, 1);
  `axi_wire(AXI_SBUS_TO_ROCKET, 64, 16);

  wire jtag_TCK;
  wire jtag_TMS;
  wire jtag_TDI;
  wire jtag_TDO;
  wire jtag_TRST;

  wire pardcore_coreclk;
  wire [1:0] pardcore_corerstn;
  wire pardcore_uncoreclk;
  wire pardcore_uncorerstn;
  wire [2:0] nohype_settings;

  wire mm2s_introut;
  wire s2mm_introut;

  zynq_soc zynq_soc_i (
    `axi_connect_if_no_id(M_AXI_FBUS, AXI_SBUS_FROM_ZYNQ),

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
    `axi_connect_if_no_id(M_AXI_DMA, AXI_DMA),
    `axilite_connect_if(S_AXILITE_MMIO, AXILITE_MMIO),

    .nohype_settings(nohype_settings),
    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),

    .led(led[6:0]),

    .mm2s_introut(mm2s_introut),
    .s2mm_introut(s2mm_introut),

    .pardcore_coreclk(pardcore_coreclk),
    .pardcore_corerstn(pardcore_corerstn),
    .pardcore_uncoreclk(pardcore_uncoreclk),
    .pardcore_uncorerstn(pardcore_uncorerstn)
  );

  addr_mapper addr_mapper_i(
    `axi_connect_if(s_axi, AXI_MEM),
    `axi_connect_if(m_axi, AXI_MEM_MAPPED)
  );

  dma_addr_mapper dma_addr_mapper_i(
    `axi_connect_if(s_axi, AXI_SBUS_FROM_ZYNQ),
    `axi_connect_if(m_axi, AXI_SBUS_TO_ROCKET)
  );

  pardcore pardcore_i(
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
    `axi_connect_if(S_AXI_DMA, AXI_DMA),
    `axilite_connect_if(M_AXILITE_MMIO, AXILITE_MMIO),
    `axi_connect_if(S_AXI_SBUS, AXI_SBUS_TO_ROCKET),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),
    .jtag_TRST(~pardcore_corerstn),

    .intrs({s2mm_introut, mm2s_introut}),

    .led(led[7]),

    .mem_part_en(nohype_settings[0]),
    .reset_to_hang_en(nohype_settings[1]),
    .distinct_hart_dsid_en(nohype_settings[2]),

    .coreclk(pardcore_coreclk),
    .corersts(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk),
    .uncore_rstn(pardcore_uncorerstn)
  );

endmodule
