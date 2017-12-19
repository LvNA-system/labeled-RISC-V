`include "../include/axi.vh"

module axi_reg #(
	parameter REG_WIDTH = 64,
	parameter INIT_VAL = 0
) (
	(* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
	(* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn, PROTOCOL AXI4LITE" *)
	input s_axi_aclk,
	input s_axi_aresetn,
	output reg [REG_WIDTH - 1:0] val,
   `axilite_slave_if(s_axi)
);

	wire [63:0] wdata = s_axi_wdata & {
		{8{s_axi_wstrb[7]}},
		{8{s_axi_wstrb[6]}},
		{8{s_axi_wstrb[5]}},
		{8{s_axi_wstrb[4]}},
		{8{s_axi_wstrb[3]}},
		{8{s_axi_wstrb[2]}},
		{8{s_axi_wstrb[1]}},
		{8{s_axi_wstrb[0]}}
	};

	wire arok = s_axi_arvalid & s_axi_arready;
	wire awok = s_axi_awvalid & s_axi_awready;
	wire wok = s_axi_wvalid & s_axi_wready;

	reg reg_awok;
	reg reg_wok;
	reg [63:0] reg_wdata;

	reg reg_b_valid;
	reg reg_r_valid;

	always@(posedge s_axi_aclk or negedge s_axi_aresetn) begin
		if(~s_axi_aresetn) begin
			val <= INIT_VAL;
			reg_awok <= 1'b0;
			reg_wok <= 1'b0;
			reg_b_valid <= 1'b0;
			reg_r_valid <= 1'b0;
		end
		else begin
			if(reg_awok == 1'b0) begin
				reg_awok = awok;
			end
			if(reg_wok == 1'b0) begin
				reg_wok = wok;
			end
			if(wok) begin
				reg_wdata = wdata;
			end

			if((reg_awok & reg_wok)) begin
				val <= reg_wdata;
				reg_b_valid <= 1'b1;
				reg_wok = 1'b0;
				reg_awok = 1'b0;
			end

			if(reg_b_valid & s_axi_bready) begin
				reg_b_valid <= 1'b0;
			end

			if(arok) begin
				reg_r_valid <= 1'b1;
			end

			if(reg_r_valid & s_axi_rready) begin
				reg_r_valid <= 1'b0;
			end

		end
	end

	assign s_axi_awready = ~reg_awok;
	assign s_axi_wready = ~reg_wok;
	assign s_axi_bvalid = reg_b_valid;
	assign s_axi_bresp = 2'b00;
	assign s_axi_arready = 1'b1;
	assign s_axi_rvalid = reg_r_valid;
	assign s_axi_rresp = 2'b00;
	assign s_axi_rdata = val;

endmodule
