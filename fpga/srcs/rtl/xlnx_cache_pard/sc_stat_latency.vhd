-------------------------------------------------------------------------------
-- sc_stat_latency.vhd - Entity and architecture
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
-- Filename:        sc_stat_latency.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_stat_latency.vhd
--
-------------------------------------------------------------------------------
-- Author:          rikardw
--
-- History:
--   rikardw  2006-10-19    First Version
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

entity sc_stat_latency is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    
    -- Configuration.
    C_STAT_LATENCY_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_LATENCY_WR_DEPTH   : natural range  1 to   32      := 16;
    C_STAT_BITS               : natural range  1 to   64      := 32;
    C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
    C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
    C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
    C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0
  );
  port (
    -- ---------------------------------------------------
    -- Common Signals
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Counter Interface
    
    ar_start                  : in  std_logic;
    ar_ack                    : in  std_logic;
    rd_valid                  : in  std_logic;
    rd_last                   : in  std_logic;
    aw_start                  : in  std_logic;
    aw_ack                    : in  std_logic;
    wr_valid                  : in  std_logic;
    wr_last                   : in  std_logic;
    wr_resp                   : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_enable               : in  std_logic;
    
    stat_rd_latency           : out STAT_POINT_TYPE;    -- External Read Latency
    stat_wr_latency           : out STAT_POINT_TYPE;    -- External Write Latency
    stat_rd_latency_conf      : in  STAT_CONF_TYPE;     -- External Read Latency Configuration
    stat_wr_latency_conf      : in  STAT_CONF_TYPE      -- External Write Latency Configuration
  );
end entity sc_stat_latency;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_stat_latency is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_statistics_counters is
    generic (
      -- Module implementation generics
      C_ACCESS_COUNTER_WIDTH : integer range 1 to 64 := 32;
      C_CYCLE_COUNTER_WIDTH  : integer range 1 to 64 := 48;
      C_USE_STDDEV           : integer range 0 to 1  :=  0;
      C_PIPELINE_DEPTH       : integer range 1 to 32 :=  1;
      C_MAX_CYCLE_WIDTH      : integer range 2 to 16 :=  8;
      C_SIMPLE_COUNTER       : boolean := false
    );
    port (
      CLK            : in  std_logic;
      Rst            : in  std_logic;
  
      -- Access signals
      Access_Request : in  std_logic;
      Access_Ready   : in  std_logic;
      Access_Active  : in  std_logic;
      Access_ActiveN : in  std_logic;
      Access_Valid   : in  std_logic;
      Access_Abort   : in  std_logic;
  
      Pause          : in  std_logic;
      Clear          : in  std_logic;
  
      Is_Running     : out std_logic;
      Is_Stopped     : out std_logic;
  
      Min_Max_Status : out STAT_TYPE;
      Access_Count   : out STAT_TYPE;
      Cycle_Count    : out STAT_TYPE;
      Cycle_Count_2  : out STAT_TYPE
    );
  end component sc_statistics_counters;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Statistics Control
  
  signal Rd_Access_Request        : std_logic;
  signal Rd_Access_Ready          : std_logic;
  signal Wr_Access_Request        : std_logic;
  signal Wr_Access_Ready          : std_logic;
  
  signal rd_first                 : std_logic;
  signal wr_first                 : std_logic;
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Statistics Control
  -----------------------------------------------------------------------------
  
  Detect_Handler : process (ACLK) is
  begin  -- process Detect_Handler
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        Rd_Access_Request <= '0';
        Rd_Access_Ready   <= '0';
        Wr_Access_Request <= '0';
        Wr_Access_Ready   <= '0';
        
        rd_first          <= '1';
        wr_first          <= '1';
        
      else
        -- Simple start.
        if( ( stat_rd_latency_conf(C_RD_LATENCY_POS) = C_STAT_RD_LATENCY_VALID ) or
            ( stat_rd_latency_conf(C_RD_LATENCY_POS) = C_STAT_RD_LATENCY_LAST  ) ) then 
          Rd_Access_Request <= stat_enable and ar_start;
        else 
          Rd_Access_Request <= stat_enable and ar_ack;
        end if;
        if( ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_VALID ) or 
            ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_LAST  ) or 
            ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_BRESP ) )then 
          Wr_Access_Request <= stat_enable and aw_start;
        else 
          Wr_Access_Request <= stat_enable and aw_ack;
        end if;
        
        -- Select end point.
        if( ( stat_rd_latency_conf(C_RD_LATENCY_POS) = C_STAT_RD_LATENCY_VALID     ) or
            ( stat_rd_latency_conf(C_RD_LATENCY_POS) = C_STAT_RD_LATENCY_ACK_VALID ) ) then 
          Rd_Access_Ready   <= stat_enable and rd_valid and rd_first;
        else 
          Rd_Access_Ready   <= stat_enable and rd_last;
        end if;
        
        if( ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_VALID     ) or 
            ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_ACK_VALID ) )then 
          Wr_Access_Ready   <= stat_enable and wr_valid and wr_first;
        elsif( ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_LAST     ) or 
               ( stat_wr_latency_conf(C_WR_LATENCY_POS) = C_STAT_WR_LATENCY_ACK_LAST ) ) then 
          Wr_Access_Ready   <= stat_enable and wr_last;
        else 
          Wr_Access_Ready   <= stat_enable and wr_resp;
        end if;
        
        -- Keep track of transaction.
        if( rd_valid = '1' ) then
          rd_first          <= rd_last;
        end if;
        if( wr_valid = '1' ) then
          wr_first          <= wr_last;
        end if;
        
      end if;
    end if;
  end process Detect_Handler;
  
  
  -----------------------------------------------------------------------------
  -- Statistics Count
  -----------------------------------------------------------------------------
  
  Rd_Inst: sc_statistics_counters
    generic map(
      -- Module implementation generics
      C_ACCESS_COUNTER_WIDTH  => C_STAT_BITS,
      C_CYCLE_COUNTER_WIDTH   => C_STAT_BIG_BITS,
      C_USE_STDDEV            => C_STAT_USE_STDDEV,
      C_PIPELINE_DEPTH        => C_STAT_LATENCY_RD_DEPTH,
      C_MAX_CYCLE_WIDTH       => C_STAT_MAX_CYCLE_WIDTH,
      C_SIMPLE_COUNTER        => false
    )
    port map(
      CLK                     => ACLK,
      Rst                     => ARESET,
  
      -- Access signals
      Access_Request          => Rd_Access_Request,
      Access_Ready            => Rd_Access_Ready,
      Access_Active           => '1',
      Access_ActiveN          => '0',
      Access_Valid            => '1',
      Access_Abort            => '0',
  
      Pause                   => '0',
      Clear                   => '0',
  
      Is_Running              => open,
      Is_Stopped              => open,
  
      Min_Max_Status          => stat_rd_latency.Min_Max_Status,
      Access_Count            => stat_rd_latency.Events,
      Cycle_Count             => stat_rd_latency.Sum,
      Cycle_Count_2           => stat_rd_latency.Sum_2
    );
  
  Wr_Inst: sc_statistics_counters
    generic map(
      -- Module implementation generics
      C_ACCESS_COUNTER_WIDTH  => C_STAT_BITS,
      C_CYCLE_COUNTER_WIDTH   => C_STAT_BIG_BITS,
      C_USE_STDDEV            => C_STAT_USE_STDDEV,
      C_PIPELINE_DEPTH        => C_STAT_LATENCY_WR_DEPTH,
      C_MAX_CYCLE_WIDTH       => C_STAT_MAX_CYCLE_WIDTH,
      C_SIMPLE_COUNTER        => false
    )
    port map(
      CLK                     => ACLK,
      Rst                     => ARESET,
  
      -- Access signals
      Access_Request          => Wr_Access_Request,
      Access_Ready            => Wr_Access_Ready,
      Access_Active           => '1',
      Access_ActiveN          => '0',
      Access_Valid            => '1',
      Access_Abort            => '0',
  
      Pause                   => '0',
      Clear                   => '0',
  
      Is_Running              => open,
      Is_Stopped              => open,
  
      Min_Max_Status          => stat_wr_latency.Min_Max_Status,
      Access_Count            => stat_wr_latency.Events,
      Cycle_Count             => stat_wr_latency.Sum,
      Cycle_Count_2           => stat_wr_latency.Sum_2
    );
  
  
end architecture IMP;


