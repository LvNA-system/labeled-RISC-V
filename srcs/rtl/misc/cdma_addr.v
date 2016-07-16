module cdma_addr(
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
  output   s_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
  input  s_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
  input [31:0] s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWLEN" *)
  input [7:0] s_axi_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWSIZE" *)
  input [2:0] s_axi_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWBURST" *)
  input [1:0] s_axi_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWLOCK" *)
  input  s_axi_awlock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWCACHE" *)
  input [3:0] s_axi_awcache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
  input [2:0] s_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWQOS" *)
  input [3:0] s_axi_awqos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREGION" *)
  input [3:0] s_axi_awregion,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWID" *)
  input [4:0] s_axi_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWUSER" *)
  input  s_axi_awuser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
  output   s_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
  input  s_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
  input [31:0] s_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WLAST" *)
  input  s_axi_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WID" *)
  input [4:0] s_axi_wid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
  input [7:0] s_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WUSER" *)
  input  s_axi_wuser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
  input  s_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
  output   s_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
  output  [1:0] s_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BID" *)
  output  [4:0] s_axi_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BUSER" *)
  output   s_axi_buser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
  output   s_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
  input  s_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
  input [31:0] s_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARLEN" *)
  input [7:0] s_axi_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARSIZE" *)
  input [2:0] s_axi_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARBURST" *)
  input [1:0] s_axi_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARLOCK" *)
  input  s_axi_arlock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARCACHE" *)
  input [3:0] s_axi_arcache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
  input [2:0] s_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARQOS" *)
  input [3:0] s_axi_arqos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREGION" *)
  input [3:0] s_axi_arregion,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARID" *)
  input [4:0] s_axi_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARUSER" *)
  input  s_axi_aruser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
  input  s_axi_rready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
  output   s_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
  output  [1:0] s_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
  output  [31:0] s_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RLAST" *)
  output   s_axi_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RID" *)
  output  [4:0] s_axi_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RUSER" *)
  output   s_axi_ruser,

  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *)
  input   m_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *)
  output  m_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *)
  output [31:0] m_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLEN" *)
  output [7:0] m_axi_awlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWSIZE" *)
  output [2:0] m_axi_awsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWBURST" *)
  output [1:0] m_axi_awburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWLOCK" *)
  output  m_axi_awlock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWCACHE" *)
  output [3:0] m_axi_awcache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWPROT" *)
  output [2:0] m_axi_awprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWQOS" *)
  output [3:0] m_axi_awqos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREGION" *)
  output [3:0] m_axi_awregion,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWID" *)
  output [4:0] m_axi_awid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWUSER" *)
  output  m_axi_awuser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *)
  input   m_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *)
  output  m_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *)
  output [31:0] m_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WLAST" *)
  output  m_axi_wlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WID" *)
  output [4:0] m_axi_wid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *)
  output [7:0] m_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WUSER" *)
  output  m_axi_wuser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *)
  output  m_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *)
  input   m_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *)
  input  [1:0] m_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BID" *)
  input  [4:0] m_axi_bid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BUSER" *)
  input   m_axi_buser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *)
  input   m_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *)
  output  m_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *)
  output [31:0] m_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLEN" *)
  output [7:0] m_axi_arlen,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARSIZE" *)
  output [2:0] m_axi_arsize,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARBURST" *)
  output [1:0] m_axi_arburst,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARLOCK" *)
  output  m_axi_arlock,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARCACHE" *)
  output [3:0] m_axi_arcache,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARPROT" *)
  output [2:0] m_axi_arprot,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARQOS" *)
  output [3:0] m_axi_arqos,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREGION" *)
  output [3:0] m_axi_arregion,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARID" *)
  output [4:0] m_axi_arid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARUSER" *)
  output  m_axi_aruser,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *)
  output  m_axi_rready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *)
  input   m_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *)
  input  [1:0] m_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *)
  input  [31:0] m_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RLAST" *)
  input   m_axi_rlast,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RID" *)
  input  [4:0] m_axi_rid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RUSER" *)
  input   m_axi_ruser
);


assign m_axi_awvalid = s_axi_awvalid;
assign m_axi_awaddr = {1'b1, s_axi_awaddr[30:0]};
assign m_axi_awlen = s_axi_awlen;
assign m_axi_awsize = s_axi_awsize;
assign m_axi_awburst = s_axi_awburst;
assign m_axi_awlock = s_axi_awlock;
assign m_axi_awcache = s_axi_awcache;
assign m_axi_awprot = s_axi_awprot;
assign m_axi_awqos = s_axi_awqos;
assign m_axi_awregion = s_axi_awregion;
assign m_axi_awid = s_axi_awid;
assign m_axi_awuser = s_axi_awuser;
assign m_axi_wvalid = s_axi_wvalid;
assign m_axi_wdata = s_axi_wdata;
assign m_axi_wlast = s_axi_wlast;
assign m_axi_wid = s_axi_wid;
assign m_axi_wstrb = s_axi_wstrb;
assign m_axi_wuser = s_axi_wuser;
assign m_axi_bready = s_axi_bready;
assign m_axi_arvalid = s_axi_arvalid;
assign m_axi_araddr = {1'b1, s_axi_araddr[30:0]};
assign m_axi_arlen = s_axi_arlen;
assign m_axi_arsize = s_axi_arsize;
assign m_axi_arburst = s_axi_arburst;
assign m_axi_arlock = s_axi_arlock;
assign m_axi_arcache = s_axi_arcache;
assign m_axi_arprot = s_axi_arprot;
assign m_axi_arqos = s_axi_arqos;
assign m_axi_arregion = s_axi_arregion;
assign m_axi_arid = s_axi_arid;
assign m_axi_aruser = s_axi_aruser;
assign m_axi_rready = s_axi_rready;
assign s_axi_awready = m_axi_awready;
assign s_axi_wready = m_axi_wready;
assign s_axi_bvalid = m_axi_bvalid;
assign s_axi_bresp = m_axi_bresp;
assign s_axi_bid = m_axi_bid;
assign s_axi_buser = m_axi_buser;
assign s_axi_arready = m_axi_arready;
assign s_axi_rvalid = m_axi_rvalid;
assign s_axi_rresp = m_axi_rresp;
assign s_axi_rdata = m_axi_rdata;
assign s_axi_rlast = m_axi_rlast;
assign s_axi_rid = m_axi_rid;
assign s_axi_ruser = m_axi_ruser;

endmodule
