`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2016 10:26:00 AM
// Design Name: 
// Module Name: leds_mux_controller
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


module leds_mux_controller #(
    parameter C_LED_DELAY = 3,	        /* delay seconds, 3s default */
    parameter C_CLK_FREQ = 100000000	/* clock freq, 100MHz default */
)(
    input  wire       clk,
    input  wire       aresetn,
    output wire [7:0] leds,
    input  wire [2:0] buttons,
    input  wire [7:0] group_default,
    input  wire [7:0] group_0,
    input  wire [7:0] group_1,
    input  wire [7:0] group_2
    );
    localparam P_LED_DELAY_CYCLES = C_LED_DELAY * C_CLK_FREQ;

    wire button_push;
    reg [1:0] selected;
    reg [31:0] delay_counter;

    assign button_push = |buttons;

    assign leds = selected[1] ? (selected[0] ? group_default : group_2)
                              : (selected[0] ? group_1       : group_0);

    always @ (posedge clk or negedge aresetn)
    begin
        if (~aresetn) begin
            selected <= 2'b11;
            delay_counter <= 32'd0;
        end else begin
            if (button_push) begin
                     if (buttons[0]) selected <= 2'b00;
                else if (buttons[1]) selected <= 2'b01;
                else if (buttons[2]) selected <= 2'b10;
                delay_counter <= P_LED_DELAY_CYCLES;
            end else begin
                if (|delay_counter)
                    delay_counter <= delay_counter - 1;
                else
                    selected <= 2'b11;
            end
        end
    end

endmodule
