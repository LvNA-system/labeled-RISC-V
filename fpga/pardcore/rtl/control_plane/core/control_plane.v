`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ICT, CAS
// Engineer: Jiuyue Ma
// 
// Create Date: 04/13/2015 02:24:55 PM
// Design Name: Generic control plane
// Module Name: ControlPlane
// Project Name: pard_fpga_vc709
// Target Devices: VC709
// Tool Versions: 2014.4
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "../../include/dmi.vh"

module core_control_plane (
  input RST,
  input SYS_CLK,

  /* I2C Interface */
  input [6:0] ADDR,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_I" *)
  input SCL_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_O" *)
  output SCL_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_T" *)
  output SCL_t,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_I" *)
  input SDA_i,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_O" *)
  output SDA_o,
  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_T" *)
  output SDA_t,

  /*core control interface*/
  output EXT_RESET_IN_CORE0,
  output EXT_RESET_IN_CORE1,
  output EXT_RESET_IN_CORE2,
  output [15:0] DS_ID_CORE0,
  output [15:0] DS_ID_CORE1,
  output [15:0] DS_ID_CORE2,

  `dmi_master(DMI, debug),

  input trigger_axis_tready,
  output trigger_axis_tvalid,
  output [15:0] trigger_axis_tdata
);

  CoreControlPlane core (
    .clock(SYS_CLK),
    .reset(RST),
    .io_addr(ADDR),
    .io_i2c_i_scl(SCL_i),
    .io_i2c_i_sda(SDA_i),
    .io_i2c_t_scl(SCL_t),
    .io_i2c_t_sda(SDA_t),
    .io_i2c_o_scl(SCL_o),
    .io_i2c_o_sda(SDA_o),
    .`dmi_connect(io_debug, debug),
    // .io_trigger_axis_ready(trigger_axis_tready),
    .io_trigger_axis_valid(trigger_axis_tvalid),
    .io_trigger_axis_bits(trigger_axis_tdata),
    .io_extReset_0(EXT_RESET_IN_CORE0),
    .io_extReset_1(EXT_RESET_IN_CORE1),
    .io_extReset_2(EXT_RESET_IN_CORE2),
    .io_dsid_0(DS_ID_CORE0),
    .io_dsid_1(DS_ID_CORE1),
    .io_dsid_2(DS_ID_CORE2)
  );
endmodule
