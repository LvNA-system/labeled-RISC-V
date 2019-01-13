`include "axi.vh"

module system_top (
  output [7:0] led
);

  `axi_wire(AXI_MEM_MAPPED, 64, 1);
  `axi_wire(AXI_MEM, 64, 1);
  `axilite_wire(AXILITE_MMIO);
  `axi_wire(AXI_DMA, 64, 1);

  `axi_wire(AXI_SBUS_FROM_ZYNQ, 64, 16);
  wire [15:0] AXI_SBUS_FROM_ZYNQ_awuser;
  wire [15:0] AXI_SBUS_FROM_ZYNQ_aruser;
  `axi_wire(AXI_SBUS_TO_ROCKET, 64, 16);
  wire [15:0] AXI_SBUS_TO_ROCKET_awuser;
  wire [15:0] AXI_SBUS_TO_ROCKET_aruser;

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
    `axi_connect_if(S_AXI_MEM, AXI_MEM_MAPPED),
    `axi_connect_if(M_AXI_SBUS, AXI_SBUS_FROM_ZYNQ),
    .M_AXI_SBUS_awuser(AXI_SBUS_FROM_ZYNQ_awuser),
    .M_AXI_SBUS_aruser(AXI_SBUS_FROM_ZYNQ_aruser),
    `axilite_connect_if(S_AXILITE_MMIO, AXILITE_MMIO),
    `axi_connect_if_no_id(M_AXI_DMA, AXI_DMA),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),

    .led(led[6:0]),

    .mm2s_introut(mm2s_introut),
    .s2mm_introut(s2mm_introut),

    .nohype_settings(nohype_settings),
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
    .s_axi_awuser(AXI_SBUS_FROM_ZYNQ_awuser),
    .s_axi_aruser(AXI_SBUS_FROM_ZYNQ_aruser),
    `axi_connect_if(s_axi, AXI_SBUS_FROM_ZYNQ),
    .m_axi_awuser(AXI_SBUS_TO_ROCKET_awuser),
    .m_axi_aruser(AXI_SBUS_TO_ROCKET_aruser),
    `axi_connect_if(m_axi, AXI_SBUS_TO_ROCKET)
  );

  pardcore pardcore_i(
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
    `axi_connect_if(S_AXI_DMA, AXI_DMA),
    .S_AXI_SBUS_awuser(AXI_SBUS_TO_ROCKET_awuser),
    .S_AXI_SBUS_aruser(AXI_SBUS_TO_ROCKET_aruser),
    `axi_connect_if(S_AXI_SBUS, AXI_SBUS_TO_ROCKET),
    `axilite_connect_if(M_AXILITE_MMIO, AXILITE_MMIO),

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
