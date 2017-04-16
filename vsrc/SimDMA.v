// See LICENSE.SiFive for license details.

module SimDMA(
  input clk,
  input reset,

  output intr,
  input axi_awready,
  output axi_awvalid,
  output [31:0] axi_awaddr,
  output [15:0] axi_awuser,

  input axi_wready,
  output axi_wvalid,
  output [63:0] axi_wdata

);

  bit r_reset;
  parameter STATE_IDLE = 3'd0, STATE_CDMA = 3'd1, STATE_INTR_WAIT = 3'd2, STATE_INTR = 3'd3, STATE_END = 3'd4;
  reg [2:0] state;
  wire state_idle = state == STATE_IDLE;
  wire state_cdma = state == STATE_CDMA;
  wire state_intr_wait = state == STATE_INTR_WAIT;
  wire state_intr = state == STATE_INTR;
  wire state_intr_end = state == STATE_END;

  parameter max_tran = 2097152; //16384;
  parameter max_tran_width = $clog2(max_tran);
  reg [31:0] counter;
  reg [63:0] bin [max_tran-1:0];
  integer file;
  reg [31:0] bin_size [0:0];
  integer nr_tran;
  integer nr_tran_width;

  initial begin
	  $readmemh("bin.size", bin_size);
	  $display("bin.size = %d", bin_size[0]);
	  nr_tran = (bin_size[0] + 7) / 8;
	  nr_tran_width = $clog2(nr_tran);
	  $display("nr_tran_width = %d", nr_tran_width);
	  if(bin_size[0] >= max_tran * 8)
		  $fatal("bin size too large!");

	  $readmemh("bin.txt", bin);
  end

  wire  #0.1 __axi_awready = axi_awready;
  wire  #0.1 __axi_wready = axi_wready;

  reg aw_ok;
  reg w_ok;

  wire [31:0] __axi_awaddr = 32'h80000000 | counter;
  wire [63:0]  __axi_wdata = bin[counter[3+max_tran_width - 1:3]];
  assign #0.1 axi_awuser = 16'd1;
  assign #0.1 axi_awaddr = __axi_awaddr;
  assign #0.1 axi_wdata = __axi_wdata;

  assign #0.1 axi_awvalid = ~aw_ok & state_cdma;
  assign #0.1 axi_wvalid = ~w_ok & state_cdma;


  assign #0.1 intr = state_intr;

  always @(posedge clk) begin
    if (reset || r_reset) begin
      counter <= 32'b0;
	  w_ok <= 1'b0;
	  aw_ok <= 1'b0;
	  state <= STATE_IDLE;
    end
	case (state)
		STATE_IDLE: begin
			state <= STATE_CDMA;
		end
		STATE_CDMA: begin
			if(w_ok & aw_ok) begin
				counter <= counter + 32'd8;
				w_ok <= 1'b0;
				aw_ok <= 1'b0;
				if(counter[9:0] == 10'b0) begin
					$write("\r%t: DMA finishes %dKB", $time, counter[31:10]);
				end
			end
			else if(counter < bin_size[0]) begin
				if(~w_ok & __axi_wready) begin
					w_ok <= 1'b1;
				end
				if(~aw_ok & __axi_awready) begin
					aw_ok <= 1'b1;
				end
			end
			else if(counter >= bin_size[0]) begin
				state <= STATE_INTR_WAIT;
				counter <= 32'b0;
				$display("\nDMA transfer OK");
			end
		end

		STATE_INTR_WAIT: begin
			if(counter < 10000) begin
				counter <= counter + 1'b1;
			end
			else begin
				state <= STATE_INTR;
				counter <= 32'b0;
			end
		end

		STATE_INTR: begin
			if(counter < 10) begin
				counter <= counter + 1'b1;
			end
			else begin
				state <= STATE_END;
				counter <= 32'b0;
			end
		end

		default:;

	endcase
  end

  always @(posedge clk) begin
    r_reset <= reset;
  end
endmodule
