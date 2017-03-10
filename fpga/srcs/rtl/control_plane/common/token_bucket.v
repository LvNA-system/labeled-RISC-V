/**
 *  Token bucket:
 *    Limit one ds' bandwidth using tokens.
 *    Read request is served priorly to write request.
 */
module token_bucket(
  // Global signals
  input aclk,
  input aresetn,

  (* mark_debug = "true" *) input is_reading,
  (* mark_debug = "true" *) input is_writing,
  (* mark_debug = "true" *) input can_read,
  (* mark_debug = "true" *) input can_write,

  input [31:0] nr_rbyte,
  input [31:0] nr_wbyte,

  // Token bucket info
  input [31:0] bucket_size,  // Max size of this bucket
  input [31:0] bucket_freq,  // One can gain tokens every `freq' cycles
  input [31:0] bucket_inc,   // Number of tokens each time one can gain

  (* mark_debug = "true" *) output rpass,  // Reed can pass
  (* mark_debug = "true" *) output wpass   // Write can pass
);

  wire bypass = (bucket_freq == 32'b0);

  reg [31:0] nr_token;
  wire is_token_change;
  wire [31:0] nr_token_change;
  wire [31:0] nr_token_next = nr_token + nr_token_change;
  wire [31:0] nr_token_next_real = (nr_token_next > bucket_size ? bucket_size : nr_token_next);

  always @(posedge aclk or negedge aresetn) begin
    if (~aresetn) begin
      nr_token <= 32'd0;
    end
    else if (is_token_change) begin
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

  wire [31:0] rtoken_sub = is_reading ? nr_rbyte : 32'd0;
  wire [31:0] wtoken_sub = is_writing ? nr_wbyte  : 32'd0;
  wire [31:0] token_sub  = rtoken_sub + wtoken_sub;

  // Read is prior to write
  // If this ds is not reading or writing, the traffic it consumes is zero.
  // Therefore rpass and wpass is high and won't block this ds.
  assign rpass = (rtoken_sub <= nr_token) || bypass;
  assign wpass = (wtoken_sub + rtoken_sub <= nr_token) || bypass;

  assign nr_token_change = (is_token_add ? bucket_inc : 32'd0)
                           - ((rpass && can_read) ? rtoken_sub : 32'd0)
                           - ((wpass && can_write) ? wtoken_sub : 32'd0);
  assign is_token_change = (nr_token_change != 32'd0) && !bypass;

endmodule
