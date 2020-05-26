`include "axi.vh"

module system_top (
  input [0:0]CLK_IN_D_clk_n,
  input [0:0]CLK_IN_D_clk_p,
  input [0:0]pcie_mgt_rxn,
  input [0:0]pcie_mgt_rxp,
  output [0:0]pcie_mgt_txn,
  output [0:0]pcie_mgt_txp
//  output [7:0] led
);

  `axi_wire(AXI_MEM_MAPPED, 64, 16);
  `axi_wire(AXI_MEM, 64, 16);
  `axi_wire(AXI_MMIO, 64, 8);
  `axi_wire(AXI_DMA, 64, 16);

  //`axi_wire(AXI_FBUS_FROM_ZYNQ, 64, 16);
  `axi_wire(AXI_FBUS_TO_ROCKET, 64, 16);

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

  wire [4:0] pardcore_intrs;

  zynq_soc zynq_soc_i (
    `axi_connect_if(S_AXI_MEM, AXI_MEM_MAPPED),
    `axi_connect_if(S_AXI_MMIO, AXI_MMIO),
    //`axi_connect_if(M_AXI_HPM0_FPD_0, AXI_FBUS_FROM_ZYNQ),
    `axi_connect_if(M_AXI_DMA, AXI_DMA),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),

    .CLK_IN_D_clk_n(CLK_IN_D_clk_n),
    .CLK_IN_D_clk_p(CLK_IN_D_clk_p),
    .pcie_mgt_rxn(pcie_mgt_rxn),
    .pcie_mgt_rxp(pcie_mgt_rxp),
    .pcie_mgt_txn(pcie_mgt_txn),
    .pcie_mgt_txp(pcie_mgt_txp),

//    .led(led[6:0]),

    .pardcore_intrs(pardcore_intrs),

    .nohype_settings(nohype_settings),
    .pardcore_coreclk(pardcore_coreclk),
    .pardcore_corerstn(pardcore_corerstn),
    .pardcore_uncoreclk(pardcore_uncoreclk)
  );

  addr_mapper addr_mapper_i(
    `axi_connect_if(s_axi, AXI_MEM),
    `axi_connect_if(m_axi, AXI_MEM_MAPPED)
  );

  dma_addr_mapper dma_addr_mapper_i(
    `axi_connect_if(s_axi, AXI_DMA),
    `axi_connect_if(m_axi, AXI_FBUS_TO_ROCKET)
  );

  pardcore pardcore_i(
    `axi_connect_if(M_AXI_MEM, AXI_MEM),
    `axi_connect_if(S_AXI_DMA, AXI_FBUS_TO_ROCKET),
    //`axi_connect_if(S_AXI_SBUS, AXI_FBUS_TO_ROCKET),
    `axi_connect_if(M_AXI_MMIO, AXI_MMIO),

    .jtag_TCK(jtag_TCK),
    .jtag_TMS(jtag_TMS),
    .jtag_TDI(jtag_TDI),
    .jtag_TDO(jtag_TDO),
    .jtag_TRST(~pardcore_corerstn),

    .intrs(pardcore_intrs),

//    .led(led[7]),
    .mem_part_en(nohype_settings[0]),
    .reset_to_hang_en(nohype_settings[1]),
    .distinct_hart_dsid_en(nohype_settings[2]),
    .coreclk(pardcore_coreclk),
    .corersts(~pardcore_corerstn),
    .uncoreclk(pardcore_uncoreclk)
  );

endmodule
