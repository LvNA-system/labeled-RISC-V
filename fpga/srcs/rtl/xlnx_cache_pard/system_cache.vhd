-------------------------------------------------------------------------------
-- system_cache.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2011,2013,2014 Xilinx, Inc. All rights reserved.
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
-- Filename:        system_cache.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              system_cache.vhd
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
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

entity system_cache is
  generic (
    -- General.
    C_FAMILY                  : string                        := "virtex7";
    C_INSTANCE                : string                        := "system_cache";
    C_FREQ                    : natural                       := 0;
    
    -- IP Specific.
    C_BASEADDR                : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
    C_HIGHADDR                : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    C_ENABLE_CTRL             : natural range  0 to    1      := 1;
    C_ENABLE_STATISTICS       : natural range  0 to  255      := 127;
    C_ENABLE_VERSION_REGISTER : natural range  0 to    3      := 2;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      := 8;
    C_NUM_GENERIC_PORTS       : natural range  0 to   32      := 2;
    C_ENABLE_COHERENCY        : natural range  0 to    1      := 0;
    C_ENABLE_EXCLUSIVE        : natural range  0 to    1      := 0;
    C_NUM_SETS                : natural range  2 to   32      := 16;
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
    C_CACHE_SIZE              : natural                       := 524288;

    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- Lx Cache specific.
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      := 4;
    C_Lx_CACHE_SIZE           : natural                       := 8192;
    
    -- Optimized AXI4 Slave Interface #0 specific.
    C_S0_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S0_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S0_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #1 specific.
    C_S1_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S1_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S1_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #2 specific.
    C_S2_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S2_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S2_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #3 specific.
    C_S3_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S3_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S3_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #4 specific.
    C_S4_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S4_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S4_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #5 specific.
    C_S5_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S5_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S5_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #6 specific.
    C_S6_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S6_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S6_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #7 specific.
    C_S7_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S7_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S7_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #8 specific.
    C_S8_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S8_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S8_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #9 specific.
    C_S9_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
    C_S9_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
    C_S9_AXI_ID_WIDTH         : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #10 specific.
    C_S10_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S10_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S10_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #11 specific.
    C_S11_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S11_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S11_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #12 specific.
    C_S12_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S12_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S12_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #13 specific.
    C_S13_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S13_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S13_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #14 specific.
    C_S14_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S14_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S14_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Optimized AXI4 Slave Interface #15 specific.
    C_S15_AXI_ADDR_WIDTH      : natural range 15 to   64      := 32;
    C_S15_AXI_DATA_WIDTH      : natural range 32 to 1024      := 32;
    C_S15_AXI_ID_WIDTH        : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #0 specific.
    C_S0_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S0_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S0_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #1 specific.
    C_S1_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S1_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S1_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #2 specific.
    C_S2_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S2_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S2_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #3 specific.
    C_S3_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S3_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S3_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #4 specific.
    C_S4_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S4_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S4_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #5 specific.
    C_S5_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S5_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S5_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #6 specific.
    C_S6_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S6_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S6_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #7 specific.
    C_S7_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S7_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S7_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #8 specific.
    C_S8_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S8_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S8_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #9 specific.
    C_S9_AXI_GEN_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S9_AXI_GEN_DATA_WIDTH   : natural range 32 to 1024      := 32;
    C_S9_AXI_GEN_ID_WIDTH     : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #10 specific.
    C_S10_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S10_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S10_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #11 specific.
    C_S11_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S11_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S11_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #12 specific.
    C_S12_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S12_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S12_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #13 specific.
    C_S13_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S13_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S13_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #14 specific.
    C_S14_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S14_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S14_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Generic AXI4 Slave Interface #15 specific.
    C_S15_AXI_GEN_ADDR_WIDTH  : natural range 15 to   64      := 32;
    C_S15_AXI_GEN_DATA_WIDTH  : natural range 32 to 1024      := 32;
    C_S15_AXI_GEN_ID_WIDTH    : natural                       := 1;
    
    -- Control AXI4-Lite Slave Interface specific.
    C_S_AXI_CTRL_ADDR_WIDTH   : natural range 15 to   64      := 32;
    C_S_AXI_CTRL_DATA_WIDTH   : natural range 32 to   64      := 32;
    
    -- AXI4 Master Interface specific.
    C_M_AXI_THREAD_ID_WIDTH   : natural range  1 to   32      :=  1;
    C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_M_AXI_ADDR_WIDTH        : natural range 15 to   64      := 32
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESETN                   : in  std_logic;
    
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
    S0_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S0_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S1_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S1_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S2_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S2_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S2_AXI_CRREADY            : out std_logic;                 							-- For ACE
    
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
    S3_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S3_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S4_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S4_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S5_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S5_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S6_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S6_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S7_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S7_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    -- Optimized AXI4/ACE Interface #8 Slave Signals
    
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
    S8_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S8_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S9_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S9_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S10_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S10_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S11_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S11_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S12_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S12_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S13_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S13_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S14_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S14_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S15_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S15_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S0_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S0_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S1_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S1_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S2_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S2_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S3_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S3_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S4_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S4_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S5_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S5_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S6_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S6_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S7_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S7_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S8_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S8_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S9_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S9_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S10_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S10_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S11_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S11_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S12_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S12_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S13_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S13_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S14_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S14_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S15_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
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
    S15_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
    S15_AXI_GEN_RID            : out std_logic_vector(C_S15_AXI_GEN_ID_WIDTH-1 downto 0);
    S15_AXI_GEN_RDATA          : out std_logic_vector(C_S15_AXI_GEN_DATA_WIDTH-1 downto 0);
    S15_AXI_GEN_RRESP          : out std_logic_vector(1 downto 0);
    S15_AXI_GEN_RLAST          : out std_logic;
    S15_AXI_GEN_RVALID         : out std_logic;
    S15_AXI_GEN_RREADY         : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Control AXI4-Lite Slave Interface Signals
    
    -- AW-Channel
    S_AXI_CTRL_AWADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_AWVALID             : in  std_logic;
    S_AXI_CTRL_AWREADY             : out std_logic;

    -- W-Channel
    S_AXI_CTRL_WDATA               : in  std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_WVALID              : in  std_logic;
    S_AXI_CTRL_WREADY              : out std_logic;

    -- B-Channel
    S_AXI_CTRL_BRESP               : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_BVALID              : out std_logic;
    S_AXI_CTRL_BREADY              : in  std_logic;

    -- AR-Channel
    S_AXI_CTRL_ARADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_ARVALID             : in  std_logic;
    S_AXI_CTRL_ARREADY             : out std_logic;

    -- R-Channel
    S_AXI_CTRL_RDATA               : out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_RRESP               : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_RVALID              : out std_logic;
    S_AXI_CTRL_RREADY              : in  std_logic;

    
    -- ---------------------------------------------------
    -- AXI4 Interface master signals.
    
    M_AXI_AWID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_AWADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_AWLEN               : out std_logic_vector(7 downto 0);
    M_AXI_AWSIZE              : out std_logic_vector(2 downto 0);
    M_AXI_AWBURST             : out std_logic_vector(1 downto 0);
    M_AXI_AWLOCK              : out std_logic;
    M_AXI_AWCACHE             : out std_logic_vector(3 downto 0);
    M_AXI_AWPROT              : out std_logic_vector(2 downto 0);
    M_AXI_AWQOS               : out std_logic_vector(3 downto 0);
    M_AXI_AWVALID             : out std_logic;
    M_AXI_AWREADY             : in  std_logic;
    M_AXI_AWUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
    M_AXI_WDATA               : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_WSTRB               : out std_logic_vector((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
    M_AXI_WLAST               : out std_logic;
    M_AXI_WVALID              : out std_logic;
    M_AXI_WREADY              : in  std_logic;
    
    M_AXI_BRESP               : in  std_logic_vector(1 downto 0);
    M_AXI_BID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_BVALID              : in  std_logic;
    M_AXI_BREADY              : out std_logic;
    
    M_AXI_ARID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_ARADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_ARLEN               : out std_logic_vector(7 downto 0);
    M_AXI_ARSIZE              : out std_logic_vector(2 downto 0);
    M_AXI_ARBURST             : out std_logic_vector(1 downto 0);
    M_AXI_ARLOCK              : out std_logic;
    M_AXI_ARCACHE             : out std_logic_vector(3 downto 0);
    M_AXI_ARPROT              : out std_logic_vector(2 downto 0);
    M_AXI_ARQOS               : out std_logic_vector(3 downto 0);
    M_AXI_ARVALID             : out std_logic;
    M_AXI_ARREADY             : in  std_logic;
    M_AXI_ARUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
    
    M_AXI_RID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_RDATA               : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_RRESP               : in  std_logic_vector(1 downto 0);
    M_AXI_RLAST               : in  std_logic;
    M_AXI_RVALID              : in  std_logic;
    M_AXI_RREADY              : out std_logic;

    --For PARD stab
    lookup_valid_to_stab                : out std_logic;
    lookup_DSid_to_stab                 : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    lookup_hit_to_stab          		: out std_logic;
    lookup_miss_to_stab         		: out std_logic;
    update_tag_en_to_stab               : out std_logic;
    update_tag_we_to_stab       		: out std_logic_vector(C_NUM_SETS - 1 downto 0);
    update_tag_old_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    update_tag_new_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    lru_history_en_to_ptab              : out std_logic;
    lru_dsid_valid_to_ptab              : out std_logic;
    lru_dsid_to_ptab                    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    way_mask_from_ptab                  : in  std_logic_vector(C_NUM_SETS - 1 downto 0)
  );
end entity system_cache;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.All;


architecture IMP of system_cache is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  --
  -- Top level for System Cache, instanciates the next level of the design and
  -- calculate constants for data wirdth, bit pattern etc form the current 
  -- configuration. 
  -- The four hierarcical blocks instantiated are:
  -- 
  -- * Front End (FE) for decoding and preparing incomming transactions to the
  --   internal data representation. Also arbitrates and from multiple ports 
  --   and forwards on transaction at the time to the next stage.
  --
  -- * Cache Core (CC) for the actual caching and mantainance of data.
  --
  -- * Back End (BE) for the communication with the memory sub system.
  --
  -- * Control interface for collecting and controlling statistics gathering.
  --
  --
  -- Address bit mapping:
  -- ====================
  --
  --                                    |<------------- Cache Size Addr Bits ------------>|
  --                  |<------- Tag Addr Bits ------->|
  --                                            |<-------- Data Index Bits -------->|
  --                                            |<-- Tag Index Bits --->|
  --   _______________ _________________ _____________ _________________ ___________ _____
  --  |_______________|_________________|_____________|_________________|___________|_____|
  --
  --   \_____________/ \_______________/ \___________/ \_______________/ \_________/ \___/
  --    |               |                 |             |                 |           |                 
  --    IP Valid Addr   Offset Addr       Set Bits      Line              Word Addr   Byte Addr
  --                                   /               \
  --                                  /                 \
  --                                 /                   \
  --                                /_____________ _______\ 
  --                                |_____________|_______|
  --                                                                     
  --                                \____________/ \_____/  
  --                                  |              |                 
  --                                  Parallel Addr  Serial Addr  
  --
  --
  -- TAG contents:
  -- =============
  --
  --   _ _ _ _ _________________ 
  --  |_|_|_|_|_________________|
  --
  --   | | | | \_______________/ 
  --   | | | Locked     | 
  --   | | Dirty        Tag Address bits
  --   | Reused
  --   Valid 
  --
  --
  -- Meaning:
  --  Valid   - TAG is valid and cacheline contains valid data
  --  Dirty   - Cacheline contains dirty data
  --  Locked  - Cacheline is locked and access to it has to be stalled until lock is released. A cacheline is 
  --            locked when it is allocated and waits for data to arrive from external memory.
  --  Address - Address bit for the cacheline
  --
  --
  -- Transaction Latency:
  -- ====================
  -- 
  -- Read Hit:    
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 3   (Mem, Check, Pipeline)
  --  Interface : 1   (Read Queue)
  --  => Total 4 clk
  --  
  -- Read Miss:
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 2   (Mem, Check)
  --  Update    : 1   (Update)
  --  Backend   : 2   (Queue, Register)
  --  Exernal   : x   (Interconnect, Memory)
  --  Interface : 1   (Read Queue)
  --  => Total 6+x clk
  --  
  -- Evict:
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 2   (Mem, Check)
  --  Update    : 3+d (Update, Queue, Data, Queue) d=32*cl/maxi dw
  
  -- Read Miss Dirty:
  --  If 2+d > x
  --    => Total 6+d
  --  else
  --    Same as Read Miss.
  -- 
  -- Write Hit:
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 2+d (Mem, Check, Data) d=max(0, burst len - 1)
  --  Interface : 2   (Queue, Register)
  --  => Total 4+d clk
  --  
  -- Write Miss:
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 2   (Mem, Check)
  --  Update    : 1   (Update)
  --  Backend   : 2   (Queue, Register)
  --  Exernal   : x   (Interconnect, Memory)
  --  Interface : 1   (Read Queue)
  --  => Total 6+x clk
  --  
  -- Write Miss Allocate:
  --  Arbiter   : 0   (pre arbited)
  --  Lookup    : 2   (Mem, Check)
  --  Update    : 2+d (Queue, Data, Queue)  d=burst len
  --  Interface : 1   (Read Queue)
  --  => Total 5+d clk
  --  
  -- Write Miss Dirty:
  --  => max(Write Miss Allocate, Evict) clk
  --  
  
    
  -----------------------------------------------------------------------------
  -- Disabled Constants
  -----------------------------------------------------------------------------
  
  -- IP Specific.
  constant C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  C_NUM_SETS;
    
  -- Debugging.
  constant C_USE_DEBUG               : natural range  0 to    1      :=  0;
    
  -- IP Specific Optimizations.
  constant C_OPTIMIZE_ORDER          : natural range  4 to    4      :=  4;
    
  -- Static configuration of read data pipeline.
  constant C_PIPELINE_LU_READ_DATA   : boolean                       := true;
  
  -- How to handle automatic cleaning of dirty lines.
  constant C_ENABLE_AUTOMATIC_CLEAN     : natural             := 0;
  constant C_AUTOMATIC_CLEAN_MODE       : natural             := 1;
  
  -- Optimized AXI4 Slave Interface #0 to #15 specific.
  constant C_S0_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S0_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S0_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S0_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S0_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S0_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S0_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S0_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S0_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S0_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S0_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S1_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S1_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S1_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S1_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S1_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S1_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S1_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S1_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S1_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S1_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S1_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S2_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S2_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S2_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S2_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S2_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S2_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S2_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S2_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S2_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S2_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S2_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S3_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S3_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S3_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S3_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S3_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S3_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S3_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S3_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S3_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S3_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S3_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S4_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S4_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S4_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S4_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S4_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S4_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S4_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S4_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S4_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S4_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S4_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S5_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S5_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S5_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S5_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S5_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S5_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S5_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S5_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S5_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S5_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S5_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S6_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S6_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S6_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S6_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S6_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S6_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S6_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S6_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S6_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S6_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S6_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S7_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S7_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S7_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S7_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S7_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S7_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S7_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S7_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S7_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S7_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S7_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S8_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S8_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S8_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S8_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S8_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S8_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S8_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S8_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S8_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S8_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S8_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S9_AXI_SUPPORT_UNIQUE              : natural range 0 to 1 :=  0;
  constant C_S9_AXI_SUPPORT_DIRTY               : natural range 0 to 1 :=  0;
  constant C_S9_AXI_FORCE_READ_ALLOCATE         : natural range 0 to 1 :=  1;
  constant C_S9_AXI_PROHIBIT_READ_ALLOCATE      : natural range 0 to 1 :=  0;
  constant C_S9_AXI_FORCE_WRITE_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S9_AXI_PROHIBIT_WRITE_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S9_AXI_FORCE_READ_BUFFER           : natural range 0 to 1 :=  0;
  constant C_S9_AXI_PROHIBIT_READ_BUFFER        : natural range 0 to 1 :=  0;
  constant C_S9_AXI_FORCE_WRITE_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S9_AXI_PROHIBIT_WRITE_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S9_AXI_PROHIBIT_EXCLUSIVE          : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S10_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S10_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S10_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S10_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S10_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S10_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S10_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S10_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S10_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S10_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S10_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S11_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S11_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S11_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S11_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S11_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S11_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S11_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S11_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S11_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S11_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S11_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S12_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S12_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S12_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S12_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S12_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S12_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S12_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S12_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S12_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S12_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S12_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S13_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S13_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S13_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S13_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S13_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S13_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S13_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S13_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S13_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S13_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S13_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S14_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S14_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S14_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S14_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S14_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S14_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S14_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S14_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S14_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S14_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S14_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  constant C_S15_AXI_SUPPORT_UNIQUE             : natural range 0 to 1 :=  0;
  constant C_S15_AXI_SUPPORT_DIRTY              : natural range 0 to 1 :=  0;
  constant C_S15_AXI_FORCE_READ_ALLOCATE        : natural range 0 to 1 :=  1;
  constant C_S15_AXI_PROHIBIT_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S15_AXI_FORCE_WRITE_ALLOCATE       : natural range 0 to 1 :=  1;
  constant C_S15_AXI_PROHIBIT_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S15_AXI_FORCE_READ_BUFFER          : natural range 0 to 1 :=  0;
  constant C_S15_AXI_PROHIBIT_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S15_AXI_FORCE_WRITE_BUFFER         : natural range 0 to 1 :=  0;
  constant C_S15_AXI_PROHIBIT_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S15_AXI_PROHIBIT_EXCLUSIVE         : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE + C_ENABLE_COHERENCY);
  
  -- Generic AXI4 Slave Interface #0 specific.
  constant C_S0_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S0_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S0_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S1_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S1_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S1_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S2_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S2_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S2_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S3_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S3_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S3_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S4_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S4_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S4_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S5_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S5_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S5_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S6_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S6_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S6_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S7_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S7_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S7_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S8_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S8_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S8_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S9_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S9_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S9_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S10_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S10_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S10_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                            is_off(C_ENABLE_COHERENCY);
  constant C_S11_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S11_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S11_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                            is_off(C_ENABLE_COHERENCY);
  constant C_S12_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S12_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S12_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                           is_off(C_ENABLE_COHERENCY);
  constant C_S13_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S13_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S13_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                            is_off(C_ENABLE_COHERENCY);
  constant C_S14_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S14_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S14_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                            is_off(C_ENABLE_COHERENCY);
  constant C_S15_AXI_GEN_FORCE_READ_ALLOCATE     : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_PROHIBIT_READ_ALLOCATE  : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_FORCE_WRITE_ALLOCATE    : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_PROHIBIT_WRITE_ALLOCATE : natural range 0 to 1 :=  1;
  constant C_S15_AXI_GEN_FORCE_READ_BUFFER       : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_PROHIBIT_READ_BUFFER    : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_FORCE_WRITE_BUFFER      : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_PROHIBIT_WRITE_BUFFER   : natural range 0 to 1 :=  0;
  constant C_S15_AXI_GEN_PROHIBIT_EXCLUSIVE      : natural range 0 to 1 :=  is_off(C_ENABLE_EXCLUSIVE) * 
                                                                            is_off(C_ENABLE_COHERENCY);
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  -- Translate family string to enumerated type.
  constant C_TARGET                     : TARGET_FAMILY_TYPE  := String_To_Family(C_FAMILY, false);
  
  -- Enable/Disable the debug information.
  constant C_USE_DEBUG_BOOL             : boolean             := ( C_USE_DEBUG /= 0);
    
  -- Enable/Disable the assertions.
  constant C_USE_ASSERTIONS             : boolean             := C_USE_DEBUG_BOOL;
  
  -- Enable/Disable the internal exclusive monitor.
  constant C_ENABLE_EX_MON              : natural range  0 to    1      :=  C_ENABLE_EXCLUSIVE * 
                                                                            ( 1 - C_ENABLE_COHERENCY );
  
  -- Enable/Disable statistics.
  constant C_USE_STATISTICS             : boolean                       := ( C_ENABLE_CTRL /= 0 );
  constant C_STAT_OPT_LAT_RD_DEPTH      : natural range  1 to   32      :=  4;
  constant C_STAT_OPT_LAT_WR_DEPTH      : natural range  1 to   32      := 16;
  constant C_STAT_GEN_LAT_RD_DEPTH      : natural range  1 to   32      := 16;
  constant C_STAT_GEN_LAT_WR_DEPTH      : natural range  1 to   32      := 16;
  constant C_STAT_MEM_LAT_RD_DEPTH      : natural range  1 to   32      := 16;
  constant C_STAT_MEM_LAT_WR_DEPTH      : natural range  1 to   32      := 16;
  constant C_STAT_BITS                  : natural range  1 to   64      := 32;
  constant C_STAT_BIG_BITS              : natural range  1 to   64      := 48;
  constant C_STAT_COUNTER_BITS          : natural range  1 to   31      := 16;
  constant C_STAT_MAX_CYCLE_WIDTH       : natural range  2 to   16      := 16;
  constant C_STAT_USE_STDDEV            : natural range  0 to    1      :=  1;
  
  -- Total number of ports.
  constant C_NUM_PORTS                  : positive            := C_NUM_OPTIMIZED_PORTS + C_NUM_GENERIC_PORTS;
  
  -- Lookup side of BRAM.  
  constant C_CACHE_DATA_ADDR_WIDTH      : natural             := Log2(C_CACHE_DATA_WIDTH/8);
  
  -- Update side of BRAM.  
  constant C_EXTERNAL_DATA_WIDTH        : natural             := C_M_AXI_DATA_WIDTH;
  constant C_EXTERNAL_DATA_ADDR_WIDTH   : natural             := Log2(C_EXTERNAL_DATA_WIDTH/8);
  
  -- Use same width for all addresses.
  constant C_S_AXI_ADDR_WIDTH           : natural             := 
                               max_of(max_of(max_of(max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  0,  C_S0_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  1,  C_S1_AXI_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS >  2,  C_S2_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  3,  C_S3_AXI_ADDR_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  4,  C_S4_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  5,  C_S5_AXI_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS >  6,  C_S6_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  7,  C_S7_AXI_ADDR_WIDTH, 0)))),
                                             max_of(max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  8,  C_S8_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  9,  C_S9_AXI_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS > 10, C_S10_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 11, C_S11_AXI_ADDR_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS > 12, C_S12_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 13, C_S12_AXI_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS > 14, C_S14_AXI_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 15, C_S15_AXI_ADDR_WIDTH, 0))))),
                                      max_of(max_of(max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  0,  C_S0_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  1,  C_S1_AXI_GEN_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   >  2,  C_S2_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  3,  C_S3_AXI_GEN_ADDR_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  4,  C_S4_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  5,  C_S5_AXI_GEN_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   >  6,  C_S6_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  7,  C_S7_AXI_GEN_ADDR_WIDTH, 0)))),
                                             max_of(max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  8,  C_S8_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  9,  C_S9_AXI_GEN_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   > 10, C_S10_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 11, C_S11_AXI_GEN_ADDR_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_GENERIC_PORTS   > 12, C_S12_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 13, C_S13_AXI_GEN_ADDR_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   > 14, C_S14_AXI_GEN_ADDR_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 15, C_S15_AXI_GEN_ADDR_WIDTH, 0))))));
  
  -- Use same width for snoop data.
  constant C_S_AXI_DATA_WIDTH           : natural             := C_S0_AXI_DATA_WIDTH;
  
  -- Maximal ID width for all active ports.
  constant C_ID_WIDTH                   : natural range  1 to   32      :=  
                               max_of(max_of(max_of(max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  0,  C_S0_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  1,  C_S1_AXI_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS >  2,  C_S2_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  3,  C_S3_AXI_ID_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  4,  C_S4_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  5,  C_S5_AXI_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS >  6,  C_S6_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  7,  C_S7_AXI_ID_WIDTH, 0)))),
                                             max_of(max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS >  8,  C_S8_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS >  9,  C_S9_AXI_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS > 10, C_S10_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 11, C_S11_AXI_ID_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_OPTIMIZED_PORTS > 12, C_S12_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 13, C_S12_AXI_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_OPTIMIZED_PORTS > 14, C_S14_AXI_ID_WIDTH, 0),
                                                                  sel(C_NUM_OPTIMIZED_PORTS > 15, C_S15_AXI_ID_WIDTH, 0))))),
                                      max_of(max_of(max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  0,  C_S0_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  1,  C_S1_AXI_GEN_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   >  2,  C_S2_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  3,  C_S3_AXI_GEN_ID_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  4,  C_S4_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  5,  C_S5_AXI_GEN_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   >  6,  C_S6_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  7,  C_S7_AXI_GEN_ID_WIDTH, 0)))),
                                             max_of(max_of(max_of(sel(C_NUM_GENERIC_PORTS   >  8,  C_S8_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   >  9,  C_S9_AXI_GEN_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   > 10, C_S10_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 11, C_S11_AXI_GEN_ID_WIDTH, 0))),
                                                    max_of(max_of(sel(C_NUM_GENERIC_PORTS   > 12, C_S12_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 13, C_S13_AXI_GEN_ID_WIDTH, 0)),
                                                           max_of(sel(C_NUM_GENERIC_PORTS   > 14, C_S14_AXI_GEN_ID_WIDTH, 0),
                                                                  sel(C_NUM_GENERIC_PORTS   > 15, C_S15_AXI_GEN_ID_WIDTH, 0))))));
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_FRONTEND_ERROR            : natural :=  0;
  constant C_ASSERT_CACHECORE_ERROR           : natural :=  1;
  constant C_ASSERT_BACKEND_ERROR             : natural :=  2;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  3;
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  -- Address bit sizes.
  constant C_VALID_ADDR_BITS          : natural := Addr_Bits(C_HIGHADDR, C_BASEADDR, C_S_AXI_ADDR_WIDTH);
  constant C_CACHE_SIZE_ADDR_BITS     : natural := log2(C_CACHE_SIZE);
  constant C_Lx_CACHE_SIZE_ADDR_BITS  : natural := log2(C_Lx_CACHE_SIZE);
  constant C_ASSOCIATIVE_ADDR_BITS    : natural := log2(C_NUM_SETS);
  constant C_PARALLEL_ASSOC_ADDR_BITS : natural := log2(C_NUM_PARALLEL_SETS);
  constant C_SERIAL_ASSOC_ADDR_BITS   : natural := C_ASSOCIATIVE_ADDR_BITS - C_PARALLEL_ASSOC_ADDR_BITS;
  constant C_NUM_SERIAL_SETS          : natural := 2 ** C_SERIAL_ASSOC_ADDR_BITS;
  constant C_LINE_ADDR_BITS           : natural := log2(C_CACHE_LINE_LENGTH);
  constant C_Lx_LINE_ADDR_BITS        : natural := log2(C_Lx_CACHE_LINE_LENGTH);
  constant C_WORD_ADDR_BITS           : natural := log2(C_CACHE_DATA_WIDTH / 8);
  constant C_Lx_WORD_ADDR_BITS        : natural := log2(sel(C_NUM_OPTIMIZED_PORTS > 0, C_S0_AXI_DATA_WIDTH, 
                                                                                       C_S0_AXI_GEN_DATA_WIDTH) / 8);
  constant C_EXT_WORD_ADDR_BITS       : natural := log2(C_EXTERNAL_DATA_WIDTH / 8);
  
  -- TAG information size.
  constant C_Lx_NUM_ADDR_TAG_BITS     : natural := C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - C_Lx_CACHE_SIZE_ADDR_BITS;
  constant C_NUM_ADDR_TAG_BITS        : natural := C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - C_CACHE_SIZE_ADDR_BITS + 
                                                   C_ASSOCIATIVE_ADDR_BITS;
  constant C_NUM_STATUS_BITS          : natural := 4;
  constant C_TAG_SIZE                 : natural := C_NUM_STATUS_BITS + C_NUM_ADDR_TAG_BITS + C_DSID_WIDTH;
  
  -- Size information (per parallel block).
  constant C_NUM_DATA_WORDS           : natural := C_CACHE_SIZE / ( C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH / 8 );
  constant C_NUM_TAG_WORDS            : natural := C_CACHE_SIZE / ( C_NUM_PARALLEL_SETS * 32/8 ) / C_CACHE_LINE_LENGTH;
  constant C_DATA_ADDR_BITS           : natural := log2(C_NUM_DATA_WORDS);
  constant C_TAG_ADDR_BITS            : natural := log2(C_NUM_TAG_WORDS);
  constant C_LRU_ADDR_BITS            : natural := C_TAG_ADDR_BITS - C_SERIAL_ASSOC_ADDR_BITS;
  
  -- Set information
  constant C_SET_BITS                 : natural := log2(C_NUM_SETS);
  constant C_PARALLEL_SET_BITS        : natural := log2(C_NUM_PARALLEL_SETS);
  constant C_SERIAL_SET_BITS          : natural := log2(C_NUM_SERIAL_SETS);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  -- Subtypes of the address from all points of view.
  
  -- Ranges for address parts (System Cache).
  subtype C_ADDR_VALID_POS            is natural range C_MAX_ADDR_WIDTH - 1                                    downto 
                                                       C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS;
  subtype C_ADDR_INTERNAL_POS         is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       0;
  subtype C_ADDR_REQ_POS              is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_WORD_ADDR_BITS;
  subtype C_ADDR_DIRECT_POS           is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_LINE_ADDR_BITS + 2;
  subtype C_ADDR_TAG_CONTENTS_POS     is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_LINE_ADDR_BITS + 2;
  subtype C_ADDR_DATA_POS             is natural range C_CACHE_SIZE_ADDR_BITS - C_PARALLEL_ASSOC_ADDR_BITS - 1 downto 
                                                       C_WORD_ADDR_BITS;
  subtype C_ADDR_EXT_DATA_POS         is natural range C_CACHE_SIZE_ADDR_BITS - C_PARALLEL_ASSOC_ADDR_BITS - 1 downto 
                                                       C_EXT_WORD_ADDR_BITS;
  subtype C_ADDR_TAG_POS              is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_CACHE_SIZE_ADDR_BITS - C_ASSOCIATIVE_ADDR_BITS;
  subtype C_ADDR_ALL_SETS_POS         is natural range C_CACHE_SIZE_ADDR_BITS - 1                              downto 
                                                       C_LINE_ADDR_BITS + 2;
  subtype C_ADDR_ASSOCIATIVE_POS      is natural range C_CACHE_SIZE_ADDR_BITS - 1                              downto 
                                                       C_CACHE_SIZE_ADDR_BITS - C_ASSOCIATIVE_ADDR_BITS;
  subtype C_ADDR_FULL_LINE_POS        is natural range C_CACHE_SIZE_ADDR_BITS - C_PARALLEL_ASSOC_ADDR_BITS - 1 downto 
                                                       C_LINE_ADDR_BITS + 2;
  subtype C_ADDR_LINE_POS             is natural range C_CACHE_SIZE_ADDR_BITS - C_ASSOCIATIVE_ADDR_BITS - 1    downto 
                                                       C_LINE_ADDR_BITS + 2;
  subtype C_ADDR_OFFSET_POS           is natural range C_LINE_ADDR_BITS + 2 - 1                                downto 
                                                       0;
  subtype C_ADDR_EXT_WORD_POS         is natural range C_LINE_ADDR_BITS + 2 - 1                                downto 
                                                       C_EXT_WORD_ADDR_BITS;
  subtype C_ADDR_WORD_POS             is natural range C_LINE_ADDR_BITS + 2 - 1                                downto 
                                                       C_WORD_ADDR_BITS;
  subtype C_ADDR_EXT_BYTE_POS         is natural range C_EXT_WORD_ADDR_BITS- 1                                 downto 
                                                       0;
  subtype C_ADDR_BYTE_POS             is natural range C_WORD_ADDR_BITS- 1                                     downto 
                                                       0;
  
  
  -- Ranges for address parts (Lx Cache).
  subtype C_Lx_ADDR_REQ_POS           is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_Lx_WORD_ADDR_BITS;
  subtype C_Lx_ADDR_DIRECT_POS        is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_Lx_LINE_ADDR_BITS + 2;
  subtype C_Lx_ADDR_DATA_POS          is natural range C_Lx_CACHE_SIZE_ADDR_BITS - 1                           downto 
                                                       C_Lx_WORD_ADDR_BITS;
  subtype C_Lx_ADDR_TAG_POS           is natural range C_MAX_ADDR_WIDTH - C_VALID_ADDR_BITS - 1                downto 
                                                       C_Lx_CACHE_SIZE_ADDR_BITS;
  subtype C_Lx_ADDR_LINE_POS          is natural range C_Lx_CACHE_SIZE_ADDR_BITS - 1                           downto 
                                                       C_Lx_LINE_ADDR_BITS + 2;
  subtype C_Lx_ADDR_OFFSET_POS        is natural range C_Lx_LINE_ADDR_BITS + 2 - 1                             downto 
                                                       0;
  subtype C_Lx_ADDR_WORD_POS          is natural range C_Lx_LINE_ADDR_BITS + 2 - 1                             downto 
                                                       C_Lx_WORD_ADDR_BITS;
  subtype C_Lx_ADDR_BYTE_POS          is natural range C_Lx_WORD_ADDR_BITS- 1                                  downto 
                                                       0;
  
  
  -- Subtypes for address parts.
  subtype ADDR_VALID_TYPE             is std_logic_vector(C_ADDR_VALID_POS);
  subtype ADDR_INTERNAL_TYPE          is std_logic_vector(C_ADDR_INTERNAL_POS);
  subtype ADDR_REQ_TYPE               is std_logic_vector(C_ADDR_REQ_POS);
  subtype ADDR_DIRECT_TYPE            is std_logic_vector(C_ADDR_DIRECT_POS);
  subtype ADDR_EXT_DATA_TYPE          is std_logic_vector(C_ADDR_EXT_DATA_POS);
  subtype ADDR_DATA_TYPE              is std_logic_vector(C_ADDR_DATA_POS);
  subtype ADDR_TAG_ADDR_TYPE          is std_logic_vector(C_ADDR_TAG_CONTENTS_POS);
  subtype ADDR_TAG_TYPE               is std_logic_vector(C_ADDR_TAG_POS);
  subtype ADDR_ALL_SETS_TYPE          is std_logic_vector(C_ADDR_ALL_SETS_POS);
  subtype ADDR_ASSOCIATIVE_TYPE       is std_logic_vector(C_ADDR_ASSOCIATIVE_POS);
  subtype ADDR_FULL_LINE_TYPE         is std_logic_vector(C_ADDR_FULL_LINE_POS);
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_EXT_WORD_TYPE          is std_logic_vector(C_ADDR_EXT_WORD_POS);
  subtype ADDR_WORD_TYPE              is std_logic_vector(C_ADDR_WORD_POS);
  subtype ADDR_EXT_BYTE_TYPE          is std_logic_vector(C_ADDR_EXT_BYTE_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  subtype Lx_ADDR_REQ_TYPE            is std_logic_vector(C_Lx_ADDR_REQ_POS);
  subtype Lx_ADDR_DIRECT_TYPE         is std_logic_vector(C_Lx_ADDR_DIRECT_POS);
  subtype Lx_ADDR_DATA_TYPE           is std_logic_vector(C_Lx_ADDR_DATA_POS);
  subtype Lx_ADDR_TAG_TYPE            is std_logic_vector(C_Lx_ADDR_TAG_POS);
  subtype Lx_ADDR_LINE_TYPE           is std_logic_vector(C_Lx_ADDR_LINE_POS);
  subtype Lx_ADDR_OFFSET_TYPE         is std_logic_vector(C_Lx_ADDR_OFFSET_POS);
  subtype Lx_ADDR_WORD_TYPE           is std_logic_vector(C_Lx_ADDR_WORD_POS);
  subtype Lx_ADDR_BYTE_TYPE           is std_logic_vector(C_Lx_ADDR_BYTE_POS);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Set)
  -----------------------------------------------------------------------------
  
  -- Set related.
  subtype C_SET_POS                   is natural range C_NUM_SETS - 1          downto 0;
  subtype C_SERIAL_SET_POS            is natural range C_NUM_SERIAL_SETS - 1   downto 0;
  subtype C_PARALLEL_SET_POS          is natural range C_NUM_PARALLEL_SETS - 1 downto 0;
  subtype C_SET_BIT_POS               is natural range C_SET_BITS - 1          downto 0;
  subtype C_SERIAL_SET_BIT_POS        is natural range C_SET_BITS - 1          downto C_SET_BITS - C_SERIAL_SET_BITS;
  subtype C_PARALLEL_SET_BIT_POS      is natural range C_PARALLEL_SET_BITS - 1 downto 0;
  
  subtype SET_TYPE                    is std_logic_vector(C_SET_POS);
  subtype SERIAL_SET_TYPE             is std_logic_vector(C_SERIAL_SET_POS);
  subtype PARALLEL_SET_TYPE           is std_logic_vector(C_PARALLEL_SET_POS);
  subtype SET_BIT_TYPE                is std_logic_vector(C_SET_BIT_POS);
  subtype SERIAL_SET_BIT_TYPE         is std_logic_vector(C_SERIAL_SET_BIT_POS);
  subtype PARALLEL_SET_BIT_TYPE       is std_logic_vector(C_PARALLEL_SET_BIT_POS);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Data)
  -----------------------------------------------------------------------------
  
  -- Data related.
  subtype C_BE_POS                is natural range C_CACHE_DATA_WIDTH/8 - 1    downto 0;
  subtype C_DATA_POS              is natural range C_CACHE_DATA_WIDTH - 1      downto 0;
  subtype BE_TYPE                 is std_logic_vector(C_BE_POS);
  subtype DATA_TYPE               is std_logic_vector(C_DATA_POS);
  
  -- Data related.
  subtype C_EXT_BE_POS                is natural range C_EXTERNAL_DATA_WIDTH/8 - 1    downto 0;
  subtype C_EXT_DATA_POS              is natural range C_EXTERNAL_DATA_WIDTH - 1      downto 0;
  subtype EXT_BE_TYPE                 is std_logic_vector(C_EXT_BE_POS);
  subtype EXT_DATA_TYPE               is std_logic_vector(C_EXT_DATA_POS);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Dirty/Shared)
  -----------------------------------------------------------------------------
  
  subtype C_VDL_POS                   is natural range C_NUM_SERIAL_SETS*C_NUM_PARALLEL_SETS-1 downto 0;
  subtype VDL_TYPE                    is std_logic_vector(C_VDL_POS);
  
  subtype C_PARALLEL_VDL_POS          is natural range C_NUM_SERIAL_SETS*C_NUM_PARALLEL_SETS-1 downto 
                                                       (C_NUM_SERIAL_SETS-1)*C_NUM_PARALLEL_SETS;
  subtype PARALLEL_VDL_TYPE           is std_logic_vector(C_PARALLEL_VDL_POS);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (TAG)
  -----------------------------------------------------------------------------
  
  -- Ranges for TAG information parts.
  constant C_TAG_VALID_POS            : natural := C_NUM_ADDR_TAG_BITS + 2;
  constant C_TAG_DIRTY_POS            : natural := C_NUM_ADDR_TAG_BITS + 1;
  constant C_TAG_LOCKED_POS           : natural := C_NUM_ADDR_TAG_BITS + 0;
  subtype C_TAG_ADDR_POS              is natural range C_NUM_ADDR_TAG_BITS - 1 downto 0;
  
  -- Subtypes for TAG information parts.
  subtype C_TAG_ADDR_TYPE             is std_logic_vector(C_TAG_ADDR_POS);
  
  
  -----------------------------------------------------------------------------
  -- Components
  -----------------------------------------------------------------------------
  
  component sc_front_end is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_OPT_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_OPT_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_GEN_LAT_RD_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_GEN_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;

      -- Optimized AXI4 Slave Interface #0 specific.
      C_S0_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
      C_S0_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
      C_S0_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
      C_S0_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
      C_S0_AXI_ID_WIDTH         : natural                       := 4;
      C_S0_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S0_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S0_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S0_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S0_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S1_AXI_ID_WIDTH         : natural                       := 1;
      C_S1_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S1_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S1_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S1_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S1_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S2_AXI_ID_WIDTH         : natural                       := 1;
      C_S2_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S2_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S2_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S2_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S2_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S3_AXI_ID_WIDTH         : natural                       := 1;
      C_S3_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S3_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S3_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S3_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S3_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S4_AXI_ID_WIDTH         : natural                       := 1;
      C_S4_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S4_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S4_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S4_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S4_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S5_AXI_ID_WIDTH         : natural                       := 1;
      C_S5_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S5_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S5_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S5_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S5_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S6_AXI_ID_WIDTH         : natural                       := 1;
      C_S6_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S6_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S6_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S6_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S6_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S7_AXI_ID_WIDTH         : natural                       := 1;
      C_S7_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S7_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S7_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S7_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S7_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S8_AXI_ID_WIDTH         : natural                       := 1;
      C_S8_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S8_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S8_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S8_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S8_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S9_AXI_ID_WIDTH         : natural                       := 1;
      C_S9_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S9_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S9_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S9_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S9_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S10_AXI_ID_WIDTH         : natural                       := 1;
      C_S10_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S10_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S10_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S10_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S10_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
      C_S10_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
      C_S10_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
      C_S10_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
      C_S10_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
      C_S10_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
      C_S10_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
      
      -- Optimized AXI4 Slave Interface #11 specific.
      C_S11_AXI_BASEADDR         : std_logic_vector(63 downto 0) := X"FFFF_FFFF_FFFF_FFFF";
      C_S11_AXI_HIGHADDR         : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
      C_S11_AXI_ADDR_WIDTH       : natural range 15 to   64      := 32;
      C_S11_AXI_DATA_WIDTH       : natural range 32 to 1024      := 32;
      C_S11_AXI_ID_WIDTH         : natural                       := 1;
      C_S11_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S11_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S11_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S11_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S11_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S12_AXI_ID_WIDTH         : natural                       := 1;
      C_S12_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S12_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S12_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S12_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S12_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S13_AXI_ID_WIDTH         : natural                       := 1;
      C_S13_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S13_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S13_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S13_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S13_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S14_AXI_ID_WIDTH         : natural                       := 1;
      C_S14_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S14_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S14_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S14_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S14_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S15_AXI_ID_WIDTH         : natural                       := 1;
      C_S15_AXI_SUPPORT_UNIQUE   : natural range  0 to    1      := 1;
      C_S15_AXI_SUPPORT_DIRTY    : natural range  0 to    1      := 0;
      C_S15_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  1;
      C_S15_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
      C_S15_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  1;
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
      C_S0_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S1_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S2_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S3_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S4_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S5_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S6_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S7_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S8_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S9_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S10_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S11_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S12_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S13_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S14_AXI_GEN_ID_WIDTH     : natural                       := 1;
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
      C_S15_AXI_GEN_ID_WIDTH     : natural                       := 1;
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

      -- PARD Specific.
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
      
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
      S0_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S0_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S1_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S1_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S2_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S2_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S3_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S3_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S4_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S4_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S5_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S5_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S6_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S6_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S7_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S7_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S8_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S8_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S9_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S9_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S10_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S10_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S11_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S11_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S12_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S12_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S13_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S13_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S14_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S14_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S15_AXI_AWUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S15_AXI_ARUSER             : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S0_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S0_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S1_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S1_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S2_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S2_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S3_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S3_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S4_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S4_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S5_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S5_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S6_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S6_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S7_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S7_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S8_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S8_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S9_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S9_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S10_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S10_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S11_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S11_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S12_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S12_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S13_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S13_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S14_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S14_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S15_AXI_GEN_AWUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      S15_AXI_GEN_ARUSER         : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);          -- For PARD
      
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
      -- Update signals (to Ports).
      
      -- Write miss response
      update_ext_bresp_valid    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
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
  end component sc_front_end;
  
  component sc_cache_core is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean:= false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- IP Specific.
      C_PIPELINE_LU_READ_DATA   : boolean                       := false;
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
      C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
      C_NUM_SETS                : natural range  1 to   32      :=  2;
      C_NUM_SERIAL_SETS         : natural range  1 to    8      :=  2;
      C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
      C_ID_WIDTH                : natural range  1 to   32      :=  1;
      
      -- Data type and settings specific.
      C_LRU_ADDR_BITS           : natural range  4 to   63      := 13;
      C_TAG_SIZE                : natural range  3 to   96      := 15;
      C_NUM_STATUS_BITS         : natural range  4 to    4      :=  4;
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- For PARD
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_CACHE_DATA_ADDR_WIDTH   : natural range  2 to    7      :=  2;
      C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
      C_EXTERNAL_DATA_ADDR_WIDTH: natural range  2 to    7      :=  2;
      C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
      C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
      C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
      C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
      C_ADDR_EXT_DATA_HI        : natural range  2 to   63      := 14;
      C_ADDR_EXT_DATA_LO        : natural range  2 to   63      :=  2;
      C_ADDR_DATA_HI            : natural range  2 to   63      := 14;
      C_ADDR_DATA_LO            : natural range  2 to   63      :=  2;
      C_ADDR_TAG_HI             : natural range  4 to   63      := 27;
      C_ADDR_TAG_LO             : natural range  4 to   63      := 14;
      C_ADDR_FULL_LINE_HI       : natural range  4 to   63      := 14;
      C_ADDR_FULL_LINE_LO       : natural range  4 to   63      :=  7;
      C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
      C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
      C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
      C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
      C_ADDR_EXT_WORD_HI        : natural range  2 to   63      :=  6;
      C_ADDR_EXT_WORD_LO        : natural range  2 to   63      :=  2;
      C_ADDR_WORD_HI            : natural range  2 to   63      :=  6;
      C_ADDR_WORD_LO            : natural range  2 to   63      :=  2;
      C_ADDR_EXT_BYTE_HI        : natural range  0 to   63      :=  1;
      C_ADDR_EXT_BYTE_LO        : natural range  0 to   63      :=  0;
      C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
      C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
      C_SET_BIT_HI              : natural range  0 to    4      :=  0;
      C_SET_BIT_LO              : natural range  0 to    0      :=  0
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      -- ---------------------------------------------------
      -- Access signals.
      
      access_valid              : in  std_logic;
      access_info               : ACCESS_TYPE;
      access_use                : in  std_logic_vector(C_ADDR_WORD_HI downto C_ADDR_BYTE_LO);
      access_stp                : in  std_logic_vector(C_ADDR_WORD_HI downto C_ADDR_BYTE_LO);
      access_id                 : in  std_logic_vector(C_ID_WIDTH - 1 downto 0);
      
      access_data_valid         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_last          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_be            : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      access_data_word          : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      lookup_read_data_hit      : out std_logic;
      lookup_read_data_snoop    : out std_logic;
      lookup_read_data_allocate : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_info_full            : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_data_hit_pop         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_data_hit_almost_full : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_data_hit_full        : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_data_hit_fit         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      read_data_miss_full       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Access).
      
      lookup_piperun            : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Frontend).
      
      lookup_read_data_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      lookup_read_data_last     : out std_logic;
      lookup_read_data_resp     : out std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
      lookup_read_data_set      : out natural range 0 to C_NUM_PARALLEL_SETS - 1;
      lookup_read_data_word     : out std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
      
      lookup_write_data_ready   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Arbiter).
      
      lookup_read_done          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Update signals (to Frontend).
      
      -- Read miss
      update_read_data_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      update_read_data_last     : out std_logic;
      update_read_data_resp     : out std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
      update_read_data_word     : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      update_read_data_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      -- Write Miss
      update_write_data_ready   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      -- Write miss response
      update_ext_bresp_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      update_ext_bresp          : out std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push    : out std_logic;
      update_auto_clean_addr    : out AXI_ADDR_TYPE;
      update_auto_clean_DSid    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      -- ---------------------------------------------------
      -- Update signals (to Backend).
      
      read_req_valid            : out std_logic;
      read_req_port             : out natural range 0 to C_NUM_PORTS - 1;
      read_req_addr             : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      read_req_len              : out std_logic_vector(8 - 1 downto 0);
      read_req_size             : out std_logic_vector(3 - 1 downto 0);
      read_req_exclusive        : out std_logic;
      read_req_kind             : out std_logic;
      read_req_ready            : in  std_logic;
      read_req_DSid             : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_req_valid           : out std_logic;
      write_req_port            : out natural range 0 to C_NUM_PORTS - 1;
      write_req_internal        : out std_logic;
      write_req_addr            : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      write_req_len             : out std_logic_vector(8 - 1 downto 0);
      write_req_size            : out std_logic_vector(3 - 1 downto 0);
      write_req_exclusive       : out std_logic;
      write_req_kind            : out std_logic;
      write_req_line_only       : out std_logic;
      write_req_ready           : in  std_logic;
      write_req_DSid            : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_data_valid          : out std_logic;
      write_data_last           : out std_logic;
      write_data_be             : out std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
      write_data_word           : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      write_data_ready          : in  std_logic;
      write_data_almost_full    : in  std_logic;
      write_data_full           : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Backend signals.
      
      backend_wr_resp_valid     : in  std_logic;
      backend_wr_resp_port      : out natural range 0 to C_NUM_PORTS - 1;
      backend_wr_resp_internal  : out std_logic;
      backend_wr_resp_addr      : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      backend_wr_resp_bresp     : in  std_logic_vector(2 - 1 downto 0);
      backend_wr_resp_ready     : out std_logic;
      
      backend_rd_data_valid     : in  std_logic;
      backend_rd_data_last      : in  std_logic;
      backend_rd_data_word      : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      backend_rd_data_rresp     : in  std_logic_vector(2 - 1 downto 0);
      backend_rd_data_ready     : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      : in  std_logic;
      stat_enable                     : in  std_logic;
      
      -- Lookup
      stat_lu_opt_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      
      stat_lu_gen_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      
      stat_lu_stall                   : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_fetch_stall             : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_mem_stall               : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_stall              : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_hit_stall          : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_miss_stall         : out STAT_POINT_TYPE;    -- Time per occurance
      
      -- Update
      stat_ud_stall                   : out STAT_POINT_TYPE;    -- Time transactions are stalled
      stat_ud_tag_free                : out STAT_POINT_TYPE;    -- Cycles tag is free
      stat_ud_data_free               : out STAT_POINT_TYPE;    -- Cycles data is free
      stat_ud_ri                      : out STAT_FIFO_TYPE;     -- Read Information
      stat_ud_r                       : out STAT_FIFO_TYPE;     -- Read data (optional)
      stat_ud_e                       : out STAT_FIFO_TYPE;     -- Evict
      stat_ud_bs                      : out STAT_FIFO_TYPE;     -- BRESP Source
      stat_ud_wm                      : out STAT_FIFO_TYPE;     -- Write Miss
      stat_ud_wma                     : out STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      MEMORY_DEBUG1             : out std_logic_vector(255 downto 0);
      MEMORY_DEBUG2             : out std_logic_vector(255 downto 0);
      LOOKUP_DEBUG              : out std_logic_vector(255 downto 0);
      UPDATE_DEBUG1             : out std_logic_vector(255 downto 0);
      UPDATE_DEBUG2             : out std_logic_vector(255 downto 0);

    --For PARD stab
    lookup_valid_to_stab                : out std_logic;
    lookup_DSid_to_stab                 : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    lookup_hit_to_stab          		: out std_logic;
    lookup_miss_to_stab         		: out std_logic;
    update_tag_en_to_stab               : out std_logic;
    update_tag_we_to_stab       		: out std_logic_vector(C_NUM_SETS - 1 downto 0);
    update_tag_old_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    update_tag_new_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    lru_history_en_to_ptab              : out std_logic;
    lru_dsid_valid_to_ptab              : out std_logic;
    lru_dsid_to_ptab                    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    way_mask_from_ptab                  : in  std_logic_vector(C_NUM_SETS - 1 downto 0)
);
  end component sc_cache_core;
  
  component sc_back_end is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_DEBUG               : boolean                       := false;
      C_USE_ASSERTIONS          : boolean                       := false;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_MEM_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_MEM_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- IP Specific.
      C_BASEADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
      C_HIGHADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 32;
      C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
      C_EXTERNAL_DATA_ADDR_WIDTH: natural range  2 to    7      :=  2;
      C_OPTIMIZE_ORDER          : natural range  0 to    5      :=  0;

      -- PARD Specific.
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
      
      -- Data type and settings specific.
      C_ADDR_VALID_HI           : natural range  0 to   63      := 31;
      C_ADDR_VALID_LO           : natural range  0 to   63      := 28;
      C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
      C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
      C_ADDR_TAG_CONTENTS_HI    : natural range  0 to   63      := 27;
      C_ADDR_TAG_CONTENTS_LO    : natural range  0 to   63      :=  7;
      C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
      C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
      
      -- AXI4 Master Interface specific.
      C_M_AXI_THREAD_ID_WIDTH   : natural range  1 to   32      :=  1;
      C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_M_AXI_ADDR_WIDTH        : natural                       := 32
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      read_req_valid            : in  std_logic;
      read_req_port             : in  natural range 0 to C_NUM_PORTS - 1;
      read_req_addr             : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      read_req_len              : in  std_logic_vector(8 - 1 downto 0);
      read_req_size             : in  std_logic_vector(3 - 1 downto 0);
      read_req_exclusive        : in  std_logic;
      read_req_kind             : in  std_logic;
      read_req_ready            : out std_logic;
      read_req_DSid             : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_req_valid           : in  std_logic;
      write_req_port            : in  natural range 0 to C_NUM_PORTS - 1;
      write_req_internal        : in  std_logic;
      write_req_addr            : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      write_req_len             : in  std_logic_vector(8 - 1 downto 0);
      write_req_size            : in  std_logic_vector(3 - 1 downto 0);
      write_req_exclusive       : in  std_logic;
      write_req_kind            : in  std_logic;
      write_req_line_only       : in  std_logic;
      write_req_ready           : out std_logic;
      write_req_DSid            : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_data_valid          : in  std_logic;
      write_data_last           : in  std_logic;
      write_data_be             : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
      write_data_word           : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      write_data_ready          : out std_logic;
      write_data_almost_full    : out std_logic;
      write_data_full           : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Backend signals (to Update).
      
      backend_wr_resp_valid     : out std_logic;
      backend_wr_resp_port      : in  natural range 0 to C_NUM_PORTS - 1;
      backend_wr_resp_internal  : in  std_logic;
      backend_wr_resp_addr      : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      backend_wr_resp_bresp     : out AXI_BRESP_TYPE;
      backend_wr_resp_ready     : in  std_logic;
      
      backend_rd_data_valid     : out std_logic;
      backend_rd_data_last      : out std_logic;
      backend_rd_data_word      : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      backend_rd_data_rresp     : out std_logic_vector(2 - 1 downto 0);
      backend_rd_data_ready     : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- AXI4 Master Interface Signals.
      
      M_AXI_AWID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_AWADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_AWLEN               : out std_logic_vector(7 downto 0);
      M_AXI_AWSIZE              : out std_logic_vector(2 downto 0);
      M_AXI_AWBURST             : out std_logic_vector(1 downto 0);
      M_AXI_AWLOCK              : out std_logic;
      M_AXI_AWCACHE             : out std_logic_vector(3 downto 0);
      M_AXI_AWPROT              : out std_logic_vector(2 downto 0);
      M_AXI_AWQOS               : out std_logic_vector(3 downto 0);
      M_AXI_AWVALID             : out std_logic;
      M_AXI_AWREADY             : in  std_logic;
      M_AXI_AWUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
      
      M_AXI_WDATA               : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      M_AXI_WSTRB               : out std_logic_vector((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
      M_AXI_WLAST               : out std_logic;
      M_AXI_WVALID              : out std_logic;
      M_AXI_WREADY              : in  std_logic;
      
      M_AXI_BRESP               : in  std_logic_vector(1 downto 0);
      M_AXI_BID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_BVALID              : in  std_logic;
      M_AXI_BREADY              : out std_logic;
      
      M_AXI_ARID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_ARADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_ARLEN               : out std_logic_vector(7 downto 0);
      M_AXI_ARSIZE              : out std_logic_vector(2 downto 0);
      M_AXI_ARBURST             : out std_logic_vector(1 downto 0);
      M_AXI_ARLOCK              : out std_logic;
      M_AXI_ARCACHE             : out std_logic_vector(3 downto 0);
      M_AXI_ARPROT              : out std_logic_vector(2 downto 0);
      M_AXI_ARQOS               : out std_logic_vector(3 downto 0);
      M_AXI_ARVALID             : out std_logic;
      M_AXI_ARREADY             : in  std_logic;
      M_AXI_ARUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
      
      M_AXI_RID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_RDATA               : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      M_AXI_RRESP               : in  std_logic_vector(1 downto 0);
      M_AXI_RLAST               : in  std_logic;
      M_AXI_RVALID              : in  std_logic;
      M_AXI_RREADY              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      -- Backend
      stat_be_aw                : out STAT_FIFO_TYPE;     -- Write Address
      stat_be_w                 : out STAT_FIFO_TYPE;     -- Write Data
      stat_be_ar                : out STAT_FIFO_TYPE;     -- Read Address
      stat_be_ar_search_depth   : out STAT_POINT_TYPE;    -- Average search depth
      stat_be_ar_stall          : out STAT_POINT_TYPE;    -- Average total stall
      stat_be_ar_protect_stall  : out STAT_POINT_TYPE;    -- Average protected stall
      stat_be_rd_latency        : out STAT_POINT_TYPE;    -- External Read Latency
      stat_be_wr_latency        : out STAT_POINT_TYPE;    -- External Write Latency
      stat_be_rd_latency_conf   : in  STAT_CONF_TYPE;     -- External Read Latency Configuration
      stat_be_wr_latency_conf   : in  STAT_CONF_TYPE;     -- External Write Latency Configuration
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      BACKEND_DEBUG             : out std_logic_vector(255 downto 0)
    );
  end component sc_back_end;
  
  component sc_s_axi_ctrl_interface is
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
      C_ENABLE_CTRL             : natural range  0 to    1      :=  0;
      C_ENABLE_AUTOMATIC_CLEAN  : natural range  0 to    1      :=  0;
      C_AUTOMATIC_CLEAN_MODE    : natural range  0 to    1      :=  0;
      C_DSID_WIDTH              : natural range  0 to   32      := 16;
      -- Data type and settings specific.
      C_ADDR_ALL_SETS_HI        : natural range  4 to   63      := 14;
      C_ADDR_ALL_SETS_LO        : natural range  4 to   63      :=  7;
      
      -- IP Specific.
      C_ENABLE_STATISTICS       : natural range  0 to  255      := 255;
      C_ENABLE_VERSION_REGISTER : natural range  0 to    3      :=  0;
      C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
      C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
      C_ENABLE_EXCLUSIVE        : natural range  0 to    1      :=  0;
      C_NUM_SETS                : natural range  2 to   32      :=  2;
      C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
      C_CACHE_SIZE              : natural                       := 32768;
      C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  4;
      C_Lx_CACHE_SIZE           : natural                       := 1024;
      C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      
      -- AXI4-Lite Interface Specific.
      C_S_AXI_CTRL_BASEADDR     : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
      C_S_AXI_CTRL_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
      C_S_AXI_CTRL_DATA_WIDTH   : natural range 32 to   64      := 32;
      C_S_AXI_CTRL_ADDR_WIDTH   : natural                       := 32
      
    );
    port (
      -- ---------------------------------------------------
      -- Common signals
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- AXI4-Lite Slave Interface Signals
      
      -- AW-Channel
      S_AXI_CTRL_AWADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
      S_AXI_CTRL_AWVALID             : in  std_logic;
      S_AXI_CTRL_AWREADY             : out std_logic;
  
      -- W-Channel
      S_AXI_CTRL_WDATA               : in  std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
      S_AXI_CTRL_WVALID              : in  std_logic;
      S_AXI_CTRL_WREADY              : out std_logic;
  
      -- B-Channel
      S_AXI_CTRL_BRESP               : out std_logic_vector(1 downto 0);
      S_AXI_CTRL_BVALID              : out std_logic;
      S_AXI_CTRL_BREADY              : in  std_logic;
  
      -- AR-Channel
      S_AXI_CTRL_ARADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
      S_AXI_CTRL_ARVALID             : in  std_logic;
      S_AXI_CTRL_ARREADY             : out std_logic;
  
      -- R-Channel
      S_AXI_CTRL_RDATA               : out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
      S_AXI_CTRL_RRESP               : out std_logic_vector(1 downto 0);
      S_AXI_CTRL_RVALID              : out std_logic;
      S_AXI_CTRL_RREADY              : in  std_logic;
  
      
      -- ---------------------------------------------------
      -- Control If Transactions.
      
      ctrl_init_done                  : out std_logic;
      ctrl_access                     : out ARBITRATION_TYPE;
      ctrl_ready                      : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push          : in  std_logic;
      update_auto_clean_addr          : in  AXI_ADDR_TYPE;
      update_auto_clean_DSid          : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      : out std_logic;
      stat_enable                     : out std_logic;
      
      -- Optimized ports.
      stat_s_axi_rd_segments          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
      stat_s_axi_wr_segments          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
      stat_s_axi_rip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_r                    : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_bip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_bp                   : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_wip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_w                    : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_rd_latency           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_wr_latency           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_rd_latency_conf      : out STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_s_axi_wr_latency_conf      : out STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  
      -- Generic ports.
      stat_s_axi_gen_rd_segments      : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
      stat_s_axi_gen_wr_segments      : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
      stat_s_axi_gen_rip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_r                : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_bip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_bp               : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_wip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_w                : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_rd_latency       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_wr_latency       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_rd_latency_conf  : out STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_s_axi_gen_wr_latency_conf  : out STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      
      -- Arbiter
      stat_arb_valid                  : in  STAT_POINT_TYPE;    -- Time valid transactions exist
      stat_arb_concurrent_accesses    : in  STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
      stat_arb_opt_read_blocked       : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
      stat_arb_gen_read_blocked       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                                -- Time valid read is blocked by prohibit
      
      -- Access
      stat_access_valid               : in  STAT_POINT_TYPE;    -- Time valid per transaction
      stat_access_stall               : in  STAT_POINT_TYPE;    -- Time stalled per transaction
      stat_access_fetch_stall         : in  STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
      stat_access_req_stall           : in  STAT_POINT_TYPE;    -- Time stalled per transaction (req)
      stat_access_act_stall           : in  STAT_POINT_TYPE;    -- Time stalled per transaction (act)
      
      -- Lookup
      stat_lu_opt_write_hit           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss_dirty    : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_hit            : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss_dirty     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_write_hit    : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_read_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_first_write_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      
      stat_lu_gen_write_hit           : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss          : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss_dirty    : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_hit            : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss           : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss_dirty     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_write_hit    : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_read_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_first_write_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      
      stat_lu_stall                   : in  STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_fetch_stall             : in  STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_mem_stall               : in  STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_stall              : in  STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_hit_stall          : in  STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_miss_stall         : in  STAT_POINT_TYPE;    -- Time per occurance
      
      -- Update
      stat_ud_stall                   : in  STAT_POINT_TYPE;    -- Time transactions are stalled
      stat_ud_tag_free                : in  STAT_POINT_TYPE;    -- Cycles tag is free
      stat_ud_data_free               : in  STAT_POINT_TYPE;    -- Cycles data is free
      stat_ud_ri                      : in  STAT_FIFO_TYPE;     -- Read Information
      stat_ud_r                       : in  STAT_FIFO_TYPE;     -- Read data (optional)
      stat_ud_e                       : in  STAT_FIFO_TYPE;     -- Evict
      stat_ud_bs                      : in  STAT_FIFO_TYPE;     -- BRESP Source
      stat_ud_wm                      : in  STAT_FIFO_TYPE;     -- Write Miss
      stat_ud_wma                     : in  STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
      
      -- Backend
      stat_be_aw                      : in  STAT_FIFO_TYPE;     -- Write Address
      stat_be_w                       : in  STAT_FIFO_TYPE;     -- Write Data
      stat_be_ar                      : in  STAT_FIFO_TYPE;     -- Read Address
      stat_be_ar_search_depth         : in  STAT_POINT_TYPE;    -- Average search depth
      stat_be_ar_stall                : in  STAT_POINT_TYPE;    -- Average total stall
      stat_be_ar_protect_stall        : in  STAT_POINT_TYPE;    -- Average protected stall
      stat_be_rd_latency              : in  STAT_POINT_TYPE;    -- External Read Latency
      stat_be_wr_latency              : in  STAT_POINT_TYPE;    -- External Write Latency
      stat_be_rd_latency_conf         : out STAT_CONF_TYPE;     -- External Read Latency Configuration
      stat_be_wr_latency_conf         : out STAT_CONF_TYPE;     -- External Write Latency Configuration
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      IF_DEBUG                  : out std_logic_vector(255 downto 0)
    );
  end component sc_s_axi_ctrl_interface;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Common signals.
  
  signal ARESET                     : std_logic;


  -- ---------------------------------------------------
  -- Debug signals.
    
  signal OPT_IF0_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF1_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF2_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF3_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF4_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF5_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF6_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF7_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF8_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF9_DEBUG             : std_logic_vector(255 downto 0);
  signal OPT_IF10_DEBUG            : std_logic_vector(255 downto 0);
  signal OPT_IF11_DEBUG            : std_logic_vector(255 downto 0);
  signal OPT_IF12_DEBUG            : std_logic_vector(255 downto 0);
  signal OPT_IF13_DEBUG            : std_logic_vector(255 downto 0);
  signal OPT_IF14_DEBUG            : std_logic_vector(255 downto 0);
  signal OPT_IF15_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF0_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF1_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF2_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF3_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF4_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF5_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF6_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF7_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF8_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF9_DEBUG             : std_logic_vector(255 downto 0);
  signal GEN_IF10_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF11_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF12_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF13_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF14_DEBUG            : std_logic_vector(255 downto 0);
  signal GEN_IF15_DEBUG            : std_logic_vector(255 downto 0);
  signal CTRL_IF_DEBUG             : std_logic_vector(255 downto 0);
  signal ARBITER_DEBUG             : std_logic_vector(255 downto 0);
  signal ACCESS_DEBUG              : std_logic_vector(255 downto 0);
  signal MEMORY_DEBUG1             : std_logic_vector(255 downto 0);
  signal MEMORY_DEBUG2             : std_logic_vector(255 downto 0);
  signal LOOKUP_DEBUG              : std_logic_vector(255 downto 0);
  signal UPDATE_DEBUG1             : std_logic_vector(255 downto 0);
  signal UPDATE_DEBUG2             : std_logic_vector(255 downto 0);
  signal BACKEND_DEBUG             : std_logic_vector(255 downto 0);
  
  
--  -- ----------------------------------------
--  -- Keep * MARK_DEBUG for all debug ports
--  attribute KEEP : string;
--  attribute MARK_DEBUG : string;
--
--  attribute KEEP       of ARBITER_DEBUG: signal is "TRUE";
--  attribute MARK_DEBUG of ARBITER_DEBUG: signal is "TRUE";
--  attribute KEEP       of ACCESS_DEBUG : signal is "TRUE";
--  attribute MARK_DEBUG of ACCESS_DEBUG : signal is "TRUE";
--  attribute KEEP       of MEMORY_DEBUG1: signal is "TRUE";
--  attribute MARK_DEBUG of MEMORY_DEBUG1: signal is "TRUE";
--  attribute KEEP       of MEMORY_DEBUG2: signal is "TRUE";
--  attribute MARK_DEBUG of MEMORY_DEBUG2: signal is "TRUE";
--  attribute KEEP       of LOOKUP_DEBUG : signal is "TRUE";
--  attribute MARK_DEBUG of LOOKUP_DEBUG : signal is "TRUE";
--  attribute KEEP       of UPDATE_DEBUG1: signal is "TRUE";
--  attribute MARK_DEBUG of UPDATE_DEBUG1: signal is "TRUE";
--  attribute KEEP       of UPDATE_DEBUG2: signal is "TRUE";
--  attribute MARK_DEBUG of UPDATE_DEBUG2: signal is "TRUE";
--  attribute KEEP       of BACKEND_DEBUG: signal is "TRUE";
--  attribute MARK_DEBUG of BACKEND_DEBUG: signal is "TRUE";


  -- ----------------------------------------
  -- Signals between Backend and Core
  -- 
  
  -- Write miss response (to Ports)
  signal update_ext_bresp_valid     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_ext_bresp           : std_logic_vector(2 - 1 downto 0);
  signal update_ext_bresp_ready     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Automatic Clean Information. (ctrl if)
  signal update_auto_clean_push     : std_logic;
  signal update_auto_clean_addr     : AXI_ADDR_TYPE;
  signal update_auto_clean_DSid     : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  -- Lookup signals (to Arbiter).
  signal lookup_read_done           : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Lookup signals
  signal lookup_piperun             : std_logic;
  
  -- Write Miss
  signal lookup_write_data_ready    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal update_write_data_ready    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Access signals (to Lookup).
  signal access_valid               : std_logic;
  signal access_info                : ACCESS_TYPE;
  signal access_use                 : ADDR_OFFSET_TYPE;
  signal access_stp                 : ADDR_OFFSET_TYPE;
  signal access_id                  : std_logic_vector(C_ID_WIDTH - 1 downto 0);
  signal access_data_valid          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal access_data_last           : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal access_data_be             : std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
  signal access_data_word           : std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
  
  -- Internal Interface Signals (Read request).
  signal lookup_read_data_new       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal lookup_read_data_hit       : std_logic;
  signal lookup_read_data_snoop     : std_logic;
  signal lookup_read_data_allocate  : std_logic;
  
  -- Internal Interface Signals (Read Data).
  signal read_info_almost_full      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_info_full             : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_data_hit_pop          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_data_hit_almost_full  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_data_hit_full         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_data_hit_fit          : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal read_data_miss_full        : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Read miss
  signal lookup_read_data_valid     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal lookup_read_data_last      : std_logic;
  signal lookup_read_data_resp      : AXI_RRESP_TYPE;
  signal lookup_read_data_set       : natural range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lookup_read_data_word      : std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
  signal lookup_read_data_ready     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  signal update_read_data_valid     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_read_data_last      : std_logic;
  signal update_read_data_resp      : std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
  signal update_read_data_word      : std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
  signal update_read_data_ready     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -- ---------------------------------------------------
  -- Signals between Core and Backend
  
  -- Update signals.
  signal read_req_valid             : std_logic;
  signal read_req_port              : natural range 0 to C_NUM_PORTS - 1;
  signal read_req_addr              : ADDR_INTERNAL_TYPE;
  signal read_req_len               : AXI_LENGTH_TYPE;
  signal read_req_size              : AXI_SIZE_TYPE;
  signal read_req_exclusive         : std_logic;
  signal read_req_kind              : std_logic;
  signal read_req_ready             : std_logic;
  signal read_req_DSid              : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  
  signal write_req_valid            : std_logic;
  signal write_req_port             : natural range 0 to C_NUM_PORTS - 1;
  signal write_req_internal         : std_logic;
  signal write_req_addr             : ADDR_INTERNAL_TYPE;
  signal write_req_len              : AXI_LENGTH_TYPE;
  signal write_req_size             : AXI_SIZE_TYPE;
  signal write_req_exclusive        : std_logic;
  signal write_req_kind             : std_logic;
  signal write_req_line_only        : std_logic;
  signal write_req_ready            : std_logic;
  signal write_req_DSid             : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  
  signal write_data_valid           : std_logic;
  signal write_data_last            : std_logic;
  signal write_data_be              : std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
  signal write_data_word            : std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
  signal write_data_ready           : std_logic;
  signal write_data_almost_full     : std_logic;
  signal write_data_full            : std_logic;
  
  
  -- Backend signals (to Update).
  signal backend_wr_resp_valid      : std_logic;
  signal backend_wr_resp_port       : natural range 0 to C_NUM_PORTS - 1;
  signal backend_wr_resp_internal   : std_logic;
  signal backend_wr_resp_addr       : ADDR_INTERNAL_TYPE;
  signal backend_wr_resp_bresp      : AXI_BRESP_TYPE;
  signal backend_wr_resp_ready      : std_logic;
  
  signal backend_rd_data_valid      : std_logic;
  signal backend_rd_data_last       : std_logic;
  signal backend_rd_data_word       : EXT_DATA_TYPE;
  signal backend_rd_data_rresp      : std_logic_vector(2 - 1 downto 0);
  signal backend_rd_data_ready      : std_logic;
  
    
  -- ---------------------------------------------------
  -- Control If Transactions.
  
  signal ctrl_init_done             : std_logic;
  signal ctrl_access                : ARBITRATION_TYPE;
  signal ctrl_ready                 : std_logic;
  
  
  -- ----------------------------------------
  -- Statistics signals.
  
  signal stat_reset                      : std_logic;
  signal stat_enable                     : std_logic;
    
  -- Optimized ports.
  signal stat_s_axi_rd_segments          : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
  signal stat_s_axi_wr_segments          : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
  signal stat_s_axi_rip                  : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_r                    : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_bip                  : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_bp                   : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_wip                  : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_w                    : STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_rd_latency           : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_wr_latency           : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_rd_latency_conf      : STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_wr_latency_conf      : STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);

  -- Generic ports.
  signal stat_s_axi_gen_rd_segments      : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
  signal stat_s_axi_gen_wr_segments      : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
  signal stat_s_axi_gen_rip              : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_r                : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_bip              : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_bp               : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_wip              : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_w                : STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_rd_latency       : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_wr_latency       : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_rd_latency_conf  : STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_wr_latency_conf  : STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
   
  -- Arbiter
  signal stat_arb_valid                  : STAT_POINT_TYPE;    -- Time valid transactions exist
  signal stat_arb_concurrent_accesses    : STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
  signal stat_arb_opt_read_blocked       : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
  signal stat_arb_gen_read_blocked       : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                               -- Time valid read is blocked by prohibit
   
  -- Access
  signal stat_access_valid               : STAT_POINT_TYPE;    -- Time valid per transaction
  signal stat_access_stall               : STAT_POINT_TYPE;    -- Time stalled per transaction
  signal stat_access_fetch_stall         : STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
  signal stat_access_req_stall           : STAT_POINT_TYPE;    -- Time stalled per transaction (req)
  signal stat_access_act_stall           : STAT_POINT_TYPE;    -- Time stalled per transaction (act)
   
  -- Lookup
  signal stat_lu_opt_write_hit           : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_write_miss          : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_write_miss_dirty    : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_read_hit            : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_read_miss           : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_read_miss_dirty     : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_locked_write_hit    : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_locked_read_hit     : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_opt_first_write_hit     : STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_lu_gen_write_hit           : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_write_miss          : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_write_miss_dirty    : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_read_hit            : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_read_miss           : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_read_miss_dirty     : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_locked_write_hit    : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_locked_read_hit     : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_gen_first_write_hit     : STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
  signal stat_lu_stall                   : STAT_POINT_TYPE;    -- Time per occurance
  signal stat_lu_fetch_stall             : STAT_POINT_TYPE;    -- Time per occurance
  signal stat_lu_mem_stall               : STAT_POINT_TYPE;    -- Time per occurance
  signal stat_lu_data_stall              : STAT_POINT_TYPE;    -- Time per occurance
  signal stat_lu_data_hit_stall          : STAT_POINT_TYPE;    -- Time per occurance
  signal stat_lu_data_miss_stall         : STAT_POINT_TYPE;    -- Time per occurance
   
  -- Update
  signal stat_ud_stall                   : STAT_POINT_TYPE;    -- Time transactions are stalled
  signal stat_ud_tag_free                : STAT_POINT_TYPE;    -- Cycles tag is free
  signal stat_ud_data_free               : STAT_POINT_TYPE;    -- Cycles data is free
  signal stat_ud_ri                      : STAT_FIFO_TYPE;     -- Read Information
  signal stat_ud_r                       : STAT_FIFO_TYPE;     -- Read data (optional)
  signal stat_ud_e                       : STAT_FIFO_TYPE;     -- Evict
  signal stat_ud_bs                      : STAT_FIFO_TYPE;     -- BRESP Source
  signal stat_ud_wm                      : STAT_FIFO_TYPE;     -- Write Miss
  signal stat_ud_wma                     : STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
   
  -- Backend
  signal stat_be_aw                      : STAT_FIFO_TYPE;     -- Write Address
  signal stat_be_w                       : STAT_FIFO_TYPE;     -- Write Data
  signal stat_be_ar                      : STAT_FIFO_TYPE;     -- Read Address
  signal stat_be_ar_search_depth         : STAT_POINT_TYPE;    -- Average search depth
  signal stat_be_ar_stall                : STAT_POINT_TYPE;    -- Average total stall
  signal stat_be_ar_protect_stall        : STAT_POINT_TYPE;    -- Average protected stall
  signal stat_be_rd_latency              : STAT_POINT_TYPE;    -- External Read Latency
  signal stat_be_wr_latency              : STAT_POINT_TYPE;    -- External Write Latency
  signal stat_be_rd_latency_conf         : STAT_CONF_TYPE;     -- External Read Latency Configuration
  signal stat_be_wr_latency_conf         : STAT_CONF_TYPE;     -- External Write Latency Configuration
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal frontend_assert            : std_logic;
  signal cachecore_assert           : std_logic;
  signal backend_assert             : std_logic;
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
begin  -- architecture IMP


  -----------------------------------------------------------------------------
  -- Active high internal reset
  -----------------------------------------------------------------------------
  Reset_Handle : process (ACLK) is
  begin  -- process Reset_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      ARESET  <= not ARESETN;
    end if;
  end process Reset_Handle;
  
  
  -----------------------------------------------------------------------------
  -- Frontend
  -----------------------------------------------------------------------------
  
  FE: sc_front_end
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG_BOOL,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_OPT_LAT_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
      C_STAT_OPT_LAT_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
      C_STAT_GEN_LAT_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
      C_STAT_GEN_LAT_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,

      -- PARD specific.
      C_DSID_WIDTH              => C_DSID_WIDTH,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S0_AXI_BASEADDR         => C_BASEADDR,
      C_S0_AXI_HIGHADDR         => C_HIGHADDR,
      C_S0_AXI_ADDR_WIDTH       => C_S0_AXI_ADDR_WIDTH,
      C_S0_AXI_DATA_WIDTH       => C_S0_AXI_DATA_WIDTH,
      C_S0_AXI_ID_WIDTH         => C_S0_AXI_ID_WIDTH,
      C_S0_AXI_SUPPORT_UNIQUE   => C_S0_AXI_SUPPORT_UNIQUE,
      C_S0_AXI_SUPPORT_DIRTY    => C_S0_AXI_SUPPORT_DIRTY,
      C_S0_AXI_FORCE_READ_ALLOCATE     => C_S0_AXI_FORCE_READ_ALLOCATE,
      C_S0_AXI_PROHIBIT_READ_ALLOCATE  => C_S0_AXI_PROHIBIT_READ_ALLOCATE,
      C_S0_AXI_FORCE_WRITE_ALLOCATE    => C_S0_AXI_FORCE_WRITE_ALLOCATE,
      C_S0_AXI_PROHIBIT_WRITE_ALLOCATE => C_S0_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S0_AXI_FORCE_READ_BUFFER       => C_S0_AXI_FORCE_READ_BUFFER,
      C_S0_AXI_PROHIBIT_READ_BUFFER    => C_S0_AXI_PROHIBIT_READ_BUFFER,
      C_S0_AXI_FORCE_WRITE_BUFFER      => C_S0_AXI_FORCE_WRITE_BUFFER,
      C_S0_AXI_PROHIBIT_WRITE_BUFFER   => C_S0_AXI_PROHIBIT_WRITE_BUFFER,
      C_S0_AXI_PROHIBIT_EXCLUSIVE      => C_S0_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #1 specific.
      C_S1_AXI_BASEADDR         => C_BASEADDR,
      C_S1_AXI_HIGHADDR         => C_HIGHADDR,
      C_S1_AXI_ADDR_WIDTH       => C_S1_AXI_ADDR_WIDTH,
      C_S1_AXI_DATA_WIDTH       => C_S1_AXI_DATA_WIDTH,
      C_S1_AXI_ID_WIDTH         => C_S1_AXI_ID_WIDTH,
      C_S1_AXI_SUPPORT_UNIQUE   => C_S1_AXI_SUPPORT_UNIQUE,
      C_S1_AXI_SUPPORT_DIRTY    => C_S1_AXI_SUPPORT_DIRTY,
      C_S1_AXI_FORCE_READ_ALLOCATE     => C_S1_AXI_FORCE_READ_ALLOCATE,
      C_S1_AXI_PROHIBIT_READ_ALLOCATE  => C_S1_AXI_PROHIBIT_READ_ALLOCATE,
      C_S1_AXI_FORCE_WRITE_ALLOCATE    => C_S1_AXI_FORCE_WRITE_ALLOCATE,
      C_S1_AXI_PROHIBIT_WRITE_ALLOCATE => C_S1_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S1_AXI_FORCE_READ_BUFFER       => C_S1_AXI_FORCE_READ_BUFFER,
      C_S1_AXI_PROHIBIT_READ_BUFFER    => C_S1_AXI_PROHIBIT_READ_BUFFER,
      C_S1_AXI_FORCE_WRITE_BUFFER      => C_S1_AXI_FORCE_WRITE_BUFFER,
      C_S1_AXI_PROHIBIT_WRITE_BUFFER   => C_S1_AXI_PROHIBIT_WRITE_BUFFER,
      C_S1_AXI_PROHIBIT_EXCLUSIVE      => C_S1_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #2 specific.
      C_S2_AXI_BASEADDR         => C_BASEADDR,
      C_S2_AXI_HIGHADDR         => C_HIGHADDR,
      C_S2_AXI_ADDR_WIDTH       => C_S2_AXI_ADDR_WIDTH,
      C_S2_AXI_DATA_WIDTH       => C_S2_AXI_DATA_WIDTH,
      C_S2_AXI_ID_WIDTH         => C_S2_AXI_ID_WIDTH,
      C_S2_AXI_SUPPORT_UNIQUE   => C_S2_AXI_SUPPORT_UNIQUE,
      C_S2_AXI_SUPPORT_DIRTY    => C_S2_AXI_SUPPORT_DIRTY,
      C_S2_AXI_FORCE_READ_ALLOCATE     => C_S2_AXI_FORCE_READ_ALLOCATE,
      C_S2_AXI_PROHIBIT_READ_ALLOCATE  => C_S2_AXI_PROHIBIT_READ_ALLOCATE,
      C_S2_AXI_FORCE_WRITE_ALLOCATE    => C_S2_AXI_FORCE_WRITE_ALLOCATE,
      C_S2_AXI_PROHIBIT_WRITE_ALLOCATE => C_S2_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S2_AXI_FORCE_READ_BUFFER       => C_S2_AXI_FORCE_READ_BUFFER,
      C_S2_AXI_PROHIBIT_READ_BUFFER    => C_S2_AXI_PROHIBIT_READ_BUFFER,
      C_S2_AXI_FORCE_WRITE_BUFFER      => C_S2_AXI_FORCE_WRITE_BUFFER,
      C_S2_AXI_PROHIBIT_WRITE_BUFFER   => C_S2_AXI_PROHIBIT_WRITE_BUFFER,
      C_S2_AXI_PROHIBIT_EXCLUSIVE      => C_S2_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #3 specific.
      C_S3_AXI_BASEADDR         => C_BASEADDR,
      C_S3_AXI_HIGHADDR         => C_HIGHADDR,
      C_S3_AXI_ADDR_WIDTH       => C_S3_AXI_ADDR_WIDTH,
      C_S3_AXI_DATA_WIDTH       => C_S3_AXI_DATA_WIDTH,
      C_S3_AXI_ID_WIDTH         => C_S3_AXI_ID_WIDTH,
      C_S3_AXI_SUPPORT_UNIQUE   => C_S3_AXI_SUPPORT_UNIQUE,
      C_S3_AXI_SUPPORT_DIRTY    => C_S3_AXI_SUPPORT_DIRTY,
      C_S3_AXI_FORCE_READ_ALLOCATE     => C_S3_AXI_FORCE_READ_ALLOCATE,
      C_S3_AXI_PROHIBIT_READ_ALLOCATE  => C_S3_AXI_PROHIBIT_READ_ALLOCATE,
      C_S3_AXI_FORCE_WRITE_ALLOCATE    => C_S3_AXI_FORCE_WRITE_ALLOCATE,
      C_S3_AXI_PROHIBIT_WRITE_ALLOCATE => C_S3_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S3_AXI_FORCE_READ_BUFFER       => C_S3_AXI_FORCE_READ_BUFFER,
      C_S3_AXI_PROHIBIT_READ_BUFFER    => C_S3_AXI_PROHIBIT_READ_BUFFER,
      C_S3_AXI_FORCE_WRITE_BUFFER      => C_S3_AXI_FORCE_WRITE_BUFFER,
      C_S3_AXI_PROHIBIT_WRITE_BUFFER   => C_S3_AXI_PROHIBIT_WRITE_BUFFER,
      C_S3_AXI_PROHIBIT_EXCLUSIVE      => C_S3_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #4 specific.
      C_S4_AXI_BASEADDR         => C_BASEADDR,
      C_S4_AXI_HIGHADDR         => C_HIGHADDR,
      C_S4_AXI_ADDR_WIDTH       => C_S4_AXI_ADDR_WIDTH,
      C_S4_AXI_DATA_WIDTH       => C_S4_AXI_DATA_WIDTH,
      C_S4_AXI_ID_WIDTH         => C_S4_AXI_ID_WIDTH,
      C_S4_AXI_SUPPORT_UNIQUE   => C_S4_AXI_SUPPORT_UNIQUE,
      C_S4_AXI_SUPPORT_DIRTY    => C_S4_AXI_SUPPORT_DIRTY,
      C_S4_AXI_FORCE_READ_ALLOCATE     => C_S4_AXI_FORCE_READ_ALLOCATE,
      C_S4_AXI_PROHIBIT_READ_ALLOCATE  => C_S4_AXI_PROHIBIT_READ_ALLOCATE,
      C_S4_AXI_FORCE_WRITE_ALLOCATE    => C_S4_AXI_FORCE_WRITE_ALLOCATE,
      C_S4_AXI_PROHIBIT_WRITE_ALLOCATE => C_S4_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S4_AXI_FORCE_READ_BUFFER       => C_S4_AXI_FORCE_READ_BUFFER,
      C_S4_AXI_PROHIBIT_READ_BUFFER    => C_S4_AXI_PROHIBIT_READ_BUFFER,
      C_S4_AXI_FORCE_WRITE_BUFFER      => C_S4_AXI_FORCE_WRITE_BUFFER,
      C_S4_AXI_PROHIBIT_WRITE_BUFFER   => C_S4_AXI_PROHIBIT_WRITE_BUFFER,
      C_S4_AXI_PROHIBIT_EXCLUSIVE      => C_S4_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #5 specific.
      C_S5_AXI_BASEADDR         => C_BASEADDR,
      C_S5_AXI_HIGHADDR         => C_HIGHADDR,
      C_S5_AXI_ADDR_WIDTH       => C_S5_AXI_ADDR_WIDTH,
      C_S5_AXI_DATA_WIDTH       => C_S5_AXI_DATA_WIDTH,
      C_S5_AXI_ID_WIDTH         => C_S5_AXI_ID_WIDTH,
      C_S5_AXI_SUPPORT_UNIQUE   => C_S5_AXI_SUPPORT_UNIQUE,
      C_S5_AXI_SUPPORT_DIRTY    => C_S5_AXI_SUPPORT_DIRTY,
      C_S5_AXI_FORCE_READ_ALLOCATE     => C_S5_AXI_FORCE_READ_ALLOCATE,
      C_S5_AXI_PROHIBIT_READ_ALLOCATE  => C_S5_AXI_PROHIBIT_READ_ALLOCATE,
      C_S5_AXI_FORCE_WRITE_ALLOCATE    => C_S5_AXI_FORCE_WRITE_ALLOCATE,
      C_S5_AXI_PROHIBIT_WRITE_ALLOCATE => C_S5_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S5_AXI_FORCE_READ_BUFFER       => C_S5_AXI_FORCE_READ_BUFFER,
      C_S5_AXI_PROHIBIT_READ_BUFFER    => C_S5_AXI_PROHIBIT_READ_BUFFER,
      C_S5_AXI_FORCE_WRITE_BUFFER      => C_S5_AXI_FORCE_WRITE_BUFFER,
      C_S5_AXI_PROHIBIT_WRITE_BUFFER   => C_S5_AXI_PROHIBIT_WRITE_BUFFER,
      C_S5_AXI_PROHIBIT_EXCLUSIVE      => C_S5_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #6 specific.
      C_S6_AXI_BASEADDR         => C_BASEADDR,
      C_S6_AXI_HIGHADDR         => C_HIGHADDR,
      C_S6_AXI_ADDR_WIDTH       => C_S6_AXI_ADDR_WIDTH,
      C_S6_AXI_DATA_WIDTH       => C_S6_AXI_DATA_WIDTH,
      C_S6_AXI_ID_WIDTH         => C_S6_AXI_ID_WIDTH,
      C_S6_AXI_SUPPORT_UNIQUE   => C_S6_AXI_SUPPORT_UNIQUE,
      C_S6_AXI_SUPPORT_DIRTY    => C_S6_AXI_SUPPORT_DIRTY,
      C_S6_AXI_FORCE_READ_ALLOCATE     => C_S6_AXI_FORCE_READ_ALLOCATE,
      C_S6_AXI_PROHIBIT_READ_ALLOCATE  => C_S6_AXI_PROHIBIT_READ_ALLOCATE,
      C_S6_AXI_FORCE_WRITE_ALLOCATE    => C_S6_AXI_FORCE_WRITE_ALLOCATE,
      C_S6_AXI_PROHIBIT_WRITE_ALLOCATE => C_S6_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S6_AXI_FORCE_READ_BUFFER       => C_S6_AXI_FORCE_READ_BUFFER,
      C_S6_AXI_PROHIBIT_READ_BUFFER    => C_S6_AXI_PROHIBIT_READ_BUFFER,
      C_S6_AXI_FORCE_WRITE_BUFFER      => C_S6_AXI_FORCE_WRITE_BUFFER,
      C_S6_AXI_PROHIBIT_WRITE_BUFFER   => C_S6_AXI_PROHIBIT_WRITE_BUFFER,
      C_S6_AXI_PROHIBIT_EXCLUSIVE      => C_S6_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #7 specific.
      C_S7_AXI_BASEADDR         => C_BASEADDR,
      C_S7_AXI_HIGHADDR         => C_HIGHADDR,
      C_S7_AXI_ADDR_WIDTH       => C_S7_AXI_ADDR_WIDTH,
      C_S7_AXI_DATA_WIDTH       => C_S7_AXI_DATA_WIDTH,
      C_S7_AXI_ID_WIDTH         => C_S7_AXI_ID_WIDTH,
      C_S7_AXI_SUPPORT_UNIQUE   => C_S7_AXI_SUPPORT_UNIQUE,
      C_S7_AXI_SUPPORT_DIRTY    => C_S7_AXI_SUPPORT_DIRTY,
      C_S7_AXI_FORCE_READ_ALLOCATE     => C_S7_AXI_FORCE_READ_ALLOCATE,
      C_S7_AXI_PROHIBIT_READ_ALLOCATE  => C_S7_AXI_PROHIBIT_READ_ALLOCATE,
      C_S7_AXI_FORCE_WRITE_ALLOCATE    => C_S7_AXI_FORCE_WRITE_ALLOCATE,
      C_S7_AXI_PROHIBIT_WRITE_ALLOCATE => C_S7_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S7_AXI_FORCE_READ_BUFFER       => C_S7_AXI_FORCE_READ_BUFFER,
      C_S7_AXI_PROHIBIT_READ_BUFFER    => C_S7_AXI_PROHIBIT_READ_BUFFER,
      C_S7_AXI_FORCE_WRITE_BUFFER      => C_S7_AXI_FORCE_WRITE_BUFFER,
      C_S7_AXI_PROHIBIT_WRITE_BUFFER   => C_S7_AXI_PROHIBIT_WRITE_BUFFER,
      C_S7_AXI_PROHIBIT_EXCLUSIVE      => C_S7_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S8_AXI_BASEADDR         => C_BASEADDR,
      C_S8_AXI_HIGHADDR         => C_HIGHADDR,
      C_S8_AXI_ADDR_WIDTH       => C_S8_AXI_ADDR_WIDTH,
      C_S8_AXI_DATA_WIDTH       => C_S8_AXI_DATA_WIDTH,
      C_S8_AXI_ID_WIDTH         => C_S8_AXI_ID_WIDTH,
      C_S8_AXI_SUPPORT_UNIQUE   => C_S8_AXI_SUPPORT_UNIQUE,
      C_S8_AXI_SUPPORT_DIRTY    => C_S8_AXI_SUPPORT_DIRTY,
      C_S8_AXI_FORCE_READ_ALLOCATE     => C_S8_AXI_FORCE_READ_ALLOCATE,
      C_S8_AXI_PROHIBIT_READ_ALLOCATE  => C_S8_AXI_PROHIBIT_READ_ALLOCATE,
      C_S8_AXI_FORCE_WRITE_ALLOCATE    => C_S8_AXI_FORCE_WRITE_ALLOCATE,
      C_S8_AXI_PROHIBIT_WRITE_ALLOCATE => C_S8_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S8_AXI_FORCE_READ_BUFFER       => C_S8_AXI_FORCE_READ_BUFFER,
      C_S8_AXI_PROHIBIT_READ_BUFFER    => C_S8_AXI_PROHIBIT_READ_BUFFER,
      C_S8_AXI_FORCE_WRITE_BUFFER      => C_S8_AXI_FORCE_WRITE_BUFFER,
      C_S8_AXI_PROHIBIT_WRITE_BUFFER   => C_S8_AXI_PROHIBIT_WRITE_BUFFER,
      C_S8_AXI_PROHIBIT_EXCLUSIVE      => C_S8_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S9_AXI_BASEADDR         => C_BASEADDR,
      C_S9_AXI_HIGHADDR         => C_HIGHADDR,
      C_S9_AXI_ADDR_WIDTH       => C_S9_AXI_ADDR_WIDTH,
      C_S9_AXI_DATA_WIDTH       => C_S9_AXI_DATA_WIDTH,
      C_S9_AXI_ID_WIDTH         => C_S9_AXI_ID_WIDTH,
      C_S9_AXI_SUPPORT_UNIQUE   => C_S9_AXI_SUPPORT_UNIQUE,
      C_S9_AXI_SUPPORT_DIRTY    => C_S9_AXI_SUPPORT_DIRTY,
      C_S9_AXI_FORCE_READ_ALLOCATE     => C_S9_AXI_FORCE_READ_ALLOCATE,
      C_S9_AXI_PROHIBIT_READ_ALLOCATE  => C_S9_AXI_PROHIBIT_READ_ALLOCATE,
      C_S9_AXI_FORCE_WRITE_ALLOCATE    => C_S9_AXI_FORCE_WRITE_ALLOCATE,
      C_S9_AXI_PROHIBIT_WRITE_ALLOCATE => C_S9_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S9_AXI_FORCE_READ_BUFFER       => C_S9_AXI_FORCE_READ_BUFFER,
      C_S9_AXI_PROHIBIT_READ_BUFFER    => C_S9_AXI_PROHIBIT_READ_BUFFER,
      C_S9_AXI_FORCE_WRITE_BUFFER      => C_S9_AXI_FORCE_WRITE_BUFFER,
      C_S9_AXI_PROHIBIT_WRITE_BUFFER   => C_S9_AXI_PROHIBIT_WRITE_BUFFER,
      C_S9_AXI_PROHIBIT_EXCLUSIVE      => C_S9_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S10_AXI_BASEADDR         => C_BASEADDR,
      C_S10_AXI_HIGHADDR         => C_HIGHADDR,
      C_S10_AXI_ADDR_WIDTH       => C_S10_AXI_ADDR_WIDTH,
      C_S10_AXI_DATA_WIDTH       => C_S10_AXI_DATA_WIDTH,
      C_S10_AXI_ID_WIDTH         => C_S10_AXI_ID_WIDTH,
      C_S10_AXI_SUPPORT_UNIQUE   => C_S10_AXI_SUPPORT_UNIQUE,
      C_S10_AXI_SUPPORT_DIRTY    => C_S10_AXI_SUPPORT_DIRTY,
      C_S10_AXI_FORCE_READ_ALLOCATE     => C_S10_AXI_FORCE_READ_ALLOCATE,
      C_S10_AXI_PROHIBIT_READ_ALLOCATE  => C_S10_AXI_PROHIBIT_READ_ALLOCATE,
      C_S10_AXI_FORCE_WRITE_ALLOCATE    => C_S10_AXI_FORCE_WRITE_ALLOCATE,
      C_S10_AXI_PROHIBIT_WRITE_ALLOCATE => C_S10_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S10_AXI_FORCE_READ_BUFFER       => C_S10_AXI_FORCE_READ_BUFFER,
      C_S10_AXI_PROHIBIT_READ_BUFFER    => C_S10_AXI_PROHIBIT_READ_BUFFER,
      C_S10_AXI_FORCE_WRITE_BUFFER      => C_S10_AXI_FORCE_WRITE_BUFFER,
      C_S10_AXI_PROHIBIT_WRITE_BUFFER   => C_S10_AXI_PROHIBIT_WRITE_BUFFER,
      C_S10_AXI_PROHIBIT_EXCLUSIVE      => C_S10_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S11_AXI_BASEADDR         => C_BASEADDR,
      C_S11_AXI_HIGHADDR         => C_HIGHADDR,
      C_S11_AXI_ADDR_WIDTH       => C_S11_AXI_ADDR_WIDTH,
      C_S11_AXI_DATA_WIDTH       => C_S11_AXI_DATA_WIDTH,
      C_S11_AXI_ID_WIDTH         => C_S11_AXI_ID_WIDTH,
      C_S11_AXI_SUPPORT_UNIQUE   => C_S11_AXI_SUPPORT_UNIQUE,
      C_S11_AXI_SUPPORT_DIRTY    => C_S11_AXI_SUPPORT_DIRTY,
      C_S11_AXI_FORCE_READ_ALLOCATE     => C_S11_AXI_FORCE_READ_ALLOCATE,
      C_S11_AXI_PROHIBIT_READ_ALLOCATE  => C_S11_AXI_PROHIBIT_READ_ALLOCATE,
      C_S11_AXI_FORCE_WRITE_ALLOCATE    => C_S11_AXI_FORCE_WRITE_ALLOCATE,
      C_S11_AXI_PROHIBIT_WRITE_ALLOCATE => C_S11_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S11_AXI_FORCE_READ_BUFFER       => C_S11_AXI_FORCE_READ_BUFFER,
      C_S11_AXI_PROHIBIT_READ_BUFFER    => C_S11_AXI_PROHIBIT_READ_BUFFER,
      C_S11_AXI_FORCE_WRITE_BUFFER      => C_S11_AXI_FORCE_WRITE_BUFFER,
      C_S11_AXI_PROHIBIT_WRITE_BUFFER   => C_S11_AXI_PROHIBIT_WRITE_BUFFER,
      C_S11_AXI_PROHIBIT_EXCLUSIVE      => C_S11_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S12_AXI_BASEADDR         => C_BASEADDR,
      C_S12_AXI_HIGHADDR         => C_HIGHADDR,
      C_S12_AXI_ADDR_WIDTH       => C_S12_AXI_ADDR_WIDTH,
      C_S12_AXI_DATA_WIDTH       => C_S12_AXI_DATA_WIDTH,
      C_S12_AXI_ID_WIDTH         => C_S12_AXI_ID_WIDTH,
      C_S12_AXI_SUPPORT_UNIQUE   => C_S12_AXI_SUPPORT_UNIQUE,
      C_S12_AXI_SUPPORT_DIRTY    => C_S12_AXI_SUPPORT_DIRTY,
      C_S12_AXI_FORCE_READ_ALLOCATE     => C_S12_AXI_FORCE_READ_ALLOCATE,
      C_S12_AXI_PROHIBIT_READ_ALLOCATE  => C_S12_AXI_PROHIBIT_READ_ALLOCATE,
      C_S12_AXI_FORCE_WRITE_ALLOCATE    => C_S12_AXI_FORCE_WRITE_ALLOCATE,
      C_S12_AXI_PROHIBIT_WRITE_ALLOCATE => C_S12_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S12_AXI_FORCE_READ_BUFFER       => C_S12_AXI_FORCE_READ_BUFFER,
      C_S12_AXI_PROHIBIT_READ_BUFFER    => C_S12_AXI_PROHIBIT_READ_BUFFER,
      C_S12_AXI_FORCE_WRITE_BUFFER      => C_S12_AXI_FORCE_WRITE_BUFFER,
      C_S12_AXI_PROHIBIT_WRITE_BUFFER   => C_S12_AXI_PROHIBIT_WRITE_BUFFER,
      C_S12_AXI_PROHIBIT_EXCLUSIVE      => C_S12_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S13_AXI_BASEADDR         => C_BASEADDR,
      C_S13_AXI_HIGHADDR         => C_HIGHADDR,
      C_S13_AXI_ADDR_WIDTH       => C_S13_AXI_ADDR_WIDTH,
      C_S13_AXI_DATA_WIDTH       => C_S13_AXI_DATA_WIDTH,
      C_S13_AXI_ID_WIDTH         => C_S13_AXI_ID_WIDTH,
      C_S13_AXI_SUPPORT_UNIQUE   => C_S13_AXI_SUPPORT_UNIQUE,
      C_S13_AXI_SUPPORT_DIRTY    => C_S13_AXI_SUPPORT_DIRTY,
      C_S13_AXI_FORCE_READ_ALLOCATE     => C_S13_AXI_FORCE_READ_ALLOCATE,
      C_S13_AXI_PROHIBIT_READ_ALLOCATE  => C_S13_AXI_PROHIBIT_READ_ALLOCATE,
      C_S13_AXI_FORCE_WRITE_ALLOCATE    => C_S13_AXI_FORCE_WRITE_ALLOCATE,
      C_S13_AXI_PROHIBIT_WRITE_ALLOCATE => C_S13_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S13_AXI_FORCE_READ_BUFFER       => C_S13_AXI_FORCE_READ_BUFFER,
      C_S13_AXI_PROHIBIT_READ_BUFFER    => C_S13_AXI_PROHIBIT_READ_BUFFER,
      C_S13_AXI_FORCE_WRITE_BUFFER      => C_S13_AXI_FORCE_WRITE_BUFFER,
      C_S13_AXI_PROHIBIT_WRITE_BUFFER   => C_S13_AXI_PROHIBIT_WRITE_BUFFER,
      C_S13_AXI_PROHIBIT_EXCLUSIVE      => C_S13_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S14_AXI_BASEADDR         => C_BASEADDR,
      C_S14_AXI_HIGHADDR         => C_HIGHADDR,
      C_S14_AXI_ADDR_WIDTH       => C_S14_AXI_ADDR_WIDTH,
      C_S14_AXI_DATA_WIDTH       => C_S14_AXI_DATA_WIDTH,
      C_S14_AXI_ID_WIDTH         => C_S14_AXI_ID_WIDTH,
      C_S14_AXI_SUPPORT_UNIQUE   => C_S14_AXI_SUPPORT_UNIQUE,
      C_S14_AXI_SUPPORT_DIRTY    => C_S14_AXI_SUPPORT_DIRTY,
      C_S14_AXI_FORCE_READ_ALLOCATE     => C_S14_AXI_FORCE_READ_ALLOCATE,
      C_S14_AXI_PROHIBIT_READ_ALLOCATE  => C_S14_AXI_PROHIBIT_READ_ALLOCATE,
      C_S14_AXI_FORCE_WRITE_ALLOCATE    => C_S14_AXI_FORCE_WRITE_ALLOCATE,
      C_S14_AXI_PROHIBIT_WRITE_ALLOCATE => C_S14_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S14_AXI_FORCE_READ_BUFFER       => C_S14_AXI_FORCE_READ_BUFFER,
      C_S14_AXI_PROHIBIT_READ_BUFFER    => C_S14_AXI_PROHIBIT_READ_BUFFER,
      C_S14_AXI_FORCE_WRITE_BUFFER      => C_S14_AXI_FORCE_WRITE_BUFFER,
      C_S14_AXI_PROHIBIT_WRITE_BUFFER   => C_S14_AXI_PROHIBIT_WRITE_BUFFER,
      C_S14_AXI_PROHIBIT_EXCLUSIVE      => C_S14_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Optimized AXI4 Slave Interface #0 specific.
      C_S15_AXI_BASEADDR         => C_BASEADDR,
      C_S15_AXI_HIGHADDR         => C_HIGHADDR,
      C_S15_AXI_ADDR_WIDTH       => C_S15_AXI_ADDR_WIDTH,
      C_S15_AXI_DATA_WIDTH       => C_S15_AXI_DATA_WIDTH,
      C_S15_AXI_ID_WIDTH         => C_S15_AXI_ID_WIDTH,
      C_S15_AXI_SUPPORT_UNIQUE   => C_S15_AXI_SUPPORT_UNIQUE,
      C_S15_AXI_SUPPORT_DIRTY    => C_S15_AXI_SUPPORT_DIRTY,
      C_S15_AXI_FORCE_READ_ALLOCATE     => C_S15_AXI_FORCE_READ_ALLOCATE,
      C_S15_AXI_PROHIBIT_READ_ALLOCATE  => C_S15_AXI_PROHIBIT_READ_ALLOCATE,
      C_S15_AXI_FORCE_WRITE_ALLOCATE    => C_S15_AXI_FORCE_WRITE_ALLOCATE,
      C_S15_AXI_PROHIBIT_WRITE_ALLOCATE => C_S15_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S15_AXI_FORCE_READ_BUFFER       => C_S15_AXI_FORCE_READ_BUFFER,
      C_S15_AXI_PROHIBIT_READ_BUFFER    => C_S15_AXI_PROHIBIT_READ_BUFFER,
      C_S15_AXI_FORCE_WRITE_BUFFER      => C_S15_AXI_FORCE_WRITE_BUFFER,
      C_S15_AXI_PROHIBIT_WRITE_BUFFER   => C_S15_AXI_PROHIBIT_WRITE_BUFFER,
      C_S15_AXI_PROHIBIT_EXCLUSIVE      => C_S15_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S0_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S0_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S0_AXI_GEN_ADDR_WIDTH   => C_S0_AXI_GEN_ADDR_WIDTH,
      C_S0_AXI_GEN_DATA_WIDTH   => C_S0_AXI_GEN_DATA_WIDTH,
      C_S0_AXI_GEN_ID_WIDTH     => C_S0_AXI_GEN_ID_WIDTH,
      C_S0_AXI_GEN_FORCE_READ_ALLOCATE      => C_S0_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S0_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S0_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S0_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S0_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S0_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S0_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S0_AXI_GEN_FORCE_READ_BUFFER        => C_S0_AXI_GEN_FORCE_READ_BUFFER,
      C_S0_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S0_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S0_AXI_GEN_FORCE_WRITE_BUFFER       => C_S0_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S0_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S0_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S0_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S0_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S1_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S1_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S1_AXI_GEN_ADDR_WIDTH   => C_S1_AXI_GEN_ADDR_WIDTH,
      C_S1_AXI_GEN_DATA_WIDTH   => C_S1_AXI_GEN_DATA_WIDTH,
      C_S1_AXI_GEN_ID_WIDTH     => C_S1_AXI_GEN_ID_WIDTH,
      C_S1_AXI_GEN_FORCE_READ_ALLOCATE      => C_S1_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S1_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S1_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S1_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S1_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S1_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S1_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S1_AXI_GEN_FORCE_READ_BUFFER        => C_S1_AXI_GEN_FORCE_READ_BUFFER,
      C_S1_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S1_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S1_AXI_GEN_FORCE_WRITE_BUFFER       => C_S1_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S1_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S1_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S1_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S1_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S2_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S2_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S2_AXI_GEN_ADDR_WIDTH   => C_S2_AXI_GEN_ADDR_WIDTH,
      C_S2_AXI_GEN_DATA_WIDTH   => C_S2_AXI_GEN_DATA_WIDTH,
      C_S2_AXI_GEN_ID_WIDTH     => C_S2_AXI_GEN_ID_WIDTH,
      C_S2_AXI_GEN_FORCE_READ_ALLOCATE      => C_S2_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S2_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S2_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S2_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S2_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S2_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S2_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S2_AXI_GEN_FORCE_READ_BUFFER        => C_S2_AXI_GEN_FORCE_READ_BUFFER,
      C_S2_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S2_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S2_AXI_GEN_FORCE_WRITE_BUFFER       => C_S2_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S2_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S2_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S2_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S2_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S3_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S3_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S3_AXI_GEN_ADDR_WIDTH   => C_S3_AXI_GEN_ADDR_WIDTH,
      C_S3_AXI_GEN_DATA_WIDTH   => C_S3_AXI_GEN_DATA_WIDTH,
      C_S3_AXI_GEN_ID_WIDTH     => C_S3_AXI_GEN_ID_WIDTH,
      C_S3_AXI_GEN_FORCE_READ_ALLOCATE      => C_S3_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S3_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S3_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S3_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S3_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S3_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S3_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S3_AXI_GEN_FORCE_READ_BUFFER        => C_S3_AXI_GEN_FORCE_READ_BUFFER,
      C_S3_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S3_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S3_AXI_GEN_FORCE_WRITE_BUFFER       => C_S3_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S3_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S3_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S3_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S3_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S4_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S4_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S4_AXI_GEN_ADDR_WIDTH   => C_S4_AXI_GEN_ADDR_WIDTH,
      C_S4_AXI_GEN_DATA_WIDTH   => C_S4_AXI_GEN_DATA_WIDTH,
      C_S4_AXI_GEN_ID_WIDTH     => C_S4_AXI_GEN_ID_WIDTH,
      C_S4_AXI_GEN_FORCE_READ_ALLOCATE      => C_S4_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S4_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S4_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S4_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S4_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S4_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S4_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S4_AXI_GEN_FORCE_READ_BUFFER        => C_S4_AXI_GEN_FORCE_READ_BUFFER,
      C_S4_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S4_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S4_AXI_GEN_FORCE_WRITE_BUFFER       => C_S4_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S4_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S4_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S4_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S4_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S5_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S5_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S5_AXI_GEN_ADDR_WIDTH   => C_S5_AXI_GEN_ADDR_WIDTH,
      C_S5_AXI_GEN_DATA_WIDTH   => C_S5_AXI_GEN_DATA_WIDTH,
      C_S5_AXI_GEN_ID_WIDTH     => C_S5_AXI_GEN_ID_WIDTH,
      C_S5_AXI_GEN_FORCE_READ_ALLOCATE      => C_S5_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S5_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S5_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S5_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S5_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S5_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S5_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S5_AXI_GEN_FORCE_READ_BUFFER        => C_S5_AXI_GEN_FORCE_READ_BUFFER,
      C_S5_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S5_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S5_AXI_GEN_FORCE_WRITE_BUFFER       => C_S5_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S5_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S5_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S5_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S5_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S6_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S6_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S6_AXI_GEN_ADDR_WIDTH   => C_S6_AXI_GEN_ADDR_WIDTH,
      C_S6_AXI_GEN_DATA_WIDTH   => C_S6_AXI_GEN_DATA_WIDTH,
      C_S6_AXI_GEN_ID_WIDTH     => C_S6_AXI_GEN_ID_WIDTH,
      C_S6_AXI_GEN_FORCE_READ_ALLOCATE      => C_S6_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S6_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S6_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S6_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S6_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S6_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S6_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S6_AXI_GEN_FORCE_READ_BUFFER        => C_S6_AXI_GEN_FORCE_READ_BUFFER,
      C_S6_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S6_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S6_AXI_GEN_FORCE_WRITE_BUFFER       => C_S6_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S6_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S6_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S6_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S6_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S7_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S7_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S7_AXI_GEN_ADDR_WIDTH   => C_S7_AXI_GEN_ADDR_WIDTH,
      C_S7_AXI_GEN_DATA_WIDTH   => C_S7_AXI_GEN_DATA_WIDTH,
      C_S7_AXI_GEN_ID_WIDTH     => C_S7_AXI_GEN_ID_WIDTH,
      C_S7_AXI_GEN_FORCE_READ_ALLOCATE      => C_S7_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S7_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S7_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S7_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S7_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S7_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S7_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S7_AXI_GEN_FORCE_READ_BUFFER        => C_S7_AXI_GEN_FORCE_READ_BUFFER,
      C_S7_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S7_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S7_AXI_GEN_FORCE_WRITE_BUFFER       => C_S7_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S7_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S7_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S7_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S7_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S8_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S8_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S8_AXI_GEN_ADDR_WIDTH   => C_S8_AXI_GEN_ADDR_WIDTH,
      C_S8_AXI_GEN_DATA_WIDTH   => C_S8_AXI_GEN_DATA_WIDTH,
      C_S8_AXI_GEN_ID_WIDTH     => C_S8_AXI_GEN_ID_WIDTH,
      C_S8_AXI_GEN_FORCE_READ_ALLOCATE      => C_S8_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S8_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S8_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S8_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S8_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S8_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S8_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S8_AXI_GEN_FORCE_READ_BUFFER        => C_S8_AXI_GEN_FORCE_READ_BUFFER,
      C_S8_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S8_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S8_AXI_GEN_FORCE_WRITE_BUFFER       => C_S8_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S8_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S8_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S8_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S8_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S9_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S9_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S9_AXI_GEN_ADDR_WIDTH   => C_S9_AXI_GEN_ADDR_WIDTH,
      C_S9_AXI_GEN_DATA_WIDTH   => C_S9_AXI_GEN_DATA_WIDTH,
      C_S9_AXI_GEN_ID_WIDTH     => C_S9_AXI_GEN_ID_WIDTH,
      C_S9_AXI_GEN_FORCE_READ_ALLOCATE      => C_S9_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S9_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S9_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S9_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S9_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S9_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S9_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S9_AXI_GEN_FORCE_READ_BUFFER        => C_S9_AXI_GEN_FORCE_READ_BUFFER,
      C_S9_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S9_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S9_AXI_GEN_FORCE_WRITE_BUFFER       => C_S9_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S9_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S9_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S9_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S9_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S10_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S10_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S10_AXI_GEN_ADDR_WIDTH   => C_S10_AXI_GEN_ADDR_WIDTH,
      C_S10_AXI_GEN_DATA_WIDTH   => C_S10_AXI_GEN_DATA_WIDTH,
      C_S10_AXI_GEN_ID_WIDTH     => C_S10_AXI_GEN_ID_WIDTH,
      C_S10_AXI_GEN_FORCE_READ_ALLOCATE      => C_S10_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S10_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S10_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S10_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S10_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S10_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S10_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S10_AXI_GEN_FORCE_READ_BUFFER        => C_S10_AXI_GEN_FORCE_READ_BUFFER,
      C_S10_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S10_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S10_AXI_GEN_FORCE_WRITE_BUFFER       => C_S10_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S10_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S10_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S10_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S10_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S11_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S11_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S11_AXI_GEN_ADDR_WIDTH   => C_S11_AXI_GEN_ADDR_WIDTH,
      C_S11_AXI_GEN_DATA_WIDTH   => C_S11_AXI_GEN_DATA_WIDTH,
      C_S11_AXI_GEN_ID_WIDTH     => C_S11_AXI_GEN_ID_WIDTH,
      C_S11_AXI_GEN_FORCE_READ_ALLOCATE      => C_S11_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S11_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S11_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S11_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S11_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S11_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S11_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S11_AXI_GEN_FORCE_READ_BUFFER        => C_S11_AXI_GEN_FORCE_READ_BUFFER,
      C_S11_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S11_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S11_AXI_GEN_FORCE_WRITE_BUFFER       => C_S11_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S11_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S11_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S11_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S11_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S12_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S12_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S12_AXI_GEN_ADDR_WIDTH   => C_S12_AXI_GEN_ADDR_WIDTH,
      C_S12_AXI_GEN_DATA_WIDTH   => C_S12_AXI_GEN_DATA_WIDTH,
      C_S12_AXI_GEN_ID_WIDTH     => C_S12_AXI_GEN_ID_WIDTH,
      C_S12_AXI_GEN_FORCE_READ_ALLOCATE      => C_S12_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S12_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S12_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S12_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S12_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S12_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S12_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S12_AXI_GEN_FORCE_READ_BUFFER        => C_S12_AXI_GEN_FORCE_READ_BUFFER,
      C_S12_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S12_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S12_AXI_GEN_FORCE_WRITE_BUFFER       => C_S12_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S12_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S12_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S12_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S12_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S13_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S13_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S13_AXI_GEN_ADDR_WIDTH   => C_S13_AXI_GEN_ADDR_WIDTH,
      C_S13_AXI_GEN_DATA_WIDTH   => C_S13_AXI_GEN_DATA_WIDTH,
      C_S13_AXI_GEN_ID_WIDTH     => C_S13_AXI_GEN_ID_WIDTH,
      C_S13_AXI_GEN_FORCE_READ_ALLOCATE      => C_S13_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S13_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S13_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S13_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S13_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S13_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S13_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S13_AXI_GEN_FORCE_READ_BUFFER        => C_S13_AXI_GEN_FORCE_READ_BUFFER,
      C_S13_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S13_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S13_AXI_GEN_FORCE_WRITE_BUFFER       => C_S13_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S13_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S13_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S13_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S13_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S14_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S14_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S14_AXI_GEN_ADDR_WIDTH   => C_S14_AXI_GEN_ADDR_WIDTH,
      C_S14_AXI_GEN_DATA_WIDTH   => C_S14_AXI_GEN_DATA_WIDTH,
      C_S14_AXI_GEN_ID_WIDTH     => C_S14_AXI_GEN_ID_WIDTH,
      C_S14_AXI_GEN_FORCE_READ_ALLOCATE      => C_S14_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S14_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S14_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S14_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S14_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S14_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S14_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S14_AXI_GEN_FORCE_READ_BUFFER        => C_S14_AXI_GEN_FORCE_READ_BUFFER,
      C_S14_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S14_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S14_AXI_GEN_FORCE_WRITE_BUFFER       => C_S14_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S14_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S14_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S14_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S14_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Generic AXI4 Slave Interface #0 specific.
      C_S15_AXI_GEN_BASEADDR     => C_BASEADDR,
      C_S15_AXI_GEN_HIGHADDR     => C_HIGHADDR,
      C_S15_AXI_GEN_ADDR_WIDTH   => C_S15_AXI_GEN_ADDR_WIDTH,
      C_S15_AXI_GEN_DATA_WIDTH   => C_S15_AXI_GEN_DATA_WIDTH,
      C_S15_AXI_GEN_ID_WIDTH     => C_S15_AXI_GEN_ID_WIDTH,
      C_S15_AXI_GEN_FORCE_READ_ALLOCATE      => C_S15_AXI_GEN_FORCE_READ_ALLOCATE,
      C_S15_AXI_GEN_PROHIBIT_READ_ALLOCATE   => C_S15_AXI_GEN_PROHIBIT_READ_ALLOCATE,
      C_S15_AXI_GEN_FORCE_WRITE_ALLOCATE     => C_S15_AXI_GEN_FORCE_WRITE_ALLOCATE,
      C_S15_AXI_GEN_PROHIBIT_WRITE_ALLOCATE  => C_S15_AXI_GEN_PROHIBIT_WRITE_ALLOCATE,
      C_S15_AXI_GEN_FORCE_READ_BUFFER        => C_S15_AXI_GEN_FORCE_READ_BUFFER,
      C_S15_AXI_GEN_PROHIBIT_READ_BUFFER     => C_S15_AXI_GEN_PROHIBIT_READ_BUFFER,
      C_S15_AXI_GEN_FORCE_WRITE_BUFFER       => C_S15_AXI_GEN_FORCE_WRITE_BUFFER,
      C_S15_AXI_GEN_PROHIBIT_WRITE_BUFFER    => C_S15_AXI_GEN_PROHIBIT_WRITE_BUFFER,
      C_S15_AXI_GEN_PROHIBIT_EXCLUSIVE       => C_S15_AXI_GEN_PROHIBIT_EXCLUSIVE,
      
      -- Data type and settings specific.
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_POS'high,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_POS'low,
      C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
      C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      C_Lx_ADDR_REQ_HI          => C_Lx_ADDR_REQ_POS'high,
      C_Lx_ADDR_REQ_LO          => C_Lx_ADDR_REQ_POS'low,
      C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_POS'high,
      C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_POS'low,
      C_Lx_ADDR_DATA_HI         => C_Lx_ADDR_DATA_POS'high,
      C_Lx_ADDR_DATA_LO         => C_Lx_ADDR_DATA_POS'low,
      C_Lx_ADDR_TAG_HI          => C_Lx_ADDR_TAG_POS'high,
      C_Lx_ADDR_TAG_LO          => C_Lx_ADDR_TAG_POS'low,
      C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_POS'high,
      C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_POS'low,
      C_Lx_ADDR_OFFSET_HI       => C_Lx_ADDR_OFFSET_POS'high,
      C_Lx_ADDR_OFFSET_LO       => C_Lx_ADDR_OFFSET_POS'low,
      C_Lx_ADDR_WORD_HI         => C_Lx_ADDR_WORD_POS'high,
      C_Lx_ADDR_WORD_LO         => C_Lx_ADDR_WORD_POS'low,
      C_Lx_ADDR_BYTE_HI         => C_Lx_ADDR_BYTE_POS'high,
      C_Lx_ADDR_BYTE_LO         => C_Lx_ADDR_BYTE_POS'low,
      
      -- Lx Cache Specific.
      C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
      C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
      C_Lx_NUM_ADDR_TAG_BITS    => C_Lx_NUM_ADDR_TAG_BITS,
      
      -- System Cache Specific.
      C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
      C_ID_WIDTH                => C_ID_WIDTH,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_ENABLE_CTRL             => C_ENABLE_CTRL,
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_GENERIC_PORTS       => C_NUM_GENERIC_PORTS,
      C_NUM_PORTS               => C_NUM_PORTS,
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #0 Slave Signals.
      
      S0_AXI_AWID               => S0_AXI_AWID,
      S0_AXI_AWADDR             => S0_AXI_AWADDR,
      S0_AXI_AWLEN              => S0_AXI_AWLEN,
      S0_AXI_AWSIZE             => S0_AXI_AWSIZE,
      S0_AXI_AWBURST            => S0_AXI_AWBURST,
      S0_AXI_AWLOCK             => S0_AXI_AWLOCK,
      S0_AXI_AWCACHE            => S0_AXI_AWCACHE,
      S0_AXI_AWPROT             => S0_AXI_AWPROT,
      S0_AXI_AWQOS              => S0_AXI_AWQOS,
      S0_AXI_AWVALID            => S0_AXI_AWVALID,
      S0_AXI_AWREADY            => S0_AXI_AWREADY,
      S0_AXI_AWDOMAIN           => S0_AXI_AWDOMAIN,
      S0_AXI_AWSNOOP            => S0_AXI_AWSNOOP,
      S0_AXI_AWBAR              => S0_AXI_AWBAR,
      S0_AXI_AWUSER             => S0_AXI_AWUSER,
      
      S0_AXI_WDATA              => S0_AXI_WDATA,
      S0_AXI_WSTRB              => S0_AXI_WSTRB,
      S0_AXI_WLAST              => S0_AXI_WLAST,
      S0_AXI_WVALID             => S0_AXI_WVALID,
      S0_AXI_WREADY             => S0_AXI_WREADY,
      
      S0_AXI_BRESP              => S0_AXI_BRESP,
      S0_AXI_BID                => S0_AXI_BID,
      S0_AXI_BVALID             => S0_AXI_BVALID,
      S0_AXI_BREADY             => S0_AXI_BREADY,
      S0_AXI_WACK               => S0_AXI_WACK,
      
      S0_AXI_ARID               => S0_AXI_ARID,
      S0_AXI_ARADDR             => S0_AXI_ARADDR,
      S0_AXI_ARLEN              => S0_AXI_ARLEN,
      S0_AXI_ARSIZE             => S0_AXI_ARSIZE,
      S0_AXI_ARBURST            => S0_AXI_ARBURST,
      S0_AXI_ARLOCK             => S0_AXI_ARLOCK,
      S0_AXI_ARCACHE            => S0_AXI_ARCACHE,
      S0_AXI_ARPROT             => S0_AXI_ARPROT,
      S0_AXI_ARQOS              => S0_AXI_ARQOS,
      S0_AXI_ARVALID            => S0_AXI_ARVALID,
      S0_AXI_ARREADY            => S0_AXI_ARREADY,
      S0_AXI_ARDOMAIN           => S0_AXI_ARDOMAIN,
      S0_AXI_ARSNOOP            => S0_AXI_ARSNOOP,
      S0_AXI_ARBAR              => S0_AXI_ARBAR,
      S0_AXI_ARUSER             => S0_AXI_ARUSER,
      
      S0_AXI_RID                => S0_AXI_RID,
      S0_AXI_RDATA              => S0_AXI_RDATA,
      S0_AXI_RRESP              => S0_AXI_RRESP,
      S0_AXI_RLAST              => S0_AXI_RLAST,
      S0_AXI_RVALID             => S0_AXI_RVALID,
      S0_AXI_RREADY             => S0_AXI_RREADY,
      S0_AXI_RACK               => S0_AXI_RACK,
      
      S0_AXI_ACVALID            => S0_AXI_ACVALID,
      S0_AXI_ACADDR             => S0_AXI_ACADDR,
      S0_AXI_ACSNOOP            => S0_AXI_ACSNOOP,
      S0_AXI_ACPROT             => S0_AXI_ACPROT,
      S0_AXI_ACREADY            => S0_AXI_ACREADY,
      
      S0_AXI_CRVALID            => S0_AXI_CRVALID,
      S0_AXI_CRRESP             => S0_AXI_CRRESP,
      S0_AXI_CRREADY            => S0_AXI_CRREADY,
      
      S0_AXI_CDVALID            => S0_AXI_CDVALID,
      S0_AXI_CDDATA             => S0_AXI_CDDATA,
      S0_AXI_CDLAST             => S0_AXI_CDLAST,
      S0_AXI_CDREADY            => S0_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #1 Slave Signals.
      
      S1_AXI_AWID               => S1_AXI_AWID,
      S1_AXI_AWADDR             => S1_AXI_AWADDR,
      S1_AXI_AWLEN              => S1_AXI_AWLEN,
      S1_AXI_AWSIZE             => S1_AXI_AWSIZE,
      S1_AXI_AWBURST            => S1_AXI_AWBURST,
      S1_AXI_AWLOCK             => S1_AXI_AWLOCK,
      S1_AXI_AWCACHE            => S1_AXI_AWCACHE,
      S1_AXI_AWPROT             => S1_AXI_AWPROT,
      S1_AXI_AWQOS              => S1_AXI_AWQOS,
      S1_AXI_AWVALID            => S1_AXI_AWVALID,
      S1_AXI_AWREADY            => S1_AXI_AWREADY,
      S1_AXI_AWDOMAIN           => S1_AXI_AWDOMAIN,
      S1_AXI_AWSNOOP            => S1_AXI_AWSNOOP,
      S1_AXI_AWBAR              => S1_AXI_AWBAR,
      S1_AXI_AWUSER             => S1_AXI_AWUSER,
      
      S1_AXI_WDATA              => S1_AXI_WDATA,
      S1_AXI_WSTRB              => S1_AXI_WSTRB,
      S1_AXI_WLAST              => S1_AXI_WLAST,
      S1_AXI_WVALID             => S1_AXI_WVALID,
      S1_AXI_WREADY             => S1_AXI_WREADY,
      
      S1_AXI_BRESP              => S1_AXI_BRESP,
      S1_AXI_BID                => S1_AXI_BID,
      S1_AXI_BVALID             => S1_AXI_BVALID,
      S1_AXI_BREADY             => S1_AXI_BREADY,
      S1_AXI_WACK               => S1_AXI_WACK,
      
      S1_AXI_ARID               => S1_AXI_ARID,
      S1_AXI_ARADDR             => S1_AXI_ARADDR,
      S1_AXI_ARLEN              => S1_AXI_ARLEN,
      S1_AXI_ARSIZE             => S1_AXI_ARSIZE,
      S1_AXI_ARBURST            => S1_AXI_ARBURST,
      S1_AXI_ARLOCK             => S1_AXI_ARLOCK,
      S1_AXI_ARCACHE            => S1_AXI_ARCACHE,
      S1_AXI_ARPROT             => S1_AXI_ARPROT,
      S1_AXI_ARQOS              => S1_AXI_ARQOS,
      S1_AXI_ARVALID            => S1_AXI_ARVALID,
      S1_AXI_ARREADY            => S1_AXI_ARREADY,
      S1_AXI_ARDOMAIN           => S1_AXI_ARDOMAIN,
      S1_AXI_ARSNOOP            => S1_AXI_ARSNOOP,
      S1_AXI_ARBAR              => S1_AXI_ARBAR,
      S1_AXI_ARUSER             => S1_AXI_ARUSER,
      
      S1_AXI_RID                => S1_AXI_RID,
      S1_AXI_RDATA              => S1_AXI_RDATA,
      S1_AXI_RRESP              => S1_AXI_RRESP,
      S1_AXI_RLAST              => S1_AXI_RLAST,
      S1_AXI_RVALID             => S1_AXI_RVALID,
      S1_AXI_RREADY             => S1_AXI_RREADY,
      S1_AXI_RACK               => S1_AXI_RACK,
      
      S1_AXI_ACVALID            => S1_AXI_ACVALID,
      S1_AXI_ACADDR             => S1_AXI_ACADDR,
      S1_AXI_ACSNOOP            => S1_AXI_ACSNOOP,
      S1_AXI_ACPROT             => S1_AXI_ACPROT,
      S1_AXI_ACREADY            => S1_AXI_ACREADY,
      
      S1_AXI_CRVALID            => S1_AXI_CRVALID,
      S1_AXI_CRRESP             => S1_AXI_CRRESP,
      S1_AXI_CRREADY            => S1_AXI_CRREADY,
      
      S1_AXI_CDVALID            => S1_AXI_CDVALID,
      S1_AXI_CDDATA             => S1_AXI_CDDATA,
      S1_AXI_CDLAST             => S1_AXI_CDLAST,
      S1_AXI_CDREADY            => S1_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #2 Slave Signals.
      
      S2_AXI_AWID               => S2_AXI_AWID,
      S2_AXI_AWADDR             => S2_AXI_AWADDR,
      S2_AXI_AWLEN              => S2_AXI_AWLEN,
      S2_AXI_AWSIZE             => S2_AXI_AWSIZE,
      S2_AXI_AWBURST            => S2_AXI_AWBURST,
      S2_AXI_AWLOCK             => S2_AXI_AWLOCK,
      S2_AXI_AWCACHE            => S2_AXI_AWCACHE,
      S2_AXI_AWPROT             => S2_AXI_AWPROT,
      S2_AXI_AWQOS              => S2_AXI_AWQOS,
      S2_AXI_AWVALID            => S2_AXI_AWVALID,
      S2_AXI_AWREADY            => S2_AXI_AWREADY,
      S2_AXI_AWDOMAIN           => S2_AXI_AWDOMAIN,
      S2_AXI_AWSNOOP            => S2_AXI_AWSNOOP,
      S2_AXI_AWBAR              => S2_AXI_AWBAR,
      S2_AXI_AWUSER             => S2_AXI_AWUSER,
      
      S2_AXI_WDATA              => S2_AXI_WDATA,
      S2_AXI_WSTRB              => S2_AXI_WSTRB,
      S2_AXI_WLAST              => S2_AXI_WLAST,
      S2_AXI_WVALID             => S2_AXI_WVALID,
      S2_AXI_WREADY             => S2_AXI_WREADY,
      
      S2_AXI_BRESP              => S2_AXI_BRESP,
      S2_AXI_BID                => S2_AXI_BID,
      S2_AXI_BVALID             => S2_AXI_BVALID,
      S2_AXI_BREADY             => S2_AXI_BREADY,
      S2_AXI_WACK               => S2_AXI_WACK,
      
      S2_AXI_ARID               => S2_AXI_ARID,
      S2_AXI_ARADDR             => S2_AXI_ARADDR,
      S2_AXI_ARLEN              => S2_AXI_ARLEN,
      S2_AXI_ARSIZE             => S2_AXI_ARSIZE,
      S2_AXI_ARBURST            => S2_AXI_ARBURST,
      S2_AXI_ARLOCK             => S2_AXI_ARLOCK,
      S2_AXI_ARCACHE            => S2_AXI_ARCACHE,
      S2_AXI_ARPROT             => S2_AXI_ARPROT,
      S2_AXI_ARQOS              => S2_AXI_ARQOS,
      S2_AXI_ARVALID            => S2_AXI_ARVALID,
      S2_AXI_ARREADY            => S2_AXI_ARREADY,
      S2_AXI_ARDOMAIN           => S2_AXI_ARDOMAIN,
      S2_AXI_ARSNOOP            => S2_AXI_ARSNOOP,
      S2_AXI_ARBAR              => S2_AXI_ARBAR,
      S2_AXI_ARUSER             => S2_AXI_ARUSER,
      
      S2_AXI_RID                => S2_AXI_RID,
      S2_AXI_RDATA              => S2_AXI_RDATA,
      S2_AXI_RRESP              => S2_AXI_RRESP,
      S2_AXI_RLAST              => S2_AXI_RLAST,
      S2_AXI_RVALID             => S2_AXI_RVALID,
      S2_AXI_RREADY             => S2_AXI_RREADY,
      S2_AXI_RACK               => S2_AXI_RACK,
      
      S2_AXI_ACVALID            => S2_AXI_ACVALID,
      S2_AXI_ACADDR             => S2_AXI_ACADDR,
      S2_AXI_ACSNOOP            => S2_AXI_ACSNOOP,
      S2_AXI_ACPROT             => S2_AXI_ACPROT,
      S2_AXI_ACREADY            => S2_AXI_ACREADY,
      
      S2_AXI_CRVALID            => S2_AXI_CRVALID,
      S2_AXI_CRRESP             => S2_AXI_CRRESP,
      S2_AXI_CRREADY            => S2_AXI_CRREADY,
      
      S2_AXI_CDVALID            => S2_AXI_CDVALID,
      S2_AXI_CDDATA             => S2_AXI_CDDATA,
      S2_AXI_CDLAST             => S2_AXI_CDLAST,
      S2_AXI_CDREADY            => S2_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #3 Slave Signals.
      
      S3_AXI_AWID               => S3_AXI_AWID,
      S3_AXI_AWADDR             => S3_AXI_AWADDR,
      S3_AXI_AWLEN              => S3_AXI_AWLEN,
      S3_AXI_AWSIZE             => S3_AXI_AWSIZE,
      S3_AXI_AWBURST            => S3_AXI_AWBURST,
      S3_AXI_AWLOCK             => S3_AXI_AWLOCK,
      S3_AXI_AWCACHE            => S3_AXI_AWCACHE,
      S3_AXI_AWPROT             => S3_AXI_AWPROT,
      S3_AXI_AWQOS              => S3_AXI_AWQOS,
      S3_AXI_AWVALID            => S3_AXI_AWVALID,
      S3_AXI_AWREADY            => S3_AXI_AWREADY,
      S3_AXI_AWDOMAIN           => S3_AXI_AWDOMAIN,
      S3_AXI_AWSNOOP            => S3_AXI_AWSNOOP,
      S3_AXI_AWBAR              => S3_AXI_AWBAR,
      S3_AXI_AWUSER             => S3_AXI_AWUSER,
      
      S3_AXI_WDATA              => S3_AXI_WDATA,
      S3_AXI_WSTRB              => S3_AXI_WSTRB,
      S3_AXI_WLAST              => S3_AXI_WLAST,
      S3_AXI_WVALID             => S3_AXI_WVALID,
      S3_AXI_WREADY             => S3_AXI_WREADY,
      
      S3_AXI_BRESP              => S3_AXI_BRESP,
      S3_AXI_BID                => S3_AXI_BID,
      S3_AXI_BVALID             => S3_AXI_BVALID,
      S3_AXI_BREADY             => S3_AXI_BREADY,
      S3_AXI_WACK               => S3_AXI_WACK,
      
      S3_AXI_ARID               => S3_AXI_ARID,
      S3_AXI_ARADDR             => S3_AXI_ARADDR,
      S3_AXI_ARLEN              => S3_AXI_ARLEN,
      S3_AXI_ARSIZE             => S3_AXI_ARSIZE,
      S3_AXI_ARBURST            => S3_AXI_ARBURST,
      S3_AXI_ARLOCK             => S3_AXI_ARLOCK,
      S3_AXI_ARCACHE            => S3_AXI_ARCACHE,
      S3_AXI_ARPROT             => S3_AXI_ARPROT,
      S3_AXI_ARQOS              => S3_AXI_ARQOS,
      S3_AXI_ARVALID            => S3_AXI_ARVALID,
      S3_AXI_ARREADY            => S3_AXI_ARREADY,
      S3_AXI_ARDOMAIN           => S3_AXI_ARDOMAIN,
      S3_AXI_ARSNOOP            => S3_AXI_ARSNOOP,
      S3_AXI_ARBAR              => S3_AXI_ARBAR,
      S3_AXI_ARUSER             => S3_AXI_ARUSER,
      
      S3_AXI_RID                => S3_AXI_RID,
      S3_AXI_RDATA              => S3_AXI_RDATA,
      S3_AXI_RRESP              => S3_AXI_RRESP,
      S3_AXI_RLAST              => S3_AXI_RLAST,
      S3_AXI_RVALID             => S3_AXI_RVALID,
      S3_AXI_RREADY             => S3_AXI_RREADY,
      S3_AXI_RACK               => S3_AXI_RACK,
      
      S3_AXI_ACVALID            => S3_AXI_ACVALID,
      S3_AXI_ACADDR             => S3_AXI_ACADDR,
      S3_AXI_ACSNOOP            => S3_AXI_ACSNOOP,
      S3_AXI_ACPROT             => S3_AXI_ACPROT,
      S3_AXI_ACREADY            => S3_AXI_ACREADY,
      
      S3_AXI_CRVALID            => S3_AXI_CRVALID,
      S3_AXI_CRRESP             => S3_AXI_CRRESP,
      S3_AXI_CRREADY            => S3_AXI_CRREADY,
      
      S3_AXI_CDVALID            => S3_AXI_CDVALID,
      S3_AXI_CDDATA             => S3_AXI_CDDATA,
      S3_AXI_CDLAST             => S3_AXI_CDLAST,
      S3_AXI_CDREADY            => S3_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #4 Slave Signals.
      
      S4_AXI_AWID               => S4_AXI_AWID,
      S4_AXI_AWADDR             => S4_AXI_AWADDR,
      S4_AXI_AWLEN              => S4_AXI_AWLEN,
      S4_AXI_AWSIZE             => S4_AXI_AWSIZE,
      S4_AXI_AWBURST            => S4_AXI_AWBURST,
      S4_AXI_AWLOCK             => S4_AXI_AWLOCK,
      S4_AXI_AWCACHE            => S4_AXI_AWCACHE,
      S4_AXI_AWPROT             => S4_AXI_AWPROT,
      S4_AXI_AWQOS              => S4_AXI_AWQOS,
      S4_AXI_AWVALID            => S4_AXI_AWVALID,
      S4_AXI_AWREADY            => S4_AXI_AWREADY,
      S4_AXI_AWDOMAIN           => S4_AXI_AWDOMAIN,
      S4_AXI_AWSNOOP            => S4_AXI_AWSNOOP,
      S4_AXI_AWBAR              => S4_AXI_AWBAR,
      S4_AXI_AWUSER             => S4_AXI_AWUSER,
      
      S4_AXI_WDATA              => S4_AXI_WDATA,
      S4_AXI_WSTRB              => S4_AXI_WSTRB,
      S4_AXI_WLAST              => S4_AXI_WLAST,
      S4_AXI_WVALID             => S4_AXI_WVALID,
      S4_AXI_WREADY             => S4_AXI_WREADY,
      
      S4_AXI_BRESP              => S4_AXI_BRESP,
      S4_AXI_BID                => S4_AXI_BID,
      S4_AXI_BVALID             => S4_AXI_BVALID,
      S4_AXI_BREADY             => S4_AXI_BREADY,
      S4_AXI_WACK               => S4_AXI_WACK,
      
      S4_AXI_ARID               => S4_AXI_ARID,
      S4_AXI_ARADDR             => S4_AXI_ARADDR,
      S4_AXI_ARLEN              => S4_AXI_ARLEN,
      S4_AXI_ARSIZE             => S4_AXI_ARSIZE,
      S4_AXI_ARBURST            => S4_AXI_ARBURST,
      S4_AXI_ARLOCK             => S4_AXI_ARLOCK,
      S4_AXI_ARCACHE            => S4_AXI_ARCACHE,
      S4_AXI_ARPROT             => S4_AXI_ARPROT,
      S4_AXI_ARQOS              => S4_AXI_ARQOS,
      S4_AXI_ARVALID            => S4_AXI_ARVALID,
      S4_AXI_ARREADY            => S4_AXI_ARREADY,
      S4_AXI_ARDOMAIN           => S4_AXI_ARDOMAIN,
      S4_AXI_ARSNOOP            => S4_AXI_ARSNOOP,
      S4_AXI_ARBAR              => S4_AXI_ARBAR,
      S4_AXI_ARUSER             => S4_AXI_ARUSER,
      
      S4_AXI_RID                => S4_AXI_RID,
      S4_AXI_RDATA              => S4_AXI_RDATA,
      S4_AXI_RRESP              => S4_AXI_RRESP,
      S4_AXI_RLAST              => S4_AXI_RLAST,
      S4_AXI_RVALID             => S4_AXI_RVALID,
      S4_AXI_RREADY             => S4_AXI_RREADY,
      S4_AXI_RACK               => S4_AXI_RACK,
      
      S4_AXI_ACVALID            => S4_AXI_ACVALID,
      S4_AXI_ACADDR             => S4_AXI_ACADDR,
      S4_AXI_ACSNOOP            => S4_AXI_ACSNOOP,
      S4_AXI_ACPROT             => S4_AXI_ACPROT,
      S4_AXI_ACREADY            => S4_AXI_ACREADY,
      
      S4_AXI_CRVALID            => S4_AXI_CRVALID,
      S4_AXI_CRRESP             => S4_AXI_CRRESP,
      S4_AXI_CRREADY            => S4_AXI_CRREADY,
      
      S4_AXI_CDVALID            => S4_AXI_CDVALID,
      S4_AXI_CDDATA             => S4_AXI_CDDATA,
      S4_AXI_CDLAST             => S4_AXI_CDLAST,
      S4_AXI_CDREADY            => S4_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #5 Slave Signals.
      
      S5_AXI_AWID               => S5_AXI_AWID,
      S5_AXI_AWADDR             => S5_AXI_AWADDR,
      S5_AXI_AWLEN              => S5_AXI_AWLEN,
      S5_AXI_AWSIZE             => S5_AXI_AWSIZE,
      S5_AXI_AWBURST            => S5_AXI_AWBURST,
      S5_AXI_AWLOCK             => S5_AXI_AWLOCK,
      S5_AXI_AWCACHE            => S5_AXI_AWCACHE,
      S5_AXI_AWPROT             => S5_AXI_AWPROT,
      S5_AXI_AWQOS              => S5_AXI_AWQOS,
      S5_AXI_AWVALID            => S5_AXI_AWVALID,
      S5_AXI_AWREADY            => S5_AXI_AWREADY,
      S5_AXI_AWDOMAIN           => S5_AXI_AWDOMAIN,
      S5_AXI_AWSNOOP            => S5_AXI_AWSNOOP,
      S5_AXI_AWBAR              => S5_AXI_AWBAR,
      S5_AXI_AWUSER             => S5_AXI_AWUSER,
      
      S5_AXI_WDATA              => S5_AXI_WDATA,
      S5_AXI_WSTRB              => S5_AXI_WSTRB,
      S5_AXI_WLAST              => S5_AXI_WLAST,
      S5_AXI_WVALID             => S5_AXI_WVALID,
      S5_AXI_WREADY             => S5_AXI_WREADY,
      
      S5_AXI_BRESP              => S5_AXI_BRESP,
      S5_AXI_BID                => S5_AXI_BID,
      S5_AXI_BVALID             => S5_AXI_BVALID,
      S5_AXI_BREADY             => S5_AXI_BREADY,
      S5_AXI_WACK               => S5_AXI_WACK,
      
      S5_AXI_ARID               => S5_AXI_ARID,
      S5_AXI_ARADDR             => S5_AXI_ARADDR,
      S5_AXI_ARLEN              => S5_AXI_ARLEN,
      S5_AXI_ARSIZE             => S5_AXI_ARSIZE,
      S5_AXI_ARBURST            => S5_AXI_ARBURST,
      S5_AXI_ARLOCK             => S5_AXI_ARLOCK,
      S5_AXI_ARCACHE            => S5_AXI_ARCACHE,
      S5_AXI_ARPROT             => S5_AXI_ARPROT,
      S5_AXI_ARQOS              => S5_AXI_ARQOS,
      S5_AXI_ARVALID            => S5_AXI_ARVALID,
      S5_AXI_ARREADY            => S5_AXI_ARREADY,
      S5_AXI_ARDOMAIN           => S5_AXI_ARDOMAIN,
      S5_AXI_ARSNOOP            => S5_AXI_ARSNOOP,
      S5_AXI_ARBAR              => S5_AXI_ARBAR,
      S5_AXI_ARUSER             => S5_AXI_ARUSER,
      
      S5_AXI_RID                => S5_AXI_RID,
      S5_AXI_RDATA              => S5_AXI_RDATA,
      S5_AXI_RRESP              => S5_AXI_RRESP,
      S5_AXI_RLAST              => S5_AXI_RLAST,
      S5_AXI_RVALID             => S5_AXI_RVALID,
      S5_AXI_RREADY             => S5_AXI_RREADY,
      S5_AXI_RACK               => S5_AXI_RACK,
      
      S5_AXI_ACVALID            => S5_AXI_ACVALID,
      S5_AXI_ACADDR             => S5_AXI_ACADDR,
      S5_AXI_ACSNOOP            => S5_AXI_ACSNOOP,
      S5_AXI_ACPROT             => S5_AXI_ACPROT,
      S5_AXI_ACREADY            => S5_AXI_ACREADY,
      
      S5_AXI_CRVALID            => S5_AXI_CRVALID,
      S5_AXI_CRRESP             => S5_AXI_CRRESP,
      S5_AXI_CRREADY            => S5_AXI_CRREADY,
      
      S5_AXI_CDVALID            => S5_AXI_CDVALID,
      S5_AXI_CDDATA             => S5_AXI_CDDATA,
      S5_AXI_CDLAST             => S5_AXI_CDLAST,
      S5_AXI_CDREADY            => S5_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #6 Slave Signals.
      
      S6_AXI_AWID               => S6_AXI_AWID,
      S6_AXI_AWADDR             => S6_AXI_AWADDR,
      S6_AXI_AWLEN              => S6_AXI_AWLEN,
      S6_AXI_AWSIZE             => S6_AXI_AWSIZE,
      S6_AXI_AWBURST            => S6_AXI_AWBURST,
      S6_AXI_AWLOCK             => S6_AXI_AWLOCK,
      S6_AXI_AWCACHE            => S6_AXI_AWCACHE,
      S6_AXI_AWPROT             => S6_AXI_AWPROT,
      S6_AXI_AWQOS              => S6_AXI_AWQOS,
      S6_AXI_AWVALID            => S6_AXI_AWVALID,
      S6_AXI_AWREADY            => S6_AXI_AWREADY,
      S6_AXI_AWDOMAIN           => S6_AXI_AWDOMAIN,
      S6_AXI_AWSNOOP            => S6_AXI_AWSNOOP,
      S6_AXI_AWBAR              => S6_AXI_AWBAR,
      S6_AXI_AWUSER             => S6_AXI_AWUSER,
      
      S6_AXI_WDATA              => S6_AXI_WDATA,
      S6_AXI_WSTRB              => S6_AXI_WSTRB,
      S6_AXI_WLAST              => S6_AXI_WLAST,
      S6_AXI_WVALID             => S6_AXI_WVALID,
      S6_AXI_WREADY             => S6_AXI_WREADY,
      
      S6_AXI_BRESP              => S6_AXI_BRESP,
      S6_AXI_BID                => S6_AXI_BID,
      S6_AXI_BVALID             => S6_AXI_BVALID,
      S6_AXI_BREADY             => S6_AXI_BREADY,
      S6_AXI_WACK               => S6_AXI_WACK,
      
      S6_AXI_ARID               => S6_AXI_ARID,
      S6_AXI_ARADDR             => S6_AXI_ARADDR,
      S6_AXI_ARLEN              => S6_AXI_ARLEN,
      S6_AXI_ARSIZE             => S6_AXI_ARSIZE,
      S6_AXI_ARBURST            => S6_AXI_ARBURST,
      S6_AXI_ARLOCK             => S6_AXI_ARLOCK,
      S6_AXI_ARCACHE            => S6_AXI_ARCACHE,
      S6_AXI_ARPROT             => S6_AXI_ARPROT,
      S6_AXI_ARQOS              => S6_AXI_ARQOS,
      S6_AXI_ARVALID            => S6_AXI_ARVALID,
      S6_AXI_ARREADY            => S6_AXI_ARREADY,
      S6_AXI_ARDOMAIN           => S6_AXI_ARDOMAIN,
      S6_AXI_ARSNOOP            => S6_AXI_ARSNOOP,
      S6_AXI_ARBAR              => S6_AXI_ARBAR,
      S6_AXI_ARUSER             => S6_AXI_ARUSER,
      
      S6_AXI_RID                => S6_AXI_RID,
      S6_AXI_RDATA              => S6_AXI_RDATA,
      S6_AXI_RRESP              => S6_AXI_RRESP,
      S6_AXI_RLAST              => S6_AXI_RLAST,
      S6_AXI_RVALID             => S6_AXI_RVALID,
      S6_AXI_RREADY             => S6_AXI_RREADY,
      S6_AXI_RACK               => S6_AXI_RACK,
      
      S6_AXI_ACVALID            => S6_AXI_ACVALID,
      S6_AXI_ACADDR             => S6_AXI_ACADDR,
      S6_AXI_ACSNOOP            => S6_AXI_ACSNOOP,
      S6_AXI_ACPROT             => S6_AXI_ACPROT,
      S6_AXI_ACREADY            => S6_AXI_ACREADY,
      
      S6_AXI_CRVALID            => S6_AXI_CRVALID,
      S6_AXI_CRRESP             => S6_AXI_CRRESP,
      S6_AXI_CRREADY            => S6_AXI_CRREADY,
      
      S6_AXI_CDVALID            => S6_AXI_CDVALID,
      S6_AXI_CDDATA             => S6_AXI_CDDATA,
      S6_AXI_CDLAST             => S6_AXI_CDLAST,
      S6_AXI_CDREADY            => S6_AXI_CDREADY,
      
  
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #7 Slave Signals.
      
      S7_AXI_AWID               => S7_AXI_AWID,
      S7_AXI_AWADDR             => S7_AXI_AWADDR,
      S7_AXI_AWLEN              => S7_AXI_AWLEN,
      S7_AXI_AWSIZE             => S7_AXI_AWSIZE,
      S7_AXI_AWBURST            => S7_AXI_AWBURST,
      S7_AXI_AWLOCK             => S7_AXI_AWLOCK,
      S7_AXI_AWCACHE            => S7_AXI_AWCACHE,
      S7_AXI_AWPROT             => S7_AXI_AWPROT,
      S7_AXI_AWQOS              => S7_AXI_AWQOS,
      S7_AXI_AWVALID            => S7_AXI_AWVALID,
      S7_AXI_AWREADY            => S7_AXI_AWREADY,
      S7_AXI_AWDOMAIN           => S7_AXI_AWDOMAIN,
      S7_AXI_AWSNOOP            => S7_AXI_AWSNOOP,
      S7_AXI_AWBAR              => S7_AXI_AWBAR,
      S7_AXI_AWUSER             => S7_AXI_AWUSER,
      
      S7_AXI_WDATA              => S7_AXI_WDATA,
      S7_AXI_WSTRB              => S7_AXI_WSTRB,
      S7_AXI_WLAST              => S7_AXI_WLAST,
      S7_AXI_WVALID             => S7_AXI_WVALID,
      S7_AXI_WREADY             => S7_AXI_WREADY,
      
      S7_AXI_BRESP              => S7_AXI_BRESP,
      S7_AXI_BID                => S7_AXI_BID,
      S7_AXI_BVALID             => S7_AXI_BVALID,
      S7_AXI_BREADY             => S7_AXI_BREADY,
      S7_AXI_WACK               => S7_AXI_WACK,
      
      S7_AXI_ARID               => S7_AXI_ARID,
      S7_AXI_ARADDR             => S7_AXI_ARADDR,
      S7_AXI_ARLEN              => S7_AXI_ARLEN,
      S7_AXI_ARSIZE             => S7_AXI_ARSIZE,
      S7_AXI_ARBURST            => S7_AXI_ARBURST,
      S7_AXI_ARLOCK             => S7_AXI_ARLOCK,
      S7_AXI_ARCACHE            => S7_AXI_ARCACHE,
      S7_AXI_ARPROT             => S7_AXI_ARPROT,
      S7_AXI_ARQOS              => S7_AXI_ARQOS,
      S7_AXI_ARVALID            => S7_AXI_ARVALID,
      S7_AXI_ARREADY            => S7_AXI_ARREADY,
      S7_AXI_ARDOMAIN           => S7_AXI_ARDOMAIN,
      S7_AXI_ARSNOOP            => S7_AXI_ARSNOOP,
      S7_AXI_ARBAR              => S7_AXI_ARBAR,
      S7_AXI_ARUSER             => S7_AXI_ARUSER,
      
      S7_AXI_RID                => S7_AXI_RID,
      S7_AXI_RDATA              => S7_AXI_RDATA,
      S7_AXI_RRESP              => S7_AXI_RRESP,
      S7_AXI_RLAST              => S7_AXI_RLAST,
      S7_AXI_RVALID             => S7_AXI_RVALID,
      S7_AXI_RREADY             => S7_AXI_RREADY,
      S7_AXI_RACK               => S7_AXI_RACK,
      
      S7_AXI_ACVALID            => S7_AXI_ACVALID,
      S7_AXI_ACADDR             => S7_AXI_ACADDR,
      S7_AXI_ACSNOOP            => S7_AXI_ACSNOOP,
      S7_AXI_ACPROT             => S7_AXI_ACPROT,
      S7_AXI_ACREADY            => S7_AXI_ACREADY,
      
      S7_AXI_CRVALID            => S7_AXI_CRVALID,
      S7_AXI_CRRESP             => S7_AXI_CRRESP,
      S7_AXI_CRREADY            => S7_AXI_CRREADY,
      
      S7_AXI_CDVALID            => S7_AXI_CDVALID,
      S7_AXI_CDDATA             => S7_AXI_CDDATA,
      S7_AXI_CDLAST             => S7_AXI_CDLAST,
      S7_AXI_CDREADY            => S7_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #8 Slave Signals.
      
      S8_AXI_AWID               => S8_AXI_AWID,
      S8_AXI_AWADDR             => S8_AXI_AWADDR,
      S8_AXI_AWLEN              => S8_AXI_AWLEN,
      S8_AXI_AWSIZE             => S8_AXI_AWSIZE,
      S8_AXI_AWBURST            => S8_AXI_AWBURST,
      S8_AXI_AWLOCK             => S8_AXI_AWLOCK,
      S8_AXI_AWCACHE            => S8_AXI_AWCACHE,
      S8_AXI_AWPROT             => S8_AXI_AWPROT,
      S8_AXI_AWQOS              => S8_AXI_AWQOS,
      S8_AXI_AWVALID            => S8_AXI_AWVALID,
      S8_AXI_AWREADY            => S8_AXI_AWREADY,
      S8_AXI_AWDOMAIN           => S8_AXI_AWDOMAIN,
      S8_AXI_AWSNOOP            => S8_AXI_AWSNOOP,
      S8_AXI_AWBAR              => S8_AXI_AWBAR,
      S8_AXI_AWUSER             => S8_AXI_AWUSER,
      
      S8_AXI_WDATA              => S8_AXI_WDATA,
      S8_AXI_WSTRB              => S8_AXI_WSTRB,
      S8_AXI_WLAST              => S8_AXI_WLAST,
      S8_AXI_WVALID             => S8_AXI_WVALID,
      S8_AXI_WREADY             => S8_AXI_WREADY,
      
      S8_AXI_BRESP              => S8_AXI_BRESP,
      S8_AXI_BID                => S8_AXI_BID,
      S8_AXI_BVALID             => S8_AXI_BVALID,
      S8_AXI_BREADY             => S8_AXI_BREADY,
      S8_AXI_WACK               => S8_AXI_WACK,
      
      S8_AXI_ARID               => S8_AXI_ARID,
      S8_AXI_ARADDR             => S8_AXI_ARADDR,
      S8_AXI_ARLEN              => S8_AXI_ARLEN,
      S8_AXI_ARSIZE             => S8_AXI_ARSIZE,
      S8_AXI_ARBURST            => S8_AXI_ARBURST,
      S8_AXI_ARLOCK             => S8_AXI_ARLOCK,
      S8_AXI_ARCACHE            => S8_AXI_ARCACHE,
      S8_AXI_ARPROT             => S8_AXI_ARPROT,
      S8_AXI_ARQOS              => S8_AXI_ARQOS,
      S8_AXI_ARVALID            => S8_AXI_ARVALID,
      S8_AXI_ARREADY            => S8_AXI_ARREADY,
      S8_AXI_ARDOMAIN           => S8_AXI_ARDOMAIN,
      S8_AXI_ARSNOOP            => S8_AXI_ARSNOOP,
      S8_AXI_ARBAR              => S8_AXI_ARBAR,
      S8_AXI_ARUSER             => S8_AXI_ARUSER,
      
      S8_AXI_RID                => S8_AXI_RID,
      S8_AXI_RDATA              => S8_AXI_RDATA,
      S8_AXI_RRESP              => S8_AXI_RRESP,
      S8_AXI_RLAST              => S8_AXI_RLAST,
      S8_AXI_RVALID             => S8_AXI_RVALID,
      S8_AXI_RREADY             => S8_AXI_RREADY,
      S8_AXI_RACK               => S8_AXI_RACK,
      
      S8_AXI_ACVALID            => S8_AXI_ACVALID,
      S8_AXI_ACADDR             => S8_AXI_ACADDR,
      S8_AXI_ACSNOOP            => S8_AXI_ACSNOOP,
      S8_AXI_ACPROT             => S8_AXI_ACPROT,
      S8_AXI_ACREADY            => S8_AXI_ACREADY,
      
      S8_AXI_CRVALID            => S8_AXI_CRVALID,
      S8_AXI_CRRESP             => S8_AXI_CRRESP,
      S8_AXI_CRREADY            => S8_AXI_CRREADY,
      
      S8_AXI_CDVALID            => S8_AXI_CDVALID,
      S8_AXI_CDDATA             => S8_AXI_CDDATA,
      S8_AXI_CDLAST             => S8_AXI_CDLAST,
      S8_AXI_CDREADY            => S8_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #9 Slave Signals.
      
      S9_AXI_AWID               => S9_AXI_AWID,
      S9_AXI_AWADDR             => S9_AXI_AWADDR,
      S9_AXI_AWLEN              => S9_AXI_AWLEN,
      S9_AXI_AWSIZE             => S9_AXI_AWSIZE,
      S9_AXI_AWBURST            => S9_AXI_AWBURST,
      S9_AXI_AWLOCK             => S9_AXI_AWLOCK,
      S9_AXI_AWCACHE            => S9_AXI_AWCACHE,
      S9_AXI_AWPROT             => S9_AXI_AWPROT,
      S9_AXI_AWQOS              => S9_AXI_AWQOS,
      S9_AXI_AWVALID            => S9_AXI_AWVALID,
      S9_AXI_AWREADY            => S9_AXI_AWREADY,
      S9_AXI_AWDOMAIN           => S9_AXI_AWDOMAIN,
      S9_AXI_AWSNOOP            => S9_AXI_AWSNOOP,
      S9_AXI_AWBAR              => S9_AXI_AWBAR,
      S9_AXI_AWUSER             => S9_AXI_AWUSER,
      
      S9_AXI_WDATA              => S9_AXI_WDATA,
      S9_AXI_WSTRB              => S9_AXI_WSTRB,
      S9_AXI_WLAST              => S9_AXI_WLAST,
      S9_AXI_WVALID             => S9_AXI_WVALID,
      S9_AXI_WREADY             => S9_AXI_WREADY,
      
      S9_AXI_BRESP              => S9_AXI_BRESP,
      S9_AXI_BID                => S9_AXI_BID,
      S9_AXI_BVALID             => S9_AXI_BVALID,
      S9_AXI_BREADY             => S9_AXI_BREADY,
      S9_AXI_WACK               => S9_AXI_WACK,
      
      S9_AXI_ARID               => S9_AXI_ARID,
      S9_AXI_ARADDR             => S9_AXI_ARADDR,
      S9_AXI_ARLEN              => S9_AXI_ARLEN,
      S9_AXI_ARSIZE             => S9_AXI_ARSIZE,
      S9_AXI_ARBURST            => S9_AXI_ARBURST,
      S9_AXI_ARLOCK             => S9_AXI_ARLOCK,
      S9_AXI_ARCACHE            => S9_AXI_ARCACHE,
      S9_AXI_ARPROT             => S9_AXI_ARPROT,
      S9_AXI_ARQOS              => S9_AXI_ARQOS,
      S9_AXI_ARVALID            => S9_AXI_ARVALID,
      S9_AXI_ARREADY            => S9_AXI_ARREADY,
      S9_AXI_ARDOMAIN           => S9_AXI_ARDOMAIN,
      S9_AXI_ARSNOOP            => S9_AXI_ARSNOOP,
      S9_AXI_ARBAR              => S9_AXI_ARBAR,
      S9_AXI_ARUSER             => S9_AXI_ARUSER,
      
      S9_AXI_RID                => S9_AXI_RID,
      S9_AXI_RDATA              => S9_AXI_RDATA,
      S9_AXI_RRESP              => S9_AXI_RRESP,
      S9_AXI_RLAST              => S9_AXI_RLAST,
      S9_AXI_RVALID             => S9_AXI_RVALID,
      S9_AXI_RREADY             => S9_AXI_RREADY,
      S9_AXI_RACK               => S9_AXI_RACK,
      
      S9_AXI_ACVALID            => S9_AXI_ACVALID,
      S9_AXI_ACADDR             => S9_AXI_ACADDR,
      S9_AXI_ACSNOOP            => S9_AXI_ACSNOOP,
      S9_AXI_ACPROT             => S9_AXI_ACPROT,
      S9_AXI_ACREADY            => S9_AXI_ACREADY,
      
      S9_AXI_CRVALID            => S9_AXI_CRVALID,
      S9_AXI_CRRESP             => S9_AXI_CRRESP,
      S9_AXI_CRREADY            => S9_AXI_CRREADY,
      
      S9_AXI_CDVALID            => S9_AXI_CDVALID,
      S9_AXI_CDDATA             => S9_AXI_CDDATA,
      S9_AXI_CDLAST             => S9_AXI_CDLAST,
      S9_AXI_CDREADY            => S9_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #10 Slave Signals.
      
      S10_AXI_AWID               => S10_AXI_AWID,
      S10_AXI_AWADDR             => S10_AXI_AWADDR,
      S10_AXI_AWLEN              => S10_AXI_AWLEN,
      S10_AXI_AWSIZE             => S10_AXI_AWSIZE,
      S10_AXI_AWBURST            => S10_AXI_AWBURST,
      S10_AXI_AWLOCK             => S10_AXI_AWLOCK,
      S10_AXI_AWCACHE            => S10_AXI_AWCACHE,
      S10_AXI_AWPROT             => S10_AXI_AWPROT,
      S10_AXI_AWQOS              => S10_AXI_AWQOS,
      S10_AXI_AWVALID            => S10_AXI_AWVALID,
      S10_AXI_AWREADY            => S10_AXI_AWREADY,
      S10_AXI_AWDOMAIN           => S10_AXI_AWDOMAIN,
      S10_AXI_AWSNOOP            => S10_AXI_AWSNOOP,
      S10_AXI_AWBAR              => S10_AXI_AWBAR,
      S10_AXI_AWUSER             => S10_AXI_AWUSER,
      
      S10_AXI_WDATA              => S10_AXI_WDATA,
      S10_AXI_WSTRB              => S10_AXI_WSTRB,
      S10_AXI_WLAST              => S10_AXI_WLAST,
      S10_AXI_WVALID             => S10_AXI_WVALID,
      S10_AXI_WREADY             => S10_AXI_WREADY,
      
      S10_AXI_BRESP              => S10_AXI_BRESP,
      S10_AXI_BID                => S10_AXI_BID,
      S10_AXI_BVALID             => S10_AXI_BVALID,
      S10_AXI_BREADY             => S10_AXI_BREADY,
      S10_AXI_WACK               => S10_AXI_WACK,
      
      S10_AXI_ARID               => S10_AXI_ARID,
      S10_AXI_ARADDR             => S10_AXI_ARADDR,
      S10_AXI_ARLEN              => S10_AXI_ARLEN,
      S10_AXI_ARSIZE             => S10_AXI_ARSIZE,
      S10_AXI_ARBURST            => S10_AXI_ARBURST,
      S10_AXI_ARLOCK             => S10_AXI_ARLOCK,
      S10_AXI_ARCACHE            => S10_AXI_ARCACHE,
      S10_AXI_ARPROT             => S10_AXI_ARPROT,
      S10_AXI_ARQOS              => S10_AXI_ARQOS,
      S10_AXI_ARVALID            => S10_AXI_ARVALID,
      S10_AXI_ARREADY            => S10_AXI_ARREADY,
      S10_AXI_ARDOMAIN           => S10_AXI_ARDOMAIN,
      S10_AXI_ARSNOOP            => S10_AXI_ARSNOOP,
      S10_AXI_ARBAR              => S10_AXI_ARBAR,
      S10_AXI_ARUSER             => S10_AXI_ARUSER,
      
      S10_AXI_RID                => S10_AXI_RID,
      S10_AXI_RDATA              => S10_AXI_RDATA,
      S10_AXI_RRESP              => S10_AXI_RRESP,
      S10_AXI_RLAST              => S10_AXI_RLAST,
      S10_AXI_RVALID             => S10_AXI_RVALID,
      S10_AXI_RREADY             => S10_AXI_RREADY,
      S10_AXI_RACK               => S10_AXI_RACK,
      
      S10_AXI_ACVALID            => S10_AXI_ACVALID,
      S10_AXI_ACADDR             => S10_AXI_ACADDR,
      S10_AXI_ACSNOOP            => S10_AXI_ACSNOOP,
      S10_AXI_ACPROT             => S10_AXI_ACPROT,
      S10_AXI_ACREADY            => S10_AXI_ACREADY,
      
      S10_AXI_CRVALID            => S10_AXI_CRVALID,
      S10_AXI_CRRESP             => S10_AXI_CRRESP,
      S10_AXI_CRREADY            => S10_AXI_CRREADY,
      
      S10_AXI_CDVALID            => S10_AXI_CDVALID,
      S10_AXI_CDDATA             => S10_AXI_CDDATA,
      S10_AXI_CDLAST             => S10_AXI_CDLAST,
      S10_AXI_CDREADY            => S10_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #11 Slave Signals.
      
      S11_AXI_AWID               => S11_AXI_AWID,
      S11_AXI_AWADDR             => S11_AXI_AWADDR,
      S11_AXI_AWLEN              => S11_AXI_AWLEN,
      S11_AXI_AWSIZE             => S11_AXI_AWSIZE,
      S11_AXI_AWBURST            => S11_AXI_AWBURST,
      S11_AXI_AWLOCK             => S11_AXI_AWLOCK,
      S11_AXI_AWCACHE            => S11_AXI_AWCACHE,
      S11_AXI_AWPROT             => S11_AXI_AWPROT,
      S11_AXI_AWQOS              => S11_AXI_AWQOS,
      S11_AXI_AWVALID            => S11_AXI_AWVALID,
      S11_AXI_AWREADY            => S11_AXI_AWREADY,
      S11_AXI_AWDOMAIN           => S11_AXI_AWDOMAIN,
      S11_AXI_AWSNOOP            => S11_AXI_AWSNOOP,
      S11_AXI_AWBAR              => S11_AXI_AWBAR,
      S11_AXI_AWUSER             => S11_AXI_AWUSER,
      
      S11_AXI_WDATA              => S11_AXI_WDATA,
      S11_AXI_WSTRB              => S11_AXI_WSTRB,
      S11_AXI_WLAST              => S11_AXI_WLAST,
      S11_AXI_WVALID             => S11_AXI_WVALID,
      S11_AXI_WREADY             => S11_AXI_WREADY,
      
      S11_AXI_BRESP              => S11_AXI_BRESP,
      S11_AXI_BID                => S11_AXI_BID,
      S11_AXI_BVALID             => S11_AXI_BVALID,
      S11_AXI_BREADY             => S11_AXI_BREADY,
      S11_AXI_WACK               => S11_AXI_WACK,
      
      S11_AXI_ARID               => S11_AXI_ARID,
      S11_AXI_ARADDR             => S11_AXI_ARADDR,
      S11_AXI_ARLEN              => S11_AXI_ARLEN,
      S11_AXI_ARSIZE             => S11_AXI_ARSIZE,
      S11_AXI_ARBURST            => S11_AXI_ARBURST,
      S11_AXI_ARLOCK             => S11_AXI_ARLOCK,
      S11_AXI_ARCACHE            => S11_AXI_ARCACHE,
      S11_AXI_ARPROT             => S11_AXI_ARPROT,
      S11_AXI_ARQOS              => S11_AXI_ARQOS,
      S11_AXI_ARVALID            => S11_AXI_ARVALID,
      S11_AXI_ARREADY            => S11_AXI_ARREADY,
      S11_AXI_ARDOMAIN           => S11_AXI_ARDOMAIN,
      S11_AXI_ARSNOOP            => S11_AXI_ARSNOOP,
      S11_AXI_ARBAR              => S11_AXI_ARBAR,
      S11_AXI_ARUSER             => S11_AXI_ARUSER,
      
      S11_AXI_RID                => S11_AXI_RID,
      S11_AXI_RDATA              => S11_AXI_RDATA,
      S11_AXI_RRESP              => S11_AXI_RRESP,
      S11_AXI_RLAST              => S11_AXI_RLAST,
      S11_AXI_RVALID             => S11_AXI_RVALID,
      S11_AXI_RREADY             => S11_AXI_RREADY,
      S11_AXI_RACK               => S11_AXI_RACK,
      
      S11_AXI_ACVALID            => S11_AXI_ACVALID,
      S11_AXI_ACADDR             => S11_AXI_ACADDR,
      S11_AXI_ACSNOOP            => S11_AXI_ACSNOOP,
      S11_AXI_ACPROT             => S11_AXI_ACPROT,
      S11_AXI_ACREADY            => S11_AXI_ACREADY,
      
      S11_AXI_CRVALID            => S11_AXI_CRVALID,
      S11_AXI_CRRESP             => S11_AXI_CRRESP,
      S11_AXI_CRREADY            => S11_AXI_CRREADY,
      
      S11_AXI_CDVALID            => S11_AXI_CDVALID,
      S11_AXI_CDDATA             => S11_AXI_CDDATA,
      S11_AXI_CDLAST             => S11_AXI_CDLAST,
      S11_AXI_CDREADY            => S11_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #12 Slave Signals.
      
      S12_AXI_AWID               => S12_AXI_AWID,
      S12_AXI_AWADDR             => S12_AXI_AWADDR,
      S12_AXI_AWLEN              => S12_AXI_AWLEN,
      S12_AXI_AWSIZE             => S12_AXI_AWSIZE,
      S12_AXI_AWBURST            => S12_AXI_AWBURST,
      S12_AXI_AWLOCK             => S12_AXI_AWLOCK,
      S12_AXI_AWCACHE            => S12_AXI_AWCACHE,
      S12_AXI_AWPROT             => S12_AXI_AWPROT,
      S12_AXI_AWQOS              => S12_AXI_AWQOS,
      S12_AXI_AWVALID            => S12_AXI_AWVALID,
      S12_AXI_AWREADY            => S12_AXI_AWREADY,
      S12_AXI_AWDOMAIN           => S12_AXI_AWDOMAIN,
      S12_AXI_AWSNOOP            => S12_AXI_AWSNOOP,
      S12_AXI_AWBAR              => S12_AXI_AWBAR,
      S12_AXI_AWUSER             => S12_AXI_AWUSER,
      
      S12_AXI_WDATA              => S12_AXI_WDATA,
      S12_AXI_WSTRB              => S12_AXI_WSTRB,
      S12_AXI_WLAST              => S12_AXI_WLAST,
      S12_AXI_WVALID             => S12_AXI_WVALID,
      S12_AXI_WREADY             => S12_AXI_WREADY,
      
      S12_AXI_BRESP              => S12_AXI_BRESP,
      S12_AXI_BID                => S12_AXI_BID,
      S12_AXI_BVALID             => S12_AXI_BVALID,
      S12_AXI_BREADY             => S12_AXI_BREADY,
      S12_AXI_WACK               => S12_AXI_WACK,
      
      S12_AXI_ARID               => S12_AXI_ARID,
      S12_AXI_ARADDR             => S12_AXI_ARADDR,
      S12_AXI_ARLEN              => S12_AXI_ARLEN,
      S12_AXI_ARSIZE             => S12_AXI_ARSIZE,
      S12_AXI_ARBURST            => S12_AXI_ARBURST,
      S12_AXI_ARLOCK             => S12_AXI_ARLOCK,
      S12_AXI_ARCACHE            => S12_AXI_ARCACHE,
      S12_AXI_ARPROT             => S12_AXI_ARPROT,
      S12_AXI_ARQOS              => S12_AXI_ARQOS,
      S12_AXI_ARVALID            => S12_AXI_ARVALID,
      S12_AXI_ARREADY            => S12_AXI_ARREADY,
      S12_AXI_ARDOMAIN           => S12_AXI_ARDOMAIN,
      S12_AXI_ARSNOOP            => S12_AXI_ARSNOOP,
      S12_AXI_ARBAR              => S12_AXI_ARBAR,
      S12_AXI_ARUSER             => S12_AXI_ARUSER,
      
      S12_AXI_RID                => S12_AXI_RID,
      S12_AXI_RDATA              => S12_AXI_RDATA,
      S12_AXI_RRESP              => S12_AXI_RRESP,
      S12_AXI_RLAST              => S12_AXI_RLAST,
      S12_AXI_RVALID             => S12_AXI_RVALID,
      S12_AXI_RREADY             => S12_AXI_RREADY,
      S12_AXI_RACK               => S12_AXI_RACK,
      
      S12_AXI_ACVALID            => S12_AXI_ACVALID,
      S12_AXI_ACADDR             => S12_AXI_ACADDR,
      S12_AXI_ACSNOOP            => S12_AXI_ACSNOOP,
      S12_AXI_ACPROT             => S12_AXI_ACPROT,
      S12_AXI_ACREADY            => S12_AXI_ACREADY,
      
      S12_AXI_CRVALID            => S12_AXI_CRVALID,
      S12_AXI_CRRESP             => S12_AXI_CRRESP,
      S12_AXI_CRREADY            => S12_AXI_CRREADY,
      
      S12_AXI_CDVALID            => S12_AXI_CDVALID,
      S12_AXI_CDDATA             => S12_AXI_CDDATA,
      S12_AXI_CDLAST             => S12_AXI_CDLAST,
      S12_AXI_CDREADY            => S12_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #13 Slave Signals.
      
      S13_AXI_AWID               => S13_AXI_AWID,
      S13_AXI_AWADDR             => S13_AXI_AWADDR,
      S13_AXI_AWLEN              => S13_AXI_AWLEN,
      S13_AXI_AWSIZE             => S13_AXI_AWSIZE,
      S13_AXI_AWBURST            => S13_AXI_AWBURST,
      S13_AXI_AWLOCK             => S13_AXI_AWLOCK,
      S13_AXI_AWCACHE            => S13_AXI_AWCACHE,
      S13_AXI_AWPROT             => S13_AXI_AWPROT,
      S13_AXI_AWQOS              => S13_AXI_AWQOS,
      S13_AXI_AWVALID            => S13_AXI_AWVALID,
      S13_AXI_AWREADY            => S13_AXI_AWREADY,
      S13_AXI_AWDOMAIN           => S13_AXI_AWDOMAIN,
      S13_AXI_AWSNOOP            => S13_AXI_AWSNOOP,
      S13_AXI_AWBAR              => S13_AXI_AWBAR,
      S13_AXI_AWUSER             => S13_AXI_AWUSER,
      
      S13_AXI_WDATA              => S13_AXI_WDATA,
      S13_AXI_WSTRB              => S13_AXI_WSTRB,
      S13_AXI_WLAST              => S13_AXI_WLAST,
      S13_AXI_WVALID             => S13_AXI_WVALID,
      S13_AXI_WREADY             => S13_AXI_WREADY,
      
      S13_AXI_BRESP              => S13_AXI_BRESP,
      S13_AXI_BID                => S13_AXI_BID,
      S13_AXI_BVALID             => S13_AXI_BVALID,
      S13_AXI_BREADY             => S13_AXI_BREADY,
      S13_AXI_WACK               => S13_AXI_WACK,
      
      S13_AXI_ARID               => S13_AXI_ARID,
      S13_AXI_ARADDR             => S13_AXI_ARADDR,
      S13_AXI_ARLEN              => S13_AXI_ARLEN,
      S13_AXI_ARSIZE             => S13_AXI_ARSIZE,
      S13_AXI_ARBURST            => S13_AXI_ARBURST,
      S13_AXI_ARLOCK             => S13_AXI_ARLOCK,
      S13_AXI_ARCACHE            => S13_AXI_ARCACHE,
      S13_AXI_ARPROT             => S13_AXI_ARPROT,
      S13_AXI_ARQOS              => S13_AXI_ARQOS,
      S13_AXI_ARVALID            => S13_AXI_ARVALID,
      S13_AXI_ARREADY            => S13_AXI_ARREADY,
      S13_AXI_ARDOMAIN           => S13_AXI_ARDOMAIN,
      S13_AXI_ARSNOOP            => S13_AXI_ARSNOOP,
      S13_AXI_ARBAR              => S13_AXI_ARBAR,
      S13_AXI_ARUSER             => S13_AXI_ARUSER,
      
      S13_AXI_RID                => S13_AXI_RID,
      S13_AXI_RDATA              => S13_AXI_RDATA,
      S13_AXI_RRESP              => S13_AXI_RRESP,
      S13_AXI_RLAST              => S13_AXI_RLAST,
      S13_AXI_RVALID             => S13_AXI_RVALID,
      S13_AXI_RREADY             => S13_AXI_RREADY,
      S13_AXI_RACK               => S13_AXI_RACK,
      
      S13_AXI_ACVALID            => S13_AXI_ACVALID,
      S13_AXI_ACADDR             => S13_AXI_ACADDR,
      S13_AXI_ACSNOOP            => S13_AXI_ACSNOOP,
      S13_AXI_ACPROT             => S13_AXI_ACPROT,
      S13_AXI_ACREADY            => S13_AXI_ACREADY,
      
      S13_AXI_CRVALID            => S13_AXI_CRVALID,
      S13_AXI_CRRESP             => S13_AXI_CRRESP,
      S13_AXI_CRREADY            => S13_AXI_CRREADY,
      
      S13_AXI_CDVALID            => S13_AXI_CDVALID,
      S13_AXI_CDDATA             => S13_AXI_CDDATA,
      S13_AXI_CDLAST             => S13_AXI_CDLAST,
      S13_AXI_CDREADY            => S13_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #14 Slave Signals.
      
      S14_AXI_AWID               => S14_AXI_AWID,
      S14_AXI_AWADDR             => S14_AXI_AWADDR,
      S14_AXI_AWLEN              => S14_AXI_AWLEN,
      S14_AXI_AWSIZE             => S14_AXI_AWSIZE,
      S14_AXI_AWBURST            => S14_AXI_AWBURST,
      S14_AXI_AWLOCK             => S14_AXI_AWLOCK,
      S14_AXI_AWCACHE            => S14_AXI_AWCACHE,
      S14_AXI_AWPROT             => S14_AXI_AWPROT,
      S14_AXI_AWQOS              => S14_AXI_AWQOS,
      S14_AXI_AWVALID            => S14_AXI_AWVALID,
      S14_AXI_AWREADY            => S14_AXI_AWREADY,
      S14_AXI_AWDOMAIN           => S14_AXI_AWDOMAIN,
      S14_AXI_AWSNOOP            => S14_AXI_AWSNOOP,
      S14_AXI_AWBAR              => S14_AXI_AWBAR,
      S14_AXI_AWUSER             => S14_AXI_AWUSER,
      
      S14_AXI_WDATA              => S14_AXI_WDATA,
      S14_AXI_WSTRB              => S14_AXI_WSTRB,
      S14_AXI_WLAST              => S14_AXI_WLAST,
      S14_AXI_WVALID             => S14_AXI_WVALID,
      S14_AXI_WREADY             => S14_AXI_WREADY,
      
      S14_AXI_BRESP              => S14_AXI_BRESP,
      S14_AXI_BID                => S14_AXI_BID,
      S14_AXI_BVALID             => S14_AXI_BVALID,
      S14_AXI_BREADY             => S14_AXI_BREADY,
      S14_AXI_WACK               => S14_AXI_WACK,
      
      S14_AXI_ARID               => S14_AXI_ARID,
      S14_AXI_ARADDR             => S14_AXI_ARADDR,
      S14_AXI_ARLEN              => S14_AXI_ARLEN,
      S14_AXI_ARSIZE             => S14_AXI_ARSIZE,
      S14_AXI_ARBURST            => S14_AXI_ARBURST,
      S14_AXI_ARLOCK             => S14_AXI_ARLOCK,
      S14_AXI_ARCACHE            => S14_AXI_ARCACHE,
      S14_AXI_ARPROT             => S14_AXI_ARPROT,
      S14_AXI_ARQOS              => S14_AXI_ARQOS,
      S14_AXI_ARVALID            => S14_AXI_ARVALID,
      S14_AXI_ARREADY            => S14_AXI_ARREADY,
      S14_AXI_ARDOMAIN           => S14_AXI_ARDOMAIN,
      S14_AXI_ARSNOOP            => S14_AXI_ARSNOOP,
      S14_AXI_ARBAR              => S14_AXI_ARBAR,
      S14_AXI_ARUSER             => S14_AXI_ARUSER,
      
      S14_AXI_RID                => S14_AXI_RID,
      S14_AXI_RDATA              => S14_AXI_RDATA,
      S14_AXI_RRESP              => S14_AXI_RRESP,
      S14_AXI_RLAST              => S14_AXI_RLAST,
      S14_AXI_RVALID             => S14_AXI_RVALID,
      S14_AXI_RREADY             => S14_AXI_RREADY,
      S14_AXI_RACK               => S14_AXI_RACK,
      
      S14_AXI_ACVALID            => S14_AXI_ACVALID,
      S14_AXI_ACADDR             => S14_AXI_ACADDR,
      S14_AXI_ACSNOOP            => S14_AXI_ACSNOOP,
      S14_AXI_ACPROT             => S14_AXI_ACPROT,
      S14_AXI_ACREADY            => S14_AXI_ACREADY,
      
      S14_AXI_CRVALID            => S14_AXI_CRVALID,
      S14_AXI_CRRESP             => S14_AXI_CRRESP,
      S14_AXI_CRREADY            => S14_AXI_CRREADY,
      
      S14_AXI_CDVALID            => S14_AXI_CDVALID,
      S14_AXI_CDDATA             => S14_AXI_CDDATA,
      S14_AXI_CDLAST             => S14_AXI_CDLAST,
      S14_AXI_CDREADY            => S14_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Optimized AXI4/ACE Interface #15 Slave Signals.
      
      S15_AXI_AWID               => S15_AXI_AWID,
      S15_AXI_AWADDR             => S15_AXI_AWADDR,
      S15_AXI_AWLEN              => S15_AXI_AWLEN,
      S15_AXI_AWSIZE             => S15_AXI_AWSIZE,
      S15_AXI_AWBURST            => S15_AXI_AWBURST,
      S15_AXI_AWLOCK             => S15_AXI_AWLOCK,
      S15_AXI_AWCACHE            => S15_AXI_AWCACHE,
      S15_AXI_AWPROT             => S15_AXI_AWPROT,
      S15_AXI_AWQOS              => S15_AXI_AWQOS,
      S15_AXI_AWVALID            => S15_AXI_AWVALID,
      S15_AXI_AWREADY            => S15_AXI_AWREADY,
      S15_AXI_AWDOMAIN           => S15_AXI_AWDOMAIN,
      S15_AXI_AWSNOOP            => S15_AXI_AWSNOOP,
      S15_AXI_AWBAR              => S15_AXI_AWBAR,
      S15_AXI_AWUSER             => S15_AXI_AWUSER,
      
      S15_AXI_WDATA              => S15_AXI_WDATA,
      S15_AXI_WSTRB              => S15_AXI_WSTRB,
      S15_AXI_WLAST              => S15_AXI_WLAST,
      S15_AXI_WVALID             => S15_AXI_WVALID,
      S15_AXI_WREADY             => S15_AXI_WREADY,
      
      S15_AXI_BRESP              => S15_AXI_BRESP,
      S15_AXI_BID                => S15_AXI_BID,
      S15_AXI_BVALID             => S15_AXI_BVALID,
      S15_AXI_BREADY             => S15_AXI_BREADY,
      S15_AXI_WACK               => S15_AXI_WACK,
      
      S15_AXI_ARID               => S15_AXI_ARID,
      S15_AXI_ARADDR             => S15_AXI_ARADDR,
      S15_AXI_ARLEN              => S15_AXI_ARLEN,
      S15_AXI_ARSIZE             => S15_AXI_ARSIZE,
      S15_AXI_ARBURST            => S15_AXI_ARBURST,
      S15_AXI_ARLOCK             => S15_AXI_ARLOCK,
      S15_AXI_ARCACHE            => S15_AXI_ARCACHE,
      S15_AXI_ARPROT             => S15_AXI_ARPROT,
      S15_AXI_ARQOS              => S15_AXI_ARQOS,
      S15_AXI_ARVALID            => S15_AXI_ARVALID,
      S15_AXI_ARREADY            => S15_AXI_ARREADY,
      S15_AXI_ARDOMAIN           => S15_AXI_ARDOMAIN,
      S15_AXI_ARSNOOP            => S15_AXI_ARSNOOP,
      S15_AXI_ARBAR              => S15_AXI_ARBAR,
      S15_AXI_ARUSER             => S15_AXI_ARUSER,
      
      S15_AXI_RID                => S15_AXI_RID,
      S15_AXI_RDATA              => S15_AXI_RDATA,
      S15_AXI_RRESP              => S15_AXI_RRESP,
      S15_AXI_RLAST              => S15_AXI_RLAST,
      S15_AXI_RVALID             => S15_AXI_RVALID,
      S15_AXI_RREADY             => S15_AXI_RREADY,
      S15_AXI_RACK               => S15_AXI_RACK,
      
      S15_AXI_ACVALID            => S15_AXI_ACVALID,
      S15_AXI_ACADDR             => S15_AXI_ACADDR,
      S15_AXI_ACSNOOP            => S15_AXI_ACSNOOP,
      S15_AXI_ACPROT             => S15_AXI_ACPROT,
      S15_AXI_ACREADY            => S15_AXI_ACREADY,
      
      S15_AXI_CRVALID            => S15_AXI_CRVALID,
      S15_AXI_CRRESP             => S15_AXI_CRRESP,
      S15_AXI_CRREADY            => S15_AXI_CRREADY,
      
      S15_AXI_CDVALID            => S15_AXI_CDVALID,
      S15_AXI_CDDATA             => S15_AXI_CDDATA,
      S15_AXI_CDLAST             => S15_AXI_CDLAST,
      S15_AXI_CDREADY            => S15_AXI_CDREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #0 Slave Signals.
      
      S0_AXI_GEN_AWID           => S0_AXI_GEN_AWID,
      S0_AXI_GEN_AWADDR         => S0_AXI_GEN_AWADDR,
      S0_AXI_GEN_AWLEN          => S0_AXI_GEN_AWLEN,
      S0_AXI_GEN_AWSIZE         => S0_AXI_GEN_AWSIZE,
      S0_AXI_GEN_AWBURST        => S0_AXI_GEN_AWBURST,
      S0_AXI_GEN_AWLOCK         => S0_AXI_GEN_AWLOCK,
      S0_AXI_GEN_AWCACHE        => S0_AXI_GEN_AWCACHE,
      S0_AXI_GEN_AWPROT         => S0_AXI_GEN_AWPROT,
      S0_AXI_GEN_AWQOS          => S0_AXI_GEN_AWQOS,
      S0_AXI_GEN_AWVALID        => S0_AXI_GEN_AWVALID,
      S0_AXI_GEN_AWREADY        => S0_AXI_GEN_AWREADY,
      S0_AXI_GEN_AWUSER         => S0_AXI_GEN_AWUSER,
      
      S0_AXI_GEN_WDATA          => S0_AXI_GEN_WDATA,
      S0_AXI_GEN_WSTRB          => S0_AXI_GEN_WSTRB,
      S0_AXI_GEN_WLAST          => S0_AXI_GEN_WLAST,
      S0_AXI_GEN_WVALID         => S0_AXI_GEN_WVALID,
      S0_AXI_GEN_WREADY         => S0_AXI_GEN_WREADY,
      
      S0_AXI_GEN_BRESP          => S0_AXI_GEN_BRESP,
      S0_AXI_GEN_BID            => S0_AXI_GEN_BID,
      S0_AXI_GEN_BVALID         => S0_AXI_GEN_BVALID,
      S0_AXI_GEN_BREADY         => S0_AXI_GEN_BREADY,
      
      S0_AXI_GEN_ARID           => S0_AXI_GEN_ARID,
      S0_AXI_GEN_ARADDR         => S0_AXI_GEN_ARADDR,
      S0_AXI_GEN_ARLEN          => S0_AXI_GEN_ARLEN,
      S0_AXI_GEN_ARSIZE         => S0_AXI_GEN_ARSIZE,
      S0_AXI_GEN_ARBURST        => S0_AXI_GEN_ARBURST,
      S0_AXI_GEN_ARLOCK         => S0_AXI_GEN_ARLOCK,
      S0_AXI_GEN_ARCACHE        => S0_AXI_GEN_ARCACHE,
      S0_AXI_GEN_ARPROT         => S0_AXI_GEN_ARPROT,
      S0_AXI_GEN_ARQOS          => S0_AXI_GEN_ARQOS,
      S0_AXI_GEN_ARVALID        => S0_AXI_GEN_ARVALID,
      S0_AXI_GEN_ARREADY        => S0_AXI_GEN_ARREADY,
      S0_AXI_GEN_ARUSER         => S0_AXI_GEN_ARUSER,
      
      S0_AXI_GEN_RID            => S0_AXI_GEN_RID,
      S0_AXI_GEN_RDATA          => S0_AXI_GEN_RDATA,
      S0_AXI_GEN_RRESP          => S0_AXI_GEN_RRESP,
      S0_AXI_GEN_RLAST          => S0_AXI_GEN_RLAST,
      S0_AXI_GEN_RVALID         => S0_AXI_GEN_RVALID,
      S0_AXI_GEN_RREADY         => S0_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #1 Slave Signals.
      
      S1_AXI_GEN_AWID           => S1_AXI_GEN_AWID,
      S1_AXI_GEN_AWADDR         => S1_AXI_GEN_AWADDR,
      S1_AXI_GEN_AWLEN          => S1_AXI_GEN_AWLEN,
      S1_AXI_GEN_AWSIZE         => S1_AXI_GEN_AWSIZE,
      S1_AXI_GEN_AWBURST        => S1_AXI_GEN_AWBURST,
      S1_AXI_GEN_AWLOCK         => S1_AXI_GEN_AWLOCK,
      S1_AXI_GEN_AWCACHE        => S1_AXI_GEN_AWCACHE,
      S1_AXI_GEN_AWPROT         => S1_AXI_GEN_AWPROT,
      S1_AXI_GEN_AWQOS          => S1_AXI_GEN_AWQOS,
      S1_AXI_GEN_AWVALID        => S1_AXI_GEN_AWVALID,
      S1_AXI_GEN_AWREADY        => S1_AXI_GEN_AWREADY,
      S1_AXI_GEN_AWUSER         => S1_AXI_GEN_AWUSER,
      
      S1_AXI_GEN_WDATA          => S1_AXI_GEN_WDATA,
      S1_AXI_GEN_WSTRB          => S1_AXI_GEN_WSTRB,
      S1_AXI_GEN_WLAST          => S1_AXI_GEN_WLAST,
      S1_AXI_GEN_WVALID         => S1_AXI_GEN_WVALID,
      S1_AXI_GEN_WREADY         => S1_AXI_GEN_WREADY,
      
      S1_AXI_GEN_BRESP          => S1_AXI_GEN_BRESP,
      S1_AXI_GEN_BID            => S1_AXI_GEN_BID,
      S1_AXI_GEN_BVALID         => S1_AXI_GEN_BVALID,
      S1_AXI_GEN_BREADY         => S1_AXI_GEN_BREADY,
      
      S1_AXI_GEN_ARID           => S1_AXI_GEN_ARID,
      S1_AXI_GEN_ARADDR         => S1_AXI_GEN_ARADDR,
      S1_AXI_GEN_ARLEN          => S1_AXI_GEN_ARLEN,
      S1_AXI_GEN_ARSIZE         => S1_AXI_GEN_ARSIZE,
      S1_AXI_GEN_ARBURST        => S1_AXI_GEN_ARBURST,
      S1_AXI_GEN_ARLOCK         => S1_AXI_GEN_ARLOCK,
      S1_AXI_GEN_ARCACHE        => S1_AXI_GEN_ARCACHE,
      S1_AXI_GEN_ARPROT         => S1_AXI_GEN_ARPROT,
      S1_AXI_GEN_ARQOS          => S1_AXI_GEN_ARQOS,
      S1_AXI_GEN_ARVALID        => S1_AXI_GEN_ARVALID,
      S1_AXI_GEN_ARREADY        => S1_AXI_GEN_ARREADY,
      S1_AXI_GEN_ARUSER         => S1_AXI_GEN_ARUSER,
      
      S1_AXI_GEN_RID            => S1_AXI_GEN_RID,
      S1_AXI_GEN_RDATA          => S1_AXI_GEN_RDATA,
      S1_AXI_GEN_RRESP          => S1_AXI_GEN_RRESP,
      S1_AXI_GEN_RLAST          => S1_AXI_GEN_RLAST,
      S1_AXI_GEN_RVALID         => S1_AXI_GEN_RVALID,
      S1_AXI_GEN_RREADY         => S1_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #2 Slave Signals.
      
      S2_AXI_GEN_AWID           => S2_AXI_GEN_AWID,
      S2_AXI_GEN_AWADDR         => S2_AXI_GEN_AWADDR,
      S2_AXI_GEN_AWLEN          => S2_AXI_GEN_AWLEN,
      S2_AXI_GEN_AWSIZE         => S2_AXI_GEN_AWSIZE,
      S2_AXI_GEN_AWBURST        => S2_AXI_GEN_AWBURST,
      S2_AXI_GEN_AWLOCK         => S2_AXI_GEN_AWLOCK,
      S2_AXI_GEN_AWCACHE        => S2_AXI_GEN_AWCACHE,
      S2_AXI_GEN_AWPROT         => S2_AXI_GEN_AWPROT,
      S2_AXI_GEN_AWQOS          => S2_AXI_GEN_AWQOS,
      S2_AXI_GEN_AWVALID        => S2_AXI_GEN_AWVALID,
      S2_AXI_GEN_AWREADY        => S2_AXI_GEN_AWREADY,
      S2_AXI_GEN_AWUSER         => S2_AXI_GEN_AWUSER,
      
      S2_AXI_GEN_WDATA          => S2_AXI_GEN_WDATA,
      S2_AXI_GEN_WSTRB          => S2_AXI_GEN_WSTRB,
      S2_AXI_GEN_WLAST          => S2_AXI_GEN_WLAST,
      S2_AXI_GEN_WVALID         => S2_AXI_GEN_WVALID,
      S2_AXI_GEN_WREADY         => S2_AXI_GEN_WREADY,
      
      S2_AXI_GEN_BRESP          => S2_AXI_GEN_BRESP,
      S2_AXI_GEN_BID            => S2_AXI_GEN_BID,
      S2_AXI_GEN_BVALID         => S2_AXI_GEN_BVALID,
      S2_AXI_GEN_BREADY         => S2_AXI_GEN_BREADY,
      
      S2_AXI_GEN_ARID           => S2_AXI_GEN_ARID,
      S2_AXI_GEN_ARADDR         => S2_AXI_GEN_ARADDR,
      S2_AXI_GEN_ARLEN          => S2_AXI_GEN_ARLEN,
      S2_AXI_GEN_ARSIZE         => S2_AXI_GEN_ARSIZE,
      S2_AXI_GEN_ARBURST        => S2_AXI_GEN_ARBURST,
      S2_AXI_GEN_ARLOCK         => S2_AXI_GEN_ARLOCK,
      S2_AXI_GEN_ARCACHE        => S2_AXI_GEN_ARCACHE,
      S2_AXI_GEN_ARPROT         => S2_AXI_GEN_ARPROT,
      S2_AXI_GEN_ARQOS          => S2_AXI_GEN_ARQOS,
      S2_AXI_GEN_ARVALID        => S2_AXI_GEN_ARVALID,
      S2_AXI_GEN_ARREADY        => S2_AXI_GEN_ARREADY,
      S2_AXI_GEN_ARUSER         => S2_AXI_GEN_ARUSER,
      
      S2_AXI_GEN_RID            => S2_AXI_GEN_RID,
      S2_AXI_GEN_RDATA          => S2_AXI_GEN_RDATA,
      S2_AXI_GEN_RRESP          => S2_AXI_GEN_RRESP,
      S2_AXI_GEN_RLAST          => S2_AXI_GEN_RLAST,
      S2_AXI_GEN_RVALID         => S2_AXI_GEN_RVALID,
      S2_AXI_GEN_RREADY         => S2_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #3 Slave Signals.
      
      S3_AXI_GEN_AWID           => S3_AXI_GEN_AWID,
      S3_AXI_GEN_AWADDR         => S3_AXI_GEN_AWADDR,
      S3_AXI_GEN_AWLEN          => S3_AXI_GEN_AWLEN,
      S3_AXI_GEN_AWSIZE         => S3_AXI_GEN_AWSIZE,
      S3_AXI_GEN_AWBURST        => S3_AXI_GEN_AWBURST,
      S3_AXI_GEN_AWLOCK         => S3_AXI_GEN_AWLOCK,
      S3_AXI_GEN_AWCACHE        => S3_AXI_GEN_AWCACHE,
      S3_AXI_GEN_AWPROT         => S3_AXI_GEN_AWPROT,
      S3_AXI_GEN_AWQOS          => S3_AXI_GEN_AWQOS,
      S3_AXI_GEN_AWVALID        => S3_AXI_GEN_AWVALID,
      S3_AXI_GEN_AWREADY        => S3_AXI_GEN_AWREADY,
      S3_AXI_GEN_AWUSER         => S3_AXI_GEN_AWUSER,
      
      S3_AXI_GEN_WDATA          => S3_AXI_GEN_WDATA,
      S3_AXI_GEN_WSTRB          => S3_AXI_GEN_WSTRB,
      S3_AXI_GEN_WLAST          => S3_AXI_GEN_WLAST,
      S3_AXI_GEN_WVALID         => S3_AXI_GEN_WVALID,
      S3_AXI_GEN_WREADY         => S3_AXI_GEN_WREADY,
      
      S3_AXI_GEN_BRESP          => S3_AXI_GEN_BRESP,
      S3_AXI_GEN_BID            => S3_AXI_GEN_BID,
      S3_AXI_GEN_BVALID         => S3_AXI_GEN_BVALID,
      S3_AXI_GEN_BREADY         => S3_AXI_GEN_BREADY,
      
      S3_AXI_GEN_ARID           => S3_AXI_GEN_ARID,
      S3_AXI_GEN_ARADDR         => S3_AXI_GEN_ARADDR,
      S3_AXI_GEN_ARLEN          => S3_AXI_GEN_ARLEN,
      S3_AXI_GEN_ARSIZE         => S3_AXI_GEN_ARSIZE,
      S3_AXI_GEN_ARBURST        => S3_AXI_GEN_ARBURST,
      S3_AXI_GEN_ARLOCK         => S3_AXI_GEN_ARLOCK,
      S3_AXI_GEN_ARCACHE        => S3_AXI_GEN_ARCACHE,
      S3_AXI_GEN_ARPROT         => S3_AXI_GEN_ARPROT,
      S3_AXI_GEN_ARQOS          => S3_AXI_GEN_ARQOS,
      S3_AXI_GEN_ARVALID        => S3_AXI_GEN_ARVALID,
      S3_AXI_GEN_ARREADY        => S3_AXI_GEN_ARREADY,
      S3_AXI_GEN_ARUSER         => S3_AXI_GEN_ARUSER,
      
      S3_AXI_GEN_RID            => S3_AXI_GEN_RID,
      S3_AXI_GEN_RDATA          => S3_AXI_GEN_RDATA,
      S3_AXI_GEN_RRESP          => S3_AXI_GEN_RRESP,
      S3_AXI_GEN_RLAST          => S3_AXI_GEN_RLAST,
      S3_AXI_GEN_RVALID         => S3_AXI_GEN_RVALID,
      S3_AXI_GEN_RREADY         => S3_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #4 Slave Signals.
      
      S4_AXI_GEN_AWID           => S4_AXI_GEN_AWID,
      S4_AXI_GEN_AWADDR         => S4_AXI_GEN_AWADDR,
      S4_AXI_GEN_AWLEN          => S4_AXI_GEN_AWLEN,
      S4_AXI_GEN_AWSIZE         => S4_AXI_GEN_AWSIZE,
      S4_AXI_GEN_AWBURST        => S4_AXI_GEN_AWBURST,
      S4_AXI_GEN_AWLOCK         => S4_AXI_GEN_AWLOCK,
      S4_AXI_GEN_AWCACHE        => S4_AXI_GEN_AWCACHE,
      S4_AXI_GEN_AWPROT         => S4_AXI_GEN_AWPROT,
      S4_AXI_GEN_AWQOS          => S4_AXI_GEN_AWQOS,
      S4_AXI_GEN_AWVALID        => S4_AXI_GEN_AWVALID,
      S4_AXI_GEN_AWREADY        => S4_AXI_GEN_AWREADY,
      S4_AXI_GEN_AWUSER         => S4_AXI_GEN_AWUSER,
      
      S4_AXI_GEN_WDATA          => S4_AXI_GEN_WDATA,
      S4_AXI_GEN_WSTRB          => S4_AXI_GEN_WSTRB,
      S4_AXI_GEN_WLAST          => S4_AXI_GEN_WLAST,
      S4_AXI_GEN_WVALID         => S4_AXI_GEN_WVALID,
      S4_AXI_GEN_WREADY         => S4_AXI_GEN_WREADY,
      
      S4_AXI_GEN_BRESP          => S4_AXI_GEN_BRESP,
      S4_AXI_GEN_BID            => S4_AXI_GEN_BID,
      S4_AXI_GEN_BVALID         => S4_AXI_GEN_BVALID,
      S4_AXI_GEN_BREADY         => S4_AXI_GEN_BREADY,
      
      S4_AXI_GEN_ARID           => S4_AXI_GEN_ARID,
      S4_AXI_GEN_ARADDR         => S4_AXI_GEN_ARADDR,
      S4_AXI_GEN_ARLEN          => S4_AXI_GEN_ARLEN,
      S4_AXI_GEN_ARSIZE         => S4_AXI_GEN_ARSIZE,
      S4_AXI_GEN_ARBURST        => S4_AXI_GEN_ARBURST,
      S4_AXI_GEN_ARLOCK         => S4_AXI_GEN_ARLOCK,
      S4_AXI_GEN_ARCACHE        => S4_AXI_GEN_ARCACHE,
      S4_AXI_GEN_ARPROT         => S4_AXI_GEN_ARPROT,
      S4_AXI_GEN_ARQOS          => S4_AXI_GEN_ARQOS,
      S4_AXI_GEN_ARVALID        => S4_AXI_GEN_ARVALID,
      S4_AXI_GEN_ARREADY        => S4_AXI_GEN_ARREADY,
      S4_AXI_GEN_ARUSER         => S4_AXI_GEN_ARUSER,
      
      S4_AXI_GEN_RID            => S4_AXI_GEN_RID,
      S4_AXI_GEN_RDATA          => S4_AXI_GEN_RDATA,
      S4_AXI_GEN_RRESP          => S4_AXI_GEN_RRESP,
      S4_AXI_GEN_RLAST          => S4_AXI_GEN_RLAST,
      S4_AXI_GEN_RVALID         => S4_AXI_GEN_RVALID,
      S4_AXI_GEN_RREADY         => S4_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #5 Slave Signals.
      
      S5_AXI_GEN_AWID           => S5_AXI_GEN_AWID,
      S5_AXI_GEN_AWADDR         => S5_AXI_GEN_AWADDR,
      S5_AXI_GEN_AWLEN          => S5_AXI_GEN_AWLEN,
      S5_AXI_GEN_AWSIZE         => S5_AXI_GEN_AWSIZE,
      S5_AXI_GEN_AWBURST        => S5_AXI_GEN_AWBURST,
      S5_AXI_GEN_AWLOCK         => S5_AXI_GEN_AWLOCK,
      S5_AXI_GEN_AWCACHE        => S5_AXI_GEN_AWCACHE,
      S5_AXI_GEN_AWPROT         => S5_AXI_GEN_AWPROT,
      S5_AXI_GEN_AWQOS          => S5_AXI_GEN_AWQOS,
      S5_AXI_GEN_AWVALID        => S5_AXI_GEN_AWVALID,
      S5_AXI_GEN_AWREADY        => S5_AXI_GEN_AWREADY,
      S5_AXI_GEN_AWUSER         => S5_AXI_GEN_AWUSER,
      
      S5_AXI_GEN_WDATA          => S5_AXI_GEN_WDATA,
      S5_AXI_GEN_WSTRB          => S5_AXI_GEN_WSTRB,
      S5_AXI_GEN_WLAST          => S5_AXI_GEN_WLAST,
      S5_AXI_GEN_WVALID         => S5_AXI_GEN_WVALID,
      S5_AXI_GEN_WREADY         => S5_AXI_GEN_WREADY,
      
      S5_AXI_GEN_BRESP          => S5_AXI_GEN_BRESP,
      S5_AXI_GEN_BID            => S5_AXI_GEN_BID,
      S5_AXI_GEN_BVALID         => S5_AXI_GEN_BVALID,
      S5_AXI_GEN_BREADY         => S5_AXI_GEN_BREADY,
      
      S5_AXI_GEN_ARID           => S5_AXI_GEN_ARID,
      S5_AXI_GEN_ARADDR         => S5_AXI_GEN_ARADDR,
      S5_AXI_GEN_ARLEN          => S5_AXI_GEN_ARLEN,
      S5_AXI_GEN_ARSIZE         => S5_AXI_GEN_ARSIZE,
      S5_AXI_GEN_ARBURST        => S5_AXI_GEN_ARBURST,
      S5_AXI_GEN_ARLOCK         => S5_AXI_GEN_ARLOCK,
      S5_AXI_GEN_ARCACHE        => S5_AXI_GEN_ARCACHE,
      S5_AXI_GEN_ARPROT         => S5_AXI_GEN_ARPROT,
      S5_AXI_GEN_ARQOS          => S5_AXI_GEN_ARQOS,
      S5_AXI_GEN_ARVALID        => S5_AXI_GEN_ARVALID,
      S5_AXI_GEN_ARREADY        => S5_AXI_GEN_ARREADY,
      S5_AXI_GEN_ARUSER         => S5_AXI_GEN_ARUSER,
      
      S5_AXI_GEN_RID            => S5_AXI_GEN_RID,
      S5_AXI_GEN_RDATA          => S5_AXI_GEN_RDATA,
      S5_AXI_GEN_RRESP          => S5_AXI_GEN_RRESP,
      S5_AXI_GEN_RLAST          => S5_AXI_GEN_RLAST,
      S5_AXI_GEN_RVALID         => S5_AXI_GEN_RVALID,
      S5_AXI_GEN_RREADY         => S5_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #6 Slave Signals.
      
      S6_AXI_GEN_AWID           => S6_AXI_GEN_AWID,
      S6_AXI_GEN_AWADDR         => S6_AXI_GEN_AWADDR,
      S6_AXI_GEN_AWLEN          => S6_AXI_GEN_AWLEN,
      S6_AXI_GEN_AWSIZE         => S6_AXI_GEN_AWSIZE,
      S6_AXI_GEN_AWBURST        => S6_AXI_GEN_AWBURST,
      S6_AXI_GEN_AWLOCK         => S6_AXI_GEN_AWLOCK,
      S6_AXI_GEN_AWCACHE        => S6_AXI_GEN_AWCACHE,
      S6_AXI_GEN_AWPROT         => S6_AXI_GEN_AWPROT,
      S6_AXI_GEN_AWQOS          => S6_AXI_GEN_AWQOS,
      S6_AXI_GEN_AWVALID        => S6_AXI_GEN_AWVALID,
      S6_AXI_GEN_AWREADY        => S6_AXI_GEN_AWREADY,
      S6_AXI_GEN_AWUSER         => S6_AXI_GEN_AWUSER,
      
      S6_AXI_GEN_WDATA          => S6_AXI_GEN_WDATA,
      S6_AXI_GEN_WSTRB          => S6_AXI_GEN_WSTRB,
      S6_AXI_GEN_WLAST          => S6_AXI_GEN_WLAST,
      S6_AXI_GEN_WVALID         => S6_AXI_GEN_WVALID,
      S6_AXI_GEN_WREADY         => S6_AXI_GEN_WREADY,
      
      S6_AXI_GEN_BRESP          => S6_AXI_GEN_BRESP,
      S6_AXI_GEN_BID            => S6_AXI_GEN_BID,
      S6_AXI_GEN_BVALID         => S6_AXI_GEN_BVALID,
      S6_AXI_GEN_BREADY         => S6_AXI_GEN_BREADY,
      
      S6_AXI_GEN_ARID           => S6_AXI_GEN_ARID,
      S6_AXI_GEN_ARADDR         => S6_AXI_GEN_ARADDR,
      S6_AXI_GEN_ARLEN          => S6_AXI_GEN_ARLEN,
      S6_AXI_GEN_ARSIZE         => S6_AXI_GEN_ARSIZE,
      S6_AXI_GEN_ARBURST        => S6_AXI_GEN_ARBURST,
      S6_AXI_GEN_ARLOCK         => S6_AXI_GEN_ARLOCK,
      S6_AXI_GEN_ARCACHE        => S6_AXI_GEN_ARCACHE,
      S6_AXI_GEN_ARPROT         => S6_AXI_GEN_ARPROT,
      S6_AXI_GEN_ARQOS          => S6_AXI_GEN_ARQOS,
      S6_AXI_GEN_ARVALID        => S6_AXI_GEN_ARVALID,
      S6_AXI_GEN_ARREADY        => S6_AXI_GEN_ARREADY,
      S6_AXI_GEN_ARUSER         => S6_AXI_GEN_ARUSER,
      
      S6_AXI_GEN_RID            => S6_AXI_GEN_RID,
      S6_AXI_GEN_RDATA          => S6_AXI_GEN_RDATA,
      S6_AXI_GEN_RRESP          => S6_AXI_GEN_RRESP,
      S6_AXI_GEN_RLAST          => S6_AXI_GEN_RLAST,
      S6_AXI_GEN_RVALID         => S6_AXI_GEN_RVALID,
      S6_AXI_GEN_RREADY         => S6_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #7 Slave Signals.
      
      S7_AXI_GEN_AWID           => S7_AXI_GEN_AWID,
      S7_AXI_GEN_AWADDR         => S7_AXI_GEN_AWADDR,
      S7_AXI_GEN_AWLEN          => S7_AXI_GEN_AWLEN,
      S7_AXI_GEN_AWSIZE         => S7_AXI_GEN_AWSIZE,
      S7_AXI_GEN_AWBURST        => S7_AXI_GEN_AWBURST,
      S7_AXI_GEN_AWLOCK         => S7_AXI_GEN_AWLOCK,
      S7_AXI_GEN_AWCACHE        => S7_AXI_GEN_AWCACHE,
      S7_AXI_GEN_AWPROT         => S7_AXI_GEN_AWPROT,
      S7_AXI_GEN_AWQOS          => S7_AXI_GEN_AWQOS,
      S7_AXI_GEN_AWVALID        => S7_AXI_GEN_AWVALID,
      S7_AXI_GEN_AWREADY        => S7_AXI_GEN_AWREADY,
      S7_AXI_GEN_AWUSER         => S7_AXI_GEN_AWUSER,
      
      S7_AXI_GEN_WDATA          => S7_AXI_GEN_WDATA,
      S7_AXI_GEN_WSTRB          => S7_AXI_GEN_WSTRB,
      S7_AXI_GEN_WLAST          => S7_AXI_GEN_WLAST,
      S7_AXI_GEN_WVALID         => S7_AXI_GEN_WVALID,
      S7_AXI_GEN_WREADY         => S7_AXI_GEN_WREADY,
      
      S7_AXI_GEN_BRESP          => S7_AXI_GEN_BRESP,
      S7_AXI_GEN_BID            => S7_AXI_GEN_BID,
      S7_AXI_GEN_BVALID         => S7_AXI_GEN_BVALID,
      S7_AXI_GEN_BREADY         => S7_AXI_GEN_BREADY,
      
      S7_AXI_GEN_ARID           => S7_AXI_GEN_ARID,
      S7_AXI_GEN_ARADDR         => S7_AXI_GEN_ARADDR,
      S7_AXI_GEN_ARLEN          => S7_AXI_GEN_ARLEN,
      S7_AXI_GEN_ARSIZE         => S7_AXI_GEN_ARSIZE,
      S7_AXI_GEN_ARBURST        => S7_AXI_GEN_ARBURST,
      S7_AXI_GEN_ARLOCK         => S7_AXI_GEN_ARLOCK,
      S7_AXI_GEN_ARCACHE        => S7_AXI_GEN_ARCACHE,
      S7_AXI_GEN_ARPROT         => S7_AXI_GEN_ARPROT,
      S7_AXI_GEN_ARQOS          => S7_AXI_GEN_ARQOS,
      S7_AXI_GEN_ARVALID        => S7_AXI_GEN_ARVALID,
      S7_AXI_GEN_ARREADY        => S7_AXI_GEN_ARREADY,
      S7_AXI_GEN_ARUSER         => S7_AXI_GEN_ARUSER,
      
      S7_AXI_GEN_RID            => S7_AXI_GEN_RID,
      S7_AXI_GEN_RDATA          => S7_AXI_GEN_RDATA,
      S7_AXI_GEN_RRESP          => S7_AXI_GEN_RRESP,
      S7_AXI_GEN_RLAST          => S7_AXI_GEN_RLAST,
      S7_AXI_GEN_RVALID         => S7_AXI_GEN_RVALID,
      S7_AXI_GEN_RREADY         => S7_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #8 Slave Signals.
      
      S8_AXI_GEN_AWID           => S8_AXI_GEN_AWID,
      S8_AXI_GEN_AWADDR         => S8_AXI_GEN_AWADDR,
      S8_AXI_GEN_AWLEN          => S8_AXI_GEN_AWLEN,
      S8_AXI_GEN_AWSIZE         => S8_AXI_GEN_AWSIZE,
      S8_AXI_GEN_AWBURST        => S8_AXI_GEN_AWBURST,
      S8_AXI_GEN_AWLOCK         => S8_AXI_GEN_AWLOCK,
      S8_AXI_GEN_AWCACHE        => S8_AXI_GEN_AWCACHE,
      S8_AXI_GEN_AWPROT         => S8_AXI_GEN_AWPROT,
      S8_AXI_GEN_AWQOS          => S8_AXI_GEN_AWQOS,
      S8_AXI_GEN_AWVALID        => S8_AXI_GEN_AWVALID,
      S8_AXI_GEN_AWREADY        => S8_AXI_GEN_AWREADY,
      S8_AXI_GEN_AWUSER         => S8_AXI_GEN_AWUSER,
      
      S8_AXI_GEN_WDATA          => S8_AXI_GEN_WDATA,
      S8_AXI_GEN_WSTRB          => S8_AXI_GEN_WSTRB,
      S8_AXI_GEN_WLAST          => S8_AXI_GEN_WLAST,
      S8_AXI_GEN_WVALID         => S8_AXI_GEN_WVALID,
      S8_AXI_GEN_WREADY         => S8_AXI_GEN_WREADY,
      
      S8_AXI_GEN_BRESP          => S8_AXI_GEN_BRESP,
      S8_AXI_GEN_BID            => S8_AXI_GEN_BID,
      S8_AXI_GEN_BVALID         => S8_AXI_GEN_BVALID,
      S8_AXI_GEN_BREADY         => S8_AXI_GEN_BREADY,
      
      S8_AXI_GEN_ARID           => S8_AXI_GEN_ARID,
      S8_AXI_GEN_ARADDR         => S8_AXI_GEN_ARADDR,
      S8_AXI_GEN_ARLEN          => S8_AXI_GEN_ARLEN,
      S8_AXI_GEN_ARSIZE         => S8_AXI_GEN_ARSIZE,
      S8_AXI_GEN_ARBURST        => S8_AXI_GEN_ARBURST,
      S8_AXI_GEN_ARLOCK         => S8_AXI_GEN_ARLOCK,
      S8_AXI_GEN_ARCACHE        => S8_AXI_GEN_ARCACHE,
      S8_AXI_GEN_ARPROT         => S8_AXI_GEN_ARPROT,
      S8_AXI_GEN_ARQOS          => S8_AXI_GEN_ARQOS,
      S8_AXI_GEN_ARVALID        => S8_AXI_GEN_ARVALID,
      S8_AXI_GEN_ARREADY        => S8_AXI_GEN_ARREADY,
      S8_AXI_GEN_ARUSER         => S8_AXI_GEN_ARUSER,
      
      S8_AXI_GEN_RID            => S8_AXI_GEN_RID,
      S8_AXI_GEN_RDATA          => S8_AXI_GEN_RDATA,
      S8_AXI_GEN_RRESP          => S8_AXI_GEN_RRESP,
      S8_AXI_GEN_RLAST          => S8_AXI_GEN_RLAST,
      S8_AXI_GEN_RVALID         => S8_AXI_GEN_RVALID,
      S8_AXI_GEN_RREADY         => S8_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #9 Slave Signals.
      
      S9_AXI_GEN_AWID           => S9_AXI_GEN_AWID,
      S9_AXI_GEN_AWADDR         => S9_AXI_GEN_AWADDR,
      S9_AXI_GEN_AWLEN          => S9_AXI_GEN_AWLEN,
      S9_AXI_GEN_AWSIZE         => S9_AXI_GEN_AWSIZE,
      S9_AXI_GEN_AWBURST        => S9_AXI_GEN_AWBURST,
      S9_AXI_GEN_AWLOCK         => S9_AXI_GEN_AWLOCK,
      S9_AXI_GEN_AWCACHE        => S9_AXI_GEN_AWCACHE,
      S9_AXI_GEN_AWPROT         => S9_AXI_GEN_AWPROT,
      S9_AXI_GEN_AWQOS          => S9_AXI_GEN_AWQOS,
      S9_AXI_GEN_AWVALID        => S9_AXI_GEN_AWVALID,
      S9_AXI_GEN_AWREADY        => S9_AXI_GEN_AWREADY,
      S9_AXI_GEN_AWUSER         => S9_AXI_GEN_AWUSER,
      
      S9_AXI_GEN_WDATA          => S9_AXI_GEN_WDATA,
      S9_AXI_GEN_WSTRB          => S9_AXI_GEN_WSTRB,
      S9_AXI_GEN_WLAST          => S9_AXI_GEN_WLAST,
      S9_AXI_GEN_WVALID         => S9_AXI_GEN_WVALID,
      S9_AXI_GEN_WREADY         => S9_AXI_GEN_WREADY,
      
      S9_AXI_GEN_BRESP          => S9_AXI_GEN_BRESP,
      S9_AXI_GEN_BID            => S9_AXI_GEN_BID,
      S9_AXI_GEN_BVALID         => S9_AXI_GEN_BVALID,
      S9_AXI_GEN_BREADY         => S9_AXI_GEN_BREADY,
      
      S9_AXI_GEN_ARID           => S9_AXI_GEN_ARID,
      S9_AXI_GEN_ARADDR         => S9_AXI_GEN_ARADDR,
      S9_AXI_GEN_ARLEN          => S9_AXI_GEN_ARLEN,
      S9_AXI_GEN_ARSIZE         => S9_AXI_GEN_ARSIZE,
      S9_AXI_GEN_ARBURST        => S9_AXI_GEN_ARBURST,
      S9_AXI_GEN_ARLOCK         => S9_AXI_GEN_ARLOCK,
      S9_AXI_GEN_ARCACHE        => S9_AXI_GEN_ARCACHE,
      S9_AXI_GEN_ARPROT         => S9_AXI_GEN_ARPROT,
      S9_AXI_GEN_ARQOS          => S9_AXI_GEN_ARQOS,
      S9_AXI_GEN_ARVALID        => S9_AXI_GEN_ARVALID,
      S9_AXI_GEN_ARREADY        => S9_AXI_GEN_ARREADY,
      S9_AXI_GEN_ARUSER         => S9_AXI_GEN_ARUSER,
      
      S9_AXI_GEN_RID            => S9_AXI_GEN_RID,
      S9_AXI_GEN_RDATA          => S9_AXI_GEN_RDATA,
      S9_AXI_GEN_RRESP          => S9_AXI_GEN_RRESP,
      S9_AXI_GEN_RLAST          => S9_AXI_GEN_RLAST,
      S9_AXI_GEN_RVALID         => S9_AXI_GEN_RVALID,
      S9_AXI_GEN_RREADY         => S9_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #10 Slave Signals.
      
      S10_AXI_GEN_AWID           => S10_AXI_GEN_AWID,
      S10_AXI_GEN_AWADDR         => S10_AXI_GEN_AWADDR,
      S10_AXI_GEN_AWLEN          => S10_AXI_GEN_AWLEN,
      S10_AXI_GEN_AWSIZE         => S10_AXI_GEN_AWSIZE,
      S10_AXI_GEN_AWBURST        => S10_AXI_GEN_AWBURST,
      S10_AXI_GEN_AWLOCK         => S10_AXI_GEN_AWLOCK,
      S10_AXI_GEN_AWCACHE        => S10_AXI_GEN_AWCACHE,
      S10_AXI_GEN_AWPROT         => S10_AXI_GEN_AWPROT,
      S10_AXI_GEN_AWQOS          => S10_AXI_GEN_AWQOS,
      S10_AXI_GEN_AWVALID        => S10_AXI_GEN_AWVALID,
      S10_AXI_GEN_AWREADY        => S10_AXI_GEN_AWREADY,
      S10_AXI_GEN_AWUSER         => S10_AXI_GEN_AWUSER,
      
      S10_AXI_GEN_WDATA          => S10_AXI_GEN_WDATA,
      S10_AXI_GEN_WSTRB          => S10_AXI_GEN_WSTRB,
      S10_AXI_GEN_WLAST          => S10_AXI_GEN_WLAST,
      S10_AXI_GEN_WVALID         => S10_AXI_GEN_WVALID,
      S10_AXI_GEN_WREADY         => S10_AXI_GEN_WREADY,
      
      S10_AXI_GEN_BRESP          => S10_AXI_GEN_BRESP,
      S10_AXI_GEN_BID            => S10_AXI_GEN_BID,
      S10_AXI_GEN_BVALID         => S10_AXI_GEN_BVALID,
      S10_AXI_GEN_BREADY         => S10_AXI_GEN_BREADY,
      
      S10_AXI_GEN_ARID           => S10_AXI_GEN_ARID,
      S10_AXI_GEN_ARADDR         => S10_AXI_GEN_ARADDR,
      S10_AXI_GEN_ARLEN          => S10_AXI_GEN_ARLEN,
      S10_AXI_GEN_ARSIZE         => S10_AXI_GEN_ARSIZE,
      S10_AXI_GEN_ARBURST        => S10_AXI_GEN_ARBURST,
      S10_AXI_GEN_ARLOCK         => S10_AXI_GEN_ARLOCK,
      S10_AXI_GEN_ARCACHE        => S10_AXI_GEN_ARCACHE,
      S10_AXI_GEN_ARPROT         => S10_AXI_GEN_ARPROT,
      S10_AXI_GEN_ARQOS          => S10_AXI_GEN_ARQOS,
      S10_AXI_GEN_ARVALID        => S10_AXI_GEN_ARVALID,
      S10_AXI_GEN_ARREADY        => S10_AXI_GEN_ARREADY,
      S10_AXI_GEN_ARUSER         => S10_AXI_GEN_ARUSER,
      
      S10_AXI_GEN_RID            => S10_AXI_GEN_RID,
      S10_AXI_GEN_RDATA          => S10_AXI_GEN_RDATA,
      S10_AXI_GEN_RRESP          => S10_AXI_GEN_RRESP,
      S10_AXI_GEN_RLAST          => S10_AXI_GEN_RLAST,
      S10_AXI_GEN_RVALID         => S10_AXI_GEN_RVALID,
      S10_AXI_GEN_RREADY         => S10_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #11 Slave Signals.
      
      S11_AXI_GEN_AWID           => S11_AXI_GEN_AWID,
      S11_AXI_GEN_AWADDR         => S11_AXI_GEN_AWADDR,
      S11_AXI_GEN_AWLEN          => S11_AXI_GEN_AWLEN,
      S11_AXI_GEN_AWSIZE         => S11_AXI_GEN_AWSIZE,
      S11_AXI_GEN_AWBURST        => S11_AXI_GEN_AWBURST,
      S11_AXI_GEN_AWLOCK         => S11_AXI_GEN_AWLOCK,
      S11_AXI_GEN_AWCACHE        => S11_AXI_GEN_AWCACHE,
      S11_AXI_GEN_AWPROT         => S11_AXI_GEN_AWPROT,
      S11_AXI_GEN_AWQOS          => S11_AXI_GEN_AWQOS,
      S11_AXI_GEN_AWVALID        => S11_AXI_GEN_AWVALID,
      S11_AXI_GEN_AWREADY        => S11_AXI_GEN_AWREADY,
      S11_AXI_GEN_AWUSER         => S11_AXI_GEN_AWUSER,
      
      S11_AXI_GEN_WDATA          => S11_AXI_GEN_WDATA,
      S11_AXI_GEN_WSTRB          => S11_AXI_GEN_WSTRB,
      S11_AXI_GEN_WLAST          => S11_AXI_GEN_WLAST,
      S11_AXI_GEN_WVALID         => S11_AXI_GEN_WVALID,
      S11_AXI_GEN_WREADY         => S11_AXI_GEN_WREADY,
      
      S11_AXI_GEN_BRESP          => S11_AXI_GEN_BRESP,
      S11_AXI_GEN_BID            => S11_AXI_GEN_BID,
      S11_AXI_GEN_BVALID         => S11_AXI_GEN_BVALID,
      S11_AXI_GEN_BREADY         => S11_AXI_GEN_BREADY,
      
      S11_AXI_GEN_ARID           => S11_AXI_GEN_ARID,
      S11_AXI_GEN_ARADDR         => S11_AXI_GEN_ARADDR,
      S11_AXI_GEN_ARLEN          => S11_AXI_GEN_ARLEN,
      S11_AXI_GEN_ARSIZE         => S11_AXI_GEN_ARSIZE,
      S11_AXI_GEN_ARBURST        => S11_AXI_GEN_ARBURST,
      S11_AXI_GEN_ARLOCK         => S11_AXI_GEN_ARLOCK,
      S11_AXI_GEN_ARCACHE        => S11_AXI_GEN_ARCACHE,
      S11_AXI_GEN_ARPROT         => S11_AXI_GEN_ARPROT,
      S11_AXI_GEN_ARQOS          => S11_AXI_GEN_ARQOS,
      S11_AXI_GEN_ARVALID        => S11_AXI_GEN_ARVALID,
      S11_AXI_GEN_ARREADY        => S11_AXI_GEN_ARREADY,
      S11_AXI_GEN_ARUSER         => S11_AXI_GEN_ARUSER,
      
      S11_AXI_GEN_RID            => S11_AXI_GEN_RID,
      S11_AXI_GEN_RDATA          => S11_AXI_GEN_RDATA,
      S11_AXI_GEN_RRESP          => S11_AXI_GEN_RRESP,
      S11_AXI_GEN_RLAST          => S11_AXI_GEN_RLAST,
      S11_AXI_GEN_RVALID         => S11_AXI_GEN_RVALID,
      S11_AXI_GEN_RREADY         => S11_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #12 Slave Signals.
      
      S12_AXI_GEN_AWID           => S12_AXI_GEN_AWID,
      S12_AXI_GEN_AWADDR         => S12_AXI_GEN_AWADDR,
      S12_AXI_GEN_AWLEN          => S12_AXI_GEN_AWLEN,
      S12_AXI_GEN_AWSIZE         => S12_AXI_GEN_AWSIZE,
      S12_AXI_GEN_AWBURST        => S12_AXI_GEN_AWBURST,
      S12_AXI_GEN_AWLOCK         => S12_AXI_GEN_AWLOCK,
      S12_AXI_GEN_AWCACHE        => S12_AXI_GEN_AWCACHE,
      S12_AXI_GEN_AWPROT         => S12_AXI_GEN_AWPROT,
      S12_AXI_GEN_AWQOS          => S12_AXI_GEN_AWQOS,
      S12_AXI_GEN_AWVALID        => S12_AXI_GEN_AWVALID,
      S12_AXI_GEN_AWREADY        => S12_AXI_GEN_AWREADY,
      S12_AXI_GEN_AWUSER         => S12_AXI_GEN_AWUSER,
      
      S12_AXI_GEN_WDATA          => S12_AXI_GEN_WDATA,
      S12_AXI_GEN_WSTRB          => S12_AXI_GEN_WSTRB,
      S12_AXI_GEN_WLAST          => S12_AXI_GEN_WLAST,
      S12_AXI_GEN_WVALID         => S12_AXI_GEN_WVALID,
      S12_AXI_GEN_WREADY         => S12_AXI_GEN_WREADY,
      
      S12_AXI_GEN_BRESP          => S12_AXI_GEN_BRESP,
      S12_AXI_GEN_BID            => S12_AXI_GEN_BID,
      S12_AXI_GEN_BVALID         => S12_AXI_GEN_BVALID,
      S12_AXI_GEN_BREADY         => S12_AXI_GEN_BREADY,
      
      S12_AXI_GEN_ARID           => S12_AXI_GEN_ARID,
      S12_AXI_GEN_ARADDR         => S12_AXI_GEN_ARADDR,
      S12_AXI_GEN_ARLEN          => S12_AXI_GEN_ARLEN,
      S12_AXI_GEN_ARSIZE         => S12_AXI_GEN_ARSIZE,
      S12_AXI_GEN_ARBURST        => S12_AXI_GEN_ARBURST,
      S12_AXI_GEN_ARLOCK         => S12_AXI_GEN_ARLOCK,
      S12_AXI_GEN_ARCACHE        => S12_AXI_GEN_ARCACHE,
      S12_AXI_GEN_ARPROT         => S12_AXI_GEN_ARPROT,
      S12_AXI_GEN_ARQOS          => S12_AXI_GEN_ARQOS,
      S12_AXI_GEN_ARVALID        => S12_AXI_GEN_ARVALID,
      S12_AXI_GEN_ARREADY        => S12_AXI_GEN_ARREADY,
      S12_AXI_GEN_ARUSER         => S12_AXI_GEN_ARUSER,
      
      S12_AXI_GEN_RID            => S12_AXI_GEN_RID,
      S12_AXI_GEN_RDATA          => S12_AXI_GEN_RDATA,
      S12_AXI_GEN_RRESP          => S12_AXI_GEN_RRESP,
      S12_AXI_GEN_RLAST          => S12_AXI_GEN_RLAST,
      S12_AXI_GEN_RVALID         => S12_AXI_GEN_RVALID,
      S12_AXI_GEN_RREADY         => S12_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #13 Slave Signals.
      
      S13_AXI_GEN_AWID           => S13_AXI_GEN_AWID,
      S13_AXI_GEN_AWADDR         => S13_AXI_GEN_AWADDR,
      S13_AXI_GEN_AWLEN          => S13_AXI_GEN_AWLEN,
      S13_AXI_GEN_AWSIZE         => S13_AXI_GEN_AWSIZE,
      S13_AXI_GEN_AWBURST        => S13_AXI_GEN_AWBURST,
      S13_AXI_GEN_AWLOCK         => S13_AXI_GEN_AWLOCK,
      S13_AXI_GEN_AWCACHE        => S13_AXI_GEN_AWCACHE,
      S13_AXI_GEN_AWPROT         => S13_AXI_GEN_AWPROT,
      S13_AXI_GEN_AWQOS          => S13_AXI_GEN_AWQOS,
      S13_AXI_GEN_AWVALID        => S13_AXI_GEN_AWVALID,
      S13_AXI_GEN_AWREADY        => S13_AXI_GEN_AWREADY,
      S13_AXI_GEN_AWUSER         => S13_AXI_GEN_AWUSER,
      
      S13_AXI_GEN_WDATA          => S13_AXI_GEN_WDATA,
      S13_AXI_GEN_WSTRB          => S13_AXI_GEN_WSTRB,
      S13_AXI_GEN_WLAST          => S13_AXI_GEN_WLAST,
      S13_AXI_GEN_WVALID         => S13_AXI_GEN_WVALID,
      S13_AXI_GEN_WREADY         => S13_AXI_GEN_WREADY,
      
      S13_AXI_GEN_BRESP          => S13_AXI_GEN_BRESP,
      S13_AXI_GEN_BID            => S13_AXI_GEN_BID,
      S13_AXI_GEN_BVALID         => S13_AXI_GEN_BVALID,
      S13_AXI_GEN_BREADY         => S13_AXI_GEN_BREADY,
      
      S13_AXI_GEN_ARID           => S13_AXI_GEN_ARID,
      S13_AXI_GEN_ARADDR         => S13_AXI_GEN_ARADDR,
      S13_AXI_GEN_ARLEN          => S13_AXI_GEN_ARLEN,
      S13_AXI_GEN_ARSIZE         => S13_AXI_GEN_ARSIZE,
      S13_AXI_GEN_ARBURST        => S13_AXI_GEN_ARBURST,
      S13_AXI_GEN_ARLOCK         => S13_AXI_GEN_ARLOCK,
      S13_AXI_GEN_ARCACHE        => S13_AXI_GEN_ARCACHE,
      S13_AXI_GEN_ARPROT         => S13_AXI_GEN_ARPROT,
      S13_AXI_GEN_ARQOS          => S13_AXI_GEN_ARQOS,
      S13_AXI_GEN_ARVALID        => S13_AXI_GEN_ARVALID,
      S13_AXI_GEN_ARREADY        => S13_AXI_GEN_ARREADY,
      S13_AXI_GEN_ARUSER         => S13_AXI_GEN_ARUSER,
      
      S13_AXI_GEN_RID            => S13_AXI_GEN_RID,
      S13_AXI_GEN_RDATA          => S13_AXI_GEN_RDATA,
      S13_AXI_GEN_RRESP          => S13_AXI_GEN_RRESP,
      S13_AXI_GEN_RLAST          => S13_AXI_GEN_RLAST,
      S13_AXI_GEN_RVALID         => S13_AXI_GEN_RVALID,
      S13_AXI_GEN_RREADY         => S13_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #14 Slave Signals.
      
      S14_AXI_GEN_AWID           => S14_AXI_GEN_AWID,
      S14_AXI_GEN_AWADDR         => S14_AXI_GEN_AWADDR,
      S14_AXI_GEN_AWLEN          => S14_AXI_GEN_AWLEN,
      S14_AXI_GEN_AWSIZE         => S14_AXI_GEN_AWSIZE,
      S14_AXI_GEN_AWBURST        => S14_AXI_GEN_AWBURST,
      S14_AXI_GEN_AWLOCK         => S14_AXI_GEN_AWLOCK,
      S14_AXI_GEN_AWCACHE        => S14_AXI_GEN_AWCACHE,
      S14_AXI_GEN_AWPROT         => S14_AXI_GEN_AWPROT,
      S14_AXI_GEN_AWQOS          => S14_AXI_GEN_AWQOS,
      S14_AXI_GEN_AWVALID        => S14_AXI_GEN_AWVALID,
      S14_AXI_GEN_AWREADY        => S14_AXI_GEN_AWREADY,
      S14_AXI_GEN_AWUSER         => S14_AXI_GEN_AWUSER,
      
      S14_AXI_GEN_WDATA          => S14_AXI_GEN_WDATA,
      S14_AXI_GEN_WSTRB          => S14_AXI_GEN_WSTRB,
      S14_AXI_GEN_WLAST          => S14_AXI_GEN_WLAST,
      S14_AXI_GEN_WVALID         => S14_AXI_GEN_WVALID,
      S14_AXI_GEN_WREADY         => S14_AXI_GEN_WREADY,
      
      S14_AXI_GEN_BRESP          => S14_AXI_GEN_BRESP,
      S14_AXI_GEN_BID            => S14_AXI_GEN_BID,
      S14_AXI_GEN_BVALID         => S14_AXI_GEN_BVALID,
      S14_AXI_GEN_BREADY         => S14_AXI_GEN_BREADY,
      
      S14_AXI_GEN_ARID           => S14_AXI_GEN_ARID,
      S14_AXI_GEN_ARADDR         => S14_AXI_GEN_ARADDR,
      S14_AXI_GEN_ARLEN          => S14_AXI_GEN_ARLEN,
      S14_AXI_GEN_ARSIZE         => S14_AXI_GEN_ARSIZE,
      S14_AXI_GEN_ARBURST        => S14_AXI_GEN_ARBURST,
      S14_AXI_GEN_ARLOCK         => S14_AXI_GEN_ARLOCK,
      S14_AXI_GEN_ARCACHE        => S14_AXI_GEN_ARCACHE,
      S14_AXI_GEN_ARPROT         => S14_AXI_GEN_ARPROT,
      S14_AXI_GEN_ARQOS          => S14_AXI_GEN_ARQOS,
      S14_AXI_GEN_ARVALID        => S14_AXI_GEN_ARVALID,
      S14_AXI_GEN_ARREADY        => S14_AXI_GEN_ARREADY,
      S14_AXI_GEN_ARUSER         => S14_AXI_GEN_ARUSER,
      
      S14_AXI_GEN_RID            => S14_AXI_GEN_RID,
      S14_AXI_GEN_RDATA          => S14_AXI_GEN_RDATA,
      S14_AXI_GEN_RRESP          => S14_AXI_GEN_RRESP,
      S14_AXI_GEN_RLAST          => S14_AXI_GEN_RLAST,
      S14_AXI_GEN_RVALID         => S14_AXI_GEN_RVALID,
      S14_AXI_GEN_RREADY         => S14_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Generic AXI4/ACE Interface #15 Slave Signals.
      
      S15_AXI_GEN_AWID           => S15_AXI_GEN_AWID,
      S15_AXI_GEN_AWADDR         => S15_AXI_GEN_AWADDR,
      S15_AXI_GEN_AWLEN          => S15_AXI_GEN_AWLEN,
      S15_AXI_GEN_AWSIZE         => S15_AXI_GEN_AWSIZE,
      S15_AXI_GEN_AWBURST        => S15_AXI_GEN_AWBURST,
      S15_AXI_GEN_AWLOCK         => S15_AXI_GEN_AWLOCK,
      S15_AXI_GEN_AWCACHE        => S15_AXI_GEN_AWCACHE,
      S15_AXI_GEN_AWPROT         => S15_AXI_GEN_AWPROT,
      S15_AXI_GEN_AWQOS          => S15_AXI_GEN_AWQOS,
      S15_AXI_GEN_AWVALID        => S15_AXI_GEN_AWVALID,
      S15_AXI_GEN_AWREADY        => S15_AXI_GEN_AWREADY,
      S15_AXI_GEN_AWUSER         => S15_AXI_GEN_AWUSER,
      
      S15_AXI_GEN_WDATA          => S15_AXI_GEN_WDATA,
      S15_AXI_GEN_WSTRB          => S15_AXI_GEN_WSTRB,
      S15_AXI_GEN_WLAST          => S15_AXI_GEN_WLAST,
      S15_AXI_GEN_WVALID         => S15_AXI_GEN_WVALID,
      S15_AXI_GEN_WREADY         => S15_AXI_GEN_WREADY,
      
      S15_AXI_GEN_BRESP          => S15_AXI_GEN_BRESP,
      S15_AXI_GEN_BID            => S15_AXI_GEN_BID,
      S15_AXI_GEN_BVALID         => S15_AXI_GEN_BVALID,
      S15_AXI_GEN_BREADY         => S15_AXI_GEN_BREADY,
      
      S15_AXI_GEN_ARID           => S15_AXI_GEN_ARID,
      S15_AXI_GEN_ARADDR         => S15_AXI_GEN_ARADDR,
      S15_AXI_GEN_ARLEN          => S15_AXI_GEN_ARLEN,
      S15_AXI_GEN_ARSIZE         => S15_AXI_GEN_ARSIZE,
      S15_AXI_GEN_ARBURST        => S15_AXI_GEN_ARBURST,
      S15_AXI_GEN_ARLOCK         => S15_AXI_GEN_ARLOCK,
      S15_AXI_GEN_ARCACHE        => S15_AXI_GEN_ARCACHE,
      S15_AXI_GEN_ARPROT         => S15_AXI_GEN_ARPROT,
      S15_AXI_GEN_ARQOS          => S15_AXI_GEN_ARQOS,
      S15_AXI_GEN_ARVALID        => S15_AXI_GEN_ARVALID,
      S15_AXI_GEN_ARREADY        => S15_AXI_GEN_ARREADY,
      S15_AXI_GEN_ARUSER         => S15_AXI_GEN_ARUSER,
      
      S15_AXI_GEN_RID            => S15_AXI_GEN_RID,
      S15_AXI_GEN_RDATA          => S15_AXI_GEN_RDATA,
      S15_AXI_GEN_RRESP          => S15_AXI_GEN_RRESP,
      S15_AXI_GEN_RLAST          => S15_AXI_GEN_RLAST,
      S15_AXI_GEN_RVALID         => S15_AXI_GEN_RVALID,
      S15_AXI_GEN_RREADY         => S15_AXI_GEN_RREADY,
      
      
      -- ---------------------------------------------------
      -- Control If Transactions.
      
      ctrl_init_done            => ctrl_init_done,
      ctrl_access               => ctrl_access,
      ctrl_ready                => ctrl_ready,
      
      
      -- ---------------------------------------------------
      -- Lookup signals.
      
      lookup_piperun            => lookup_piperun,
      
      lookup_write_data_ready   => lookup_write_data_ready,
      
      lookup_read_done          => lookup_read_done,
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      update_write_data_ready   => update_write_data_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Ports).
      
      -- Write miss response
      update_ext_bresp_valid    => update_ext_bresp_valid,
      update_ext_bresp          => update_ext_bresp,
      update_ext_bresp_ready    => update_ext_bresp_ready,
      
      
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
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      => lookup_read_data_new,
      lookup_read_data_hit      => lookup_read_data_hit,
      lookup_read_data_snoop    => lookup_read_data_snoop,
      lookup_read_data_allocate => lookup_read_data_allocate,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     => read_info_almost_full,
      read_info_full            => read_info_full,
      read_data_hit_pop         => read_data_hit_pop,
      read_data_hit_almost_full => read_data_hit_almost_full,
      read_data_hit_full        => read_data_hit_full,
      read_data_hit_fit         => read_data_hit_fit,
      read_data_miss_full       => read_data_miss_full,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (Read Data).
      
      lookup_read_data_valid    => lookup_read_data_valid,
      lookup_read_data_last     => lookup_read_data_last,
      lookup_read_data_resp     => lookup_read_data_resp,
      lookup_read_data_set      => lookup_read_data_set,
      lookup_read_data_word     => lookup_read_data_word,
      lookup_read_data_ready    => lookup_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals (Read Data).
      
      update_read_data_valid    => update_read_data_valid,
      update_read_data_last     => update_read_data_last,
      update_read_data_resp     => update_read_data_resp,
      update_read_data_word     => update_read_data_word,
      update_read_data_ready    => update_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      => stat_reset,
      stat_enable                     => stat_enable,
      
      -- Optimized ports.
      stat_s_axi_rd_segments          => stat_s_axi_rd_segments,
      stat_s_axi_wr_segments          => stat_s_axi_wr_segments,
      stat_s_axi_rip                  => stat_s_axi_rip,
      stat_s_axi_r                    => stat_s_axi_r,
      stat_s_axi_bip                  => stat_s_axi_bip,
      stat_s_axi_bp                   => stat_s_axi_bp,
      stat_s_axi_wip                  => stat_s_axi_wip,
      stat_s_axi_w                    => stat_s_axi_w,
      stat_s_axi_rd_latency           => stat_s_axi_rd_latency,
      stat_s_axi_wr_latency           => stat_s_axi_wr_latency,
      stat_s_axi_rd_latency_conf      => stat_s_axi_rd_latency_conf,
      stat_s_axi_wr_latency_conf      => stat_s_axi_wr_latency_conf,
  
      -- Generic ports.
      stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments,
      stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments,
      stat_s_axi_gen_rip              => stat_s_axi_gen_rip,
      stat_s_axi_gen_r                => stat_s_axi_gen_r,
      stat_s_axi_gen_bip              => stat_s_axi_gen_bip,
      stat_s_axi_gen_bp               => stat_s_axi_gen_bp,
      stat_s_axi_gen_wip              => stat_s_axi_gen_wip,
      stat_s_axi_gen_w                => stat_s_axi_gen_w,
      stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency,
      stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency,
      stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf,
      stat_s_axi_gen_wr_latency_conf  =>stat_s_axi_gen_wr_latency_conf ,
      
      -- Arbiter
      stat_arb_valid                  => stat_arb_valid,
      stat_arb_concurrent_accesses    => stat_arb_concurrent_accesses,
      stat_arb_opt_read_blocked       => stat_arb_opt_read_blocked,
      stat_arb_gen_read_blocked       => stat_arb_gen_read_blocked,
      
      -- Access
      stat_access_valid               => stat_access_valid,
      stat_access_stall               => stat_access_stall,
      stat_access_fetch_stall         => stat_access_fetch_stall,
      stat_access_req_stall           => stat_access_req_stall,
      stat_access_act_stall           => stat_access_act_stall,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => frontend_assert,
      
      
      -- ---------------------------------------------------
      -- Debug signals.
      
      OPT_IF0_DEBUG             => OPT_IF0_DEBUG,
      OPT_IF1_DEBUG             => OPT_IF1_DEBUG,
      OPT_IF2_DEBUG             => OPT_IF2_DEBUG,
      OPT_IF3_DEBUG             => OPT_IF3_DEBUG,
      OPT_IF4_DEBUG             => OPT_IF4_DEBUG,
      OPT_IF5_DEBUG             => OPT_IF5_DEBUG,
      OPT_IF6_DEBUG             => OPT_IF6_DEBUG,
      OPT_IF7_DEBUG             => OPT_IF7_DEBUG,
      OPT_IF8_DEBUG             => OPT_IF8_DEBUG,
      OPT_IF9_DEBUG             => OPT_IF9_DEBUG,
      OPT_IF10_DEBUG            => OPT_IF10_DEBUG,
      OPT_IF11_DEBUG            => OPT_IF11_DEBUG,
      OPT_IF12_DEBUG            => OPT_IF12_DEBUG,
      OPT_IF13_DEBUG            => OPT_IF13_DEBUG,
      OPT_IF14_DEBUG            => OPT_IF14_DEBUG,
      OPT_IF15_DEBUG            => OPT_IF15_DEBUG,
      GEN_IF0_DEBUG             => GEN_IF0_DEBUG,
      GEN_IF1_DEBUG             => GEN_IF1_DEBUG,
      GEN_IF2_DEBUG             => GEN_IF2_DEBUG,
      GEN_IF3_DEBUG             => GEN_IF3_DEBUG,
      GEN_IF4_DEBUG             => GEN_IF4_DEBUG,
      GEN_IF5_DEBUG             => GEN_IF5_DEBUG,
      GEN_IF6_DEBUG             => GEN_IF6_DEBUG,
      GEN_IF7_DEBUG             => GEN_IF7_DEBUG,
      GEN_IF8_DEBUG             => GEN_IF8_DEBUG,
      GEN_IF9_DEBUG             => GEN_IF9_DEBUG,
      GEN_IF10_DEBUG            => GEN_IF10_DEBUG,
      GEN_IF11_DEBUG            => GEN_IF11_DEBUG,
      GEN_IF12_DEBUG            => GEN_IF12_DEBUG,
      GEN_IF13_DEBUG            => GEN_IF13_DEBUG,
      GEN_IF14_DEBUG            => GEN_IF14_DEBUG,
      GEN_IF15_DEBUG            => GEN_IF15_DEBUG,
      ARBITER_DEBUG             => ARBITER_DEBUG,
      ACCESS_DEBUG              => ACCESS_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- Cache Core
  -----------------------------------------------------------------------------
  
  CC: sc_cache_core
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG_BOOL,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- IP Specific.
      C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_GENERIC_PORTS       => C_NUM_GENERIC_PORTS,
      C_NUM_PORTS               => C_NUM_PORTS,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON,
      C_NUM_SETS                => C_NUM_SETS,
      C_NUM_SERIAL_SETS         => C_NUM_SERIAL_SETS,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      C_ID_WIDTH                => C_ID_WIDTH,
      
      -- Data type and settings specific.
      C_LRU_ADDR_BITS           => C_LRU_ADDR_BITS,
      C_TAG_SIZE                => C_TAG_SIZE,
      C_NUM_STATUS_BITS         => C_NUM_STATUS_BITS,
      C_DSID_WIDTH              => C_DSID_WIDTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_CACHE_DATA_ADDR_WIDTH   => C_CACHE_DATA_ADDR_WIDTH,
      C_EXTERNAL_DATA_WIDTH     => C_EXTERNAL_DATA_WIDTH,
      C_EXTERNAL_DATA_ADDR_WIDTH=> C_EXTERNAL_DATA_ADDR_WIDTH,
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_POS'high,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_POS'low,
      C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
      C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
      C_ADDR_EXT_DATA_HI        => C_ADDR_EXT_DATA_POS'high,
      C_ADDR_EXT_DATA_LO        => C_ADDR_EXT_DATA_POS'low,
      C_ADDR_DATA_HI            => C_ADDR_DATA_POS'high,
      C_ADDR_DATA_LO            => C_ADDR_DATA_POS'low,
      C_ADDR_TAG_HI             => C_ADDR_TAG_POS'high,
      C_ADDR_TAG_LO             => C_ADDR_TAG_POS'low,
      C_ADDR_FULL_LINE_HI       => C_ADDR_FULL_LINE_POS'high,
      C_ADDR_FULL_LINE_LO       => C_ADDR_FULL_LINE_POS'low,
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_EXT_WORD_HI        => C_ADDR_EXT_WORD_POS'high,
      C_ADDR_EXT_WORD_LO        => C_ADDR_EXT_WORD_POS'low,
      C_ADDR_WORD_HI            => C_ADDR_WORD_POS'high,
      C_ADDR_WORD_LO            => C_ADDR_WORD_POS'low,
      C_ADDR_EXT_BYTE_HI        => C_ADDR_EXT_BYTE_POS'high,
      C_ADDR_EXT_BYTE_LO        => C_ADDR_EXT_BYTE_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      C_SET_BIT_HI              => C_SET_BIT_POS'high,
      C_SET_BIT_LO              => C_SET_BIT_POS'low
    )
    port map (
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      => ACLK,
      ARESET                    => ARESET,
      
      -- ---------------------------------------------------
      -- Access signals.
      
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
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      => lookup_read_data_new,
      lookup_read_data_hit      => lookup_read_data_hit,
      lookup_read_data_snoop    => lookup_read_data_snoop,
      lookup_read_data_allocate => lookup_read_data_allocate,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     => read_info_almost_full,
      read_info_full            => read_info_full,
      read_data_hit_pop         => read_data_hit_pop,
      read_data_hit_almost_full => read_data_hit_almost_full,
      read_data_hit_full        => read_data_hit_full,
      read_data_hit_fit         => read_data_hit_fit,
      read_data_miss_full       => read_data_miss_full,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Access).
      
      lookup_piperun            => lookup_piperun,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Frontend).
      
      
      lookup_read_data_valid    => lookup_read_data_valid,
      lookup_read_data_last     => lookup_read_data_last,
      lookup_read_data_resp     => lookup_read_data_resp,
      lookup_read_data_set      => lookup_read_data_set,
      lookup_read_data_word     => lookup_read_data_word,
      
      lookup_write_data_ready   => lookup_write_data_ready,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Arbiter).
      
      lookup_read_done          => lookup_read_done,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Frontend).
      
      -- Read miss
      update_read_data_valid    => update_read_data_valid,
      update_read_data_last     => update_read_data_last,
      update_read_data_resp     => update_read_data_resp,
      update_read_data_word     => update_read_data_word,
      update_read_data_ready    => update_read_data_ready,
      
      -- Write Miss
      update_write_data_ready   => update_write_data_ready,
      
      -- Write miss response
      update_ext_bresp_valid    => update_ext_bresp_valid,
      update_ext_bresp          => update_ext_bresp,
      update_ext_bresp_ready    => update_ext_bresp_ready,
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push    => update_auto_clean_push,
      update_auto_clean_addr    => update_auto_clean_addr,
      update_auto_clean_DSid    => update_auto_clean_DSid,
      
      -- ---------------------------------------------------
      -- Update signals (to Backend).
      
      read_req_valid            => read_req_valid,
      read_req_port             => read_req_port,
      read_req_addr             => read_req_addr,
      read_req_len              => read_req_len,
      read_req_size             => read_req_size,
      read_req_exclusive        => read_req_exclusive,
      read_req_kind             => read_req_kind,
      read_req_ready            => read_req_ready,
      read_req_DSid             => read_req_DSid,
      
      write_req_valid           => write_req_valid,
      write_req_port            => write_req_port,
      write_req_internal        => write_req_internal,
      write_req_addr            => write_req_addr,
      write_req_len             => write_req_len,
      write_req_size            => write_req_size,
      write_req_exclusive       => write_req_exclusive,
      write_req_kind            => write_req_kind,
      write_req_line_only       => write_req_line_only,
      write_req_ready           => write_req_ready,
      write_req_DSid            => write_req_DSid,
      
      write_data_valid          => write_data_valid,
      write_data_last           => write_data_last,
      write_data_be             => write_data_be,
      write_data_word           => write_data_word,
      write_data_ready          => write_data_ready,
      write_data_almost_full    => write_data_almost_full,
      write_data_full           => write_data_full,
      
      
      -- ---------------------------------------------------
      -- Backend signals.
      
      backend_wr_resp_valid     => backend_wr_resp_valid,
      backend_wr_resp_port      => backend_wr_resp_port,
      backend_wr_resp_internal  => backend_wr_resp_internal,
      backend_wr_resp_addr      => backend_wr_resp_addr,
      backend_wr_resp_bresp     => backend_wr_resp_bresp,
      backend_wr_resp_ready     => backend_wr_resp_ready,
      
      backend_rd_data_valid     => backend_rd_data_valid,
      backend_rd_data_last      => backend_rd_data_last,
      backend_rd_data_word      => backend_rd_data_word,
      backend_rd_data_rresp     => backend_rd_data_rresp,
      backend_rd_data_ready     => backend_rd_data_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      => stat_reset,
      stat_enable                     => stat_enable,
      
      -- Lookup
      stat_lu_opt_write_hit           => stat_lu_opt_write_hit,
      stat_lu_opt_write_miss          => stat_lu_opt_write_miss,
      stat_lu_opt_write_miss_dirty    => stat_lu_opt_write_miss_dirty,
      stat_lu_opt_read_hit            => stat_lu_opt_read_hit,
      stat_lu_opt_read_miss           => stat_lu_opt_read_miss,
      stat_lu_opt_read_miss_dirty     => stat_lu_opt_read_miss_dirty,
      stat_lu_opt_locked_write_hit    => stat_lu_opt_locked_write_hit,
      stat_lu_opt_locked_read_hit     => stat_lu_opt_locked_read_hit,
      stat_lu_opt_first_write_hit     => stat_lu_opt_first_write_hit,
      
      stat_lu_gen_write_hit           => stat_lu_gen_write_hit,
      stat_lu_gen_write_miss          => stat_lu_gen_write_miss,
      stat_lu_gen_write_miss_dirty    => stat_lu_gen_write_miss_dirty,
      stat_lu_gen_read_hit            => stat_lu_gen_read_hit,
      stat_lu_gen_read_miss           => stat_lu_gen_read_miss,
      stat_lu_gen_read_miss_dirty     => stat_lu_gen_read_miss_dirty,
      stat_lu_gen_locked_write_hit    => stat_lu_gen_locked_write_hit,
      stat_lu_gen_locked_read_hit     => stat_lu_gen_locked_read_hit,
      stat_lu_gen_first_write_hit     => stat_lu_gen_first_write_hit,
      
      stat_lu_stall                   => stat_lu_stall,
      stat_lu_fetch_stall             => stat_lu_fetch_stall,
      stat_lu_mem_stall               => stat_lu_mem_stall,
      stat_lu_data_stall              => stat_lu_data_stall,
      stat_lu_data_hit_stall          => stat_lu_data_hit_stall,
      stat_lu_data_miss_stall         => stat_lu_data_miss_stall,
      
      -- Update
      stat_ud_stall                   => stat_ud_stall,
      stat_ud_tag_free                => stat_ud_tag_free,
      stat_ud_data_free               => stat_ud_data_free,
      stat_ud_ri                      => stat_ud_ri,
      stat_ud_r                       => stat_ud_r,
      stat_ud_e                       => stat_ud_e,
      stat_ud_bs                      => stat_ud_bs,
      stat_ud_wm                      => stat_ud_wm,
      stat_ud_wma                     => stat_ud_wma,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => cachecore_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      MEMORY_DEBUG1             => MEMORY_DEBUG1,
      MEMORY_DEBUG2             => MEMORY_DEBUG2,
      LOOKUP_DEBUG              => LOOKUP_DEBUG,
      UPDATE_DEBUG1             => UPDATE_DEBUG1,
      UPDATE_DEBUG2             => UPDATE_DEBUG2,

      --For PARD stab
      lookup_valid_to_stab              => lookup_valid_to_stab,
      lookup_DSid_to_stab               => lookup_DSid_to_stab,
      lookup_hit_to_stab 				=> lookup_hit_to_stab,
      lookup_miss_to_stab       		=> lookup_miss_to_stab,
      update_tag_en_to_stab             => update_tag_en_to_stab,
      update_tag_we_to_stab     		=> update_tag_we_to_stab,
      update_tag_old_DSid_vec_to_stab 	=> update_tag_old_DSid_vec_to_stab,
      update_tag_new_DSid_vec_to_stab 	=> update_tag_new_DSid_vec_to_stab,
      lru_history_en_to_ptab            => lru_history_en_to_ptab,
      lru_dsid_valid_to_ptab            => lru_dsid_valid_to_ptab,
      lru_dsid_to_ptab                  => lru_dsid_to_ptab,
      way_mask_from_ptab                => way_mask_from_ptab
    );
  
  
  -----------------------------------------------------------------------------
  -- Backend
  -----------------------------------------------------------------------------
  
  BE: sc_back_end
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG_BOOL,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_MEM_LAT_RD_DEPTH   => C_STAT_MEM_LAT_RD_DEPTH,
      C_STAT_MEM_LAT_WR_DEPTH   => C_STAT_MEM_LAT_WR_DEPTH,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,

      -- PARD specific.
      C_DSID_WIDTH              => C_DSID_WIDTH,
      
      -- IP Specific.
      C_BASEADDR                => C_BASEADDR,
      C_HIGHADDR                => C_HIGHADDR,
      C_NUM_PORTS               => C_NUM_PORTS,
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      C_EXTERNAL_DATA_WIDTH     => C_EXTERNAL_DATA_WIDTH,
      C_EXTERNAL_DATA_ADDR_WIDTH=> C_EXTERNAL_DATA_ADDR_WIDTH,
      C_OPTIMIZE_ORDER          => C_OPTIMIZE_ORDER,
      
      -- Data type and settings specific.
      C_ADDR_VALID_HI           => C_ADDR_VALID_POS'high,
      C_ADDR_VALID_LO           => C_ADDR_VALID_POS'low,
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_POS'high,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_POS'low,
      C_ADDR_TAG_CONTENTS_HI    => C_ADDR_TAG_CONTENTS_POS'high,
      C_ADDR_TAG_CONTENTS_LO    => C_ADDR_TAG_CONTENTS_POS'low,
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      
      -- AXI4 Master Interface specific.
      C_M_AXI_THREAD_ID_WIDTH   => C_M_AXI_THREAD_ID_WIDTH,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      C_M_AXI_ADDR_WIDTH        => C_M_AXI_ADDR_WIDTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      read_req_valid            => read_req_valid,
      read_req_port             => read_req_port,
      read_req_addr             => read_req_addr,
      read_req_len              => read_req_len,
      read_req_size             => read_req_size,
      read_req_exclusive        => read_req_exclusive,
      read_req_kind             => read_req_kind,
      read_req_ready            => read_req_ready,
      read_req_DSid             => read_req_DSid,
      
      write_req_valid           => write_req_valid,
      write_req_port            => write_req_port,
      write_req_internal        => write_req_internal,
      write_req_addr            => write_req_addr,
      write_req_len             => write_req_len,
      write_req_size            => write_req_size,
      write_req_exclusive       => write_req_exclusive,
      write_req_kind            => write_req_kind,
      write_req_line_only       => write_req_line_only,
      write_req_ready           => write_req_ready,
      write_req_DSid            => write_req_DSid,
      
      write_data_valid          => write_data_valid,
      write_data_last           => write_data_last,
      write_data_be             => write_data_be,
      write_data_word           => write_data_word,
      write_data_ready          => write_data_ready,
      write_data_almost_full    => write_data_almost_full,
      write_data_full           => write_data_full,
      
      
      -- ---------------------------------------------------
      -- Backend signals (to Update).
      
      backend_wr_resp_valid     => backend_wr_resp_valid,
      backend_wr_resp_port      => backend_wr_resp_port,
      backend_wr_resp_internal  => backend_wr_resp_internal,
      backend_wr_resp_addr      => backend_wr_resp_addr,
      backend_wr_resp_bresp     => backend_wr_resp_bresp,
      backend_wr_resp_ready     => backend_wr_resp_ready,
      
      backend_rd_data_valid     => backend_rd_data_valid,
      backend_rd_data_last      => backend_rd_data_last,
      backend_rd_data_word      => backend_rd_data_word,
      backend_rd_data_rresp     => backend_rd_data_rresp,
      backend_rd_data_ready     => backend_rd_data_ready,
  
      
      -- ---------------------------------------------------
      -- AXI4 Master Interface Signals.
      
      M_AXI_AWID                => M_AXI_AWID,
      M_AXI_AWADDR              => M_AXI_AWADDR,
      M_AXI_AWLEN               => M_AXI_AWLEN,
      M_AXI_AWSIZE              => M_AXI_AWSIZE,
      M_AXI_AWBURST             => M_AXI_AWBURST,
      M_AXI_AWLOCK              => M_AXI_AWLOCK,
      M_AXI_AWCACHE             => M_AXI_AWCACHE,
      M_AXI_AWPROT              => M_AXI_AWPROT,
      M_AXI_AWQOS               => M_AXI_AWQOS,
      M_AXI_AWVALID             => M_AXI_AWVALID,
      M_AXI_AWREADY             => M_AXI_AWREADY,
      M_AXI_AWUSER              => M_AXI_AWUSER,
      
      M_AXI_WDATA               => M_AXI_WDATA,
      M_AXI_WSTRB               => M_AXI_WSTRB,
      M_AXI_WLAST               => M_AXI_WLAST,
      M_AXI_WVALID              => M_AXI_WVALID,
      M_AXI_WREADY              => M_AXI_WREADY,
      
      M_AXI_BRESP               => M_AXI_BRESP,
      M_AXI_BID                 => M_AXI_BID,
      M_AXI_BVALID              => M_AXI_BVALID,
      M_AXI_BREADY              => M_AXI_BREADY,
      
      M_AXI_ARID                => M_AXI_ARID,
      M_AXI_ARADDR              => M_AXI_ARADDR,
      M_AXI_ARLEN               => M_AXI_ARLEN,
      M_AXI_ARSIZE              => M_AXI_ARSIZE,
      M_AXI_ARBURST             => M_AXI_ARBURST,
      M_AXI_ARLOCK              => M_AXI_ARLOCK,
      M_AXI_ARCACHE             => M_AXI_ARCACHE,
      M_AXI_ARPROT              => M_AXI_ARPROT,
      M_AXI_ARQOS               => M_AXI_ARQOS,
      M_AXI_ARVALID             => M_AXI_ARVALID,
      M_AXI_ARREADY             => M_AXI_ARREADY,
      M_AXI_ARUSER              => M_AXI_ARUSER,
      
      M_AXI_RID                 => M_AXI_RID,
      M_AXI_RDATA               => M_AXI_RDATA,
      M_AXI_RRESP               => M_AXI_RRESP,
      M_AXI_RLAST               => M_AXI_RLAST,
      M_AXI_RVALID              => M_AXI_RVALID,
      M_AXI_RREADY              => M_AXI_RREADY,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      -- Backend
      stat_be_aw                => stat_be_aw,
      stat_be_w                 => stat_be_w,
      stat_be_ar                => stat_be_ar,
      stat_be_ar_search_depth   => stat_be_ar_search_depth,
      stat_be_ar_stall          => stat_be_ar_stall,
      stat_be_ar_protect_stall  => stat_be_ar_protect_stall,
      stat_be_rd_latency        => stat_be_rd_latency,
      stat_be_wr_latency        => stat_be_wr_latency,
      stat_be_rd_latency_conf   => stat_be_rd_latency_conf,
      stat_be_wr_latency_conf   => stat_be_wr_latency_conf,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => backend_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      BACKEND_DEBUG             => BACKEND_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- Control port 
  -----------------------------------------------------------------------------
  
  AXI_Ctrl: sc_s_axi_ctrl_interface
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG_BOOL,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      C_ENABLE_CTRL             => C_ENABLE_CTRL,
      C_ENABLE_AUTOMATIC_CLEAN  => C_ENABLE_AUTOMATIC_CLEAN,
      C_AUTOMATIC_CLEAN_MODE    => C_AUTOMATIC_CLEAN_MODE,
      C_DSID_WIDTH			   => C_DSID_WIDTH,
      -- Data type and settings specific.
      C_ADDR_ALL_SETS_HI        => C_ADDR_ALL_SETS_POS'high,
      C_ADDR_ALL_SETS_LO        => C_ADDR_ALL_SETS_POS'low,
      
      -- IP Specific.
      C_ENABLE_STATISTICS       => C_ENABLE_STATISTICS,
      C_ENABLE_VERSION_REGISTER => C_ENABLE_VERSION_REGISTER,
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_GENERIC_PORTS       => C_NUM_GENERIC_PORTS,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EXCLUSIVE        => C_ENABLE_EXCLUSIVE,
      C_NUM_SETS                => C_NUM_SETS,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      C_CACHE_SIZE              => C_CACHE_SIZE,
      C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
      C_Lx_CACHE_SIZE           => C_Lx_CACHE_SIZE,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      
      -- AXI4 Interface Specific.
      C_S_AXI_CTRL_BASEADDR     => C_BASEADDR,
      C_S_AXI_CTRL_HIGHADDR     => C_HIGHADDR,
      C_S_AXI_CTRL_DATA_WIDTH   => C_S_AXI_CTRL_DATA_WIDTH,
      C_S_AXI_CTRL_ADDR_WIDTH   => C_S_AXI_CTRL_ADDR_WIDTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
      
      
      -- ---------------------------------------------------
      -- AXI4-Lite Slave Interface Signals
      
      -- AW-Channel
      S_AXI_CTRL_AWADDR         => S_AXI_CTRL_AWADDR,
      S_AXI_CTRL_AWVALID        => S_AXI_CTRL_AWVALID,
      S_AXI_CTRL_AWREADY        => S_AXI_CTRL_AWREADY,
  
      -- W-Channel
      S_AXI_CTRL_WDATA          => S_AXI_CTRL_WDATA,
      S_AXI_CTRL_WVALID         => S_AXI_CTRL_WVALID,
      S_AXI_CTRL_WREADY         => S_AXI_CTRL_WREADY,
  
      -- B-Channel
      S_AXI_CTRL_BRESP          => S_AXI_CTRL_BRESP,
      S_AXI_CTRL_BVALID         => S_AXI_CTRL_BVALID,
      S_AXI_CTRL_BREADY         => S_AXI_CTRL_BREADY,
  
      -- AR-Channel
      S_AXI_CTRL_ARADDR         => S_AXI_CTRL_ARADDR,
      S_AXI_CTRL_ARVALID        => S_AXI_CTRL_ARVALID,
      S_AXI_CTRL_ARREADY        => S_AXI_CTRL_ARREADY,
  
      -- R-Channel
      S_AXI_CTRL_RDATA          => S_AXI_CTRL_RDATA,
      S_AXI_CTRL_RRESP          => S_AXI_CTRL_RRESP,
      S_AXI_CTRL_RVALID         => S_AXI_CTRL_RVALID,
      S_AXI_CTRL_RREADY         => S_AXI_CTRL_RREADY,
  
      
      -- ---------------------------------------------------
      -- Control If Transactions.
      
      ctrl_init_done            => ctrl_init_done,
      ctrl_access               => ctrl_access,
      ctrl_ready                => ctrl_ready,
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push    => update_auto_clean_push,
      update_auto_clean_addr    => update_auto_clean_addr,
      update_auto_clean_DSid    => update_auto_clean_DSid,
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      => stat_reset,
      stat_enable                     => stat_enable,
      
      -- Optimized ports.
      stat_s_axi_rd_segments          => stat_s_axi_rd_segments,
      stat_s_axi_wr_segments          => stat_s_axi_wr_segments,
      stat_s_axi_rip                  => stat_s_axi_rip,
      stat_s_axi_r                    => stat_s_axi_r,
      stat_s_axi_bip                  => stat_s_axi_bip,
      stat_s_axi_bp                   => stat_s_axi_bp,
      stat_s_axi_wip                  => stat_s_axi_wip,
      stat_s_axi_w                    => stat_s_axi_w,
      stat_s_axi_rd_latency           => stat_s_axi_rd_latency,
      stat_s_axi_wr_latency           => stat_s_axi_wr_latency,
      stat_s_axi_rd_latency_conf      => stat_s_axi_rd_latency_conf,
      stat_s_axi_wr_latency_conf      => stat_s_axi_wr_latency_conf,
  
      -- Generic ports.
      stat_s_axi_gen_rd_segments      => stat_s_axi_gen_rd_segments,
      stat_s_axi_gen_wr_segments      => stat_s_axi_gen_wr_segments,
      stat_s_axi_gen_rip              => stat_s_axi_gen_rip,
      stat_s_axi_gen_r                => stat_s_axi_gen_r,
      stat_s_axi_gen_bip              => stat_s_axi_gen_bip,
      stat_s_axi_gen_bp               => stat_s_axi_gen_bp,
      stat_s_axi_gen_wip              => stat_s_axi_gen_wip,
      stat_s_axi_gen_w                => stat_s_axi_gen_w,
      stat_s_axi_gen_rd_latency       => stat_s_axi_gen_rd_latency,
      stat_s_axi_gen_wr_latency       => stat_s_axi_gen_wr_latency,
      stat_s_axi_gen_rd_latency_conf  => stat_s_axi_gen_rd_latency_conf,
      stat_s_axi_gen_wr_latency_conf  => stat_s_axi_gen_wr_latency_conf,
      
      -- Arbiter
      stat_arb_valid                  => stat_arb_valid,
      stat_arb_concurrent_accesses    => stat_arb_concurrent_accesses,
      stat_arb_opt_read_blocked       => stat_arb_opt_read_blocked,
      stat_arb_gen_read_blocked       => stat_arb_gen_read_blocked,
      
      -- Access
      stat_access_valid               => stat_access_valid,
      stat_access_stall               => stat_access_stall,
      stat_access_fetch_stall         => stat_access_fetch_stall,
      stat_access_req_stall           => stat_access_req_stall,
      stat_access_act_stall           => stat_access_act_stall,
      
      -- Lookup
      stat_lu_opt_write_hit           => stat_lu_opt_write_hit,
      stat_lu_opt_write_miss          => stat_lu_opt_write_miss,
      stat_lu_opt_write_miss_dirty    => stat_lu_opt_write_miss_dirty,
      stat_lu_opt_read_hit            => stat_lu_opt_read_hit,
      stat_lu_opt_read_miss           => stat_lu_opt_read_miss,
      stat_lu_opt_read_miss_dirty     => stat_lu_opt_read_miss_dirty,
      stat_lu_opt_locked_write_hit    => stat_lu_opt_locked_write_hit,
      stat_lu_opt_locked_read_hit     => stat_lu_opt_locked_read_hit,
      stat_lu_opt_first_write_hit     => stat_lu_opt_first_write_hit,
      
      stat_lu_gen_write_hit           => stat_lu_gen_write_hit,
      stat_lu_gen_write_miss          => stat_lu_gen_write_miss,
      stat_lu_gen_write_miss_dirty    => stat_lu_gen_write_miss_dirty,
      stat_lu_gen_read_hit            => stat_lu_gen_read_hit,
      stat_lu_gen_read_miss           => stat_lu_gen_read_miss,
      stat_lu_gen_read_miss_dirty     => stat_lu_gen_read_miss_dirty,
      stat_lu_gen_locked_write_hit    => stat_lu_gen_locked_write_hit,
      stat_lu_gen_locked_read_hit     => stat_lu_gen_locked_read_hit,
      stat_lu_gen_first_write_hit     => stat_lu_gen_first_write_hit,
      
      stat_lu_stall                   => stat_lu_stall,
      stat_lu_fetch_stall             => stat_lu_fetch_stall,
      stat_lu_mem_stall               => stat_lu_mem_stall,
      stat_lu_data_stall              => stat_lu_data_stall,
      stat_lu_data_hit_stall          => stat_lu_data_hit_stall,
      stat_lu_data_miss_stall         => stat_lu_data_miss_stall,
      
      -- Update
      stat_ud_stall                   => stat_ud_stall,
      stat_ud_tag_free                => stat_ud_tag_free,
      stat_ud_data_free               => stat_ud_data_free,
      stat_ud_ri                      => stat_ud_ri,
      stat_ud_r                       => stat_ud_r,
      stat_ud_e                       => stat_ud_e,
      stat_ud_bs                      => stat_ud_bs,
      stat_ud_wm                      => stat_ud_wm,
      stat_ud_wma                     => stat_ud_wma,
      
      -- Backend
      stat_be_aw                      => stat_be_aw,
      stat_be_w                       => stat_be_w,
      stat_be_ar                      => stat_be_ar,
      stat_be_ar_search_depth         => stat_be_ar_search_depth,
      stat_be_ar_stall                => stat_be_ar_stall,
      stat_be_ar_protect_stall        => stat_be_ar_protect_stall,
      stat_be_rd_latency              => stat_be_rd_latency,
      stat_be_wr_latency              => stat_be_wr_latency,
      stat_be_rd_latency_conf         => stat_be_rd_latency_conf,
      stat_be_wr_latency_conf         => stat_be_wr_latency_conf,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      IF_DEBUG                  => CTRL_IF_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- Disabled signals
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Performance monitor
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect behaviour
  
  Assertions: block
  begin
    -- Detect condition
    assert_err(C_ASSERT_FRONTEND_ERROR)   <= frontend_assert  when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_CACHECORE_ERROR)  <= cachecore_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_BACKEND_ERROR)    <= backend_assert   when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_FRONTEND_ERROR) /= '1' 
      report "System Cache: Frontend module error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_CACHECORE_ERROR) /= '1' 
      report "System Cache: Cache Core module error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BACKEND_ERROR) /= '1' 
      report "System Cache: Backend module error."
        severity error;
    
    -- pragma translate_on
  end block Assertions;
  
  
  -- Clocked to remove glites in simulation
  Delay_Assertions : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      assert_err_1  <= assert_err;
    end if;
  end process Delay_Assertions;
  
  
end architecture IMP;
