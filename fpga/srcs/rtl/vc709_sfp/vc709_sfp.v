`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/09/19 17:25:14
// Design Name: 
// Module Name: vc709_sfp
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vc709_sfp(
    clk50,
    i2c_clk,
    i2c_data,
    i2c_mux_rst_n,
    sync_reset,
    si5324_rst_n,
    signal_detect,
    LED,
    SFP_LOS,
    SFP_MOD_DETECT, 
    SFP_RS0,
    SFP_TX_DISABLE 
    );
input clk50;
inout i2c_clk;
inout i2c_data;
output i2c_mux_rst_n;
input sync_reset;
output si5324_rst_n;
output [3:0] signal_detect;
output [7:0] LED;
input  [3:0] SFP_LOS;
input  [3:0] SFP_MOD_DETECT;
output [3:0] SFP_RS0;
output [3:0] SFP_TX_DISABLE;

wire clk50;
wire i2c_clk;
wire i2c_data;
wire i2c_mux_rst_n;
wire reset;
wire si5324_rst_n;
wire [3:0] signal_detect;
wire [7:0] LED;
wire [3:0] SFP_LOS;
wire [3:0] SFP_MOD_DETECT;
wire [3:0] SFP_RS0;
wire [3:0] SFP_TX_DISABLE;
    
    // disable optics if module is NOT present
    assign  SFP_TX_DISABLE[0] = SFP_MOD_DETECT[0] ? 1'b1 : 1'b0 ; 
    assign  SFP_TX_DISABLE[1] = SFP_MOD_DETECT[1] ? 1'b1 : 1'b0 ;
    assign  SFP_TX_DISABLE[2] = SFP_MOD_DETECT[2] ? 1'b1 : 1'b0 ;
    assign  SFP_TX_DISABLE[3] = SFP_MOD_DETECT[3] ? 1'b1 : 1'b0 ;
    
    // select high bandwidth mode if module is present
    assign  SFP_RS0[0] = 0 ; 
    assign  SFP_RS0[1] = 0 ;
    assign  SFP_RS0[2] = 0 ;
    assign  SFP_RS0[3] = 0 ;
    /*
    assign  SFP_RS0[0] = SFP_MOD_DETECT[0] ? 1'b0 : 1'b1 ; 
    assign  SFP_RS0[1] = SFP_MOD_DETECT[1] ? 1'b0 : 1'b1 ;
    assign  SFP_RS0[2] = SFP_MOD_DETECT[2] ? 1'b0 : 1'b1 ;
    assign  SFP_RS0[3] = SFP_MOD_DETECT[3] ? 1'b0 : 1'b1 ;
    */
    
    // assign GPIO LEDS for SFP+ module user visual status 
    assign LED[0] = SFP_MOD_DETECT[0] ; // DS2 (right side of LED array)
    assign LED[1] = SFP_MOD_DETECT[1] ; // DS3
    assign LED[2] = SFP_MOD_DETECT[2] ; // DS4
    assign LED[3] = SFP_MOD_DETECT[3] ; // DS5
    
    assign LED[4] = SFP_LOS[0] ; // DS6
    assign LED[5] = SFP_LOS[1] ; // DS7
    assign LED[6] = SFP_LOS[2] ; // DS8
    assign LED[7] = SFP_LOS[3] ; // DS9 (left side of LED array) 
    
    // assign signal detect
    assign signal_detect[0] = SFP_LOS[0] ? 1'b0 : 1'b1;
    assign signal_detect[1] = SFP_LOS[1] ? 1'b0 : 1'b1;
    assign signal_detect[2] = SFP_LOS[2] ? 1'b0 : 1'b1;
    assign signal_detect[3] = SFP_LOS[3] ? 1'b0 : 1'b1;
    
    clock_control cc_inst(
        .clk50(clk50),
        .rst(sync_reset),
        .i2c_clk(i2c_clk),
        .i2c_data(i2c_data),
        .i2c_mux_rst_n(i2c_mux_rst_n),
        .si5324_rst_n(si5324_rst_n));
        
endmodule
