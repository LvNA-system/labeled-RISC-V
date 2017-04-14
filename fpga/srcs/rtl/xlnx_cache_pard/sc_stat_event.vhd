-------------------------------------------------------------------------------
-- sc_stat_event.vhd - Entity and architecture
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
-- Filename:        sc_stat_event.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_stat_event.vhd
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
use work.system_cache_queue_pkg.all;

entity sc_stat_event is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    
    -- Configuration.
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
    -- Probe Interface
    
    probe                     : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_enable               : in  std_logic;
    
    stat_data                 : out STAT_POINT_TYPE
  );
end entity sc_stat_event;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_stat_event is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_stat_counter is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      
      -- Configuration.
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
      
      update                    : in  std_logic;
      counter                   : in  std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_enable               : in  std_logic;
      
      stat_data                 : out STAT_POINT_TYPE
    );
  end component sc_stat_counter;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Statistics
  
  signal probe_d1                 : std_logic;
  signal probe_d2                 : std_logic;
  signal probe_fall_edge          : std_logic;
  
  signal num_cycles               : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
  
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Detection
  -----------------------------------------------------------------------------
  
  Detect_Handler : process (ACLK) is
  begin  -- process Detect_Handler
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        probe_d1    <= '0';
        probe_d2    <= '0';
        num_cycles  <= (others=>'0');
        
      else
        probe_d1    <= probe;
        probe_d2    <= probe_d1;
        
        if( probe_d1 = '1' ) then
          num_cycles  <= std_logic_vector(unsigned(num_cycles) + 1);
        else
          num_cycles  <= (others=>'0');
        end if;
        
      end if;
    end if;
  end process Detect_Handler;
  
  probe_fall_edge  <= (not probe_d1) and probe_d2;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  CNT_INST: sc_stat_counter
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      
      -- Configuration.
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV
    )
    port map(
      -- ---------------------------------------------------
      -- Common Signals
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Counter Interface
      
      update                    => probe_fall_edge,
      counter                   => num_cycles,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_enable               => stat_enable,
      
      stat_data                 => stat_data
    );
  
  
end architecture IMP;


