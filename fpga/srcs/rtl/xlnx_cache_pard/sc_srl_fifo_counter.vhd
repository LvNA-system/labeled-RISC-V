-------------------------------------------------------------------------------
-- sc_srl_fifo_counter.vhd - Entity and architecture
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
-- Filename:        sc_srl_fifo_counter.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_srl_fifo_counter.vhd
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

entity sc_srl_fifo_counter is
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
    
    -- Configuration.
    C_PUSH_ON_CARRY           : boolean                       := false;
    C_POP_ON_CARRY            : boolean                       := false;
    C_ENABLE_PROTECTION       : boolean                       := false;
    C_USE_QUALIFIER           : boolean                       := false;
    C_QUALIFIER_LEVEL         : natural range  0 to    1      := 1;
    C_USE_REGISTER_OUTPUT     : boolean                       := false;
    C_QUEUE_ADDR_WIDTH        : natural range  2 to   10      :=  5;
    C_LINE_LENGTH             : natural range  1 to 1023      :=  4
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;

    -- ---------------------------------------------------
    -- Queue Counter Interface
    
    queue_push                : in  std_logic;
    queue_pop                 : in  std_logic;
    queue_push_qualifier      : in  std_logic;
    queue_pop_qualifier       : in  std_logic;
    queue_refresh_reg         : out std_logic;
    
    queue_almost_full         : out std_logic := '0';
    queue_full                : out std_logic := '0';
    queue_almost_empty        : out std_logic := '0';
    queue_empty               : out std_logic := '1';
    queue_exist               : out std_logic := '0';
    queue_line_fit            : out std_logic := '1';
    queue_index               : out std_logic_vector(C_QUEUE_ADDR_WIDTH - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    stat_data                 : out STAT_FIFO_TYPE;
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals
    
    DEBUG                     : out std_logic_vector(255 downto 0)
  );
end entity sc_srl_fifo_counter;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_srl_fifo_counter is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Custom types (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_READ_FROM_EMPTY           : natural :=  0;
  constant C_ASSERT_WRITE_TO_FULL             : natural :=  1;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  2;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  -- Types for Queue Length.
  constant C_DATA_QUEUE_LENGTH        : integer:= 2 ** C_QUEUE_ADDR_WIDTH;
  constant C_DATA_QUEUE_LENGTH_BITS   : integer:= C_QUEUE_ADDR_WIDTH;
  subtype DATA_QUEUE_ADDR_POS         is natural range C_DATA_QUEUE_LENGTH - 1 downto 0;
  subtype DATA_QUEUE_ADDR_TYPE        is std_logic_vector(C_DATA_QUEUE_LENGTH_BITS - 1 downto 0);
  
  -- Levels for counters.
  constant C_DATA_QUEUE_EMPTY         : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - 1,                 C_DATA_QUEUE_LENGTH_BITS));
                      
  constant C_DATA_QUEUE_ALMOST_EMPTY  : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(1,                                       C_DATA_QUEUE_LENGTH_BITS));
                      
  constant C_DATA_QUEUE_ALMOST_FULL   : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - 4,                 C_DATA_QUEUE_LENGTH_BITS));
                      
  constant C_DATA_QUEUE_LINE_LEVEL_UP : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - 3 - C_LINE_LENGTH, C_DATA_QUEUE_LENGTH_BITS));
                      
  constant C_DATA_QUEUE_LINE_LEVEL_DN : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - 1 - C_LINE_LENGTH, C_DATA_QUEUE_LENGTH_BITS));
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_stat_counter is
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
  end component sc_stat_counter;
  
  
  component carry_and_n is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_and_n;
  
  component carry_or_n is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_or_n;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Queue Control Selection
  
  signal queue_push_srl           : std_logic;
  signal queue_pop_srl            : std_logic;
  signal queue_refresh_reg_i      : std_logic;
  signal queue_exist_i            : std_logic;
  
  
  -- ----------------------------------------
  -- Queue Handling
  
  signal refresh_counter          : std_logic;
  signal read_fifo_addr           : DATA_QUEUE_ADDR_TYPE:= (others=>'1');
  
  signal queue_almost_full_cmb    : std_logic;
  signal queue_almost_empty_cmb   : std_logic;
  signal queue_line_fit_up_cmb    : std_logic;
  signal queue_line_fit_dn_cmb    : std_logic;
  
  signal queue_almost_full_i      : std_logic;
  signal queue_full_i             : std_logic;
  signal queue_almost_empty_i     : std_logic;
  signal queue_empty_i            : std_logic;
  signal queue_line_fit_i         : std_logic;
  signal queue_push_prot          : std_logic;
  signal queue_pop_prot           : std_logic;
  
  signal stat_index               : STAT_POINT_TYPE;
  signal stat_empty               : STAT_POINT_TYPE;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1             : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Queue Control Selection
  -----------------------------------------------------------------------------
  
  No_Reg_Ctrl: if( not C_USE_REGISTER_OUTPUT ) generate
  begin
    queue_push_srl      <= queue_push;
    queue_pop_srl       <= queue_pop;
    queue_refresh_reg_i <= '0';
    
    queue_exist         <= not queue_empty_i;
  end generate No_Reg_Ctrl;
  
  Use_Reg_Ctrl: if( C_USE_REGISTER_OUTPUT ) generate
    signal queue_pop_reg            : std_logic;
  begin
    queue_push_srl      <= queue_push;
    
    No_Pop_Carry: if( not C_POP_ON_CARRY ) generate
    begin
      queue_pop_srl       <= queue_refresh_reg_i and not queue_empty_i;
      queue_pop_reg       <= queue_pop;
      queue_refresh_reg_i <= queue_pop_reg or not queue_exist_i;
    end generate No_Pop_Carry;
    
    Use_Pop_Carry: if( C_POP_ON_CARRY ) generate
    begin
      SRL_Or_Inst1: carry_or_n 
        generic map(
          C_TARGET => C_TARGET
        )
        port map(
          Carry_IN  => queue_pop,
          A_N       => queue_exist_i,
          Carry_OUT => queue_refresh_reg_i
        );
      SRL_And_Inst1: carry_and_n 
        generic map(
          C_TARGET => C_TARGET
        )
        port map(
          Carry_IN  => queue_refresh_reg_i,
          A_N       => queue_empty_i,
          Carry_OUT => queue_pop_srl
        );
    end generate Use_Pop_Carry;
    
    -- Handle flags for register stage.
    Register_Flag_Handling : process (ACLK) is
    begin  -- process Register_Flag_Handling
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          queue_exist_i         <= '0';
          
        elsif( queue_refresh_reg_i = '1' ) then
          queue_exist_i         <= not queue_empty_i;
          
        end if;
      end if;
    end process Register_Flag_Handling;
    
    queue_exist         <= queue_exist_i;
    
  end generate Use_Reg_Ctrl;
  
  
  -----------------------------------------------------------------------------
  -- Queue Handling
  -----------------------------------------------------------------------------
  
  No_Qualifier: if( not C_USE_QUALIFIER ) generate
  begin
    -- Is protection enabled?
    queue_push_prot   <= queue_full_i  when C_ENABLE_PROTECTION else '0';
    queue_pop_prot    <= queue_empty_i when C_ENABLE_PROTECTION else '0';
  end generate No_Qualifier;
  
  Use_Qualifier: if( C_USE_QUALIFIER ) generate
  begin
    queue_push_prot   <= queue_push_qualifier  when C_QUALIFIER_LEVEL = 0 else not queue_push_qualifier;
    queue_pop_prot    <= queue_pop_qualifier   when C_QUALIFIER_LEVEL = 0 else not queue_pop_qualifier;
  end generate Use_Qualifier;
  
  -- Detect when pointer needs updating.
  refresh_counter <= ( queue_push_srl and not queue_push_prot ) xor ( queue_pop_srl and not queue_pop_prot );
  
  Use_RTL: if( C_TARGET = RTL ) generate
  begin
    -- Handle pointer to Queue.
    FIFO_Pointer : process (ACLK) is
    begin  -- process FIFO_Pointer
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          read_fifo_addr  <= C_DATA_QUEUE_EMPTY;
        elsif( refresh_counter = '1' ) then
          if ( queue_push_srl = '1' ) then
            read_fifo_addr  <= std_logic_vector(unsigned(read_fifo_addr) + 1);
          else
            read_fifo_addr  <= std_logic_vector(unsigned(read_fifo_addr) - 1);
          end if;
        end if;
      end if;
    end process FIFO_Pointer;
    
    -- Handle flags to Queue.
    Flag_Handling : process (ACLK) is
    begin  -- process Flag_Handling
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          queue_almost_full_i   <= '0';
          queue_full_i          <= '0';
          queue_almost_empty_i  <= '0';
          queue_empty_i         <= '1';
          if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) then
            queue_line_fit_i      <= '0';
          else
            queue_line_fit_i      <= '1';
          end if;
          
        elsif( refresh_counter = '1' ) then
          if ( queue_push_srl = '1' ) then
            queue_almost_full_i   <= queue_almost_full_cmb;
            queue_full_i          <= queue_almost_full_i;
            queue_almost_empty_i  <= queue_empty_i;
            queue_empty_i         <= '0';
            if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) then
              queue_line_fit_i      <= '0';
            else
              queue_line_fit_i      <= queue_line_fit_up_cmb;
            end if;
            
          else
            queue_almost_full_i   <= queue_full_i;
            queue_full_i          <= '0';
            queue_almost_empty_i  <= queue_almost_empty_cmb;
            queue_empty_i         <= queue_almost_empty_i;
            if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) then
              queue_line_fit_i      <= '0';
            else
              queue_line_fit_i      <= queue_line_fit_dn_cmb;
            end if;
            
          end if;
        end if;
      end if;
    end process Flag_Handling;
    
  end generate Use_RTL;
  
  Use_FPGA: if( C_TARGET /= RTL ) generate
    signal queue_almost_full_next   : std_logic;
    signal queue_full_next          : std_logic;
    signal queue_almost_empty_next  : std_logic;
    signal queue_empty_next         : std_logic;
    signal queue_line_fit_next      : std_logic;
    
    signal cnt_s                    : std_logic_vector(C_QUEUE_ADDR_WIDTH - 1 downto 0);
    signal cnt_di                   : std_logic_vector(C_QUEUE_ADDR_WIDTH - 2 downto 0);
    signal carry                    : std_logic_vector(C_QUEUE_ADDR_WIDTH - 1 downto 0);
    signal read_fifo_addr_next      : std_logic_vector(C_QUEUE_ADDR_WIDTH - 1 downto 0);
  begin
    -- Start carry chain.
    carry(0)  <= '0';
    
    Cnt_Bit_Gen: for I in 0 to C_QUEUE_ADDR_WIDTH - 1 generate
    begin
--      queue_pop_srl       <= queue_refresh_reg_i and not queue_empty_i;
--      queue_pop_reg       <= queue_pop;
--      queue_refresh_reg_i <= queue_pop_reg or not queue_exist_i;

      No_Prot: if ( ( not C_USE_QUALIFIER ) and ( C_USE_REGISTER_OUTPUT and not C_POP_ON_CARRY ) ) generate
      begin
        Last_Bit: if( I = C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6
            generic map(
              INIT => X"FFAE005100510051"
            )
            port map(
              O  => cnt_s(I),                     -- [out]
              I0 => queue_empty_i,                -- [in]
              I1 => queue_exist_i,                -- [in]
              I2 => queue_pop,                    -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Last_Bit;
        Other_Bits: if( I /= 0 and I /= C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"FFAE005100510051"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_empty_i,                -- [in]
              I1 => queue_exist_i,                -- [in]
              I2 => queue_pop,                    -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Other_Bits;
        First_Bit: if( I = 0 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"51AEAE51AE51AE51"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_empty_i,                -- [in]
              I1 => queue_exist_i,                -- [in]
              I2 => queue_pop,                    -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate First_Bit;
      end generate No_Prot;
          
      Active_Low: if ( C_USE_QUALIFIER and C_QUALIFIER_LEVEL = 0 ) or
                     ( ( not C_USE_QUALIFIER ) and not ( C_USE_REGISTER_OUTPUT and not C_POP_ON_CARRY ) ) generate
      begin
        Last_Bit: if( I = C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6
            generic map(
              INIT => X"BFAF405040504050"
            )
            port map(
              O  => cnt_s(I),                     -- [out]
              I0 => queue_pop_prot,               -- [in]
              I1 => queue_push_prot,              -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Last_Bit;
        Other_Bits: if( I /= 0 and I /= C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"BFAF405040504050"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_pop_prot,               -- [in]
              I1 => queue_push_prot,              -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Other_Bits;
        First_Bit: if( I = 0 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"9CAF635063506350"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_pop_prot,               -- [in]
              I1 => queue_push_prot,              -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate First_Bit;
      end generate Active_Low;
          
      Active_High: if ( C_USE_QUALIFIER and C_QUALIFIER_LEVEL = 1 ) generate
      begin
        -- Use qualifier directly since the inverter might cause suboptimal implementation for counter.
        
        Last_Bit: if( I = C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6
            generic map(
              INIT => X"4F5FB0A0B0A0B0A0"
            )
            port map(
              O  => cnt_s(I),                     -- [out]
              I0 => queue_pop_qualifier,          -- [in]
              I1 => queue_push_qualifier,         -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Last_Bit;
        Other_Bits: if( I /= 0 and I /= C_QUEUE_ADDR_WIDTH - 1 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"4F5FB0A0B0A0B0A0"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_pop_qualifier,          -- [in]
              I1 => queue_push_qualifier,         -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate Other_Bits;
        First_Bit: if( I = 0 ) generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"635F9CA09CA09CA0"
            )
            port map(
              O5 => cnt_di(I),                    -- [out]
              O6 => cnt_s(I),                     -- [out]
              I0 => queue_pop_qualifier,          -- [in]
              I1 => queue_push_qualifier,         -- [in]
              I2 => queue_pop_srl,                -- [in]
              I3 => queue_push_srl,               -- [in]
              I4 => read_fifo_addr(I),            -- [in]
              I5 => '1'                           -- [in]
            );
        end generate First_Bit;
      end generate Active_High;
          
      Use_Muxcy: if( I /= C_QUEUE_ADDR_WIDTH - 1 ) generate
      begin
        MUXCY_Inst : MUXCY_L
          port map (
            DI => cnt_di(I),
            CI => carry(I),
            S  => cnt_s(I),
            LO => carry(I+1));
      end generate Use_Muxcy;
  
      -- Merge addsub result with carry in to get final result
      XOR_Inst : XORCY
        port map (
          LI => cnt_s(I),
          CI => carry(I),
          O  => read_fifo_addr_next(I));
          
      FDS_Inst : FDS
        port map (
          Q  => read_fifo_addr(I),            -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => read_fifo_addr_next(I),       -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
      
    end generate Cnt_Bit_Gen;
  
    -- Handle flags to Queue.
    Flag_Handling : process (refresh_counter, queue_push_srl, queue_push_prot, 
                             queue_full_i, 
                             queue_almost_full_cmb, queue_almost_full_i, 
                             queue_almost_empty_cmb, queue_almost_empty_i, 
                             queue_empty_i, 
                             queue_line_fit_up_cmb, queue_line_fit_dn_cmb, queue_line_fit_i) is
    begin  -- process Flag_Handling
      if( refresh_counter = '1' ) then
        if ( ( queue_push_srl and not queue_push_prot ) = '1' ) then
          queue_almost_full_next  <= queue_almost_full_cmb;
          queue_full_next         <= queue_almost_full_i;
          queue_almost_empty_next <= queue_empty_i;
          queue_empty_next        <= '0';
          if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= queue_line_fit_up_cmb;
          end if;
          
        else
          queue_almost_full_next  <= queue_full_i;
          queue_full_next         <= '0';
          queue_almost_empty_next <= queue_almost_empty_cmb;
          queue_empty_next        <= queue_almost_empty_i;
          if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= queue_line_fit_dn_cmb;
          end if;
          
        end if;
      else
        queue_almost_full_next  <= queue_almost_full_i;
        queue_full_next         <= queue_full_i;
        queue_almost_empty_next <= queue_almost_empty_i;
        queue_empty_next        <= queue_empty_i;
        queue_line_fit_next     <= queue_line_fit_i;
      end if;
    end process Flag_Handling;
      
    Almost_Full_Inst : FDR
      port map (
        Q  => queue_almost_full_i,          -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_full_next,       -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Full_Inst : FDR
      port map (
        Q  => queue_full_i,                 -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_full_next,              -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Almost_Empty_Inst : FDR
      port map (
        Q  => queue_almost_empty_i,         -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_empty_next,      -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Empty_Inst : FDS
      port map (
        Q  => queue_empty_i,                -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_empty_next,             -- [in  std_logic]
        S  => ARESET                        -- [in  std_logic]
      );
    
    Use_Normal_Line: if( C_LINE_LENGTH < C_DATA_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDS
        port map (
          Q  => queue_line_fit_i,             -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Normal_Line;
    Use_Long_Line: if( C_LINE_LENGTH >= C_DATA_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDR
        port map (
          Q  => queue_line_fit_i,             -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          R  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Long_Line;
  end generate Use_FPGA;
  
  
  -----------------------------------------------------------------------------
  -- Queue Level Decoding
  -----------------------------------------------------------------------------
  
  -- Calculate Queue Status.
  queue_almost_full_cmb  <= '1' when (read_fifo_addr  = C_DATA_QUEUE_ALMOST_FULL)   else '0';
  queue_almost_empty_cmb <= '1' when (read_fifo_addr  = C_DATA_QUEUE_ALMOST_EMPTY)  else '0';
  queue_line_fit_up_cmb  <= '1' when (read_fifo_addr  = C_DATA_QUEUE_EMPTY) or         
                                     (read_fifo_addr  < C_DATA_QUEUE_LINE_LEVEL_UP) else '0';
  queue_line_fit_dn_cmb  <= '1' when (read_fifo_addr  < C_DATA_QUEUE_LINE_LEVEL_DN) else '0';
  
  
  -----------------------------------------------------------------------------
  -- Assign Outputs
  -----------------------------------------------------------------------------
  
  queue_refresh_reg   <= queue_refresh_reg_i;
  queue_almost_full   <= queue_almost_full_i;
  queue_full          <= queue_full_i;
  queue_almost_empty  <= queue_almost_empty_i;
  queue_empty         <= queue_empty_i;
  queue_line_fit      <= queue_line_fit_i;
  queue_index         <= read_fifo_addr;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Statistics: if( not C_USE_STATISTICS ) generate
  begin
    stat_empty  <= C_NULL_STAT_POINT;
    stat_index  <= C_NULL_STAT_POINT;
  end generate No_Statistics;
  
  Use_Statistics: if( C_USE_STATISTICS ) generate
    signal stat_fifo_update         : std_logic:= '0';
    signal stat_fifo_addr           : DATA_QUEUE_ADDR_TYPE:= (others=>'1');
  begin
    Stat_Pipeline : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (stat_reset = '1') then          -- synchronous reset (active true)
          stat_fifo_update  <= '0';
          stat_fifo_addr    <= (others=>'0');
        else
          stat_fifo_update  <= refresh_counter;
          stat_fifo_addr    <= std_logic_vector(unsigned(read_fifo_addr) + 1);
        end if;
      end if;
    end process Stat_Pipeline;
    
    STAT_CNT_INST: sc_stat_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => C_QUEUE_ADDR_WIDTH,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV
      )
      port map(
        -- ---------------------------------------------------
        -- Common Signals
        
        ACLK                      => ACLK,
        ARESET                    => stat_reset,
    
        -- ---------------------------------------------------
        -- Counter Interface
        
        update                    => stat_fifo_update,
        counter                   => stat_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
    
        stat_data                 => stat_index
      );
      
    STAT_EMPTY_INST: sc_stat_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
        C_STAT_COUNTER_BITS       => 2,
        C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
        C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV
      )
      port map(
        -- ---------------------------------------------------
        -- Common Signals
        
        ACLK                      => ACLK,
        ARESET                    => stat_reset,
    
        -- ---------------------------------------------------
        -- Counter Interface
        
        update                    => queue_empty_i,
        counter                   => std_logic_vector(to_unsigned(1, 2)),
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_empty
      );
      
  end generate Use_Statistics;
  
  -- Assign outputs.
  Assign_Output : process (stat_empty, stat_index) is
  begin  -- process Assign_Output
    -- Default.
    stat_data.Empty_Cycles              <= (others=>'0');
    stat_data.Index_Updates             <= (others=>'0');
    stat_data.Index_Max                 <= (others=>'0');
    stat_data.Index_Sum                 <= (others=>'0');
    
    stat_data.Empty_Cycles              <= stat_empty.Sum;
    stat_data.Index_Updates             <= stat_index.Events;
    stat_data.Index_Max(C_STAT_MAX_POS) <= stat_index.Min_Max_Status(C_STAT_MAX_POS);
    stat_data.Index_Sum                 <= stat_index.Sum;
  end process Assign_Output;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          DEBUG  <= (others=>'0');
        else
          -- Default assignment.
          DEBUG      <= (others=>'0');
          
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect FIFO behaviour
  
  FIFO_Assertions: block
  begin
    -- Detect error conditions.
    assert_err(C_ASSERT_READ_FROM_EMPTY)  <= ( queue_empty_i and ( queue_pop_srl and not queue_pop_prot   ) )
                                                  when C_USE_ASSERTIONS else 
                                             '0';
    assert_err(C_ASSERT_WRITE_TO_FULL)    <= ( queue_full_i  and ( queue_push_srl and not queue_push_prot ) and not 
                                                                 ( queue_pop_srl  and not queue_pop_prot  ) ) 
                                                  when C_USE_ASSERTIONS else 
                                             '0';
    
    -- pragma translate_off
    
    -- Report any issues.
    assert assert_err_1(C_ASSERT_READ_FROM_EMPTY) /= '1' 
      report "SRL_FIFO Counter: Illegal Read from Empty FIFO."
        severity error;
    
    
    assert assert_err_1(C_ASSERT_WRITE_TO_FULL) /= '1' 
      report "SRL_FIFO Counter: Illegal Write to Full FIFO."
        severity error;
      
    -- pragma translate_on
  end block FIFO_Assertions;
  
  
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


