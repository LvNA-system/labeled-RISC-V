-------------------------------------------------------------------------------
-- sc_stat_counter.vhd - Entity and architecture
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
-- Filename:        sc_stat_counter.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_stat_counter.vhd
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

entity sc_stat_counter is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    
    -- Configuration.
    C_STAT_SIMPLE_COUNTER     : natural range  0 to    1      :=  0;
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
end entity sc_stat_counter;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_stat_counter is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Statistics
  
  signal counter_2                : std_logic_vector(2 * C_STAT_COUNTER_BITS - 1 downto 0);
  signal counter_events_i         : std_logic_vector(C_STAT_BITS             - 1 downto 0);
  signal counter_i                : std_logic_vector(C_STAT_COUNTER_BITS     - 1 downto 0);
  signal counter_min_i            : std_logic_vector(C_STAT_COUNTER_BITS     - 1 downto 0);
  signal counter_max_i            : std_logic_vector(C_STAT_COUNTER_BITS     - 1 downto 0);
  signal counter_sum_i            : std_logic_vector(C_STAT_BIG_BITS         - 1 downto 0);
  
  signal update_d1                : std_logic;
  signal counter_2_d1             : std_logic_vector(2 * C_STAT_COUNTER_BITS - 1 downto 0);
  signal counter_sum_2_i          : std_logic_vector(C_STAT_BIG_BITS         - 1 downto 0);
  
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  Gen_Simple: if( C_STAT_SIMPLE_COUNTER /= 0 ) generate
  begin
    counter_i <= std_logic_vector(to_unsigned(1, counter_i'length));
    counter_2 <= std_logic_vector(to_unsigned(1, counter_2'length));
  end generate Gen_Simple;
  Not_Simple: if( C_STAT_SIMPLE_COUNTER = 0 ) generate
  begin
    counter_i <= counter;
    -- Generate Counter^2.
    counter_2 <= std_logic_vector( unsigned(counter) * unsigned(counter) );
  end generate Not_Simple;
  
  Statistics_Handler : process (ACLK) is
  begin  -- process Statistics_Handler
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        counter_events_i  <= (others=>'0');
        counter_min_i     <= (others=>'1');
        counter_max_i     <= (others=>'0');
        counter_sum_i     <= (others=>'0');
        
      elsif( ( stat_enable and update ) = '1' ) then
        -- Event counter.
        counter_events_i  <= std_logic_vector(unsigned(counter_events_i) + 1);
        
        if( C_STAT_SIMPLE_COUNTER = 0 ) then
          -- Detect Minimum.
          if ( unsigned(counter_i) < unsigned(counter_min_i) ) then
            counter_min_i                 <= (others=>'0');
            counter_min_i(counter'range)  <= counter_i;
          end if;
          
          -- Detect Maximum.
          if ( unsigned(counter_i) > unsigned(counter_max_i) ) then
            counter_max_i                 <= (others=>'0');
            counter_max_i(counter'range)  <= counter_i;
          end if;
        else
          counter_min_i     <= (others=>'1');
          counter_max_i     <= (others=>'0');
        end if;
        
        -- Sum of all counter events.
        counter_sum_i     <= std_logic_vector(unsigned(counter_sum_i)   + unsigned(counter_i));
        
      end if;
    end if;
  end process Statistics_Handler;
  
  Delayed_Statistics_Handler : process (ACLK) is
  begin  -- process Delayed_Statistics_Handler
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        update_d1         <= '0';
        counter_2_d1      <= (others=>'0');     
        counter_sum_2_i   <= (others=>'0');
        
      else
        update_d1         <= stat_enable and update;
        counter_2_d1      <= counter_2;
        
        if( update_d1 = '1' ) then
          -- Sum of all counter events.
          if( C_STAT_USE_STDDEV /= 0 ) then
            counter_sum_2_i   <= std_logic_vector(unsigned(counter_sum_2_i) + 
                                                  unsigned(counter_2_d1(C_STAT_COUNTER_BITS - 1 downto 0)));
          else
            counter_sum_2_i   <= (others=>'0');
          end if;
          
        end if;
      end if;
    end if;
  end process Delayed_Statistics_Handler;
  
  -- Assign outputs.
  Assign_Output : process (counter_events_i, counter_min_i, counter_max_i, counter_sum_i, counter_sum_2_i) is
  begin  -- process Assign_Output
    -- Default.
    stat_data.Events          <= (others=>'0');
    stat_data.Min_Max_Status  <= (others=>'0');
    stat_data.Sum             <= (others=>'0');
    stat_data.Sum_2           <= (others=>'0');
    
    stat_data.Events(C_STAT_BITS    - 1 downto 0)                                           <= counter_events_i;
    stat_data.Min_Max_Status(C_STAT_MIN_LO + C_STAT_COUNTER_BITS - 1 downto C_STAT_MIN_LO)  <= counter_min_i;
    stat_data.Min_Max_Status(C_STAT_MAX_LO + C_STAT_COUNTER_BITS - 1 downto C_STAT_MAX_LO)  <= counter_max_i;
    stat_data.Min_Max_Status(C_STAT_FULL_POS)                                               <= '0';
    stat_data.Min_Max_Status(C_STAT_OVERFLOW_POS)                                           <= '0';
    stat_data.Sum(C_STAT_BIG_BITS   - 1 downto 0)                                           <= counter_sum_i;
    stat_data.Sum_2(C_STAT_BIG_BITS - 1 downto 0)                                           <= counter_sum_2_i;
    
  end process Assign_Output;
  
end architecture IMP;


