-------------------------------------------------------------------------------
-- sc_primitives.vhd - Entity and architecture
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
-- Filename:        srl_fifo_counter.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              srl_fifo_counter.vhd
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

library Unisim;
use Unisim.vcomponents.all;


entity carry_and_di is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE
    );
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    DI        : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_and_di;


architecture IMP of carry_and_di is
  signal carry_out_i : std_logic;
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate
  begin
    MUXCY_I : MUXCY_L
      port map (
        DI => DI,
        CI => Carry_IN,
        S  => A,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate
    signal a_loc    : std_logic;
--    attribute KEEP  : string;
--    attribute KEEP  of a_loc  : signal is "true";
  begin
    a_loc <= A;
    MUXCY_I : MUXCY_L
      port map (
        DI => DI,
        CI => Carry_IN,
        S  => a_loc,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= Carry_IN when A = '1' else DI;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_and is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE
    );
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_and;


architecture IMP of carry_and is
  signal carry_out_i : std_logic;
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate
  begin
    MUXCY_I : MUXCY_L
      port map (
        DI => '0',
        CI => Carry_IN,
        S  => A,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate
    signal a_loc    : std_logic;
--    attribute KEEP  : string;
--    attribute KEEP  of a_loc  : signal is "true";
  begin
    a_loc <= A;
    MUXCY_I : MUXCY_L
      port map (
        DI => '0',
        CI => Carry_IN,
        S  => a_loc,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= Carry_IN when A = '1' else '0';
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_and_n is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE
    );
  port (
    Carry_IN  : in  std_logic;
    A_N       : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_and_n;


architecture IMP of carry_and_n is
  signal carry_out_i : std_logic;
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate
    signal A : std_logic;
  begin
    A <= not A_N;
    MUXCY_I : MUXCY_L
      port map (
        DI => '0',
        CI => Carry_IN,
        S  => A,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate
    signal A : std_logic;
--    attribute KEEP  : string;
--    attribute KEEP  of A  : signal is "true";
  begin
    A <= not A_N;
    MUXCY_I : MUXCY_L
      port map (
        DI => '0',
        CI => Carry_IN,
        S  => A,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= Carry_IN when A_N = '0' else '0';
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_or is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE
  );
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    Carry_OUT : out std_logic
  );
end entity carry_or;


architecture IMP of carry_or is
  signal carry_out_i : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate
    signal A_N : std_logic;
  begin
    A_N <= not A;
    MUXCY_I : MUXCY_L
      port map (
        DI => '1',
        CI => Carry_IN,
        S  => A_N,
        LO => carry_out_i);
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate
    signal A_N : std_logic;
--    attribute KEEP  : string;
--    attribute KEEP  of A_N  : signal is "true";
  begin
    A_N <= not A;
    MUXCY_I : MUXCY_L
      port map (
        DI => '1',
        CI => Carry_IN,
        S  => A_N,
        LO => carry_out_i);
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= '1' when A = '1' else Carry_IN;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_or_n is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE
  );
  port (
    Carry_IN  : in  std_logic;
    A_N       : in  std_logic;
    Carry_OUT : out std_logic
  );
end entity carry_or_n;


architecture IMP of carry_or_n is
  signal carry_out_i : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate
  begin
    MUXCY_I : MUXCY_L
      port map (
        DI => '1',
        CI => Carry_IN,
        S  => A_N,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate
    signal a_loc    : std_logic;
--    attribute KEEP  : string;
--    attribute KEEP  of a_loc  : signal is "true";
  begin
    a_loc <= A_N;
    MUXCY_I : MUXCY_L
      port map (
        DI => '1',
        CI => Carry_IN,
        S  => a_loc,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= '1' when A_N = '0' else Carry_IN;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_vec_or is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_INPUTS  : natural;
    C_SIZE    : natural
  );
  port (
    Carry_IN  : in  std_logic;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_OUT : out std_logic
  );
end entity carry_vec_or;


architecture IMP of carry_vec_or is

  component carry_or is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_or;

  constant C_INPUTS_PER_BIT : integer := C_INPUTS;
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  

begin  -- architecture IMP

  assign_sigs : process (A_Vec) is
  begin  -- process assign_sigs
    A                     <= (others => '0');
    A(C_SIZE-1 downto 0)  <= A_Vec;
  end process assign_sigs;

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '0';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        sel_I  := sel_I or A(C_BITS_PER_LUT * I + J);
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_or
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_vec_and_n is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_INPUTS  : natural;
    C_SIZE    : natural
  );
  port (
    Carry_IN  : in  std_logic;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_OUT : out std_logic
  );
end entity carry_vec_and_n;


architecture IMP of carry_vec_and_n is

  component carry_and is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

  constant C_INPUTS_PER_BIT : integer := C_INPUTS;
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  

begin  -- architecture IMP

  assign_sigs : process (A_Vec) is
  begin  -- process assign_sigs
    A                     <= (others => '0');
    A(C_SIZE-1 downto 0)  <= A_Vec;
  end process assign_sigs;

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        sel_I  := sel_I and not A(C_BITS_PER_LUT * I + J);
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_latch_and is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_NUM_PAD : natural := 0;
    C_INV_C   : boolean
  );
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    O         : out std_logic;
    Carry_OUT : out std_logic
  );
end entity carry_latch_and;


architecture IMP of carry_latch_and is
  signal carry_out_i  : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL) generate
    signal carry_pad   : std_logic_vector(C_NUM_PAD downto 0);
    signal carry_value : std_logic;
    signal A_N         : std_logic;
  begin
    carry_pad(0)  <= Carry_IN;
    
    The_Pad : for I in 0 to C_NUM_PAD - 1 generate
    begin
      MUXCY_Inst: MUXCY_L
        port map (
          DI => '0',                          -- [in  std_logic]
          CI => carry_pad(I),                 -- [in  std_logic]
          S  => '1',                          -- [in  std_logic]
          LO => carry_pad(I+1)                -- [out std_logic]
        );
    end generate The_Pad;
    
    Using_Inv : if (C_INV_C) generate
      signal carry_point : std_logic;
    begin
      Using_Pad : if ( C_NUM_PAD > 0 ) generate
      begin
        carry_point   <= carry_pad(carry_pad'left - 1);
        Carry_OUT     <= carry_pad(carry_pad'left);
      end generate Using_Pad;
      No_Pad : if ( C_NUM_PAD = 0 ) generate
      begin
        MUXCY_Inst1: MUXCY_L
          port map (
            DI => '0',                          -- [in  std_logic]
            CI => Carry_IN,                     -- [in  std_logic]
            S  => '1',                          -- [in  std_logic]
            LO => carry_out_i                   -- [out std_logic]
          );
          
        carry_point   <= Carry_IN;
        Carry_OUT     <= carry_out_i;
      end generate No_Pad;
      
      XORCY_Inst1: XORCY
        port map (
          LI => '1',                          -- [in  std_logic]
          CI => carry_point,                  -- [in  std_logic]
          O  => carry_value                   -- [out std_logic]
        );
      
    end generate Using_Inv;
    No_Inv : if (not C_INV_C) generate
    begin
      carry_value   <= carry_pad(carry_pad'left);
      Carry_OUT     <= carry_pad(carry_pad'left);
    end generate No_Inv;
    
    A_N <= not A;
    
    AND2B1L_Inst1 : AND2B1L
      port map (
        O   => O,                           -- [out std_logic]
        DI  => carry_value,                 -- [in  std_logic]
        SRI => A_N                          -- [in  std_logic]
      );
  
  end generate Using_FPGA;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    O         <= (     Carry_IN ) and A when not C_INV_C else 
                 ( not Carry_IN ) and A;
    Carry_OUT <=       Carry_IN;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_latch_and_n is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_NUM_PAD : natural := 0;
    C_INV_C   : boolean
  );
  port (
    Carry_IN  : in  std_logic;
    A_N       : in  std_logic;
    O         : out std_logic;
    Carry_OUT : out std_logic
  );
end entity carry_latch_and_n;


architecture IMP of carry_latch_and_n is
  signal carry_out_i : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL) generate
    signal carry_pad   : std_logic_vector(C_NUM_PAD downto 0);
    signal carry_value : std_logic;
  begin
    carry_pad(0)  <= Carry_IN;
    
    The_Pad : for I in 0 to C_NUM_PAD - 1 generate
    begin
      MUXCY_Inst: MUXCY_L
        port map (
          DI => '0',                          -- [in  std_logic]
          CI => carry_pad(I),                 -- [in  std_logic]
          S  => '1',                          -- [in  std_logic]
          LO => carry_pad(I+1)                -- [out std_logic]
        );
    end generate The_Pad;
    
    Using_Inv : if (C_INV_C) generate
      signal carry_point : std_logic;
    begin
      Using_Pad : if ( C_NUM_PAD > 0 ) generate
      begin
        carry_point   <= carry_pad(carry_pad'left - 1);
        Carry_OUT     <= carry_pad(carry_pad'left);
      end generate Using_Pad;
      No_Pad : if ( C_NUM_PAD = 0 ) generate
      begin
        MUXCY_Inst1: MUXCY_L
          port map (
            DI => '0',                          -- [in  std_logic]
            CI => Carry_IN,                     -- [in  std_logic]
            S  => '1',                          -- [in  std_logic]
            LO => carry_out_i                   -- [out std_logic]
          );
          
        carry_point   <= Carry_IN;
        Carry_OUT     <= carry_out_i;
      end generate No_Pad;
      
      XORCY_Inst1: XORCY
        port map (
          LI => '1',                          -- [in  std_logic]
          CI => carry_point,                  -- [in  std_logic]
          O  => carry_value                   -- [out std_logic]
        );
      
    end generate Using_Inv;
    No_Inv : if (not C_INV_C) generate
    begin
      carry_value   <= carry_pad(carry_pad'left);
      Carry_OUT     <= carry_pad(carry_pad'left);
    end generate No_Inv;
        
    AND2B1L_Inst1 : AND2B1L
      port map (
        O   => O,                           -- [out std_logic]
        DI  => carry_value,                 -- [in  std_logic]
        SRI => A_N                          -- [in  std_logic]
      );
  
  end generate Using_FPGA;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    O         <= (     Carry_IN ) and not A_N when not C_INV_C else 
                 ( not Carry_IN ) and not A_N;
    Carry_OUT <=       Carry_IN;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_latch_or is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_NUM_PAD : natural := 0;
    C_INV_C   : boolean
  );
  port (
    Carry_IN  : in  std_logic;
    A         : in  std_logic;
    O         : out std_logic;
    Carry_OUT : out std_logic
  );
end entity carry_latch_or;


architecture IMP of carry_latch_or is
  signal carry_out_i : std_logic;

begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL) generate
    signal carry_pad   : std_logic_vector(C_NUM_PAD downto 0);
    signal carry_value : std_logic;
  begin
    carry_pad(0)  <= Carry_IN;
    
    The_Pad : for I in 0 to C_NUM_PAD - 1 generate
    begin
      MUXCY_Inst: MUXCY_L
        port map (
          DI => '0',                          -- [in  std_logic]
          CI => carry_pad(I),                 -- [in  std_logic]
          S  => '1',                          -- [in  std_logic]
          LO => carry_pad(I+1)                -- [out std_logic]
        );
    end generate The_Pad;
    
    Using_Inv : if (C_INV_C) generate
      signal carry_point : std_logic;
    begin
      Using_Pad : if ( C_NUM_PAD > 0 ) generate
      begin
        carry_point   <= carry_pad(carry_pad'left - 1);
        Carry_OUT     <= carry_pad(carry_pad'left);
      end generate Using_Pad;
      No_Pad : if ( C_NUM_PAD = 0 ) generate
      begin
        MUXCY_Inst1: MUXCY_L
          port map (
            DI => '0',                          -- [in  std_logic]
            CI => Carry_IN,                     -- [in  std_logic]
            S  => '1',                          -- [in  std_logic]
            LO => carry_out_i                   -- [out std_logic]
          );
          
        carry_point   <= Carry_IN;
        Carry_OUT     <= carry_out_i;
      end generate No_Pad;
      
      XORCY_Inst1: XORCY
        port map (
          LI => '1',                          -- [in  std_logic]
          CI => carry_point,                  -- [in  std_logic]
          O  => carry_value                   -- [out std_logic]
        );
      
    end generate Using_Inv;
    No_Inv : if (not C_INV_C) generate
    begin
      carry_value   <= carry_pad(carry_pad'left);
      Carry_OUT     <= carry_pad(carry_pad'left);
    end generate No_Inv;
        
    OR2L_Inst1: OR2L
      port map (
        O   => O,                           -- [out std_logic]
        DI  => carry_value,                 -- [in  std_logic]
        SRI => A                            -- [in  std_logic]
      );
  
  end generate Using_FPGA;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    O         <= (     Carry_IN ) or A when not C_INV_C else 
                 ( not Carry_IN ) or A;
    Carry_OUT <=       Carry_IN;
  end generate Using_RTL;

end architecture IMP;


--library IEEE;
--use IEEE.std_logic_1164.all;
--use ieee.numeric_std.all;

--library work;
--use work.system_cache_pkg.all;

--library Unisim;
--use Unisim.vcomponents.all;


--entity carry_latch_or_n is
--  generic (
--    C_KEEP    : boolean:= false;
--    C_TARGET  : TARGET_FAMILY_TYPE;
--    C_NUM_PAD : natural := 0;
--    C_INV_C   : boolean
--  );
--  port (
--    Carry_IN  : in  std_logic;
--    A_N       : in  std_logic;
--    O         : out std_logic;
--    Carry_OUT : out std_logic
--  );
--end entity carry_latch_or_n;


--architecture IMP of carry_latch_or_n is
--  signal carry_out_i : std_logic;

--begin  -- architecture IMP

--  -----------------------------------------------------------------------------
--  -- FPGA implementation
--  -----------------------------------------------------------------------------
--  Using_FPGA : if (C_TARGET /= RTL) generate
--    signal carry_pad   : std_logic_vector(C_NUM_PAD downto 0);
--    signal carry_value : std_logic;
--    signal A           : std_logic;
--  begin
--    carry_pad(0)  <= Carry_IN;
    
--    The_Pad : for I in 0 to C_NUM_PAD - 1 generate
--    begin
--      MUXCY_Inst: MUXCY_L
--        port map (
--          DI => '0',                          -- [in  std_logic]
--          CI => carry_pad(I),                 -- [in  std_logic]
--          S  => '1',                          -- [in  std_logic]
--          LO => carry_pad(I+1)                -- [out std_logic]
--        );
--    end generate The_Pad;
    
--    Using_Inv : if (C_INV_C) generate
--      signal carry_point : std_logic;
--    begin
--      Using_Pad : if ( C_NUM_PAD > 0 ) generate
--      begin
--        carry_point   <= carry_pad(carry_pad'left - 1);
--        Carry_OUT     <= carry_pad(carry_pad'left);
--      end generate Using_Pad;
--      No_Pad : if ( C_NUM_PAD = 0 ) generate
--      begin
--        MUXCY_Inst1: MUXCY_L
--          port map (
--            DI => '0',                          -- [in  std_logic]
--            CI => Carry_IN,                     -- [in  std_logic]
--            S  => '1',                          -- [in  std_logic]
--            LO => carry_out_i                   -- [out std_logic]
--          );
          
--        carry_point   <= Carry_IN;
--        Carry_OUT     <= carry_out_i;
--      end generate No_Pad;
      
--      XORCY_Inst1: XORCY
--        port map (
--          LI => '1',                          -- [in  std_logic]
--          CI => carry_point,                  -- [in  std_logic]
--          O  => carry_value                   -- [out std_logic]
--        );
      
--    end generate Using_Inv;
--    No_Inv : if (not C_INV_C) generate
--    begin
--      carry_value   <= carry_pad(carry_pad'left);
--      Carry_OUT     <= carry_pad(carry_pad'left);
--    end generate No_Inv;
    
--    A <= not A_N;
    
--    OR2L_Inst1: OR2L
--      port map (
--        O   => O,                           -- [out std_logic]
--        DI  => carry_value,                 -- [in  std_logic]
--        SRI => A                            -- [in  std_logic]
--      );
  
--  end generate Using_FPGA;

--  -----------------------------------------------------------------------------
--  -- RTL Implementation
--  -----------------------------------------------------------------------------
--  Using_RTL: if (C_TARGET = RTL) generate
--  begin
--    O         <= (     Carry_IN ) or not A_N when not C_INV_C else 
--                 ( not Carry_IN ) or not A_N;
--    Carry_OUT <=       Carry_IN;
--  end generate Using_RTL;

--end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_piperun_step is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE
    );
  port (
    Carry_IN  : in  std_logic;
    Need      : in  std_logic;
    Stall     : in  std_logic;
    Done      : in  std_logic;
    Carry_OUT : out std_logic);
end entity carry_piperun_step;


architecture IMP of carry_piperun_step is
  signal carry_out_i : std_logic;
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL) generate
    signal S      : std_logic;
  begin
    S <= ( not Need ) or ( Need and Done ) or ( Need and not Stall );
    MUXCY_I : MUXCY_L
      port map (
        DI => '0',
        CI => Carry_IN,
        S  => S,
        LO => carry_out_i);    
    Carry_OUT <= carry_out_i;
  end generate Using_FPGA;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= Carry_IN when ( Need               ) = '0' else 
                 Carry_IN when ( Need and     Done  ) = '1' else 
                 Carry_IN when ( Need and not Stall ) = '1' else '0';
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_compare is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_SIZE    : natural
  );
  port (
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    B_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_In  : in  std_logic;
    Carry_Out : out std_logic
  );
end entity carry_compare;


architecture IMP of carry_compare is

  component carry_and is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

  constant C_INPUTS_PER_BIT : integer := 2;
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  

begin  -- architecture IMP

  assign_sigs : process (A_Vec, B_Vec) is
  begin  -- process assign_sigs
    A                   <= (others => '1');
    A(C_SIZE-1 downto 0)  <= A_Vec;
    B                   <= (others => '1');
    B(C_SIZE-1 downto 0)  <= B_Vec;
  end process assign_sigs;

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A, B)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        sel_I  := sel_I and ( ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


--library IEEE;
--use IEEE.std_logic_1164.all;
--use ieee.numeric_std.all;

--library work;
--use work.system_cache_pkg.all;

--library Unisim;
--use Unisim.vcomponents.all;


--entity carry_prio_mux is
--  generic (
--    C_KEEP    : boolean:= false;
--    C_TARGET  : TARGET_FAMILY_TYPE;
--    REVERSE   : boolean;
--    C_IS_COLD : std_logic;
--    C_SIZE    : natural
--  );
--  port (
--    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
--    M_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
--    Carry_In  : in  std_logic;
--    Carry_Out : out std_logic
--  );
--end entity carry_prio_mux;


--architecture IMP of carry_prio_mux is

--  constant C_INPUTS_PER_BIT : integer := 2;
--  constant C_BITS_PER_LUT   : integer := ((Family_To_LUT_Size(C_TARGET)-1) / C_INPUTS_PER_BIT);
--  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

--begin  -- architecture IMP

--  -----------------------------------------------------------------------------
--  -- FPGA implementation
--  -----------------------------------------------------------------------------
--  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate

--    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal data   : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
--    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal A_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
--  begin

--    assign_sigs : process (A_Vec, M_Vec) is
--    begin  -- process assign_sigs
--      A                     <= (others => '1');
--      A(C_SIZE-1 downto 0)  <= A_Vec;
--      M                     <= (others => C_IS_COLD);
--      M(C_SIZE-1 downto 0)  <= M_Vec;
--    end process assign_sigs;
  
--    assign_order : process (A, M) is
--    begin  -- process assign_order
--      A_I <= A;
--      M_I <= M;
      
--      if( REVERSE ) then 
--        for i in 0 to C_SIZE - 1 loop
--          A_I(A_I'left - i) <= A(A'right + i);
--          M_I(M_I'left - i) <= M(M'right + i);
--        end loop; 
--      end if;
--    end process assign_order;
  
--    carry(0) <= Carry_In;
  
--    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
--    begin
--      -- Combine the signals that fit into one LUT.
--      Compare_All_Bits: process(A_I, M_I)
--        variable sel_I   : std_logic;
--        variable data_I  : std_logic;
--      begin
--        sel_I   := '1';
--        data_I  := A_I(C_BITS_PER_LUT * I);
--        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
--          if( M_I(C_BITS_PER_LUT * I + J) = not C_IS_COLD ) then
--            data_I  := A_I(C_BITS_PER_LUT * I + J);
--          end if;
--          sel_I  := sel_I and ( ( C_IS_COLD xnor M_I(C_BITS_PER_LUT * I + J) ) );
--        end loop Compare_Bits;
--        sel(I)  <= sel_I;
--        data(I) <= data_I;
--      end process Compare_All_Bits;
  
--      MUXCY_I : MUXCY_L
--        port map (
--          DI => data(I),
--          CI => Carry(I),
--          S  => sel(I),
--          LO => Carry(I+1));    
  
--    end generate The_Compare;
  
--    Carry_Out <= Carry(C_NR_OF_LUTS);

--  end generate Using_FPGA;

--  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate

--    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal data   : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
--    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal A_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
--    attribute KEEP  : string;
--    attribute KEEP  of sel  : signal is "true";
--    attribute KEEP  of data : signal is "true";
--  begin

--    assign_sigs : process (A_Vec, M_Vec) is
--    begin  -- process assign_sigs
--      A                     <= (others => '1');
--      A(C_SIZE-1 downto 0)  <= A_Vec;
--      M                     <= (others => C_IS_COLD);
--      M(C_SIZE-1 downto 0)  <= M_Vec;
--    end process assign_sigs;
  
--    assign_order : process (A, M) is
--    begin  -- process assign_order
--      A_I <= A;
--      M_I <= M;
      
--      if( REVERSE ) then 
--        for i in 0 to C_SIZE - 1 loop
--          A_I(A_I'left - i) <= A(A'right + i);
--          M_I(M_I'left - i) <= M(M'right + i);
--        end loop; 
--      end if;
--    end process assign_order;
  
--    carry(0) <= Carry_In;
  
--    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
--    begin
--      -- Combine the signals that fit into one LUT.
--      Compare_All_Bits: process(A_I, M_I)
--        variable sel_I   : std_logic;
--        variable data_I  : std_logic;
--      begin
--        sel_I   := '1';
--        data_I  := A_I(C_BITS_PER_LUT * I);
--        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
--          if( M_I(C_BITS_PER_LUT * I + J) = not C_IS_COLD ) then
--            data_I  := A_I(C_BITS_PER_LUT * I + J);
--          end if;
--          sel_I  := sel_I and ( ( C_IS_COLD xnor M_I(C_BITS_PER_LUT * I + J) ) );
--        end loop Compare_Bits;
--        sel(I)  <= sel_I;
--        data(I) <= data_I;
--      end process Compare_All_Bits;
  
--      MUXCY_I : MUXCY_L
--        port map (
--          DI => data(I),
--          CI => Carry(I),
--          S  => sel(I),
--          LO => Carry(I+1));    
  
--    end generate The_Compare;
  
--    Carry_Out <= Carry(C_NR_OF_LUTS);

--  end generate Using_FPGA_Keep;

--  -----------------------------------------------------------------------------
--  -- RTL Implementation
--  -----------------------------------------------------------------------------
--  Using_RTL: if (C_TARGET = RTL) generate
--  begin
--    Find_Highest_Prio: process(A_Vec, M_Vec)
--    begin
--      -- Default assignment.
--      Carry_OUT  <= Carry_IN;
      
--      -- Find highest prio that is selected.
--      if( REVERSE ) then 
--        for i in C_SIZE - 1 to 0 loop
--          if( M_Vec(i) = not C_IS_COLD ) then
--            Carry_OUT <= A_Vec(i);
--          end if;
--        end loop; 
--      else
--        for i in 0 downto C_SIZE - 1 loop
--          if( M_Vec(i) = not C_IS_COLD ) then
--            Carry_OUT <= A_Vec(i);
--          end if;
--        end loop; 
--      end if;
--    end process Find_Highest_Prio;
--  end generate Using_RTL;

--end architecture IMP;


--library IEEE;
--use IEEE.std_logic_1164.all;
--use ieee.numeric_std.all;

--library work;
--use work.system_cache_pkg.all;

--library Unisim;
--use Unisim.vcomponents.all;


--entity carry_prio_mux_enable is
--  generic (
--    C_KEEP    : boolean:= false;
--    C_TARGET  : TARGET_FAMILY_TYPE;
--    REVERSE   : boolean;
--    C_IS_COLD : std_logic;
--    C_SIZE    : natural
--  );
--  port (
--    Carry_In  : in  std_logic;
--    Enable    : in  std_logic;
--    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
--    M_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
--    Carry_Out : out std_logic
--  );
--end entity carry_prio_mux_enable;


--architecture IMP of carry_prio_mux_enable is

--  constant C_INPUTS_PER_BIT : integer := 2;
--  constant C_BITS_PER_LUT   : integer := ((Family_To_LUT_Size(C_TARGET)-2) / C_INPUTS_PER_BIT);
--  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

--begin  -- architecture IMP

--  -----------------------------------------------------------------------------
--  -- FPGA implementation
--  -----------------------------------------------------------------------------
--  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate

--    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal data   : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
--    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal A_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
--  begin

--    assign_sigs : process (A_Vec, M_Vec) is
--    begin  -- process assign_sigs
--      A                     <= (others => '1');
--      A(C_SIZE-1 downto 0)  <= A_Vec;
--      M                     <= (others => C_IS_COLD);
--      M(C_SIZE-1 downto 0)  <= M_Vec;
--    end process assign_sigs;
  
--    assign_order : process (A, M) is
--    begin  -- process assign_order
--      A_I <= A;
--      M_I <= M;
      
--      if( REVERSE ) then 
--        for i in 0 to C_SIZE - 1 loop
--          A_I(A_I'left - i) <= A(A'right + i);
--          M_I(M_I'left - i) <= M(M'right + i);
--        end loop; 
--      end if;
--    end process assign_order;
  
--    carry(0) <= Carry_In;
  
--    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
--    begin
--      -- Combine the signals that fit into one LUT.
--      Compare_All_Bits: process(A_I, M_I, Enable)
--        variable sel_I   : std_logic;
--        variable data_I  : std_logic;
--      begin
--        sel_I   := '1';
--        data_I  := A_I(C_BITS_PER_LUT * I);
--        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
--          if( M_I(C_BITS_PER_LUT * I + J) = not C_IS_COLD ) then
--            data_I  := A_I(C_BITS_PER_LUT * I + J);
--          end if;
--          sel_I  := sel_I and ( ( C_IS_COLD xnor M_I(C_BITS_PER_LUT * I + J) ) );
--        end loop Compare_Bits;
--        sel(I)  <= sel_I or not Enable;
--        data(I) <= data_I;
--      end process Compare_All_Bits;
  
--      MUXCY_I : MUXCY_L
--        port map (
--          DI => data(I),
--          CI => Carry(I),
--          S  => sel(I),
--          LO => Carry(I+1));    
  
--    end generate The_Compare;
  
--    Carry_Out <= Carry(C_NR_OF_LUTS);

--  end generate Using_FPGA;

--  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate

--    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal data   : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
--    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal A_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--    signal M_I    : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
--    attribute KEEP  : string;
--    attribute KEEP  of sel  : signal is "true";
--    attribute KEEP  of data : signal is "true";
--  begin

--    assign_sigs : process (A_Vec, M_Vec) is
--    begin  -- process assign_sigs
--      A                     <= (others => '1');
--      A(C_SIZE-1 downto 0)  <= A_Vec;
--      M                     <= (others => C_IS_COLD);
--      M(C_SIZE-1 downto 0)  <= M_Vec;
--    end process assign_sigs;
  
--    assign_order : process (A, M) is
--    begin  -- process assign_order
--      A_I <= A;
--      M_I <= M;
      
--      if( REVERSE ) then 
--        for i in 0 to C_SIZE - 1 loop
--          A_I(A_I'left - i) <= A(A'right + i);
--          M_I(M_I'left - i) <= M(M'right + i);
--        end loop; 
--      end if;
--    end process assign_order;
  
--    carry(0) <= Carry_In;
  
--    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
--    begin
--      -- Combine the signals that fit into one LUT.
--      Compare_All_Bits: process(A_I, M_I, Enable)
--        variable sel_I   : std_logic;
--        variable data_I  : std_logic;
--      begin
--        sel_I   := '1';
--        data_I  := A_I(C_BITS_PER_LUT * I);
--        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
--          if( M_I(C_BITS_PER_LUT * I + J) = not C_IS_COLD ) then
--            data_I  := A_I(C_BITS_PER_LUT * I + J);
--          end if;
--          sel_I  := sel_I and ( ( C_IS_COLD xnor M_I(C_BITS_PER_LUT * I + J) ) );
--        end loop Compare_Bits;
--        sel(I)  <= sel_I or not Enable;
--        data(I) <= data_I;
--      end process Compare_All_Bits;
  
--      MUXCY_I : MUXCY_L
--        port map (
--          DI => data(I),
--          CI => Carry(I),
--          S  => sel(I),
--          LO => Carry(I+1));    
  
--    end generate The_Compare;
  
--    Carry_Out <= Carry(C_NR_OF_LUTS);

--  end generate Using_FPGA_Keep;

--  -----------------------------------------------------------------------------
--  -- RTL Implementation
--  -----------------------------------------------------------------------------
--  Using_RTL: if (C_TARGET = RTL) generate
--  begin
--    Find_Highest_Prio: process(A_Vec, M_Vec, Enable)
--    begin
--      -- Default assignment.
--      Carry_OUT  <= Carry_IN;
      
--      -- Find highest prio that is selected.
--      if( REVERSE ) then 
--        for i in C_SIZE - 1 downto 0 loop
--          if( M_Vec(i) = not C_IS_COLD and Enable = '1' ) then
--            Carry_OUT <= A_Vec(i);
--          end if;
--        end loop; 
--      else
--        for i in 0 to C_SIZE - 1 loop
--          if( M_Vec(i) = not C_IS_COLD and Enable = '1' ) then
--            Carry_OUT <= A_Vec(i);
--          end if;
--        end loop; 
--      end if;
--    end process Find_Highest_Prio;
--  end generate Using_RTL;

--end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_select_and is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE;
    C_SIZE   : natural
  );
  port (
    Carry_In  : in  std_logic;
    No        : in  natural range 0 to C_SIZE-1;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_Out : out std_logic
  );
end entity carry_select_and;


architecture IMP of carry_select_and is

  component carry_and is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

--  constant C_INPUTS_PER_BIT : integer := 1 + Log2(C_SIZE);
  constant C_INPUTS_PER_BIT : integer := Family_To_LUT_Size(C_TARGET);
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

begin  -- architecture IMP

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A_Vec, No)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        if( No = C_BITS_PER_LUT * I + J ) then
          sel_I  := A_Vec(C_BITS_PER_LUT * I + J);
        end if;
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_select_and_n is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE;
    C_SIZE   : natural
  );
  port (
    Carry_In  : in  std_logic;
    No        : in  natural range 0 to C_SIZE-1;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_Out : out std_logic
  );
end entity carry_select_and_n;


architecture IMP of carry_select_and_n is

  component carry_and_n is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and_n;

--  constant C_INPUTS_PER_BIT : integer := 1 + Log2(C_SIZE);
  constant C_INPUTS_PER_BIT : integer := Family_To_LUT_Size(C_TARGET);
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

begin  -- architecture IMP

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A_Vec, No)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '0';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        if( No = C_BITS_PER_LUT * I + J ) then
          sel_I  := A_Vec(C_BITS_PER_LUT * I + J);
        end if;
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and_n
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A_N       => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_select_or is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE;
    C_SIZE   : natural
  );
  port (
    Carry_In  : in  std_logic;
    No        : in  natural range 0 to C_SIZE-1;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_Out : out std_logic
  );
end entity carry_select_or;


architecture IMP of carry_select_or is

  component carry_or is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_or;

--  constant C_INPUTS_PER_BIT : integer := 1 + Log2(C_SIZE);
  constant C_INPUTS_PER_BIT : integer := Family_To_LUT_Size(C_TARGET);
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

begin  -- architecture IMP

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A_Vec, No)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '0';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        if( No = C_BITS_PER_LUT * I + J ) then
          sel_I  := A_Vec(C_BITS_PER_LUT * I + J);
        end if;
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_or_I1: carry_or
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_select_or_n is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE;
    C_SIZE   : natural
  );
  port (
    Carry_In  : in  std_logic;
    No        : in  natural range 0 to C_SIZE-1;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_Out : out std_logic
  );
end entity carry_select_or_n;


architecture IMP of carry_select_or_n is

  component carry_or_n is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_or_n;

--  constant C_INPUTS_PER_BIT : integer := 1 + Log2(C_SIZE);
  constant C_INPUTS_PER_BIT : integer := Family_To_LUT_Size(C_TARGET);
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

begin  -- architecture IMP

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A_Vec, No)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        if( No = C_BITS_PER_LUT * I + J ) then
          sel_I  := A_Vec(C_BITS_PER_LUT * I + J);
        end if;
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_or_I1: carry_or_n
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A_N       => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_compare_const is
  generic (
    C_KEEP    : boolean:= false;
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_SIGNALS : natural := 1;
    C_SIZE    : natural;
    B_Vec     : std_logic_vector);
  port (
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_In  : in  std_logic;
    Carry_Out : out std_logic);
end entity carry_compare_const;


architecture IMP of carry_compare_const is

  component carry_and is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

  constant C_INPUTS_PER_BIT : integer := C_SIGNALS;
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
begin  -- architecture IMP

  assign_sigs : process (A_Vec) is
  begin  -- process assign_sigs
    A                   <= (others => '1');
    A(C_SIZE-1 downto 0)  <= A_Vec;
    B                   <= (others => '1');
    B(C_SIZE-1 downto 0)  <= B_Vec;
  end process assign_sigs;

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A, B)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        sel_I  := sel_I and ( ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


--library IEEE;
--use IEEE.std_logic_1164.all;
--use ieee.numeric_std.all;

--library work;
--use work.system_cache_pkg.all;

--library Unisim;
--use Unisim.vcomponents.all;


--entity carry_compare_mask is
--  generic (
--    C_KEEP   : boolean:= false;
--    C_TARGET : TARGET_FAMILY_TYPE;
--    C_SIZE   : natural);
--  port (
--    A_Vec      : in  std_logic_vector(C_SIZE-1 downto 0);
--    B_Vec      : in  std_logic_vector(C_SIZE-1 downto 0);
--    Mask       : in  std_logic_vector(C_SIZE-1 downto 0);
--    Carry_In   : in  std_logic;
--    Carry_Out  : out std_logic);
--end entity carry_compare_mask;


--architecture IMP of carry_compare_mask is

--  component carry_and is
--    generic (
--      C_KEEP   : boolean:= false;
--      C_TARGET : TARGET_FAMILY_TYPE);
--    port (
--      Carry_IN  : in  std_logic;
--      A         : in  std_logic;
--      Carry_OUT : out std_logic);
--  end component carry_and;

--  constant C_INPUTS_PER_BIT : integer:= 3;
--  constant C_BITS_PER_LUT   : integer:= (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
--  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

--  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
--  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

--  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--  signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
--  signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);

--begin  -- architecture IMP

--  assign_sigs : process (A_Vec, B_Vec, Mask) is
--  begin  -- process assign_sigs
--    A                   <= (others => '1');
--    A(C_SIZE-1 downto 0)  <= A_Vec;
--    B                   <= (others => '1');
--    B(C_SIZE-1 downto 0)  <= B_Vec;
--    M                   <= (others => '1');
--    M(C_SIZE-1 downto 0)  <= Mask;
--  end process assign_sigs;

--  carry(0) <= Carry_In;

--  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
--  begin
--    -- Combine the signals that fit into one LUT.
--    Compare_All_Bits: process(A, B, M)
--      variable sel_I   : std_logic;
--    begin
--      sel_I  :=  '1';
--      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
--        sel_I  := sel_I and ( not(M(C_BITS_PER_LUT * I + J)) or
--                              ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
--      end loop Compare_Bits;
--      sel(I) <= sel_I;
--    end process Compare_All_Bits;

--    carry_and_I1: carry_and
--      generic map (
--        C_KEEP   => C_KEEP,
--        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
--      port map (
--        Carry_IN  => Carry(I),    -- [in  std_logic]
--        A         => sel(I),      -- [in  std_logic]
--        Carry_OUT => Carry(I+1)); -- [out std_logic]

--  end generate The_Compare;

--  Carry_Out <= Carry(C_NR_OF_LUTS);

--end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity carry_compare_mask_const is
  generic (
    C_KEEP   : boolean:= false;
    C_TARGET : TARGET_FAMILY_TYPE;
    C_SIZE   : natural;
    B_Vec    : std_logic_vector);
  port (
    A_Vec      : in  std_logic_vector(C_SIZE-1 downto 0);
    Mask       : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_In   : in  std_logic;
    Carry_Out  : out std_logic);
end entity carry_compare_mask_const;


architecture IMP of carry_compare_mask_const is

  component carry_and is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE);
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;

  constant C_INPUTS_PER_BIT : integer:= 2;
  constant C_BITS_PER_LUT   : integer:= (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;

  signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
  signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);

  signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  signal M      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);

begin  -- architecture IMP

  assign_sigs : process (A_Vec, Mask) is
  begin  -- process assign_sigs
    A                   <= (others => '1');
    A(C_SIZE-1 downto 0)  <= A_Vec;
    B                   <= (others => '1');
    B(C_SIZE-1 downto 0)  <= B_Vec;
    M                   <= (others => '1');
    M(C_SIZE-1 downto 0)  <= Mask;
  end process assign_sigs;

  carry(0) <= Carry_In;

  The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
  begin
    -- Combine the signals that fit into one LUT.
    Compare_All_Bits: process(A, B, M)
      variable sel_I   : std_logic;
    begin
      sel_I  :=  '1';
      Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
        sel_I  := sel_I and ( not(M(C_BITS_PER_LUT * I + J)) or
                              ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
      end loop Compare_Bits;
      sel(I) <= sel_I;
    end process Compare_All_Bits;

    carry_and_I1: carry_and
      generic map (
        C_KEEP   => C_KEEP,
        C_TARGET => C_TARGET)     -- [TARGET_FAMILY_TYPE]
      port map (
        Carry_IN  => Carry(I),    -- [in  std_logic]
        A         => sel(I),      -- [in  std_logic]
        Carry_OUT => Carry(I+1)); -- [out std_logic]

  end generate The_Compare;

  Carry_Out <= Carry(C_NR_OF_LUTS);

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity comparator is
  generic (
    C_KEEP            : boolean:= false;
    C_TARGET          : TARGET_FAMILY_TYPE;
    C_SIZE            : natural);
  port (
    Carry_IN  : in  std_logic;
    DI        : in  std_logic;
    A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    B_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
    Carry_OUT : out std_logic);
end entity comparator;

architecture IMP of comparator is

  constant C_INPUTS_PER_BIT : integer := 2;
  constant C_BITS_PER_LUT   : integer := (Family_To_LUT_Size(C_TARGET) / C_INPUTS_PER_BIT);
  constant C_NR_OF_LUTS     : integer := (C_SIZE + (C_BITS_PER_LUT - 1)) / C_BITS_PER_LUT;


begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- FPGA implementation
  -----------------------------------------------------------------------------
  Using_FPGA : if (C_TARGET /= RTL and not C_KEEP) generate

    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
    signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
  begin

    assign_sigs : process (A_Vec, B_Vec) is
    begin  -- process assign_sigs
      A                     <= (others => '1');
      A(C_SIZE-1 downto 0)  <= A_Vec;
      B                     <= (others => '1');
      B(C_SIZE-1 downto 0)  <= B_Vec;
    end process assign_sigs;
  
    carry(0) <= Carry_In;
  
    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
    begin
      -- Combine the signals that fit into one LUT.
      Compare_All_Bits: process(A, B)
        variable sel_I   : std_logic;
      begin
        sel_I  :=  '1';
        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
          sel_I  := sel_I and ( ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
        end loop Compare_Bits;
        sel(I) <= sel_I;
      end process Compare_All_Bits;
  
      MUXCY_I : MUXCY_L
        port map (
          DI => DI,
          CI => Carry(I),
          S  => sel(I),
          LO => Carry(I+1));    
  
    end generate The_Compare;
  
    Carry_Out <= Carry(C_NR_OF_LUTS);

  end generate Using_FPGA;

  Using_FPGA_Keep : if (C_TARGET /= RTL and C_KEEP) generate

    signal sel    : std_logic_vector(C_NR_OF_LUTS - 1 downto 0);
    signal carry  : std_logic_vector(C_NR_OF_LUTS     downto 0);
  
    signal A      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
    signal B      : std_logic_vector(C_NR_OF_LUTS * C_BITS_PER_LUT - 1 downto 0);
  
--    attribute KEEP  : string;
--    attribute KEEP  of sel  : signal is "true";
  begin

    assign_sigs : process (A_Vec, B_Vec) is
    begin  -- process assign_sigs
      A                     <= (others => '1');
      A(C_SIZE-1 downto 0)  <= A_Vec;
      B                     <= (others => '1');
      B(C_SIZE-1 downto 0)  <= B_Vec;
    end process assign_sigs;
  
    carry(0) <= Carry_In;
  
    The_Compare : for I in 0 to C_NR_OF_LUTS - 1 generate
    begin
      -- Combine the signals that fit into one LUT.
      Compare_All_Bits: process(A, B)
        variable sel_I   : std_logic;
      begin
        sel_I  :=  '1';
        Compare_Bits: for J in 0 to C_BITS_PER_LUT - 1 loop
          sel_I  := sel_I and ( ( A(C_BITS_PER_LUT * I + J) xnor B(C_BITS_PER_LUT * I + J) ) );
        end loop Compare_Bits;
        sel(I) <= sel_I;
      end process Compare_All_Bits;
  
      MUXCY_I : MUXCY_L
        port map (
          DI => DI,
          CI => Carry(I),
          S  => sel(I),
          LO => Carry(I+1));    
  
    end generate The_Compare;
  
    Carry_Out <= Carry(C_NR_OF_LUTS);

  end generate Using_FPGA_Keep;

  -----------------------------------------------------------------------------
  -- RTL Implementation
  -----------------------------------------------------------------------------
  Using_RTL: if (C_TARGET = RTL) generate
  begin
    Carry_OUT <= Carry_IN when A_Vec = B_Vec else DI;
  end generate Using_RTL;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity reg_ce is
  generic (
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_IS_SET  : std_logic_vector;
    C_CE_LOW  : std_logic_vector;
    C_NUM_CE  : natural;
    C_SIZE    : natural
  );
  port (
    CLK       : in  std_logic;
    SR        : in  std_logic;
    CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
    D         : in  std_logic_vector(C_SIZE   - 1 downto 0);
    Q         : out std_logic_vector(C_SIZE   - 1 downto 0)
  );
end entity reg_ce;


architecture IMP of reg_ce is

  constant C_IS_SET_I       : std_logic_vector(C_SIZE   - 1 downto 0) := C_IS_SET;
  constant C_CE_LOW_I       : std_logic_vector(C_NUM_CE - 1 downto 0) := C_CE_LOW;
  
  signal CE_I               : std_logic_vector(C_NUM_CE - 1 downto 0);
  signal D_I                : std_logic_vector(C_SIZE   - 1 downto 0);
  signal Q_I                : std_logic_vector(C_SIZE   - 1 downto 0);
  
begin  -- architecture IMP

  CE_I  <= CE xor C_CE_LOW_I;

  The_Bit : for I in 0 to C_SIZE - 1 generate
  begin
    -----------------------------------------------------------------------------
    -- FPGA implementation
    -----------------------------------------------------------------------------
    Using_FPGA : if (C_TARGET /= RTL) generate
    begin
      D_I(I)  <= D(I)   when ( reduce_and(CE_I(C_NUM_CE - 1 downto 1)) = '1' ) else 
                 Q_I(I);
      
      Using_Set : if ( C_IS_SET_I(I) = '1' ) generate
      begin
        FDS_Inst : FDSE
          port map (
            Q  => Q_I(I),                       -- [out std_logic]
            C  => CLK,                          -- [in  std_logic]
            CE => CE_I(0),                      -- [in  std_logic]
            D  => D_I(I),                       -- [in  std_logic]
            S  => SR                            -- [in  std_logic]
          );
      end generate Using_Set;
      Using_Reset : if ( C_IS_SET_I(I) /= '1' ) generate
      begin
        FDS_Inst : FDRE
          port map (
            Q  => Q_I(I),                       -- [out std_logic]
            C  => CLK,                          -- [in  std_logic]
            CE => CE_I(0),                      -- [in  std_logic]
            D  => D_I(I),                       -- [in  std_logic]
            R  => SR                            -- [in  std_logic]
          );
      end generate Using_Reset;
      
      Q(I)  <= Q_I(I) ;
    end generate Using_FPGA;
  
    -----------------------------------------------------------------------------
    -- RTL Implementation
    -----------------------------------------------------------------------------
    Using_RTL: if (C_TARGET = RTL) generate
    begin
      Reg_Handler : process (CLK) is
      begin  -- process Length_Handler
        if (CLK'event and CLK = '1') then   -- rising clock edge
          if ( SR = '1' ) then              -- synchronous reset (active high)
            Q(I) <= C_IS_SET_I(I);
          elsif( reduce_and(CE xor C_CE_LOW_I) = '1' ) then
            Q(I) <= D(I);
          end if;
        end if;
      end process Reg_Handler;
    end generate Using_RTL;
  end generate The_Bit;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity reg_ce_kill is
  generic (
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_IS_SET  : std_logic_vector;
    C_CE_LOW  : std_logic_vector;
    C_NUM_CE  : natural;
    C_SIZE    : natural
  );
  port (
    CLK       : in  std_logic;
    SR        : in  std_logic;
    KILL      : in  std_logic;
    CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
    D         : in  std_logic_vector(C_SIZE   - 1 downto 0);
    Q         : out std_logic_vector(C_SIZE   - 1 downto 0)
  );
end entity reg_ce_kill;


architecture IMP of reg_ce_kill is

  constant C_IS_SET_I       : std_logic_vector(C_SIZE   - 1 downto 0) := C_IS_SET;
  constant C_CE_LOW_I       : std_logic_vector(C_NUM_CE - 1 downto 0) := C_CE_LOW;
  
  signal CE_I               : std_logic_vector(C_NUM_CE - 1 downto 0);
  signal D_I                : std_logic_vector(C_SIZE   - 1 downto 0);
  signal Q_I                : std_logic_vector(C_SIZE   - 1 downto 0);
  
begin  -- architecture IMP

  CE_I  <= CE xor C_CE_LOW_I;

  The_Bit : for I in 0 to C_SIZE - 1 generate
  begin
    -----------------------------------------------------------------------------
    -- FPGA implementation
    -----------------------------------------------------------------------------
    Using_FPGA : if (C_TARGET /= RTL) generate
    begin
      D_I(I)  <= D(I)                when ( reduce_and(CE_I(C_NUM_CE - 1 downto 1)) = '1' ) else 
                 Q_I(I) and not KILL;
      
      Using_Set : if ( C_IS_SET_I(I) = '1' ) generate
      begin
        FDS_Inst : FDSE
          port map (
            Q  => Q_I(I),                       -- [out std_logic]
            C  => CLK,                          -- [in  std_logic]
            CE => CE_I(0),                      -- [in  std_logic]
            D  => D_I(I),                       -- [in  std_logic]
            S  => SR                            -- [in  std_logic]
          );
      end generate Using_Set;
      Using_Reset : if ( C_IS_SET_I(I) /= '1' ) generate
      begin
        FDS_Inst : FDRE
          port map (
            Q  => Q_I(I),                       -- [out std_logic]
            C  => CLK,                          -- [in  std_logic]
            CE => CE_I(0),                      -- [in  std_logic]
            D  => D_I(I),                       -- [in  std_logic]
            R  => SR                            -- [in  std_logic]
          );
      end generate Using_Reset;
      
      Q(I)  <= Q_I(I) ;
    end generate Using_FPGA;
  
    -----------------------------------------------------------------------------
    -- RTL Implementation
    -----------------------------------------------------------------------------
    Using_RTL: if (C_TARGET = RTL) generate
    begin
      Reg_Handler : process (CLK) is
      begin  -- process Length_Handler
        if (CLK'event and CLK = '1') then   -- rising clock edge
          if ( SR = '1' ) then              -- synchronous reset (active high)
            Q(I) <= C_IS_SET_I(I);
          elsif( reduce_and(CE xor C_CE_LOW_I) = '1' ) then
            Q(I) <= D(I);
          elsif( KILL = '1' ) then
            Q(I) <= C_IS_SET_I(I);
          end if;
        end if;
      end process Reg_Handler;
    end generate Using_RTL;
  end generate The_Bit;

end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity bit_reg_ce is
  generic (
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_IS_SET  : std_logic;
    C_CE_LOW  : std_logic_vector;
    C_NUM_CE  : natural
  );
  port (
    CLK       : in  std_logic;
    SR        : in  std_logic;
    CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
    D         : in  std_logic;
    Q         : out std_logic
  );
end entity bit_reg_ce;


architecture IMP of bit_reg_ce is

  component reg_ce is
    generic (
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_IS_SET  : std_logic_vector;
      C_CE_LOW  : std_logic_vector;
      C_NUM_CE  : natural;
      C_SIZE    : natural
    );
    port (
      CLK       : in  std_logic;
      SR        : in  std_logic;
      CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
      D         : in  std_logic_vector(C_SIZE   - 1 downto 0);
      Q         : out std_logic_vector(C_SIZE   - 1 downto 0)
    );
  end component reg_ce;
  
  signal D_I                : std_logic_vector(0 downto 0);
  signal Q_I                : std_logic_vector(0 downto 0);
  
begin  -- architecture IMP

  D_I(0) <= D;
  
  Inst: reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (0 downto 0=>C_IS_SET),
      C_CE_LOW  => C_CE_LOW,
      C_NUM_CE  => C_NUM_CE,
      C_SIZE    => 1
    )
    port map(
      CLK       => CLK,
      SR        => SR,
      CE        => CE,
      D         => D_I,
      Q         => Q_I
    );

  Q <= Q_I(0);
  
end architecture IMP;


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.system_cache_pkg.all;

library Unisim;
use Unisim.vcomponents.all;


entity bit_reg_ce_kill is
  generic (
    C_TARGET  : TARGET_FAMILY_TYPE;
    C_IS_SET  : std_logic;
    C_CE_LOW  : std_logic_vector;
    C_NUM_CE  : natural
  );
  port (
    CLK       : in  std_logic;
    SR        : in  std_logic;
    KILL      : in  std_logic;
    CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
    D         : in  std_logic;
    Q         : out std_logic
  );
end entity bit_reg_ce_kill;


architecture IMP of bit_reg_ce_kill is

  component reg_ce_kill is
    generic (
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_IS_SET  : std_logic_vector;
      C_CE_LOW  : std_logic_vector;
      C_NUM_CE  : natural;
      C_SIZE    : natural
    );
    port (
      CLK       : in  std_logic;
      SR        : in  std_logic;
      KILL      : in  std_logic;
      CE        : in  std_logic_vector(C_NUM_CE - 1 downto 0);
      D         : in  std_logic_vector(C_SIZE   - 1 downto 0);
      Q         : out std_logic_vector(C_SIZE   - 1 downto 0)
    );
  end component reg_ce_kill;
  
  signal D_I                : std_logic_vector(0 downto 0);
  signal Q_I                : std_logic_vector(0 downto 0);
  
begin  -- architecture IMP

  D_I(0) <= D;
  
  Inst: reg_ce_kill
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (0 downto 0=>C_IS_SET),
      C_CE_LOW  => C_CE_LOW,
      C_NUM_CE  => C_NUM_CE,
      C_SIZE    => 1
    )
    port map(
      CLK       => CLK,
      SR        => SR,
      KILL      => KILL,
      CE        => CE,
      D         => D_I,
      Q         => Q_I
    );

  Q <= Q_I(0);
  
end architecture IMP;


