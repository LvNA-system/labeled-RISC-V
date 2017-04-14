/**
 *  Token bucket:
 *    Limit one ds' bandwidth using tokens.
 *    Read request is served priorly to write request.
 */
module token_bucket(
  // Global signals
  input aclk,
  input aresetn,

  input is_reading,
  input is_writing,
  input can_read,
  input can_write,

  input [31:0] nr_rbyte,
  input [31:0] nr_wbyte,

  // Token bucket info
  input [31:0] bucket_size,  // Max size of this bucket
  input [31:0] bucket_freq,  // One can gain tokens every `freq' cycles
  input [31:0] bucket_inc,   // Number of tokens each time one can gain

  output reg enable  // Whether request from this ds is allowed.
);

  reg [31:0] nr_token;
  wire [31:0] nr_token_change;
  wire [31:0] nr_token_next = nr_token + nr_token_change;
  wire [31:0] nr_token_next_real = (nr_token_next > bucket_size ? bucket_size : nr_token_next);

  always @(posedge aclk or negedge aresetn) begin
    if (~aresetn) begin
      nr_token <= bucket_size;
    end
    else begin
      nr_token <= nr_token_next_real;
    end
  end

  reg [31:0] counter;
  always @(posedge aclk or negedge aresetn) begin
    if (~aresetn) begin
      counter <= 32'd0;
    end
    else begin
      counter <= (counter >= bucket_freq ? 32'd1 : counter + 32'd1);
    end
  end

  wire is_token_add = (counter == 32'b1);
  wire [31:0] token_add = is_token_add ? bucket_inc : 32'd0;

  wire bypass = (bucket_freq == 32'b0);

  wire ren = is_reading && can_read;
  wire wen = is_writing && can_write;
  wire [31:0] rtoken_sub = (ren && !bypass) ? nr_rbyte : 32'd0;
  wire [31:0] wtoken_sub = (wen && !bypass) ? nr_wbyte : 32'd0;
  wire [31:0] token_sub  = rtoken_sub + wtoken_sub;
  wire consume_up = token_sub >= nr_token;

  // Read is prior to write
  // If this ds is not reading or writing, the traffic it consumes is zero.
  // Therefore rpass and wpass is high and won't block this ds.
  assign rpass = rtoken_sub <= nr_token;
  assign wpass = !consume_up;  // Neglect case `token_sub == nr_token`, but it can be calc correctly for wtoken_sub_real.

  wire [31:0] rtoken_sub_real = rpass ? rtoken_sub : nr_token;
  wire [31:0] wtoken_sub_real = wpass ? wtoken_sub : nr_token - rtoken_sub_real;  // If rpass is false, it is 0.

  assign nr_token_change = token_add - rtoken_sub_real - wtoken_sub_real;

  //
  // Throttle logic
  //
  reg [31:0] token_threshold;  // The number of tokens that can allow requests from this ds.
  wire [31:0] token_threshold_real = (token_threshold > bucket_size) ? bucket_size : token_threshold;  // Choose feasible one.
  always @(posedge aclk or negedge aresetn) begin
    if (~aresetn) begin
      enable <= 1'b1;
      token_threshold <= 32'd0;
    end
    else if ((ren || wen) && consume_up) begin
      // This cycle read and/or write request consumes all tokens.
      // We need to remeber this event and disable the ds' ability to send requests.
      enable <= 1'b0;
      // Heuristic, considering that L2 traffic is always in the size of cache block.
      // TODO Use total token consumption, or use read or write consumption only?
      token_threshold <= token_sub;
    end
    else if (nr_token >= token_threshold_real && nr_token != 32'd0) begin  // Don't want traffic to go through when bucket size is 0.
      enable <= 1'b1;
      token_threshold <= 32'd0;
    end
  end
endmodule
