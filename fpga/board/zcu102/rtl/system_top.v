`include "axi.vh"

module system_top (
);

  `axi_wire(AXI_MEM_MAPPED, 64, 4);
  `axi_wire(AXI_MEM, 64, 4);
  `axilite_wire(AXILITE_MMIO);

  wire jtag_TCK;
  wire jtag_TMS;
  wire jtag_TDI;
  wire jtag_TDO;
  wire jtag_TRST;

  wire pardcore_coreclk;
  wire [1:0] pardcore_corerstn;
  wire pardcore_uncoreclk;
  wire pardcore_uncorerstn;

  zynq_soc zynq_soc_i (
    `axi_connect_if(S_AXI_MEM, AXI_MEM_MAPPED),
    `axilite_connect_if(S_AXILITE_MMIO, AXILITE_MMIO),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),

    .pardcore_coreclk(pardcore_coreclk),
    .pardcore_corerstn(pardcore_corerstn),
    .pardcore_uncoreclk(pardcore_uncoreclk),
    .pardcore_uncorerstn(pardcore_uncorerstn)
  );

  addr_mapper addr_mapper_i(
    `axi_connect_if(s_axi, AXI_MEM),
    `axi_connect_if(m_axi, AXI_MEM_MAPPED)
  );

  pardcore pardcore_i(
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
    `axilite_connect_if(M_AXILITE_MMIO, AXILITE_MMIO),
//    `axi_connect_if(S_AXI_CDMA, AXI_CDMA),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),
    .jtag_TRST(~pardcore_uncorerstn),

    .coreclk(pardcore_coreclk),
    .corersts(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk),
    .uncore_rstn(pardcore_uncorerstn)
  );

endmodule
