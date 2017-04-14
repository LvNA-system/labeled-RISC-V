-------------------------------------------------------------------------------
-- sc_s_axi_length_generation.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_length_generation.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_length_generation.vhd
--
-------------------------------------------------------------------------------
-- Author:          rikardw
--
-- History:
--   rikardw  2011-07-27    First Version
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


entity sc_s_axi_length_generation is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    
    -- AXI4 Interface Specific.
    C_S_AXI_ADDR_WIDTH        : natural                       := 32;
    
    -- System Cache Specific.
    C_CACHE_LINE_LENGTH       : natural range  4 to  128      := 16;
    
    -- Data type and settings specific.
    C_ADDR_LENGTH_HI          : natural range  0 to   63      := 10;
    C_ADDR_LENGTH_LO          : natural range  0 to   63      :=  0;
    C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
    C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
    C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
    C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Input Signals.
    
    arbiter_piperun           : in  std_logic;
    new_transaction           : in  std_logic;
    first_part                : in  std_logic;
    access_is_incr            : in  std_logic;
    access_is_wrap            : in  std_logic;
    access_byte_len           : in  AXI_ADDR_TYPE;
    aligned_addr              : in  AXI_ADDR_TYPE;
    allowed_max_wrap_len      : in  std_logic_vector(C_ADDR_LENGTH_HI downto C_ADDR_LENGTH_LO);
    full_line_beats           : in  std_logic_vector(C_ADDR_LENGTH_HI downto C_ADDR_LENGTH_LO);
    wrap_end_beats            : in  AXI_LENGTH_TYPE;
    adjusted_addr             : in  AXI_LENGTH_TYPE;
    wrap_split_mask           : in  AXI_LENGTH_TYPE;
    S_AXI_ALEN_q              : in  AXI_LENGTH_TYPE;
    S_AXI_AADDR_q             : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Output Signals.
    
    fit_lx_line               : out std_logic;
    wrap_is_aligned           : out std_logic;
    access_must_split         : out std_logic;
    transaction_start_beats   : out AXI_LENGTH_TYPE;
    remaining_length          : out AXI_LENGTH_TYPE;
    wrap_fit_lx_line          : out std_logic;
    access_cross_line         : out std_logic;
    wrap_must_split           : out std_logic;
    access_fit_sys_line       : out std_logic;
    req_last                  : out std_logic;
    transaction_done          : out std_logic;
    port_access_len           : out AXI_LENGTH_TYPE;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_length_generation;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_length_generation is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ADDR_OFFSET_BITS         : natural := C_ADDR_OFFSET_HI - C_ADDR_OFFSET_LO + 1;
  constant C_ADDR_BYTE_BITS           : natural := C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1;
  constant C_ADDR_PAGE_BITS           : natural := 12;
  constant C_ADDR_PAGE_HI             : natural := C_ADDR_PAGE_BITS - 1;
  constant C_ADDR_PAGE_LO             : natural := 0;
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  
  -- Address related.
  subtype C_ADDR_LINE_POS             is natural range C_ADDR_LINE_HI       downto C_ADDR_LINE_LO;
  subtype C_ADDR_OFFSET_POS           is natural range C_ADDR_OFFSET_HI     downto C_ADDR_OFFSET_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  
  subtype C_ADDR_LENGTH_POS           is natural range C_ADDR_LENGTH_HI     downto C_ADDR_LENGTH_LO;
  
  subtype C_ADDR_PAGE_NUM_POS         is natural range C_S_AXI_ADDR_WIDTH - 1 downto C_ADDR_PAGE_BITS;
  subtype C_ADDR_PAGE_POS             is natural range C_ADDR_PAGE_HI         downto C_ADDR_PAGE_LO;
  
  
  -- Subtypes for address parts.
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  subtype ADDR_LENGTH_TYPE            is std_logic_vector(C_ADDR_LENGTH_POS);
  
  subtype ADDR_PAGE_NUM_TYPE          is std_logic_vector(C_ADDR_PAGE_NUM_POS);
  subtype ADDR_PAGE_TYPE              is std_logic_vector(C_ADDR_PAGE_POS);
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ADDR_LENGTH              : natural := C_ADDR_LENGTH_HI - C_ADDR_LENGTH_LO + 1;
  constant C_FULL_LINE_BYTE_LENGTH    : ADDR_LENGTH_TYPE := std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH * 4 - 1, 
                                                                                         C_ADDR_LENGTH));
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component carry_latch_and is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_INV_C   : boolean
    );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      O         : out std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_latch_and;
  
  component carry_compare_mask_const is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE;
      C_SIZE   : natural;
      B_Vec    : std_logic_vector
    );
    port (
      A_Vec      : in  std_logic_vector(C_SIZE-1 downto 0);
      Mask       : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_In   : in  std_logic;
      Carry_Out  : out std_logic
    );
  end component carry_compare_mask_const;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Decode Transaction Information
  
  signal fit_lx_line_i            : std_logic;
  signal wrap_is_aligned_i        : std_logic;
  signal access_fit_sys_line_i    : std_logic;
  signal wrap_fit_lx_line_i       : std_logic;
  signal incr_end_address         : AXI_ADDR_TYPE;
  signal wrap_must_split_i        : std_logic;
  signal access_must_split_i      : std_logic;
  signal access_cross_line_i      : std_logic;
  signal transaction_start_beats_i: AXI_LENGTH_TYPE;
  signal wrap_tot_beats           : AXI_LENGTH_TYPE;
  
  
  -- ----------------------------------------
  -- Handle Internal Transactions
  
  signal port_access_len_i        : AXI_LENGTH_TYPE;
  signal remaining_length_i       : AXI_LENGTH_TYPE;
  signal req_last_i               : std_logic;
  
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Shared Code
  -----------------------------------------------------------------------------
  
  -- Calculate Incr end address.
  incr_end_address    <= std_logic_vector(unsigned(aligned_addr) + unsigned(access_byte_len));
  
  -- Detect when the transaction has to split.
  wrap_must_split_i   <= access_is_wrap and not wrap_fit_lx_line_i and not wrap_is_aligned_i;
  access_must_split_i <= wrap_must_split_i or access_cross_line_i;
  
  -- Number of Wrap beats.
  wrap_tot_beats  <= S_AXI_ALEN_q(7 downto 0);
  
  
  -----------------------------------------------------------------------------
  -- RTL Code
  -----------------------------------------------------------------------------
  
  Use_RTL: if( C_TARGET = RTL ) generate
    signal port_access_len_ii       : AXI_LENGTH_TYPE;
    signal wrap_split_beats         : AXI_LENGTH_TYPE;
    signal remaining_length_new     : AXI_LENGTH_TYPE;
  begin
    -- Determine if transaction can fit in Lx Line Length.
    fit_lx_line_i             <= '1' when to_integer(unsigned(access_byte_len(C_ADDR_LENGTH_POS))) <= 
                                          to_integer(unsigned(allowed_max_wrap_len)) else 
                                 '0';
    
    -- Determine if a wrap can fit in Lx Line Length.
    wrap_fit_lx_line_i        <= access_is_wrap and fit_lx_line_i;
    
    -- Calculate if transaction is longer than internal cache line.
    access_fit_sys_line_i     <= '1' when to_integer(unsigned(access_byte_len(C_ADDR_LENGTH_POS))) <= 
                                          (C_CACHE_LINE_LENGTH * 4 - 1) else 
                                 '0';
    
    -- Test if Incr transaction crosses Cache Line boundaries.
    -- (Page High can only be smaller than Line Low for unsupported interface size)
    access_cross_line_i       <= access_is_incr or not access_fit_sys_line_i
                                   when    S_AXI_AADDR_q(C_ADDR_PAGE_HI downto C_ADDR_LINE_LO) /= 
                                        incr_end_address(C_ADDR_PAGE_HI downto C_ADDR_LINE_LO) else 
                               not access_fit_sys_line_i;
    
    -- Detect if wrap is aligned to wrap start address.
    wrap_is_aligned_i         <= '1' when ( S_AXI_AADDR_q(C_ADDR_OFFSET_POS) and access_byte_len(C_ADDR_OFFSET_POS) ) = 
                                            (C_ADDR_OFFSET_POS=>'0') else 
                                 '0';
    
    -- Point of split for wrapping burst.
    wrap_split_beats          <= adjusted_addr and wrap_split_mask;
    
    -- Number of beats in the first cache line.
    transaction_start_beats_i <= std_logic_vector(unsigned(full_line_beats(C_AXI_LENGTH_POS)) - unsigned(wrap_end_beats)) 
                                       when access_cross_line_i = '1' else
                                 std_logic_vector(unsigned(wrap_tot_beats) - unsigned(wrap_split_beats)) 
                                       when wrap_must_split_i = '1' else
                                 S_AXI_ALEN_q;
    
    -- Select transaction length.
    Gen_Len: process (first_part, transaction_start_beats_i, req_last_i, remaining_length_i, full_line_beats) is
    begin  -- process Gen_Len
      if( first_part = '1' ) then
        port_access_len_ii  <= transaction_start_beats_i;
      elsif( req_last_i = '1' ) then
        port_access_len_ii  <= remaining_length_i;
      else
        port_access_len_ii  <= full_line_beats(C_AXI_LENGTH_POS);
      end if;
    end process Gen_Len;
    
    -- Select transaction length.
    Gen_Rem_Len: process (first_part, S_AXI_ALEN_q, port_access_len_ii, remaining_length_i) is
    begin  -- process Gen_Rem_Len
      if( first_part = '1' ) then
        remaining_length_new  <= std_logic_vector(unsigned(S_AXI_ALEN_q) - unsigned(port_access_len_ii) - 1);
      else
        remaining_length_new  <= std_logic_vector(unsigned(remaining_length_i) - unsigned(port_access_len_ii) - 1);
      end if;
    end process Gen_Rem_Len;
    
    -- Keep track of remaining length.
    Length_Handler : process (ACLK) is
    begin  -- process Length_Handler
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
          port_access_len_i   <= (others=>'0');
          remaining_length_i  <= (others=>'0');
        elsif( ( arbiter_piperun = '1' ) and ( new_transaction = '1' ) ) then
          port_access_len_i   <= port_access_len_ii;
          remaining_length_i  <= remaining_length_new;
        end if;
      end if;
    end process Length_Handler;
    
    -- Determine if this is the last piece.
    req_last_i        <= '1' when ( ( first_part and not access_must_split_i ) = '1' ) or 
                                  ( first_part = '0' and
                                    ( to_integer(unsigned(remaining_length_i)) <= 
                                      to_integer(unsigned(full_line_beats(C_AXI_LENGTH_POS)))) ) else 
                         '0';
    
    -- Last part has been forwarded.
    transaction_done  <= new_transaction and req_last_i;
    
  end generate Use_RTL;
  
  
  -----------------------------------------------------------------------------
  -- FPGA Optimized Code
  -----------------------------------------------------------------------------
  
  Use_FPGA: if( C_TARGET /= RTL ) generate
  
    signal start_carry_sel          : std_logic;
    signal remaining_carry          : AXI_LENGTH_CARRY_TYPE;
    signal remaining_di             : AXI_LENGTH_TYPE;
    signal remaining_s              : AXI_LENGTH_TYPE;
    signal pre_length_i             : AXI_LENGTH_TYPE;
    signal pre_length               : AXI_LENGTH_TYPE;
    
    signal first_part_n             : std_logic;
    signal more_beats_carry         : AXI_LENGTH_CARRY_TYPE;
    signal more_beats_di            : AXI_LENGTH_TYPE;
    signal more_beats_s             : AXI_LENGTH_TYPE;
    signal use_full_length          : std_logic;
    
    signal fit_sys_carry            : std_logic_vector(C_ADDR_LENGTH_HI + 1 downto C_ADDR_LENGTH_LO);
    signal fit_sys_di               : ADDR_LENGTH_TYPE;
    signal fit_sys_s                : ADDR_LENGTH_TYPE;
    signal cross_carry              : std_logic_vector(C_ADDR_PAGE_HI + 1 downto C_ADDR_LINE_LO);
    signal cross_s                  : std_logic_vector(C_ADDR_PAGE_HI     downto C_ADDR_LINE_LO);
    
    signal fit_lx_carry             : std_logic_vector(C_ADDR_LENGTH_HI + 1 downto C_ADDR_LENGTH_LO);
    signal fit_lx_di                : ADDR_LENGTH_TYPE;
    signal fit_lx_s                 : ADDR_LENGTH_TYPE;
    signal fit_lx_line_n            : std_logic;
    signal fit_lx_line_n_i          : std_logic;
    signal wrap_fit_lx_line_n       : std_logic;
    
    signal long_split_len           : AXI_LENGTH_TYPE;
    signal short_split_carry        : AXI_LENGTH_CARRY_TYPE;
    signal short_split_di           : AXI_LENGTH_TYPE;
    signal short_split_s            : AXI_LENGTH_TYPE;
    signal short_split_len          : AXI_LENGTH_TYPE;
    
    signal feedback_or_full_len     : AXI_LENGTH_TYPE;
    signal feedback_or_other_len    : AXI_LENGTH_TYPE;
    signal port_access_len_cmb      : AXI_LENGTH_TYPE;
    
    signal first_done               : std_logic;
    
  begin
    -- ----------------------------------------
    -- Generate length before previous segment.
    
    pre_length_i  <= remaining_length_i when new_transaction = '1' else pre_length;
    
    remaining_carry(0) <= '0';
    
    Remaining_Bit_Gen: for I in 0 to C_AXI_LENGTH_WIDTH - 1 generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"F099CCCC00550000"
        )
        port map(
          O5 => remaining_di(I),              -- [out std_logic]
          O6 => remaining_s(I),               -- [out std_logic]
          I0 => port_access_len_i(I),         -- [in  std_logic]
          I1 => pre_length(I),                -- [in  std_logic]
          I2 => S_AXI_ALEN_q(I),              -- [in  std_logic]
          I3 => first_part,                   -- [in  std_logic]
          I4 => '1',                          -- [in  std_logic]
          I5 => '1'                           -- [in  std_logic]
        );
      MUXCY_Inst : MUXCY_L
        port map (
          DI => remaining_di(I),              -- [in  std_logic]
          CI => remaining_carry(I),           -- [in  std_logic]
          S  => remaining_s(I),               -- [in  std_logic]
          LO => remaining_carry(I+1)          -- [out std_logic]
        );

      -- Merge addsub result with carry in to get final result
      XOR_Inst : XORCY
        port map (
          LI => remaining_s(I),               -- [in  std_logic]
          CI => remaining_carry(I),           -- [in  std_logic]
          O  => remaining_length_i(I)         -- [out std_logic]
        );
          
      FDS_Inst : FDSE
        port map (
          Q  => pre_length(I),                -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          CE => arbiter_piperun,              -- [in  std_logic]
          D  => pre_length_i(I),              -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
      
    end generate Remaining_Bit_Gen;
    
    
    -- ----------------------------------------
    -- Detect middle segments.
    
    first_part_n                              <= not first_part;
    more_beats_carry(more_beats_carry'right)  <= '0';
    
    More_Beat_Det: for I in 0 to C_AXI_LENGTH_WIDTH - 1 generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"F099CCCC00550000"
        )
        port map(
          O5 => more_beats_di(I),             -- [out std_logic]
          O6 => more_beats_s(I),              -- [out std_logic]
          I0 => full_line_beats(I),           -- [in  std_logic]
          I1 => remaining_length_i(I),        -- [in  std_logic]
          I2 => '0',                          -- [in  std_logic]
          I3 => '0',                          -- [in  std_logic]
          I4 => '1',                          -- [in  std_logic]
          I5 => '1'                           -- [in  std_logic]
        );
        
      MUXCY_Inst : MUXCY_L
        port map (
          DI => more_beats_di(I),
          CI => more_beats_carry(I),
          S  => more_beats_s(I),
          LO => more_beats_carry(I+1)
        );

    end generate More_Beat_Det;
    
    Use_Full_Inst : MUXCY_L
      port map (
        DI => '0',
        CI => more_beats_carry(more_beats_carry'left),
        S  => first_part_n,
        LO => use_full_length
      );
    
    
    -- ----------------------------------------
    -- Detect crossing line
    
    fit_sys_carry(fit_sys_carry'right) <= '0';
    
    Fit_Sys_Det: for I in C_ADDR_LENGTH_LO to C_ADDR_LENGTH_HI generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"F099CCCC00550000"
        )
        port map(
          O5 => fit_sys_di(I),                -- [out std_logic]
          O6 => fit_sys_s(I),                 -- [out std_logic]
          I0 => C_FULL_LINE_BYTE_LENGTH(I),   -- [in  std_logic]
          I1 => access_byte_len(I),           -- [in  std_logic]
          I2 => '0',                          -- [in  std_logic]
          I3 => '0',                          -- [in  std_logic]
          I4 => '1',                          -- [in  std_logic]
          I5 => '1'                           -- [in  std_logic]
        );
        
      MUXCY_Inst : MUXCY_L
        port map (
          DI => fit_sys_di(I),
          CI => fit_sys_carry(I),
          S  => fit_sys_s(I),
          LO => fit_sys_carry(I+1)
        );
      
    end generate Fit_Sys_Det;
    
    access_fit_sys_line_i           <= not fit_sys_carry(fit_sys_carry'left);
    cross_carry(cross_carry'right)  <= fit_sys_carry(fit_sys_carry'left);
    
    Cross_Det: for I in C_ADDR_LINE_LO to C_ADDR_PAGE_HI generate
    begin
--      cross_s(I) <= not access_is_incr when S_AXI_AADDR_q(I) /= incr_end_address(I) else '0';
      
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"9009FFFF00000000"
        )
        port map(
          O5 => open,                         -- [out std_logic]
          O6 => cross_s(I),                   -- [out std_logic]
          I0 => S_AXI_AADDR_q(I),             -- [in  std_logic]
          I1 => incr_end_address(I),          -- [in  std_logic]
          I2 => S_AXI_AADDR_q(I+1),           -- [in  std_logic]
          I3 => incr_end_address(I+1),        -- [in  std_logic]
          I4 => access_is_incr,               -- [in  std_logic]
          I5 => '1'                           -- [in  std_logic]
        );
        
      MUXCY_Inst : MUXCY_L
        port map (
          DI => '1',
          CI => cross_carry(I),
          S  => cross_s(I),
          LO => cross_carry(I+1)
        );
      
    end generate Cross_Det;
    
    access_cross_line_i <= cross_carry(cross_carry'left);

    
    -- ----------------------------------------
    -- Detect wrap split
    
    fit_lx_carry(fit_lx_carry'right)  <= '0';
    
    Fit_Lx_Det: for I in C_ADDR_LENGTH_LO to C_ADDR_LENGTH_HI generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"F099CCCC00550000"
        )
        port map(
          O5 => fit_lx_di(I),                 -- [out std_logic]
          O6 => fit_lx_s(I),                  -- [out std_logic]
          I0 => allowed_max_wrap_len(I),      -- [in  std_logic]
          I1 => access_byte_len(I),           -- [in  std_logic]
          I2 => '0',                          -- [in  std_logic]
          I3 => '0',                          -- [in  std_logic]
          I4 => '1',                          -- [in  std_logic]
          I5 => '1'                           -- [in  std_logic]
        );
        
      MUXCY_Inst : MUXCY_L
        port map (
          DI => fit_lx_di(I),                 -- [in  std_logic]
          CI => fit_lx_carry(I),              -- [in  std_logic]
          S  => fit_lx_s(I),                  -- [in  std_logic]
          LO => fit_lx_carry(I+1));           -- [out std_logic]
      
    end generate Fit_Lx_Det;
    
    fit_lx_line_n             <= fit_lx_carry(fit_lx_carry'left);
    fit_lx_line_i             <= not fit_lx_line_n;
    
    Fit_Lx_Latch_And_Inst1: carry_latch_and
      generic map(
        C_TARGET  => C_TARGET,
        C_INV_C   => true
      )
      port map(
        Carry_IN  => fit_lx_line_n,
        A         => access_is_wrap,
        O         => wrap_fit_lx_line_i,
        Carry_OUT => fit_lx_line_n_i
      );
      
    Fit_Lx_MUXCY_Inst2: MUXCY_L
      port map (
        DI => '0',                          -- [in  std_logic]
        CI => fit_lx_line_n_i,              -- [in  std_logic]
        S  => access_is_wrap,               -- [in  std_logic]
        LO => wrap_fit_lx_line_n            -- [out std_logic]
      );
      
    
    -- ----------------------------------------
    -- Detect wrap alignment
    
    Aligned_Inst: carry_compare_mask_const
      generic map(
        C_TARGET    => C_TARGET,
        C_SIZE      => C_ADDR_OFFSET_BITS,
        B_Vec       => (C_ADDR_OFFSET_POS=>'0')
      )
      port map(
        A_Vec       => S_AXI_AADDR_q(C_ADDR_OFFSET_POS),
        Mask        => access_byte_len(C_ADDR_OFFSET_POS),
        Carry_In    => '1',
        Carry_Out   => wrap_is_aligned_i
      );
    
    
    -- ----------------------------------------
    -- Generate sub lengths
    
    long_split_len  <= std_logic_vector(unsigned(full_line_beats(C_AXI_LENGTH_POS)) - unsigned(wrap_end_beats));
    
    short_split_carry(short_split_carry'right)  <= '1';
    
    Short_Split_Bit_Gen: for I in 0 to C_AXI_LENGTH_WIDTH - 1 generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"8787878777777777"
        )
        port map(
          O5 => short_split_di(I),              -- [out std_logic]
          O6 => short_split_s(I),               -- [out std_logic]
          I0 => adjusted_addr(I),               -- [in  std_logic]
          I1 => wrap_split_mask(I),             -- [in  std_logic]
          I2 => wrap_tot_beats(I),              -- [in  std_logic]
          I3 => '0',                            -- [in  std_logic]
          I4 => '0',                            -- [in  std_logic]
          I5 => '1'                             -- [in  std_logic]
        );
        
      MUXCY_Inst : MUXCY_L
        port map (
          DI => short_split_di(I),              -- [in  std_logic]
          CI => short_split_carry(I),           -- [in  std_logic]
          S  => short_split_s(I),               -- [in  std_logic]
          LO => short_split_carry(I+1)          -- [out std_logic]
        );

      -- Merge addsub result with carry in to get final result
      XOR_Inst : XORCY
        port map (
          LI => short_split_s(I),               -- [in  std_logic]
          CI => short_split_carry(I),           -- [in  std_logic]
          O  => short_split_len(I)              -- [out std_logic]
        );
          
    end generate Short_Split_Bit_Gen;
    
    
    -- ----------------------------------------
    -- Generate first length
    
    Start_Len_Bit_Gen: for I in 0 to C_AXI_LENGTH_WIDTH - 1 generate
    begin
      LUT_Inst: LUT6_2
        generic map(
          INIT => X"F0F0F0F0AACCAAAA"
        )
        port map(
          O5 => open,                         -- [out std_logic]
          O6 => transaction_start_beats_i(I), -- [out std_logic]
          I0 => S_AXI_ALEN_q(I),              -- [in  std_logic]
          I1 => short_split_len(I),           -- [in  std_logic]
          I2 => long_split_len(I),            -- [in  std_logic]
          I3 => wrap_is_aligned_i,            -- [in  std_logic]
          I4 => wrap_fit_lx_line_n,           -- [in  std_logic]
          I5 => access_cross_line_i           -- [in  std_logic]
        );
      
    end generate Start_Len_Bit_Gen;
    
    
    -- ----------------------------------------
    -- Generate length
    
    feedback_or_full_len  <= full_line_beats(C_AXI_LENGTH_POS) when new_transaction = '1' else
                             port_access_len_i;
    
    Port_Len_Bit_Gen: for I in 0 to C_AXI_LENGTH_WIDTH - 1 generate
    begin
      LUT_Inst1: LUT6_2
        generic map(
          INIT => X"F0CCF0CCAAAAAAAA"
        )
        port map(
          O5 => open,                         -- [out std_logic]
          O6 => feedback_or_other_len(I),     -- [out std_logic]
          I0 => port_access_len_i(I),         -- [in  std_logic]
          I1 => remaining_length_i(I),        -- [in  std_logic]
          I2 => transaction_start_beats_i(I), -- [in  std_logic]
          I3 => first_part,                   -- [in  std_logic]
          I4 => '0',                          -- [in  std_logic]
          I5 => new_transaction               -- [in  std_logic]
        );
        
      MUXF7_I1 : MUXF7
        port map (
          O  => port_access_len_cmb(I),       -- [out std_logic]
          I0 => feedback_or_other_len(I),     -- [in  std_logic]
          I1 => feedback_or_full_len(I),      -- [in  std_logic]
          S  => use_full_length               -- [in  std_logic]
        );
        
      FDS_Inst : FDSE
        port map (
          Q  => port_access_len_i(I),         -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          CE => arbiter_piperun,              -- [in  std_logic]
          D  => port_access_len_cmb(I),       -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
      
    end generate Port_Len_Bit_Gen;
    
    
    -- ----------------------------------------
    -- Determine if this is the last piece.
    
    first_done  <= first_part and not access_must_split_i;
    
    req_last_i  <= first_done or ( not use_full_length and not first_part );
    
    
    -- ----------------------------------------
    -- Last part has been forwarded.
    
    transaction_done  <= new_transaction and req_last_i;
    
    
  end generate Use_FPGA;
  
  
  -----------------------------------------------------------------------------
  -- Assign Output
  -----------------------------------------------------------------------------
  
  fit_lx_line             <= fit_lx_line_i;
  wrap_is_aligned         <= wrap_is_aligned_i;
  access_must_split       <= access_must_split_i;
  transaction_start_beats <= transaction_start_beats_i;
  remaining_length        <= remaining_length_i;
  access_fit_sys_line     <= access_fit_sys_line_i;
  wrap_fit_lx_line        <= wrap_fit_lx_line_i;
  access_cross_line       <= access_cross_line_i;
  wrap_must_split         <= wrap_must_split_i;
  req_last                <= req_last_i;
  port_access_len         <= port_access_len_i;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          IF_DEBUG  <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG      <= (others=>'0');
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- None.
  
  
end architecture IMP;
  
  
