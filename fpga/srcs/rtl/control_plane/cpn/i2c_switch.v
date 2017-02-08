`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Frontier System Group, ICT, CAS
// Engineer: Jiuyue Ma
// 
// Create Date: 2015/03/31 16:38:18
// Design Name: I2C Switch
// Module Name: i2c_switch
// Project Name: pard_fpga_vc709
// Target Devices: x7vc690tffg1761-2
// Tool Versions: Vivado 2014.4
// Description: IIC Switch module 
// Dependencies: None 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module i2c_switch(
    aclk, aresetn, addr,
    /* upstream */
    SCL_i, SCL_o, SCL_t, SDA_i, SDA_o, SDA_t,
    /* downstream */
    SC_i, SC_o, SC_t, SD_i, SD_o, SD_t
);
    input  wire        aclk;
    input  wire        aresetn;
    input  wire [2:0]  addr;
    /* upstream */
    output wire        SCL_i;
    input  wire        SCL_o;
    input  wire        SCL_t;
    output wire        SDA_i;
    input  wire        SDA_o;
    input  wire        SDA_t;
    /* dwonstream */
    output wire [7:0]  SC_i;
    input  wire [7:0]  SC_o;
    input  wire [7:0]  SC_t;
    output wire [7:0]  SD_i;
    input  wire [7:0]  SD_o;
    input  wire [7:0]  SD_t;
    
    /* Wire connect to Master Side */
    wire wire_scl_i;
    wire wire_scl_o;
    wire wire_scl_t;
    wire wire_sda_i;
    wire wire_sda_o;
    wire wire_sda_t;
    i2c_wire wire_i
    (
        .SCL0_i(SCL_i),
        .SCL0_o(SCL_o),
        .SCL0_t(SCL_t),
        .SDA0_i(SDA_i),
        .SDA0_o(SDA_o),
        .SDA0_t(SDA_t),
        /******************/
        .SCL1_i(wire_scl_i),
        .SCL1_o(wire_scl_o),
        .SCL1_t(wire_scl_t),
        .SDA1_i(wire_sda_i),
        .SDA1_o(wire_sda_o),
        .SDA1_t(wire_sda_t)
    );
    
    /**
     * Input Filter & I2C Bus Control
     */
    wire [7:0]    control_reg;
    wire slave_valid;
    wire slave_scl_o;
    wire slave_scl_t;
    wire slave_sda_o;
    wire slave_sda_t;
    i2c_slave i2c_bus_control
    (
        .ACLK(aclk),
        .RST(~aresetn),
        .ADDR(addr[2:0]),
        .CONTROL(control_reg[7:0]),
        .VALID(slave_valid),
        .SCL_ext_i(wire_scl_i),
        .SCL_o(slave_scl_o),
        .SCL_t(slave_scl_t),
        .SDA_ext_i(wire_sda_i),
        .SDA_o(slave_sda_o),
        .SDA_t(slave_sda_t)
    );
    
    /**
     * Generate switch network
     */
    generate
    genvar i;
        for(i = 0; i < 8; i = i + 1)
        begin
            assign SC_i[i] = control_reg[i] ? wire_scl_i : 1'd1;
            assign SD_i[i] = control_reg[i] ? wire_sda_i : 1'd1;
        end
    endgenerate
    
    wire SCx_o;
    wire SCx_t;
    wire SDx_o;
    wire SDx_t;
    Mux8 #(.DEFAULT_OUT(1'b0)) SCx_o_mux(
        .Vector_in(SC_o),
        .Sel_in(control_reg),
        .Out(SCx_o)
    );
    Mux8 #(.DEFAULT_OUT(1'b1)) SCx_t_mux(
        .Vector_in(SC_t),
        .Sel_in(control_reg),
        .Out(SCx_t)
    );
    Mux8 #(.DEFAULT_OUT(1'b0)) SDx_o_mux(
        .Vector_in(SD_o),
        .Sel_in(control_reg),
        .Out(SDx_o)
    );
    Mux8 #(.DEFAULT_OUT(1'b1)) SDx_t_mux(
        .Vector_in(SD_t),
        .Sel_in(control_reg),
        .Out(SDx_t)
    );

    assign wire_scl_o = slave_valid ? slave_scl_o : SCx_o;
    assign wire_scl_t = slave_valid ? slave_scl_t : SCx_t;
    assign wire_sda_o = slave_valid ? slave_sda_o : SDx_o;
    assign wire_sda_t = slave_valid ? slave_sda_t : SDx_t;

endmodule
