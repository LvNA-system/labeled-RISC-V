-------------------------------------------------------------------------------
-- sc_ram_module.vhd - Entity and architecture
-------------------------------------------------------------------------------
--
-- (c) Copyright 2006-2009,2014 Xilinx, Inc. All rights reserved.
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
-- Filename:        sc_ram_module.vhd
--
-- Description:     This file contains instantiations of various block RAM
--                  and an HDL implementation of distributed RAM.
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_ram_module.vhd
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

entity sc_ram_module is
  generic (
    C_TARGET        : TARGET_FAMILY_TYPE;
    C_RECURSIVE_INST: boolean               := false;
    C_WE_A_WIDTH    : positive              := 1;
    C_DATA_A_WIDTH  : positive              := 18;  -- No upper limit
    C_ADDR_A_WIDTH  : natural range 1 to 18 := 11;
    C_WE_B_WIDTH    : positive              := 1;
    C_DATA_B_WIDTH  : positive              := 18;  -- No upper limit
    C_ADDR_B_WIDTH  : natural range 1 to 18 := 11;
    C_FORCE_BRAM    : boolean               := true;
    C_FORCE_LUTRAM  : boolean               := false
  );
  port (
    -- PORT A
    CLKA            : in  std_logic;
    ENA             : in  std_logic;
    WEA             : in  std_logic_vector(C_WE_A_WIDTH-1 downto 0);
    ADDRA           : in  std_logic_vector(C_ADDR_A_WIDTH-1 downto 0);
    DATA_INA        : in  std_logic_vector(C_DATA_A_WIDTH-1 downto 0);
    DATA_OUTA       : out std_logic_vector(C_DATA_A_WIDTH-1 downto 0):= (others=>'0');
    -- PORT B
    CLKB            : in  std_logic;
    ENB             : in  std_logic;
    WEB             : in  std_logic_vector(C_WE_B_WIDTH-1 downto 0);
    ADDRB           : in  std_logic_vector(C_ADDR_B_WIDTH-1 downto 0);
    DATA_INB        : in  std_logic_vector(C_DATA_B_WIDTH-1 downto 0);
    DATA_OUTB       : out std_logic_vector(C_DATA_B_WIDTH-1 downto 0):= (others=>'0')
  );
end entity sc_ram_module;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_ram_module is
  
  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Custom types and Constants
  -----------------------------------------------------------------------------
  
  -- Constants for selected memory.
  constant using_parity           : boolean := ( C_DATA_A_WIDTH = C_DATA_B_WIDTH ) and 
                                               ( C_WE_A_WIDTH   = C_WE_B_WIDTH ) and 
                                               ( ( ( C_DATA_A_WIDTH / C_WE_A_WIDTH ) /= 8 ) or 
                                                 ( ( C_DATA_B_WIDTH / C_WE_B_WIDTH ) /= 8 ) );
  constant max_data_width         : natural := max_of(C_DATA_A_WIDTH, C_DATA_B_WIDTH);
  constant port_a_is_wide         : natural := boolean'pos(C_DATA_A_WIDTH > C_DATA_B_WIDTH);
  constant port_b_is_wide         : natural := boolean'pos(C_DATA_B_WIDTH > C_DATA_A_WIDTH);
  constant target_addr_width      : natural := min_of(C_ADDR_A_WIDTH, C_ADDR_B_WIDTH);
  constant port_ratio             : natural := max_of(C_DATA_A_WIDTH, C_DATA_B_WIDTH) / 
                                               min_of(C_DATA_A_WIDTH, C_DATA_B_WIDTH);

    
  -- Constants for architecture properties.
  constant arch_36kbit_bram       : boolean := Has_Target(C_TARGET, BRAM_36k);
  constant write_mode             : string := "READ_FIRST";
  constant sim_check_mode         : string := "NONE";
  
  
  -- Constants/Types for memory types and properties.
  type bram_kind is (DISTRAM, B36_Sx, B72_S1);
  subtype allowed_addr_bits is natural range 1 to 18;

  type BRAM_TYPE is record
    What_Kind   : bram_kind;
    Data_size   : natural;
    No_WE       : natural;
    Addr_size   : natural;
    Parity_size : natural;
    Par_Padding : natural;
  end record BRAM_TYPE;
  
  type ramb36_index_vector_type   is array (boolean) of natural;
  constant ramb36_index_vector    : ramb36_index_vector_type := (false => 0, true => 10);
  constant is_ram36               : natural                  := ramb36_index_vector(arch_36kbit_bram);

  type maddr_index_vector_type    is array (bram_kind) of allowed_addr_bits;
  constant bram_max_addr_size     : maddr_index_vector_type := (DISTRAM => 7, 
                                                                B36_Sx  => 15, 
                                                                B72_S1  => 16);
  
  
  -- Constants/Types for size dependencies.
  type ram_addr_vector        is array (allowed_addr_bits) of natural;
  type kind_type              is (mixed, bram, lutram);
  type ram_select_vector      is array (kind_type) of ram_addr_vector;
  constant ram_select_lookup : ram_select_vector :=
    (mixed  => (1, 2, 3, 4, 5, 6, 7, 8, 9+is_ram36, 10+is_ram36, 11+is_ram36, 12+is_ram36,
                13+is_ram36, 14+is_ram36, 15+is_ram36, 16+is_ram36, 17+is_ram36, 18+is_ram36),
     bram   => (9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36, 9+is_ram36,
                9+is_ram36, 9+is_ram36, 9+is_ram36, 10+is_ram36, 11+is_ram36, 12+is_ram36,
                13+is_ram36, 14+is_ram36, 15+is_ram36, 16+is_ram36, 17+is_ram36, 18+is_ram36),
     lutram => (1, 2, 3, 4, 5, 6, 7, 8, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38));

  type bram_type_vector is array (natural range 1 to 38) of BRAM_TYPE;
  constant bram_type_lookup : bram_type_vector :=
    (1  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 1,  Parity_size => 0, Par_Padding => 0),
     2  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 2,  Parity_size => 0, Par_Padding => 0),
     3  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 3,  Parity_size => 0, Par_Padding => 0),
     4  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 4,  Parity_size => 0, Par_Padding => 0),
     5  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 5,  Parity_size => 0, Par_Padding => 0),
     6  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 6,  Parity_size => 0, Par_Padding => 0),
     7  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 7,  Parity_size => 0, Par_Padding => 0),
     8  => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 8,  Parity_size => 0, Par_Padding => 0),
     
     9  => (what_kind => B36_Sx,  Data_size => 32, No_WE => 4, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     10 => (what_kind => B36_Sx,  Data_size => 32, No_WE => 4, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     11 => (what_kind => B36_Sx,  Data_size => 16, No_WE => 2, Addr_size => 11, Parity_size => 2, Par_Padding => 0),
     12 => (what_kind => B36_Sx,  Data_size => 8,  No_WE => 1, Addr_size => 12, Parity_size => 1, Par_Padding => 0),
     13 => (what_kind => B36_Sx,  Data_size => 4,  No_WE => 1, Addr_size => 13, Parity_size => 0, Par_Padding => 1),
     14 => (what_kind => B36_Sx,  Data_size => 2,  No_WE => 1, Addr_size => 14, Parity_size => 0, Par_Padding => 1),
     15 => (what_kind => B36_Sx,  Data_size => 1,  No_WE => 1, Addr_size => 15, Parity_size => 0, Par_Padding => 1),
     16 => (what_kind => B36_Sx,  Data_size => 1,  No_WE => 1, Addr_size => 16, Parity_size => 0, Par_Padding => 1),
     17 => (what_kind => B36_Sx,  Data_size => 1,  No_WE => 1, Addr_size => 17, Parity_size => 0, Par_Padding => 1),
     18 => (what_kind => B36_Sx,  Data_size => 1,  No_WE => 1, Addr_size => 18, Parity_size => 0, Par_Padding => 1),
     
     19 => (what_kind => B36_Sx,  Data_size => 32, No_WE => 4, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     20 => (what_kind => B36_Sx,  Data_size => 32, No_WE => 4, Addr_size => 10, Parity_size => 4, Par_Padding => 0),
     21 => (what_kind => B36_Sx,  Data_size => 16, No_WE => 2, Addr_size => 11, Parity_size => 2, Par_Padding => 0),
     22 => (what_kind => B36_Sx,  Data_size => 8,  No_WE => 1, Addr_size => 12, Parity_size => 1, Par_Padding => 0),
     23 => (what_kind => B36_Sx,  Data_size => 4,  No_WE => 1, Addr_size => 13, Parity_size => 0, Par_Padding => 1),
     24 => (what_kind => B36_Sx,  Data_size => 2,  No_WE => 1, Addr_size => 14, Parity_size => 0, Par_Padding => 1),
     25 => (what_kind => B36_Sx,  Data_size => 1,  No_WE => 1, Addr_size => 15, Parity_size => 0, Par_Padding => 1),
     26 => (what_kind => B72_S1,  Data_size => 1,  No_WE => 1, Addr_size => 16, Parity_size => 0, Par_Padding => 1),
     27 => (what_kind => B72_S1,  Data_size => 1,  No_WE => 1, Addr_size => 17, Parity_size => 0, Par_Padding => 1),
     28 => (what_kind => B72_S1,  Data_size => 1,  No_WE => 1, Addr_size => 18, Parity_size => 0, Par_Padding => 1),
     
     29 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 9,  Parity_size => 0, Par_Padding => 0),
     30 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 10, Parity_size => 0, Par_Padding => 0),
     31 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 11, Parity_size => 0, Par_Padding => 0),
     32 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 12, Parity_size => 0, Par_Padding => 0),
     33 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 13, Parity_size => 0, Par_Padding => 0),
     34 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 14, Parity_size => 0, Par_Padding => 0),
     35 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 15, Parity_size => 0, Par_Padding => 0),
     36 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 16, Parity_size => 0, Par_Padding => 0),
     37 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 17, Parity_size => 0, Par_Padding => 0),
     38 => (what_kind => DISTRAM, Data_size => 1,  No_WE => 1, Addr_size => 18, Parity_size => 0, Par_Padding => 0)
   );

  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  -- Function to detect how to select memory settings.
  function select_kind (force_bram : boolean; force_lutram : boolean) return kind_type is
  begin
    if force_bram then
      return bram;
    elsif force_lutram then
      return lutram;
    end if;
    return mixed;
  end function select_kind;
  
  
  -- Function to return the maximum number of address bits to be use.
  function select_max_addr (ratio : natural; kind : kind_type) return natural is
    constant wide_has_we        : natural := boolean'pos(( port_a_is_wide = 1 and C_WE_A_WIDTH > 1 ) or 
                                                         ( port_b_is_wide = 1 and C_WE_B_WIDTH > 1 ));
    variable best_addr_so_far   : natural := 0;
  begin
    -- Filter impossible configurations.
    if( ( port_ratio > 4 ) and 
        ( ( port_a_is_wide = 1 and C_WE_A_WIDTH > 1 ) or 
          ( port_b_is_wide = 1 and C_WE_B_WIDTH > 1 ) ) )then
      return 0;
    end if;
    
    -- Search for best fit.
    for I in allowed_addr_bits'low to allowed_addr_bits'high loop
      if( ( ( ratio               ) <= bram_type_lookup(ram_select_lookup(kind)(I)).Data_size ) and 
          ( ( wide_has_we*8*ratio ) <= bram_type_lookup(ram_select_lookup(kind)(I)).Data_size ) and 
          ( ( B72_S1              ) /= bram_type_lookup(ram_select_lookup(kind)(I)).what_kind ) ) then
        if( target_addr_width <= bram_type_lookup(ram_select_lookup(kind)(I)).Addr_size ) then
          -- Optimal found.
          return bram_type_lookup(ram_select_lookup(kind)(I)).Addr_size;
        elsif( best_addr_so_far < bram_type_lookup(ram_select_lookup(kind)(I)).Addr_size ) then
          -- Possible candidate.
          best_addr_so_far  := bram_type_lookup(ram_select_lookup(kind)(I)).Addr_size;
        end if;
      end if;
    end loop;
    
    -- Return best option available.
    return best_addr_so_far;
  end function select_max_addr;
  
  
  -- Calculate amount of RAMs needed to satisfy depth, width and we settings.
  function calc_nr_of_brams (What_BRAM : BRAM_TYPE; 
                             data_size : natural; we_size : natural; using_parity : boolean) return natural is
    constant ram_full_data_width  : natural := What_BRAM.Data_size + What_BRAM.Parity_size;
    constant ram_data_per_we      : natural := ram_full_data_width / What_BRAM.No_WE;
    constant data_per_we          : natural := data_size / we_size;
    constant ram_we_per_we        : natural := ( data_per_we + ram_data_per_we - 1 ) / ram_data_per_we;
    constant total_ram_we         : natural := ram_we_per_we * we_size;
  begin
    if using_parity then
      return (total_ram_we + What_BRAM.No_WE - 1) / What_BRAM.No_WE;
    else
      return (data_size + What_BRAM.Data_size - 1) / What_BRAM.Data_size;
    end if;
  end function calc_nr_of_brams;
  
  
  -- Procedure to handle assignment of vectors with different sizes.
  procedure assign (signal output : out std_logic_vector; signal input : in std_logic_vector) is
  begin
    if input'length = 1 then
      output <= (output'range => input(input'right));
    elsif input'length > output'length then
      output <= input(input'right + output'length - 1 downto input'right);
    else
      output <= (output'range => '0');
      output(output'right + input'length - 1 downto output'right) <= input;
    end if;
  end procedure assign;
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_ram_module is
    generic (
      C_TARGET        : TARGET_FAMILY_TYPE;
      C_RECURSIVE_INST: boolean               := false;
      C_WE_A_WIDTH    : positive              := 1;
      C_DATA_A_WIDTH  : positive              := 18;  -- No upper limit
      C_ADDR_A_WIDTH  : natural range 1 to 18 := 11;
      C_WE_B_WIDTH    : positive              := 1;
      C_DATA_B_WIDTH  : positive              := 18;  -- No upper limit
      C_ADDR_B_WIDTH  : natural range 1 to 18 := 11;
      C_FORCE_BRAM    : boolean               := true;
      C_FORCE_LUTRAM  : boolean               := false
    );
    port (
      -- PORT A
      CLKA            : in  std_logic;
      ENA             : in  std_logic;
      WEA             : in  std_logic_vector(C_WE_A_WIDTH-1 downto 0);
      ADDRA           : in  std_logic_vector(C_ADDR_A_WIDTH-1 downto 0);
      DATA_INA        : in  std_logic_vector(C_DATA_A_WIDTH-1 downto 0);
      DATA_OUTA       : out std_logic_vector(C_DATA_A_WIDTH-1 downto 0);
      -- PORT B
      CLKB            : in  std_logic;
      ENB             : in  std_logic;
      WEB             : in  std_logic_vector(C_WE_B_WIDTH-1 downto 0);
      ADDRB           : in  std_logic_vector(C_ADDR_B_WIDTH-1 downto 0);
      DATA_INB        : in  std_logic_vector(C_DATA_B_WIDTH-1 downto 0);
      DATA_OUTB       : out std_logic_vector(C_DATA_B_WIDTH-1 downto 0)
    );
  end component sc_ram_module;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  
  constant What_Kind              : kind_type := select_kind(C_FORCE_BRAM, C_FORCE_LUTRAM);
  
  type addr_index_vector_type     is array (boolean) of natural;
  constant addr_index_vector      : addr_index_vector_type := (false  => C_ADDR_A_WIDTH, 
                                                               true   => select_max_addr(port_ratio, What_Kind));
  constant max_allowed_addr_bits  : natural                  := addr_index_vector(port_ratio /= 1);

  constant What_BRAM              : BRAM_TYPE := bram_type_lookup(ram_select_lookup(What_Kind)(max_allowed_addr_bits));
  
  constant nr_of_brams            : natural := calc_nr_of_brams(What_BRAM, max_data_width, C_WE_A_WIDTH, using_parity);
  constant just_data_bits_size    : natural := nr_of_brams * What_BRAM.Data_size;
  constant just_par_bits_size     : natural := nr_of_brams * What_BRAM.Parity_size + What_BRAM.Par_Padding;
  constant rs                     : natural := What_BRAM.Data_size;
  constant wers                   : natural := rs / 8;
  constant ws                     : natural := just_data_bits_size / port_ratio;
  constant wews                   : natural := ws / 8;
  constant no_ws_ram              : natural := ws / rs;
  constant cs                     : natural := rs / port_ratio;
  constant wecs                   : natural := cs / 8;
  constant no_cs                  : natural := ws / cs;

  constant addr_size_a            : natural := max_of(What_BRAM.Addr_size, C_ADDR_A_WIDTH);
  constant addr_size_b            : natural := max_of(What_BRAM.Addr_size, C_ADDR_B_WIDTH);
  
  constant a_raw_data_width       : natural := What_BRAM.Data_size / sel(port_b_is_wide = 1, port_ratio, 1);
  constant b_raw_data_width       : natural := What_BRAM.Data_size / sel(port_a_is_wide = 1, port_ratio, 1);
  
  constant a_just_data_bits_size  : natural := nr_of_brams * a_raw_data_width;
  constant b_just_data_bits_size  : natural := nr_of_brams * b_raw_data_width;
  
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- local signals for padding if the size doesn't match perfectly
  
  signal addra_i        : std_logic_vector(addr_size_a-1 downto 0);
  signal addrb_i        : std_logic_vector(addr_size_b-1 downto 0);

  signal wea_i          : std_logic_vector((a_just_data_bits_size+7)/8-1 downto 0);
  signal data_ina_i     : std_logic_vector(a_just_data_bits_size-1 downto 0);
  signal data_ina_ii    : std_logic_vector(a_just_data_bits_size-1 downto 0);
  signal data_outa_i    : std_logic_vector(a_just_data_bits_size-1 downto 0) := (others => '0');
  signal data_outa_ii   : std_logic_vector(a_just_data_bits_size-1 downto 0) := (others => '0');
  signal web_i          : std_logic_vector((b_just_data_bits_size+7)/8-1 downto 0);
  signal data_inb_i     : std_logic_vector(b_just_data_bits_size-1 downto 0);
  signal data_inb_ii    : std_logic_vector(b_just_data_bits_size-1 downto 0);
  signal data_outb_i    : std_logic_vector(b_just_data_bits_size-1 downto 0) := (others => '0');
  signal data_outb_ii   : std_logic_vector(b_just_data_bits_size-1 downto 0) := (others => '0');

  signal data_inpa_i    : std_logic_vector(just_par_bits_size-1 downto 0);
  signal data_inpb_i    : std_logic_vector(just_par_bits_size-1 downto 0);
  signal data_inpa_ii   : std_logic_vector(just_par_bits_size-1 downto 0);
  signal data_inpb_ii   : std_logic_vector(just_par_bits_size-1 downto 0);
  signal data_outpa_i   : std_logic_vector(just_par_bits_size-1 downto 0) := (others => '0');
  signal data_outpb_i   : std_logic_vector(just_par_bits_size-1 downto 0) := (others => '0');
  signal data_outpa_ii  : std_logic_vector(just_par_bits_size-1 downto 0) := (others => '0');
  signal data_outpb_ii  : std_logic_vector(just_par_bits_size-1 downto 0) := (others => '0');

  
begin  -- architecture IMP


  -----------------------------------------------------------------------------
  -- Check valid configurations
  -----------------------------------------------------------------------------
  
  assert not( ( port_ratio > 4 ) and 
              ( ( port_a_is_wide = 1 and C_WE_A_WIDTH > 1 ) or 
                ( port_b_is_wide = 1 and C_WE_B_WIDTH > 1 ) ) )
    report   "sc_ram_module: illegal combination of C_WE_WIDTH and C_DATA_WIDTH ratios."
    severity failure;
  
  
  -----------------------------------------------------------------------------
  -- Padding and Splitting of Buses
  -----------------------------------------------------------------------------
  
  Padding_Addr_Vectors : process(ADDRA, ADDRB) is
  begin  -- process Padding_Addr_Vectors
    addra_i              <= (others => '1');
    addra_i(ADDRA'range) <= ADDRA;
    addrb_i              <= (others => '1');
    addrb_i(ADDRB'range) <= ADDRB;
  end process Padding_Addr_Vectors;    
  
  
  Divide_Data_Bus: if ( using_parity ) generate
    constant ram_full_data_width  : natural := What_BRAM.Data_size + What_BRAM.Parity_size;
    constant data_size            : natural := What_BRAM.Data_size;
    constant par_size             : natural := What_BRAM.Parity_size;
    constant pure_ram_data_per_we : natural := What_BRAM.Data_size / What_BRAM.No_WE;
    constant pure_ram_par_per_we  : natural := What_BRAM.Parity_size / What_BRAM.No_WE;
    constant ram_data_per_we      : natural := ram_full_data_width / What_BRAM.No_WE;
    constant data_per_we          : natural := C_DATA_A_WIDTH / C_WE_A_WIDTH;
    constant ram_we_per_we        : natural := ( data_per_we + ram_data_per_we - 1 ) / ram_data_per_we;
    constant total_ram_we         : natural := ram_we_per_we * C_WE_A_WIDTH;
    constant ram_all_data_per_we  : natural := ram_we_per_we * pure_ram_data_per_we;
    constant ram_all_par_per_we   : natural := ram_we_per_we * pure_ram_par_per_we;
    constant data_part            : natural := min_of(data_per_we, ram_all_data_per_we);
    constant par_part             : integer := data_per_we - data_part;
    
  begin
    padding_vectors : process(DATA_INA, DATA_INB, WEA, WEB, data_outa_ii,
                              data_outb_ii, data_outpa_ii, data_outpb_ii) is
    begin  -- process padding_vectors
      -- Default
      data_ina_ii  <= (others => '0');
      data_inb_ii  <= (others => '0');
      data_inpa_ii <= (others => '0');
      data_inpb_ii <= (others => '0');
      wea_i        <= (others => '0');
      web_i        <= (others => '0');
      
      if (What_BRAM.What_Kind = DISTRAM) then
        assign(wea_i, WEA);
        assign(web_i, WEB);
      end if;
      
      -- Assign.
      for I in 0 to C_WE_A_WIDTH-1 loop
        if (What_BRAM.What_Kind /= DISTRAM) then
          wea_i((I+1)*ram_we_per_we - 1 downto I*ram_we_per_we) <= (others=>WEA(I));
          web_i((I+1)*ram_we_per_we - 1 downto I*ram_we_per_we) <= (others=>WEB(I));
        end if;
        
        data_ina_ii(I*ram_all_data_per_we + data_part - 1 downto I*ram_all_data_per_we)  <= DATA_INA(I*data_per_we + data_part - 1 downto I*data_per_we);
        data_inb_ii(I*ram_all_data_per_we + data_part - 1 downto I*ram_all_data_per_we)  <= DATA_INB(I*data_per_we + data_part - 1 downto I*data_per_we);
        
        DATA_OUTA(I*data_per_we + data_part - 1 downto I*data_per_we) <= data_outa_ii(I*ram_all_data_per_we + data_part - 1 downto I*ram_all_data_per_we);
        DATA_OUTB(I*data_per_we + data_part - 1 downto I*data_per_we) <= data_outb_ii(I*ram_all_data_per_we + data_part - 1 downto I*ram_all_data_per_we);
        
        if( par_part > 0 ) then
          data_inpa_ii(I*ram_all_par_per_we + par_part - 1 downto I*ram_all_par_per_we) <= DATA_INA((I+1)*data_per_we - 1 downto I*data_per_we + data_part);
          data_inpb_ii(I*ram_all_par_per_we + par_part - 1 downto I*ram_all_par_per_we) <= DATA_INB((I+1)*data_per_we - 1 downto I*data_per_we + data_part);
          
          DATA_OUTA((I+1)*data_per_we - 1 downto I*data_per_we + data_part) <= data_outpa_ii(I*ram_all_par_per_we + par_part - 1 downto I*ram_all_par_per_we);
          DATA_OUTB((I+1)*data_per_we - 1 downto I*data_per_we + data_part) <= data_outpb_ii(I*ram_all_par_per_we + par_part - 1 downto I*ram_all_par_per_we);
        end if;
      end loop;
    end process padding_vectors;
    
  end generate Divide_Data_Bus;
    
  No_Divide_Data_Bus: if ( not using_parity ) generate
  begin
    Data_Size_Less_Than_Bram_Size_A: if (C_DATA_A_WIDTH < just_data_bits_size) generate
    begin
      padding_vectors : process(DATA_INA, data_outa_i) is
      begin  -- process padding_vectors
        -- Default drive the parity inputs to '0'
        data_inpa_i <= (others => '0');
  
        data_ina_i                 <= (others => '0');
        data_ina_i(DATA_INA'range) <= DATA_INA;
        DATA_OUTA                  <= data_outa_i(DATA_OUTA'range);
      end process padding_vectors;    
    end generate Data_Size_Less_Than_Bram_Size_A;
  
    Data_Size_Less_Than_Bram_Size_B: if (C_DATA_B_WIDTH < just_data_bits_size) generate
    begin
      padding_vectors : process(DATA_INB, data_outb_i) is
      begin  -- process padding_vectors
        -- Default drive the parity inputs to '0'
        data_inpb_i <= (others => '0');
  
        data_inb_i                 <= (others => '0');
        data_inb_i(DATA_INB'range) <= DATA_INB;
        DATA_OUTB                  <= data_outb_i(DATA_OUTB'range);
      end process padding_vectors;    
    end generate Data_Size_Less_Than_Bram_Size_B;
  
    Data_Size_Equal_To_BRAM_Size_A: if (C_DATA_A_WIDTH = just_data_bits_size) generate
    begin
      padding_vectors : process(DATA_INA, data_outa_i) is
      begin  -- process padding_vectors
        -- Default drive the parity inputs to '0'
        data_inpa_i <= (others => '0');
  
        data_ina_i <= DATA_INA;
        DATA_OUTA  <= data_outa_i;
      end process padding_vectors;    
    end generate Data_Size_Equal_To_BRAM_Size_A;
    
    Data_Size_Equal_To_BRAM_Size_B: if (C_DATA_B_WIDTH = just_data_bits_size) generate
    begin
      padding_vectors : process(DATA_INB, data_outb_i) is
      begin  -- process padding_vectors
        -- Default drive the parity inputs to '0'
        data_inpb_i <= (others => '0');
  
        data_inb_i <= DATA_INB;
        DATA_OUTB  <= data_outb_i;
      end process padding_vectors;    
    end generate Data_Size_Equal_To_BRAM_Size_B;
    
    Reorder_Data_Bus_A: if ( ( port_ratio /= 1 ) and ( C_DATA_A_WIDTH > C_DATA_B_WIDTH ) and not C_RECURSIVE_INST ) generate
    begin
      assign(web_i, WEB);
      data_inb_ii <= data_inb_i;
      data_outb_i <= data_outb_ii;
      
      The_Src: for I in 0 to port_ratio-1 generate
      begin
        The_Dst: for J in 0 to no_cs-1 generate
        begin
          A_Small_WE: if( C_WE_A_WIDTH = 1 ) generate
          begin
            assign(wea_i, WEA);
          end generate A_Small_WE;
          A_Wide_WE: if( C_WE_A_WIDTH /= 1 ) generate
          begin
            wea_i((I+1)*wecs + J*wers - 1 downto I*wecs + J*wers) <= WEA(I*wews + (J+1)*wecs - 1 downto I*wews + J*wecs);
          end generate A_Wide_WE;
          data_ina_ii((I+1)*cs + J*rs - 1 downto I*cs + J*rs)   <= data_ina_i(I*ws + (J+1)*cs - 1 downto I*ws + J*cs);
          data_outa_i(I*ws + (J+1)*cs - 1 downto I*ws + J*cs)   <= data_outa_ii((I+1)*cs + J*rs - 1 downto I*cs + J*rs);
        end generate The_Dst;
      end generate The_Src;
      
    end generate Reorder_Data_Bus_A;
    
    Reorder_Data_Bus_B: if ( ( port_ratio /= 1 ) and ( C_DATA_A_WIDTH < C_DATA_B_WIDTH ) and not C_RECURSIVE_INST ) generate
    begin
      assign(wea_i, WEA);
      data_ina_ii <= data_ina_i;
      data_outa_i <= data_outa_ii;
      
      The_Src: for I in 0 to port_ratio-1 generate
      begin
        The_Dst: for J in 0 to no_cs-1 generate
        begin
          B_Small_WE: if( C_WE_B_WIDTH = 1 ) generate
          begin
            assign(web_i, WEB);
          end generate B_Small_WE;
          B_Wide_WE: if( C_WE_B_WIDTH /= 1 ) generate
          begin
            web_i((I+1)*wecs + J*wers - 1 downto I*wecs + J*wers) <= WEB(I*wews + (J+1)*wecs - 1 downto I*wews + J*wecs);
          end generate B_Wide_WE;
          data_inb_ii((I+1)*cs + J*rs - 1 downto I*cs + J*rs)   <= data_inb_i(I*ws + (J+1)*cs - 1 downto I*ws + J*cs);
          data_outb_i(I*ws + (J+1)*cs - 1 downto I*ws + J*cs)   <= data_outb_ii((I+1)*cs + J*rs - 1 downto I*cs + J*rs);
        end generate The_Dst;
      end generate The_Src;
      
    end generate Reorder_Data_Bus_B;
      
    No_Reorder_Data_Bus: if ( port_ratio = 1 or C_RECURSIVE_INST ) generate
    begin
      assign(wea_i, WEA);
      assign(web_i, WEB);
      
      data_ina_ii <= data_ina_i;
      data_inb_ii <= data_inb_i;
      
      data_outa_i <= data_outa_ii;
      data_outb_i <= data_outb_ii;
    end generate No_Reorder_Data_Bus;
    
  end generate No_Divide_Data_Bus;
  
  
  -----------------------------------------------------------------------------
  -- BlockRAM
  -----------------------------------------------------------------------------
  
  Using_BRAM : if (What_BRAM.What_Kind /= DISTRAM) generate
    constant native_max_addr_size   : natural := min_of(max_allowed_addr_bits, 
                                                        bram_max_addr_size(What_BRAM.What_Kind));
    constant native_max_addr_size_a : natural := native_max_addr_size + port_b_is_wide * Log2(port_ratio);
    constant native_max_addr_size_b : natural := native_max_addr_size + port_a_is_wide * Log2(port_ratio);
  begin
    Recursive : if (target_addr_width > native_max_addr_size) generate
    
      constant num_ram_modules : integer:= 2 ** ( target_addr_width - native_max_addr_size );
      type ram_a_output is array (0 to num_ram_modules - 1) of std_logic_vector(C_DATA_A_WIDTH-1 downto 0);
      type ram_b_output is array (0 to num_ram_modules - 1) of std_logic_vector(C_DATA_B_WIDTH-1 downto 0);
      
      signal addra_cmb  : std_logic_vector(target_addr_width - native_max_addr_size - 1 downto 0);
      signal addrb_cmb  : std_logic_vector(target_addr_width - native_max_addr_size - 1 downto 0);
      signal addra_q    : std_logic_vector(target_addr_width - native_max_addr_size - 1 downto 0);
      signal addrb_q    : std_logic_vector(target_addr_width - native_max_addr_size - 1 downto 0);
      signal data_a     : ram_a_output;
      signal data_b     : ram_b_output;
      
    begin
      -- Extract module address.
      addra_cmb <= addra_i(addra_i'left downto addra_i'right + native_max_addr_size_a);
      addrb_cmb <= addrb_i(addrb_i'left downto addrb_i'right + native_max_addr_size_b);

      -- Instantiate all modules needed for the memory.
      The_RAM_INSTs : for J in 0 to num_ram_modules-1 generate
        signal wea_masked : std_logic_vector(C_WE_A_WIDTH-1 downto 0);
        signal web_masked : std_logic_vector(C_WE_B_WIDTH-1 downto 0);
      begin

        -- Generate local write enable
        wea_masked <= wea_i(C_WE_A_WIDTH-1 downto 0) when to_integer(unsigned(addra_cmb)) = J else (others=>'0');
        web_masked <= web_i(C_WE_B_WIDTH-1 downto 0) when to_integer(unsigned(addrb_cmb)) = J else (others=>'0');
 
        RAM_Inst: sc_ram_module
          generic map (
            C_TARGET          => C_TARGET,
            C_RECURSIVE_INST  => true,
            C_WE_A_WIDTH      => C_WE_A_WIDTH,
            C_DATA_A_WIDTH    => C_DATA_A_WIDTH,
            C_ADDR_A_WIDTH    => native_max_addr_size_a,
            C_WE_B_WIDTH      => C_WE_B_WIDTH,
            C_DATA_B_WIDTH    => C_DATA_B_WIDTH,
            C_ADDR_B_WIDTH    => native_max_addr_size_b,
            C_FORCE_BRAM      => C_FORCE_BRAM,
            C_FORCE_LUTRAM    => C_FORCE_LUTRAM)
          port map(
            -- PORT A
            CLKA      => CLKA,
            WEA       => wea_masked,
            ENA       => ENA,
            ADDRA     => addra_i(addra_i'right + native_max_addr_size_a - 1 downto addra_i'right),
            DATA_INA  => data_ina_ii(C_DATA_A_WIDTH - 1 downto 0),
            DATA_OUTA => data_a(J),
            -- PORT B
            CLKB      => CLKB,
            WEB       => web_masked,
            ENB       => ENB,
            ADDRB     => addrb_i(addrb_i'right + native_max_addr_size_b - 1 downto addrb_i'right),
            DATA_INB  => data_inb_ii(C_DATA_B_WIDTH - 1 downto 0),
            DATA_OUTB => data_b(J)
            );
      end generate The_RAM_INSTs;

      -- Clock address for multiplexing the delayed memory data.
      PortA : process(CLKA)
      begin
        if CLKA'event and CLKA = '1' then
          if ENA = '1' then
            addra_q <= addra_cmb;
          end if;
        end if;
      end process PortA;

      PortB : process(CLKB)
      begin
        if CLKB'event and CLKB = '1' then
          if ENB = '1' then
            addrb_q <= addrb_cmb;
          end if;
        end if;
      end process PortB;

      -- Multiplex data from memory.
      data_outa_ii  <= data_a(to_integer(unsigned(addra_q)));
      data_outb_ii  <= data_b(to_integer(unsigned(addrb_q)));

    end generate Recursive;

    Native : if (target_addr_width <= native_max_addr_size) generate
    begin
      -----------------------------------------------------------------------------
      -- BlockRAM 36kbit
      -----------------------------------------------------------------------------
      
      Using_B36_Sx : if (What_BRAM.What_Kind = B36_Sx) generate
        constant a_data_width     : natural := a_raw_data_width + a_raw_data_width/8;
        constant b_data_width     : natural := b_raw_data_width + b_raw_data_width/8;
        constant a_we_data_width  : natural := max_of(1, a_raw_data_width / 8);
        constant b_we_data_width  : natural := max_of(1, b_raw_data_width / 8);
        signal addra_ii : std_logic_vector(15 downto 0);
        signal addrb_ii : std_logic_vector(15 downto 0);

      begin
    
        Pad_RAMB36_Addresses : process (addra_i, addrb_i) is
          begin  -- process Pad_RAMB36_Addresses
            -- Address bit 15 is only used when BRAMs are cascaded
            addra_ii                              <= (others => '1');
            addra_ii(14-native_max_addr_size_a+C_ADDR_A_WIDTH downto 15-native_max_addr_size_a) <= addra_i(C_ADDR_A_WIDTH - 1 downto 0);
            addrb_ii                              <= (others => '1');
            addrb_ii(14-native_max_addr_size_b+C_ADDR_B_WIDTH downto 15-native_max_addr_size_b) <= addrb_i(C_ADDR_B_WIDTH - 1 downto 0);
        end process Pad_RAMB36_Addresses;
    
        The_BRAMs : for I in 0 to nr_of_brams-1 generate
          signal wea_ii : std_logic_vector( 3 downto 0);
          signal dia_i  : std_logic_vector(31 downto 0);
          signal diap_i : std_logic_vector( 3 downto 0);
          signal doa_i  : std_logic_vector(31 downto 0);
          signal doap_i : std_logic_vector( 3 downto 0);
          signal web_ii : std_logic_vector( 3 downto 0);
          signal web_iii: std_logic_vector( 7 downto 0);
          signal dib_i  : std_logic_vector(31 downto 0);
          signal dibp_i : std_logic_vector( 3 downto 0);
          signal dob_i  : std_logic_vector(31 downto 0);
          signal dobp_i : std_logic_vector( 3 downto 0);
        begin
    
          Pad_RAMB36_Data : process (wea_i, web_i, data_ina_ii, data_inb_ii, data_inpa_ii, data_inpb_ii) is
          begin  -- process Pad_RAMB36_Data
            wea_ii          <= (others => '0');
            web_ii          <= (others => '0');
            dia_i           <= (others => '0');
            dib_i           <= (others => '0');
            diap_i          <= (others => '0');
            dibp_i          <= (others => '0');
            
            wea_ii(a_we_data_width - 1 downto 0)  <= wea_i(max_of((I+1)*a_raw_data_width/8 - 1, (I+0)*a_raw_data_width/8) downto 
                                                                  (I+0)*a_raw_data_width/8);
            web_ii(b_we_data_width - 1 downto 0)  <= web_i(max_of((I+1)*b_raw_data_width/8 - 1, (I+0)*b_raw_data_width/8) downto 
                                                                  (I+0)*b_raw_data_width/8);
            dia_i(a_raw_data_width - 1 downto 0)  <= data_ina_ii((I+1)*a_raw_data_width - 1 downto 
                                                                 (I+0)*a_raw_data_width);
            dib_i(b_raw_data_width - 1 downto 0)  <= data_inb_ii((I+1)*b_raw_data_width - 1 downto 
                                                                 (I+0)*b_raw_data_width);
            if ( using_parity ) then
              diap_i(a_we_data_width - 1 downto 0)  <= data_inpa_ii(max_of((I+1)*a_raw_data_width/8 - 1, (I+0)*a_raw_data_width/8) downto 
                                                                           (I+0)*a_raw_data_width/8);
              dibp_i(b_we_data_width - 1 downto 0)  <= data_inpb_ii(max_of((I+1)*b_raw_data_width/8 - 1, (I+0)*b_raw_data_width/8) downto 
                                                                           (I+0)*b_raw_data_width/8);
            end if;
          end process Pad_RAMB36_Data;
    
          data_outa_ii((I+1)*a_raw_data_width - 1 downto (I+0)*a_raw_data_width) <= 
                            doa_i(a_raw_data_width - 1 downto 0);
    
          data_outb_ii((I+1)*b_raw_data_width - 1 downto (I+0)*b_raw_data_width) <= 
                            dob_i(b_raw_data_width - 1 downto 0);
          
          Parity_Bus: if ( using_parity ) generate
          begin
            data_outpa_ii(max_of((I+1)*a_raw_data_width/8 - 1, (I+0)*a_raw_data_width/8) downto 
                                 (I+0)*a_raw_data_width/8) <= doap_i(max_of(a_raw_data_width/8 - 1, 0) downto 0);
      
            data_outpb_ii(max_of((I+1)*b_raw_data_width/8 - 1, (I+0)*b_raw_data_width/8) downto 
                                 (I+0)*b_raw_data_width/8) <= dobp_i(max_of(b_raw_data_width/8 - 1, 0) downto 0);
          end generate Parity_Bus;

          web_iii <= "0000"    & web_ii             when  b_data_width > 18 else
                     "000000"  & web_ii(1 downto 0) when  b_data_width > 9  else
                     "0000000" & web_ii(0);

          RAMB36_I1: RAMB36E1
            generic map(
               DOA_REG                    => 0,               -- [integer]
               DOB_REG                    => 0,               -- [integer]
               RAM_EXTENSION_A            => "NONE",          -- [string]
               RAM_EXTENSION_B            => "NONE",          -- [string]
               RAM_MODE                   => "TDP",           -- [string]
               READ_WIDTH_A               => a_data_width,    -- [integer]
               READ_WIDTH_B               => b_data_width,    -- [integer]
               SIM_COLLISION_CHECK        => sim_check_mode,  -- [string]
               SIM_DEVICE                 => "7SERIES",       -- [string]
               WRITE_MODE_A               => write_mode,      -- [string]
               WRITE_MODE_B               => write_mode,      -- [string]
               WRITE_WIDTH_A              => a_data_width,    -- [integer]
               WRITE_WIDTH_B              => b_data_width     -- [integer]
            )
            port map(
               CASCADEOUTA                => open,            -- [out std_ulogic]
               CASCADEOUTB                => open,            -- [out std_ulogic]
               DBITERR                    => open,            -- [out std_ulogic]
               DOADO                      => doa_i,           -- [out std_logic_vector(31 downto 0)]
               DOBDO                      => dob_i,           -- [out std_logic_vector(31 downto 0)]
               DOPADOP                    => doap_i,          -- [out std_logic_vector(3 downto 0)]
               DOPBDOP                    => dobp_i,          -- [out std_logic_vector(3 downto 0)]
               ECCPARITY                  => open,            -- [out std_logic_vector(7 downto 0)]
               RDADDRECC                  => open,            -- [out std_logic_vector(8 downto 0)]
               SBITERR                    => open,            -- [out std_ulogic]
               ADDRARDADDR                => addra_ii,        -- [in std_logic_vector(15 downto 0)]
               ADDRBWRADDR                => addrb_ii,        -- [in std_logic_vector(15 downto 0)]
               CASCADEINA                 => '0',             -- [in std_ulogic]
               CASCADEINB                 => '0',             -- [in std_ulogic]
               CLKARDCLK                  => CLKA,            -- [in std_ulogic]
               CLKBWRCLK                  => CLKB,            -- [in std_ulogic]
               DIADI                      => dia_i,           -- [in std_logic_vector(31 downto 0)]
               DIBDI                      => dib_i,           -- [in std_logic_vector(31 downto 0)]
               DIPADIP                    => diap_i,          -- [in std_logic_vector(3 downto 0)]
               DIPBDIP                    => dibp_i,          -- [in std_logic_vector(3 downto 0)]
               ENARDEN                    => ENA,             -- [in std_ulogic]
               ENBWREN                    => ENB,             -- [in std_ulogic]
               INJECTDBITERR              => '0',             -- [in std_ulogic]
               INJECTSBITERR              => '0',             -- [in std_ulogic]
               REGCEAREGCE                => '1',             -- [in std_ulogic]
               REGCEB                     => '1',             -- [in std_ulogic]
               RSTRAMARSTRAM              => '0',             -- [in std_ulogic]
               RSTRAMB                    => '0',             -- [in std_ulogic]
               RSTREGARSTREG              => '0',             -- [in std_ulogic]
               RSTREGB                    => '0',             -- [in std_ulogic]
               WEA                        => wea_ii,          -- [in std_logic_vector(3 downto 0)]
               WEBWE                      => web_iii          -- [in std_logic_vector(7 downto 0)]
            );
        end generate The_BRAMs;
      end generate Using_B36_Sx;
      
      
      -----------------------------------------------------------------------------
      -- BlockRAM 72kbit
      -----------------------------------------------------------------------------
      
      Using_B72_S1 : if (What_BRAM.What_Kind = B72_S1) generate
        signal addra_ii : std_logic_vector(15 downto 0);
        signal addrb_ii : std_logic_vector(15 downto 0);
      begin
        Pad_RAMB36_Addresses : process (addra_i, addrb_i) is
          begin  -- process Pad_RAMB36_Addresses
            -- Address bit 15 is only used when BRAMs are cascaded
            addra_ii                              <= (others => '1');
            addra_ii(15-native_max_addr_size_a+C_ADDR_A_WIDTH downto 16-native_max_addr_size_a) <= addra_i(C_ADDR_A_WIDTH - 1 downto 0);
            addrb_ii                              <= (others => '1');
            addrb_ii(15-native_max_addr_size_b+C_ADDR_B_WIDTH downto 16-native_max_addr_size_b) <= addrb_i(C_ADDR_B_WIDTH - 1 downto 0);
        end process Pad_RAMB36_Addresses;
    
        The_BRAMs : for I in 0 to nr_of_brams-1 generate
          signal wea_ii : std_logic_vector( 3 downto 0);
          signal dia_i  : std_logic_vector(31 downto 0);
          signal diap_i : std_logic_vector( 3 downto 0);
          signal doa_i  : std_logic_vector(31 downto 0);
          signal doap_i : std_logic_vector( 3 downto 0);
          
          signal web_ii : std_logic;
          signal web_iii: std_logic_vector( 7 downto 0);
          signal dib_i  : std_logic_vector(31 downto 0);
          signal dibp_i : std_logic_vector( 3 downto 0);
          signal dob_i  : std_logic_vector(31 downto 0);
          signal dobp_i : std_logic_vector( 3 downto 0);
          
          signal cascade_a    : std_logic;
          signal cascade_b    : std_logic;
          
        begin
    
          wea_ii          <= (others => wea_i(I/8));
          dia_i           <= "0000000000000000000000000000000" & data_ina_ii(I);
          diap_i          <= "0000";
          data_outa_ii(I) <= doa_i(0);
    
          web_ii          <= web_i(I/8);
          dib_i           <= "0000000000000000000000000000000" & data_inb_ii(I);
          dibp_i          <= "0000";
          data_outb_ii(I) <= dob_i(0);
    
          web_iii         <= "0000000" & web_ii;
          
          RAMB36_I1: RAMB36E1
            generic map(
               DOA_REG                    => 0,               -- [integer]
               DOB_REG                    => 0,               -- [integer]
               RAM_EXTENSION_A            => "UPPER",         -- [string]
               RAM_EXTENSION_B            => "UPPER",         -- [string]
               RAM_MODE                   => "TDP",           -- [string]
               READ_WIDTH_A               => 1,               -- [integer]
               READ_WIDTH_B               => 1,               -- [integer]
               SIM_COLLISION_CHECK        => sim_check_mode,  -- [string]
               SIM_DEVICE                 => "7SERIES",       -- [string]
               WRITE_MODE_A               => write_mode,      -- [string]
               WRITE_MODE_B               => write_mode,      -- [string]
               WRITE_WIDTH_A              => 1,               -- [integer]
               WRITE_WIDTH_B              => 1                -- [integer]
            )
            port map(
               CASCADEOUTA                => open,            -- [out std_ulogic]
               CASCADEOUTB                => open,            -- [out std_ulogic]
               DBITERR                    => open,            -- [out std_ulogic]
               DOADO                      => doa_i,           -- [out std_logic_vector(31 downto 0)]
               DOBDO                      => dob_i,           -- [out std_logic_vector(31 downto 0)]
               DOPADOP                    => doap_i,          -- [out std_logic_vector(3 downto 0)]
               DOPBDOP                    => dobp_i,          -- [out std_logic_vector(3 downto 0)]
               ECCPARITY                  => open,            -- [out std_logic_vector(7 downto 0)]
               RDADDRECC                  => open,            -- [out std_logic_vector(8 downto 0)]
               SBITERR                    => open,            -- [out std_ulogic]
               ADDRARDADDR                => addra_ii,        -- [in std_logic_vector(15 downto 0)]
               ADDRBWRADDR                => addrb_ii,        -- [in std_logic_vector(15 downto 0)]
               CASCADEINA                 => cascade_a,       -- [in std_ulogic]
               CASCADEINB                 => cascade_b,       -- [in std_ulogic]
               CLKARDCLK                  => CLKA,            -- [in std_ulogic]
               CLKBWRCLK                  => CLKB,            -- [in std_ulogic]
               DIADI                      => dia_i,           -- [in std_logic_vector(31 downto 0)]
               DIBDI                      => dib_i,           -- [in std_logic_vector(31 downto 0)]
               DIPADIP                    => diap_i,          -- [in std_logic_vector(3 downto 0)]
               DIPBDIP                    => dibp_i,          -- [in std_logic_vector(3 downto 0)]
               ENARDEN                    => ENA,             -- [in std_ulogic]
               ENBWREN                    => ENB,             -- [in std_ulogic]
               INJECTDBITERR              => '0',             -- [in std_ulogic]
               INJECTSBITERR              => '0',             -- [in std_ulogic]
               REGCEAREGCE                => '1',             -- [in std_ulogic]
               REGCEB                     => '1',             -- [in std_ulogic]
               RSTRAMARSTRAM              => '0',             -- [in std_ulogic]
               RSTRAMB                    => '0',             -- [in std_ulogic]
               RSTREGARSTREG              => '0',             -- [in std_ulogic]
               RSTREGB                    => '0',             -- [in std_ulogic]
               WEA                        => wea_ii,          -- [in std_logic_vector(3 downto 0)]
               WEBWE                      => web_iii          -- [in std_logic_vector(7 downto 0)]
            );
              
          RAMB36_I2: RAMB36E1
            generic map(
               DOA_REG                    => 0,               -- [integer]
               DOB_REG                    => 0,               -- [integer]
               RAM_EXTENSION_A            => "LOWER",         -- [string]
               RAM_EXTENSION_B            => "LOWER",         -- [string]
               RAM_MODE                   => "TDP",           -- [string]
               READ_WIDTH_A               => 1,               -- [integer]
               READ_WIDTH_B               => 1,               -- [integer]
               SIM_COLLISION_CHECK        => sim_check_mode,  -- [string]
               SIM_DEVICE                 => "7SERIES",       -- [string]
               WRITE_MODE_A               => write_mode,      -- [string]
               WRITE_MODE_B               => write_mode,      -- [string]
               WRITE_WIDTH_A              => 1,               -- [integer]
               WRITE_WIDTH_B              => 1                -- [integer]
            )
            port map(
               CASCADEOUTA                => cascade_a,       -- [out std_ulogic]
               CASCADEOUTB                => cascade_b,       -- [out std_ulogic]
               DBITERR                    => open,            -- [out std_ulogic]
               DOADO                      => open,            -- [out std_logic_vector(31 downto 0)]
               DOBDO                      => open,            -- [out std_logic_vector(31 downto 0)]
               DOPADOP                    => open,            -- [out std_logic_vector(3 downto 0)]
               DOPBDOP                    => open,            -- [out std_logic_vector(3 downto 0)]
               ECCPARITY                  => open,            -- [out std_logic_vector(7 downto 0)]
               RDADDRECC                  => open,            -- [out std_logic_vector(8 downto 0)]
               SBITERR                    => open,            -- [out std_ulogic]
               ADDRARDADDR                => addra_ii,        -- [in std_logic_vector(15 downto 0)]
               ADDRBWRADDR                => addrb_ii,        -- [in std_logic_vector(15 downto 0)]
               CASCADEINA                 => '0',             -- [in std_ulogic]
               CASCADEINB                 => '0',             -- [in std_ulogic]
               CLKARDCLK                  => CLKA,            -- [in std_ulogic]
               CLKBWRCLK                  => CLKB,            -- [in std_ulogic]
               DIADI                      => dia_i,           -- [in std_logic_vector(31 downto 0)]
               DIBDI                      => dib_i,           -- [in std_logic_vector(31 downto 0)]
               DIPADIP                    => diap_i,          -- [in std_logic_vector(3 downto 0)]
               DIPBDIP                    => dibp_i,          -- [in std_logic_vector(3 downto 0)]
               ENARDEN                    => ENA,             -- [in std_ulogic]
               ENBWREN                    => ENB,             -- [in std_ulogic]
               INJECTDBITERR              => '0',             -- [in std_ulogic]
               INJECTSBITERR              => '0',             -- [in std_ulogic]
               REGCEAREGCE                => '1',             -- [in std_ulogic]
               REGCEB                     => '1',             -- [in std_ulogic]
               RSTRAMARSTRAM              => '0',             -- [in std_ulogic]
               RSTRAMB                    => '0',             -- [in std_ulogic]
               RSTREGARSTREG              => '0',             -- [in std_ulogic]
               RSTREGB                    => '0',             -- [in std_ulogic]
               WEA                        => wea_ii,          -- [in std_logic_vector(3 downto 0)]
               WEBWE                      => web_iii          -- [in std_logic_vector(7 downto 0)]
            );
              
        end generate The_BRAMs;
      end generate Using_B72_S1;
    end generate Native;
  end generate Using_BRAM;
  
  
  -----------------------------------------------------------------------------
  -- Distributed LUTRAM
  -----------------------------------------------------------------------------
  
  Using_DistRAM : if (What_BRAM.What_Kind = DISTRAM) generate
    constant native_max_addr_size : integer := 7;
  begin
    Recursive : if (What_BRAM.Addr_size > native_max_addr_size) generate
      constant num_ram_modules : integer:= 2 ** ( What_BRAM.Addr_size - native_max_addr_size );
      type ram_output is array (0 to num_ram_modules - 1) of std_logic_vector(just_data_bits_size-1 downto 0);
      
      signal addra_cmb  : std_logic_vector(What_BRAM.Addr_size - native_max_addr_size - 1 downto 0);
      signal addrb_cmb  : std_logic_vector(What_BRAM.Addr_size - native_max_addr_size - 1 downto 0);
      signal addra_q    : std_logic_vector(What_BRAM.Addr_size - native_max_addr_size - 1 downto 0);
      signal addrb_q    : std_logic_vector(What_BRAM.Addr_size - native_max_addr_size - 1 downto 0);
      signal data_a     : ram_output;
      signal data_b     : ram_output;
    begin
      -- Extract module address.
      addra_cmb <= addra_i(addra_i'left downto addra_i'right + native_max_addr_size);
      addrb_cmb <= addrb_i(addrb_i'left downto addrb_i'right + native_max_addr_size);

      -- Instantiate all modules needed for the memory.
      The_RAM_INSTs : for J in 0 to num_ram_modules-1 generate
        signal wea_masked : std_logic_vector(C_WE_A_WIDTH-1 downto 0);
        signal web_masked : std_logic_vector(C_WE_B_WIDTH-1 downto 0);
      begin

        -- Generate local write enable
        wea_masked <= WEA(C_WE_A_WIDTH-1 downto 0) when to_integer(unsigned(addra_cmb)) = J else (others=>'0');
        web_masked <= WEB(C_WE_B_WIDTH-1 downto 0) when to_integer(unsigned(addrb_cmb)) = J else (others=>'0');
 
        RAM_Inst: sc_ram_module
          generic map (
            C_TARGET          => C_TARGET,
            C_RECURSIVE_INST  => true,
            C_DATA_A_WIDTH    => just_data_bits_size,
            C_WE_A_WIDTH      => C_WE_A_WIDTH,
            C_ADDR_A_WIDTH    => native_max_addr_size,
            C_DATA_B_WIDTH    => just_data_bits_size,
            C_WE_B_WIDTH      => C_WE_B_WIDTH,
            C_ADDR_B_WIDTH    => native_max_addr_size,
            C_FORCE_BRAM      => false,
            C_FORCE_LUTRAM    => true)
          port map(
            -- PORT A
            CLKA      => CLKA,
            WEA       => wea_masked,
            ENA       => ENA,
            ADDRA     => addra_i(addra_i'right + native_max_addr_size - 1 downto addra_i'right),
            DATA_INA  => data_ina_ii,
            DATA_OUTA => data_a(J),
            -- PORT B
            CLKB      => CLKB,
            WEB       => web_masked,
            ENB       => ENB,
            ADDRB     => addrb_i(addrb_i'right + native_max_addr_size - 1 downto addrb_i'right),
            DATA_INB  => data_inb_ii,
            DATA_OUTB => data_b(J)
            );
      end generate The_RAM_INSTs;

      -- Clock address for multiplexing the delayed memory data.
      PortA : process(CLKA)
      begin
        if CLKA'event and CLKA = '1' then
          if ENA = '1' then
            addra_q <= addra_cmb;
          end if;
        end if;
      end process PortA;

      PortB : process(CLKB)
      begin
        if CLKB'event and CLKB = '1' then
          if ENB = '1' then
            addrb_q <= addrb_cmb;
          end if;
        end if;
      end process PortB;

      -- Multiplex data from memory.
      data_outa_ii  <= data_a(to_integer(unsigned(addra_q)));
      data_outb_ii  <= data_b(to_integer(unsigned(addrb_q)));

    end generate Recursive;

    Native : if (What_BRAM.Addr_size <= native_max_addr_size) generate
      constant native_data_size : integer := just_data_bits_size / C_WE_B_WIDTH;
    begin
      The_DistRAMs : for I in 0 to C_WE_B_WIDTH-1 generate
      begin

        Block_DistRAM : block
          type RAM_Type is
            array (0 to 2**C_ADDR_B_WIDTH - 1) of std_logic_vector(native_data_size - 1 downto 0);

          signal RAM : RAM_Type := (others => (others=>'0'));

          attribute ram_style        : string;
          attribute ram_style of RAM : signal is "distributed";
        begin

          PortA : process(CLKA)
          begin
            if CLKA'event and CLKA = '1' then
              -- Assume that write port A is not used
              if ENA = '1' then
                data_outa_ii((I+1)*native_data_size-1 downto I*native_data_size) <= RAM(to_integer(unsigned(addra_i)));
              end if;
            end if;
          end process PortA;

          PortB : process(CLKB)
          begin
            if CLKB'event and CLKB = '1' then
              if ENB = '1' and WEB(I) = '1' then
                RAM(to_integer(unsigned(addrb_i))) <= data_inb_ii((I+1)*native_data_size-1 downto I*native_data_size);
                data_outb_ii((I+1)*native_data_size-1 downto I*native_data_size) <= RAM(to_integer(unsigned(addrb_i)));
              elsif ENB = '1' then
                data_outb_ii((I+1)*native_data_size-1 downto I*native_data_size) <= RAM(to_integer(unsigned(addrb_i)));
              end if;
            end if;
          end process PortB;

        end block Block_DistRAM;
      end generate The_DistRAMS;
    end generate Native;
  end generate Using_DistRAM;
  
  
end architecture IMP;
