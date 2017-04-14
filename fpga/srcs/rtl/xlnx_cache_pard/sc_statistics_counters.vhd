-------------------------------------------------------------------------------
-- sc_statistics_counters.vhd - Entity and architecture
--
--  ***************************************************************************
--  **  Copyright(C) 2008 by Xilinx, Inc. All rights reserved.               **
--  **                                                                       **
--  **  This text contains proprietary, confidential                         **
--  **  information of Xilinx, Inc. , is distributed by                      **
--  **  under license from Xilinx, Inc., and may be used,                    **
--  **  copied and/or disclosed only pursuant to the terms                   **
--  **  of a valid license agreement with Xilinx, Inc.                       **
--  **                                                                       **
--  **  Unmodified source code is guaranteed to place and route,             **
--  **  function and run at speed according to the datasheet                 **
--  **  specification. Source code is provided "as-is", with no              **
--  **  obligation on the part of Xilinx to provide support.                 **
--  **                                                                       **
--  **  Xilinx Hotline support of source code IP shall only include          **
--  **  standard level Xilinx Hotline support, and will only address         **
--  **  issues and questions related to the standard released Netlist        **
--  **  version of the core (and thus indirectly, the original core source). **
--  **                                                                       **
--  **  The Xilinx Support Hotline does not have access to source            **
--  **  code and therefore cannot answer specific questions related          **
--  **  to source HDL. The Xilinx Support Hotline will only be able          **
--  **  to confirm the problem in the Netlist version of the core.           **
--  **                                                                       **
--  **  This copyright and support notice must be retained as part           **
--  **  of this text at all times.                                           **
--  ***************************************************************************
--
-------------------------------------------------------------------------------
-- Filename:        sc_statistics_counters.vhd
--
-- Description:     
--    Use ring of counters: 1, 2, 4, 8, 16, 32 ...
--      lastCounterIndex indicates the counter to start
--      firstCounterIndex indicates the counter to stop
--
--    xpsl assume always Running -> eventually Stopping;
--    xpsl assume never Running and Stopping;
--
--    if Starting and not full then
--      start counter(lastCounterIndex);
--      lastCounterIndex <= lastCounterIndex + 1;
--      if lastCounterIndex = firstCounterIndex then
--        full <= true;
--      end if;
--    end if;
--    if Ending then
--      if lastCounterIndex = firstCounterIndex and not full then
--        empty <= true;
--      else
--        stop counter(firstCounterIndex);
--        update statistics(firstCounterIndex);
--        firstCounterIndex <= firstCounterIndex + 1;
--      end if;
--    end if;
--
--    if updateStatistics then
--      counterValue        <= counter(firstCounterIndex);
--      totalAccesses       <= totalAccesses + 1;
--      accessCycles        <= accessCycles + counterValue;
--      accessCyclesSquared <= accessCyclesSquared +
--                                counterValue * counterValue;
--      if maxAccessLength < counterValue then
--        maxAccessLength   <= counterValue;
--      end if;
--    end if;
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_statistics_counters.vhd
--
-------------------------------------------------------------------------------
-- Author:          stefana
--
-- History:
--   stefana  2008-07-28    First Version
--   stefana  2008-11-10    Added simple counters
--   stefana  2009-03-02    Increased width of access counter
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

library work;
use work.system_cache_pkg.all;

entity sc_statistics_counters is
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
end entity sc_statistics_counters;

library IEEE;
use IEEE.numeric_std.all;

library work;
use work.system_cache_pkg.all;

architecture IMP of sc_statistics_counters is

  -- log2 function returns the number of bits required to encode x choices
  function log2(x : natural) return integer is
    variable i  : integer := 0;   
  begin 
    if x = 0 then return 0;
    else
      while 2**i < x loop
        i := i+1;
      end loop;
      return i;
    end if;
  end function log2;
  
  subtype Cycle_Type    is std_logic_vector(0 to C_MAX_CYCLE_WIDTH - 1);
  subtype Power_Type    is std_logic_vector(0 to 2*C_MAX_CYCLE_WIDTH - 1);
  subtype Counter_Type  is std_logic_vector(0 to C_CYCLE_COUNTER_WIDTH - 1);
  subtype Index_Type    is integer range 0 to C_PIPELINE_DEPTH - 1;
  subtype Pipeline_Type is std_logic_vector(0 to C_PIPELINE_DEPTH - 1);

  type Cycle_Array_Type is array(0 to C_PIPELINE_DEPTH - 1) of Cycle_Type;

  signal Count           : Cycle_Array_Type;
  signal Count_Stop      : Cycle_Type;
  signal Count_Stop_d1   : Cycle_Type;
  signal Access_Overflow : Pipeline_Type;

  signal firstIndex      : Index_Type;
  signal lastIndex       : Index_Type;
  signal stopIndex       : Index_Type;
  signal firstIndex_Next : Index_Type;
  signal lastIndex_Next  : Index_Type;
  signal Empty           : boolean;

  signal Maximum         : Cycle_Type;
  signal Minimum         : Cycle_Type;
  signal Access_Count_i  : std_logic_vector(0 to C_ACCESS_COUNTER_WIDTH-1);
  signal Cycle_Count_i   : Counter_Type;
  signal Cycle_Count_2_i : Counter_Type;
  signal Overflow        : std_logic;
  signal Full            : std_logic;

  signal Stopping        : boolean;
  signal Starting        : boolean;
  signal Running         : Pipeline_Type;
  signal Is_Valid        : Pipeline_Type;
  signal update_d1       : std_logic;
  signal update_d2       : std_logic;
  signal counter_2_d1    : Power_Type;

begin

  Gen_Simple_Counter: if C_SIMPLE_COUNTER generate
    Counters_FF: process(Clk)
    begin
      if Clk'event and Clk = '1' then     -- rising clock edge
        if Rst = '1' then
          Access_Count_i  <= (others => '0');

          Count           <= (others => (others => '0'));
          Access_Overflow <= (others => '0');
          Overflow        <= '0';
        else
          for I in 0 to C_PIPELINE_DEPTH - 1 loop
            if Running(I) = '1' then
              if Count(I) = (Cycle_Type'range => '1') then
                Access_Overflow(I) <= '1';
                Overflow <= '1';
              else
                Count(I) <= std_logic_vector(unsigned(Count(I)) + 1);
              end if;
            end if;
          end loop;
          if Stopping then
            if Is_Valid(stopIndex) = '1' then
              Access_Count_i  <= std_logic_vector(unsigned(Access_Count_i) + 1);
            end if;
            Count(stopIndex) <= (others => '0');
            Access_Overflow(stopIndex) <= '0';
          end if;
          if Clear = '1' then
            Access_Count_i  <= (others => '0');
          end if;
        end if;
      end if;
    end process Counters_FF;

    Cycle_Count_i   <= (others => '0');
    Cycle_Count_2_i <= (others => '0');
    Minimum         <= (others => '0');
    Maximum         <= (others => '0');
  end generate Gen_Simple_Counter;


  Gen_Access_Counter: if not C_SIMPLE_COUNTER generate
    Counters_FF: process(Clk)
    begin
      if Clk'event and Clk = '1' then     -- rising clock edge
        if Rst = '1' then
          Access_Count_i  <= (others => '0');
          Cycle_Count_i   <= (others => '0');
          Minimum         <= (others => '1');
          Maximum         <= (others => '0');

          update_d1       <= '0';
          Count_Stop_d1   <= (others => '0');
          Count           <= (others => (others => '0'));
          Access_Overflow <= (others => '0');
          Overflow        <= '0';
        else
          update_d1       <= '0';
          Count_Stop_d1   <= Count_Stop;
          
          if Clear = '1' then
            Access_Count_i  <= (others => '0');
            Cycle_Count_i   <= (others => '0');
            Minimum         <= (others => '1');
            Maximum         <= (others => '0');
          end if;
          for I in 0 to C_PIPELINE_DEPTH - 1 loop
            if Running(I) = '1' then
              if Count(I) = (Cycle_Type'range => '1') then
                Access_Overflow(I) <= '1';
                Overflow <= '1';
              else
                Count(I) <= std_logic_vector(unsigned(Count(I)) + 1);
              end if;
            end if;
          end loop;
          if Stopping then
            if Is_Valid(stopIndex) = '1' then
              Access_Count_i  <= std_logic_vector(unsigned(Access_Count_i) + 1);
              Cycle_Count_i   <= std_logic_vector(unsigned(Cycle_Count_i) +
                                                  unsigned(Count_Stop));
              update_d1       <= '1';
              if Count_Stop < Minimum then
                Minimum <= Count_Stop;
              end if;
              if Count_Stop > Maximum and Access_Overflow(stopIndex) = '0' then
                Maximum <= Count_Stop;
              end if;
            end if;
            Count(stopIndex) <= (others => '0');
            Access_Overflow(stopIndex) <= '0';
          end if;
        end if;
      end if;
    end process Counters_FF;
  end generate Gen_Access_Counter;

  Delayed_Statistics_Handler : process (Clk) is
  begin  -- process Delayed_Statistics_Handler
    if( Clk'event and Clk = '1' ) then   -- rising clock edge
      if( Rst = '1' ) then              -- synchronous reset (active high)
        update_d2         <= '0';
        counter_2_d1      <= (others=>'0');
        Cycle_Count_2_i   <= (others=>'0');
        
      else
        update_d2         <= update_d1;
        counter_2_d1      <= std_logic_vector(unsigned(Count_Stop_d1) * unsigned(Count_Stop_d1));
        
        if Clear = '1' then
          Cycle_Count_2_i <= (others => '0');
        end if;
        if( update_d2 = '1' ) then
          -- Sum of all counter events.
          if( C_USE_STDDEV /= 0 ) then
            Cycle_Count_2_i <= std_logic_vector(unsigned(Cycle_Count_2_i) + unsigned(counter_2_d1));
          else
            Cycle_Count_2_i <= (others=>'0');
          end if;
          
        end if;
      end if;
    end if;
  end process Delayed_Statistics_Handler;
  
  Count_Stop <= Count(stopIndex);

  Access_FF : process(Clk)
  begin
    if Clk'event and Clk = '1' then     -- rising clock edge
      if Rst = '1' then
        Starting   <= false;
        Stopping   <= false;
        Running    <= (others => '0');
        Is_Valid   <= (others => '0');
        firstIndex <= 0;
        lastIndex  <= 0;
        stopIndex  <= 0;
        Empty      <= true;
        Full       <= '0';
      else
        Starting <= false;
        Stopping <= false;
        if (Running(firstIndex) = '1') then
          if (Access_Abort = '1') then
            Is_Valid(firstIndex) <= '0';
            Running(firstIndex)  <= '0';
            firstIndex           <= firstIndex_Next;
            stopIndex            <= firstIndex;
            Stopping             <= true;
            if firstIndex_Next = lastIndex then
              Empty <= true;
            end if;
          else
            if Access_Valid = '1' then
              Is_Valid(firstIndex) <= '1';
            end if;
            if Access_Ready = '1' then
              -- No check of Access_Active or Access_Active_N
              Running(firstIndex) <= '0';
              firstIndex          <= firstIndex_Next;
              stopIndex           <= firstIndex;
              Stopping            <= true;
              if firstIndex_Next = lastIndex then
                Empty <= true;
              end if;
            end if;
          end if;
        end if;
        if Access_Request = '1' and
           Access_Active = '1' and
           Access_ActiveN = '0' and
           Pause = '0' then
          if lastIndex = firstIndex and not Empty and Access_Abort = '0' then
            Full <= '1';
          else
            Running(lastIndex)  <= '1';
            Is_Valid(lastIndex) <= '0';
            lastIndex           <= lastIndex_Next;
            Empty               <= false;
            Starting            <= true;
            
            -- Support for zero cycle accesses
            if Access_Abort = '0' and Empty then
              if Access_Valid = '1' then
                Is_Valid(lastIndex) <= '1';
              end if;
              if Access_Ready = '1' then
                -- No check of Access_Active or Access_Active_N
                Running(lastIndex) <= '0';
                firstIndex <= firstIndex_Next;
                stopIndex  <= lastIndex;
                Stopping   <= true;
                Empty      <= true;
              end if;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process Access_FF;

  No_PipeLining : if C_PIPELINE_DEPTH = 1 generate
    firstIndex_Next <= 0;
    lastIndex_Next  <= 0;
  end generate No_PipeLining;

  PipeLining : if C_PIPELINE_DEPTH > 1 generate
    constant C_PIPELINE_BITS : integer := Log2(C_PIPELINE_DEPTH);

    subtype Index_Vector is std_logic_vector(0 to C_PIPELINE_BITS - 1);

    signal firstIndex_Vector : Index_Vector;
    signal lastIndex_Vector  : Index_Vector;
  begin
    firstIndex_Vector <= std_logic_vector(to_unsigned(firstIndex, C_PIPELINE_BITS));
    firstIndex_Next   <= to_integer(unsigned(firstIndex_Vector) + 1);

    lastIndex_Vector  <= std_logic_vector(to_unsigned(lastIndex, C_PIPELINE_BITS));
    lastIndex_Next    <= to_integer(unsigned(lastIndex_Vector)  + 1);
  end generate PipeLining;


  Assign: process(Access_Count_i, Minimum, Maximum, Full, Overflow, Cycle_Count_i, Cycle_Count_2_i)
  begin
    Access_Count  <= (others => '0');
    Access_Count(C_ACCESS_COUNTER_WIDTH - 1 downto 0) <= Access_Count_i;
    
    Min_Max_Status  <= (others => '0');
    Min_Max_Status(C_STAT_MIN_POS)      <= Minimum;
    Min_Max_Status(C_STAT_MAX_POS)      <= Maximum;
    Min_Max_Status(C_STAT_FULL_POS)     <= Full;
    Min_Max_Status(C_STAT_OVERFLOW_POS) <= Overflow;
    
    Cycle_Count   <= (others => '0');
    Cycle_Count(C_CYCLE_COUNTER_WIDTH   - 1 downto 0) <= Cycle_Count_i;
    
    Cycle_Count_2 <= (others => '0');
    Cycle_Count_2(C_CYCLE_COUNTER_WIDTH - 1 downto 0) <= Cycle_Count_2_i;

  end process Assign;


  Is_Running <= Running(firstIndex);
  Is_Stopped <= not Running(firstIndex);

end architecture IMP;

