`timescale 1ns / 1ps
module cache_control_plane (
    input  wire RST,
    input  wire SYS_CLK,
    /* I2C Interface */
    input  wire[6:0] ADDR,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_I" *) input  wire SCL_i,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_O" *) output wire SCL_o,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SCL_T" *) output wire SCL_t,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_I" *) input  wire SDA_i,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_O" *) output wire SDA_o,
	  (* X_INTERFACE_INFO = "xilinx.com:interface:iic:1.0 I2C SDA_T" *) output wire SDA_t,
    
    //Cache Statistic
    input wire                                              lookup_valid_to_stab,
    input wire [15 : 0]                                     lookup_DSid_to_stab,
    input wire                                              lookup_hit_to_stab,
    input wire                                              lookup_miss_to_stab,
    input wire                                              update_tag_en_to_stab,
    input wire [15 : 0]                                     update_tag_we_to_stab,
    input wire [255 : 0]                                    update_tag_old_DSid_vec_to_stab,
    input wire [255 : 0]                                    update_tag_new_DSid_vec_to_stab,
    input wire                                              lru_history_en_to_ptab,
    input wire                                              lru_dsid_valid_to_ptab,
    input wire [15 : 0]                                     lru_dsid_to_ptab,
    output     [15 : 0]                                     way_mask_to_cache,

    /* PRM trigger logic */
    input trigger_axis_tready,
    output trigger_axis_tvalid,
    output [15:0] trigger_axis_tdata
);

  wire [15:0] update_tag_old_dsids_0;
  wire [15:0] update_tag_old_dsids_1;
  wire [15:0] update_tag_old_dsids_2;
  wire [15:0] update_tag_old_dsids_3;
  wire [15:0] update_tag_old_dsids_4;
  wire [15:0] update_tag_old_dsids_5;
  wire [15:0] update_tag_old_dsids_6;
  wire [15:0] update_tag_old_dsids_7;
  wire [15:0] update_tag_old_dsids_8;
  wire [15:0] update_tag_old_dsids_9;
  wire [15:0] update_tag_old_dsids_10;
  wire [15:0] update_tag_old_dsids_11;
  wire [15:0] update_tag_old_dsids_12;
  wire [15:0] update_tag_old_dsids_13;
  wire [15:0] update_tag_old_dsids_14;
  wire [15:0] update_tag_old_dsids_15;
  wire [15:0] update_tag_new_dsids_0;
  wire [15:0] update_tag_new_dsids_1;
  wire [15:0] update_tag_new_dsids_2;
  wire [15:0] update_tag_new_dsids_3;
  wire [15:0] update_tag_new_dsids_4;
  wire [15:0] update_tag_new_dsids_5;
  wire [15:0] update_tag_new_dsids_6;
  wire [15:0] update_tag_new_dsids_7;
  wire [15:0] update_tag_new_dsids_8;
  wire [15:0] update_tag_new_dsids_9;
  wire [15:0] update_tag_new_dsids_10;
  wire [15:0] update_tag_new_dsids_11;
  wire [15:0] update_tag_new_dsids_12;
  wire [15:0] update_tag_new_dsids_13;
  wire [15:0] update_tag_new_dsids_14;
  wire [15:0] update_tag_new_dsids_15;

  assign {
    update_tag_old_dsids_15,
    update_tag_old_dsids_14,
    update_tag_old_dsids_13,
    update_tag_old_dsids_12,
    update_tag_old_dsids_11,
    update_tag_old_dsids_10,
    update_tag_old_dsids_9,
    update_tag_old_dsids_8,
    update_tag_old_dsids_7,
    update_tag_old_dsids_6,
    update_tag_old_dsids_5,
    update_tag_old_dsids_4,
    update_tag_old_dsids_3,
    update_tag_old_dsids_2,
    update_tag_old_dsids_1,
    update_tag_old_dsids_0
  } = update_tag_old_DSid_vec_to_stab;

  assign {
    update_tag_new_dsids_15,
    update_tag_new_dsids_14,
    update_tag_new_dsids_13,
    update_tag_new_dsids_12,
    update_tag_new_dsids_11,
    update_tag_new_dsids_10,
    update_tag_new_dsids_9,
    update_tag_new_dsids_8,
    update_tag_new_dsids_7,
    update_tag_new_dsids_6,
    update_tag_new_dsids_5,
    update_tag_new_dsids_4,
    update_tag_new_dsids_3,
    update_tag_new_dsids_2,
    update_tag_new_dsids_1,
    update_tag_new_dsids_0
  } = update_tag_new_DSid_vec_to_stab;

  CacheControlPlane cachecp (
    .clock(SYS_CLK),
    .reset(RST),
    .io_addr(ADDR),
    .io_i2c_i_scl(SCL_i),
    .io_i2c_i_sda(SDA_i),
    .io_i2c_t_scl(SCL_t),
    .io_i2c_t_sda(SDA_t),
    .io_i2c_o_scl(SCL_o),
    .io_i2c_o_sda(SDA_o),
    .io_trigger_axis_ready(trigger_axis_tready),
    .io_trigger_axis_valid(trigger_axis_tvalid),
    .io_trigger_axis_bits(trigger_axis_tdata),
    .io_lookup_valid(lookup_valid_to_stab),
    .io_lookup_dsid(lookup_DSid_to_stab),
    .io_lookup_hit(lookup_hit_to_stab),
    .io_lookup_miss(lookup_miss_to_stab),
    .io_update_tag_enable(update_tag_en_to_stab),
    .io_update_tag_write_enable(update_tag_we_to_stab),
    .io_update_tag_old_dsids_0(update_tag_old_dsids_0),
    .io_update_tag_old_dsids_1(update_tag_old_dsids_1),
    .io_update_tag_old_dsids_2(update_tag_old_dsids_2),
    .io_update_tag_old_dsids_3(update_tag_old_dsids_3),
    .io_update_tag_old_dsids_4(update_tag_old_dsids_4),
    .io_update_tag_old_dsids_5(update_tag_old_dsids_5),
    .io_update_tag_old_dsids_6(update_tag_old_dsids_6),
    .io_update_tag_old_dsids_7(update_tag_old_dsids_7),
    .io_update_tag_old_dsids_8(update_tag_old_dsids_8),
    .io_update_tag_old_dsids_9(update_tag_old_dsids_9),
    .io_update_tag_old_dsids_10(update_tag_old_dsids_10),
    .io_update_tag_old_dsids_11(update_tag_old_dsids_11),
    .io_update_tag_old_dsids_12(update_tag_old_dsids_12),
    .io_update_tag_old_dsids_13(update_tag_old_dsids_13),
    .io_update_tag_old_dsids_14(update_tag_old_dsids_14),
    .io_update_tag_old_dsids_15(update_tag_old_dsids_15),
    .io_update_tag_new_dsids_0(update_tag_new_dsids_0),
    .io_update_tag_new_dsids_1(update_tag_new_dsids_1),
    .io_update_tag_new_dsids_2(update_tag_new_dsids_2),
    .io_update_tag_new_dsids_3(update_tag_new_dsids_3),
    .io_update_tag_new_dsids_4(update_tag_new_dsids_4),
    .io_update_tag_new_dsids_5(update_tag_new_dsids_5),
    .io_update_tag_new_dsids_6(update_tag_new_dsids_6),
    .io_update_tag_new_dsids_7(update_tag_new_dsids_7),
    .io_update_tag_new_dsids_8(update_tag_new_dsids_8),
    .io_update_tag_new_dsids_9(update_tag_new_dsids_9),
    .io_update_tag_new_dsids_10(update_tag_new_dsids_10),
    .io_update_tag_new_dsids_11(update_tag_new_dsids_11),
    .io_update_tag_new_dsids_12(update_tag_new_dsids_12),
    .io_update_tag_new_dsids_13(update_tag_new_dsids_13),
    .io_update_tag_new_dsids_14(update_tag_new_dsids_14),
    .io_update_tag_new_dsids_15(update_tag_new_dsids_15),
    .io_lru_history_enable(lru_history_en_to_ptab),
    .io_lru_dsid_valid(lru_dsid_valid_to_ptab),
    .io_lru_dsid(lru_dsid_to_ptab),
    .io_waymask(way_mask_to_cache)
  );
endmodule
