`timescale 1ns / 1ps

`include "../../include/axi.vh"

module mig_control_plane(
    input  wire       aclk,
    input  wire       aresetn,
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
    /* APM Interface */
    input wire         APM_VALID,
    input wire  [31:0] APM_ADDR ,
    input wire  [31:0] APM_DATA,

    /* Enables for cores' L1 traffic */
    output [2:0] L1enable,
    input trigger_axis_tready,
    output trigger_axis_tvalid,
    output [15:0] trigger_axis_tdata,

    `axi_in_interface(S_AXI, s_axi, 5),
    `axi_out_interface(M_AXI, m_axi, 5)
  );

  MigControlPlane mig (
    .clock(aclk),
    .reset(~aresetn),
    .io_addr(ADDR),
    .io_l1enable_0(L1enable[0]),
    .io_l1enable_1(L1enable[1]),
    .io_l1enable_2(L1enable[2]),
    .io_i2c_i_scl(SCL_i),
    .io_i2c_i_sda(SDA_i),
    .io_i2c_t_scl(SCL_t),
    .io_i2c_t_sda(SDA_t),
    .io_i2c_o_scl(SCL_o),
    .io_i2c_o_sda(SDA_o),
    .io_apm_valid(APM_VALID),
    .io_apm_addr(APM_ADDR),
    .io_apm_data(APM_DATA),
    .io_trigger_axis_ready(trigger_axis_tready),
    .io_trigger_axis_valid(trigger_axis_tvalid),
    .io_trigger_axis_bits(trigger_axis_tdata),
    `axi_connect_interface(io_s_axi, s_axi),
    `axi_connect_interface(io_m_axi, m_axi)
  );
endmodule
