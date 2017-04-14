-------------------------------------------------------------------------------
-- sc_front_end.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and 
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Filename:        sc_front_end.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_front_end.vhd
--
-------------------------------------------------------------------------------
-- Author:          rikardw
--
-- History:
--   rikardw  2011-05-30    First Version
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

-- pragma xilinx_rtl_off
library unisim;
use unisim.vcomponents.all;
-- pragma xilinx_rtl_on

library work;
use work.system_cache_pkg.all;


entity sc_front_end is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    C_USE_ASSERTIONS          : boolean                       := false;
    C_USE_STATISTICS          : boolean                       := false;
    C_STAT_OPT_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_OPT_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
    C_STAT_GEN_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_GEN_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
    C_STAT_BITS               : natural range  1 to   64      := 32;
    C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
    C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
    C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
    C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;

    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- Optimized AXI4 Slave Interface #0 specific.
    C_S0_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S0_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S0_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S0_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S0_AXI_ID_WIDTH         : natural                       := 4;
    C_S0_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S0_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S0_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S0_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S0_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S0_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S0_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S0_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S0_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S0_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S0_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #1 specific.
    C_S1_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S1_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S1_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S1_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S1_AXI_ID_WIDTH         : natural                       := 4;
    C_S1_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S1_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S1_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S1_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S1_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S1_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S1_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S1_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S1_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S1_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S1_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #2 specific.
    C_S2_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S2_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S2_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S2_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S2_AXI_ID_WIDTH         : natural                       := 4;
    C_S2_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S2_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S2_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S2_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S2_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S2_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S2_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S2_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S2_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S2_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S2_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #3 specific.
    C_S3_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S3_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S3_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S3_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S3_AXI_ID_WIDTH         : natural                       := 4;
    C_S3_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S3_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S3_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S3_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S3_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S3_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S3_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S3_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S3_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S3_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S3_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #4 specific.
    C_S4_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S4_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S4_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S4_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S4_AXI_ID_WIDTH         : natural                       := 4;
    C_S4_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S4_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S4_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S4_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S4_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S4_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S4_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S4_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S4_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S4_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S4_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #5 specific.
    C_S5_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S5_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S5_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S5_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S5_AXI_ID_WIDTH         : natural                       := 4;
    C_S5_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S5_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S5_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S5_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S5_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S5_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S5_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S5_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S5_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S5_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S5_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #6 specific.
    C_S6_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S6_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S6_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S6_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S6_AXI_ID_WIDTH         : natural                       := 4;
    C_S6_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S6_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S6_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S6_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S6_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S6_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S6_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S6_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S6_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S6_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S6_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #7 specific.
    C_S7_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S7_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S7_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S7_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S7_AXI_ID_WIDTH         : natural                       := 4;
    C_S7_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S7_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S7_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S7_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S7_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S7_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S7_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S7_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S7_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S7_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S7_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #8 specific.
    C_S8_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S8_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S8_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S8_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S8_AXI_ID_WIDTH         : natural                       := 4;
    C_S8_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S8_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S8_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S8_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S8_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S8_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S8_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S8_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S8_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S8_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S8_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #9 specific.
    C_S9_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S9_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S9_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S9_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S9_AXI_ID_WIDTH         : natural                       := 4;
    C_S9_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S9_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S9_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S9_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S9_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S9_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S9_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S9_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S9_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S9_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S9_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #10 specific.
    C_S10_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S10_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S10_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S10_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S10_AXI_ID_WIDTH         : natural                       := 4;
    C_S10_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S10_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S10_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S10_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S10_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S10_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S10_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S10_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S10_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S10_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S10_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #1 specific.
    C_S11_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S11_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S11_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S11_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S11_AXI_ID_WIDTH         : natural                       := 4;
    C_S11_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S11_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S11_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S11_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S11_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S11_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S11_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S11_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S11_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S11_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S11_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #12 specific.
    C_S12_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S12_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S12_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S12_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S12_AXI_ID_WIDTH         : natural                       := 4;
    C_S12_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S12_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S12_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S12_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S12_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S12_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S12_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S12_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S12_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S12_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S12_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #13 specific.
    C_S13_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S13_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S13_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S13_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S13_AXI_ID_WIDTH         : natural                       := 4;
    C_S13_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S13_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S13_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S13_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S13_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S13_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S13_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S13_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S13_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S13_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S13_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #14 specific.
    C_S14_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S14_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S14_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S14_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S14_AXI_ID_WIDTH         : natural                       := 4;
    C_S14_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S14_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S14_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S14_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S14_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S14_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S14_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S14_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S14_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S14_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S14_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Optimized AXI4 Slave Interface #15 specific.
    C_S15_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S15_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S15_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S15_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S15_AXI_ID_WIDTH         : natural                       := 4;
    C_S15_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
    C_S15_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
    C_S15_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S15_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S15_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S15_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S15_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S15_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S15_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S15_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S15_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #0 specific.
    C_S0_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S0_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S0_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S0_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S0_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S0_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S0_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #1 specific.
    C_S1_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S1_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S1_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S1_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S1_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S1_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S1_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #2 specific.
    C_S2_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S2_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S2_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S2_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S2_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S2_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S2_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #3 specific.
    C_S3_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S3_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S3_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S3_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S3_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S3_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S3_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #4 specific.
    C_S4_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S4_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S4_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S4_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S4_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S4_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S4_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #5 specific.
    C_S5_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S5_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S5_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S5_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S5_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S5_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S5_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #6 specific.
    C_S6_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S6_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S6_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S6_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S6_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S6_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S6_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #7 specific.
    C_S7_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S7_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S7_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S7_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S7_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S7_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S7_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #8 specific.
    C_S8_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S8_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S8_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S8_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S8_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S8_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S8_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #9 specific.
    C_S9_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S9_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S9_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S9_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S9_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S9_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S9_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #10 specific.
    C_S10_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S10_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S10_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S10_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S10_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S10_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S10_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #11 specific.
    C_S11_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S11_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S11_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S11_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S11_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S11_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S11_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #12 specific.
    C_S12_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S12_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S12_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S12_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S12_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S12_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S12_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #13 specific.
    C_S13_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S13_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S13_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S13_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S13_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S13_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S13_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #14 specific.
    C_S14_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S14_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S14_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S14_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S14_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S14_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S14_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Generic AXI4 Slave Interface #15 specific.
    C_S15_AXI_GEN_BASEADDR     : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_S15_AXI_GEN_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_S15_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S15_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S15_AXI_GEN_ID_WIDTH     : natural                       := 4;
    C_S15_AXI_GEN_FORCE_READ_ALLOCATE      : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_PROHIBIT_READ_ALLOCATE   : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_FORCE_WRITE_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_FORCE_READ_BUFFER        : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_PROHIBIT_READ_BUFFER     : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_FORCE_WRITE_BUFFER       : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_PROHIBIT_WRITE_BUFFER    : natural range  0 to    1      :=  0;
    C_S15_AXI_GEN_PROHIBIT_EXCLUSIVE       : natural range  0 to    1      :=  1;
    
    -- Data type and settings specific.
    C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
    C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
    C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
    C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
    C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
    C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
    C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
    C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
    C_Lx_ADDR_REQ_HI          : natural range  2 to   63      := 27;
    C_Lx_ADDR_REQ_LO          : natural range  2 to   63      :=  7;
    C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
    C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
    C_Lx_ADDR_DATA_HI         : natural range  2 to   63      := 14;
    C_Lx_ADDR_DATA_LO         : natural range  2 to   63      :=  2;
    C_Lx_ADDR_TAG_HI          : natural range  4 to   63      := 27;
    C_Lx_ADDR_TAG_LO          : natural range  4 to   63      := 14;
    C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
    C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
    C_Lx_ADDR_OFFSET_HI       : natural range  2 to   63      :=  6;
    C_Lx_ADDR_OFFSET_LO       : natural range  0 to   63      :=  0;
    C_Lx_ADDR_WORD_HI         : natural range  2 to   63      :=  6;
    C_Lx_ADDR_WORD_LO         : natural range  2 to   63      :=  2;
    C_Lx_ADDR_BYTE_HI         : natural range  0 to   63      :=  1;
    C_Lx_ADDR_BYTE_LO         : natural range  0 to   63      :=  0;
    
    -- Lx Cache Specific.
    C_Lx_CACHE_SIZE           : natural                       := 1024;
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
    C_Lx_NUM_ADDR_TAG_BITS    : natural range  1 to   63      :=  8;
    
    -- System Cache Specific.
    C_PIPELINE_LU_READ_DATA   : boolean                       := false;
    C_ID_WIDTH                : natural range  1 to   32      :=  4;
    C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
    C_ENABLE_CTRL             : natural range  0 to    1      :=  0;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
    C_NUM_PORTS               : natural range  1 to   32      :=  1;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
    C_ENABLE_EX_MON           : natural range  0 to    1      :=  0
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #0 Slave Signals.
    
    S0_AXI_AWID               : in  std_logic_vector(C_S0_AXI_ID_WIDTH-1 downto 0);
    S0_AXI_AWADDR             : in  std_logic_vector(C_S0_AXI_ADDR_WIDTH-1 downto 0);
    S0_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S0_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S0_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S0_AXI_AWLOCK             : in  std_logic;
    S0_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S0_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S0_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S0_AXI_AWVALID            : in  std_logic;
    S0_AXI_AWREADY            : out std_logic;
    S0_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S0_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S0_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S0_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S0_AXI_WDATA              : in  std_logic_vector(C_S0_AXI_DATA_WIDTH-1 downto 0);
    S0_AXI_WSTRB              : in  std_logic_vector((C_S0_AXI_DATA_WIDTH/8)-1 downto 0);
    S0_AXI_WLAST              : in  std_logic;
    S0_AXI_WVALID             : in  std_logic;
    S0_AXI_WREADY             : out std_logic;
    
    S0_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S0_AXI_BID                : out std_logic_vector(C_S0_AXI_ID_WIDTH-1 downto 0);
    S0_AXI_BVALID             : out std_logic;
    S0_AXI_BREADY             : in  std_logic;
    S0_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S0_AXI_ARID               : in  std_logic_vector(C_S0_AXI_ID_WIDTH-1 downto 0);
    S0_AXI_ARADDR             : in  std_logic_vector(C_S0_AXI_ADDR_WIDTH-1 downto 0);
    S0_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S0_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S0_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S0_AXI_ARLOCK             : in  std_logic;
    S0_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S0_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S0_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S0_AXI_ARVALID            : in  std_logic;
    S0_AXI_ARREADY            : out std_logic;
    S0_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S0_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S0_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S0_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S0_AXI_RID                : out std_logic_vector(C_S0_AXI_ID_WIDTH-1 downto 0);
    S0_AXI_RDATA              : out std_logic_vector(C_S0_AXI_DATA_WIDTH-1 downto 0);
    S0_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S0_AXI_RLAST              : out std_logic;
    S0_AXI_RVALID             : out std_logic;
    S0_AXI_RREADY             : in  std_logic;
    S0_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S0_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S0_AXI_ACADDR             : out std_logic_vector(C_S0_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S0_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S0_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S0_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S0_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S0_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S0_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S0_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S0_AXI_CDDATA             : in  std_logic_vector(C_S0_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S0_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S0_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #1 Slave Signals.
    
    S1_AXI_AWID               : in  std_logic_vector(C_S1_AXI_ID_WIDTH-1 downto 0);
    S1_AXI_AWADDR             : in  std_logic_vector(C_S1_AXI_ADDR_WIDTH-1 downto 0);
    S1_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S1_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S1_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S1_AXI_AWLOCK             : in  std_logic;
    S1_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S1_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S1_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S1_AXI_AWVALID            : in  std_logic;
    S1_AXI_AWREADY            : out std_logic;
    S1_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S1_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S1_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S1_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S1_AXI_WDATA              : in  std_logic_vector(C_S1_AXI_DATA_WIDTH-1 downto 0);
    S1_AXI_WSTRB              : in  std_logic_vector((C_S1_AXI_DATA_WIDTH/8)-1 downto 0);
    S1_AXI_WLAST              : in  std_logic;
    S1_AXI_WVALID             : in  std_logic;
    S1_AXI_WREADY             : out std_logic;
    
    S1_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S1_AXI_BID                : out std_logic_vector(C_S1_AXI_ID_WIDTH-1 downto 0);
    S1_AXI_BVALID             : out std_logic;
    S1_AXI_BREADY             : in  std_logic;
    S1_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S1_AXI_ARID               : in  std_logic_vector(C_S1_AXI_ID_WIDTH-1 downto 0);
    S1_AXI_ARADDR             : in  std_logic_vector(C_S1_AXI_ADDR_WIDTH-1 downto 0);
    S1_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S1_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S1_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S1_AXI_ARLOCK             : in  std_logic;
    S1_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S1_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S1_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S1_AXI_ARVALID            : in  std_logic;
    S1_AXI_ARREADY            : out std_logic;
    S1_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S1_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S1_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S1_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S1_AXI_RID                : out std_logic_vector(C_S1_AXI_ID_WIDTH-1 downto 0);
    S1_AXI_RDATA              : out std_logic_vector(C_S1_AXI_DATA_WIDTH-1 downto 0);
    S1_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S1_AXI_RLAST              : out std_logic;
    S1_AXI_RVALID             : out std_logic;
    S1_AXI_RREADY             : in  std_logic;
    S1_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S1_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S1_AXI_ACADDR             : out std_logic_vector(C_S1_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S1_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S1_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S1_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S1_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S1_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S1_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S1_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S1_AXI_CDDATA             : in  std_logic_vector(C_S1_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S1_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S1_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #2 Slave Signals.
    
    S2_AXI_AWID               : in  std_logic_vector(C_S2_AXI_ID_WIDTH-1 downto 0);
    S2_AXI_AWADDR             : in  std_logic_vector(C_S2_AXI_ADDR_WIDTH-1 downto 0);
    S2_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S2_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S2_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S2_AXI_AWLOCK             : in  std_logic;
    S2_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S2_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S2_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S2_AXI_AWVALID            : in  std_logic;
    S2_AXI_AWREADY            : out std_logic;
    S2_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S2_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S2_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S2_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S2_AXI_WDATA              : in  std_logic_vector(C_S2_AXI_DATA_WIDTH-1 downto 0);
    S2_AXI_WSTRB              : in  std_logic_vector((C_S2_AXI_DATA_WIDTH/8)-1 downto 0);
    S2_AXI_WLAST              : in  std_logic;
    S2_AXI_WVALID             : in  std_logic;
    S2_AXI_WREADY             : out std_logic;
    
    S2_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S2_AXI_BID                : out std_logic_vector(C_S2_AXI_ID_WIDTH-1 downto 0);
    S2_AXI_BVALID             : out std_logic;
    S2_AXI_BREADY             : in  std_logic;
    S2_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S2_AXI_ARID               : in  std_logic_vector(C_S2_AXI_ID_WIDTH-1 downto 0);
    S2_AXI_ARADDR             : in  std_logic_vector(C_S2_AXI_ADDR_WIDTH-1 downto 0);
    S2_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S2_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S2_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S2_AXI_ARLOCK             : in  std_logic;
    S2_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S2_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S2_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S2_AXI_ARVALID            : in  std_logic;
    S2_AXI_ARREADY            : out std_logic;
    S2_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S2_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S2_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S2_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S2_AXI_RID                : out std_logic_vector(C_S2_AXI_ID_WIDTH-1 downto 0);
    S2_AXI_RDATA              : out std_logic_vector(C_S2_AXI_DATA_WIDTH-1 downto 0);
    S2_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S2_AXI_RLAST              : out std_logic;
    S2_AXI_RVALID             : out std_logic;
    S2_AXI_RREADY             : in  std_logic;
    S2_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S2_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S2_AXI_ACADDR             : out std_logic_vector(C_S2_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S2_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S2_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S2_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S2_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S2_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S2_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S2_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S2_AXI_CDDATA             : in  std_logic_vector(C_S2_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S2_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S2_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #3 Slave Signals.
    
    S3_AXI_AWID               : in  std_logic_vector(C_S3_AXI_ID_WIDTH-1 downto 0);
    S3_AXI_AWADDR             : in  std_logic_vector(C_S3_AXI_ADDR_WIDTH-1 downto 0);
    S3_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S3_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S3_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S3_AXI_AWLOCK             : in  std_logic;
    S3_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S3_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S3_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S3_AXI_AWVALID            : in  std_logic;
    S3_AXI_AWREADY            : out std_logic;
    S3_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S3_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S3_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S3_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S3_AXI_WDATA              : in  std_logic_vector(C_S3_AXI_DATA_WIDTH-1 downto 0);
    S3_AXI_WSTRB              : in  std_logic_vector((C_S3_AXI_DATA_WIDTH/8)-1 downto 0);
    S3_AXI_WLAST              : in  std_logic;
    S3_AXI_WVALID             : in  std_logic;
    S3_AXI_WREADY             : out std_logic;
    
    S3_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S3_AXI_BID                : out std_logic_vector(C_S3_AXI_ID_WIDTH-1 downto 0);
    S3_AXI_BVALID             : out std_logic;
    S3_AXI_BREADY             : in  std_logic;
    S3_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S3_AXI_ARID               : in  std_logic_vector(C_S3_AXI_ID_WIDTH-1 downto 0);
    S3_AXI_ARADDR             : in  std_logic_vector(C_S3_AXI_ADDR_WIDTH-1 downto 0);
    S3_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S3_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S3_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S3_AXI_ARLOCK             : in  std_logic;
    S3_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S3_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S3_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S3_AXI_ARVALID            : in  std_logic;
    S3_AXI_ARREADY            : out std_logic;
    S3_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S3_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S3_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S3_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S3_AXI_RID                : out std_logic_vector(C_S3_AXI_ID_WIDTH-1 downto 0);
    S3_AXI_RDATA              : out std_logic_vector(C_S3_AXI_DATA_WIDTH-1 downto 0);
    S3_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S3_AXI_RLAST              : out std_logic;
    S3_AXI_RVALID             : out std_logic;
    S3_AXI_RREADY             : in  std_logic;
    S3_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S3_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S3_AXI_ACADDR             : out std_logic_vector(C_S3_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S3_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S3_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S3_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S3_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S3_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S3_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S3_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S3_AXI_CDDATA             : in  std_logic_vector(C_S3_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S3_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S3_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #4 Slave Signals.
    
    S4_AXI_AWID               : in  std_logic_vector(C_S4_AXI_ID_WIDTH-1 downto 0);
    S4_AXI_AWADDR             : in  std_logic_vector(C_S4_AXI_ADDR_WIDTH-1 downto 0);
    S4_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S4_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S4_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S4_AXI_AWLOCK             : in  std_logic;
    S4_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S4_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S4_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S4_AXI_AWVALID            : in  std_logic;
    S4_AXI_AWREADY            : out std_logic;
    S4_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S4_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S4_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S4_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S4_AXI_WDATA              : in  std_logic_vector(C_S4_AXI_DATA_WIDTH-1 downto 0);
    S4_AXI_WSTRB              : in  std_logic_vector((C_S4_AXI_DATA_WIDTH/8)-1 downto 0);
    S4_AXI_WLAST              : in  std_logic;
    S4_AXI_WVALID             : in  std_logic;
    S4_AXI_WREADY             : out std_logic;
    
    S4_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S4_AXI_BID                : out std_logic_vector(C_S4_AXI_ID_WIDTH-1 downto 0);
    S4_AXI_BVALID             : out std_logic;
    S4_AXI_BREADY             : in  std_logic;
    S4_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S4_AXI_ARID               : in  std_logic_vector(C_S4_AXI_ID_WIDTH-1 downto 0);
    S4_AXI_ARADDR             : in  std_logic_vector(C_S4_AXI_ADDR_WIDTH-1 downto 0);
    S4_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S4_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S4_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S4_AXI_ARLOCK             : in  std_logic;
    S4_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S4_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S4_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S4_AXI_ARVALID            : in  std_logic;
    S4_AXI_ARREADY            : out std_logic;
    S4_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S4_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S4_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S4_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S4_AXI_RID                : out std_logic_vector(C_S4_AXI_ID_WIDTH-1 downto 0);
    S4_AXI_RDATA              : out std_logic_vector(C_S4_AXI_DATA_WIDTH-1 downto 0);
    S4_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S4_AXI_RLAST              : out std_logic;
    S4_AXI_RVALID             : out std_logic;
    S4_AXI_RREADY             : in  std_logic;
    S4_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S4_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S4_AXI_ACADDR             : out std_logic_vector(C_S4_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S4_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S4_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S4_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S4_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S4_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S4_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S4_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S4_AXI_CDDATA             : in  std_logic_vector(C_S4_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S4_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S4_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #5 Slave Signals.
    
    S5_AXI_AWID               : in  std_logic_vector(C_S5_AXI_ID_WIDTH-1 downto 0);
    S5_AXI_AWADDR             : in  std_logic_vector(C_S5_AXI_ADDR_WIDTH-1 downto 0);
    S5_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S5_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S5_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S5_AXI_AWLOCK             : in  std_logic;
    S5_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S5_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S5_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S5_AXI_AWVALID            : in  std_logic;
    S5_AXI_AWREADY            : out std_logic;
    S5_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S5_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S5_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S5_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S5_AXI_WDATA              : in  std_logic_vector(C_S5_AXI_DATA_WIDTH-1 downto 0);
    S5_AXI_WSTRB              : in  std_logic_vector((C_S5_AXI_DATA_WIDTH/8)-1 downto 0);
    S5_AXI_WLAST              : in  std_logic;
    S5_AXI_WVALID             : in  std_logic;
    S5_AXI_WREADY             : out std_logic;
    
    S5_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S5_AXI_BID                : out std_logic_vector(C_S5_AXI_ID_WIDTH-1 downto 0);
    S5_AXI_BVALID             : out std_logic;
    S5_AXI_BREADY             : in  std_logic;
    S5_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S5_AXI_ARID               : in  std_logic_vector(C_S5_AXI_ID_WIDTH-1 downto 0);
    S5_AXI_ARADDR             : in  std_logic_vector(C_S5_AXI_ADDR_WIDTH-1 downto 0);
    S5_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S5_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S5_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S5_AXI_ARLOCK             : in  std_logic;
    S5_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S5_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S5_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S5_AXI_ARVALID            : in  std_logic;
    S5_AXI_ARREADY            : out std_logic;
    S5_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S5_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S5_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S5_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S5_AXI_RID                : out std_logic_vector(C_S5_AXI_ID_WIDTH-1 downto 0);
    S5_AXI_RDATA              : out std_logic_vector(C_S5_AXI_DATA_WIDTH-1 downto 0);
    S5_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S5_AXI_RLAST              : out std_logic;
    S5_AXI_RVALID             : out std_logic;
    S5_AXI_RREADY             : in  std_logic;
    S5_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S5_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S5_AXI_ACADDR             : out std_logic_vector(C_S5_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S5_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S5_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S5_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S5_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S5_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S5_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S5_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S5_AXI_CDDATA             : in  std_logic_vector(C_S5_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S5_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S5_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #6 Slave Signals.
    
    S6_AXI_AWID               : in  std_logic_vector(C_S6_AXI_ID_WIDTH-1 downto 0);
    S6_AXI_AWADDR             : in  std_logic_vector(C_S6_AXI_ADDR_WIDTH-1 downto 0);
    S6_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S6_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S6_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S6_AXI_AWLOCK             : in  std_logic;
    S6_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S6_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S6_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S6_AXI_AWVALID            : in  std_logic;
    S6_AXI_AWREADY            : out std_logic;
    S6_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S6_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S6_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S6_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S6_AXI_WDATA              : in  std_logic_vector(C_S6_AXI_DATA_WIDTH-1 downto 0);
    S6_AXI_WSTRB              : in  std_logic_vector((C_S6_AXI_DATA_WIDTH/8)-1 downto 0);
    S6_AXI_WLAST              : in  std_logic;
    S6_AXI_WVALID             : in  std_logic;
    S6_AXI_WREADY             : out std_logic;
    
    S6_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S6_AXI_BID                : out std_logic_vector(C_S6_AXI_ID_WIDTH-1 downto 0);
    S6_AXI_BVALID             : out std_logic;
    S6_AXI_BREADY             : in  std_logic;
    S6_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S6_AXI_ARID               : in  std_logic_vector(C_S6_AXI_ID_WIDTH-1 downto 0);
    S6_AXI_ARADDR             : in  std_logic_vector(C_S6_AXI_ADDR_WIDTH-1 downto 0);
    S6_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S6_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S6_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S6_AXI_ARLOCK             : in  std_logic;
    S6_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S6_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S6_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S6_AXI_ARVALID            : in  std_logic;
    S6_AXI_ARREADY            : out std_logic;
    S6_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S6_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S6_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S6_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S6_AXI_RID                : out std_logic_vector(C_S6_AXI_ID_WIDTH-1 downto 0);
    S6_AXI_RDATA              : out std_logic_vector(C_S6_AXI_DATA_WIDTH-1 downto 0);
    S6_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S6_AXI_RLAST              : out std_logic;
    S6_AXI_RVALID             : out std_logic;
    S6_AXI_RREADY             : in  std_logic;
    S6_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S6_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S6_AXI_ACADDR             : out std_logic_vector(C_S6_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S6_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S6_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S6_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S6_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S6_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S6_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S6_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S6_AXI_CDDATA             : in  std_logic_vector(C_S6_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S6_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S6_AXI_CDREADY            : out std_logic;                                         -- For ACE
    

    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #7 Slave Signals.
    
    S7_AXI_AWID               : in  std_logic_vector(C_S7_AXI_ID_WIDTH-1 downto 0);
    S7_AXI_AWADDR             : in  std_logic_vector(C_S7_AXI_ADDR_WIDTH-1 downto 0);
    S7_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S7_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S7_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S7_AXI_AWLOCK             : in  std_logic;
    S7_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S7_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S7_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S7_AXI_AWVALID            : in  std_logic;
    S7_AXI_AWREADY            : out std_logic;
    S7_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S7_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S7_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S7_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S7_AXI_WDATA              : in  std_logic_vector(C_S7_AXI_DATA_WIDTH-1 downto 0);
    S7_AXI_WSTRB              : in  std_logic_vector((C_S7_AXI_DATA_WIDTH/8)-1 downto 0);
    S7_AXI_WLAST              : in  std_logic;
    S7_AXI_WVALID             : in  std_logic;
    S7_AXI_WREADY             : out std_logic;
    
    S7_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S7_AXI_BID                : out std_logic_vector(C_S7_AXI_ID_WIDTH-1 downto 0);
    S7_AXI_BVALID             : out std_logic;
    S7_AXI_BREADY             : in  std_logic;
    S7_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S7_AXI_ARID               : in  std_logic_vector(C_S7_AXI_ID_WIDTH-1 downto 0);
    S7_AXI_ARADDR             : in  std_logic_vector(C_S7_AXI_ADDR_WIDTH-1 downto 0);
    S7_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S7_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S7_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S7_AXI_ARLOCK             : in  std_logic;
    S7_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S7_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S7_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S7_AXI_ARVALID            : in  std_logic;
    S7_AXI_ARREADY            : out std_logic;
    S7_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S7_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S7_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S7_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S7_AXI_RID                : out std_logic_vector(C_S7_AXI_ID_WIDTH-1 downto 0);
    S7_AXI_RDATA              : out std_logic_vector(C_S7_AXI_DATA_WIDTH-1 downto 0);
    S7_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S7_AXI_RLAST              : out std_logic;
    S7_AXI_RVALID             : out std_logic;
    S7_AXI_RREADY             : in  std_logic;
    S7_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S7_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S7_AXI_ACADDR             : out std_logic_vector(C_S7_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S7_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S7_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S7_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S7_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S7_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S7_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S7_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S7_AXI_CDDATA             : in  std_logic_vector(C_S7_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S7_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S7_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #8 Slave Signals.
    
    S8_AXI_AWID               : in  std_logic_vector(C_S8_AXI_ID_WIDTH-1 downto 0);
    S8_AXI_AWADDR             : in  std_logic_vector(C_S8_AXI_ADDR_WIDTH-1 downto 0);
    S8_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S8_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S8_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S8_AXI_AWLOCK             : in  std_logic;
    S8_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S8_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S8_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S8_AXI_AWVALID            : in  std_logic;
    S8_AXI_AWREADY            : out std_logic;
    S8_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S8_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S8_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S8_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S8_AXI_WDATA              : in  std_logic_vector(C_S8_AXI_DATA_WIDTH-1 downto 0);
    S8_AXI_WSTRB              : in  std_logic_vector((C_S8_AXI_DATA_WIDTH/8)-1 downto 0);
    S8_AXI_WLAST              : in  std_logic;
    S8_AXI_WVALID             : in  std_logic;
    S8_AXI_WREADY             : out std_logic;
    
    S8_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S8_AXI_BID                : out std_logic_vector(C_S8_AXI_ID_WIDTH-1 downto 0);
    S8_AXI_BVALID             : out std_logic;
    S8_AXI_BREADY             : in  std_logic;
    S8_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S8_AXI_ARID               : in  std_logic_vector(C_S8_AXI_ID_WIDTH-1 downto 0);
    S8_AXI_ARADDR             : in  std_logic_vector(C_S8_AXI_ADDR_WIDTH-1 downto 0);
    S8_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S8_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S8_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S8_AXI_ARLOCK             : in  std_logic;
    S8_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S8_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S8_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S8_AXI_ARVALID            : in  std_logic;
    S8_AXI_ARREADY            : out std_logic;
    S8_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S8_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S8_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S8_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S8_AXI_RID                : out std_logic_vector(C_S8_AXI_ID_WIDTH-1 downto 0);
    S8_AXI_RDATA              : out std_logic_vector(C_S8_AXI_DATA_WIDTH-1 downto 0);
    S8_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S8_AXI_RLAST              : out std_logic;
    S8_AXI_RVALID             : out std_logic;
    S8_AXI_RREADY             : in  std_logic;
    S8_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S8_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S8_AXI_ACADDR             : out std_logic_vector(C_S8_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S8_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S8_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S8_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S8_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S8_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S8_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S8_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S8_AXI_CDDATA             : in  std_logic_vector(C_S8_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S8_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S8_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #9 Slave Signals.
    
    S9_AXI_AWID               : in  std_logic_vector(C_S9_AXI_ID_WIDTH-1 downto 0);
    S9_AXI_AWADDR             : in  std_logic_vector(C_S9_AXI_ADDR_WIDTH-1 downto 0);
    S9_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S9_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S9_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S9_AXI_AWLOCK             : in  std_logic;
    S9_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S9_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S9_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S9_AXI_AWVALID            : in  std_logic;
    S9_AXI_AWREADY            : out std_logic;
    S9_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S9_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S9_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S9_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S9_AXI_WDATA              : in  std_logic_vector(C_S9_AXI_DATA_WIDTH-1 downto 0);
    S9_AXI_WSTRB              : in  std_logic_vector((C_S9_AXI_DATA_WIDTH/8)-1 downto 0);
    S9_AXI_WLAST              : in  std_logic;
    S9_AXI_WVALID             : in  std_logic;
    S9_AXI_WREADY             : out std_logic;
    
    S9_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S9_AXI_BID                : out std_logic_vector(C_S9_AXI_ID_WIDTH-1 downto 0);
    S9_AXI_BVALID             : out std_logic;
    S9_AXI_BREADY             : in  std_logic;
    S9_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S9_AXI_ARID               : in  std_logic_vector(C_S9_AXI_ID_WIDTH-1 downto 0);
    S9_AXI_ARADDR             : in  std_logic_vector(C_S9_AXI_ADDR_WIDTH-1 downto 0);
    S9_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S9_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S9_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S9_AXI_ARLOCK             : in  std_logic;
    S9_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S9_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S9_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S9_AXI_ARVALID            : in  std_logic;
    S9_AXI_ARREADY            : out std_logic;
    S9_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S9_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S9_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S9_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S9_AXI_RID                : out std_logic_vector(C_S9_AXI_ID_WIDTH-1 downto 0);
    S9_AXI_RDATA              : out std_logic_vector(C_S9_AXI_DATA_WIDTH-1 downto 0);
    S9_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S9_AXI_RLAST              : out std_logic;
    S9_AXI_RVALID             : out std_logic;
    S9_AXI_RREADY             : in  std_logic;
    S9_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S9_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S9_AXI_ACADDR             : out std_logic_vector(C_S9_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S9_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S9_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S9_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S9_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S9_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S9_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S9_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S9_AXI_CDDATA             : in  std_logic_vector(C_S9_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S9_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S9_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #10 Slave Signals.
    
    S10_AXI_AWID               : in  std_logic_vector(C_S10_AXI_ID_WIDTH-1 downto 0);
    S10_AXI_AWADDR             : in  std_logic_vector(C_S10_AXI_ADDR_WIDTH-1 downto 0);
    S10_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S10_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S10_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S10_AXI_AWLOCK             : in  std_logic;
    S10_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S10_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S10_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S10_AXI_AWVALID            : in  std_logic;
    S10_AXI_AWREADY            : out std_logic;
    S10_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S10_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S10_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S10_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S10_AXI_WDATA              : in  std_logic_vector(C_S10_AXI_DATA_WIDTH-1 downto 0);
    S10_AXI_WSTRB              : in  std_logic_vector((C_S10_AXI_DATA_WIDTH/8)-1 downto 0);
    S10_AXI_WLAST              : in  std_logic;
    S10_AXI_WVALID             : in  std_logic;
    S10_AXI_WREADY             : out std_logic;
    
    S10_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S10_AXI_BID                : out std_logic_vector(C_S10_AXI_ID_WIDTH-1 downto 0);
    S10_AXI_BVALID             : out std_logic;
    S10_AXI_BREADY             : in  std_logic;
    S10_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S10_AXI_ARID               : in  std_logic_vector(C_S10_AXI_ID_WIDTH-1 downto 0);
    S10_AXI_ARADDR             : in  std_logic_vector(C_S10_AXI_ADDR_WIDTH-1 downto 0);
    S10_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S10_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S10_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S10_AXI_ARLOCK             : in  std_logic;
    S10_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S10_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S10_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S10_AXI_ARVALID            : in  std_logic;
    S10_AXI_ARREADY            : out std_logic;
    S10_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S10_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S10_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S10_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S10_AXI_RID                : out std_logic_vector(C_S10_AXI_ID_WIDTH-1 downto 0);
    S10_AXI_RDATA              : out std_logic_vector(C_S10_AXI_DATA_WIDTH-1 downto 0);
    S10_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S10_AXI_RLAST              : out std_logic;
    S10_AXI_RVALID             : out std_logic;
    S10_AXI_RREADY             : in  std_logic;
    S10_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S10_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S10_AXI_ACADDR             : out std_logic_vector(C_S10_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S10_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S10_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S10_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S10_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S10_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S10_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S10_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S10_AXI_CDDATA             : in  std_logic_vector(C_S10_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S10_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S10_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #11 Slave Signals.
    
    S11_AXI_AWID               : in  std_logic_vector(C_S11_AXI_ID_WIDTH-1 downto 0);
    S11_AXI_AWADDR             : in  std_logic_vector(C_S11_AXI_ADDR_WIDTH-1 downto 0);
    S11_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S11_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S11_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S11_AXI_AWLOCK             : in  std_logic;
    S11_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S11_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S11_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S11_AXI_AWVALID            : in  std_logic;
    S11_AXI_AWREADY            : out std_logic;
    S11_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S11_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S11_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S11_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S11_AXI_WDATA              : in  std_logic_vector(C_S11_AXI_DATA_WIDTH-1 downto 0);
    S11_AXI_WSTRB              : in  std_logic_vector((C_S11_AXI_DATA_WIDTH/8)-1 downto 0);
    S11_AXI_WLAST              : in  std_logic;
    S11_AXI_WVALID             : in  std_logic;
    S11_AXI_WREADY             : out std_logic;
    
    S11_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S11_AXI_BID                : out std_logic_vector(C_S11_AXI_ID_WIDTH-1 downto 0);
    S11_AXI_BVALID             : out std_logic;
    S11_AXI_BREADY             : in  std_logic;
    S11_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S11_AXI_ARID               : in  std_logic_vector(C_S11_AXI_ID_WIDTH-1 downto 0);
    S11_AXI_ARADDR             : in  std_logic_vector(C_S11_AXI_ADDR_WIDTH-1 downto 0);
    S11_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S11_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S11_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S11_AXI_ARLOCK             : in  std_logic;
    S11_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S11_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S11_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S11_AXI_ARVALID            : in  std_logic;
    S11_AXI_ARREADY            : out std_logic;
    S11_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S11_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S11_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S11_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S11_AXI_RID                : out std_logic_vector(C_S11_AXI_ID_WIDTH-1 downto 0);
    S11_AXI_RDATA              : out std_logic_vector(C_S11_AXI_DATA_WIDTH-1 downto 0);
    S11_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S11_AXI_RLAST              : out std_logic;
    S11_AXI_RVALID             : out std_logic;
    S11_AXI_RREADY             : in  std_logic;
    S11_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S11_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S11_AXI_ACADDR             : out std_logic_vector(C_S11_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S11_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S11_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S11_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S11_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S11_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S11_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S11_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S11_AXI_CDDATA             : in  std_logic_vector(C_S11_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S11_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S11_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #12 Slave Signals.
    
    S12_AXI_AWID               : in  std_logic_vector(C_S12_AXI_ID_WIDTH-1 downto 0);
    S12_AXI_AWADDR             : in  std_logic_vector(C_S12_AXI_ADDR_WIDTH-1 downto 0);
    S12_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S12_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S12_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S12_AXI_AWLOCK             : in  std_logic;
    S12_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S12_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S12_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S12_AXI_AWVALID            : in  std_logic;
    S12_AXI_AWREADY            : out std_logic;
    S12_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S12_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S12_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S12_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S12_AXI_WDATA              : in  std_logic_vector(C_S12_AXI_DATA_WIDTH-1 downto 0);
    S12_AXI_WSTRB              : in  std_logic_vector((C_S12_AXI_DATA_WIDTH/8)-1 downto 0);
    S12_AXI_WLAST              : in  std_logic;
    S12_AXI_WVALID             : in  std_logic;
    S12_AXI_WREADY             : out std_logic;
    
    S12_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S12_AXI_BID                : out std_logic_vector(C_S12_AXI_ID_WIDTH-1 downto 0);
    S12_AXI_BVALID             : out std_logic;
    S12_AXI_BREADY             : in  std_logic;
    S12_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S12_AXI_ARID               : in  std_logic_vector(C_S12_AXI_ID_WIDTH-1 downto 0);
    S12_AXI_ARADDR             : in  std_logic_vector(C_S12_AXI_ADDR_WIDTH-1 downto 0);
    S12_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S12_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S12_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S12_AXI_ARLOCK             : in  std_logic;
    S12_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S12_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S12_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S12_AXI_ARVALID            : in  std_logic;
    S12_AXI_ARREADY            : out std_logic;
    S12_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S12_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S12_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S12_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S12_AXI_RID                : out std_logic_vector(C_S12_AXI_ID_WIDTH-1 downto 0);
    S12_AXI_RDATA              : out std_logic_vector(C_S12_AXI_DATA_WIDTH-1 downto 0);
    S12_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S12_AXI_RLAST              : out std_logic;
    S12_AXI_RVALID             : out std_logic;
    S12_AXI_RREADY             : in  std_logic;
    S12_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S12_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S12_AXI_ACADDR             : out std_logic_vector(C_S12_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S12_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S12_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S12_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S12_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S12_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S12_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S12_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S12_AXI_CDDATA             : in  std_logic_vector(C_S12_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S12_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S12_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #13 Slave Signals.
    
    S13_AXI_AWID               : in  std_logic_vector(C_S13_AXI_ID_WIDTH-1 downto 0);
    S13_AXI_AWADDR             : in  std_logic_vector(C_S13_AXI_ADDR_WIDTH-1 downto 0);
    S13_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S13_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S13_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S13_AXI_AWLOCK             : in  std_logic;
    S13_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S13_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S13_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S13_AXI_AWVALID            : in  std_logic;
    S13_AXI_AWREADY            : out std_logic;
    S13_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S13_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S13_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S13_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S13_AXI_WDATA              : in  std_logic_vector(C_S13_AXI_DATA_WIDTH-1 downto 0);
    S13_AXI_WSTRB              : in  std_logic_vector((C_S13_AXI_DATA_WIDTH/8)-1 downto 0);
    S13_AXI_WLAST              : in  std_logic;
    S13_AXI_WVALID             : in  std_logic;
    S13_AXI_WREADY             : out std_logic;
    
    S13_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S13_AXI_BID                : out std_logic_vector(C_S13_AXI_ID_WIDTH-1 downto 0);
    S13_AXI_BVALID             : out std_logic;
    S13_AXI_BREADY             : in  std_logic;
    S13_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S13_AXI_ARID               : in  std_logic_vector(C_S13_AXI_ID_WIDTH-1 downto 0);
    S13_AXI_ARADDR             : in  std_logic_vector(C_S13_AXI_ADDR_WIDTH-1 downto 0);
    S13_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S13_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S13_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S13_AXI_ARLOCK             : in  std_logic;
    S13_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S13_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S13_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S13_AXI_ARVALID            : in  std_logic;
    S13_AXI_ARREADY            : out std_logic;
    S13_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S13_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S13_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S13_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S13_AXI_RID                : out std_logic_vector(C_S13_AXI_ID_WIDTH-1 downto 0);
    S13_AXI_RDATA              : out std_logic_vector(C_S13_AXI_DATA_WIDTH-1 downto 0);
    S13_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S13_AXI_RLAST              : out std_logic;
    S13_AXI_RVALID             : out std_logic;
    S13_AXI_RREADY             : in  std_logic;
    S13_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S13_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S13_AXI_ACADDR             : out std_logic_vector(C_S13_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S13_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S13_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S13_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S13_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S13_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S13_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S13_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S13_AXI_CDDATA             : in  std_logic_vector(C_S13_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S13_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S13_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #14 Slave Signals.
    
    S14_AXI_AWID               : in  std_logic_vector(C_S14_AXI_ID_WIDTH-1 downto 0);
    S14_AXI_AWADDR             : in  std_logic_vector(C_S14_AXI_ADDR_WIDTH-1 downto 0);
    S14_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S14_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S14_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S14_AXI_AWLOCK             : in  std_logic;
    S14_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S14_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S14_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S14_AXI_AWVALID            : in  std_logic;
    S14_AXI_AWREADY            : out std_logic;
    S14_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S14_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S14_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S14_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S14_AXI_WDATA              : in  std_logic_vector(C_S14_AXI_DATA_WIDTH-1 downto 0);
    S14_AXI_WSTRB              : in  std_logic_vector((C_S14_AXI_DATA_WIDTH/8)-1 downto 0);
    S14_AXI_WLAST              : in  std_logic;
    S14_AXI_WVALID             : in  std_logic;
    S14_AXI_WREADY             : out std_logic;
    
    S14_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S14_AXI_BID                : out std_logic_vector(C_S14_AXI_ID_WIDTH-1 downto 0);
    S14_AXI_BVALID             : out std_logic;
    S14_AXI_BREADY             : in  std_logic;
    S14_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S14_AXI_ARID               : in  std_logic_vector(C_S14_AXI_ID_WIDTH-1 downto 0);
    S14_AXI_ARADDR             : in  std_logic_vector(C_S14_AXI_ADDR_WIDTH-1 downto 0);
    S14_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S14_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S14_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S14_AXI_ARLOCK             : in  std_logic;
    S14_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S14_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S14_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S14_AXI_ARVALID            : in  std_logic;
    S14_AXI_ARREADY            : out std_logic;
    S14_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S14_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S14_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S14_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S14_AXI_RID                : out std_logic_vector(C_S14_AXI_ID_WIDTH-1 downto 0);
    S14_AXI_RDATA              : out std_logic_vector(C_S14_AXI_DATA_WIDTH-1 downto 0);
    S14_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S14_AXI_RLAST              : out std_logic;
    S14_AXI_RVALID             : out std_logic;
    S14_AXI_RREADY             : in  std_logic;
    S14_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S14_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S14_AXI_ACADDR             : out std_logic_vector(C_S14_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S14_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S14_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S14_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S14_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S14_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S14_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S14_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S14_AXI_CDDATA             : in  std_logic_vector(C_S14_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S14_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S14_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Optimized AXI4/ACE Interface #15 Slave Signals.
    
    S15_AXI_AWID               : in  std_logic_vector(C_S15_AXI_ID_WIDTH-1 downto 0);
    S15_AXI_AWADDR             : in  std_logic_vector(C_S15_AXI_ADDR_WIDTH-1 downto 0);
    S15_AXI_AWLEN              : in  std_logic_vector(7 downto 0);
    S15_AXI_AWSIZE             : in  std_logic_vector(2 downto 0);
    S15_AXI_AWBURST            : in  std_logic_vector(1 downto 0);
    S15_AXI_AWLOCK             : in  std_logic;
    S15_AXI_AWCACHE            : in  std_logic_vector(3 downto 0);
    S15_AXI_AWPROT             : in  std_logic_vector(2 downto 0);
    S15_AXI_AWQOS              : in  std_logic_vector(3 downto 0);
    S15_AXI_AWVALID            : in  std_logic;
    S15_AXI_AWREADY            : out std_logic;
    S15_AXI_AWDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S15_AXI_AWSNOOP            : in  std_logic_vector(2 downto 0);                      -- For ACE
    S15_AXI_AWBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S15_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S15_AXI_WDATA              : in  std_logic_vector(C_S15_AXI_DATA_WIDTH-1 downto 0);
    S15_AXI_WSTRB              : in  std_logic_vector((C_S15_AXI_DATA_WIDTH/8)-1 downto 0);
    S15_AXI_WLAST              : in  std_logic;
    S15_AXI_WVALID             : in  std_logic;
    S15_AXI_WREADY             : out std_logic;
    
    S15_AXI_BRESP              : out std_logic_vector(1 downto 0);
    S15_AXI_BID                : out std_logic_vector(C_S15_AXI_ID_WIDTH-1 downto 0);
    S15_AXI_BVALID             : out std_logic;
    S15_AXI_BREADY             : in  std_logic;
    S15_AXI_WACK               : in  std_logic;                                         -- For ACE
    
    S15_AXI_ARID               : in  std_logic_vector(C_S15_AXI_ID_WIDTH-1 downto 0);
    S15_AXI_ARADDR             : in  std_logic_vector(C_S15_AXI_ADDR_WIDTH-1 downto 0);
    S15_AXI_ARLEN              : in  std_logic_vector(7 downto 0);
    S15_AXI_ARSIZE             : in  std_logic_vector(2 downto 0);
    S15_AXI_ARBURST            : in  std_logic_vector(1 downto 0);
    S15_AXI_ARLOCK             : in  std_logic;
    S15_AXI_ARCACHE            : in  std_logic_vector(3 downto 0);
    S15_AXI_ARPROT             : in  std_logic_vector(2 downto 0);
    S15_AXI_ARQOS              : in  std_logic_vector(3 downto 0);
    S15_AXI_ARVALID            : in  std_logic;
    S15_AXI_ARREADY            : out std_logic;
    S15_AXI_ARDOMAIN           : in  std_logic_vector(1 downto 0);                      -- For ACE
    S15_AXI_ARSNOOP            : in  std_logic_vector(3 downto 0);                      -- For ACE
    S15_AXI_ARBAR              : in  std_logic_vector(1 downto 0);                      -- For ACE
    S15_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S15_AXI_RID                : out std_logic_vector(C_S15_AXI_ID_WIDTH-1 downto 0);
    S15_AXI_RDATA              : out std_logic_vector(C_S15_AXI_DATA_WIDTH-1 downto 0);
    S15_AXI_RRESP              : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S15_AXI_RLAST              : out std_logic;
    S15_AXI_RVALID             : out std_logic;
    S15_AXI_RREADY             : in  std_logic;
    S15_AXI_RACK               : in  std_logic;                                         -- For ACE
    
    S15_AXI_ACVALID            : out std_logic;                                         -- For ACE
    S15_AXI_ACADDR             : out std_logic_vector(C_S15_AXI_ADDR_WIDTH-1 downto 0);  -- For ACE
    S15_AXI_ACSNOOP            : out std_logic_vector(3 downto 0);                      -- For ACE
    S15_AXI_ACPROT             : out std_logic_vector(2 downto 0);                      -- For ACE
    S15_AXI_ACREADY            : in  std_logic;                                         -- For ACE
    
    S15_AXI_CRVALID            : in  std_logic;                                         -- For ACE
    S15_AXI_CRRESP             : in  std_logic_vector(4 downto 0);                      -- For ACE
    S15_AXI_CRREADY            : out std_logic;                                         -- For ACE
    
    S15_AXI_CDVALID            : in  std_logic;                                         -- For ACE
    S15_AXI_CDDATA             : in  std_logic_vector(C_S15_AXI_DATA_WIDTH-1 downto 0);  -- For ACE
    S15_AXI_CDLAST             : in  std_logic;                                         -- For ACE
    S15_AXI_CDREADY            : out std_logic;                                         -- For ACE
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #0 Slave Signals.
    
    S0_AXI_GEN_AWID           : in  std_logic_vector(C_S0_AXI_GEN_ID_WIDTH-1 downto 0);
    S0_AXI_GEN_AWADDR         : in  std_logic_vector(C_S0_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S0_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S0_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S0_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S0_AXI_GEN_AWLOCK         : in  std_logic;
    S0_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S0_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S0_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S0_AXI_GEN_AWVALID        : in  std_logic;
    S0_AXI_GEN_AWREADY        : out std_logic;
    S0_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S0_AXI_GEN_WDATA          : in  std_logic_vector(C_S0_AXI_GEN_DATA_WIDTH-1 downto 0);
    S0_AXI_GEN_WSTRB          : in  std_logic_vector((C_S0_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S0_AXI_GEN_WLAST          : in  std_logic;
    S0_AXI_GEN_WVALID         : in  std_logic;
    S0_AXI_GEN_WREADY         : out std_logic;
    
    S0_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S0_AXI_GEN_BID            : out std_logic_vector(C_S0_AXI_GEN_ID_WIDTH-1 downto 0);
    S0_AXI_GEN_BVALID         : out std_logic;
    S0_AXI_GEN_BREADY         : in  std_logic;
    
    S0_AXI_GEN_ARID           : in  std_logic_vector(C_S0_AXI_GEN_ID_WIDTH-1 downto 0);
    S0_AXI_GEN_ARADDR         : in  std_logic_vector(C_S0_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S0_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S0_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S0_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S0_AXI_GEN_ARLOCK         : in  std_logic;
    S0_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S0_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S0_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S0_AXI_GEN_ARVALID        : in  std_logic;
    S0_AXI_GEN_ARREADY        : out std_logic;
    S0_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S0_AXI_GEN_RID            : out std_logic_vector(C_S0_AXI_GEN_ID_WIDTH-1 downto 0);
    S0_AXI_GEN_RDATA          : out std_logic_vector(C_S0_AXI_GEN_DATA_WIDTH-1 downto 0);
    S0_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S0_AXI_GEN_RLAST          : out std_logic;
    S0_AXI_GEN_RVALID         : out std_logic;
    S0_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #1 Slave Signals.
    
    S1_AXI_GEN_AWID           : in  std_logic_vector(C_S1_AXI_GEN_ID_WIDTH-1 downto 0);
    S1_AXI_GEN_AWADDR         : in  std_logic_vector(C_S1_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S1_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S1_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S1_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S1_AXI_GEN_AWLOCK         : in  std_logic;
    S1_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S1_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S1_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S1_AXI_GEN_AWVALID        : in  std_logic;
    S1_AXI_GEN_AWREADY        : out std_logic;
    S1_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S1_AXI_GEN_WDATA          : in  std_logic_vector(C_S1_AXI_GEN_DATA_WIDTH-1 downto 0);
    S1_AXI_GEN_WSTRB          : in  std_logic_vector((C_S1_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S1_AXI_GEN_WLAST          : in  std_logic;
    S1_AXI_GEN_WVALID         : in  std_logic;
    S1_AXI_GEN_WREADY         : out std_logic;
    
    S1_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S1_AXI_GEN_BID            : out std_logic_vector(C_S1_AXI_GEN_ID_WIDTH-1 downto 0);
    S1_AXI_GEN_BVALID         : out std_logic;
    S1_AXI_GEN_BREADY         : in  std_logic;
    
    S1_AXI_GEN_ARID           : in  std_logic_vector(C_S1_AXI_GEN_ID_WIDTH-1 downto 0);
    S1_AXI_GEN_ARADDR         : in  std_logic_vector(C_S1_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S1_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S1_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S1_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S1_AXI_GEN_ARLOCK         : in  std_logic;
    S1_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S1_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S1_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S1_AXI_GEN_ARVALID        : in  std_logic;
    S1_AXI_GEN_ARREADY        : out std_logic;
    S1_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S1_AXI_GEN_RID            : out std_logic_vector(C_S1_AXI_GEN_ID_WIDTH-1 downto 0);
    S1_AXI_GEN_RDATA          : out std_logic_vector(C_S1_AXI_GEN_DATA_WIDTH-1 downto 0);
    S1_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S1_AXI_GEN_RLAST          : out std_logic;
    S1_AXI_GEN_RVALID         : out std_logic;
    S1_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #2 Slave Signals.
    
    S2_AXI_GEN_AWID           : in  std_logic_vector(C_S2_AXI_GEN_ID_WIDTH-1 downto 0);
    S2_AXI_GEN_AWADDR         : in  std_logic_vector(C_S2_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S2_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S2_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S2_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S2_AXI_GEN_AWLOCK         : in  std_logic;
    S2_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S2_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S2_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S2_AXI_GEN_AWVALID        : in  std_logic;
    S2_AXI_GEN_AWREADY        : out std_logic;
    S2_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S2_AXI_GEN_WDATA          : in  std_logic_vector(C_S2_AXI_GEN_DATA_WIDTH-1 downto 0);
    S2_AXI_GEN_WSTRB          : in  std_logic_vector((C_S2_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S2_AXI_GEN_WLAST          : in  std_logic;
    S2_AXI_GEN_WVALID         : in  std_logic;
    S2_AXI_GEN_WREADY         : out std_logic;
    
    S2_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S2_AXI_GEN_BID            : out std_logic_vector(C_S2_AXI_GEN_ID_WIDTH-1 downto 0);
    S2_AXI_GEN_BVALID         : out std_logic;
    S2_AXI_GEN_BREADY         : in  std_logic;
    
    S2_AXI_GEN_ARID           : in  std_logic_vector(C_S2_AXI_GEN_ID_WIDTH-1 downto 0);
    S2_AXI_GEN_ARADDR         : in  std_logic_vector(C_S2_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S2_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S2_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S2_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S2_AXI_GEN_ARLOCK         : in  std_logic;
    S2_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S2_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S2_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S2_AXI_GEN_ARVALID        : in  std_logic;
    S2_AXI_GEN_ARREADY        : out std_logic;
    S2_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S2_AXI_GEN_RID            : out std_logic_vector(C_S2_AXI_GEN_ID_WIDTH-1 downto 0);
    S2_AXI_GEN_RDATA          : out std_logic_vector(C_S2_AXI_GEN_DATA_WIDTH-1 downto 0);
    S2_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S2_AXI_GEN_RLAST          : out std_logic;
    S2_AXI_GEN_RVALID         : out std_logic;
    S2_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #3 Slave Signals.
    
    S3_AXI_GEN_AWID           : in  std_logic_vector(C_S3_AXI_GEN_ID_WIDTH-1 downto 0);
    S3_AXI_GEN_AWADDR         : in  std_logic_vector(C_S3_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S3_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S3_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S3_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S3_AXI_GEN_AWLOCK         : in  std_logic;
    S3_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S3_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S3_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S3_AXI_GEN_AWVALID        : in  std_logic;
    S3_AXI_GEN_AWREADY        : out std_logic;
    S3_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S3_AXI_GEN_WDATA          : in  std_logic_vector(C_S3_AXI_GEN_DATA_WIDTH-1 downto 0);
    S3_AXI_GEN_WSTRB          : in  std_logic_vector((C_S3_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S3_AXI_GEN_WLAST          : in  std_logic;
    S3_AXI_GEN_WVALID         : in  std_logic;
    S3_AXI_GEN_WREADY         : out std_logic;
    
    S3_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S3_AXI_GEN_BID            : out std_logic_vector(C_S3_AXI_GEN_ID_WIDTH-1 downto 0);
    S3_AXI_GEN_BVALID         : out std_logic;
    S3_AXI_GEN_BREADY         : in  std_logic;
    
    S3_AXI_GEN_ARID           : in  std_logic_vector(C_S3_AXI_GEN_ID_WIDTH-1 downto 0);
    S3_AXI_GEN_ARADDR         : in  std_logic_vector(C_S3_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S3_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S3_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S3_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S3_AXI_GEN_ARLOCK         : in  std_logic;
    S3_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S3_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S3_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S3_AXI_GEN_ARVALID        : in  std_logic;
    S3_AXI_GEN_ARREADY        : out std_logic;
    S3_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S3_AXI_GEN_RID            : out std_logic_vector(C_S3_AXI_GEN_ID_WIDTH-1 downto 0);
    S3_AXI_GEN_RDATA          : out std_logic_vector(C_S3_AXI_GEN_DATA_WIDTH-1 downto 0);
    S3_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S3_AXI_GEN_RLAST          : out std_logic;
    S3_AXI_GEN_RVALID         : out std_logic;
    S3_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #4 Slave Signals.
    
    S4_AXI_GEN_AWID           : in  std_logic_vector(C_S4_AXI_GEN_ID_WIDTH-1 downto 0);
    S4_AXI_GEN_AWADDR         : in  std_logic_vector(C_S4_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S4_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S4_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S4_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S4_AXI_GEN_AWLOCK         : in  std_logic;
    S4_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S4_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S4_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S4_AXI_GEN_AWVALID        : in  std_logic;
    S4_AXI_GEN_AWREADY        : out std_logic;
    S4_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S4_AXI_GEN_WDATA          : in  std_logic_vector(C_S4_AXI_GEN_DATA_WIDTH-1 downto 0);
    S4_AXI_GEN_WSTRB          : in  std_logic_vector((C_S4_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S4_AXI_GEN_WLAST          : in  std_logic;
    S4_AXI_GEN_WVALID         : in  std_logic;
    S4_AXI_GEN_WREADY         : out std_logic;
    
    S4_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S4_AXI_GEN_BID            : out std_logic_vector(C_S4_AXI_GEN_ID_WIDTH-1 downto 0);
    S4_AXI_GEN_BVALID         : out std_logic;
    S4_AXI_GEN_BREADY         : in  std_logic;
    
    S4_AXI_GEN_ARID           : in  std_logic_vector(C_S4_AXI_GEN_ID_WIDTH-1 downto 0);
    S4_AXI_GEN_ARADDR         : in  std_logic_vector(C_S4_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S4_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S4_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S4_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S4_AXI_GEN_ARLOCK         : in  std_logic;
    S4_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S4_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S4_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S4_AXI_GEN_ARVALID        : in  std_logic;
    S4_AXI_GEN_ARREADY        : out std_logic;
    S4_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S4_AXI_GEN_RID            : out std_logic_vector(C_S4_AXI_GEN_ID_WIDTH-1 downto 0);
    S4_AXI_GEN_RDATA          : out std_logic_vector(C_S4_AXI_GEN_DATA_WIDTH-1 downto 0);
    S4_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S4_AXI_GEN_RLAST          : out std_logic;
    S4_AXI_GEN_RVALID         : out std_logic;
    S4_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #5 Slave Signals.
    
    S5_AXI_GEN_AWID           : in  std_logic_vector(C_S5_AXI_GEN_ID_WIDTH-1 downto 0);
    S5_AXI_GEN_AWADDR         : in  std_logic_vector(C_S5_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S5_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S5_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S5_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S5_AXI_GEN_AWLOCK         : in  std_logic;
    S5_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S5_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S5_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S5_AXI_GEN_AWVALID        : in  std_logic;
    S5_AXI_GEN_AWREADY        : out std_logic;
    S5_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S5_AXI_GEN_WDATA          : in  std_logic_vector(C_S5_AXI_GEN_DATA_WIDTH-1 downto 0);
    S5_AXI_GEN_WSTRB          : in  std_logic_vector((C_S5_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S5_AXI_GEN_WLAST          : in  std_logic;
    S5_AXI_GEN_WVALID         : in  std_logic;
    S5_AXI_GEN_WREADY         : out std_logic;
    
    S5_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S5_AXI_GEN_BID            : out std_logic_vector(C_S5_AXI_GEN_ID_WIDTH-1 downto 0);
    S5_AXI_GEN_BVALID         : out std_logic;
    S5_AXI_GEN_BREADY         : in  std_logic;
    
    S5_AXI_GEN_ARID           : in  std_logic_vector(C_S5_AXI_GEN_ID_WIDTH-1 downto 0);
    S5_AXI_GEN_ARADDR         : in  std_logic_vector(C_S5_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S5_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S5_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S5_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S5_AXI_GEN_ARLOCK         : in  std_logic;
    S5_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S5_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S5_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S5_AXI_GEN_ARVALID        : in  std_logic;
    S5_AXI_GEN_ARREADY        : out std_logic;
    S5_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S5_AXI_GEN_RID            : out std_logic_vector(C_S5_AXI_GEN_ID_WIDTH-1 downto 0);
    S5_AXI_GEN_RDATA          : out std_logic_vector(C_S5_AXI_GEN_DATA_WIDTH-1 downto 0);
    S5_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S5_AXI_GEN_RLAST          : out std_logic;
    S5_AXI_GEN_RVALID         : out std_logic;
    S5_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #6 Slave Signals.
    
    S6_AXI_GEN_AWID           : in  std_logic_vector(C_S6_AXI_GEN_ID_WIDTH-1 downto 0);
    S6_AXI_GEN_AWADDR         : in  std_logic_vector(C_S6_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S6_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S6_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S6_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S6_AXI_GEN_AWLOCK         : in  std_logic;
    S6_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S6_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S6_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S6_AXI_GEN_AWVALID        : in  std_logic;
    S6_AXI_GEN_AWREADY        : out std_logic;
    S6_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S6_AXI_GEN_WDATA          : in  std_logic_vector(C_S6_AXI_GEN_DATA_WIDTH-1 downto 0);
    S6_AXI_GEN_WSTRB          : in  std_logic_vector((C_S6_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S6_AXI_GEN_WLAST          : in  std_logic;
    S6_AXI_GEN_WVALID         : in  std_logic;
    S6_AXI_GEN_WREADY         : out std_logic;
    
    S6_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S6_AXI_GEN_BID            : out std_logic_vector(C_S6_AXI_GEN_ID_WIDTH-1 downto 0);
    S6_AXI_GEN_BVALID         : out std_logic;
    S6_AXI_GEN_BREADY         : in  std_logic;
    
    S6_AXI_GEN_ARID           : in  std_logic_vector(C_S6_AXI_GEN_ID_WIDTH-1 downto 0);
    S6_AXI_GEN_ARADDR         : in  std_logic_vector(C_S6_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S6_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S6_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S6_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S6_AXI_GEN_ARLOCK         : in  std_logic;
    S6_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S6_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S6_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S6_AXI_GEN_ARVALID        : in  std_logic;
    S6_AXI_GEN_ARREADY        : out std_logic;
    S6_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S6_AXI_GEN_RID            : out std_logic_vector(C_S6_AXI_GEN_ID_WIDTH-1 downto 0);
    S6_AXI_GEN_RDATA          : out std_logic_vector(C_S6_AXI_GEN_DATA_WIDTH-1 downto 0);
    S6_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S6_AXI_GEN_RLAST          : out std_logic;
    S6_AXI_GEN_RVALID         : out std_logic;
    S6_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #7 Slave Signals.
    
    S7_AXI_GEN_AWID           : in  std_logic_vector(C_S7_AXI_GEN_ID_WIDTH-1 downto 0);
    S7_AXI_GEN_AWADDR         : in  std_logic_vector(C_S7_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S7_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S7_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S7_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S7_AXI_GEN_AWLOCK         : in  std_logic;
    S7_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S7_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S7_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S7_AXI_GEN_AWVALID        : in  std_logic;
    S7_AXI_GEN_AWREADY        : out std_logic;
    S7_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S7_AXI_GEN_WDATA          : in  std_logic_vector(C_S7_AXI_GEN_DATA_WIDTH-1 downto 0);
    S7_AXI_GEN_WSTRB          : in  std_logic_vector((C_S7_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S7_AXI_GEN_WLAST          : in  std_logic;
    S7_AXI_GEN_WVALID         : in  std_logic;
    S7_AXI_GEN_WREADY         : out std_logic;
    
    S7_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S7_AXI_GEN_BID            : out std_logic_vector(C_S7_AXI_GEN_ID_WIDTH-1 downto 0);
    S7_AXI_GEN_BVALID         : out std_logic;
    S7_AXI_GEN_BREADY         : in  std_logic;
    
    S7_AXI_GEN_ARID           : in  std_logic_vector(C_S7_AXI_GEN_ID_WIDTH-1 downto 0);
    S7_AXI_GEN_ARADDR         : in  std_logic_vector(C_S7_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S7_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S7_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S7_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S7_AXI_GEN_ARLOCK         : in  std_logic;
    S7_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S7_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S7_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S7_AXI_GEN_ARVALID        : in  std_logic;
    S7_AXI_GEN_ARREADY        : out std_logic;
    S7_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S7_AXI_GEN_RID            : out std_logic_vector(C_S7_AXI_GEN_ID_WIDTH-1 downto 0);
    S7_AXI_GEN_RDATA          : out std_logic_vector(C_S7_AXI_GEN_DATA_WIDTH-1 downto 0);
    S7_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S7_AXI_GEN_RLAST          : out std_logic;
    S7_AXI_GEN_RVALID         : out std_logic;
    S7_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #8 Slave Signals.
    
    S8_AXI_GEN_AWID           : in  std_logic_vector(C_S8_AXI_GEN_ID_WIDTH-1 downto 0);
    S8_AXI_GEN_AWADDR         : in  std_logic_vector(C_S8_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S8_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S8_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S8_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S8_AXI_GEN_AWLOCK         : in  std_logic;
    S8_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S8_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S8_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S8_AXI_GEN_AWVALID        : in  std_logic;
    S8_AXI_GEN_AWREADY        : out std_logic;
    S8_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S8_AXI_GEN_WDATA          : in  std_logic_vector(C_S8_AXI_GEN_DATA_WIDTH-1 downto 0);
    S8_AXI_GEN_WSTRB          : in  std_logic_vector((C_S8_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S8_AXI_GEN_WLAST          : in  std_logic;
    S8_AXI_GEN_WVALID         : in  std_logic;
    S8_AXI_GEN_WREADY         : out std_logic;
    
    S8_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S8_AXI_GEN_BID            : out std_logic_vector(C_S8_AXI_GEN_ID_WIDTH-1 downto 0);
    S8_AXI_GEN_BVALID         : out std_logic;
    S8_AXI_GEN_BREADY         : in  std_logic;
    
    S8_AXI_GEN_ARID           : in  std_logic_vector(C_S8_AXI_GEN_ID_WIDTH-1 downto 0);
    S8_AXI_GEN_ARADDR         : in  std_logic_vector(C_S8_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S8_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S8_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S8_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S8_AXI_GEN_ARLOCK         : in  std_logic;
    S8_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S8_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S8_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S8_AXI_GEN_ARVALID        : in  std_logic;
    S8_AXI_GEN_ARREADY        : out std_logic;
    S8_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S8_AXI_GEN_RID            : out std_logic_vector(C_S8_AXI_GEN_ID_WIDTH-1 downto 0);
    S8_AXI_GEN_RDATA          : out std_logic_vector(C_S8_AXI_GEN_DATA_WIDTH-1 downto 0);
    S8_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S8_AXI_GEN_RLAST          : out std_logic;
    S8_AXI_GEN_RVALID         : out std_logic;
    S8_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #9 Slave Signals.
    
    S9_AXI_GEN_AWID           : in  std_logic_vector(C_S9_AXI_GEN_ID_WIDTH-1 downto 0);
    S9_AXI_GEN_AWADDR         : in  std_logic_vector(C_S9_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S9_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S9_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S9_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S9_AXI_GEN_AWLOCK         : in  std_logic;
    S9_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S9_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S9_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S9_AXI_GEN_AWVALID        : in  std_logic;
    S9_AXI_GEN_AWREADY        : out std_logic;
    S9_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S9_AXI_GEN_WDATA          : in  std_logic_vector(C_S9_AXI_GEN_DATA_WIDTH-1 downto 0);
    S9_AXI_GEN_WSTRB          : in  std_logic_vector((C_S9_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S9_AXI_GEN_WLAST          : in  std_logic;
    S9_AXI_GEN_WVALID         : in  std_logic;
    S9_AXI_GEN_WREADY         : out std_logic;
    
    S9_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S9_AXI_GEN_BID            : out std_logic_vector(C_S9_AXI_GEN_ID_WIDTH-1 downto 0);
    S9_AXI_GEN_BVALID         : out std_logic;
    S9_AXI_GEN_BREADY         : in  std_logic;
    
    S9_AXI_GEN_ARID           : in  std_logic_vector(C_S9_AXI_GEN_ID_WIDTH-1 downto 0);
    S9_AXI_GEN_ARADDR         : in  std_logic_vector(C_S9_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S9_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S9_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S9_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S9_AXI_GEN_ARLOCK         : in  std_logic;
    S9_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S9_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S9_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S9_AXI_GEN_ARVALID        : in  std_logic;
    S9_AXI_GEN_ARREADY        : out std_logic;
    S9_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S9_AXI_GEN_RID            : out std_logic_vector(C_S9_AXI_GEN_ID_WIDTH-1 downto 0);
    S9_AXI_GEN_RDATA          : out std_logic_vector(C_S9_AXI_GEN_DATA_WIDTH-1 downto 0);
    S9_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S9_AXI_GEN_RLAST          : out std_logic;
    S9_AXI_GEN_RVALID         : out std_logic;
    S9_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #10 Slave Signals.
    
    S10_AXI_GEN_AWID           : in  std_logic_vector(C_S10_AXI_GEN_ID_WIDTH-1 downto 0);
    S10_AXI_GEN_AWADDR         : in  std_logic_vector(C_S10_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S10_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S10_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S10_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S10_AXI_GEN_AWLOCK         : in  std_logic;
    S10_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S10_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S10_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S10_AXI_GEN_AWVALID        : in  std_logic;
    S10_AXI_GEN_AWREADY        : out std_logic;
    S10_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S10_AXI_GEN_WDATA          : in  std_logic_vector(C_S10_AXI_GEN_DATA_WIDTH-1 downto 0);
    S10_AXI_GEN_WSTRB          : in  std_logic_vector((C_S10_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S10_AXI_GEN_WLAST          : in  std_logic;
    S10_AXI_GEN_WVALID         : in  std_logic;
    S10_AXI_GEN_WREADY         : out std_logic;
    
    S10_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S10_AXI_GEN_BID            : out std_logic_vector(C_S10_AXI_GEN_ID_WIDTH-1 downto 0);
    S10_AXI_GEN_BVALID         : out std_logic;
    S10_AXI_GEN_BREADY         : in  std_logic;
    
    S10_AXI_GEN_ARID           : in  std_logic_vector(C_S10_AXI_GEN_ID_WIDTH-1 downto 0);
    S10_AXI_GEN_ARADDR         : in  std_logic_vector(C_S10_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S10_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S10_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S10_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S10_AXI_GEN_ARLOCK         : in  std_logic;
    S10_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S10_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S10_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S10_AXI_GEN_ARVALID        : in  std_logic;
    S10_AXI_GEN_ARREADY        : out std_logic;
    S10_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S10_AXI_GEN_RID            : out std_logic_vector(C_S10_AXI_GEN_ID_WIDTH-1 downto 0);
    S10_AXI_GEN_RDATA          : out std_logic_vector(C_S10_AXI_GEN_DATA_WIDTH-1 downto 0);
    S10_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S10_AXI_GEN_RLAST          : out std_logic;
    S10_AXI_GEN_RVALID         : out std_logic;
    S10_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #11 Slave Signals.
    
    S11_AXI_GEN_AWID           : in  std_logic_vector(C_S11_AXI_GEN_ID_WIDTH-1 downto 0);
    S11_AXI_GEN_AWADDR         : in  std_logic_vector(C_S11_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S11_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S11_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S11_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S11_AXI_GEN_AWLOCK         : in  std_logic;
    S11_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S11_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S11_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S11_AXI_GEN_AWVALID        : in  std_logic;
    S11_AXI_GEN_AWREADY        : out std_logic;
    S11_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S11_AXI_GEN_WDATA          : in  std_logic_vector(C_S11_AXI_GEN_DATA_WIDTH-1 downto 0);
    S11_AXI_GEN_WSTRB          : in  std_logic_vector((C_S11_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S11_AXI_GEN_WLAST          : in  std_logic;
    S11_AXI_GEN_WVALID         : in  std_logic;
    S11_AXI_GEN_WREADY         : out std_logic;
    
    S11_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S11_AXI_GEN_BID            : out std_logic_vector(C_S11_AXI_GEN_ID_WIDTH-1 downto 0);
    S11_AXI_GEN_BVALID         : out std_logic;
    S11_AXI_GEN_BREADY         : in  std_logic;
    
    S11_AXI_GEN_ARID           : in  std_logic_vector(C_S11_AXI_GEN_ID_WIDTH-1 downto 0);
    S11_AXI_GEN_ARADDR         : in  std_logic_vector(C_S11_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S11_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S11_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S11_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S11_AXI_GEN_ARLOCK         : in  std_logic;
    S11_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S11_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S11_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S11_AXI_GEN_ARVALID        : in  std_logic;
    S11_AXI_GEN_ARREADY        : out std_logic;
    S11_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S11_AXI_GEN_RID            : out std_logic_vector(C_S11_AXI_GEN_ID_WIDTH-1 downto 0);
    S11_AXI_GEN_RDATA          : out std_logic_vector(C_S11_AXI_GEN_DATA_WIDTH-1 downto 0);
    S11_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S11_AXI_GEN_RLAST          : out std_logic;
    S11_AXI_GEN_RVALID         : out std_logic;
    S11_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #12 Slave Signals.
    
    S12_AXI_GEN_AWID           : in  std_logic_vector(C_S12_AXI_GEN_ID_WIDTH-1 downto 0);
    S12_AXI_GEN_AWADDR         : in  std_logic_vector(C_S12_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S12_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S12_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S12_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S12_AXI_GEN_AWLOCK         : in  std_logic;
    S12_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S12_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S12_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S12_AXI_GEN_AWVALID        : in  std_logic;
    S12_AXI_GEN_AWREADY        : out std_logic;
    S12_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S12_AXI_GEN_WDATA          : in  std_logic_vector(C_S12_AXI_GEN_DATA_WIDTH-1 downto 0);
    S12_AXI_GEN_WSTRB          : in  std_logic_vector((C_S12_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S12_AXI_GEN_WLAST          : in  std_logic;
    S12_AXI_GEN_WVALID         : in  std_logic;
    S12_AXI_GEN_WREADY         : out std_logic;
    
    S12_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S12_AXI_GEN_BID            : out std_logic_vector(C_S12_AXI_GEN_ID_WIDTH-1 downto 0);
    S12_AXI_GEN_BVALID         : out std_logic;
    S12_AXI_GEN_BREADY         : in  std_logic;
    
    S12_AXI_GEN_ARID           : in  std_logic_vector(C_S12_AXI_GEN_ID_WIDTH-1 downto 0);
    S12_AXI_GEN_ARADDR         : in  std_logic_vector(C_S12_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S12_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S12_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S12_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S12_AXI_GEN_ARLOCK         : in  std_logic;
    S12_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S12_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S12_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S12_AXI_GEN_ARVALID        : in  std_logic;
    S12_AXI_GEN_ARREADY        : out std_logic;
    S12_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S12_AXI_GEN_RID            : out std_logic_vector(C_S12_AXI_GEN_ID_WIDTH-1 downto 0);
    S12_AXI_GEN_RDATA          : out std_logic_vector(C_S12_AXI_GEN_DATA_WIDTH-1 downto 0);
    S12_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S12_AXI_GEN_RLAST          : out std_logic;
    S12_AXI_GEN_RVALID         : out std_logic;
    S12_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #13 Slave Signals.
    
    S13_AXI_GEN_AWID           : in  std_logic_vector(C_S13_AXI_GEN_ID_WIDTH-1 downto 0);
    S13_AXI_GEN_AWADDR         : in  std_logic_vector(C_S13_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S13_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S13_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S13_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S13_AXI_GEN_AWLOCK         : in  std_logic;
    S13_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S13_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S13_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S13_AXI_GEN_AWVALID        : in  std_logic;
    S13_AXI_GEN_AWREADY        : out std_logic;
    S13_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S13_AXI_GEN_WDATA          : in  std_logic_vector(C_S13_AXI_GEN_DATA_WIDTH-1 downto 0);
    S13_AXI_GEN_WSTRB          : in  std_logic_vector((C_S13_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S13_AXI_GEN_WLAST          : in  std_logic;
    S13_AXI_GEN_WVALID         : in  std_logic;
    S13_AXI_GEN_WREADY         : out std_logic;
    
    S13_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S13_AXI_GEN_BID            : out std_logic_vector(C_S13_AXI_GEN_ID_WIDTH-1 downto 0);
    S13_AXI_GEN_BVALID         : out std_logic;
    S13_AXI_GEN_BREADY         : in  std_logic;
    
    S13_AXI_GEN_ARID           : in  std_logic_vector(C_S13_AXI_GEN_ID_WIDTH-1 downto 0);
    S13_AXI_GEN_ARADDR         : in  std_logic_vector(C_S13_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S13_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S13_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S13_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S13_AXI_GEN_ARLOCK         : in  std_logic;
    S13_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S13_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S13_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S13_AXI_GEN_ARVALID        : in  std_logic;
    S13_AXI_GEN_ARREADY        : out std_logic;
    S13_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S13_AXI_GEN_RID            : out std_logic_vector(C_S13_AXI_GEN_ID_WIDTH-1 downto 0);
    S13_AXI_GEN_RDATA          : out std_logic_vector(C_S13_AXI_GEN_DATA_WIDTH-1 downto 0);
    S13_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S13_AXI_GEN_RLAST          : out std_logic;
    S13_AXI_GEN_RVALID         : out std_logic;
    S13_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #14 Slave Signals.
    
    S14_AXI_GEN_AWID           : in  std_logic_vector(C_S14_AXI_GEN_ID_WIDTH-1 downto 0);
    S14_AXI_GEN_AWADDR         : in  std_logic_vector(C_S14_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S14_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S14_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S14_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S14_AXI_GEN_AWLOCK         : in  std_logic;
    S14_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S14_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S14_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S14_AXI_GEN_AWVALID        : in  std_logic;
    S14_AXI_GEN_AWREADY        : out std_logic;
    S14_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S14_AXI_GEN_WDATA          : in  std_logic_vector(C_S14_AXI_GEN_DATA_WIDTH-1 downto 0);
    S14_AXI_GEN_WSTRB          : in  std_logic_vector((C_S14_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S14_AXI_GEN_WLAST          : in  std_logic;
    S14_AXI_GEN_WVALID         : in  std_logic;
    S14_AXI_GEN_WREADY         : out std_logic;
    
    S14_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S14_AXI_GEN_BID            : out std_logic_vector(C_S14_AXI_GEN_ID_WIDTH-1 downto 0);
    S14_AXI_GEN_BVALID         : out std_logic;
    S14_AXI_GEN_BREADY         : in  std_logic;
    
    S14_AXI_GEN_ARID           : in  std_logic_vector(C_S14_AXI_GEN_ID_WIDTH-1 downto 0);
    S14_AXI_GEN_ARADDR         : in  std_logic_vector(C_S14_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S14_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S14_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S14_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S14_AXI_GEN_ARLOCK         : in  std_logic;
    S14_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S14_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S14_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S14_AXI_GEN_ARVALID        : in  std_logic;
    S14_AXI_GEN_ARREADY        : out std_logic;
    S14_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S14_AXI_GEN_RID            : out std_logic_vector(C_S14_AXI_GEN_ID_WIDTH-1 downto 0);
    S14_AXI_GEN_RDATA          : out std_logic_vector(C_S14_AXI_GEN_DATA_WIDTH-1 downto 0);
    S14_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S14_AXI_GEN_RLAST          : out std_logic;
    S14_AXI_GEN_RVALID         : out std_logic;
    S14_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Generic AXI4/ACE Interface #15 Slave Signals.
    
    S15_AXI_GEN_AWID           : in  std_logic_vector(C_S15_AXI_GEN_ID_WIDTH-1 downto 0);
    S15_AXI_GEN_AWADDR         : in  std_logic_vector(C_S15_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S15_AXI_GEN_AWLEN          : in  std_logic_vector(7 downto 0);
    S15_AXI_GEN_AWSIZE         : in  std_logic_vector(2 downto 0);
    S15_AXI_GEN_AWBURST        : in  std_logic_vector(1 downto 0);
    S15_AXI_GEN_AWLOCK         : in  std_logic;
    S15_AXI_GEN_AWCACHE        : in  std_logic_vector(3 downto 0);
    S15_AXI_GEN_AWPROT         : in  std_logic_vector(2 downto 0);
    S15_AXI_GEN_AWQOS          : in  std_logic_vector(3 downto 0);
    S15_AXI_GEN_AWVALID        : in  std_logic;
    S15_AXI_GEN_AWREADY        : out std_logic;
    S15_AXI_GEN_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S15_AXI_GEN_WDATA          : in  std_logic_vector(C_S15_AXI_GEN_DATA_WIDTH-1 downto 0);
    S15_AXI_GEN_WSTRB          : in  std_logic_vector((C_S15_AXI_GEN_DATA_WIDTH/8)-1 downto 0);
    S15_AXI_GEN_WLAST          : in  std_logic;
    S15_AXI_GEN_WVALID         : in  std_logic;
    S15_AXI_GEN_WREADY         : out std_logic;
    
    S15_AXI_GEN_BRESP          : out std_logic_vector(1 downto 0);
    S15_AXI_GEN_BID            : out std_logic_vector(C_S15_AXI_GEN_ID_WIDTH-1 downto 0);
    S15_AXI_GEN_BVALID         : out std_logic;
    S15_AXI_GEN_BREADY         : in  std_logic;
    
    S15_AXI_GEN_ARID           : in  std_logic_vector(C_S15_AXI_GEN_ID_WIDTH-1 downto 0);
    S15_AXI_GEN_ARADDR         : in  std_logic_vector(C_S15_AXI_GEN_ADDR_WIDTH-1 downto 0);
    S15_AXI_GEN_ARLEN          : in  std_logic_vector(7 downto 0);
    S15_AXI_GEN_ARSIZE         : in  std_logic_vector(2 downto 0);
    S15_AXI_GEN_ARBURST        : in  std_logic_vector(1 downto 0);
    S15_AXI_GEN_ARLOCK         : in  std_logic;
    S15_AXI_GEN_ARCACHE        : in  std_logic_vector(3 downto 0);
    S15_AXI_GEN_ARPROT         : in  std_logic_vector(2 downto 0);
    S15_AXI_GEN_ARQOS          : in  std_logic_vector(3 downto 0);
    S15_AXI_GEN_ARVALID        : in  std_logic;
    S15_AXI_GEN_ARREADY        : out std_logic;
    S15_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    S15_AXI_GEN_RID            : out std_logic_vector(C_S15_AXI_GEN_ID_WIDTH-1 downto 0);
    S15_AXI_GEN_RDATA          : out std_logic_vector(C_S15_AXI_GEN_DATA_WIDTH-1 downto 0);
    S15_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S15_AXI_GEN_RLAST          : out std_logic;
    S15_AXI_GEN_RVALID         : out std_logic;
    S15_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Control If Transactions.
    
    ctrl_init_done            : in  std_logic;
    ctrl_access               : in  ARBITRATION_TYPE;
    ctrl_ready                : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Lookup signals.
    
    lookup_piperun            : in  std_logic;
    
    lookup_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    lookup_read_done          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Update signals.
    
    update_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Update signals (to Port).
    
    -- Write miss response
    update_ext_bresp_valid    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
    update_ext_bresp_ready    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (Read Data).
    
    lookup_read_data_valid    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    lookup_read_data_last     : in  std_logic;
    lookup_read_data_resp     : in  AXI_RRESP_TYPE;
    lookup_read_data_set      : in  natural range 0 to C_NUM_PARALLEL_SETS - 1;
    lookup_read_data_word     : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
    lookup_read_data_ready    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Update signals (Read Data).
    
    update_read_data_valid    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    update_read_data_last     : in  std_logic;
    update_read_data_resp     : in  AXI_RRESP_TYPE;
    update_read_data_word     : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    update_read_data_ready    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Access signals (to Lookup/Update).
    
    access_valid              : out std_logic;
    access_info               : out ACCESS_TYPE;
    access_use                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    access_stp                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    access_id                 : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
    
    access_data_valid         : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_data_last          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_data_be            : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
    access_data_word          : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read request).
    
    lookup_read_data_new      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    lookup_read_data_hit      : in  std_logic;
    lookup_read_data_snoop    : in  std_logic;
    lookup_read_data_allocate : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read Data).
    
    read_info_almost_full     : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_info_full            : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_data_hit_pop         : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_data_hit_almost_full : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_data_hit_full        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_data_hit_fit         : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    read_data_miss_full       : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                      : in  std_logic;
    stat_enable                     : in  std_logic;
    
    -- Optimized ports.
    stat_s_axi_rd_segments          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_wr_segments          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_rip                  : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_r                    : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_bip                  : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_bp                   : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wip                  : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_w                    : out STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_rd_latency           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wr_latency           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_rd_latency_conf      : in  STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wr_latency_conf      : in  STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);

    -- Generic ports.
    stat_s_axi_gen_rd_segments      : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_gen_wr_segments      : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_gen_rip              : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_r                : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_bip              : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_bp               : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wip              : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_w                : out STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_rd_latency       : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wr_latency       : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_rd_latency_conf  : in  STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wr_latency_conf  : in  STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    
    -- Arbiter
    stat_arb_valid                  : out STAT_POINT_TYPE;    -- Time valid transactions exist
    stat_arb_concurrent_accesses    : out STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
    stat_arb_opt_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
    stat_arb_gen_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                              -- Time valid read is blocked by prohibit
    
    -- Access
    stat_access_valid               : out STAT_POINT_TYPE;    -- Time valid per transaction
    stat_access_stall               : out STAT_POINT_TYPE;    -- Time stalled per transaction
    stat_access_fetch_stall         : out STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
    stat_access_req_stall           : out STAT_POINT_TYPE;    -- Time stalled per transaction (req)
    stat_access_act_stall           : out STAT_POINT_TYPE;    -- Time stalled per transaction (act)
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug signals.
    
    OPT_IF0_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF1_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF2_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF3_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF4_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF5_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF6_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF7_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF8_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF9_DEBUG             : out std_logic_vector(255 downto 0);
    OPT_IF10_DEBUG            : out std_logic_vector(255 downto 0);
    OPT_IF11_DEBUG            : out std_logic_vector(255 downto 0);
    OPT_IF12_DEBUG            : out std_logic_vector(255 downto 0);
    OPT_IF13_DEBUG            : out std_logic_vector(255 downto 0);
    OPT_IF14_DEBUG            : out std_logic_vector(255 downto 0);
    OPT_IF15_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF0_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF1_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF2_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF3_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF4_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF5_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF6_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF7_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF8_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF9_DEBUG             : out std_logic_vector(255 downto 0);
    GEN_IF10_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF11_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF12_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF13_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF14_DEBUG            : out std_logic_vector(255 downto 0);
    GEN_IF15_DEBUG            : out std_logic_vector(255 downto 0);
    ARBITER_DEBUG             : out std_logic_vector(255 downto 0);
    ACCESS_DEBUG              : out std_logic_vector(255 downto 0)
  );
end entity sc_front_end;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_front_end is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- This module instantiates all AXI/ACE slave connections, both for the
  -- Optimized and Generiric ports.
  -- All slave port signals are vecotized and feed to the Arbiter where the 
  -- next transaction is selected.
  -- After that are the selected transaction forward to the Access module,
  -- where preprocessing takes place before anything is forwarded to the Cache
  -- Core.
  -- 
  --  ______________ 
  -- | Optimized  0 |
  -- |______________|\
  --  ______________  \        _____________    ______________
  -- | Optimized  1 |--++--+->| Arbiter     |->| Access       |->
  -- |______________|  /  /   |_____________|  |______________|
  --  ______________  /  /
  -- | Optimized  . |/  /
  -- |______________|  /
  --  ______________  /
  -- | Generic    0 |/
  -- |______________|
  -- 
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_PORT_0_ERROR              : natural :=  0;
  constant C_ASSERT_PORT_1_ERROR              : natural :=  1;
  constant C_ASSERT_PORT_2_ERROR              : natural :=  2;
  constant C_ASSERT_PORT_3_ERROR              : natural :=  3;
  constant C_ASSERT_PORT_4_ERROR              : natural :=  4;
  constant C_ASSERT_PORT_5_ERROR              : natural :=  5;
  constant C_ASSERT_PORT_6_ERROR              : natural :=  6;
  constant C_ASSERT_PORT_7_ERROR              : natural :=  7;
  constant C_ASSERT_PORT_8_ERROR              : natural :=  8;
  constant C_ASSERT_PORT_9_ERROR              : natural :=  9;
  constant C_ASSERT_PORT_10_ERROR             : natural := 10;
  constant C_ASSERT_PORT_11_ERROR             : natural := 11;
  constant C_ASSERT_PORT_12_ERROR             : natural := 12;
  constant C_ASSERT_PORT_13_ERROR             : natural := 13;
  constant C_ASSERT_PORT_14_ERROR             : natural := 14;
  constant C_ASSERT_PORT_15_ERROR             : natural := 15;
  constant C_ASSERT_PORT_16_ERROR             : natural := 16;
  constant C_ASSERT_PORT_17_ERROR             : natural := 17;
  constant C_ASSERT_PORT_18_ERROR             : natural := 18;
  constant C_ASSERT_PORT_19_ERROR             : natural := 19;
  constant C_ASSERT_PORT_20_ERROR             : natural := 20;
  constant C_ASSERT_PORT_21_ERROR             : natural := 21;
  constant C_ASSERT_PORT_22_ERROR             : natural := 22;
  constant C_ASSERT_PORT_23_ERROR             : natural := 23;
  constant C_ASSERT_PORT_24_ERROR             : natural := 24;
  constant C_ASSERT_PORT_25_ERROR             : natural := 25;
  constant C_ASSERT_PORT_26_ERROR             : natural := 26;
  constant C_ASSERT_PORT_27_ERROR             : natural := 27;
  constant C_ASSERT_PORT_28_ERROR             : natural := 28;
  constant C_ASSERT_PORT_29_ERROR             : natural := 29;
  constant C_ASSERT_PORT_30_ERROR             : natural := 30;
  constant C_ASSERT_PORT_31_ERROR             : natural := 31;
  constant C_ASSERT_ARBITER_ERROR             : natural := 32;
  constant C_ASSERT_ACCESS_ERROR              : natural := 33;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural := 34;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_NUM_FAST_PORTS           : natural range 0 to 16 := C_NUM_GENERIC_PORTS;
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types 
  -----------------------------------------------------------------------------
  
  -- Address related.
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI   downto C_ADDR_INTERNAL_LO;
  subtype C_ADDR_DIRECT_POS           is natural range C_ADDR_DIRECT_HI     downto C_ADDR_DIRECT_LO;
  subtype C_ADDR_LINE_POS             is natural range C_ADDR_LINE_HI       downto C_ADDR_LINE_LO;
  subtype C_ADDR_OFFSET_POS           is natural range C_ADDR_OFFSET_HI     downto C_ADDR_OFFSET_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  
  -- Subtypes for address parts.
  subtype ADDR_INTERNAL_TYPE          is std_logic_vector(C_ADDR_INTERNAL_POS);
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  -- Subtype for ID.
  subtype ID_TYPE                     is std_logic_vector(C_ID_WIDTH - 1 downto 0);
  type ID_PORTS_TYPE                  is array(natural range <>) of ID_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_s_axi_opt_interface is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_OPT_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_OPT_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- AXI4 Interface Specific.
      C_S_AXI_BASEADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
      C_S_AXI_HIGHADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
      C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_S_AXI_ADDR_WIDTH        : natural                       := 32;
      C_S_AXI_ID_WIDTH          : natural                       :=  4;
      C_S_AXI_SUPPORT_UNIQUE    : natural range  0 to    1      :=  1;
      C_S_AXI_SUPPORT_DIRTY     : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
      
      -- Data type and settings specific.
      C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
      C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
      C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
      C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
      C_Lx_ADDR_REQ_HI          : natural range  2 to   63      := 27;
      C_Lx_ADDR_REQ_LO          : natural range  2 to   63      :=  7;
      C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
      C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
      C_Lx_ADDR_DATA_HI         : natural range  2 to   63      := 14;
      C_Lx_ADDR_DATA_LO         : natural range  2 to   63      :=  2;
      C_Lx_ADDR_TAG_HI          : natural range  4 to   63      := 27;
      C_Lx_ADDR_TAG_LO          : natural range  4 to   63      := 14;
      C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
      C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
      C_Lx_ADDR_OFFSET_HI       : natural range  2 to   63      :=  6;
      C_Lx_ADDR_OFFSET_LO       : natural range  0 to   63      :=  0;
      C_Lx_ADDR_WORD_HI         : natural range  2 to   63      :=  6;
      C_Lx_ADDR_WORD_LO         : natural range  2 to   63      :=  2;
      C_Lx_ADDR_BYTE_HI         : natural range  0 to   63      :=  1;
      C_Lx_ADDR_BYTE_LO         : natural range  0 to   63      :=  0;
      
      -- L1 Cache Specific.
      C_Lx_CACHE_SIZE           : natural                       := 1024;
      C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
      C_Lx_NUM_ADDR_TAG_BITS    : natural range  1 to   63      :=  8;

      -- PARD Specific.
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
      
      -- System Cache Specific.
      C_PIPELINE_LU_READ_DATA   : boolean                       := false;
      C_ID_WIDTH                : natural range  1 to   32      :=  4;
      C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_PORT_NUM                : natural range  0 to   31      :=  0;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
  
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- AW-Channel
      S_AXI_AWID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_AWADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWLEN               : in  std_logic_vector(7 downto 0);
      S_AXI_AWSIZE              : in  std_logic_vector(2 downto 0);
      S_AXI_AWBURST             : in  std_logic_vector(1 downto 0);
      S_AXI_AWLOCK              : in  std_logic;
      S_AXI_AWCACHE             : in  std_logic_vector(3 downto 0);
      S_AXI_AWPROT              : in  std_logic_vector(2 downto 0);
      S_AXI_AWQOS               : in  std_logic_vector(3 downto 0);
      S_AXI_AWVALID             : in  std_logic;
      S_AXI_AWREADY             : out std_logic;
      S_AXI_AWDOMAIN            : in  std_logic_vector(1 downto 0);                      -- For ACE
      S_AXI_AWSNOOP             : in  std_logic_vector(2 downto 0);                      -- For ACE
      S_AXI_AWBAR               : in  std_logic_vector(1 downto 0);                      -- For ACE
      S_AXI_AWUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
  
      -- W-Channel
      S_AXI_WDATA               : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB               : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WLAST               : in  std_logic;
      S_AXI_WVALID              : in  std_logic;
      S_AXI_WREADY              : out std_logic;
  
      -- B-Channel
      S_AXI_BRESP               : out std_logic_vector(1 downto 0);
      S_AXI_BID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BVALID              : out std_logic;
      S_AXI_BREADY              : in  std_logic;
      S_AXI_WACK                : in  std_logic;                                         -- For ACE
  
      -- AR-Channel
      S_AXI_ARID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_ARADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARLEN               : in  std_logic_vector(7 downto 0);
      S_AXI_ARSIZE              : in  std_logic_vector(2 downto 0);
      S_AXI_ARBURST             : in  std_logic_vector(1 downto 0);
      S_AXI_ARLOCK              : in  std_logic;
      S_AXI_ARCACHE             : in  std_logic_vector(3 downto 0);
      S_AXI_ARPROT              : in  std_logic_vector(2 downto 0);
      S_AXI_ARQOS               : in  std_logic_vector(3 downto 0);
      S_AXI_ARVALID             : in  std_logic;
      S_AXI_ARREADY             : out std_logic;
      S_AXI_ARDOMAIN            : in  std_logic_vector(1 downto 0);                      -- For ACE
      S_AXI_ARSNOOP             : in  std_logic_vector(3 downto 0);                      -- For ACE
      S_AXI_ARBAR               : in  std_logic_vector(1 downto 0);                      -- For ACE
      S_AXI_ARUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
  
      -- R-Channel
      S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP               : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
      S_AXI_RLAST               : out std_logic;
      S_AXI_RVALID              : out std_logic;
      S_AXI_RREADY              : in  std_logic;
      S_AXI_RACK                : in  std_logic;                                         -- For ACE
  
      -- AC-Channel (coherency only)
      S_AXI_ACVALID             : out std_logic;                                         -- For ACE
      S_AXI_ACADDR              : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);   -- For ACE
      S_AXI_ACSNOOP             : out std_logic_vector(3 downto 0);                      -- For ACE
      S_AXI_ACPROT              : out std_logic_vector(2 downto 0);                      -- For ACE
      S_AXI_ACREADY             : in  std_logic;                                         -- For ACE
  
      -- CR-Channel (coherency only)
      S_AXI_CRVALID             : in  std_logic;                                         -- For ACE
      S_AXI_CRRESP              : in  std_logic_vector(4 downto 0);                      -- For ACE
      S_AXI_CRREADY             : out std_logic;                                         -- For ACE
  
      -- CD-Channel (coherency only)
      S_AXI_CDVALID             : in  std_logic;                                         -- For ACE
      S_AXI_CDDATA              : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);   -- For ACE
      S_AXI_CDLAST              : in  std_logic;                                         -- For ACE
      S_AXI_CDREADY             : out std_logic;                                         -- For ACE
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      arbiter_piperun           : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            : out WRITE_PORT_TYPE;
      wr_port_id                : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
      wr_port_ready             : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            : out READ_PORT_TYPE;
      rd_port_id                : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
      rd_port_ready             : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Snoop communication).
      
      snoop_fetch_piperun       : in  std_logic;
      snoop_fetch_valid         : in  std_logic;
      snoop_fetch_addr          : in  AXI_ADDR_TYPE;
      snoop_fetch_myself        : in  std_logic;
      snoop_fetch_sync          : in  std_logic;
      snoop_fetch_pos_hazard    : out std_logic;
      
      snoop_req_piperun         : in  std_logic;
      snoop_req_valid           : in  std_logic;
      snoop_req_write           : in  std_logic;
      snoop_req_size            : in  AXI_SIZE_TYPE;
      snoop_req_addr            : in  AXI_ADDR_TYPE;
      snoop_req_snoop           : in  AXI_SNOOP_TYPE;
      snoop_req_myself          : in  std_logic;
      snoop_req_always          : in  std_logic;
      snoop_req_update_filter   : in  std_logic;
      snoop_req_want            : in  std_logic;
      snoop_req_complete        : in  std_logic;
      snoop_req_complete_target : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_act_piperun         : in  std_logic;
      snoop_act_valid           : in  std_logic;
      snoop_act_waiting_4_pipe  : in  std_logic;
      snoop_act_write           : in  std_logic;
      snoop_act_addr            : in  AXI_ADDR_TYPE;
      snoop_act_prot            : in  AXI_PROT_TYPE;
      snoop_act_snoop           : in  AXI_SNOOP_TYPE;
      snoop_act_myself          : in  std_logic;
      snoop_act_always          : in  std_logic;
      snoop_act_tag_valid       : out std_logic;
      snoop_act_tag_unique      : out std_logic;
      snoop_act_tag_dirty       : out std_logic;
      snoop_act_done            : out std_logic;
      snoop_act_use_external    : out std_logic;
      snoop_act_write_blocking  : out std_logic;
      
      snoop_info_tag_valid      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_info_tag_unique     : out std_logic;
      snoop_info_tag_dirty      : out std_logic;
      
      snoop_resp_valid          : out std_logic;
      snoop_resp_crresp         : out AXI_CRRESP_TYPE;
      snoop_resp_ready          : in  std_logic;
      
      read_data_ex_rack         : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        : out std_logic;
      wr_port_data_last         : out std_logic;
      wr_port_data_be           : out std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      wr_port_data_word         : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      wr_port_data_ready        : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write response).
      
      access_bp_push            : in  std_logic;
      access_bp_early           : in  std_logic;
      
      update_ext_bresp_valid    : in  std_logic;
      update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      : in  std_logic;
      lookup_read_data_hit      : in  std_logic;
      lookup_read_data_snoop    : in  std_logic;
      lookup_read_data_allocate : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     : out std_logic;
      read_info_full            : out std_logic;
      read_data_hit_pop         : out std_logic;
      read_data_hit_almost_full : out std_logic;
      read_data_hit_full        : out std_logic;
      read_data_hit_fit         : out std_logic;
      read_data_miss_full       : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Snoop signals (Read Data & response).
      
      snoop_read_data_valid     : in  std_logic;
      snoop_read_data_last      : in  std_logic;
      snoop_read_data_resp      : in  AXI_RRESP_TYPE;
      snoop_read_data_word      : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      snoop_read_data_ready     : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Lookup signals (Read Data).
      
      lookup_read_data_valid    : in  std_logic;
      lookup_read_data_last     : in  std_logic;
      lookup_read_data_resp     : in  AXI_RRESP_TYPE;
      lookup_read_data_set      : in  natural range 0 to C_NUM_PARALLEL_SETS - 1;
      lookup_read_data_word     : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
      lookup_read_data_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Update signals (Read Data).
      
      update_read_data_valid    : in  std_logic;
      update_read_data_last     : in  std_logic;
      update_read_data_resp     : in  AXI_RRESP_TYPE;
      update_read_data_word     : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      update_read_data_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      : in  std_logic;
      stat_enable                     : in  std_logic;
      
      stat_s_axi_rd_segments          : out STAT_POINT_TYPE;
      stat_s_axi_wr_segments          : out STAT_POINT_TYPE;
      stat_s_axi_rip                  : out STAT_FIFO_TYPE;
      stat_s_axi_r                    : out STAT_FIFO_TYPE;
      stat_s_axi_bip                  : out STAT_FIFO_TYPE;
      stat_s_axi_bp                   : out STAT_FIFO_TYPE;
      stat_s_axi_wip                  : out STAT_FIFO_TYPE;
      stat_s_axi_w                    : out STAT_FIFO_TYPE;
      stat_s_axi_rd_latency           : out STAT_POINT_TYPE;
      stat_s_axi_wr_latency           : out STAT_POINT_TYPE;
      stat_s_axi_rd_latency_conf      : in  STAT_CONF_TYPE;
      stat_s_axi_wr_latency_conf      : in  STAT_CONF_TYPE;
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  : out std_logic_vector(255 downto 0)
    );
  end component sc_s_axi_opt_interface;
  
  component sc_s_axi_gen_interface is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_GEN_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_GEN_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- AXI4 Interface Specific.
      C_S_AXI_BASEADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
      C_S_AXI_HIGHADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
      C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_S_AXI_ADDR_WIDTH        : natural                       := 32;
      C_S_AXI_ID_WIDTH          : natural                       :=  4;
      C_S_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
      C_S_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
      C_S_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
      
      -- Data type and settings specific.
      C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
      C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
      C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
      C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
      C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
      C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
      
      -- Lx Cache Specific.
      C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
      C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
      C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
      C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
      C_Lx_ADDR_OFFSET_HI       : natural range  2 to   63      :=  6;
      C_Lx_ADDR_OFFSET_LO       : natural range  0 to   63      :=  0;
      C_Lx_ADDR_BYTE_HI         : natural range  0 to   63      :=  1;
      C_Lx_ADDR_BYTE_LO         : natural range  0 to   63      :=  0;
      C_Lx_CACHE_SIZE           : natural                       := 1024;
      C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
      
      -- PARD Specific.
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
      
      -- System Cache Specific.
      C_PIPELINE_LU_READ_DATA   : boolean                       := false;
      C_ID_WIDTH                : natural range  1 to   32      :=  4;
      C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_PORT_NUM                : natural range  0 to   31      :=  0;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
  
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- AW-Channel
      S_AXI_AWID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_AWADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_AWLEN               : in  std_logic_vector(7 downto 0);
      S_AXI_AWSIZE              : in  std_logic_vector(2 downto 0);
      S_AXI_AWBURST             : in  std_logic_vector(1 downto 0);
      S_AXI_AWLOCK              : in  std_logic;
      S_AXI_AWCACHE             : in  std_logic_vector(3 downto 0);
      S_AXI_AWPROT              : in  std_logic_vector(2 downto 0);
      S_AXI_AWQOS               : in  std_logic_vector(3 downto 0);
      S_AXI_AWVALID             : in  std_logic;
      S_AXI_AWREADY             : out std_logic;
      S_AXI_AWUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
  
      -- W-Channel
      S_AXI_WDATA               : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB               : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WLAST               : in  std_logic;
      S_AXI_WVALID              : in  std_logic;
      S_AXI_WREADY              : out std_logic;
  
      -- B-Channel
      S_AXI_BRESP               : out std_logic_vector(1 downto 0);
      S_AXI_BID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BVALID              : out std_logic;
      S_AXI_BREADY              : in  std_logic;
  
      -- AR-Channel
      S_AXI_ARID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_ARADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      S_AXI_ARLEN               : in  std_logic_vector(7 downto 0);
      S_AXI_ARSIZE              : in  std_logic_vector(2 downto 0);
      S_AXI_ARBURST             : in  std_logic_vector(1 downto 0);
      S_AXI_ARLOCK              : in  std_logic;
      S_AXI_ARCACHE             : in  std_logic_vector(3 downto 0);
      S_AXI_ARPROT              : in  std_logic_vector(2 downto 0);
      S_AXI_ARQOS               : in  std_logic_vector(3 downto 0);
      S_AXI_ARVALID             : in  std_logic;
      S_AXI_ARREADY             : out std_logic;
      S_AXI_ARUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
  
      -- R-Channel
      S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP               : out std_logic_vector(1 downto 0);
      S_AXI_RLAST               : out std_logic;
      S_AXI_RVALID              : out std_logic;
      S_AXI_RREADY              : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      arbiter_piperun           : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            : out WRITE_PORT_TYPE;
      wr_port_id                : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
      wr_port_ready             : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            : out READ_PORT_TYPE;
      rd_port_id                : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
      rd_port_ready             : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Snoop communication).
      
      snoop_fetch_piperun       : in  std_logic;
      snoop_fetch_valid         : in  std_logic;
      snoop_fetch_addr          : in  AXI_ADDR_TYPE;
      snoop_fetch_myself        : in  std_logic;
      snoop_fetch_sync          : in  std_logic;
      snoop_fetch_pos_hazard    : out std_logic;
      
      snoop_req_piperun         : in  std_logic;
      snoop_req_valid           : in  std_logic;
      snoop_req_write           : in  std_logic;
      snoop_req_size            : in  AXI_SIZE_TYPE;
      snoop_req_addr            : in  AXI_ADDR_TYPE;
      snoop_req_snoop           : in  AXI_SNOOP_TYPE;
      snoop_req_myself          : in  std_logic;
      snoop_req_always          : in  std_logic;
      snoop_req_update_filter   : in  std_logic;
      snoop_req_want            : in  std_logic;
      snoop_req_complete        : in  std_logic;
      snoop_req_complete_target : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_act_piperun         : in  std_logic;
      snoop_act_valid           : in  std_logic;
      snoop_act_waiting_4_pipe  : in  std_logic;
      snoop_act_write           : in  std_logic;
      snoop_act_addr            : in  AXI_ADDR_TYPE;
      snoop_act_prot            : in  AXI_PROT_TYPE;
      snoop_act_snoop           : in  AXI_SNOOP_TYPE;
      snoop_act_myself          : in  std_logic;
      snoop_act_always          : in  std_logic;
      snoop_act_tag_valid       : out std_logic;
      snoop_act_tag_unique      : out std_logic;
      snoop_act_tag_dirty       : out std_logic;
      snoop_act_done            : out std_logic;
      snoop_act_use_external    : out std_logic;
      snoop_act_write_blocking  : out std_logic;
      
      snoop_info_tag_valid      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_info_tag_unique     : out std_logic;
      snoop_info_tag_dirty      : out std_logic;
      
      snoop_resp_valid          : out std_logic;
      snoop_resp_crresp         : out AXI_CRRESP_TYPE;
      snoop_resp_ready          : in  std_logic;
      
      read_data_ex_rack         : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        : out std_logic;
      wr_port_data_last         : out std_logic;
      wr_port_data_be           : out std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      wr_port_data_word         : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      wr_port_data_ready        : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write response).
      
      access_bp_push            : in  std_logic;
      access_bp_early           : in  std_logic;
      
      update_ext_bresp_valid    : in  std_logic;
      update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      : in  std_logic;
      lookup_read_data_hit      : in  std_logic;
      lookup_read_data_snoop    : in  std_logic;
      lookup_read_data_allocate : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     : out std_logic;
      read_info_full            : out std_logic;
      read_data_hit_pop         : out std_logic;
      read_data_hit_almost_full : out std_logic;
      read_data_hit_full        : out std_logic;
      read_data_hit_fit         : out std_logic;
      read_data_miss_full       : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Snoop signals (Read Data & response).
      
      snoop_read_data_valid     : in  std_logic;
      snoop_read_data_last      : in  std_logic;
      snoop_read_data_resp      : in  AXI_RRESP_TYPE;
      snoop_read_data_word      : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      snoop_read_data_ready     : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Lookup signals (Read Data).
      
      lookup_read_data_valid    : in  std_logic;
      lookup_read_data_last     : in  std_logic;
      lookup_read_data_resp     : in  AXI_RRESP_TYPE;
      lookup_read_data_set      : in  natural range 0 to C_NUM_PARALLEL_SETS - 1;
      lookup_read_data_word     : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
      lookup_read_data_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Update signals (Read Data).
      
      update_read_data_valid    : in  std_logic;
      update_read_data_last     : in  std_logic;
      update_read_data_resp     : in  AXI_RRESP_TYPE;
      update_read_data_word     : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      update_read_data_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      : in  std_logic;
      stat_enable                     : in  std_logic;
      
      stat_s_axi_gen_rd_segments      : out STAT_POINT_TYPE; -- Per transaction
      stat_s_axi_gen_wr_segments      : out STAT_POINT_TYPE; -- Per transaction
      stat_s_axi_gen_rip              : out STAT_FIFO_TYPE;
      stat_s_axi_gen_r                : out STAT_FIFO_TYPE;
      stat_s_axi_gen_bip              : out STAT_FIFO_TYPE;
      stat_s_axi_gen_bp               : out STAT_FIFO_TYPE;
      stat_s_axi_gen_wip              : out STAT_FIFO_TYPE;
      stat_s_axi_gen_w                : out STAT_FIFO_TYPE;
      stat_s_axi_gen_rd_latency       : out STAT_POINT_TYPE;
      stat_s_axi_gen_wr_latency       : out STAT_POINT_TYPE;
      stat_s_axi_gen_rd_latency_conf  : in  STAT_CONF_TYPE;
      stat_s_axi_gen_wr_latency_conf  : in  STAT_CONF_TYPE;
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  : out std_logic_vector(255 downto 0)
    );
  end component sc_s_axi_gen_interface;
  
  component sc_arbiter is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- IP Specific.
      C_ID_WIDTH                : natural range  1 to   32      :=  4;
      C_ENABLE_CTRL             : natural range  0 to    1      :=  0;
      C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
      C_NUM_FAST_PORTS          : natural range  0 to   32      :=  0;
      C_NUM_PORTS               : natural range  1 to   32      :=  1
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
  
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      opt_port_piperun          : in  std_logic;
      arbiter_piperun           : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            : in  WRITE_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
      wr_port_id                : in  std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
      wr_port_ready             : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            : in  READ_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
      rd_port_id                : in  std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
      rd_port_ready             : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Arbiter signals (to Access).
      
      arb_access                : out ARBITRATION_TYPE;
      arb_access_id             : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
       
       
      -- ---------------------------------------------------
      -- Control If Transactions.
      
      ctrl_init_done            : in  std_logic;
      ctrl_access               : in  ARBITRATION_TYPE;
      ctrl_ready                : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Port signals.
      
      arbiter_bp_push           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      arbiter_bp_early          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      wr_port_inbound           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Access signals.
      
      access_piperun            : in  std_logic;
      access_write_priority     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_other_write_prio   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Port signals (to Arbiter).
      
      read_data_hit_fit         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Arbiter).
      
      lookup_read_done          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      : in  std_logic;
      stat_enable                     : in  std_logic;
      
      stat_arb_valid                  : out STAT_POINT_TYPE;    -- Time valid transactions exist
      stat_arb_concurrent_accesses    : out STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
      stat_arb_opt_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
      stat_arb_gen_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                                -- Time valid read is blocked by prohibit
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug signals.
      
      ARBITER_DEBUG             : out std_logic_vector(255 downto 0)
    );
  end component sc_arbiter;
  
  component sc_access is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- Data type and settings specific.
      C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
      C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
      
      -- IP Specific.
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
      C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
      C_ID_WIDTH                : natural range  1 to   32      :=  4;
      
      -- Data type and settings specific.
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
      C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      wr_port_data_last         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      wr_port_data_be           : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      wr_port_data_word         : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
      wr_port_data_ready        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Snoop communication).
      
      snoop_fetch_piperun       : out std_logic;
      snoop_fetch_valid         : out std_logic;
      snoop_fetch_addr          : out AXI_ADDR_TYPE;
      snoop_fetch_myself        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_fetch_sync          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_fetch_pos_hazard    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_req_piperun         : out std_logic;
      snoop_req_valid           : out std_logic;
      snoop_req_write           : out std_logic;
      snoop_req_size            : out AXI_SIZE_TYPE;
      snoop_req_addr            : out AXI_ADDR_TYPE;
      snoop_req_snoop           : out AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
      snoop_req_myself          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_req_always          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_req_update_filter   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_req_want            : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_req_complete        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_req_complete_target : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_act_piperun         : out std_logic;
      snoop_act_valid           : out std_logic;
      snoop_act_waiting_4_pipe  : out std_logic;
      snoop_act_write           : out std_logic;
      snoop_act_addr            : out AXI_ADDR_TYPE;
      snoop_act_prot            : out AXI_PROT_TYPE;
      snoop_act_snoop           : out AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
      snoop_act_myself          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_always          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_tag_valid       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_tag_unique      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_tag_dirty       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_done            : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_use_external    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_act_write_blocking  : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_info_tag_valid      : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_info_tag_unique     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_info_tag_dirty      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      snoop_resp_valid          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_resp_crresp         : in  AXI_CRRESP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
      snoop_resp_ready          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      read_data_ex_rack         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Arbiter signals.
      
      arb_access                : in  ARBITRATION_TYPE;
      arb_access_id             : in  std_logic_vector(C_ID_WIDTH - 1 downto 0);
       
      arbiter_bp_push           : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      arbiter_bp_early          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      wr_port_inbound           : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
       
      -- ---------------------------------------------------
      -- Lookup signals.
      
      lookup_piperun            : in  std_logic;
      
      lookup_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      update_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Access signals (for Arbiter).
      
      access_piperun            : out std_logic;
      access_write_priority     : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_other_write_prio   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      access_bp_push            : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_bp_early           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Access signals (to Lookup/Update).
      
      access_valid              : out std_logic;
      access_info               : out ACCESS_TYPE;
      access_use                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      access_stp                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      access_id                 : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
      
      access_data_valid         : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_last          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_be            : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      access_data_word          : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Snoop signals (Read Data & response).
      
      snoop_read_data_valid     : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      snoop_read_data_last      : out std_logic;
      snoop_read_data_resp      : out AXI_RRESP_TYPE;
      snoop_read_data_word      : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
      snoop_read_data_ready     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      stat_access_valid         : out STAT_POINT_TYPE;    -- Time valid per transaction
      stat_access_stall         : out STAT_POINT_TYPE;    -- Time stalled per transaction
      stat_access_fetch_stall   : out STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
      stat_access_req_stall     : out STAT_POINT_TYPE;    -- Time stalled per transaction (req)
      stat_access_act_stall     : out STAT_POINT_TYPE;    -- Time stalled per transaction (act)
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug signals.
      
      ACCESS_DEBUG              : out std_logic_vector(255 downto 0)
    );
  end component sc_access;
  
  component carry_latch_or is
    generic (
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_NUM_PAD : natural;
      C_INV_C   : boolean
    );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      O         : out std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_latch_or;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Signals between Interface and Arbiter
  
  -- Internal Interface Signals (All request).
  signal arbiter_piperun            : std_logic;
  
  
  -- Piperun Manipulation
  signal gen_port_is_idle           : std_logic;
  signal opt_port_piperun           : std_logic;
  signal gen_port_piperun           : std_logic_vector(max_of(C_NUM_PORTS - 1, 0) downto 0);
  
  
  -- Internal Interface Signals (Write request).
  signal wr_port_access             : WRITE_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
  signal wr_port_id                 : std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
  signal wr_port_ready              : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- Internal Interface Signals (Read request).
  signal rd_port_access             : READ_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
  signal rd_port_id                 : std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
  signal rd_port_ready              : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- Internal Interface Signals (Write Data).
  signal wr_port_data_valid         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal wr_port_data_last          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal wr_port_data_be            : std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
  signal wr_port_data_word          : std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
  signal wr_port_data_ready         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- Port signals (to Arbiter).
    
  signal read_data_hit_fit_i        : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
  -- ---------------------------------------------------
  -- Internal Interface Signals (Snoop communication).
  
  signal snoop_fetch_piperun       : std_logic;
  signal snoop_fetch_valid         : std_logic;
  signal snoop_fetch_addr          : AXI_ADDR_TYPE;
  signal snoop_fetch_myself        : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_fetch_sync          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_fetch_pos_hazard    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal snoop_req_piperun         : std_logic;
  signal snoop_req_valid           : std_logic;
  signal snoop_req_write           : std_logic;
  signal snoop_req_size            : AXI_SIZE_TYPE;
  signal snoop_req_addr            : AXI_ADDR_TYPE;
  signal snoop_req_snoop           : AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_myself          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_always          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_update_filter   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_want            : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_complete        : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_req_complete_target : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal snoop_act_piperun         : std_logic;
  signal snoop_act_valid           : std_logic;
  signal snoop_act_waiting_4_pipe  : std_logic;
  signal snoop_act_write           : std_logic;
  signal snoop_act_addr            : AXI_ADDR_TYPE;
  signal snoop_act_prot            : AXI_PROT_TYPE;
  signal snoop_act_snoop           : AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_myself          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_always          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_tag_valid       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_tag_unique      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_tag_dirty       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_done            : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_use_external    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_act_write_blocking  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal snoop_info_tag_valid      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_info_tag_unique     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_info_tag_dirty      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
  signal snoop_resp_valid          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_resp_crresp         : AXI_CRRESP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
  signal snoop_resp_ready          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal read_data_ex_rack          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- Arbiter signals (to Access).
  signal arb_access                 : ARBITRATION_TYPE;
  signal arb_access_id              : std_logic_vector(C_ID_WIDTH - 1 downto 0);
   
  -- Port signals.
  signal arbiter_bp_push            : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal arbiter_bp_early           : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal wr_port_inbound            : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal access_bp_push             : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal access_bp_early            : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
  -- Access signals.
  signal access_piperun             : std_logic;
  signal access_write_priority      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal access_other_write_prio    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Snoop signals (Read Data & response).
  
  signal snoop_read_data_valid      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal snoop_read_data_last       : std_logic;
  signal snoop_read_data_resp       : AXI_RRESP_TYPE;
  signal snoop_read_data_word       : std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
  signal snoop_read_data_ready      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal port_assert_error          : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal arb_assert                 : std_logic;
  signal acs_assert                 : std_logic;
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  
begin  -- architecture IMP


  -----------------------------------------------------------------------------
  -- Piperun Manipulation
  -----------------------------------------------------------------------------
  
  -- Move Generic Pipeline if it is idle
  Use_Gen_Port: if (C_NUM_GENERIC_PORTS > 0) generate
    signal pad_arbiter_piperun    : std_logic_vector(C_NUM_PORTS downto 0);
  begin
    -- Generate a dedicated Piperun for each Generic interface.
    -- It has to be a "or" of the regular Arbiter Piperun in order to pull
    -- data through the pipeline registers.
    -- I.e. the Piperun signal branches to each interface in order to bring transaction to
    -- the arbiter point even when there is no pipeline movement.
    
    -- Starting point.
    pad_arbiter_piperun(0) <= arbiter_piperun;
    
    -- The branch.
    Gen_Port: for I in 0 to C_NUM_GENERIC_PORTS - 1 generate
      signal gen_port_is_idle : std_logic;
    begin
      gen_port_is_idle  <= ( not wr_port_access(C_NUM_OPTIMIZED_PORTS + I).Valid and 
                             not rd_port_access(C_NUM_OPTIMIZED_PORTS + I).Valid );
    
      FE_PR_Latch_Inst1: carry_latch_or
        generic map(
          C_TARGET  => C_TARGET,
          C_NUM_PAD => min_of(4, I * 4),
          C_INV_C   => false
        )
        port map(
          Carry_IN  => pad_arbiter_piperun(I),
          A         => gen_port_is_idle,
          O         => gen_port_piperun(I),
          Carry_OUT => pad_arbiter_piperun(I+1)
        );
    end generate Gen_Port;
    
    -- Propagate arbiter pipeline run directly to the Optimized interfaces.
    opt_port_piperun <= pad_arbiter_piperun(C_NUM_GENERIC_PORTS);
    
  end generate Use_Gen_Port;

  No_Gen_Port: if (C_NUM_GENERIC_PORTS = 0) generate
  begin
    gen_port_piperun(0) <= arbiter_piperun;
    opt_port_piperun    <= arbiter_piperun;
  end generate No_Gen_Port;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #0
  -----------------------------------------------------------------------------
  
  Use_Port_0: if ( C_NUM_OPTIMIZED_PORTS > 0 ) generate
  begin
    AXI_0: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S0_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S0_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S0_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S0_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S0_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S0_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S0_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S0_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S0_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S0_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S0_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S0_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S0_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S0_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S0_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S0_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,

        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 0,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S0_AXI_AWID,
        S_AXI_AWADDR              => S0_AXI_AWADDR,
        S_AXI_AWLEN               => S0_AXI_AWLEN,
        S_AXI_AWSIZE              => S0_AXI_AWSIZE,
        S_AXI_AWBURST             => S0_AXI_AWBURST,
        S_AXI_AWLOCK              => S0_AXI_AWLOCK,
        S_AXI_AWCACHE             => S0_AXI_AWCACHE,
        S_AXI_AWPROT              => S0_AXI_AWPROT,
        S_AXI_AWQOS               => S0_AXI_AWQOS,
        S_AXI_AWVALID             => S0_AXI_AWVALID,
        S_AXI_AWREADY             => S0_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S0_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S0_AXI_AWSNOOP,
        S_AXI_AWBAR               => S0_AXI_AWBAR,
        S_AXI_AWUSER              => S0_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S0_AXI_WDATA,
        S_AXI_WSTRB               => S0_AXI_WSTRB,
        S_AXI_WLAST               => S0_AXI_WLAST,
        S_AXI_WVALID              => S0_AXI_WVALID,
        S_AXI_WREADY              => S0_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S0_AXI_BRESP,
        S_AXI_BID                 => S0_AXI_BID,
        S_AXI_BVALID              => S0_AXI_BVALID,
        S_AXI_BREADY              => S0_AXI_BREADY,
        S_AXI_WACK                => S0_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S0_AXI_ARID,
        S_AXI_ARADDR              => S0_AXI_ARADDR,
        S_AXI_ARLEN               => S0_AXI_ARLEN,
        S_AXI_ARSIZE              => S0_AXI_ARSIZE,
        S_AXI_ARBURST             => S0_AXI_ARBURST,
        S_AXI_ARLOCK              => S0_AXI_ARLOCK,
        S_AXI_ARCACHE             => S0_AXI_ARCACHE,
        S_AXI_ARPROT              => S0_AXI_ARPROT,
        S_AXI_ARQOS               => S0_AXI_ARQOS,
        S_AXI_ARVALID             => S0_AXI_ARVALID,
        S_AXI_ARREADY             => S0_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S0_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S0_AXI_ARSNOOP,
        S_AXI_ARBAR               => S0_AXI_ARBAR,
        S_AXI_ARUSER              => S0_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S0_AXI_RID,
        S_AXI_RDATA               => S0_AXI_RDATA,
        S_AXI_RRESP               => S0_AXI_RRESP,
        S_AXI_RLAST               => S0_AXI_RLAST,
        S_AXI_RVALID              => S0_AXI_RVALID,
        S_AXI_RREADY              => S0_AXI_RREADY,
        S_AXI_RACK                => S0_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S0_AXI_ACVALID,
        S_AXI_ACADDR              => S0_AXI_ACADDR,
        S_AXI_ACSNOOP             => S0_AXI_ACSNOOP,
        S_AXI_ACPROT              => S0_AXI_ACPROT,
        S_AXI_ACREADY             => S0_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S0_AXI_CRVALID,
        S_AXI_CRRESP              => S0_AXI_CRRESP,
        S_AXI_CRREADY             => S0_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S0_AXI_CDVALID,
        S_AXI_CDDATA              => S0_AXI_CDDATA,
        S_AXI_CDLAST              => S0_AXI_CDLAST,
        S_AXI_CDREADY             => S0_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(0),
        wr_port_id                => wr_port_id((0+1) * C_ID_WIDTH - 1 downto (0) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(0),
        rd_port_id                => rd_port_id((0+1) * C_ID_WIDTH - 1 downto (0) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(0),
        snoop_fetch_sync          => snoop_fetch_sync(0),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(0),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(0),
        snoop_req_myself          => snoop_req_myself(0),
        snoop_req_always          => snoop_req_always(0),
        snoop_req_update_filter   => snoop_req_update_filter(0),
        snoop_req_want            => snoop_req_want(0),
        snoop_req_complete        => snoop_req_complete(0),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(0),
        snoop_act_myself          => snoop_act_myself(0),
        snoop_act_always          => snoop_act_always(0),
        snoop_act_tag_valid       => snoop_act_tag_valid(0),
        snoop_act_tag_unique      => snoop_act_tag_unique(0),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(0),
        snoop_act_done            => snoop_act_done(0),
        snoop_act_use_external    => snoop_act_use_external(0),
        snoop_act_write_blocking  => snoop_act_write_blocking(0),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(0),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(0),
        
        snoop_resp_valid          => snoop_resp_valid(0),
        snoop_resp_crresp         => snoop_resp_crresp(0),
        snoop_resp_ready          => snoop_resp_ready(0),
        
        read_data_ex_rack         => read_data_ex_rack(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(0),
        wr_port_data_last         => wr_port_data_last(0),
        wr_port_data_be           => wr_port_data_be((0+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (0) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((0+1) * C_CACHE_DATA_WIDTH - 1 downto (0) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(0),
        access_bp_early           => access_bp_early(0),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(0),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(0),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(0),
        read_info_full            => read_info_full(0),
        read_data_hit_pop         => read_data_hit_pop(0),
        read_data_hit_almost_full => read_data_hit_almost_full(0),
        read_data_hit_full        => read_data_hit_full(0),
        read_data_hit_fit         => read_data_hit_fit_i(0),
        read_data_miss_full       => read_data_miss_full(0),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(0),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(1 * C_CACHE_DATA_WIDTH - 1 downto 0 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(0),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(0),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(0),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(0),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(0),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(0),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(0),
        stat_s_axi_rip              => stat_s_axi_rip(0),
        stat_s_axi_r                => stat_s_axi_r(0),
        stat_s_axi_bip              => stat_s_axi_bip(0),
        stat_s_axi_bp               => stat_s_axi_bp(0),
        stat_s_axi_wip              => stat_s_axi_wip(0),
        stat_s_axi_w                => stat_s_axi_w(0),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(0),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(0),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(0),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(0),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(0),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF0_DEBUG 
      );
  end generate Use_Port_0;
  
  No_Port_0: if ( C_NUM_OPTIMIZED_PORTS < 1 ) generate
  begin
    S0_AXI_AWREADY        <= '0';
    S0_AXI_WREADY         <= '0';
    S0_AXI_BRESP          <= (others=>'0');
    S0_AXI_BID            <= (others=>'0');
    S0_AXI_BVALID         <= '0';
    S0_AXI_ARREADY        <= '0';
    S0_AXI_RID            <= (others=>'0');
    S0_AXI_RDATA          <= (others=>'0');
    S0_AXI_RRESP          <= (others=>'0');
    S0_AXI_RLAST          <= '0';
    S0_AXI_RVALID         <= '0';
    S0_AXI_ACVALID        <= '0';
    S0_AXI_ACADDR         <= (others=>'0');
    S0_AXI_ACSNOOP        <= (others=>'0');
    S0_AXI_ACPROT         <= (others=>'0');
    S0_AXI_CRREADY        <= '0';
    S0_AXI_CDREADY        <= '0';
    port_assert_error(0)  <= '0';
    OPT_IF0_DEBUG         <= (others=>'0');
  end generate No_Port_0;
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #1
  -----------------------------------------------------------------------------
  
  Use_Port_1: if ( C_NUM_OPTIMIZED_PORTS > 1 ) generate
  begin
    AXI_1: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S1_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S1_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S1_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S1_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S1_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S1_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S1_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S1_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S1_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S1_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S1_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S1_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S1_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S1_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S1_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S1_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 1,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S1_AXI_AWID,
        S_AXI_AWADDR              => S1_AXI_AWADDR,
        S_AXI_AWLEN               => S1_AXI_AWLEN,
        S_AXI_AWSIZE              => S1_AXI_AWSIZE,
        S_AXI_AWBURST             => S1_AXI_AWBURST,
        S_AXI_AWLOCK              => S1_AXI_AWLOCK,
        S_AXI_AWCACHE             => S1_AXI_AWCACHE,
        S_AXI_AWPROT              => S1_AXI_AWPROT,
        S_AXI_AWQOS               => S1_AXI_AWQOS,
        S_AXI_AWVALID             => S1_AXI_AWVALID,
        S_AXI_AWREADY             => S1_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S1_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S1_AXI_AWSNOOP,
        S_AXI_AWBAR               => S1_AXI_AWBAR,
        S_AXI_AWUSER              => S1_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S1_AXI_WDATA,
        S_AXI_WSTRB               => S1_AXI_WSTRB,
        S_AXI_WLAST               => S1_AXI_WLAST,
        S_AXI_WVALID              => S1_AXI_WVALID,
        S_AXI_WREADY              => S1_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S1_AXI_BRESP,
        S_AXI_BID                 => S1_AXI_BID,
        S_AXI_BVALID              => S1_AXI_BVALID,
        S_AXI_BREADY              => S1_AXI_BREADY,
        S_AXI_WACK                => S1_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S1_AXI_ARID,
        S_AXI_ARADDR              => S1_AXI_ARADDR,
        S_AXI_ARLEN               => S1_AXI_ARLEN,
        S_AXI_ARSIZE              => S1_AXI_ARSIZE,
        S_AXI_ARBURST             => S1_AXI_ARBURST,
        S_AXI_ARLOCK              => S1_AXI_ARLOCK,
        S_AXI_ARCACHE             => S1_AXI_ARCACHE,
        S_AXI_ARPROT              => S1_AXI_ARPROT,
        S_AXI_ARQOS               => S1_AXI_ARQOS,
        S_AXI_ARVALID             => S1_AXI_ARVALID,
        S_AXI_ARREADY             => S1_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S1_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S1_AXI_ARSNOOP,
        S_AXI_ARBAR               => S1_AXI_ARBAR,
        S_AXI_ARUSER              => S1_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S1_AXI_RID,
        S_AXI_RDATA               => S1_AXI_RDATA,
        S_AXI_RRESP               => S1_AXI_RRESP,
        S_AXI_RLAST               => S1_AXI_RLAST,
        S_AXI_RVALID              => S1_AXI_RVALID,
        S_AXI_RREADY              => S1_AXI_RREADY,
        S_AXI_RACK                => S1_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S1_AXI_ACVALID,
        S_AXI_ACADDR              => S1_AXI_ACADDR,
        S_AXI_ACSNOOP             => S1_AXI_ACSNOOP,
        S_AXI_ACPROT              => S1_AXI_ACPROT,
        S_AXI_ACREADY             => S1_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S1_AXI_CRVALID,
        S_AXI_CRRESP              => S1_AXI_CRRESP,
        S_AXI_CRREADY             => S1_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S1_AXI_CDVALID,
        S_AXI_CDDATA              => S1_AXI_CDDATA,
        S_AXI_CDLAST              => S1_AXI_CDLAST,
        S_AXI_CDREADY             => S1_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(1),
        wr_port_id                => wr_port_id((1+1) * C_ID_WIDTH - 1 downto (1) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(1),
        rd_port_id                => rd_port_id((1+1) * C_ID_WIDTH - 1 downto (1) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(1),
        snoop_fetch_sync          => snoop_fetch_sync(1),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(1),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(1),
        snoop_req_myself          => snoop_req_myself(1),
        snoop_req_always          => snoop_req_always(1),
        snoop_req_update_filter   => snoop_req_update_filter(1),
        snoop_req_want            => snoop_req_want(1),
        snoop_req_complete        => snoop_req_complete(1),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(1),
        snoop_act_myself          => snoop_act_myself(1),
        snoop_act_always          => snoop_act_always(1),
        snoop_act_tag_valid       => snoop_act_tag_valid(1),
        snoop_act_tag_unique      => snoop_act_tag_unique(1),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(1),
        snoop_act_done            => snoop_act_done(1),
        snoop_act_use_external    => snoop_act_use_external(1),
        snoop_act_write_blocking  => snoop_act_write_blocking(1),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(1),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(1),
        
        snoop_resp_valid          => snoop_resp_valid(1),
        snoop_resp_crresp         => snoop_resp_crresp(1),
        snoop_resp_ready          => snoop_resp_ready(1),
        
        read_data_ex_rack         => read_data_ex_rack(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(1),
        wr_port_data_last         => wr_port_data_last(1),
        wr_port_data_be           => wr_port_data_be((1+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (1) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((1+1) * C_CACHE_DATA_WIDTH - 1 downto (1) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(1),
        access_bp_early           => access_bp_early(1),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(1),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(1),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(1),
        read_info_full            => read_info_full(1),
        read_data_hit_pop         => read_data_hit_pop(1),
        read_data_hit_almost_full => read_data_hit_almost_full(1),
        read_data_hit_full        => read_data_hit_full(1),
        read_data_hit_fit         => read_data_hit_fit_i(1),
        read_data_miss_full       => read_data_miss_full(1),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(1),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(2 * C_CACHE_DATA_WIDTH - 1 downto 1 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(1),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(1),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(1),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(1),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(1),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(1),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(1),
        stat_s_axi_rip              => stat_s_axi_rip(1),
        stat_s_axi_r                => stat_s_axi_r(1),
        stat_s_axi_bip              => stat_s_axi_bip(1),
        stat_s_axi_bp               => stat_s_axi_bp(1),
        stat_s_axi_wip              => stat_s_axi_wip(1),
        stat_s_axi_w                => stat_s_axi_w(1),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(1),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(1),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(1),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(1),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(1),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF1_DEBUG 
      );
  end generate Use_Port_1;
  
  No_Port_1: if ( C_NUM_OPTIMIZED_PORTS < 2 ) generate
  begin
    S1_AXI_AWREADY        <= '0';
    S1_AXI_WREADY         <= '0';
    S1_AXI_BRESP          <= (others=>'0');
    S1_AXI_BID            <= (others=>'0');
    S1_AXI_BVALID         <= '0';
    S1_AXI_ARREADY        <= '0';
    S1_AXI_RID            <= (others=>'0');
    S1_AXI_RDATA          <= (others=>'0');
    S1_AXI_RRESP          <= (others=>'0');
    S1_AXI_RLAST          <= '0';
    S1_AXI_RVALID         <= '0';
    S1_AXI_ACVALID        <= '0';
    S1_AXI_ACADDR         <= (others=>'0');
    S1_AXI_ACSNOOP        <= (others=>'0');
    S1_AXI_ACPROT         <= (others=>'0');
    S1_AXI_CRREADY        <= '0';
    S1_AXI_CDREADY        <= '0';
    port_assert_error(1)  <= '0';
    OPT_IF1_DEBUG         <= (others=>'0');
  end generate No_Port_1;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #2
  -----------------------------------------------------------------------------
  
  Use_Port_2: if ( C_NUM_OPTIMIZED_PORTS > 2 ) generate
  begin
    AXI_2: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S2_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S2_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S2_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S2_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S2_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S2_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S2_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S2_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S2_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S2_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S2_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S2_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S2_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S2_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S2_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S2_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 2,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S2_AXI_AWID,
        S_AXI_AWADDR              => S2_AXI_AWADDR,
        S_AXI_AWLEN               => S2_AXI_AWLEN,
        S_AXI_AWSIZE              => S2_AXI_AWSIZE,
        S_AXI_AWBURST             => S2_AXI_AWBURST,
        S_AXI_AWLOCK              => S2_AXI_AWLOCK,
        S_AXI_AWCACHE             => S2_AXI_AWCACHE,
        S_AXI_AWPROT              => S2_AXI_AWPROT,
        S_AXI_AWQOS               => S2_AXI_AWQOS,
        S_AXI_AWVALID             => S2_AXI_AWVALID,
        S_AXI_AWREADY             => S2_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S2_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S2_AXI_AWSNOOP,
        S_AXI_AWBAR               => S2_AXI_AWBAR,
        S_AXI_AWUSER              => S2_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S2_AXI_WDATA,
        S_AXI_WSTRB               => S2_AXI_WSTRB,
        S_AXI_WLAST               => S2_AXI_WLAST,
        S_AXI_WVALID              => S2_AXI_WVALID,
        S_AXI_WREADY              => S2_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S2_AXI_BRESP,
        S_AXI_BID                 => S2_AXI_BID,
        S_AXI_BVALID              => S2_AXI_BVALID,
        S_AXI_BREADY              => S2_AXI_BREADY,
        S_AXI_WACK                => S2_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S2_AXI_ARID,
        S_AXI_ARADDR              => S2_AXI_ARADDR,
        S_AXI_ARLEN               => S2_AXI_ARLEN,
        S_AXI_ARSIZE              => S2_AXI_ARSIZE,
        S_AXI_ARBURST             => S2_AXI_ARBURST,
        S_AXI_ARLOCK              => S2_AXI_ARLOCK,
        S_AXI_ARCACHE             => S2_AXI_ARCACHE,
        S_AXI_ARPROT              => S2_AXI_ARPROT,
        S_AXI_ARQOS               => S2_AXI_ARQOS,
        S_AXI_ARVALID             => S2_AXI_ARVALID,
        S_AXI_ARREADY             => S2_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S2_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S2_AXI_ARSNOOP,
        S_AXI_ARBAR               => S2_AXI_ARBAR,
        S_AXI_ARUSER              => S2_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S2_AXI_RID,
        S_AXI_RDATA               => S2_AXI_RDATA,
        S_AXI_RRESP               => S2_AXI_RRESP,
        S_AXI_RLAST               => S2_AXI_RLAST,
        S_AXI_RVALID              => S2_AXI_RVALID,
        S_AXI_RREADY              => S2_AXI_RREADY,
        S_AXI_RACK                => S2_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S2_AXI_ACVALID,
        S_AXI_ACADDR              => S2_AXI_ACADDR,
        S_AXI_ACSNOOP             => S2_AXI_ACSNOOP,
        S_AXI_ACPROT              => S2_AXI_ACPROT,
        S_AXI_ACREADY             => S2_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S2_AXI_CRVALID,
        S_AXI_CRRESP              => S2_AXI_CRRESP,
        S_AXI_CRREADY             => S2_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S2_AXI_CDVALID,
        S_AXI_CDDATA              => S2_AXI_CDDATA,
        S_AXI_CDLAST              => S2_AXI_CDLAST,
        S_AXI_CDREADY             => S2_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(2),
        wr_port_id                => wr_port_id((2+1) * C_ID_WIDTH - 1 downto (2) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(2),
        rd_port_id                => rd_port_id((2+1) * C_ID_WIDTH - 1 downto (2) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(2),
        snoop_fetch_sync          => snoop_fetch_sync(2),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(2),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(2),
        snoop_req_myself          => snoop_req_myself(2),
        snoop_req_always          => snoop_req_always(2),
        snoop_req_update_filter   => snoop_req_update_filter(2),
        snoop_req_want            => snoop_req_want(2),
        snoop_req_complete        => snoop_req_complete(2),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(2),
        snoop_act_myself          => snoop_act_myself(2),
        snoop_act_always          => snoop_act_always(2),
        snoop_act_tag_valid       => snoop_act_tag_valid(2),
        snoop_act_tag_unique      => snoop_act_tag_unique(2),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(2),
        snoop_act_done            => snoop_act_done(2),
        snoop_act_use_external    => snoop_act_use_external(2),
        snoop_act_write_blocking  => snoop_act_write_blocking(2),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(2),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(2),
        
        snoop_resp_valid          => snoop_resp_valid(2),
        snoop_resp_crresp         => snoop_resp_crresp(2),
        snoop_resp_ready          => snoop_resp_ready(2),
        
        read_data_ex_rack         => read_data_ex_rack(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(2),
        wr_port_data_last         => wr_port_data_last(2),
        wr_port_data_be           => wr_port_data_be((2+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (2) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((2+1) * C_CACHE_DATA_WIDTH - 1 downto (2) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(2),
        access_bp_early           => access_bp_early(2),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(2),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(2),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(2),
        read_info_full            => read_info_full(2),
        read_data_hit_pop         => read_data_hit_pop(2),
        read_data_hit_almost_full => read_data_hit_almost_full(2),
        read_data_hit_full        => read_data_hit_full(2),
        read_data_hit_fit         => read_data_hit_fit_i(2),
        read_data_miss_full       => read_data_miss_full(2),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(2),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(3 * C_CACHE_DATA_WIDTH - 1 downto 2 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(2),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(2),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(2),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(2),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(2),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(2),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(2),
        stat_s_axi_rip              => stat_s_axi_rip(2),
        stat_s_axi_r                => stat_s_axi_r(2),
        stat_s_axi_bip              => stat_s_axi_bip(2),
        stat_s_axi_bp               => stat_s_axi_bp(2),
        stat_s_axi_wip              => stat_s_axi_wip(2),
        stat_s_axi_w                => stat_s_axi_w(2),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(2),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(2),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(2),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(2),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(2),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF2_DEBUG 
      );
  end generate Use_Port_2;
  
  No_Port_2: if ( C_NUM_OPTIMIZED_PORTS < 3 ) generate
  begin
    S2_AXI_AWREADY        <= '0';
    S2_AXI_WREADY         <= '0';
    S2_AXI_BRESP          <= (others=>'0');
    S2_AXI_BID            <= (others=>'0');
    S2_AXI_BVALID         <= '0';
    S2_AXI_ARREADY        <= '0';
    S2_AXI_RID            <= (others=>'0');
    S2_AXI_RDATA          <= (others=>'0');
    S2_AXI_RRESP          <= (others=>'0');
    S2_AXI_RLAST          <= '0';
    S2_AXI_RVALID         <= '0';
    S2_AXI_ACVALID        <= '0';
    S2_AXI_ACADDR         <= (others=>'0');
    S2_AXI_ACSNOOP        <= (others=>'0');
    S2_AXI_ACPROT         <= (others=>'0');
    S2_AXI_CRREADY        <= '0';
    S2_AXI_CDREADY        <= '0';
    port_assert_error(2)  <= '0';
    OPT_IF2_DEBUG         <= (others=>'0');
  end generate No_Port_2;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #3
  -----------------------------------------------------------------------------
  
  Use_Port_3: if ( C_NUM_OPTIMIZED_PORTS > 3 ) generate
  begin
    AXI_3: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S3_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S3_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S3_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S3_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S3_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S3_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S3_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S3_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S3_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S3_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S3_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S3_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S3_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S3_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S3_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S3_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 3,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S3_AXI_AWID,
        S_AXI_AWADDR              => S3_AXI_AWADDR,
        S_AXI_AWLEN               => S3_AXI_AWLEN,
        S_AXI_AWSIZE              => S3_AXI_AWSIZE,
        S_AXI_AWBURST             => S3_AXI_AWBURST,
        S_AXI_AWLOCK              => S3_AXI_AWLOCK,
        S_AXI_AWCACHE             => S3_AXI_AWCACHE,
        S_AXI_AWPROT              => S3_AXI_AWPROT,
        S_AXI_AWQOS               => S3_AXI_AWQOS,
        S_AXI_AWVALID             => S3_AXI_AWVALID,
        S_AXI_AWREADY             => S3_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S3_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S3_AXI_AWSNOOP,
        S_AXI_AWBAR               => S3_AXI_AWBAR,
        S_AXI_AWUSER              => S3_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S3_AXI_WDATA,
        S_AXI_WSTRB               => S3_AXI_WSTRB,
        S_AXI_WLAST               => S3_AXI_WLAST,
        S_AXI_WVALID              => S3_AXI_WVALID,
        S_AXI_WREADY              => S3_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S3_AXI_BRESP,
        S_AXI_BID                 => S3_AXI_BID,
        S_AXI_BVALID              => S3_AXI_BVALID,
        S_AXI_BREADY              => S3_AXI_BREADY,
        S_AXI_WACK                => S3_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S3_AXI_ARID,
        S_AXI_ARADDR              => S3_AXI_ARADDR,
        S_AXI_ARLEN               => S3_AXI_ARLEN,
        S_AXI_ARSIZE              => S3_AXI_ARSIZE,
        S_AXI_ARBURST             => S3_AXI_ARBURST,
        S_AXI_ARLOCK              => S3_AXI_ARLOCK,
        S_AXI_ARCACHE             => S3_AXI_ARCACHE,
        S_AXI_ARPROT              => S3_AXI_ARPROT,
        S_AXI_ARQOS               => S3_AXI_ARQOS,
        S_AXI_ARVALID             => S3_AXI_ARVALID,
        S_AXI_ARREADY             => S3_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S3_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S3_AXI_ARSNOOP,
        S_AXI_ARBAR               => S3_AXI_ARBAR,
        S_AXI_ARUSER              => S3_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S3_AXI_RID,
        S_AXI_RDATA               => S3_AXI_RDATA,
        S_AXI_RRESP               => S3_AXI_RRESP,
        S_AXI_RLAST               => S3_AXI_RLAST,
        S_AXI_RVALID              => S3_AXI_RVALID,
        S_AXI_RREADY              => S3_AXI_RREADY,
        S_AXI_RACK                => S3_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S3_AXI_ACVALID,
        S_AXI_ACADDR              => S3_AXI_ACADDR,
        S_AXI_ACSNOOP             => S3_AXI_ACSNOOP,
        S_AXI_ACPROT              => S3_AXI_ACPROT,
        S_AXI_ACREADY             => S3_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S3_AXI_CRVALID,
        S_AXI_CRRESP              => S3_AXI_CRRESP,
        S_AXI_CRREADY             => S3_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S3_AXI_CDVALID,
        S_AXI_CDDATA              => S3_AXI_CDDATA,
        S_AXI_CDLAST              => S3_AXI_CDLAST,
        S_AXI_CDREADY             => S3_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(3),
        wr_port_id                => wr_port_id((3+1) * C_ID_WIDTH - 1 downto (3) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(3),
        rd_port_id                => rd_port_id((3+1) * C_ID_WIDTH - 1 downto (3) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(3),
        snoop_fetch_sync          => snoop_fetch_sync(3),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(3),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(3),
        snoop_req_myself          => snoop_req_myself(3),
        snoop_req_always          => snoop_req_always(3),
        snoop_req_update_filter   => snoop_req_update_filter(3),
        snoop_req_want            => snoop_req_want(3),
        snoop_req_complete        => snoop_req_complete(3),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(3),
        snoop_act_myself          => snoop_act_myself(3),
        snoop_act_always          => snoop_act_always(3),
        snoop_act_tag_valid       => snoop_act_tag_valid(3),
        snoop_act_tag_unique      => snoop_act_tag_unique(3),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(3),
        snoop_act_done            => snoop_act_done(3),
        snoop_act_use_external    => snoop_act_use_external(3),
        snoop_act_write_blocking  => snoop_act_write_blocking(3),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(3),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(3),
        
        snoop_resp_valid          => snoop_resp_valid(3),
        snoop_resp_crresp         => snoop_resp_crresp(3),
        snoop_resp_ready          => snoop_resp_ready(3),
        
        read_data_ex_rack         => read_data_ex_rack(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(3),
        wr_port_data_last         => wr_port_data_last(3),
        wr_port_data_be           => wr_port_data_be((3+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (3) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((3+1) * C_CACHE_DATA_WIDTH - 1 downto (3) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(3),
        access_bp_early           => access_bp_early(3),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(3),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(3),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(3),
        read_info_full            => read_info_full(3),
        read_data_hit_pop         => read_data_hit_pop(3),
        read_data_hit_almost_full => read_data_hit_almost_full(3),
        read_data_hit_full        => read_data_hit_full(3),
        read_data_hit_fit         => read_data_hit_fit_i(3),
        read_data_miss_full       => read_data_miss_full(3),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(3),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(4 * C_CACHE_DATA_WIDTH - 1 downto 3 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(3),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(3),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(3),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(3),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(3),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(3),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(3),
        stat_s_axi_rip              => stat_s_axi_rip(3),
        stat_s_axi_r                => stat_s_axi_r(3),
        stat_s_axi_bip              => stat_s_axi_bip(3),
        stat_s_axi_bp               => stat_s_axi_bp(3),
        stat_s_axi_wip              => stat_s_axi_wip(3),
        stat_s_axi_w                => stat_s_axi_w(3),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(3),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(3),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(3),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(3),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(3),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF3_DEBUG 
      );
  end generate Use_Port_3;
  
  No_Port_3: if ( C_NUM_OPTIMIZED_PORTS < 4 ) generate
  begin
    S3_AXI_AWREADY        <= '0';
    S3_AXI_WREADY         <= '0';
    S3_AXI_BRESP          <= (others=>'0');
    S3_AXI_BID            <= (others=>'0');
    S3_AXI_BVALID         <= '0';
    S3_AXI_ARREADY        <= '0';
    S3_AXI_RID            <= (others=>'0');
    S3_AXI_RDATA          <= (others=>'0');
    S3_AXI_RRESP          <= (others=>'0');
    S3_AXI_RLAST          <= '0';
    S3_AXI_RVALID         <= '0';
    S3_AXI_ACVALID        <= '0';
    S3_AXI_ACADDR         <= (others=>'0');
    S3_AXI_ACSNOOP        <= (others=>'0');
    S3_AXI_ACPROT         <= (others=>'0');
    S3_AXI_CRREADY        <= '0';
    S3_AXI_CDREADY        <= '0';
    port_assert_error(3)  <= '0';
    OPT_IF3_DEBUG         <= (others=>'0');
  end generate No_Port_3;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #4
  -----------------------------------------------------------------------------
  
  Use_Port_4: if ( C_NUM_OPTIMIZED_PORTS > 4 ) generate
  begin
    AXI_4: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S4_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S4_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S4_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S4_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S4_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S4_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S4_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S4_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S4_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S4_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S4_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S4_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S4_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S4_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S4_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S4_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 4,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S4_AXI_AWID,
        S_AXI_AWADDR              => S4_AXI_AWADDR,
        S_AXI_AWLEN               => S4_AXI_AWLEN,
        S_AXI_AWSIZE              => S4_AXI_AWSIZE,
        S_AXI_AWBURST             => S4_AXI_AWBURST,
        S_AXI_AWLOCK              => S4_AXI_AWLOCK,
        S_AXI_AWCACHE             => S4_AXI_AWCACHE,
        S_AXI_AWPROT              => S4_AXI_AWPROT,
        S_AXI_AWQOS               => S4_AXI_AWQOS,
        S_AXI_AWVALID             => S4_AXI_AWVALID,
        S_AXI_AWREADY             => S4_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S4_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S4_AXI_AWSNOOP,
        S_AXI_AWBAR               => S4_AXI_AWBAR,
        S_AXI_AWUSER              => S4_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S4_AXI_WDATA,
        S_AXI_WSTRB               => S4_AXI_WSTRB,
        S_AXI_WLAST               => S4_AXI_WLAST,
        S_AXI_WVALID              => S4_AXI_WVALID,
        S_AXI_WREADY              => S4_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S4_AXI_BRESP,
        S_AXI_BID                 => S4_AXI_BID,
        S_AXI_BVALID              => S4_AXI_BVALID,
        S_AXI_BREADY              => S4_AXI_BREADY,
        S_AXI_WACK                => S4_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S4_AXI_ARID,
        S_AXI_ARADDR              => S4_AXI_ARADDR,
        S_AXI_ARLEN               => S4_AXI_ARLEN,
        S_AXI_ARSIZE              => S4_AXI_ARSIZE,
        S_AXI_ARBURST             => S4_AXI_ARBURST,
        S_AXI_ARLOCK              => S4_AXI_ARLOCK,
        S_AXI_ARCACHE             => S4_AXI_ARCACHE,
        S_AXI_ARPROT              => S4_AXI_ARPROT,
        S_AXI_ARQOS               => S4_AXI_ARQOS,
        S_AXI_ARVALID             => S4_AXI_ARVALID,
        S_AXI_ARREADY             => S4_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S4_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S4_AXI_ARSNOOP,
        S_AXI_ARBAR               => S4_AXI_ARBAR,
        S_AXI_ARUSER              => S4_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S4_AXI_RID,
        S_AXI_RDATA               => S4_AXI_RDATA,
        S_AXI_RRESP               => S4_AXI_RRESP,
        S_AXI_RLAST               => S4_AXI_RLAST,
        S_AXI_RVALID              => S4_AXI_RVALID,
        S_AXI_RREADY              => S4_AXI_RREADY,
        S_AXI_RACK                => S4_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S4_AXI_ACVALID,
        S_AXI_ACADDR              => S4_AXI_ACADDR,
        S_AXI_ACSNOOP             => S4_AXI_ACSNOOP,
        S_AXI_ACPROT              => S4_AXI_ACPROT,
        S_AXI_ACREADY             => S4_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S4_AXI_CRVALID,
        S_AXI_CRRESP              => S4_AXI_CRRESP,
        S_AXI_CRREADY             => S4_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S4_AXI_CDVALID,
        S_AXI_CDDATA              => S4_AXI_CDDATA,
        S_AXI_CDLAST              => S4_AXI_CDLAST,
        S_AXI_CDREADY             => S4_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(4),
        wr_port_id                => wr_port_id((4+1) * C_ID_WIDTH - 1 downto (4) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(4),
        rd_port_id                => rd_port_id((4+1) * C_ID_WIDTH - 1 downto (4) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(4),
        snoop_fetch_sync          => snoop_fetch_sync(4),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(4),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(4),
        snoop_req_myself          => snoop_req_myself(4),
        snoop_req_always          => snoop_req_always(4),
        snoop_req_update_filter   => snoop_req_update_filter(4),
        snoop_req_want            => snoop_req_want(4),
        snoop_req_complete        => snoop_req_complete(4),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(4),
        snoop_act_myself          => snoop_act_myself(4),
        snoop_act_always          => snoop_act_always(4),
        snoop_act_tag_valid       => snoop_act_tag_valid(4),
        snoop_act_tag_unique      => snoop_act_tag_unique(4),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(4),
        snoop_act_done            => snoop_act_done(4),
        snoop_act_use_external    => snoop_act_use_external(4),
        snoop_act_write_blocking  => snoop_act_write_blocking(4),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(4),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(4),
        
        snoop_resp_valid          => snoop_resp_valid(4),
        snoop_resp_crresp         => snoop_resp_crresp(4),
        snoop_resp_ready          => snoop_resp_ready(4),
        
        read_data_ex_rack         => read_data_ex_rack(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(4),
        wr_port_data_last         => wr_port_data_last(4),
        wr_port_data_be           => wr_port_data_be((4+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (4) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((4+1) * C_CACHE_DATA_WIDTH - 1 downto (4) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(4),
        access_bp_early           => access_bp_early(4),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(4),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(4),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(4),
        read_info_full            => read_info_full(4),
        read_data_hit_pop         => read_data_hit_pop(4),
        read_data_hit_almost_full => read_data_hit_almost_full(4),
        read_data_hit_full        => read_data_hit_full(4),
        read_data_hit_fit         => read_data_hit_fit_i(4),
        read_data_miss_full       => read_data_miss_full(4),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(4),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(5 * C_CACHE_DATA_WIDTH - 1 downto 4 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(4),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(4),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(4),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(4),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(4),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(4),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(4),
        stat_s_axi_rip              => stat_s_axi_rip(4),
        stat_s_axi_r                => stat_s_axi_r(4),
        stat_s_axi_bip              => stat_s_axi_bip(4),
        stat_s_axi_bp               => stat_s_axi_bp(4),
        stat_s_axi_wip              => stat_s_axi_wip(4),
        stat_s_axi_w                => stat_s_axi_w(4),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(4),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(4),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(4),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(4),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(4),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF4_DEBUG 
      );
  end generate Use_Port_4;
  
  No_Port_4: if ( C_NUM_OPTIMIZED_PORTS < 5 ) generate
  begin
    S4_AXI_AWREADY        <= '0';
    S4_AXI_WREADY         <= '0';
    S4_AXI_BRESP          <= (others=>'0');
    S4_AXI_BID            <= (others=>'0');
    S4_AXI_BVALID         <= '0';
    S4_AXI_ARREADY        <= '0';
    S4_AXI_RID            <= (others=>'0');
    S4_AXI_RDATA          <= (others=>'0');
    S4_AXI_RRESP          <= (others=>'0');
    S4_AXI_RLAST          <= '0';
    S4_AXI_RVALID         <= '0';
    S4_AXI_ACVALID        <= '0';
    S4_AXI_ACADDR         <= (others=>'0');
    S4_AXI_ACSNOOP        <= (others=>'0');
    S4_AXI_ACPROT         <= (others=>'0');
    S4_AXI_CRREADY        <= '0';
    S4_AXI_CDREADY        <= '0';
    port_assert_error(4)  <= '0';
    OPT_IF4_DEBUG         <= (others=>'0');
  end generate No_Port_4;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #5
  -----------------------------------------------------------------------------
  
  Use_Port_5: if ( C_NUM_OPTIMIZED_PORTS > 5 ) generate
  begin
    AXI_5: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S5_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S5_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S5_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S5_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S5_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S5_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S5_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S5_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S5_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S5_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S5_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S5_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S5_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S5_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S5_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S5_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 5,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S5_AXI_AWID,
        S_AXI_AWADDR              => S5_AXI_AWADDR,
        S_AXI_AWLEN               => S5_AXI_AWLEN,
        S_AXI_AWSIZE              => S5_AXI_AWSIZE,
        S_AXI_AWBURST             => S5_AXI_AWBURST,
        S_AXI_AWLOCK              => S5_AXI_AWLOCK,
        S_AXI_AWCACHE             => S5_AXI_AWCACHE,
        S_AXI_AWPROT              => S5_AXI_AWPROT,
        S_AXI_AWQOS               => S5_AXI_AWQOS,
        S_AXI_AWVALID             => S5_AXI_AWVALID,
        S_AXI_AWREADY             => S5_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S5_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S5_AXI_AWSNOOP,
        S_AXI_AWBAR               => S5_AXI_AWBAR,
        S_AXI_AWUSER              => S5_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S5_AXI_WDATA,
        S_AXI_WSTRB               => S5_AXI_WSTRB,
        S_AXI_WLAST               => S5_AXI_WLAST,
        S_AXI_WVALID              => S5_AXI_WVALID,
        S_AXI_WREADY              => S5_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S5_AXI_BRESP,
        S_AXI_BID                 => S5_AXI_BID,
        S_AXI_BVALID              => S5_AXI_BVALID,
        S_AXI_BREADY              => S5_AXI_BREADY,
        S_AXI_WACK                => S5_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S5_AXI_ARID,
        S_AXI_ARADDR              => S5_AXI_ARADDR,
        S_AXI_ARLEN               => S5_AXI_ARLEN,
        S_AXI_ARSIZE              => S5_AXI_ARSIZE,
        S_AXI_ARBURST             => S5_AXI_ARBURST,
        S_AXI_ARLOCK              => S5_AXI_ARLOCK,
        S_AXI_ARCACHE             => S5_AXI_ARCACHE,
        S_AXI_ARPROT              => S5_AXI_ARPROT,
        S_AXI_ARQOS               => S5_AXI_ARQOS,
        S_AXI_ARVALID             => S5_AXI_ARVALID,
        S_AXI_ARREADY             => S5_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S5_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S5_AXI_ARSNOOP,
        S_AXI_ARBAR               => S5_AXI_ARBAR,
        S_AXI_ARUSER              => S5_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S5_AXI_RID,
        S_AXI_RDATA               => S5_AXI_RDATA,
        S_AXI_RRESP               => S5_AXI_RRESP,
        S_AXI_RLAST               => S5_AXI_RLAST,
        S_AXI_RVALID              => S5_AXI_RVALID,
        S_AXI_RREADY              => S5_AXI_RREADY,
        S_AXI_RACK                => S5_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S5_AXI_ACVALID,
        S_AXI_ACADDR              => S5_AXI_ACADDR,
        S_AXI_ACSNOOP             => S5_AXI_ACSNOOP,
        S_AXI_ACPROT              => S5_AXI_ACPROT,
        S_AXI_ACREADY             => S5_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S5_AXI_CRVALID,
        S_AXI_CRRESP              => S5_AXI_CRRESP,
        S_AXI_CRREADY             => S5_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S5_AXI_CDVALID,
        S_AXI_CDDATA              => S5_AXI_CDDATA,
        S_AXI_CDLAST              => S5_AXI_CDLAST,
        S_AXI_CDREADY             => S5_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(5),
        wr_port_id                => wr_port_id((5+1) * C_ID_WIDTH - 1 downto (5) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(5),
        rd_port_id                => rd_port_id((5+1) * C_ID_WIDTH - 1 downto (5) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(5),
        snoop_fetch_sync          => snoop_fetch_sync(5),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(5),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(5),
        snoop_req_myself          => snoop_req_myself(5),
        snoop_req_always          => snoop_req_always(5),
        snoop_req_update_filter   => snoop_req_update_filter(5),
        snoop_req_want            => snoop_req_want(5),
        snoop_req_complete        => snoop_req_complete(5),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(5),
        snoop_act_myself          => snoop_act_myself(5),
        snoop_act_always          => snoop_act_always(5),
        snoop_act_tag_valid       => snoop_act_tag_valid(5),
        snoop_act_tag_unique      => snoop_act_tag_unique(5),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(5),
        snoop_act_done            => snoop_act_done(5),
        snoop_act_use_external    => snoop_act_use_external(5),
        snoop_act_write_blocking  => snoop_act_write_blocking(5),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(5),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(5),
        
        snoop_resp_valid          => snoop_resp_valid(5),
        snoop_resp_crresp         => snoop_resp_crresp(5),
        snoop_resp_ready          => snoop_resp_ready(5),
        
        read_data_ex_rack         => read_data_ex_rack(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(5),
        wr_port_data_last         => wr_port_data_last(5),
        wr_port_data_be           => wr_port_data_be((5+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (5) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((5+1) * C_CACHE_DATA_WIDTH - 1 downto (5) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(5),
        access_bp_early           => access_bp_early(5),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(5),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(5),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(5),
        read_info_full            => read_info_full(5),
        read_data_hit_pop         => read_data_hit_pop(5),
        read_data_hit_almost_full => read_data_hit_almost_full(5),
        read_data_hit_full        => read_data_hit_full(5),
        read_data_hit_fit         => read_data_hit_fit_i(5),
        read_data_miss_full       => read_data_miss_full(5),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(5),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(6 * C_CACHE_DATA_WIDTH - 1 downto 5 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(5),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(5),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(5),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(5),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(5),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(5),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(5),
        stat_s_axi_rip              => stat_s_axi_rip(5),
        stat_s_axi_r                => stat_s_axi_r(5),
        stat_s_axi_bip              => stat_s_axi_bip(5),
        stat_s_axi_bp               => stat_s_axi_bp(5),
        stat_s_axi_wip              => stat_s_axi_wip(5),
        stat_s_axi_w                => stat_s_axi_w(5),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(5),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(5),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(5),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(5),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(5),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF5_DEBUG 
      );
  end generate Use_Port_5;
  
  No_Port_5: if ( C_NUM_OPTIMIZED_PORTS < 6 ) generate
  begin
    S5_AXI_AWREADY        <= '0';
    S5_AXI_WREADY         <= '0';
    S5_AXI_BRESP          <= (others=>'0');
    S5_AXI_BID            <= (others=>'0');
    S5_AXI_BVALID         <= '0';
    S5_AXI_ARREADY        <= '0';
    S5_AXI_RID            <= (others=>'0');
    S5_AXI_RDATA          <= (others=>'0');
    S5_AXI_RRESP          <= (others=>'0');
    S5_AXI_RLAST          <= '0';
    S5_AXI_RVALID         <= '0';
    S5_AXI_ACVALID        <= '0';
    S5_AXI_ACADDR         <= (others=>'0');
    S5_AXI_ACSNOOP        <= (others=>'0');
    S5_AXI_ACPROT         <= (others=>'0');
    S5_AXI_CRREADY        <= '0';
    S5_AXI_CDREADY        <= '0';
    port_assert_error(5)  <= '0';
    OPT_IF5_DEBUG         <= (others=>'0');
  end generate No_Port_5;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #6
  -----------------------------------------------------------------------------
  
  Use_Port_6: if ( C_NUM_OPTIMIZED_PORTS > 6 ) generate
  begin
    AXI_6: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S6_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S6_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S6_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S6_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S6_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S6_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S6_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S6_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S6_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S6_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S6_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S6_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S6_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S6_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S6_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S6_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 6,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S6_AXI_AWID,
        S_AXI_AWADDR              => S6_AXI_AWADDR,
        S_AXI_AWLEN               => S6_AXI_AWLEN,
        S_AXI_AWSIZE              => S6_AXI_AWSIZE,
        S_AXI_AWBURST             => S6_AXI_AWBURST,
        S_AXI_AWLOCK              => S6_AXI_AWLOCK,
        S_AXI_AWCACHE             => S6_AXI_AWCACHE,
        S_AXI_AWPROT              => S6_AXI_AWPROT,
        S_AXI_AWQOS               => S6_AXI_AWQOS,
        S_AXI_AWVALID             => S6_AXI_AWVALID,
        S_AXI_AWREADY             => S6_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S6_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S6_AXI_AWSNOOP,
        S_AXI_AWBAR               => S6_AXI_AWBAR,
        S_AXI_AWUSER              => S6_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S6_AXI_WDATA,
        S_AXI_WSTRB               => S6_AXI_WSTRB,
        S_AXI_WLAST               => S6_AXI_WLAST,
        S_AXI_WVALID              => S6_AXI_WVALID,
        S_AXI_WREADY              => S6_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S6_AXI_BRESP,
        S_AXI_BID                 => S6_AXI_BID,
        S_AXI_BVALID              => S6_AXI_BVALID,
        S_AXI_BREADY              => S6_AXI_BREADY,
        S_AXI_WACK                => S6_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S6_AXI_ARID,
        S_AXI_ARADDR              => S6_AXI_ARADDR,
        S_AXI_ARLEN               => S6_AXI_ARLEN,
        S_AXI_ARSIZE              => S6_AXI_ARSIZE,
        S_AXI_ARBURST             => S6_AXI_ARBURST,
        S_AXI_ARLOCK              => S6_AXI_ARLOCK,
        S_AXI_ARCACHE             => S6_AXI_ARCACHE,
        S_AXI_ARPROT              => S6_AXI_ARPROT,
        S_AXI_ARQOS               => S6_AXI_ARQOS,
        S_AXI_ARVALID             => S6_AXI_ARVALID,
        S_AXI_ARREADY             => S6_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S6_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S6_AXI_ARSNOOP,
        S_AXI_ARBAR               => S6_AXI_ARBAR,
        S_AXI_ARUSER              => S6_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S6_AXI_RID,
        S_AXI_RDATA               => S6_AXI_RDATA,
        S_AXI_RRESP               => S6_AXI_RRESP,
        S_AXI_RLAST               => S6_AXI_RLAST,
        S_AXI_RVALID              => S6_AXI_RVALID,
        S_AXI_RREADY              => S6_AXI_RREADY,
        S_AXI_RACK                => S6_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S6_AXI_ACVALID,
        S_AXI_ACADDR              => S6_AXI_ACADDR,
        S_AXI_ACSNOOP             => S6_AXI_ACSNOOP,
        S_AXI_ACPROT              => S6_AXI_ACPROT,
        S_AXI_ACREADY             => S6_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S6_AXI_CRVALID,
        S_AXI_CRRESP              => S6_AXI_CRRESP,
        S_AXI_CRREADY             => S6_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S6_AXI_CDVALID,
        S_AXI_CDDATA              => S6_AXI_CDDATA,
        S_AXI_CDLAST              => S6_AXI_CDLAST,
        S_AXI_CDREADY             => S6_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(6),
        wr_port_id                => wr_port_id((6+1) * C_ID_WIDTH - 1 downto (6) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(6),
        rd_port_id                => rd_port_id((6+1) * C_ID_WIDTH - 1 downto (6) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(6),
        snoop_fetch_sync          => snoop_fetch_sync(6),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(6),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(6),
        snoop_req_myself          => snoop_req_myself(6),
        snoop_req_always          => snoop_req_always(6),
        snoop_req_update_filter   => snoop_req_update_filter(6),
        snoop_req_want            => snoop_req_want(6),
        snoop_req_complete        => snoop_req_complete(6),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(6),
        snoop_act_myself          => snoop_act_myself(6),
        snoop_act_always          => snoop_act_always(6),
        snoop_act_tag_valid       => snoop_act_tag_valid(6),
        snoop_act_tag_unique      => snoop_act_tag_unique(6),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(6),
        snoop_act_done            => snoop_act_done(6),
        snoop_act_use_external    => snoop_act_use_external(6),
        snoop_act_write_blocking  => snoop_act_write_blocking(6),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(6),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(6),
        
        snoop_resp_valid          => snoop_resp_valid(6),
        snoop_resp_crresp         => snoop_resp_crresp(6),
        snoop_resp_ready          => snoop_resp_ready(6),
        
        read_data_ex_rack         => read_data_ex_rack(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(6),
        wr_port_data_last         => wr_port_data_last(6),
        wr_port_data_be           => wr_port_data_be((6+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (6) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((6+1) * C_CACHE_DATA_WIDTH - 1 downto (6) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(6),
        access_bp_early           => access_bp_early(6),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(6),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(6),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(6),
        read_info_full            => read_info_full(6),
        read_data_hit_pop         => read_data_hit_pop(6),
        read_data_hit_almost_full => read_data_hit_almost_full(6),
        read_data_hit_full        => read_data_hit_full(6),
        read_data_hit_fit         => read_data_hit_fit_i(6),
        read_data_miss_full       => read_data_miss_full(6),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(6),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(7 * C_CACHE_DATA_WIDTH - 1 downto 6 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(6),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(6),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(6),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(6),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(6),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(6),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(6),
        stat_s_axi_rip              => stat_s_axi_rip(6),
        stat_s_axi_r                => stat_s_axi_r(6),
        stat_s_axi_bip              => stat_s_axi_bip(6),
        stat_s_axi_bp               => stat_s_axi_bp(6),
        stat_s_axi_wip              => stat_s_axi_wip(6),
        stat_s_axi_w                => stat_s_axi_w(6),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(6),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(6),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(6),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(6),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(6),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF6_DEBUG 
      );
  end generate Use_Port_6;
  
  No_Port_6: if ( C_NUM_OPTIMIZED_PORTS < 7 ) generate
  begin
    S6_AXI_AWREADY        <= '0';
    S6_AXI_WREADY         <= '0';
    S6_AXI_BRESP          <= (others=>'0');
    S6_AXI_BID            <= (others=>'0');
    S6_AXI_BVALID         <= '0';
    S6_AXI_ARREADY        <= '0';
    S6_AXI_RID            <= (others=>'0');
    S6_AXI_RDATA          <= (others=>'0');
    S6_AXI_RRESP          <= (others=>'0');
    S6_AXI_RLAST          <= '0';
    S6_AXI_RVALID         <= '0';
    S6_AXI_ACVALID        <= '0';
    S6_AXI_ACADDR         <= (others=>'0');
    S6_AXI_ACSNOOP        <= (others=>'0');
    S6_AXI_ACPROT         <= (others=>'0');
    S6_AXI_CRREADY        <= '0';
    S6_AXI_CDREADY        <= '0';
    port_assert_error(6)  <= '0';
    OPT_IF6_DEBUG         <= (others=>'0');
  end generate No_Port_6;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #7
  -----------------------------------------------------------------------------
  
  Use_Port_7: if ( C_NUM_OPTIMIZED_PORTS > 7 ) generate
  begin
    AXI_7: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S7_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S7_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S7_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S7_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S7_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S7_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S7_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S7_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S7_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S7_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S7_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S7_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S7_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S7_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S7_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S7_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 7,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S7_AXI_AWID,
        S_AXI_AWADDR              => S7_AXI_AWADDR,
        S_AXI_AWLEN               => S7_AXI_AWLEN,
        S_AXI_AWSIZE              => S7_AXI_AWSIZE,
        S_AXI_AWBURST             => S7_AXI_AWBURST,
        S_AXI_AWLOCK              => S7_AXI_AWLOCK,
        S_AXI_AWCACHE             => S7_AXI_AWCACHE,
        S_AXI_AWPROT              => S7_AXI_AWPROT,
        S_AXI_AWQOS               => S7_AXI_AWQOS,
        S_AXI_AWVALID             => S7_AXI_AWVALID,
        S_AXI_AWREADY             => S7_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S7_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S7_AXI_AWSNOOP,
        S_AXI_AWBAR               => S7_AXI_AWBAR,
        S_AXI_AWUSER              => S7_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S7_AXI_WDATA,
        S_AXI_WSTRB               => S7_AXI_WSTRB,
        S_AXI_WLAST               => S7_AXI_WLAST,
        S_AXI_WVALID              => S7_AXI_WVALID,
        S_AXI_WREADY              => S7_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S7_AXI_BRESP,
        S_AXI_BID                 => S7_AXI_BID,
        S_AXI_BVALID              => S7_AXI_BVALID,
        S_AXI_BREADY              => S7_AXI_BREADY,
        S_AXI_WACK                => S7_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S7_AXI_ARID,
        S_AXI_ARADDR              => S7_AXI_ARADDR,
        S_AXI_ARLEN               => S7_AXI_ARLEN,
        S_AXI_ARSIZE              => S7_AXI_ARSIZE,
        S_AXI_ARBURST             => S7_AXI_ARBURST,
        S_AXI_ARLOCK              => S7_AXI_ARLOCK,
        S_AXI_ARCACHE             => S7_AXI_ARCACHE,
        S_AXI_ARPROT              => S7_AXI_ARPROT,
        S_AXI_ARQOS               => S7_AXI_ARQOS,
        S_AXI_ARVALID             => S7_AXI_ARVALID,
        S_AXI_ARREADY             => S7_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S7_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S7_AXI_ARSNOOP,
        S_AXI_ARBAR               => S7_AXI_ARBAR,
        S_AXI_ARUSER              => S7_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S7_AXI_RID,
        S_AXI_RDATA               => S7_AXI_RDATA,
        S_AXI_RRESP               => S7_AXI_RRESP,
        S_AXI_RLAST               => S7_AXI_RLAST,
        S_AXI_RVALID              => S7_AXI_RVALID,
        S_AXI_RREADY              => S7_AXI_RREADY,
        S_AXI_RACK                => S7_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S7_AXI_ACVALID,
        S_AXI_ACADDR              => S7_AXI_ACADDR,
        S_AXI_ACSNOOP             => S7_AXI_ACSNOOP,
        S_AXI_ACPROT              => S7_AXI_ACPROT,
        S_AXI_ACREADY             => S7_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S7_AXI_CRVALID,
        S_AXI_CRRESP              => S7_AXI_CRRESP,
        S_AXI_CRREADY             => S7_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S7_AXI_CDVALID,
        S_AXI_CDDATA              => S7_AXI_CDDATA,
        S_AXI_CDLAST              => S7_AXI_CDLAST,
        S_AXI_CDREADY             => S7_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(7),
        wr_port_id                => wr_port_id((7+1) * C_ID_WIDTH - 1 downto (7) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(7),
        rd_port_id                => rd_port_id((7+1) * C_ID_WIDTH - 1 downto (7) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(7),
        snoop_fetch_sync          => snoop_fetch_sync(7),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(7),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(7),
        snoop_req_myself          => snoop_req_myself(7),
        snoop_req_always          => snoop_req_always(7),
        snoop_req_update_filter   => snoop_req_update_filter(7),
        snoop_req_want            => snoop_req_want(7),
        snoop_req_complete        => snoop_req_complete(7),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(7),
        snoop_act_myself          => snoop_act_myself(7),
        snoop_act_always          => snoop_act_always(7),
        snoop_act_tag_valid       => snoop_act_tag_valid(7),
        snoop_act_tag_unique      => snoop_act_tag_unique(7),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(7),
        snoop_act_done            => snoop_act_done(7),
        snoop_act_use_external    => snoop_act_use_external(7),
        snoop_act_write_blocking  => snoop_act_write_blocking(7),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(7),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(7),
        
        snoop_resp_valid          => snoop_resp_valid(7),
        snoop_resp_crresp         => snoop_resp_crresp(7),
        snoop_resp_ready          => snoop_resp_ready(7),
        
        read_data_ex_rack         => read_data_ex_rack(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(7),
        wr_port_data_last         => wr_port_data_last(7),
        wr_port_data_be           => wr_port_data_be((7+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (7) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((7+1) * C_CACHE_DATA_WIDTH - 1 downto (7) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(7),
        access_bp_early           => access_bp_early(7),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(7),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(7),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(7),
        read_info_full            => read_info_full(7),
        read_data_hit_pop         => read_data_hit_pop(7),
        read_data_hit_almost_full => read_data_hit_almost_full(7),
        read_data_hit_full        => read_data_hit_full(7),
        read_data_hit_fit         => read_data_hit_fit_i(7),
        read_data_miss_full       => read_data_miss_full(7),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(7),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(8 * C_CACHE_DATA_WIDTH - 1 downto 7 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(7),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(7),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(7),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(7),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(7),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(7),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(7),
        stat_s_axi_rip              => stat_s_axi_rip(7),
        stat_s_axi_r                => stat_s_axi_r(7),
        stat_s_axi_bip              => stat_s_axi_bip(7),
        stat_s_axi_bp               => stat_s_axi_bp(7),
        stat_s_axi_wip              => stat_s_axi_wip(7),
        stat_s_axi_w                => stat_s_axi_w(7),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(7),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(7),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(7),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(7),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(7),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF7_DEBUG 
      );
  end generate Use_Port_7;
  
  No_Port_7: if ( C_NUM_OPTIMIZED_PORTS < 8 ) generate
  begin
    S7_AXI_AWREADY        <= '0';
    S7_AXI_WREADY         <= '0';
    S7_AXI_BRESP          <= (others=>'0');
    S7_AXI_BID            <= (others=>'0');
    S7_AXI_BVALID         <= '0';
    S7_AXI_ARREADY        <= '0';
    S7_AXI_RID            <= (others=>'0');
    S7_AXI_RDATA          <= (others=>'0');
    S7_AXI_RRESP          <= (others=>'0');
    S7_AXI_RLAST          <= '0';
    S7_AXI_RVALID         <= '0';
    S7_AXI_ACVALID        <= '0';
    S7_AXI_ACADDR         <= (others=>'0');
    S7_AXI_ACSNOOP        <= (others=>'0');
    S7_AXI_ACPROT         <= (others=>'0');
    S7_AXI_CRREADY        <= '0';
    S7_AXI_CDREADY        <= '0';
    port_assert_error(7)  <= '0';
    OPT_IF7_DEBUG         <= (others=>'0');
  end generate No_Port_7;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #8
  -----------------------------------------------------------------------------
  
  Use_Port_8: if ( C_NUM_OPTIMIZED_PORTS > 8 ) generate
  begin
    AXI_8: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S8_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S8_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S8_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S8_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S8_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S8_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S8_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S8_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S8_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S8_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S8_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S8_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S8_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S8_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S8_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S8_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 8,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S8_AXI_AWID,
        S_AXI_AWADDR              => S8_AXI_AWADDR,
        S_AXI_AWLEN               => S8_AXI_AWLEN,
        S_AXI_AWSIZE              => S8_AXI_AWSIZE,
        S_AXI_AWBURST             => S8_AXI_AWBURST,
        S_AXI_AWLOCK              => S8_AXI_AWLOCK,
        S_AXI_AWCACHE             => S8_AXI_AWCACHE,
        S_AXI_AWPROT              => S8_AXI_AWPROT,
        S_AXI_AWQOS               => S8_AXI_AWQOS,
        S_AXI_AWVALID             => S8_AXI_AWVALID,
        S_AXI_AWREADY             => S8_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S8_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S8_AXI_AWSNOOP,
        S_AXI_AWBAR               => S8_AXI_AWBAR,
        S_AXI_AWUSER              => S8_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S8_AXI_WDATA,
        S_AXI_WSTRB               => S8_AXI_WSTRB,
        S_AXI_WLAST               => S8_AXI_WLAST,
        S_AXI_WVALID              => S8_AXI_WVALID,
        S_AXI_WREADY              => S8_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S8_AXI_BRESP,
        S_AXI_BID                 => S8_AXI_BID,
        S_AXI_BVALID              => S8_AXI_BVALID,
        S_AXI_BREADY              => S8_AXI_BREADY,
        S_AXI_WACK                => S8_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S8_AXI_ARID,
        S_AXI_ARADDR              => S8_AXI_ARADDR,
        S_AXI_ARLEN               => S8_AXI_ARLEN,
        S_AXI_ARSIZE              => S8_AXI_ARSIZE,
        S_AXI_ARBURST             => S8_AXI_ARBURST,
        S_AXI_ARLOCK              => S8_AXI_ARLOCK,
        S_AXI_ARCACHE             => S8_AXI_ARCACHE,
        S_AXI_ARPROT              => S8_AXI_ARPROT,
        S_AXI_ARQOS               => S8_AXI_ARQOS,
        S_AXI_ARVALID             => S8_AXI_ARVALID,
        S_AXI_ARREADY             => S8_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S8_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S8_AXI_ARSNOOP,
        S_AXI_ARBAR               => S8_AXI_ARBAR,
        S_AXI_ARUSER              => S8_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S8_AXI_RID,
        S_AXI_RDATA               => S8_AXI_RDATA,
        S_AXI_RRESP               => S8_AXI_RRESP,
        S_AXI_RLAST               => S8_AXI_RLAST,
        S_AXI_RVALID              => S8_AXI_RVALID,
        S_AXI_RREADY              => S8_AXI_RREADY,
        S_AXI_RACK                => S8_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S8_AXI_ACVALID,
        S_AXI_ACADDR              => S8_AXI_ACADDR,
        S_AXI_ACSNOOP             => S8_AXI_ACSNOOP,
        S_AXI_ACPROT              => S8_AXI_ACPROT,
        S_AXI_ACREADY             => S8_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S8_AXI_CRVALID,
        S_AXI_CRRESP              => S8_AXI_CRRESP,
        S_AXI_CRREADY             => S8_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S8_AXI_CDVALID,
        S_AXI_CDDATA              => S8_AXI_CDDATA,
        S_AXI_CDLAST              => S8_AXI_CDLAST,
        S_AXI_CDREADY             => S8_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(8),
        wr_port_id                => wr_port_id((8+1) * C_ID_WIDTH - 1 downto (8) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(8),
        rd_port_id                => rd_port_id((8+1) * C_ID_WIDTH - 1 downto (8) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(8),
        snoop_fetch_sync          => snoop_fetch_sync(8),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(8),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(8),
        snoop_req_myself          => snoop_req_myself(8),
        snoop_req_always          => snoop_req_always(8),
        snoop_req_update_filter   => snoop_req_update_filter(8),
        snoop_req_want            => snoop_req_want(8),
        snoop_req_complete        => snoop_req_complete(8),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(8),
        snoop_act_myself          => snoop_act_myself(8),
        snoop_act_always          => snoop_act_always(8),
        snoop_act_tag_valid       => snoop_act_tag_valid(8),
        snoop_act_tag_unique      => snoop_act_tag_unique(8),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(8),
        snoop_act_done            => snoop_act_done(8),
        snoop_act_use_external    => snoop_act_use_external(8),
        snoop_act_write_blocking  => snoop_act_write_blocking(8),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(8),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(8),
        
        snoop_resp_valid          => snoop_resp_valid(8),
        snoop_resp_crresp         => snoop_resp_crresp(8),
        snoop_resp_ready          => snoop_resp_ready(8),
        
        read_data_ex_rack         => read_data_ex_rack(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(8),
        wr_port_data_last         => wr_port_data_last(8),
        wr_port_data_be           => wr_port_data_be((8+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (8) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((8+1) * C_CACHE_DATA_WIDTH - 1 downto (8) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(8),
        access_bp_early           => access_bp_early(8),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(8),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(8),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(8),
        read_info_full            => read_info_full(8),
        read_data_hit_pop         => read_data_hit_pop(8),
        read_data_hit_almost_full => read_data_hit_almost_full(8),
        read_data_hit_full        => read_data_hit_full(8),
        read_data_hit_fit         => read_data_hit_fit_i(8),
        read_data_miss_full       => read_data_miss_full(8),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(8),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(9 * C_CACHE_DATA_WIDTH - 1 downto 8 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(8),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(8),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(8),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(8),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(8),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(8),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(8),
        stat_s_axi_rip              => stat_s_axi_rip(8),
        stat_s_axi_r                => stat_s_axi_r(8),
        stat_s_axi_bip              => stat_s_axi_bip(8),
        stat_s_axi_bp               => stat_s_axi_bp(8),
        stat_s_axi_wip              => stat_s_axi_wip(8),
        stat_s_axi_w                => stat_s_axi_w(8),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(8),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(8),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(8),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(8),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(8),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF8_DEBUG 
      );
  end generate Use_Port_8;
  
  No_Port_8: if ( C_NUM_OPTIMIZED_PORTS < 9 ) generate
  begin
    S8_AXI_AWREADY        <= '0';
    S8_AXI_WREADY         <= '0';
    S8_AXI_BRESP          <= (others=>'0');
    S8_AXI_BID            <= (others=>'0');
    S8_AXI_BVALID         <= '0';
    S8_AXI_ARREADY        <= '0';
    S8_AXI_RID            <= (others=>'0');
    S8_AXI_RDATA          <= (others=>'0');
    S8_AXI_RRESP          <= (others=>'0');
    S8_AXI_RLAST          <= '0';
    S8_AXI_RVALID         <= '0';
    S8_AXI_ACVALID        <= '0';
    S8_AXI_ACADDR         <= (others=>'0');
    S8_AXI_ACSNOOP        <= (others=>'0');
    S8_AXI_ACPROT         <= (others=>'0');
    S8_AXI_CRREADY        <= '0';
    S8_AXI_CDREADY        <= '0';
    port_assert_error(8)  <= '0';
    OPT_IF8_DEBUG         <= (others=>'0');
  end generate No_Port_8;
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #9
  -----------------------------------------------------------------------------
  
  Use_Port_9: if ( C_NUM_OPTIMIZED_PORTS > 9 ) generate
  begin
    AXI_9: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S9_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S9_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S9_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S9_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S9_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S9_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S9_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S9_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S9_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S9_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S9_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S9_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S9_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S9_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S9_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S9_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 9,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S9_AXI_AWID,
        S_AXI_AWADDR              => S9_AXI_AWADDR,
        S_AXI_AWLEN               => S9_AXI_AWLEN,
        S_AXI_AWSIZE              => S9_AXI_AWSIZE,
        S_AXI_AWBURST             => S9_AXI_AWBURST,
        S_AXI_AWLOCK              => S9_AXI_AWLOCK,
        S_AXI_AWCACHE             => S9_AXI_AWCACHE,
        S_AXI_AWPROT              => S9_AXI_AWPROT,
        S_AXI_AWQOS               => S9_AXI_AWQOS,
        S_AXI_AWVALID             => S9_AXI_AWVALID,
        S_AXI_AWREADY             => S9_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S9_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S9_AXI_AWSNOOP,
        S_AXI_AWBAR               => S9_AXI_AWBAR,
        S_AXI_AWUSER              => S9_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S9_AXI_WDATA,
        S_AXI_WSTRB               => S9_AXI_WSTRB,
        S_AXI_WLAST               => S9_AXI_WLAST,
        S_AXI_WVALID              => S9_AXI_WVALID,
        S_AXI_WREADY              => S9_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S9_AXI_BRESP,
        S_AXI_BID                 => S9_AXI_BID,
        S_AXI_BVALID              => S9_AXI_BVALID,
        S_AXI_BREADY              => S9_AXI_BREADY,
        S_AXI_WACK                => S9_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S9_AXI_ARID,
        S_AXI_ARADDR              => S9_AXI_ARADDR,
        S_AXI_ARLEN               => S9_AXI_ARLEN,
        S_AXI_ARSIZE              => S9_AXI_ARSIZE,
        S_AXI_ARBURST             => S9_AXI_ARBURST,
        S_AXI_ARLOCK              => S9_AXI_ARLOCK,
        S_AXI_ARCACHE             => S9_AXI_ARCACHE,
        S_AXI_ARPROT              => S9_AXI_ARPROT,
        S_AXI_ARQOS               => S9_AXI_ARQOS,
        S_AXI_ARVALID             => S9_AXI_ARVALID,
        S_AXI_ARREADY             => S9_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S9_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S9_AXI_ARSNOOP,
        S_AXI_ARBAR               => S9_AXI_ARBAR,
        S_AXI_ARUSER              => S9_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S9_AXI_RID,
        S_AXI_RDATA               => S9_AXI_RDATA,
        S_AXI_RRESP               => S9_AXI_RRESP,
        S_AXI_RLAST               => S9_AXI_RLAST,
        S_AXI_RVALID              => S9_AXI_RVALID,
        S_AXI_RREADY              => S9_AXI_RREADY,
        S_AXI_RACK                => S9_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S9_AXI_ACVALID,
        S_AXI_ACADDR              => S9_AXI_ACADDR,
        S_AXI_ACSNOOP             => S9_AXI_ACSNOOP,
        S_AXI_ACPROT              => S9_AXI_ACPROT,
        S_AXI_ACREADY             => S9_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S9_AXI_CRVALID,
        S_AXI_CRRESP              => S9_AXI_CRRESP,
        S_AXI_CRREADY             => S9_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S9_AXI_CDVALID,
        S_AXI_CDDATA              => S9_AXI_CDDATA,
        S_AXI_CDLAST              => S9_AXI_CDLAST,
        S_AXI_CDREADY             => S9_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(9),
        wr_port_id                => wr_port_id((9+1) * C_ID_WIDTH - 1 downto (9) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(9),
        rd_port_id                => rd_port_id((9+1) * C_ID_WIDTH - 1 downto (9) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(9),
        snoop_fetch_sync          => snoop_fetch_sync(9),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(9),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(9),
        snoop_req_myself          => snoop_req_myself(9),
        snoop_req_always          => snoop_req_always(9),
        snoop_req_update_filter   => snoop_req_update_filter(9),
        snoop_req_want            => snoop_req_want(9),
        snoop_req_complete        => snoop_req_complete(9),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(9),
        snoop_act_myself          => snoop_act_myself(9),
        snoop_act_always          => snoop_act_always(9),
        snoop_act_tag_valid       => snoop_act_tag_valid(9),
        snoop_act_tag_unique      => snoop_act_tag_unique(9),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(9),
        snoop_act_done            => snoop_act_done(9),
        snoop_act_use_external    => snoop_act_use_external(9),
        snoop_act_write_blocking  => snoop_act_write_blocking(9),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(9),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(9),
        
        snoop_resp_valid          => snoop_resp_valid(9),
        snoop_resp_crresp         => snoop_resp_crresp(9),
        snoop_resp_ready          => snoop_resp_ready(9),
        
        read_data_ex_rack         => read_data_ex_rack(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(9),
        wr_port_data_last         => wr_port_data_last(9),
        wr_port_data_be           => wr_port_data_be((9+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (9) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((9+1) * C_CACHE_DATA_WIDTH - 1 downto (9) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(9),
        access_bp_early           => access_bp_early(9),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(9),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(9),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(9),
        read_info_full            => read_info_full(9),
        read_data_hit_pop         => read_data_hit_pop(9),
        read_data_hit_almost_full => read_data_hit_almost_full(9),
        read_data_hit_full        => read_data_hit_full(9),
        read_data_hit_fit         => read_data_hit_fit_i(9),
        read_data_miss_full       => read_data_miss_full(9),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(9),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(10 * C_CACHE_DATA_WIDTH - 1 downto 9 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(9),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(9),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(9),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(9),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(9),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(9),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(9),
        stat_s_axi_rip              => stat_s_axi_rip(9),
        stat_s_axi_r                => stat_s_axi_r(9),
        stat_s_axi_bip              => stat_s_axi_bip(9),
        stat_s_axi_bp               => stat_s_axi_bp(9),
        stat_s_axi_wip              => stat_s_axi_wip(9),
        stat_s_axi_w                => stat_s_axi_w(9),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(9),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(9),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(9),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(9),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(9),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF9_DEBUG 
      );
  end generate Use_Port_9;
  
  No_Port_9: if ( C_NUM_OPTIMIZED_PORTS < 10 ) generate
  begin
    S9_AXI_AWREADY        <= '0';
    S9_AXI_WREADY         <= '0';
    S9_AXI_BRESP          <= (others=>'0');
    S9_AXI_BID            <= (others=>'0');
    S9_AXI_BVALID         <= '0';
    S9_AXI_ARREADY        <= '0';
    S9_AXI_RID            <= (others=>'0');
    S9_AXI_RDATA          <= (others=>'0');
    S9_AXI_RRESP          <= (others=>'0');
    S9_AXI_RLAST          <= '0';
    S9_AXI_RVALID         <= '0';
    S9_AXI_ACVALID        <= '0';
    S9_AXI_ACADDR         <= (others=>'0');
    S9_AXI_ACSNOOP        <= (others=>'0');
    S9_AXI_ACPROT         <= (others=>'0');
    S9_AXI_CRREADY        <= '0';
    S9_AXI_CDREADY        <= '0';
    port_assert_error(9)  <= '0';
    OPT_IF9_DEBUG         <= (others=>'0');
  end generate No_Port_9;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #10
  -----------------------------------------------------------------------------
  
  Use_Port_10: if ( C_NUM_OPTIMIZED_PORTS > 10 ) generate
  begin
    AXI_10: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S10_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S10_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S10_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S10_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S10_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S10_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S10_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S10_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S10_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S10_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S10_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S10_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S10_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S10_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S10_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S10_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 10,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S10_AXI_AWID,
        S_AXI_AWADDR              => S10_AXI_AWADDR,
        S_AXI_AWLEN               => S10_AXI_AWLEN,
        S_AXI_AWSIZE              => S10_AXI_AWSIZE,
        S_AXI_AWBURST             => S10_AXI_AWBURST,
        S_AXI_AWLOCK              => S10_AXI_AWLOCK,
        S_AXI_AWCACHE             => S10_AXI_AWCACHE,
        S_AXI_AWPROT              => S10_AXI_AWPROT,
        S_AXI_AWQOS               => S10_AXI_AWQOS,
        S_AXI_AWVALID             => S10_AXI_AWVALID,
        S_AXI_AWREADY             => S10_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S10_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S10_AXI_AWSNOOP,
        S_AXI_AWBAR               => S10_AXI_AWBAR,
        S_AXI_AWUSER              => S10_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S10_AXI_WDATA,
        S_AXI_WSTRB               => S10_AXI_WSTRB,
        S_AXI_WLAST               => S10_AXI_WLAST,
        S_AXI_WVALID              => S10_AXI_WVALID,
        S_AXI_WREADY              => S10_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S10_AXI_BRESP,
        S_AXI_BID                 => S10_AXI_BID,
        S_AXI_BVALID              => S10_AXI_BVALID,
        S_AXI_BREADY              => S10_AXI_BREADY,
        S_AXI_WACK                => S10_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S10_AXI_ARID,
        S_AXI_ARADDR              => S10_AXI_ARADDR,
        S_AXI_ARLEN               => S10_AXI_ARLEN,
        S_AXI_ARSIZE              => S10_AXI_ARSIZE,
        S_AXI_ARBURST             => S10_AXI_ARBURST,
        S_AXI_ARLOCK              => S10_AXI_ARLOCK,
        S_AXI_ARCACHE             => S10_AXI_ARCACHE,
        S_AXI_ARPROT              => S10_AXI_ARPROT,
        S_AXI_ARQOS               => S10_AXI_ARQOS,
        S_AXI_ARVALID             => S10_AXI_ARVALID,
        S_AXI_ARREADY             => S10_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S10_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S10_AXI_ARSNOOP,
        S_AXI_ARBAR               => S10_AXI_ARBAR,
        S_AXI_ARUSER              => S10_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S10_AXI_RID,
        S_AXI_RDATA               => S10_AXI_RDATA,
        S_AXI_RRESP               => S10_AXI_RRESP,
        S_AXI_RLAST               => S10_AXI_RLAST,
        S_AXI_RVALID              => S10_AXI_RVALID,
        S_AXI_RREADY              => S10_AXI_RREADY,
        S_AXI_RACK                => S10_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S10_AXI_ACVALID,
        S_AXI_ACADDR              => S10_AXI_ACADDR,
        S_AXI_ACSNOOP             => S10_AXI_ACSNOOP,
        S_AXI_ACPROT              => S10_AXI_ACPROT,
        S_AXI_ACREADY             => S10_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S10_AXI_CRVALID,
        S_AXI_CRRESP              => S10_AXI_CRRESP,
        S_AXI_CRREADY             => S10_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S10_AXI_CDVALID,
        S_AXI_CDDATA              => S10_AXI_CDDATA,
        S_AXI_CDLAST              => S10_AXI_CDLAST,
        S_AXI_CDREADY             => S10_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(10),
        wr_port_id                => wr_port_id((10+1) * C_ID_WIDTH - 1 downto (10) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(10),
        rd_port_id                => rd_port_id((10+1) * C_ID_WIDTH - 1 downto (10) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(10),
        snoop_fetch_sync          => snoop_fetch_sync(10),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(10),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(10),
        snoop_req_myself          => snoop_req_myself(10),
        snoop_req_always          => snoop_req_always(10),
        snoop_req_update_filter   => snoop_req_update_filter(10),
        snoop_req_want            => snoop_req_want(10),
        snoop_req_complete        => snoop_req_complete(10),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(10),
        snoop_act_myself          => snoop_act_myself(10),
        snoop_act_always          => snoop_act_always(10),
        snoop_act_tag_valid       => snoop_act_tag_valid(10),
        snoop_act_tag_unique      => snoop_act_tag_unique(10),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(10),
        snoop_act_done            => snoop_act_done(10),
        snoop_act_use_external    => snoop_act_use_external(10),
        snoop_act_write_blocking  => snoop_act_write_blocking(10),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(10),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(10),
        
        snoop_resp_valid          => snoop_resp_valid(10),
        snoop_resp_crresp         => snoop_resp_crresp(10),
        snoop_resp_ready          => snoop_resp_ready(10),
        
        read_data_ex_rack         => read_data_ex_rack(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(10),
        wr_port_data_last         => wr_port_data_last(10),
        wr_port_data_be           => wr_port_data_be((10+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (10) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((10+1) * C_CACHE_DATA_WIDTH - 1 downto (10) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(10),
        access_bp_early           => access_bp_early(10),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(10),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(10),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(10),
        read_info_full            => read_info_full(10),
        read_data_hit_pop         => read_data_hit_pop(10),
        read_data_hit_almost_full => read_data_hit_almost_full(10),
        read_data_hit_full        => read_data_hit_full(10),
        read_data_hit_fit         => read_data_hit_fit_i(10),
        read_data_miss_full       => read_data_miss_full(10),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(10),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(11 * C_CACHE_DATA_WIDTH - 1 downto 10 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(10),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(10),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(10),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(10),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(10),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(10),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(10),
        stat_s_axi_rip              => stat_s_axi_rip(10),
        stat_s_axi_r                => stat_s_axi_r(10),
        stat_s_axi_bip              => stat_s_axi_bip(10),
        stat_s_axi_bp               => stat_s_axi_bp(10),
        stat_s_axi_wip              => stat_s_axi_wip(10),
        stat_s_axi_w                => stat_s_axi_w(10),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(10),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(10),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(10),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(10),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(10),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF10_DEBUG 
      );
  end generate Use_Port_10;
  
  No_Port_10: if ( C_NUM_OPTIMIZED_PORTS < 11 ) generate
  begin
    S10_AXI_AWREADY        <= '0';
    S10_AXI_WREADY         <= '0';
    S10_AXI_BRESP          <= (others=>'0');
    S10_AXI_BID            <= (others=>'0');
    S10_AXI_BVALID         <= '0';
    S10_AXI_ARREADY        <= '0';
    S10_AXI_RID            <= (others=>'0');
    S10_AXI_RDATA          <= (others=>'0');
    S10_AXI_RRESP          <= (others=>'0');
    S10_AXI_RLAST          <= '0';
    S10_AXI_RVALID         <= '0';
    S10_AXI_ACVALID        <= '0';
    S10_AXI_ACADDR         <= (others=>'0');
    S10_AXI_ACSNOOP        <= (others=>'0');
    S10_AXI_ACPROT         <= (others=>'0');
    S10_AXI_CRREADY        <= '0';
    S10_AXI_CDREADY        <= '0';
    port_assert_error(10)  <= '0';
    OPT_IF10_DEBUG         <= (others=>'0');
  end generate No_Port_10;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #11
  -----------------------------------------------------------------------------
  
  Use_Port_11: if ( C_NUM_OPTIMIZED_PORTS > 11 ) generate
  begin
    AXI_11: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S11_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S11_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S11_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S11_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S11_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S11_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S11_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S11_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S11_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S11_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S11_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S11_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S11_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S11_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S11_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S11_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 11,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S11_AXI_AWID,
        S_AXI_AWADDR              => S11_AXI_AWADDR,
        S_AXI_AWLEN               => S11_AXI_AWLEN,
        S_AXI_AWSIZE              => S11_AXI_AWSIZE,
        S_AXI_AWBURST             => S11_AXI_AWBURST,
        S_AXI_AWLOCK              => S11_AXI_AWLOCK,
        S_AXI_AWCACHE             => S11_AXI_AWCACHE,
        S_AXI_AWPROT              => S11_AXI_AWPROT,
        S_AXI_AWQOS               => S11_AXI_AWQOS,
        S_AXI_AWVALID             => S11_AXI_AWVALID,
        S_AXI_AWREADY             => S11_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S11_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S11_AXI_AWSNOOP,
        S_AXI_AWBAR               => S11_AXI_AWBAR,
        S_AXI_AWUSER              => S11_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S11_AXI_WDATA,
        S_AXI_WSTRB               => S11_AXI_WSTRB,
        S_AXI_WLAST               => S11_AXI_WLAST,
        S_AXI_WVALID              => S11_AXI_WVALID,
        S_AXI_WREADY              => S11_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S11_AXI_BRESP,
        S_AXI_BID                 => S11_AXI_BID,
        S_AXI_BVALID              => S11_AXI_BVALID,
        S_AXI_BREADY              => S11_AXI_BREADY,
        S_AXI_WACK                => S11_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S11_AXI_ARID,
        S_AXI_ARADDR              => S11_AXI_ARADDR,
        S_AXI_ARLEN               => S11_AXI_ARLEN,
        S_AXI_ARSIZE              => S11_AXI_ARSIZE,
        S_AXI_ARBURST             => S11_AXI_ARBURST,
        S_AXI_ARLOCK              => S11_AXI_ARLOCK,
        S_AXI_ARCACHE             => S11_AXI_ARCACHE,
        S_AXI_ARPROT              => S11_AXI_ARPROT,
        S_AXI_ARQOS               => S11_AXI_ARQOS,
        S_AXI_ARVALID             => S11_AXI_ARVALID,
        S_AXI_ARREADY             => S11_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S11_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S11_AXI_ARSNOOP,
        S_AXI_ARBAR               => S11_AXI_ARBAR,
        S_AXI_ARUSER              => S11_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S11_AXI_RID,
        S_AXI_RDATA               => S11_AXI_RDATA,
        S_AXI_RRESP               => S11_AXI_RRESP,
        S_AXI_RLAST               => S11_AXI_RLAST,
        S_AXI_RVALID              => S11_AXI_RVALID,
        S_AXI_RREADY              => S11_AXI_RREADY,
        S_AXI_RACK                => S11_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S11_AXI_ACVALID,
        S_AXI_ACADDR              => S11_AXI_ACADDR,
        S_AXI_ACSNOOP             => S11_AXI_ACSNOOP,
        S_AXI_ACPROT              => S11_AXI_ACPROT,
        S_AXI_ACREADY             => S11_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S11_AXI_CRVALID,
        S_AXI_CRRESP              => S11_AXI_CRRESP,
        S_AXI_CRREADY             => S11_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S11_AXI_CDVALID,
        S_AXI_CDDATA              => S11_AXI_CDDATA,
        S_AXI_CDLAST              => S11_AXI_CDLAST,
        S_AXI_CDREADY             => S11_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(11),
        wr_port_id                => wr_port_id((11+1) * C_ID_WIDTH - 1 downto (11) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(11),
        rd_port_id                => rd_port_id((11+1) * C_ID_WIDTH - 1 downto (11) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(11),
        snoop_fetch_sync          => snoop_fetch_sync(11),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(11),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(11),
        snoop_req_myself          => snoop_req_myself(11),
        snoop_req_always          => snoop_req_always(11),
        snoop_req_update_filter   => snoop_req_update_filter(11),
        snoop_req_want            => snoop_req_want(11),
        snoop_req_complete        => snoop_req_complete(11),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(11),
        snoop_act_myself          => snoop_act_myself(11),
        snoop_act_always          => snoop_act_always(11),
        snoop_act_tag_valid       => snoop_act_tag_valid(11),
        snoop_act_tag_unique      => snoop_act_tag_unique(11),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(11),
        snoop_act_done            => snoop_act_done(11),
        snoop_act_use_external    => snoop_act_use_external(11),
        snoop_act_write_blocking  => snoop_act_write_blocking(11),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(11),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(11),
        
        snoop_resp_valid          => snoop_resp_valid(11),
        snoop_resp_crresp         => snoop_resp_crresp(11),
        snoop_resp_ready          => snoop_resp_ready(11),
        
        read_data_ex_rack         => read_data_ex_rack(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(11),
        wr_port_data_last         => wr_port_data_last(11),
        wr_port_data_be           => wr_port_data_be((11+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (11) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((11+1) * C_CACHE_DATA_WIDTH - 1 downto (11) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(11),
        access_bp_early           => access_bp_early(11),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(11),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(11),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(11),
        read_info_full            => read_info_full(11),
        read_data_hit_pop         => read_data_hit_pop(11),
        read_data_hit_almost_full => read_data_hit_almost_full(11),
        read_data_hit_full        => read_data_hit_full(11),
        read_data_hit_fit         => read_data_hit_fit_i(11),
        read_data_miss_full       => read_data_miss_full(11),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(11),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(12 * C_CACHE_DATA_WIDTH - 1 downto 11 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(11),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(11),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(11),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(11),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(11),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(11),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(11),
        stat_s_axi_rip              => stat_s_axi_rip(11),
        stat_s_axi_r                => stat_s_axi_r(11),
        stat_s_axi_bip              => stat_s_axi_bip(11),
        stat_s_axi_bp               => stat_s_axi_bp(11),
        stat_s_axi_wip              => stat_s_axi_wip(11),
        stat_s_axi_w                => stat_s_axi_w(11),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(11),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(11),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(11),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(11),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(11),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF11_DEBUG 
      );
  end generate Use_Port_11;
  
  No_Port_11: if ( C_NUM_OPTIMIZED_PORTS < 12 ) generate
  begin
    S11_AXI_AWREADY        <= '0';
    S11_AXI_WREADY         <= '0';
    S11_AXI_BRESP          <= (others=>'0');
    S11_AXI_BID            <= (others=>'0');
    S11_AXI_BVALID         <= '0';
    S11_AXI_ARREADY        <= '0';
    S11_AXI_RID            <= (others=>'0');
    S11_AXI_RDATA          <= (others=>'0');
    S11_AXI_RRESP          <= (others=>'0');
    S11_AXI_RLAST          <= '0';
    S11_AXI_RVALID         <= '0';
    S11_AXI_ACVALID        <= '0';
    S11_AXI_ACADDR         <= (others=>'0');
    S11_AXI_ACSNOOP        <= (others=>'0');
    S11_AXI_ACPROT         <= (others=>'0');
    S11_AXI_CRREADY        <= '0';
    S11_AXI_CDREADY        <= '0';
    port_assert_error(11)  <= '0';
    OPT_IF11_DEBUG         <= (others=>'0');
  end generate No_Port_11;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #12
  -----------------------------------------------------------------------------
  
  Use_Port_12: if ( C_NUM_OPTIMIZED_PORTS > 12 ) generate
  begin
    AXI_12: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S12_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S12_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S12_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S12_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S12_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S12_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S12_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S12_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S12_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S12_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S12_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S12_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S12_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S12_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S12_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S12_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 12,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S12_AXI_AWID,
        S_AXI_AWADDR              => S12_AXI_AWADDR,
        S_AXI_AWLEN               => S12_AXI_AWLEN,
        S_AXI_AWSIZE              => S12_AXI_AWSIZE,
        S_AXI_AWBURST             => S12_AXI_AWBURST,
        S_AXI_AWLOCK              => S12_AXI_AWLOCK,
        S_AXI_AWCACHE             => S12_AXI_AWCACHE,
        S_AXI_AWPROT              => S12_AXI_AWPROT,
        S_AXI_AWQOS               => S12_AXI_AWQOS,
        S_AXI_AWVALID             => S12_AXI_AWVALID,
        S_AXI_AWREADY             => S12_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S12_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S12_AXI_AWSNOOP,
        S_AXI_AWBAR               => S12_AXI_AWBAR,
        S_AXI_AWUSER              => S12_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S12_AXI_WDATA,
        S_AXI_WSTRB               => S12_AXI_WSTRB,
        S_AXI_WLAST               => S12_AXI_WLAST,
        S_AXI_WVALID              => S12_AXI_WVALID,
        S_AXI_WREADY              => S12_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S12_AXI_BRESP,
        S_AXI_BID                 => S12_AXI_BID,
        S_AXI_BVALID              => S12_AXI_BVALID,
        S_AXI_BREADY              => S12_AXI_BREADY,
        S_AXI_WACK                => S12_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S12_AXI_ARID,
        S_AXI_ARADDR              => S12_AXI_ARADDR,
        S_AXI_ARLEN               => S12_AXI_ARLEN,
        S_AXI_ARSIZE              => S12_AXI_ARSIZE,
        S_AXI_ARBURST             => S12_AXI_ARBURST,
        S_AXI_ARLOCK              => S12_AXI_ARLOCK,
        S_AXI_ARCACHE             => S12_AXI_ARCACHE,
        S_AXI_ARPROT              => S12_AXI_ARPROT,
        S_AXI_ARQOS               => S12_AXI_ARQOS,
        S_AXI_ARVALID             => S12_AXI_ARVALID,
        S_AXI_ARREADY             => S12_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S12_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S12_AXI_ARSNOOP,
        S_AXI_ARBAR               => S12_AXI_ARBAR,
        S_AXI_ARUSER              => S12_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S12_AXI_RID,
        S_AXI_RDATA               => S12_AXI_RDATA,
        S_AXI_RRESP               => S12_AXI_RRESP,
        S_AXI_RLAST               => S12_AXI_RLAST,
        S_AXI_RVALID              => S12_AXI_RVALID,
        S_AXI_RREADY              => S12_AXI_RREADY,
        S_AXI_RACK                => S12_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S12_AXI_ACVALID,
        S_AXI_ACADDR              => S12_AXI_ACADDR,
        S_AXI_ACSNOOP             => S12_AXI_ACSNOOP,
        S_AXI_ACPROT              => S12_AXI_ACPROT,
        S_AXI_ACREADY             => S12_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S12_AXI_CRVALID,
        S_AXI_CRRESP              => S12_AXI_CRRESP,
        S_AXI_CRREADY             => S12_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S12_AXI_CDVALID,
        S_AXI_CDDATA              => S12_AXI_CDDATA,
        S_AXI_CDLAST              => S12_AXI_CDLAST,
        S_AXI_CDREADY             => S12_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(12),
        wr_port_id                => wr_port_id((12+1) * C_ID_WIDTH - 1 downto (12) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(12),
        rd_port_id                => rd_port_id((12+1) * C_ID_WIDTH - 1 downto (12) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(12),
        snoop_fetch_sync          => snoop_fetch_sync(12),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(12),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(12),
        snoop_req_myself          => snoop_req_myself(12),
        snoop_req_always          => snoop_req_always(12),
        snoop_req_update_filter   => snoop_req_update_filter(12),
        snoop_req_want            => snoop_req_want(12),
        snoop_req_complete        => snoop_req_complete(12),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(12),
        snoop_act_myself          => snoop_act_myself(12),
        snoop_act_always          => snoop_act_always(12),
        snoop_act_tag_valid       => snoop_act_tag_valid(12),
        snoop_act_tag_unique      => snoop_act_tag_unique(12),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(12),
        snoop_act_done            => snoop_act_done(12),
        snoop_act_use_external    => snoop_act_use_external(12),
        snoop_act_write_blocking  => snoop_act_write_blocking(12),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(12),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(12),
        
        snoop_resp_valid          => snoop_resp_valid(12),
        snoop_resp_crresp         => snoop_resp_crresp(12),
        snoop_resp_ready          => snoop_resp_ready(12),
        
        read_data_ex_rack         => read_data_ex_rack(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(12),
        wr_port_data_last         => wr_port_data_last(12),
        wr_port_data_be           => wr_port_data_be((12+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (12) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((12+1) * C_CACHE_DATA_WIDTH - 1 downto (12) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(12),
        access_bp_early           => access_bp_early(12),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(12),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(12),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(12),
        read_info_full            => read_info_full(12),
        read_data_hit_pop         => read_data_hit_pop(12),
        read_data_hit_almost_full => read_data_hit_almost_full(12),
        read_data_hit_full        => read_data_hit_full(12),
        read_data_hit_fit         => read_data_hit_fit_i(12),
        read_data_miss_full       => read_data_miss_full(12),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(12),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(13 * C_CACHE_DATA_WIDTH - 1 downto 12 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(12),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(12),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(12),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(12),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(12),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(12),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(12),
        stat_s_axi_rip              => stat_s_axi_rip(12),
        stat_s_axi_r                => stat_s_axi_r(12),
        stat_s_axi_bip              => stat_s_axi_bip(12),
        stat_s_axi_bp               => stat_s_axi_bp(12),
        stat_s_axi_wip              => stat_s_axi_wip(12),
        stat_s_axi_w                => stat_s_axi_w(12),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(12),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(12),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(12),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(12),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(12),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF12_DEBUG 
      );
  end generate Use_Port_12;
  
  No_Port_12: if ( C_NUM_OPTIMIZED_PORTS < 13 ) generate
  begin
    S12_AXI_AWREADY        <= '0';
    S12_AXI_WREADY         <= '0';
    S12_AXI_BRESP          <= (others=>'0');
    S12_AXI_BID            <= (others=>'0');
    S12_AXI_BVALID         <= '0';
    S12_AXI_ARREADY        <= '0';
    S12_AXI_RID            <= (others=>'0');
    S12_AXI_RDATA          <= (others=>'0');
    S12_AXI_RRESP          <= (others=>'0');
    S12_AXI_RLAST          <= '0';
    S12_AXI_RVALID         <= '0';
    S12_AXI_ACVALID        <= '0';
    S12_AXI_ACADDR         <= (others=>'0');
    S12_AXI_ACSNOOP        <= (others=>'0');
    S12_AXI_ACPROT         <= (others=>'0');
    S12_AXI_CRREADY        <= '0';
    S12_AXI_CDREADY        <= '0';
    port_assert_error(12)  <= '0';
    OPT_IF12_DEBUG         <= (others=>'0');
  end generate No_Port_12;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #13
  -----------------------------------------------------------------------------
  
  Use_Port_13: if ( C_NUM_OPTIMIZED_PORTS > 13 ) generate
  begin
    AXI_13: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S13_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S13_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S13_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S13_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S13_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S13_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S13_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S13_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S13_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S13_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S13_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S13_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S13_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S13_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S13_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S13_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 13,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S13_AXI_AWID,
        S_AXI_AWADDR              => S13_AXI_AWADDR,
        S_AXI_AWLEN               => S13_AXI_AWLEN,
        S_AXI_AWSIZE              => S13_AXI_AWSIZE,
        S_AXI_AWBURST             => S13_AXI_AWBURST,
        S_AXI_AWLOCK              => S13_AXI_AWLOCK,
        S_AXI_AWCACHE             => S13_AXI_AWCACHE,
        S_AXI_AWPROT              => S13_AXI_AWPROT,
        S_AXI_AWQOS               => S13_AXI_AWQOS,
        S_AXI_AWVALID             => S13_AXI_AWVALID,
        S_AXI_AWREADY             => S13_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S13_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S13_AXI_AWSNOOP,
        S_AXI_AWBAR               => S13_AXI_AWBAR,
        S_AXI_AWUSER              => S13_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S13_AXI_WDATA,
        S_AXI_WSTRB               => S13_AXI_WSTRB,
        S_AXI_WLAST               => S13_AXI_WLAST,
        S_AXI_WVALID              => S13_AXI_WVALID,
        S_AXI_WREADY              => S13_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S13_AXI_BRESP,
        S_AXI_BID                 => S13_AXI_BID,
        S_AXI_BVALID              => S13_AXI_BVALID,
        S_AXI_BREADY              => S13_AXI_BREADY,
        S_AXI_WACK                => S13_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S13_AXI_ARID,
        S_AXI_ARADDR              => S13_AXI_ARADDR,
        S_AXI_ARLEN               => S13_AXI_ARLEN,
        S_AXI_ARSIZE              => S13_AXI_ARSIZE,
        S_AXI_ARBURST             => S13_AXI_ARBURST,
        S_AXI_ARLOCK              => S13_AXI_ARLOCK,
        S_AXI_ARCACHE             => S13_AXI_ARCACHE,
        S_AXI_ARPROT              => S13_AXI_ARPROT,
        S_AXI_ARQOS               => S13_AXI_ARQOS,
        S_AXI_ARVALID             => S13_AXI_ARVALID,
        S_AXI_ARREADY             => S13_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S13_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S13_AXI_ARSNOOP,
        S_AXI_ARBAR               => S13_AXI_ARBAR,
        S_AXI_ARUSER              => S13_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S13_AXI_RID,
        S_AXI_RDATA               => S13_AXI_RDATA,
        S_AXI_RRESP               => S13_AXI_RRESP,
        S_AXI_RLAST               => S13_AXI_RLAST,
        S_AXI_RVALID              => S13_AXI_RVALID,
        S_AXI_RREADY              => S13_AXI_RREADY,
        S_AXI_RACK                => S13_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S13_AXI_ACVALID,
        S_AXI_ACADDR              => S13_AXI_ACADDR,
        S_AXI_ACSNOOP             => S13_AXI_ACSNOOP,
        S_AXI_ACPROT              => S13_AXI_ACPROT,
        S_AXI_ACREADY             => S13_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S13_AXI_CRVALID,
        S_AXI_CRRESP              => S13_AXI_CRRESP,
        S_AXI_CRREADY             => S13_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S13_AXI_CDVALID,
        S_AXI_CDDATA              => S13_AXI_CDDATA,
        S_AXI_CDLAST              => S13_AXI_CDLAST,
        S_AXI_CDREADY             => S13_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(13),
        wr_port_id                => wr_port_id((13+1) * C_ID_WIDTH - 1 downto (13) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(13),
        rd_port_id                => rd_port_id((13+1) * C_ID_WIDTH - 1 downto (13) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(13),
        snoop_fetch_sync          => snoop_fetch_sync(13),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(13),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(13),
        snoop_req_myself          => snoop_req_myself(13),
        snoop_req_always          => snoop_req_always(13),
        snoop_req_update_filter   => snoop_req_update_filter(13),
        snoop_req_want            => snoop_req_want(13),
        snoop_req_complete        => snoop_req_complete(13),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(13),
        snoop_act_myself          => snoop_act_myself(13),
        snoop_act_always          => snoop_act_always(13),
        snoop_act_tag_valid       => snoop_act_tag_valid(13),
        snoop_act_tag_unique      => snoop_act_tag_unique(13),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(13),
        snoop_act_done            => snoop_act_done(13),
        snoop_act_use_external    => snoop_act_use_external(13),
        snoop_act_write_blocking  => snoop_act_write_blocking(13),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(13),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(13),
        
        snoop_resp_valid          => snoop_resp_valid(13),
        snoop_resp_crresp         => snoop_resp_crresp(13),
        snoop_resp_ready          => snoop_resp_ready(13),
        
        read_data_ex_rack         => read_data_ex_rack(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(13),
        wr_port_data_last         => wr_port_data_last(13),
        wr_port_data_be           => wr_port_data_be((13+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (13) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((13+1) * C_CACHE_DATA_WIDTH - 1 downto (13) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(13),
        access_bp_early           => access_bp_early(13),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(13),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(13),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(13),
        read_info_full            => read_info_full(13),
        read_data_hit_pop         => read_data_hit_pop(13),
        read_data_hit_almost_full => read_data_hit_almost_full(13),
        read_data_hit_full        => read_data_hit_full(13),
        read_data_hit_fit         => read_data_hit_fit_i(13),
        read_data_miss_full       => read_data_miss_full(13),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(13),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(14 * C_CACHE_DATA_WIDTH - 1 downto 13 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(13),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(13),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(13),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(13),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(13),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(13),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(13),
        stat_s_axi_rip              => stat_s_axi_rip(13),
        stat_s_axi_r                => stat_s_axi_r(13),
        stat_s_axi_bip              => stat_s_axi_bip(13),
        stat_s_axi_bp               => stat_s_axi_bp(13),
        stat_s_axi_wip              => stat_s_axi_wip(13),
        stat_s_axi_w                => stat_s_axi_w(13),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(13),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(13),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(13),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(13),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(13),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF13_DEBUG 
      );
  end generate Use_Port_13;
  
  No_Port_13: if ( C_NUM_OPTIMIZED_PORTS < 14 ) generate
  begin
    S13_AXI_AWREADY        <= '0';
    S13_AXI_WREADY         <= '0';
    S13_AXI_BRESP          <= (others=>'0');
    S13_AXI_BID            <= (others=>'0');
    S13_AXI_BVALID         <= '0';
    S13_AXI_ARREADY        <= '0';
    S13_AXI_RID            <= (others=>'0');
    S13_AXI_RDATA          <= (others=>'0');
    S13_AXI_RRESP          <= (others=>'0');
    S13_AXI_RLAST          <= '0';
    S13_AXI_RVALID         <= '0';
    S13_AXI_ACVALID        <= '0';
    S13_AXI_ACADDR         <= (others=>'0');
    S13_AXI_ACSNOOP        <= (others=>'0');
    S13_AXI_ACPROT         <= (others=>'0');
    S13_AXI_CRREADY        <= '0';
    S13_AXI_CDREADY        <= '0';
    port_assert_error(13)  <= '0';
    OPT_IF13_DEBUG         <= (others=>'0');
  end generate No_Port_13;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #14
  -----------------------------------------------------------------------------
  
  Use_Port_14: if ( C_NUM_OPTIMIZED_PORTS > 14 ) generate
  begin
    AXI_14: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S14_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S14_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S14_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S14_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S14_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S14_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S14_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S14_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S14_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S14_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S14_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S14_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S14_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S14_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S14_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S14_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 14,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S14_AXI_AWID,
        S_AXI_AWADDR              => S14_AXI_AWADDR,
        S_AXI_AWLEN               => S14_AXI_AWLEN,
        S_AXI_AWSIZE              => S14_AXI_AWSIZE,
        S_AXI_AWBURST             => S14_AXI_AWBURST,
        S_AXI_AWLOCK              => S14_AXI_AWLOCK,
        S_AXI_AWCACHE             => S14_AXI_AWCACHE,
        S_AXI_AWPROT              => S14_AXI_AWPROT,
        S_AXI_AWQOS               => S14_AXI_AWQOS,
        S_AXI_AWVALID             => S14_AXI_AWVALID,
        S_AXI_AWREADY             => S14_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S14_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S14_AXI_AWSNOOP,
        S_AXI_AWBAR               => S14_AXI_AWBAR,
        S_AXI_AWUSER              => S14_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S14_AXI_WDATA,
        S_AXI_WSTRB               => S14_AXI_WSTRB,
        S_AXI_WLAST               => S14_AXI_WLAST,
        S_AXI_WVALID              => S14_AXI_WVALID,
        S_AXI_WREADY              => S14_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S14_AXI_BRESP,
        S_AXI_BID                 => S14_AXI_BID,
        S_AXI_BVALID              => S14_AXI_BVALID,
        S_AXI_BREADY              => S14_AXI_BREADY,
        S_AXI_WACK                => S14_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S14_AXI_ARID,
        S_AXI_ARADDR              => S14_AXI_ARADDR,
        S_AXI_ARLEN               => S14_AXI_ARLEN,
        S_AXI_ARSIZE              => S14_AXI_ARSIZE,
        S_AXI_ARBURST             => S14_AXI_ARBURST,
        S_AXI_ARLOCK              => S14_AXI_ARLOCK,
        S_AXI_ARCACHE             => S14_AXI_ARCACHE,
        S_AXI_ARPROT              => S14_AXI_ARPROT,
        S_AXI_ARQOS               => S14_AXI_ARQOS,
        S_AXI_ARVALID             => S14_AXI_ARVALID,
        S_AXI_ARREADY             => S14_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S14_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S14_AXI_ARSNOOP,
        S_AXI_ARBAR               => S14_AXI_ARBAR,
        S_AXI_ARUSER              => S14_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S14_AXI_RID,
        S_AXI_RDATA               => S14_AXI_RDATA,
        S_AXI_RRESP               => S14_AXI_RRESP,
        S_AXI_RLAST               => S14_AXI_RLAST,
        S_AXI_RVALID              => S14_AXI_RVALID,
        S_AXI_RREADY              => S14_AXI_RREADY,
        S_AXI_RACK                => S14_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S14_AXI_ACVALID,
        S_AXI_ACADDR              => S14_AXI_ACADDR,
        S_AXI_ACSNOOP             => S14_AXI_ACSNOOP,
        S_AXI_ACPROT              => S14_AXI_ACPROT,
        S_AXI_ACREADY             => S14_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S14_AXI_CRVALID,
        S_AXI_CRRESP              => S14_AXI_CRRESP,
        S_AXI_CRREADY             => S14_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S14_AXI_CDVALID,
        S_AXI_CDDATA              => S14_AXI_CDDATA,
        S_AXI_CDLAST              => S14_AXI_CDLAST,
        S_AXI_CDREADY             => S14_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(14),
        wr_port_id                => wr_port_id((14+1) * C_ID_WIDTH - 1 downto (14) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(14),
        rd_port_id                => rd_port_id((14+1) * C_ID_WIDTH - 1 downto (14) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(14),
        snoop_fetch_sync          => snoop_fetch_sync(14),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(14),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(14),
        snoop_req_myself          => snoop_req_myself(14),
        snoop_req_always          => snoop_req_always(14),
        snoop_req_update_filter   => snoop_req_update_filter(14),
        snoop_req_want            => snoop_req_want(14),
        snoop_req_complete        => snoop_req_complete(14),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(14),
        snoop_act_myself          => snoop_act_myself(14),
        snoop_act_always          => snoop_act_always(14),
        snoop_act_tag_valid       => snoop_act_tag_valid(14),
        snoop_act_tag_unique      => snoop_act_tag_unique(14),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(14),
        snoop_act_done            => snoop_act_done(14),
        snoop_act_use_external    => snoop_act_use_external(14),
        snoop_act_write_blocking  => snoop_act_write_blocking(14),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(14),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(14),
        
        snoop_resp_valid          => snoop_resp_valid(14),
        snoop_resp_crresp         => snoop_resp_crresp(14),
        snoop_resp_ready          => snoop_resp_ready(14),
        
        read_data_ex_rack         => read_data_ex_rack(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(14),
        wr_port_data_last         => wr_port_data_last(14),
        wr_port_data_be           => wr_port_data_be((14+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (14) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((14+1) * C_CACHE_DATA_WIDTH - 1 downto (14) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(14),
        access_bp_early           => access_bp_early(14),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(14),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(14),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(14),
        read_info_full            => read_info_full(14),
        read_data_hit_pop         => read_data_hit_pop(14),
        read_data_hit_almost_full => read_data_hit_almost_full(14),
        read_data_hit_full        => read_data_hit_full(14),
        read_data_hit_fit         => read_data_hit_fit_i(14),
        read_data_miss_full       => read_data_miss_full(14),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(14),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(15 * C_CACHE_DATA_WIDTH - 1 downto 14 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(14),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(14),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(14),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(14),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(14),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(14),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(14),
        stat_s_axi_rip              => stat_s_axi_rip(14),
        stat_s_axi_r                => stat_s_axi_r(14),
        stat_s_axi_bip              => stat_s_axi_bip(14),
        stat_s_axi_bp               => stat_s_axi_bp(14),
        stat_s_axi_wip              => stat_s_axi_wip(14),
        stat_s_axi_w                => stat_s_axi_w(14),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(14),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(14),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(14),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(14),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(14),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF14_DEBUG 
      );
  end generate Use_Port_14;
  
  No_Port_14: if ( C_NUM_OPTIMIZED_PORTS < 15 ) generate
  begin
    S14_AXI_AWREADY        <= '0';
    S14_AXI_WREADY         <= '0';
    S14_AXI_BRESP          <= (others=>'0');
    S14_AXI_BID            <= (others=>'0');
    S14_AXI_BVALID         <= '0';
    S14_AXI_ARREADY        <= '0';
    S14_AXI_RID            <= (others=>'0');
    S14_AXI_RDATA          <= (others=>'0');
    S14_AXI_RRESP          <= (others=>'0');
    S14_AXI_RLAST          <= '0';
    S14_AXI_RVALID         <= '0';
    S14_AXI_ACVALID        <= '0';
    S14_AXI_ACADDR         <= (others=>'0');
    S14_AXI_ACSNOOP        <= (others=>'0');
    S14_AXI_ACPROT         <= (others=>'0');
    S14_AXI_CRREADY        <= '0';
    S14_AXI_CDREADY        <= '0';
    port_assert_error(14)  <= '0';
    OPT_IF14_DEBUG         <= (others=>'0');
  end generate No_Port_14;
  
  
  -----------------------------------------------------------------------------
  -- Optimized AXI Slave Interface #15
  -----------------------------------------------------------------------------
  
  Use_Port_15: if ( C_NUM_OPTIMIZED_PORTS > 15 ) generate
  begin
    AXI_15: sc_s_axi_opt_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S15_AXI_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S15_AXI_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S15_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S15_AXI_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S15_AXI_ID_WIDTH,
        C_S_AXI_SUPPORT_UNIQUE    => C_S15_AXI_SUPPORT_UNIQUE,
        C_S_AXI_SUPPORT_DIRTY     => C_S15_AXI_SUPPORT_DIRTY,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S15_AXI_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S15_AXI_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S15_AXI_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S15_AXI_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S15_AXI_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S15_AXI_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S15_AXI_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S15_AXI_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S15_AXI_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
        C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_HI,
        C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_LO,
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_HI,
        C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_LO,
        C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_HI,
        C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_HI,
        C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        
        -- L1 Cache Specific.
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => 15,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S15_AXI_AWID,
        S_AXI_AWADDR              => S15_AXI_AWADDR,
        S_AXI_AWLEN               => S15_AXI_AWLEN,
        S_AXI_AWSIZE              => S15_AXI_AWSIZE,
        S_AXI_AWBURST             => S15_AXI_AWBURST,
        S_AXI_AWLOCK              => S15_AXI_AWLOCK,
        S_AXI_AWCACHE             => S15_AXI_AWCACHE,
        S_AXI_AWPROT              => S15_AXI_AWPROT,
        S_AXI_AWQOS               => S15_AXI_AWQOS,
        S_AXI_AWVALID             => S15_AXI_AWVALID,
        S_AXI_AWREADY             => S15_AXI_AWREADY,
        S_AXI_AWDOMAIN            => S15_AXI_AWDOMAIN,
        S_AXI_AWSNOOP             => S15_AXI_AWSNOOP,
        S_AXI_AWBAR               => S15_AXI_AWBAR,
        S_AXI_AWUSER              => S15_AXI_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S15_AXI_WDATA,
        S_AXI_WSTRB               => S15_AXI_WSTRB,
        S_AXI_WLAST               => S15_AXI_WLAST,
        S_AXI_WVALID              => S15_AXI_WVALID,
        S_AXI_WREADY              => S15_AXI_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S15_AXI_BRESP,
        S_AXI_BID                 => S15_AXI_BID,
        S_AXI_BVALID              => S15_AXI_BVALID,
        S_AXI_BREADY              => S15_AXI_BREADY,
        S_AXI_WACK                => S15_AXI_WACK,
    
        -- AR-Channel
        S_AXI_ARID                => S15_AXI_ARID,
        S_AXI_ARADDR              => S15_AXI_ARADDR,
        S_AXI_ARLEN               => S15_AXI_ARLEN,
        S_AXI_ARSIZE              => S15_AXI_ARSIZE,
        S_AXI_ARBURST             => S15_AXI_ARBURST,
        S_AXI_ARLOCK              => S15_AXI_ARLOCK,
        S_AXI_ARCACHE             => S15_AXI_ARCACHE,
        S_AXI_ARPROT              => S15_AXI_ARPROT,
        S_AXI_ARQOS               => S15_AXI_ARQOS,
        S_AXI_ARVALID             => S15_AXI_ARVALID,
        S_AXI_ARREADY             => S15_AXI_ARREADY,
        S_AXI_ARDOMAIN            => S15_AXI_ARDOMAIN,
        S_AXI_ARSNOOP             => S15_AXI_ARSNOOP,
        S_AXI_ARBAR               => S15_AXI_ARBAR,
        S_AXI_ARUSER              => S15_AXI_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S15_AXI_RID,
        S_AXI_RDATA               => S15_AXI_RDATA,
        S_AXI_RRESP               => S15_AXI_RRESP,
        S_AXI_RLAST               => S15_AXI_RLAST,
        S_AXI_RVALID              => S15_AXI_RVALID,
        S_AXI_RREADY              => S15_AXI_RREADY,
        S_AXI_RACK                => S15_AXI_RACK,
    
        -- AC-Channel (coherency only)
        S_AXI_ACVALID             => S15_AXI_ACVALID,
        S_AXI_ACADDR              => S15_AXI_ACADDR,
        S_AXI_ACSNOOP             => S15_AXI_ACSNOOP,
        S_AXI_ACPROT              => S15_AXI_ACPROT,
        S_AXI_ACREADY             => S15_AXI_ACREADY,
    
        -- CR-Channel (coherency only)
        S_AXI_CRVALID             => S15_AXI_CRVALID,
        S_AXI_CRRESP              => S15_AXI_CRRESP,
        S_AXI_CRREADY             => S15_AXI_CRREADY,
    
        -- CD-Channel (coherency only)
        S_AXI_CDVALID             => S15_AXI_CDVALID,
        S_AXI_CDDATA              => S15_AXI_CDDATA,
        S_AXI_CDLAST              => S15_AXI_CDLAST,
        S_AXI_CDREADY             => S15_AXI_CDREADY,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => opt_port_piperun,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(15),
        wr_port_id                => wr_port_id((15+1) * C_ID_WIDTH - 1 downto (15) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(15),
        rd_port_id                => rd_port_id((15+1) * C_ID_WIDTH - 1 downto (15) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(15),
        snoop_fetch_sync          => snoop_fetch_sync(15),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(15),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(15),
        snoop_req_myself          => snoop_req_myself(15),
        snoop_req_always          => snoop_req_always(15),
        snoop_req_update_filter   => snoop_req_update_filter(15),
        snoop_req_want            => snoop_req_want(15),
        snoop_req_complete        => snoop_req_complete(15),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(15),
        snoop_act_myself          => snoop_act_myself(15),
        snoop_act_always          => snoop_act_always(15),
        snoop_act_tag_valid       => snoop_act_tag_valid(15),
        snoop_act_tag_unique      => snoop_act_tag_unique(15),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(15),
        snoop_act_done            => snoop_act_done(15),
        snoop_act_use_external    => snoop_act_use_external(15),
        snoop_act_write_blocking  => snoop_act_write_blocking(15),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(15),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(15),
        
        snoop_resp_valid          => snoop_resp_valid(15),
        snoop_resp_crresp         => snoop_resp_crresp(15),
        snoop_resp_ready          => snoop_resp_ready(15),
        
        read_data_ex_rack         => read_data_ex_rack(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(15),
        wr_port_data_last         => wr_port_data_last(15),
        wr_port_data_be           => wr_port_data_be((15+1) * C_CACHE_DATA_WIDTH/8 - 1 downto (15) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((15+1) * C_CACHE_DATA_WIDTH - 1 downto (15) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(15),
        access_bp_early           => access_bp_early(15),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(15),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(15),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(15),
        read_info_full            => read_info_full(15),
        read_data_hit_pop         => read_data_hit_pop(15),
        read_data_hit_almost_full => read_data_hit_almost_full(15),
        read_data_hit_full        => read_data_hit_full(15),
        read_data_hit_fit         => read_data_hit_fit_i(15),
        read_data_miss_full       => read_data_miss_full(15),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(15),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(16 * C_CACHE_DATA_WIDTH - 1 downto 15 * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(15),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(15),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(15),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(15),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(15),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                  => stat_reset,
        stat_enable                 => stat_enable,
        
        stat_s_axi_rd_segments      => stat_s_axi_rd_segments(15),
        stat_s_axi_wr_segments      => stat_s_axi_wr_segments(15),
        stat_s_axi_rip              => stat_s_axi_rip(15),
        stat_s_axi_r                => stat_s_axi_r(15),
        stat_s_axi_bip              => stat_s_axi_bip(15),
        stat_s_axi_bp               => stat_s_axi_bp(15),
        stat_s_axi_wip              => stat_s_axi_wip(15),
        stat_s_axi_w                => stat_s_axi_w(15),
        stat_s_axi_rd_latency       => stat_s_axi_rd_latency(15),
        stat_s_axi_wr_latency       => stat_s_axi_wr_latency(15),
        stat_s_axi_rd_latency_conf  => stat_s_axi_rd_latency_conf(15),
        stat_s_axi_wr_latency_conf  => stat_s_axi_wr_latency_conf(15),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(15),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => OPT_IF15_DEBUG 
      );
  end generate Use_Port_15;
  
  No_Port_15: if ( C_NUM_OPTIMIZED_PORTS < 16 ) generate
  begin
    S15_AXI_AWREADY        <= '0';
    S15_AXI_WREADY         <= '0';
    S15_AXI_BRESP          <= (others=>'0');
    S15_AXI_BID            <= (others=>'0');
    S15_AXI_BVALID         <= '0';
    S15_AXI_ARREADY        <= '0';
    S15_AXI_RID            <= (others=>'0');
    S15_AXI_RDATA          <= (others=>'0');
    S15_AXI_RRESP          <= (others=>'0');
    S15_AXI_RLAST          <= '0';
    S15_AXI_RVALID         <= '0';
    S15_AXI_ACVALID        <= '0';
    S15_AXI_ACADDR         <= (others=>'0');
    S15_AXI_ACSNOOP        <= (others=>'0');
    S15_AXI_ACPROT         <= (others=>'0');
    S15_AXI_CRREADY        <= '0';
    S15_AXI_CDREADY        <= '0';
    port_assert_error(15)  <= '0';
    OPT_IF15_DEBUG         <= (others=>'0');
  end generate No_Port_15;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #0
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+0
  
  Use_Generic_Port_0: if ( C_NUM_GENERIC_PORTS > 0 ) generate
  begin
    AXI_0: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S0_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S0_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S0_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S0_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S0_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S0_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S0_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S0_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S0_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S0_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S0_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S0_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S0_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S0_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 0,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S0_AXI_GEN_AWID,
        S_AXI_AWADDR              => S0_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S0_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S0_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S0_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S0_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S0_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S0_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S0_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S0_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S0_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S0_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S0_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S0_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S0_AXI_GEN_WLAST,
        S_AXI_WVALID              => S0_AXI_GEN_WVALID,
        S_AXI_WREADY              => S0_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S0_AXI_GEN_BRESP,
        S_AXI_BID                 => S0_AXI_GEN_BID,
        S_AXI_BVALID              => S0_AXI_GEN_BVALID,
        S_AXI_BREADY              => S0_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S0_AXI_GEN_ARID,
        S_AXI_ARADDR              => S0_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S0_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S0_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S0_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S0_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S0_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S0_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S0_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S0_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S0_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S0_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S0_AXI_GEN_RID,
        S_AXI_RDATA               => S0_AXI_GEN_RDATA,
        S_AXI_RRESP               => S0_AXI_GEN_RRESP,
        S_AXI_RLAST               => S0_AXI_GEN_RLAST,
        S_AXI_RVALID              => S0_AXI_GEN_RVALID,
        S_AXI_RREADY              => S0_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 0),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 0 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 0) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 0),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 0 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 0) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 0),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 0),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 0),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 0),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 0),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 0 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 0) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 0 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 0) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 0),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 0),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 0),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 0),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 0),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 0),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 0),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 0),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 0),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 0),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 0),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 0 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 0 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 0),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 0),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 0),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(0),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(0),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(0),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(0),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(0),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(0),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(0),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(0),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(0),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(0),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(0),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(0),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(16),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF0_DEBUG 
      );
  end generate Use_Generic_Port_0;
  
  No_Generic_Port_0: if ( C_NUM_GENERIC_PORTS < 1 ) generate
  begin
    S0_AXI_GEN_AWREADY    <= '0';
    S0_AXI_GEN_WREADY     <= '0';
    S0_AXI_GEN_BRESP      <= (others=>'0');
    S0_AXI_GEN_BID        <= (others=>'0');
    S0_AXI_GEN_BVALID     <= '0';
    S0_AXI_GEN_ARREADY    <= '0';
    S0_AXI_GEN_RID        <= (others=>'0');
    S0_AXI_GEN_RDATA      <= (others=>'0');
    S0_AXI_GEN_RRESP      <= (others=>'0');
    S0_AXI_GEN_RLAST      <= '0';
    S0_AXI_GEN_RVALID     <= '0';
    port_assert_error(16)  <= '0';
    GEN_IF0_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_0;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #1
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+1
  
  Use_Generic_Port_1: if ( C_NUM_GENERIC_PORTS > 1 ) generate
  begin
    AXI_1: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S1_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S1_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S1_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S1_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S1_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S1_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S1_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S1_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S1_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S1_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S1_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S1_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S1_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S1_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 1,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S1_AXI_GEN_AWID,
        S_AXI_AWADDR              => S1_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S1_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S1_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S1_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S1_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S1_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S1_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S1_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S1_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S1_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S1_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S1_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S1_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S1_AXI_GEN_WLAST,
        S_AXI_WVALID              => S1_AXI_GEN_WVALID,
        S_AXI_WREADY              => S1_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S1_AXI_GEN_BRESP,
        S_AXI_BID                 => S1_AXI_GEN_BID,
        S_AXI_BVALID              => S1_AXI_GEN_BVALID,
        S_AXI_BREADY              => S1_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S1_AXI_GEN_ARID,
        S_AXI_ARADDR              => S1_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S1_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S1_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S1_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S1_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S1_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S1_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S1_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S1_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S1_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S1_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S1_AXI_GEN_RID,
        S_AXI_RDATA               => S1_AXI_GEN_RDATA,
        S_AXI_RRESP               => S1_AXI_GEN_RRESP,
        S_AXI_RLAST               => S1_AXI_GEN_RLAST,
        S_AXI_RVALID              => S1_AXI_GEN_RVALID,
        S_AXI_RREADY              => S1_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 1),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 1 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 1) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 1),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 1 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 1) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 1),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 1),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 1),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 1),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 1),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 1 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 1) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 1 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 1) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 1),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 1),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 1),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 1),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 1),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 1),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 1),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 1),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 1),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 1),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 1),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 1 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 1 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 1),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 1),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 1),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(1),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(1),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(1),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(1),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(1),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(1),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(1),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(1),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(1),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(1),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(1),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(1),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(17),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF1_DEBUG 
      );
  end generate Use_Generic_Port_1;
  
  No_Generic_Port_1: if ( C_NUM_GENERIC_PORTS < 2 ) generate
  begin
    S1_AXI_GEN_AWREADY    <= '0';
    S1_AXI_GEN_WREADY     <= '0';
    S1_AXI_GEN_BRESP      <= (others=>'0');
    S1_AXI_GEN_BID        <= (others=>'0');
    S1_AXI_GEN_BVALID     <= '0';
    S1_AXI_GEN_ARREADY    <= '0';
    S1_AXI_GEN_RID        <= (others=>'0');
    S1_AXI_GEN_RDATA      <= (others=>'0');
    S1_AXI_GEN_RRESP      <= (others=>'0');
    S1_AXI_GEN_RLAST      <= '0';
    S1_AXI_GEN_RVALID     <= '0';
    port_assert_error(17) <= '0';
    GEN_IF1_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_1;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #2
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+2
  
  Use_Generic_Port_2: if ( C_NUM_GENERIC_PORTS > 2 ) generate
  begin
    AXI_2: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S2_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S2_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S2_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S2_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S2_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S2_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S2_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S2_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S2_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S2_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S2_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S2_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S2_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S2_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 2,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S2_AXI_GEN_AWID,
        S_AXI_AWADDR              => S2_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S2_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S2_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S2_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S2_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S2_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S2_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S2_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S2_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S2_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S2_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S2_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S2_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S2_AXI_GEN_WLAST,
        S_AXI_WVALID              => S2_AXI_GEN_WVALID,
        S_AXI_WREADY              => S2_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S2_AXI_GEN_BRESP,
        S_AXI_BID                 => S2_AXI_GEN_BID,
        S_AXI_BVALID              => S2_AXI_GEN_BVALID,
        S_AXI_BREADY              => S2_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S2_AXI_GEN_ARID,
        S_AXI_ARADDR              => S2_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S2_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S2_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S2_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S2_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S2_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S2_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S2_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S2_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S2_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S2_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S2_AXI_GEN_RID,
        S_AXI_RDATA               => S2_AXI_GEN_RDATA,
        S_AXI_RRESP               => S2_AXI_GEN_RRESP,
        S_AXI_RLAST               => S2_AXI_GEN_RLAST,
        S_AXI_RVALID              => S2_AXI_GEN_RVALID,
        S_AXI_RREADY              => S2_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 2),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 2 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 2) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 2),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 2 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 2) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 2),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 2),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 2),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 2),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 2),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 2 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 2) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 2 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 2) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 2),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 2),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 2),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 2),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 2),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 2),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 2),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 2),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 2),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 2),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 2),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 2 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 2 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 2),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 2),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 2),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(2),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(2),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(2),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(2),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(2),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(2),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(2),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(2),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(2),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(2),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(2),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(2),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(18),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF2_DEBUG 
      );
  end generate Use_Generic_Port_2;
  
  No_Generic_Port_2: if ( C_NUM_GENERIC_PORTS < 3 ) generate
  begin
    S2_AXI_GEN_AWREADY    <= '0';
    S2_AXI_GEN_WREADY     <= '0';
    S2_AXI_GEN_BRESP      <= (others=>'0');
    S2_AXI_GEN_BID        <= (others=>'0');
    S2_AXI_GEN_BVALID     <= '0';
    S2_AXI_GEN_ARREADY    <= '0';
    S2_AXI_GEN_RID        <= (others=>'0');
    S2_AXI_GEN_RDATA      <= (others=>'0');
    S2_AXI_GEN_RRESP      <= (others=>'0');
    S2_AXI_GEN_RLAST      <= '0';
    S2_AXI_GEN_RVALID     <= '0';
    port_assert_error(18) <= '0';
    GEN_IF2_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_2;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #3
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+3
  
  Use_Generic_Port_3: if ( C_NUM_GENERIC_PORTS > 3 ) generate
  begin
    AXI_3: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S3_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S3_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S3_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S3_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S3_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S3_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S3_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S3_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S3_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S3_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S3_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S3_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S3_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S3_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 3,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S3_AXI_GEN_AWID,
        S_AXI_AWADDR              => S3_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S3_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S3_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S3_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S3_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S3_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S3_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S3_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S3_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S3_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S3_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S3_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S3_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S3_AXI_GEN_WLAST,
        S_AXI_WVALID              => S3_AXI_GEN_WVALID,
        S_AXI_WREADY              => S3_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S3_AXI_GEN_BRESP,
        S_AXI_BID                 => S3_AXI_GEN_BID,
        S_AXI_BVALID              => S3_AXI_GEN_BVALID,
        S_AXI_BREADY              => S3_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S3_AXI_GEN_ARID,
        S_AXI_ARADDR              => S3_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S3_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S3_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S3_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S3_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S3_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S3_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S3_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S3_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S3_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S3_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S3_AXI_GEN_RID,
        S_AXI_RDATA               => S3_AXI_GEN_RDATA,
        S_AXI_RRESP               => S3_AXI_GEN_RRESP,
        S_AXI_RLAST               => S3_AXI_GEN_RLAST,
        S_AXI_RVALID              => S3_AXI_GEN_RVALID,
        S_AXI_RREADY              => S3_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 3),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 3 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 3) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 3),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 3 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 3) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 3),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 3),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 3),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 3),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 3),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 3 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 3) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 3 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 3) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 3),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 3),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 3),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 3),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 3),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 3),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 3),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 3),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 3),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 3),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 3),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 3 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 3 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 3),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 3),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 3),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(3),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(3),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(3),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(3),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(3),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(3),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(3),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(3),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(3),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(3),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(3),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(3),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(19),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF3_DEBUG 
      );
  end generate Use_Generic_Port_3;
  
  No_Generic_Port_3: if ( C_NUM_GENERIC_PORTS < 4 ) generate
  begin
    S3_AXI_GEN_AWREADY    <= '0';
    S3_AXI_GEN_WREADY     <= '0';
    S3_AXI_GEN_BRESP      <= (others=>'0');
    S3_AXI_GEN_BID        <= (others=>'0');
    S3_AXI_GEN_BVALID     <= '0';
    S3_AXI_GEN_ARREADY    <= '0';
    S3_AXI_GEN_RID        <= (others=>'0');
    S3_AXI_GEN_RDATA      <= (others=>'0');
    S3_AXI_GEN_RRESP      <= (others=>'0');
    S3_AXI_GEN_RLAST      <= '0';
    S3_AXI_GEN_RVALID     <= '0';
    port_assert_error(19) <= '0';
    GEN_IF3_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_3;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #4
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+4
  
  Use_Generic_Port_4: if ( C_NUM_GENERIC_PORTS > 4 ) generate
  begin
    AXI_4: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S4_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S4_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S4_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S4_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S4_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S4_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S4_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S4_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S4_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S4_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S4_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S4_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S4_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S4_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 4,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S4_AXI_GEN_AWID,
        S_AXI_AWADDR              => S4_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S4_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S4_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S4_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S4_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S4_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S4_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S4_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S4_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S4_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S4_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S4_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S4_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S4_AXI_GEN_WLAST,
        S_AXI_WVALID              => S4_AXI_GEN_WVALID,
        S_AXI_WREADY              => S4_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S4_AXI_GEN_BRESP,
        S_AXI_BID                 => S4_AXI_GEN_BID,
        S_AXI_BVALID              => S4_AXI_GEN_BVALID,
        S_AXI_BREADY              => S4_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S4_AXI_GEN_ARID,
        S_AXI_ARADDR              => S4_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S4_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S4_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S4_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S4_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S4_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S4_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S4_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S4_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S4_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S4_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S4_AXI_GEN_RID,
        S_AXI_RDATA               => S4_AXI_GEN_RDATA,
        S_AXI_RRESP               => S4_AXI_GEN_RRESP,
        S_AXI_RLAST               => S4_AXI_GEN_RLAST,
        S_AXI_RVALID              => S4_AXI_GEN_RVALID,
        S_AXI_RREADY              => S4_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 4),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 4 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 4) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 4),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 4 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 4) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 4),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 4),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 4),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 4),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 4),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 4 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 4) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 4 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 4) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 4),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 4),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 4),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 4),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 4),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 4),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 4),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 4),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 4),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 4),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 4),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 4 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 4 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 4),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 4),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 4),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(4),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(4),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(4),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(4),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(4),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(4),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(4),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(4),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(4),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(4),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(4),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(4),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(20),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF4_DEBUG 
      );
  end generate Use_Generic_Port_4;
  
  No_Generic_Port_4: if ( C_NUM_GENERIC_PORTS < 5 ) generate
  begin
    S4_AXI_GEN_AWREADY    <= '0';
    S4_AXI_GEN_WREADY     <= '0';
    S4_AXI_GEN_BRESP      <= (others=>'0');
    S4_AXI_GEN_BID        <= (others=>'0');
    S4_AXI_GEN_BVALID     <= '0';
    S4_AXI_GEN_ARREADY    <= '0';
    S4_AXI_GEN_RID        <= (others=>'0');
    S4_AXI_GEN_RDATA      <= (others=>'0');
    S4_AXI_GEN_RRESP      <= (others=>'0');
    S4_AXI_GEN_RLAST      <= '0';
    S4_AXI_GEN_RVALID     <= '0';
    port_assert_error(20) <= '0';
    GEN_IF4_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_4;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #5
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+5
  
  Use_Generic_Port_5: if ( C_NUM_GENERIC_PORTS > 5 ) generate
  begin
    AXI_5: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S5_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S5_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S5_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S5_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S5_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S5_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S5_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S5_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S5_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S5_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S5_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S5_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S5_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S5_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 5,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S5_AXI_GEN_AWID,
        S_AXI_AWADDR              => S5_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S5_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S5_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S5_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S5_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S5_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S5_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S5_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S5_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S5_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S5_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S5_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S5_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S5_AXI_GEN_WLAST,
        S_AXI_WVALID              => S5_AXI_GEN_WVALID,
        S_AXI_WREADY              => S5_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S5_AXI_GEN_BRESP,
        S_AXI_BID                 => S5_AXI_GEN_BID,
        S_AXI_BVALID              => S5_AXI_GEN_BVALID,
        S_AXI_BREADY              => S5_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S5_AXI_GEN_ARID,
        S_AXI_ARADDR              => S5_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S5_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S5_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S5_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S5_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S5_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S5_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S5_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S5_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S5_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S5_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S5_AXI_GEN_RID,
        S_AXI_RDATA               => S5_AXI_GEN_RDATA,
        S_AXI_RRESP               => S5_AXI_GEN_RRESP,
        S_AXI_RLAST               => S5_AXI_GEN_RLAST,
        S_AXI_RVALID              => S5_AXI_GEN_RVALID,
        S_AXI_RREADY              => S5_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 5),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 5 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 5) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 5),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 5 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 5) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 5),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 5),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 5),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 5),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 5),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 5 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 5) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 5 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 5) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 5),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 5),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 5),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 5),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 5),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 5),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 5),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 5),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 5),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 5),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 5),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 5 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 5 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 5),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 5),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 5),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(5),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(5),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(5),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(5),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(5),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(5),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(5),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(5),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(5),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(5),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(5),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(5),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(21),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF5_DEBUG 
      );
  end generate Use_Generic_Port_5;
  
  No_Generic_Port_5: if ( C_NUM_GENERIC_PORTS < 6 ) generate
  begin
    S5_AXI_GEN_AWREADY    <= '0';
    S5_AXI_GEN_WREADY     <= '0';
    S5_AXI_GEN_BRESP      <= (others=>'0');
    S5_AXI_GEN_BID        <= (others=>'0');
    S5_AXI_GEN_BVALID     <= '0';
    S5_AXI_GEN_ARREADY    <= '0';
    S5_AXI_GEN_RID        <= (others=>'0');
    S5_AXI_GEN_RDATA      <= (others=>'0');
    S5_AXI_GEN_RRESP      <= (others=>'0');
    S5_AXI_GEN_RLAST      <= '0';
    S5_AXI_GEN_RVALID     <= '0';
    port_assert_error(21) <= '0';
    GEN_IF5_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_5;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #6
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+6
  
  Use_Generic_Port_6: if ( C_NUM_GENERIC_PORTS > 6 ) generate
  begin
    AXI_6: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S6_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S6_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S6_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S6_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S6_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S6_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S6_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S6_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S6_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S6_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S6_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S6_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S6_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S6_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 6,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S6_AXI_GEN_AWID,
        S_AXI_AWADDR              => S6_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S6_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S6_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S6_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S6_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S6_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S6_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S6_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S6_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S6_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S6_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S6_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S6_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S6_AXI_GEN_WLAST,
        S_AXI_WVALID              => S6_AXI_GEN_WVALID,
        S_AXI_WREADY              => S6_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S6_AXI_GEN_BRESP,
        S_AXI_BID                 => S6_AXI_GEN_BID,
        S_AXI_BVALID              => S6_AXI_GEN_BVALID,
        S_AXI_BREADY              => S6_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S6_AXI_GEN_ARID,
        S_AXI_ARADDR              => S6_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S6_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S6_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S6_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S6_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S6_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S6_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S6_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S6_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S6_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S6_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S6_AXI_GEN_RID,
        S_AXI_RDATA               => S6_AXI_GEN_RDATA,
        S_AXI_RRESP               => S6_AXI_GEN_RRESP,
        S_AXI_RLAST               => S6_AXI_GEN_RLAST,
        S_AXI_RVALID              => S6_AXI_GEN_RVALID,
        S_AXI_RREADY              => S6_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 6),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 6 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 6) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 6),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 6 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 6) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 6),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 6),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 6),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 6),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 6),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 6 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 6) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 6 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 6) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 6),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 6),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 6),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 6),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 6),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 6),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 6),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 6),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 6),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 6),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 6),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 6 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 6 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 6),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 6),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 6),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(6),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(6),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(6),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(6),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(6),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(6),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(6),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(6),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(6),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(6),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(6),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(6),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(22),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF6_DEBUG 
      );
  end generate Use_Generic_Port_6;
  
  No_Generic_Port_6: if ( C_NUM_GENERIC_PORTS < 7 ) generate
  begin
    S6_AXI_GEN_AWREADY    <= '0';
    S6_AXI_GEN_WREADY     <= '0';
    S6_AXI_GEN_BRESP      <= (others=>'0');
    S6_AXI_GEN_BID        <= (others=>'0');
    S6_AXI_GEN_BVALID     <= '0';
    S6_AXI_GEN_ARREADY    <= '0';
    S6_AXI_GEN_RID        <= (others=>'0');
    S6_AXI_GEN_RDATA      <= (others=>'0');
    S6_AXI_GEN_RRESP      <= (others=>'0');
    S6_AXI_GEN_RLAST      <= '0';
    S6_AXI_GEN_RVALID     <= '0';
    port_assert_error(22) <= '0';
    GEN_IF6_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_6;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #7
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+7
  
  Use_Generic_Port_7: if ( C_NUM_GENERIC_PORTS > 7 ) generate
  begin
    AXI_7: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S7_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S7_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S7_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S7_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S7_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S7_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S7_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S7_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S7_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S7_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S7_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S7_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S7_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S7_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 7,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S7_AXI_GEN_AWID,
        S_AXI_AWADDR              => S7_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S7_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S7_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S7_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S7_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S7_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S7_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S7_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S7_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S7_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S7_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S7_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S7_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S7_AXI_GEN_WLAST,
        S_AXI_WVALID              => S7_AXI_GEN_WVALID,
        S_AXI_WREADY              => S7_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S7_AXI_GEN_BRESP,
        S_AXI_BID                 => S7_AXI_GEN_BID,
        S_AXI_BVALID              => S7_AXI_GEN_BVALID,
        S_AXI_BREADY              => S7_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S7_AXI_GEN_ARID,
        S_AXI_ARADDR              => S7_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S7_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S7_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S7_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S7_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S7_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S7_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S7_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S7_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S7_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S7_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S7_AXI_GEN_RID,
        S_AXI_RDATA               => S7_AXI_GEN_RDATA,
        S_AXI_RRESP               => S7_AXI_GEN_RRESP,
        S_AXI_RLAST               => S7_AXI_GEN_RLAST,
        S_AXI_RVALID              => S7_AXI_GEN_RVALID,
        S_AXI_RREADY              => S7_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 7),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 7 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 7) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 7),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 7 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 7) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 7),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 7),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 7),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 7),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 7),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 7 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 7) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 7 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 7) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 7),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 7),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 7),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 7),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 7),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 7),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 7),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 7),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 7),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 7),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 7),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 7 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 7 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 7),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 7),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 7),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(7),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(7),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(7),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(7),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(7),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(7),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(7),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(7),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(7),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(7),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(7),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(7),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(23),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF7_DEBUG 
      );
  end generate Use_Generic_Port_7;
  
  No_Generic_Port_7: if ( C_NUM_GENERIC_PORTS < 8 ) generate
  begin
    S7_AXI_GEN_AWREADY    <= '0';
    S7_AXI_GEN_WREADY     <= '0';
    S7_AXI_GEN_BRESP      <= (others=>'0');
    S7_AXI_GEN_BID        <= (others=>'0');
    S7_AXI_GEN_BVALID     <= '0';
    S7_AXI_GEN_ARREADY    <= '0';
    S7_AXI_GEN_RID        <= (others=>'0');
    S7_AXI_GEN_RDATA      <= (others=>'0');
    S7_AXI_GEN_RRESP      <= (others=>'0');
    S7_AXI_GEN_RLAST      <= '0';
    S7_AXI_GEN_RVALID     <= '0';
    port_assert_error(23) <= '0';
    GEN_IF7_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_7;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #8
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+8
  
  Use_Generic_Port_8: if ( C_NUM_GENERIC_PORTS > 8 ) generate
  begin
    AXI_8: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S8_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S8_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S8_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S8_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S8_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S8_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S8_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S8_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S8_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S8_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S8_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S8_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S8_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S8_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 8,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S8_AXI_GEN_AWID,
        S_AXI_AWADDR              => S8_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S8_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S8_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S8_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S8_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S8_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S8_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S8_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S8_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S8_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S8_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S8_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S8_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S8_AXI_GEN_WLAST,
        S_AXI_WVALID              => S8_AXI_GEN_WVALID,
        S_AXI_WREADY              => S8_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S8_AXI_GEN_BRESP,
        S_AXI_BID                 => S8_AXI_GEN_BID,
        S_AXI_BVALID              => S8_AXI_GEN_BVALID,
        S_AXI_BREADY              => S8_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S8_AXI_GEN_ARID,
        S_AXI_ARADDR              => S8_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S8_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S8_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S8_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S8_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S8_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S8_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S8_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S8_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S8_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S8_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S8_AXI_GEN_RID,
        S_AXI_RDATA               => S8_AXI_GEN_RDATA,
        S_AXI_RRESP               => S8_AXI_GEN_RRESP,
        S_AXI_RLAST               => S8_AXI_GEN_RLAST,
        S_AXI_RVALID              => S8_AXI_GEN_RVALID,
        S_AXI_RREADY              => S8_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 8),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 8 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 8) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 8),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 8 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 8) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 8),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 8),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 8),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 8),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 8),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 8 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 8) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 8 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 8) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 8),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 8),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 8),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 8),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 8),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 8),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 8),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 8),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 8),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 8),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 8),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 8 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 8 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 8),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 8),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 8),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(8),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(8),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(8),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(8),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(8),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(8),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(8),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(8),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(8),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(8),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(8),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(8),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(24),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF8_DEBUG 
      );
  end generate Use_Generic_Port_8;
  
  No_Generic_Port_8: if ( C_NUM_GENERIC_PORTS < 9 ) generate
  begin
    S8_AXI_GEN_AWREADY    <= '0';
    S8_AXI_GEN_WREADY     <= '0';
    S8_AXI_GEN_BRESP      <= (others=>'0');
    S8_AXI_GEN_BID        <= (others=>'0');
    S8_AXI_GEN_BVALID     <= '0';
    S8_AXI_GEN_ARREADY    <= '0';
    S8_AXI_GEN_RID        <= (others=>'0');
    S8_AXI_GEN_RDATA      <= (others=>'0');
    S8_AXI_GEN_RRESP      <= (others=>'0');
    S8_AXI_GEN_RLAST      <= '0';
    S8_AXI_GEN_RVALID     <= '0';
    port_assert_error(24) <= '0';
    GEN_IF8_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_8;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #9
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+9
  
  Use_Generic_Port_9: if ( C_NUM_GENERIC_PORTS > 9 ) generate
  begin
    AXI_9: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S9_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S9_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S9_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S9_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S9_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S9_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S9_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S9_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S9_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S9_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S9_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S9_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S9_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S9_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 9,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S9_AXI_GEN_AWID,
        S_AXI_AWADDR              => S9_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S9_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S9_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S9_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S9_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S9_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S9_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S9_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S9_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S9_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S9_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S9_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S9_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S9_AXI_GEN_WLAST,
        S_AXI_WVALID              => S9_AXI_GEN_WVALID,
        S_AXI_WREADY              => S9_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S9_AXI_GEN_BRESP,
        S_AXI_BID                 => S9_AXI_GEN_BID,
        S_AXI_BVALID              => S9_AXI_GEN_BVALID,
        S_AXI_BREADY              => S9_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S9_AXI_GEN_ARID,
        S_AXI_ARADDR              => S9_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S9_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S9_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S9_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S9_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S9_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S9_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S9_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S9_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S9_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S9_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S9_AXI_GEN_RID,
        S_AXI_RDATA               => S9_AXI_GEN_RDATA,
        S_AXI_RRESP               => S9_AXI_GEN_RRESP,
        S_AXI_RLAST               => S9_AXI_GEN_RLAST,
        S_AXI_RVALID              => S9_AXI_GEN_RVALID,
        S_AXI_RREADY              => S9_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 9),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 9 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 9) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 9),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 9 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 9) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 9),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 9),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 9),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 9),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 9),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 9 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 9) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 9 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 9) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 9),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 9),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 9),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 9),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 9),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 9),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 9),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 9),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 9),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 9),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 9),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 9 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 9 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 9),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 9),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 9),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(9),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(9),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(9),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(9),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(9),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(9),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(9),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(9),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(9),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(9),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(9),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(9),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(25),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF9_DEBUG 
      );
  end generate Use_Generic_Port_9;
  
  No_Generic_Port_9: if ( C_NUM_GENERIC_PORTS < 10 ) generate
  begin
    S9_AXI_GEN_AWREADY    <= '0';
    S9_AXI_GEN_WREADY     <= '0';
    S9_AXI_GEN_BRESP      <= (others=>'0');
    S9_AXI_GEN_BID        <= (others=>'0');
    S9_AXI_GEN_BVALID     <= '0';
    S9_AXI_GEN_ARREADY    <= '0';
    S9_AXI_GEN_RID        <= (others=>'0');
    S9_AXI_GEN_RDATA      <= (others=>'0');
    S9_AXI_GEN_RRESP      <= (others=>'0');
    S9_AXI_GEN_RLAST      <= '0';
    S9_AXI_GEN_RVALID     <= '0';
    port_assert_error(25) <= '0';
    GEN_IF9_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_9;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #10
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+10
  
  Use_Generic_Port_10: if ( C_NUM_GENERIC_PORTS > 10 ) generate
  begin
    AXI_10: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S10_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S10_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S10_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S10_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S10_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S10_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S10_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S10_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S10_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S10_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S10_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S10_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S10_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S10_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 10,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S10_AXI_GEN_AWID,
        S_AXI_AWADDR              => S10_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S10_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S10_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S10_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S10_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S10_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S10_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S10_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S10_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S10_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S10_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S10_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S10_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S10_AXI_GEN_WLAST,
        S_AXI_WVALID              => S10_AXI_GEN_WVALID,
        S_AXI_WREADY              => S10_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S10_AXI_GEN_BRESP,
        S_AXI_BID                 => S10_AXI_GEN_BID,
        S_AXI_BVALID              => S10_AXI_GEN_BVALID,
        S_AXI_BREADY              => S10_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S10_AXI_GEN_ARID,
        S_AXI_ARADDR              => S10_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S10_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S10_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S10_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S10_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S10_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S10_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S10_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S10_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S10_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S10_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S10_AXI_GEN_RID,
        S_AXI_RDATA               => S10_AXI_GEN_RDATA,
        S_AXI_RRESP               => S10_AXI_GEN_RRESP,
        S_AXI_RLAST               => S10_AXI_GEN_RLAST,
        S_AXI_RVALID              => S10_AXI_GEN_RVALID,
        S_AXI_RREADY              => S10_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 10),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 10 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 10) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 10),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 10 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 10) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 10),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 10),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 10),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 10),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 10),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 10 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 10) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 10 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 10) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 10),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 10),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 10),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 10),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 10),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 10),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 10),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 10),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 10),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 10),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 10),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 10 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 10 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 10),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 10),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 10),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(10),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(10),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(10),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(10),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(10),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(10),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(10),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(10),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(10),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(10),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(10),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(10),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(26),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF10_DEBUG 
      );
  end generate Use_Generic_Port_10;
  
  No_Generic_Port_10: if ( C_NUM_GENERIC_PORTS < 11 ) generate
  begin
    S10_AXI_GEN_AWREADY    <= '0';
    S10_AXI_GEN_WREADY     <= '0';
    S10_AXI_GEN_BRESP      <= (others=>'0');
    S10_AXI_GEN_BID        <= (others=>'0');
    S10_AXI_GEN_BVALID     <= '0';
    S10_AXI_GEN_ARREADY    <= '0';
    S10_AXI_GEN_RID        <= (others=>'0');
    S10_AXI_GEN_RDATA      <= (others=>'0');
    S10_AXI_GEN_RRESP      <= (others=>'0');
    S10_AXI_GEN_RLAST      <= '0';
    S10_AXI_GEN_RVALID     <= '0';
    port_assert_error(26)  <= '0';
    GEN_IF10_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_10;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #11
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+11
  
  Use_Generic_Port_11: if ( C_NUM_GENERIC_PORTS > 11 ) generate
  begin
    AXI_11: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S11_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S11_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S11_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S11_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S11_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S11_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S11_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S11_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S11_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S11_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S11_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S11_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S11_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S11_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 11,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S11_AXI_GEN_AWID,
        S_AXI_AWADDR              => S11_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S11_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S11_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S11_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S11_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S11_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S11_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S11_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S11_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S11_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S11_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S11_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S11_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S11_AXI_GEN_WLAST,
        S_AXI_WVALID              => S11_AXI_GEN_WVALID,
        S_AXI_WREADY              => S11_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S11_AXI_GEN_BRESP,
        S_AXI_BID                 => S11_AXI_GEN_BID,
        S_AXI_BVALID              => S11_AXI_GEN_BVALID,
        S_AXI_BREADY              => S11_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S11_AXI_GEN_ARID,
        S_AXI_ARADDR              => S11_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S11_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S11_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S11_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S11_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S11_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S11_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S11_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S11_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S11_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S11_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S11_AXI_GEN_RID,
        S_AXI_RDATA               => S11_AXI_GEN_RDATA,
        S_AXI_RRESP               => S11_AXI_GEN_RRESP,
        S_AXI_RLAST               => S11_AXI_GEN_RLAST,
        S_AXI_RVALID              => S11_AXI_GEN_RVALID,
        S_AXI_RREADY              => S11_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 11),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 11 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 11) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 11),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 11 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 11) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 11),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 11),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 11),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 11),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 11),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 11 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 11) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 11 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 11) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 11),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 11),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 11),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 11),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 11),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 11),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 11),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 11),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 11),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 11),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 11),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 11 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 11 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 11),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 11),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 11),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(11),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(11),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(11),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(11),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(11),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(11),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(11),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(11),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(11),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(11),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(11),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(11),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(27),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF11_DEBUG 
      );
  end generate Use_Generic_Port_11;
  
  No_Generic_Port_11: if ( C_NUM_GENERIC_PORTS < 12 ) generate
  begin
    S11_AXI_GEN_AWREADY    <= '0';
    S11_AXI_GEN_WREADY     <= '0';
    S11_AXI_GEN_BRESP      <= (others=>'0');
    S11_AXI_GEN_BID        <= (others=>'0');
    S11_AXI_GEN_BVALID     <= '0';
    S11_AXI_GEN_ARREADY    <= '0';
    S11_AXI_GEN_RID        <= (others=>'0');
    S11_AXI_GEN_RDATA      <= (others=>'0');
    S11_AXI_GEN_RRESP      <= (others=>'0');
    S11_AXI_GEN_RLAST      <= '0';
    S11_AXI_GEN_RVALID     <= '0';
    port_assert_error(27)  <= '0';
    GEN_IF11_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_11;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #12
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+12
  
  Use_Generic_Port_12: if ( C_NUM_GENERIC_PORTS > 12 ) generate
  begin
    AXI_12: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S12_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S12_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S12_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S12_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S12_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S12_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S12_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S12_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S12_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S12_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S12_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S12_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S12_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S12_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 12,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S12_AXI_GEN_AWID,
        S_AXI_AWADDR              => S12_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S12_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S12_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S12_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S12_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S12_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S12_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S12_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S12_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S12_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S12_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S12_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S12_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S12_AXI_GEN_WLAST,
        S_AXI_WVALID              => S12_AXI_GEN_WVALID,
        S_AXI_WREADY              => S12_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S12_AXI_GEN_BRESP,
        S_AXI_BID                 => S12_AXI_GEN_BID,
        S_AXI_BVALID              => S12_AXI_GEN_BVALID,
        S_AXI_BREADY              => S12_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S12_AXI_GEN_ARID,
        S_AXI_ARADDR              => S12_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S12_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S12_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S12_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S12_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S12_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S12_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S12_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S12_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S12_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S12_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S12_AXI_GEN_RID,
        S_AXI_RDATA               => S12_AXI_GEN_RDATA,
        S_AXI_RRESP               => S12_AXI_GEN_RRESP,
        S_AXI_RLAST               => S12_AXI_GEN_RLAST,
        S_AXI_RVALID              => S12_AXI_GEN_RVALID,
        S_AXI_RREADY              => S12_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 12),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 12 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 12) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 12),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 12 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 12) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 12),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 12),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 12),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 12),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 12),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 12 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 12) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 12 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 12) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 12),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 12),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 12),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 12),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 12),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 12),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 12),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 12),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 12),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 12),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 12),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 12 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 12 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 12),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 12),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 12),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(12),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(12),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(12),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(12),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(12),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(12),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(12),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(12),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(12),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(12),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(12),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(12),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(28),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF12_DEBUG 
      );
  end generate Use_Generic_Port_12;
  
  No_Generic_Port_12: if ( C_NUM_GENERIC_PORTS < 13 ) generate
  begin
    S12_AXI_GEN_AWREADY    <= '0';
    S12_AXI_GEN_WREADY     <= '0';
    S12_AXI_GEN_BRESP      <= (others=>'0');
    S12_AXI_GEN_BID        <= (others=>'0');
    S12_AXI_GEN_BVALID     <= '0';
    S12_AXI_GEN_ARREADY    <= '0';
    S12_AXI_GEN_RID        <= (others=>'0');
    S12_AXI_GEN_RDATA      <= (others=>'0');
    S12_AXI_GEN_RRESP      <= (others=>'0');
    S12_AXI_GEN_RLAST      <= '0';
    S12_AXI_GEN_RVALID     <= '0';
    port_assert_error(28)  <= '0';
    GEN_IF12_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_12;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #13
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+13
  
  Use_Generic_Port_13: if ( C_NUM_GENERIC_PORTS > 13 ) generate
  begin
    AXI_13: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S13_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S13_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S13_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S13_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S13_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S13_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S13_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S13_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S13_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S13_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S13_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S13_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S13_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S13_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 13,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S13_AXI_GEN_AWID,
        S_AXI_AWADDR              => S13_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S13_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S13_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S13_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S13_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S13_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S13_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S13_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S13_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S13_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S13_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S13_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S13_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S13_AXI_GEN_WLAST,
        S_AXI_WVALID              => S13_AXI_GEN_WVALID,
        S_AXI_WREADY              => S13_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S13_AXI_GEN_BRESP,
        S_AXI_BID                 => S13_AXI_GEN_BID,
        S_AXI_BVALID              => S13_AXI_GEN_BVALID,
        S_AXI_BREADY              => S13_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S13_AXI_GEN_ARID,
        S_AXI_ARADDR              => S13_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S13_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S13_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S13_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S13_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S13_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S13_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S13_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S13_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S13_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S13_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S13_AXI_GEN_RID,
        S_AXI_RDATA               => S13_AXI_GEN_RDATA,
        S_AXI_RRESP               => S13_AXI_GEN_RRESP,
        S_AXI_RLAST               => S13_AXI_GEN_RLAST,
        S_AXI_RVALID              => S13_AXI_GEN_RVALID,
        S_AXI_RREADY              => S13_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 13),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 13 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 13) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 13),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 13 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 13) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 13),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 13),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 13),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 13),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 13),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 13 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 13) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 13 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 13) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 13),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 13),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 13),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 13),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 13),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 13),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 13),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 13),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 13),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 13),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 13),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 13 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 13 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 13),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 13),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 13),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(13),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(13),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(13),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(13),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(13),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(13),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(13),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(13),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(13),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(13),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(13),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(13),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(29),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF13_DEBUG 
      );
  end generate Use_Generic_Port_13;
  
  No_Generic_Port_13: if ( C_NUM_GENERIC_PORTS < 14 ) generate
  begin
    S13_AXI_GEN_AWREADY    <= '0';
    S13_AXI_GEN_WREADY     <= '0';
    S13_AXI_GEN_BRESP      <= (others=>'0');
    S13_AXI_GEN_BID        <= (others=>'0');
    S13_AXI_GEN_BVALID     <= '0';
    S13_AXI_GEN_ARREADY    <= '0';
    S13_AXI_GEN_RID        <= (others=>'0');
    S13_AXI_GEN_RDATA      <= (others=>'0');
    S13_AXI_GEN_RRESP      <= (others=>'0');
    S13_AXI_GEN_RLAST      <= '0';
    S13_AXI_GEN_RVALID     <= '0';
    port_assert_error(29)  <= '0';
    GEN_IF13_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_13;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #14
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+14
  
  Use_Generic_Port_14: if ( C_NUM_GENERIC_PORTS > 14 ) generate
  begin
    AXI_14: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S14_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S14_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S14_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S14_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S14_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S14_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S14_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S14_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S14_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S14_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S14_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S14_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S14_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S14_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 14,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S14_AXI_GEN_AWID,
        S_AXI_AWADDR              => S14_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S14_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S14_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S14_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S14_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S14_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S14_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S14_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S14_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S14_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S14_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S14_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S14_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S14_AXI_GEN_WLAST,
        S_AXI_WVALID              => S14_AXI_GEN_WVALID,
        S_AXI_WREADY              => S14_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S14_AXI_GEN_BRESP,
        S_AXI_BID                 => S14_AXI_GEN_BID,
        S_AXI_BVALID              => S14_AXI_GEN_BVALID,
        S_AXI_BREADY              => S14_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S14_AXI_GEN_ARID,
        S_AXI_ARADDR              => S14_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S14_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S14_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S14_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S14_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S14_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S14_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S14_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S14_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S14_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S14_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S14_AXI_GEN_RID,
        S_AXI_RDATA               => S14_AXI_GEN_RDATA,
        S_AXI_RRESP               => S14_AXI_GEN_RRESP,
        S_AXI_RLAST               => S14_AXI_GEN_RLAST,
        S_AXI_RVALID              => S14_AXI_GEN_RVALID,
        S_AXI_RREADY              => S14_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 14),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 14 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 14) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 14),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 14 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 14) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 14),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 14),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 14),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 14),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 14),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 14 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 14) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 14 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 14) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 14),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 14),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 14),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 14),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 14),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 14),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 14),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 14),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 14),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 14),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 14),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 14 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 14 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 14),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 14),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 14),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(14),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(14),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(14),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(14),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(14),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(14),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(14),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(14),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(14),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(14),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(14),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(14),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(30),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF14_DEBUG 
      );
  end generate Use_Generic_Port_14;
  
  No_Generic_Port_14: if ( C_NUM_GENERIC_PORTS < 15 ) generate
  begin
    S14_AXI_GEN_AWREADY    <= '0';
    S14_AXI_GEN_WREADY     <= '0';
    S14_AXI_GEN_BRESP      <= (others=>'0');
    S14_AXI_GEN_BID        <= (others=>'0');
    S14_AXI_GEN_BVALID     <= '0';
    S14_AXI_GEN_ARREADY    <= '0';
    S14_AXI_GEN_RID        <= (others=>'0');
    S14_AXI_GEN_RDATA      <= (others=>'0');
    S14_AXI_GEN_RRESP      <= (others=>'0');
    S14_AXI_GEN_RLAST      <= '0';
    S14_AXI_GEN_RVALID     <= '0';
    port_assert_error(30)  <= '0';
    GEN_IF14_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_14;
  
  
  -----------------------------------------------------------------------------
  -- Generic AXI Slave Interface #15
  -----------------------------------------------------------------------------
  -- idx=C_NUM_OPTIMIZED_PORTS+15
  
  Use_Generic_Port_15: if ( C_NUM_GENERIC_PORTS > 15 ) generate
  begin
    AXI_15: sc_s_axi_gen_interface
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => C_USE_STATISTICS,
        C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
        
        -- AXI4 Interface Specific.
        C_S_AXI_BASEADDR          => C_S15_AXI_GEN_BASEADDR,
        C_S_AXI_HIGHADDR          => C_S15_AXI_GEN_HIGHADDR,
        C_S_AXI_DATA_WIDTH        => C_S15_AXI_GEN_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH        => C_S15_AXI_GEN_ADDR_WIDTH,
        C_S_AXI_ID_WIDTH          => C_S15_AXI_GEN_ID_WIDTH,
        C_S_AXI_FORCE_READ_ALLOCATE     => C_S15_AXI_GEN_FORCE_READ_ALLOCATE,
        C_S_AXI_PROHIBIT_READ_ALLOCATE  => C_S15_AXI_GEN_PROHIBIT_READ_ALLOCATE,
        C_S_AXI_FORCE_WRITE_ALLOCATE    => C_S15_AXI_GEN_FORCE_WRITE_ALLOCATE,
        C_S_AXI_PROHIBIT_WRITE_ALLOCATE => C_S15_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
        C_S_AXI_FORCE_READ_BUFFER       => C_S15_AXI_GEN_FORCE_READ_BUFFER,
        C_S_AXI_PROHIBIT_READ_BUFFER    => C_S15_AXI_GEN_PROHIBIT_READ_BUFFER,
        C_S_AXI_FORCE_WRITE_BUFFER      => C_S15_AXI_GEN_FORCE_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_WRITE_BUFFER   => C_S15_AXI_GEN_PROHIBIT_WRITE_BUFFER,
        C_S_AXI_PROHIBIT_EXCLUSIVE      => C_S15_AXI_GEN_PROHIBIT_EXCLUSIVE,
        
        -- Data type and settings specific.
        C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
        C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
        C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
        C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
        C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
        C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
        
        -- L1 Cache Specific.
        C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_HI,
        C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_LO,
        C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
        C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
        C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_HI,
        C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_LO,
        C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_HI,
        C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_LO,
        C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
        C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
        
        -- PARD Specific.
        C_DSID_WIDTH              => C_DSID_WIDTH,
        
        -- System Cache Specific.
        C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
        C_ID_WIDTH                => C_ID_WIDTH,
        C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
        C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
        C_NUM_PORTS               => C_NUM_PORTS,
        C_PORT_NUM                => C_NUM_OPTIMIZED_PORTS + 15,
        C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
        C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
        C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
        C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- AXI4/ACE Slave Interface Signals.
        
        -- AW-Channel
        S_AXI_AWID                => S15_AXI_GEN_AWID,
        S_AXI_AWADDR              => S15_AXI_GEN_AWADDR,
        S_AXI_AWLEN               => S15_AXI_GEN_AWLEN,
        S_AXI_AWSIZE              => S15_AXI_GEN_AWSIZE,
        S_AXI_AWBURST             => S15_AXI_GEN_AWBURST,
        S_AXI_AWLOCK              => S15_AXI_GEN_AWLOCK,
        S_AXI_AWCACHE             => S15_AXI_GEN_AWCACHE,
        S_AXI_AWPROT              => S15_AXI_GEN_AWPROT,
        S_AXI_AWQOS               => S15_AXI_GEN_AWQOS,
        S_AXI_AWVALID             => S15_AXI_GEN_AWVALID,
        S_AXI_AWREADY             => S15_AXI_GEN_AWREADY,
        S_AXI_AWUSER              => S15_AXI_GEN_AWUSER,
    
        -- W-Channel
        S_AXI_WDATA               => S15_AXI_GEN_WDATA,
        S_AXI_WSTRB               => S15_AXI_GEN_WSTRB,
        S_AXI_WLAST               => S15_AXI_GEN_WLAST,
        S_AXI_WVALID              => S15_AXI_GEN_WVALID,
        S_AXI_WREADY              => S15_AXI_GEN_WREADY,
    
        -- B-Channel
        S_AXI_BRESP               => S15_AXI_GEN_BRESP,
        S_AXI_BID                 => S15_AXI_GEN_BID,
        S_AXI_BVALID              => S15_AXI_GEN_BVALID,
        S_AXI_BREADY              => S15_AXI_GEN_BREADY,
    
        -- AR-Channel
        S_AXI_ARID                => S15_AXI_GEN_ARID,
        S_AXI_ARADDR              => S15_AXI_GEN_ARADDR,
        S_AXI_ARLEN               => S15_AXI_GEN_ARLEN,
        S_AXI_ARSIZE              => S15_AXI_GEN_ARSIZE,
        S_AXI_ARBURST             => S15_AXI_GEN_ARBURST,
        S_AXI_ARLOCK              => S15_AXI_GEN_ARLOCK,
        S_AXI_ARCACHE             => S15_AXI_GEN_ARCACHE,
        S_AXI_ARPROT              => S15_AXI_GEN_ARPROT,
        S_AXI_ARQOS               => S15_AXI_GEN_ARQOS,
        S_AXI_ARVALID             => S15_AXI_GEN_ARVALID,
        S_AXI_ARREADY             => S15_AXI_GEN_ARREADY,
        S_AXI_ARUSER              => S15_AXI_GEN_ARUSER,
    
        -- R-Channel
        S_AXI_RID                 => S15_AXI_GEN_RID,
        S_AXI_RDATA               => S15_AXI_GEN_RDATA,
        S_AXI_RRESP               => S15_AXI_GEN_RRESP,
        S_AXI_RLAST               => S15_AXI_GEN_RLAST,
        S_AXI_RVALID              => S15_AXI_GEN_RVALID,
        S_AXI_RREADY              => S15_AXI_GEN_RREADY,
    
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (All request).
        
        arbiter_piperun           => gen_port_piperun(15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write request).
        
        wr_port_access            => wr_port_access(C_NUM_OPTIMIZED_PORTS + 15),
        wr_port_id                => wr_port_id((C_NUM_OPTIMIZED_PORTS + 15 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 15) * C_ID_WIDTH),
        wr_port_ready             => wr_port_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        rd_port_access            => rd_port_access(C_NUM_OPTIMIZED_PORTS + 15),
        rd_port_id                => rd_port_id((C_NUM_OPTIMIZED_PORTS + 15 + 1) * C_ID_WIDTH - 1 downto 
                                                (C_NUM_OPTIMIZED_PORTS + 15) * C_ID_WIDTH),
        rd_port_ready             => rd_port_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Snoop communication).
        
        snoop_fetch_piperun       => snoop_fetch_piperun,
        snoop_fetch_valid         => snoop_fetch_valid,
        snoop_fetch_addr          => snoop_fetch_addr,
        snoop_fetch_myself        => snoop_fetch_myself(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_fetch_sync          => snoop_fetch_sync(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard(C_NUM_OPTIMIZED_PORTS + 15),
        
        snoop_req_piperun         => snoop_req_piperun,
        snoop_req_valid           => snoop_req_valid,
        snoop_req_write           => snoop_req_write,
        snoop_req_size            => snoop_req_size,
        snoop_req_addr            => snoop_req_addr,
        snoop_req_snoop           => snoop_req_snoop(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_myself          => snoop_req_myself(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_always          => snoop_req_always(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_update_filter   => snoop_req_update_filter(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_want            => snoop_req_want(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_complete        => snoop_req_complete(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_req_complete_target => snoop_req_complete_target,
        
        snoop_act_piperun         => snoop_act_piperun,
        snoop_act_valid           => snoop_act_valid,
        snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
        snoop_act_write           => snoop_act_write,
        snoop_act_addr            => snoop_act_addr,
        snoop_act_prot            => snoop_act_prot,
        snoop_act_snoop           => snoop_act_snoop(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_myself          => snoop_act_myself(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_always          => snoop_act_always(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_tag_valid       => snoop_act_tag_valid(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_tag_unique      => snoop_act_tag_unique(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_tag_dirty       => snoop_act_tag_dirty(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_done            => snoop_act_done(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_use_external    => snoop_act_use_external(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_act_write_blocking  => snoop_act_write_blocking(C_NUM_OPTIMIZED_PORTS + 15),
        
        snoop_info_tag_valid      => snoop_info_tag_valid,
        snoop_info_tag_unique     => snoop_info_tag_unique(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_info_tag_dirty      => snoop_info_tag_dirty(C_NUM_OPTIMIZED_PORTS + 15),
        
        snoop_resp_valid          => snoop_resp_valid(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_resp_crresp         => snoop_resp_crresp(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_resp_ready          => snoop_resp_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        read_data_ex_rack         => read_data_ex_rack(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write Data).
        
        wr_port_data_valid        => wr_port_data_valid(C_NUM_OPTIMIZED_PORTS + 15),
        wr_port_data_last         => wr_port_data_last(C_NUM_OPTIMIZED_PORTS + 15),
        wr_port_data_be           => wr_port_data_be((C_NUM_OPTIMIZED_PORTS + 15 + 1) * C_CACHE_DATA_WIDTH/8 - 1 downto 
                                                     (C_NUM_OPTIMIZED_PORTS + 15) * C_CACHE_DATA_WIDTH/8),
        wr_port_data_word         => wr_port_data_word((C_NUM_OPTIMIZED_PORTS + 15 + 1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                       (C_NUM_OPTIMIZED_PORTS + 15) * C_CACHE_DATA_WIDTH),
        wr_port_data_ready        => wr_port_data_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Write response).
        
        access_bp_push            => access_bp_push(C_NUM_OPTIMIZED_PORTS + 15),
        access_bp_early           => access_bp_early(C_NUM_OPTIMIZED_PORTS + 15),
        
        update_ext_bresp_valid    => update_ext_bresp_valid(C_NUM_OPTIMIZED_PORTS + 15),
        update_ext_bresp          => update_ext_bresp,
        update_ext_bresp_ready    => update_ext_bresp_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read request).
        
        lookup_read_data_new      => lookup_read_data_new(C_NUM_OPTIMIZED_PORTS + 15),
        lookup_read_data_hit      => lookup_read_data_hit,
        lookup_read_data_snoop    => lookup_read_data_snoop,
        lookup_read_data_allocate => lookup_read_data_allocate,
        
        
        -- ---------------------------------------------------
        -- Internal Interface Signals (Read Data).
        
        read_info_almost_full     => read_info_almost_full(C_NUM_OPTIMIZED_PORTS + 15),
        read_info_full            => read_info_full(C_NUM_OPTIMIZED_PORTS + 15),
        read_data_hit_pop         => read_data_hit_pop(C_NUM_OPTIMIZED_PORTS + 15),
        read_data_hit_almost_full => read_data_hit_almost_full(C_NUM_OPTIMIZED_PORTS + 15),
        read_data_hit_full        => read_data_hit_full(C_NUM_OPTIMIZED_PORTS + 15),
        read_data_hit_fit         => read_data_hit_fit_i(C_NUM_OPTIMIZED_PORTS + 15),
        read_data_miss_full       => read_data_miss_full(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Snoop signals (Read Data & response).
        
        snoop_read_data_valid     => snoop_read_data_valid(C_NUM_OPTIMIZED_PORTS + 15),
        snoop_read_data_last      => snoop_read_data_last,
        snoop_read_data_resp      => snoop_read_data_resp,
        snoop_read_data_word      => snoop_read_data_word(( C_NUM_OPTIMIZED_PORTS + 15 + 1 ) * C_CACHE_DATA_WIDTH - 1 downto 
                                                          ( C_NUM_OPTIMIZED_PORTS + 15 ) * C_CACHE_DATA_WIDTH),
        snoop_read_data_ready     => snoop_read_data_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Lookup signals (Read Data).
        
        lookup_read_data_valid    => lookup_read_data_valid(C_NUM_OPTIMIZED_PORTS + 15),
        lookup_read_data_last     => lookup_read_data_last,
        lookup_read_data_resp     => lookup_read_data_resp,
        lookup_read_data_set      => lookup_read_data_set,
        lookup_read_data_word     => lookup_read_data_word,
        lookup_read_data_ready    => lookup_read_data_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Update signals (Read Data).
        
        update_read_data_valid    => update_read_data_valid(C_NUM_OPTIMIZED_PORTS + 15),
        update_read_data_last     => update_read_data_last,
        update_read_data_resp     => update_read_data_resp,
        update_read_data_word     => update_read_data_word,
        update_read_data_ready    => update_read_data_ready(C_NUM_OPTIMIZED_PORTS + 15),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                      => stat_reset,
        stat_enable                     => stat_enable,
        
        stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments(15),
        stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments(15),
        stat_s_axi_gen_rip              => stat_s_axi_gen_rip(15),
        stat_s_axi_gen_r                => stat_s_axi_gen_r(15),
        stat_s_axi_gen_bip              => stat_s_axi_gen_bip(15),
        stat_s_axi_gen_bp               => stat_s_axi_gen_bp(15),
        stat_s_axi_gen_wip              => stat_s_axi_gen_wip(15),
        stat_s_axi_gen_w                => stat_s_axi_gen_w(15),
        stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency(15),
        stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency(15),
        stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf(15),
        stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf(15),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => port_assert_error(31),
        
        
        -- ---------------------------------------------------
        -- Debug Signals.
        
        IF_DEBUG                  => GEN_IF15_DEBUG 
      );
  end generate Use_Generic_Port_15;
  
  No_Generic_Port_15: if ( C_NUM_GENERIC_PORTS < 16 ) generate
  begin
    S15_AXI_GEN_AWREADY    <= '0';
    S15_AXI_GEN_WREADY     <= '0';
    S15_AXI_GEN_BRESP      <= (others=>'0');
    S15_AXI_GEN_BID        <= (others=>'0');
    S15_AXI_GEN_BVALID     <= '0';
    S15_AXI_GEN_ARREADY    <= '0';
    S15_AXI_GEN_RID        <= (others=>'0');
    S15_AXI_GEN_RDATA      <= (others=>'0');
    S15_AXI_GEN_RRESP      <= (others=>'0');
    S15_AXI_GEN_RLAST      <= '0';
    S15_AXI_GEN_RVALID     <= '0';
    port_assert_error(31)  <= '0';
    GEN_IF15_DEBUG         <= (others=>'0');
  end generate No_Generic_Port_15;
  
  
  -----------------------------------------------------------------------------
  -- Arbiter
  -----------------------------------------------------------------------------
  
  ARB: sc_arbiter
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- IP Specific.
      C_ID_WIDTH                => C_ID_WIDTH,
      C_ENABLE_CTRL             => C_ENABLE_CTRL,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON,
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_GENERIC_PORTS       => C_NUM_GENERIC_PORTS,
      C_NUM_FAST_PORTS          => C_NUM_FAST_PORTS,
      C_NUM_PORTS               => C_NUM_PORTS
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      opt_port_piperun          => opt_port_piperun,
      arbiter_piperun           => arbiter_piperun,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            => wr_port_access,
      wr_port_id                => wr_port_id,
      wr_port_ready             => wr_port_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            => rd_port_access,
      rd_port_id                => rd_port_id,
      rd_port_ready             => rd_port_ready,
      
      
      -- ---------------------------------------------------
      -- Arbiter signals (to Access).
      
      arb_access                => arb_access,
      arb_access_id             => arb_access_id,
       
       
      -- ---------------------------------------------------
      -- Control If Transactions.
      
      ctrl_init_done            => ctrl_init_done,
      ctrl_access               => ctrl_access,
      ctrl_ready                => ctrl_ready,
      
      
      -- ---------------------------------------------------
      -- Port signals.
      
      arbiter_bp_push           => arbiter_bp_push,
      arbiter_bp_early          => arbiter_bp_early,
      
      wr_port_inbound           => wr_port_inbound,
      
      
      -- ---------------------------------------------------
      -- Access signals.
      
      access_piperun            => access_piperun,
      access_write_priority     => access_write_priority,
      access_other_write_prio   => access_other_write_prio,
      
      
      -- ---------------------------------------------------
      -- Port signals (to Arbiter).
      
      read_data_hit_fit         => read_data_hit_fit_i,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Arbiter).
      
      lookup_read_done          => lookup_read_done,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      => stat_reset,
      stat_enable                     => stat_enable,
      
      stat_arb_valid                  => stat_arb_valid,
      stat_arb_concurrent_accesses    => stat_arb_concurrent_accesses,
      stat_arb_opt_read_blocked       => stat_arb_opt_read_blocked,
      stat_arb_gen_read_blocked       => stat_arb_gen_read_blocked,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => arb_assert,
      
      
      -- ---------------------------------------------------
      -- Debug signals.
      
      ARBITER_DEBUG             => ARBITER_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- Access
  -----------------------------------------------------------------------------
  
  ACS: sc_access 
    generic map (
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- Data type and settings specific.
      C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_HI,
      C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_LO,
      
      -- IP Specific.
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_PORTS               => C_NUM_PORTS,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON,
      C_ID_WIDTH                => C_ID_WIDTH,
      
      -- Data type and settings specific.
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        => wr_port_data_valid,
      wr_port_data_last         => wr_port_data_last,
      wr_port_data_be           => wr_port_data_be,
      wr_port_data_word         => wr_port_data_word,
      wr_port_data_ready        => wr_port_data_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Snoop communication).
      
      snoop_fetch_piperun       => snoop_fetch_piperun,
      snoop_fetch_valid         => snoop_fetch_valid,
      snoop_fetch_addr          => snoop_fetch_addr,
      snoop_fetch_myself        => snoop_fetch_myself,
      snoop_fetch_sync          => snoop_fetch_sync,
      snoop_fetch_pos_hazard    => snoop_fetch_pos_hazard,
      
      snoop_req_piperun         => snoop_req_piperun,
      snoop_req_valid           => snoop_req_valid,
      snoop_req_write           => snoop_req_write,
      snoop_req_size            => snoop_req_size,
      snoop_req_addr            => snoop_req_addr,
      snoop_req_snoop           => snoop_req_snoop,
      snoop_req_myself          => snoop_req_myself,
      snoop_req_always          => snoop_req_always,
      snoop_req_update_filter   => snoop_req_update_filter,
      snoop_req_want            => snoop_req_want,
      snoop_req_complete        => snoop_req_complete,
      snoop_req_complete_target => snoop_req_complete_target,
      
      snoop_act_piperun         => snoop_act_piperun,
      snoop_act_valid           => snoop_act_valid,
      snoop_act_waiting_4_pipe  => snoop_act_waiting_4_pipe,
      snoop_act_write           => snoop_act_write,
      snoop_act_addr            => snoop_act_addr,
      snoop_act_prot            => snoop_act_prot,
      snoop_act_snoop           => snoop_act_snoop,
      snoop_act_myself          => snoop_act_myself,
      snoop_act_always          => snoop_act_always,
      snoop_act_tag_valid       => snoop_act_tag_valid,
      snoop_act_tag_unique      => snoop_act_tag_unique,
      snoop_act_tag_dirty       => snoop_act_tag_dirty,
      snoop_act_done            => snoop_act_done,
      snoop_act_use_external    => snoop_act_use_external,
      snoop_act_write_blocking  => snoop_act_write_blocking,
      
      snoop_info_tag_valid      => snoop_info_tag_valid,
      snoop_info_tag_unique     => snoop_info_tag_unique,
      snoop_info_tag_dirty      => snoop_info_tag_dirty,
      
      snoop_resp_valid          => snoop_resp_valid,
      snoop_resp_crresp         => snoop_resp_crresp,
      snoop_resp_ready          => snoop_resp_ready,
      
      read_data_ex_rack         => read_data_ex_rack,
        
      
      -- ---------------------------------------------------
      -- Arbiter signals.
      
      arb_access                => arb_access,
      arb_access_id             => arb_access_id,
      
      arbiter_bp_push           => arbiter_bp_push,
      arbiter_bp_early          => arbiter_bp_early,
      
      wr_port_inbound           => wr_port_inbound,
      
      
      -- ---------------------------------------------------
      -- Lookup signals.
      
      lookup_piperun            => lookup_piperun,
      
      lookup_write_data_ready   => lookup_write_data_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      update_write_data_ready   => update_write_data_ready,
      
      
      -- ---------------------------------------------------
      -- Access signals (for Arbiter).
      
      access_piperun            => access_piperun,
      access_write_priority     => access_write_priority,
      access_other_write_prio   => access_other_write_prio,
      
      access_bp_push            => access_bp_push,
      access_bp_early           => access_bp_early,
      
      
      -- ---------------------------------------------------
      -- Access signals (to Lookup/Update).
      
      access_valid              => access_valid,
      access_info               => access_info,
      access_use                => access_use,
      access_stp                => access_stp,
      access_id                 => access_id,
      
      access_data_valid         => access_data_valid,
      access_data_last          => access_data_last,
      access_data_be            => access_data_be,
      access_data_word          => access_data_word,
      
      
      -- ---------------------------------------------------
      -- Snoop signals (Read Data & response).
      
      snoop_read_data_valid     => snoop_read_data_valid,
      snoop_read_data_last      => snoop_read_data_last,
      snoop_read_data_resp      => snoop_read_data_resp,
      snoop_read_data_word      => snoop_read_data_word,
      snoop_read_data_ready     => snoop_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_access_valid         => stat_access_valid,
      stat_access_stall         => stat_access_stall,
      stat_access_fetch_stall   => stat_access_fetch_stall,
      stat_access_req_stall     => stat_access_req_stall,
      stat_access_act_stall     => stat_access_act_stall,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => acs_assert,
      
      
      -- ---------------------------------------------------
      -- Debug signals.
      
      ACCESS_DEBUG              => ACCESS_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- External signals
  -----------------------------------------------------------------------------
  
  read_data_hit_fit <= read_data_hit_fit_i;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect behaviour
  
  Assertions: block
  begin
    -- Detect condition
    assert_err(C_ASSERT_PORT_0_ERROR)  <= port_assert_error(0)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_1_ERROR)  <= port_assert_error(1)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_2_ERROR)  <= port_assert_error(2)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_3_ERROR)  <= port_assert_error(3)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_4_ERROR)  <= port_assert_error(4)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_5_ERROR)  <= port_assert_error(5)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_6_ERROR)  <= port_assert_error(6)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_7_ERROR)  <= port_assert_error(7)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_8_ERROR)  <= port_assert_error(8)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_9_ERROR)  <= port_assert_error(9)  when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_10_ERROR) <= port_assert_error(10) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_11_ERROR) <= port_assert_error(11) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_12_ERROR) <= port_assert_error(12) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_13_ERROR) <= port_assert_error(13) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_14_ERROR) <= port_assert_error(14) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_15_ERROR) <= port_assert_error(15) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_16_ERROR) <= port_assert_error(16) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_17_ERROR) <= port_assert_error(17) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_18_ERROR) <= port_assert_error(18) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_19_ERROR) <= port_assert_error(19) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_20_ERROR) <= port_assert_error(20) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_21_ERROR) <= port_assert_error(21) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_22_ERROR) <= port_assert_error(22) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_23_ERROR) <= port_assert_error(23) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_24_ERROR) <= port_assert_error(24) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_25_ERROR) <= port_assert_error(25) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_26_ERROR) <= port_assert_error(26) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_27_ERROR) <= port_assert_error(27) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_28_ERROR) <= port_assert_error(28) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_29_ERROR) <= port_assert_error(29) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_30_ERROR) <= port_assert_error(30) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_PORT_31_ERROR) <= port_assert_error(31) when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_ARBITER_ERROR) <= arb_assert           when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_ACCESS_ERROR)  <= acs_assert           when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_0_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 0 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_1_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 1 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_2_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 2 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_3_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 3 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_4_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 4 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_5_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 5 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_6_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 6 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_7_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 7 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_8_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 8 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_9_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 9 error."
        severity error;
    
    assert assert_err_1(C_ASSERT_PORT_10_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 10 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_11_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 11 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_12_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 12 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_13_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 13 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_14_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 14 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_15_ERROR) /= '1' 
      report "Frontend: Optimized AXI port 15 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_16_ERROR) /= '1' 
      report "Frontend: Generic AXI port 0 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_17_ERROR) /= '1' 
      report "Frontend: Generic AXI port 1 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_18_ERROR) /= '1' 
      report "Frontend: Generic AXI port 2 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_19_ERROR) /= '1' 
      report "Frontend: Generic AXI port 3 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_20_ERROR) /= '1' 
      report "Frontend: Generic AXI port 4 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_21_ERROR) /= '1' 
      report "Frontend: Generic AXI port 5 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_22_ERROR) /= '1' 
      report "Frontend: Generic AXI port 6 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_23_ERROR) /= '1' 
      report "Frontend: Generic AXI port 7 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_24_ERROR) /= '1' 
      report "Frontend: Generic AXI port 8 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_25_ERROR) /= '1' 
      report "Frontend: Generic AXI port 9 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_26_ERROR) /= '1' 
      report "Frontend: Generic AXI port 10 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_27_ERROR) /= '1' 
      report "Frontend: Generic AXI port 11 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_28_ERROR) /= '1' 
      report "Frontend: Generic AXI port 12 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_29_ERROR) /= '1' 
      report "Frontend: Generic AXI port 13 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_30_ERROR) /= '1' 
      report "Frontend: Generic AXI port 14 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_PORT_31_ERROR) /= '1' 
      report "Frontend: Generic AXI port 15 error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_ARBITER_ERROR) /= '1' 
      report "Frontend: Arbiter error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_ACCESS_ERROR) /= '1' 
      report "Frontend: Access error."
        severity error;
    
    -- pragma translate_on
  end block Assertions;
  
  
  -- ----------------------------------------
  -- Clocked to remove glites in simulation
  
  Delay_Assertions : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      assert_err_1  <= assert_err;
    end if;
  end process Delay_Assertions;
  
  -- Assign output
  assert_error  <= reduce_or(assert_err_1);
  
  
end architecture IMP;
