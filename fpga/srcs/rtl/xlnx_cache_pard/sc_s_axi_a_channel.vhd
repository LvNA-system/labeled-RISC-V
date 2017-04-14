-------------------------------------------------------------------------------
-- sc_s_axi_a_channel.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_a_channel.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_a_channel.vhd
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


entity sc_s_axi_a_channel is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    C_USE_STATISTICS          : boolean                       := false;
    C_STAT_BITS               : natural range  1 to   64      := 32;
    C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
    C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
    C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
    C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
    
    -- AXI4 Interface Specific.
    C_S_AXI_BASEADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
    C_S_AXI_HIGHADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
    C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 64;
    C_S_AXI_ADDR_WIDTH        : natural                       := 32;
    C_S_AXI_ID_WIDTH          : natural                       :=  4;
    C_S_AXI_FORCE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_ALLOCATE : natural range  0 to    1      :=  0;
    C_S_AXI_FORCE_BUFFER      : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_BUFFER   : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_EXCLUSIVE: natural range  0 to    1      :=  1;
    
    -- Configuration.
    C_IS_READ                 : natural range  0 to    1      :=  0;
    C_LEN_WIDTH               : natural range  0 to    8      :=  2;
    C_REST_WIDTH              : natural range  0 to    7      :=  2;
    
    -- Data type and settings specific.
    C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
    C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
    C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
    C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;

    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- System Cache Specific.
    C_ID_WIDTH                : natural range  1 to   32      :=  1;
    C_CACHE_LINE_LENGTH       : natural range  4 to  128      := 16;
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
    S_AXI_AID                 : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AADDR               : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ALEN                : in  std_logic_vector(7 downto 0);
    S_AXI_ASIZE               : in  std_logic_vector(2 downto 0);
    S_AXI_ABURST              : in  std_logic_vector(1 downto 0);
    S_AXI_ALOCK               : in  std_logic;
    S_AXI_ACACHE              : in  std_logic_vector(3 downto 0);
    S_AXI_APROT               : in  std_logic_vector(2 downto 0);
    S_AXI_AQOS                : in  std_logic_vector(3 downto 0);
    S_AXI_AVALID              : in  std_logic;
    S_AXI_AREADY              : out std_logic;
    S_AXI_AUSER               : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write data).
    
    wr_valid                  : out std_logic;
    wr_last                   : out std_logic;
    wr_failed                 : out std_logic;
    wr_offset                 : out std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
    wr_stp                    : out std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
    wr_use                    : out std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
    wr_len                    : out AXI_LENGTH_TYPE;
    wr_ready                  : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Write Response Information Interface Signals.
    
    write_req_valid           : out std_logic;
    write_req_ID              : out std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
    write_req_last            : out std_logic;
    write_req_failed          : out std_logic;
    write_req_ready           : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Read Information Interface Signals.
    
    read_req_valid            : out std_logic;
    read_req_ID               : out std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
    read_req_last             : out std_logic;
    read_req_failed           : out std_logic;
    read_req_single           : out std_logic;
    read_req_rest             : out std_logic_vector(C_REST_WIDTH - 1 downto 0);
    read_req_offset           : out std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_stp              : out std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_use              : out std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_len              : out std_logic_vector(C_LEN_WIDTH - 1  downto 0);
    read_req_ready            : in  std_logic;
    
    
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
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    stat_s_axi_gen_segments   : out STAT_POINT_TYPE; -- Per transaction
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_a_channel;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_a_channel is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Address channel decoding for both read and write.
  -- Any transaction that doesn't fit the capabilities of the cache core is
  -- split in to pieces. Reasons for this could be that the transaction span
  -- multiple cache lines or are o wrapping in certain ways.
  -- 
  
    
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
  
  constant C_BYTE_LENGTH              : natural := 8 + Log2(C_S_AXI_DATA_WIDTH/8);
  constant C_ADDR_LENGTH_HI           : natural := C_BYTE_LENGTH - 1;
  constant C_ADDR_LENGTH_LO           : natural := C_ADDR_OFFSET_LO;
  
  subtype C_ADDR_LENGTH_POS           is natural range C_ADDR_LENGTH_HI     downto C_ADDR_LENGTH_LO;
  
  subtype C_ADDR_PAGE_NUM_POS         is natural range C_MAX_ADDR_WIDTH - 1 downto C_ADDR_PAGE_BITS;
  subtype C_ADDR_PAGE_POS             is natural range C_ADDR_PAGE_HI       downto C_ADDR_PAGE_LO;
  
  
  -- Subtypes for address parts.
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  subtype ADDR_LENGTH_TYPE            is std_logic_vector(C_ADDR_LENGTH_POS);
  
  subtype ADDR_PAGE_NUM_TYPE          is std_logic_vector(C_ADDR_PAGE_NUM_POS);
  subtype ADDR_PAGE_TYPE              is std_logic_vector(C_ADDR_PAGE_POS);
  
  constant C_SIZE_MUX_BITS            : natural := Log2(Log2(C_CACHE_DATA_WIDTH/8) + 1);
  subtype C_SIZE_MUX_POS              is natural range C_SIZE_MUX_BITS - 1 downto 0;
  
  constant C_MAX_SIZE_MUX_BITS        : natural := 3;
  subtype C_MAX_SIZE_MUX_POS          is natural range 2 ** C_MAX_SIZE_MUX_BITS - 1 downto 0;
  type SIZE_MUX_AXI_LEN_TYPE          is array(C_MAX_SIZE_MUX_POS) of AXI_LENGTH_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  subtype C_BYTE_MASK_POS             is natural range C_BYTE_LENGTH - 1 + 7 downto 7;
  subtype C_HALF_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 6 downto 6;
  subtype C_WORD_MASK_POS             is natural range C_BYTE_LENGTH - 1 + 5 downto 5;
  subtype C_DOUBLE_WORD_MASK_POS      is natural range C_BYTE_LENGTH - 1 + 4 downto 4;
  subtype C_QUAD_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 3 downto 3;
  subtype C_OCTA_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 2 downto 2;
  subtype C_HEXADECA_WORD_MASK_POS    is natural range C_BYTE_LENGTH - 1 + 1 downto 1;
  subtype C_TRIACONTADI_MASK_POS      is natural range C_BYTE_LENGTH - 1 + 0 downto 0;
  
  constant C_BYTE_RATIO               : natural := C_CACHE_DATA_WIDTH / C_BYTE_WIDTH;
  constant C_HALF_WORD_RATIO          : natural := C_CACHE_DATA_WIDTH / C_HALF_WORD_WIDTH;
  constant C_WORD_RATIO               : natural := C_CACHE_DATA_WIDTH / C_WORD_WIDTH;
  constant C_DOUBLE_WORD_RATIO        : natural := C_CACHE_DATA_WIDTH / C_DOUBLE_WORD_WIDTH;
  constant C_QUAD_WORD_RATIO          : natural := C_CACHE_DATA_WIDTH / C_QUAD_WORD_WIDTH;
  constant C_OCTA_WORD_RATIO          : natural := C_CACHE_DATA_WIDTH / C_OCTA_WORD_WIDTH;
  constant C_HEXADECA_WORD_RATIO      : natural := C_CACHE_DATA_WIDTH / C_HEXADECA_WORD_WIDTH;
  constant C_TRIACONTADI_WORD_RATIO   : natural := C_CACHE_DATA_WIDTH / C_TRIACONTADI_WORD_WIDTH;
  
  constant C_BYTE_RATIO_BITS              : natural := Log2(C_BYTE_RATIO);
  constant C_HALF_WORD_RATIO_BITS         : natural := Log2(C_HALF_WORD_RATIO);
  constant C_WORD_RATIO_BITS              : natural := Log2(C_WORD_RATIO);
  constant C_DOUBLE_WORD_RATIO_BITS       : natural := Log2(C_DOUBLE_WORD_RATIO);
  constant C_QUAD_WORD_RATIO_BITS         : natural := Log2(C_QUAD_WORD_RATIO);
  constant C_OCTA_WORD_RATIO_BITS         : natural := Log2(C_OCTA_WORD_RATIO);
  constant C_HEXADECA_WORD_RATIO_BITS     : natural := Log2(C_HEXADECA_WORD_RATIO);
  constant C_TRIACONTADI_WORD_RATIO_BITS  : natural := Log2(C_TRIACONTADI_WORD_RATIO);
  
  subtype C_DEFAULT_RATIO_POS         is natural range C_AXI_LENGTH_WIDTH - 1             downto 
                                                       0;
  subtype C_BYTE_RATIO_POS            is natural range C_BYTE_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1             downto 
                                                       C_BYTE_RATIO_BITS;
  subtype C_HALF_WORD_RATIO_POS       is natural range C_HALF_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1        downto 
                                                       C_HALF_WORD_RATIO_BITS;
  subtype C_WORD_RATIO_POS            is natural range C_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1             downto 
                                                       C_WORD_RATIO_BITS;
  subtype C_DOUBLE_WORD_RATIO_POS     is natural range C_DOUBLE_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1      downto 
                                                       C_DOUBLE_WORD_RATIO_BITS;
  subtype C_QUAD_WORD_RATIO_POS       is natural range C_QUAD_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1        downto 
                                                       C_QUAD_WORD_RATIO_BITS;
  subtype C_OCTA_WORD_RATIO_POS       is natural range C_OCTA_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1        downto 
                                                       C_OCTA_WORD_RATIO_BITS;
  subtype C_HEXADECA_WORD_RATIO_POS   is natural range C_HEXADECA_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1    downto 
                                                       C_HEXADECA_WORD_RATIO_BITS;
  subtype C_TRIACONTADI_RATIO_POS     is natural range C_TRIACONTADI_WORD_RATIO_BITS + C_AXI_LENGTH_WIDTH - 1 downto 
                                                       C_TRIACONTADI_WORD_RATIO_BITS;
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Local rest.
  subtype C_REST_POS                  is natural range C_REST_WIDTH - 1 downto 0;
  subtype REST_TYPE                   is std_logic_vector(C_REST_POS);
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_CACHELINE_MASK           : AXI_ADDR_TYPE := std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH * 4 - 1, 
                                                                                      C_MAX_ADDR_WIDTH));
  
  constant C_NATIVE_SIZE              : AXI_SIZE_TYPE := std_logic_vector(to_unsigned(Log2(C_CACHE_DATA_WIDTH/8), 
                                                                                      AXI_SIZE_TYPE'length));
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component carry_and is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_and;
  
  component carry_or is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_or;
  
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
  
  component carry_latch_and is
    generic (
      C_KEEP    : boolean:= false;
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
  end component carry_latch_and;
  
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
  
  component bit_reg_ce is
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
  end component bit_reg_ce;
  
  component bit_reg_ce_kill is
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
  end component bit_reg_ce_kill;
  
  component sc_s_axi_length_generation is
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
  end component sc_s_axi_length_generation;
  
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
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  signal S_AXI_AADDR_I            : AXI_ADDR_TYPE;
  
  -- ----------------------------------------
  -- Buffer Incomming Transaction Information (AW, AR)
  
  signal S_AXI_AID_q              : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
  signal S_AXI_AADDR_q            : AXI_ADDR_TYPE;
  signal S_AXI_ALEN_q             : AXI_LENGTH_TYPE;
  signal S_AXI_ASIZE_q            : AXI_SIZE_TYPE;
  signal S_AXI_ALOCK_q            : std_logic;
  signal S_AXI_ACACHE_q           : AXI_CACHE_TYPE;
  signal S_AXI_APROT_q            : AXI_PROT_TYPE;
  signal S_AXI_AVALID_cmb         : std_logic;
  signal S_AXI_AVALID_q           : std_logic;
  signal S_AXI_AREADY_I           : std_logic;
  signal S_AXI_AUSER_q            : PARD_DSID_TYPE;
  signal first_part_cmb           : std_logic;
  signal first_part               : std_logic;
  
  
  -- ----------------------------------------
  -- Pre-Decode Transaction 
  
  signal access_is_incr_cmb       : std_logic;
  signal access_is_wrap_cmb       : std_logic;
  signal access_byte_len_cmb      : AXI_ADDR_TYPE;
  signal access_size_mask_cmb     : AXI_ADDR_TYPE;
  signal access_stp_bits_cmb      : ADDR_BYTE_TYPE;
  signal access_rest_max_cmb      : REST_TYPE;
  signal aligned_addr_cmb         : AXI_ADDR_TYPE;
  signal full_line_beats_cmb      : ADDR_LENGTH_TYPE;
  signal masked_addr_cmb          : AXI_ADDR_TYPE;
  signal wrap_end_beats_cmb       : AXI_LENGTH_TYPE;
  signal wrap_end_beats_vec       : SIZE_MUX_AXI_LEN_TYPE;
  signal allowed_max_wrap_len_cmb : ADDR_LENGTH_TYPE;
  
  
  -- ----------------------------------------
  -- Decode Transaction Information
  
  signal access_is_incr           : std_logic;
  signal access_is_wrap           : std_logic;
  signal extended_length          : std_logic_vector(21 downto 0);
  signal access_byte_len          : AXI_ADDR_TYPE;
  signal allowed_max_wrap_len     : ADDR_LENGTH_TYPE;
  signal aligned_addr             : AXI_ADDR_TYPE;
  signal fit_lx_line              : std_logic;
  signal wrap_fit_lx_line         : std_logic;
  signal wrap_is_aligned          : std_logic;
  signal access_fit_sys_line      : std_logic;
  signal access_cross_line        : std_logic;
  signal exclusive_too_long       : std_logic;
  signal exclusive_too_long_i     : std_logic;
  signal exclusive_not_killed     : std_logic;
  signal wrap_must_split          : std_logic;
  signal access_must_split        : std_logic;
  signal full_line_beats          : ADDR_LENGTH_TYPE;
  signal wrap_end_beats           : AXI_LENGTH_TYPE;
  signal access_stp_bits          : ADDR_BYTE_TYPE;
  signal access_use_bits          : ADDR_BYTE_TYPE;
  signal access_rest_max          : REST_TYPE;
  signal transaction_start_beats  : AXI_LENGTH_TYPE;
  signal wrap_split_beats         : AXI_LENGTH_TYPE;
  signal adjusted_addr_vec        : SIZE_MUX_AXI_LEN_TYPE;
  signal adjusted_addr            : AXI_LENGTH_TYPE;
  signal wrap_split_mask_vec      : SIZE_MUX_AXI_LEN_TYPE;
  signal wrap_split_mask          : AXI_LENGTH_TYPE;
  
  
  -- ----------------------------------------
  -- Handle Internal Transactions
  
  signal port_access_addr         : AXI_ADDR_TYPE;
  signal sequential_addr_step     : AXI_ADDR_TYPE;
  signal sequential_addr_i        : AXI_ADDR_TYPE;
  signal sequential_addr          : AXI_ADDR_TYPE;
  signal port_access_len          : AXI_LENGTH_TYPE;
  signal extended_port_access_len : std_logic_vector(C_AXI_LENGTH_WIDTH + 7 - 1 downto 0);
  signal scaled_port_access_len   : AXI_LENGTH_TYPE;
  signal remaining_length         : AXI_LENGTH_TYPE;
  signal port_access_kind         : std_logic;
  signal req_last                 : std_logic;
  signal allocate_i               : std_logic;
  signal bufferable_i             : std_logic;
  signal bufferable_ii            : std_logic;
  signal new_transaction          : std_logic;
  signal transaction_done         : std_logic;
  signal port_ready               : std_logic;
  signal port_ready_with_valid    : std_logic;
  signal port_want_new_access     : std_logic;
  signal port_exist_and_allowed   : std_logic;
  signal transaction_and_piperun  : std_logic_vector(1 downto 0);
  signal port_access_q            : COMMON_PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Move Information to Next Stage
  
  signal req_last_q               : std_logic;
  signal exclusive_too_long_q     : std_logic;
  signal access_stp_bits_q        : ADDR_BYTE_TYPE;
  signal access_use_bits_new      : ADDR_BYTE_TYPE;
  signal access_use_bits_q        : ADDR_BYTE_TYPE;
  signal id_q                     : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal port_access_valid_i      : std_logic;
  signal port_access_valid        : std_logic;
  signal queue_done_cmb           : std_logic;
  signal queue_done               : std_logic;
  
  
  -- ----------------------------------------
  -- R-Channel Information
  
  signal read_req_valid_i         : std_logic;
  signal read_req_single_i        : std_logic;
  signal read_req_rest_i          : std_logic_vector(C_REST_WIDTH - 1 downto 0);
  signal read_req_rest_q          : std_logic_vector(C_REST_WIDTH - 1 downto 0);
    
    
  -- ----------------------------------------
  -- Create Write Transaction
  
  signal wr_valid_i               : std_logic;
  signal write_req_valid_i        : std_logic;
  signal wr_port_access_i         : WRITE_PORT_TYPE;
  signal wr_port_access_q         : WRITE_PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Create Read Transaction
  
  signal rd_port_access_i         : READ_PORT_TYPE;
  signal rd_port_access_q         : READ_PORT_TYPE;
  
  
begin  -- architecture IMP
  
  -- Create internal signal with maximum width.
  S_AXI_AADDR_I <= fit_vec(S_AXI_AADDR, C_MAX_ADDR_WIDTH);
  
  -----------------------------------------------------------------------------
  -- Buffer Incomming Transaction Information (AW or AR)
  -- 
  -- The incomming commands are buffered in order to have good timing for
  -- maipulation of the trans action.
  -----------------------------------------------------------------------------
  
  Addr_Request_Valid : process (S_AXI_AREADY_I, S_AXI_AVALID, arbiter_piperun, transaction_done, 
                                S_AXI_AVALID_q, new_transaction, first_part) is
  begin  -- process Addr_Request_Valid
    if( S_AXI_AREADY_I = '1' ) then
      S_AXI_AVALID_cmb  <= S_AXI_AVALID;
    elsif( ( arbiter_piperun and transaction_done ) = '1' ) then
      S_AXI_AVALID_cmb  <= '0';
    else
      S_AXI_AVALID_cmb  <= S_AXI_AVALID_q;
    end if;
    
    if( S_AXI_AREADY_I = '1' ) then
      first_part_cmb    <= S_AXI_AVALID;
    elsif( ( arbiter_piperun and new_transaction ) = '1' ) then
      first_part_cmb    <= '0';
    else
      first_part_cmb    <= first_part;
    end if;
  end process Addr_Request_Valid;
  
  Valid_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => "1",
      D         => S_AXI_AVALID_cmb,
      Q         => S_AXI_AVALID_q
    );
    
  First_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '1',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => "1",
      D         => first_part_cmb,
      Q         => first_part
    );
    
  Addr_Request : process (ACLK) is
  begin  -- process Addr_Request
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET = '1' ) then             -- synchronous reset (active high)
        S_AXI_AID_q     <= (others=>'0');
        S_AXI_AADDR_q   <= (others=>'0');
        S_AXI_ALEN_q    <= (others=>'0');
        S_AXI_ASIZE_q   <= (others=>'0');
        S_AXI_ALOCK_q   <= '0';
        S_AXI_ACACHE_q  <= (others=>'0');
        S_AXI_APROT_q   <= (others=>'0');
        S_AXI_AUSER_q   <= (others=>'0');
        
      else
        if( S_AXI_AREADY_I = '1' ) then
          S_AXI_AID_q     <= S_AXI_AID;
          S_AXI_AADDR_q   <= S_AXI_AADDR_I;
          S_AXI_ALEN_q    <= S_AXI_ALEN;
          S_AXI_ASIZE_q   <= S_AXI_ASIZE;
          S_AXI_ALOCK_q   <= S_AXI_ALOCK;
          S_AXI_ACACHE_q  <= S_AXI_ACACHE;
          S_AXI_APROT_q   <= S_AXI_APROT;
          S_AXI_AUSER_q   <= fit_vec(S_AXI_AUSER, C_DSID_WIDTH);
          
        end if;
      end if;
    end if;
  end process Addr_Request;
  
  -- Ready to get new word.
  S_AXI_AREADY_I  <= ( not S_AXI_AVALID_q );
  S_AXI_AREADY    <= S_AXI_AREADY_I and not ARESET;
        
        
  -----------------------------------------------------------------------------
  -- Pre-Decode Transaction 
  -- 
  -- Information that need some predecoding in order to get good timing.
  -----------------------------------------------------------------------------
  
  -- Decode transaction type.
  access_is_incr_cmb    <= not access_is_wrap_cmb;
  access_is_wrap_cmb    <= '1' when S_AXI_ABURST = C_AW_WRAP else '0';
  
  -- Extend the length vector (help signal).
  Ext_Len: process (S_AXI_ALEN) is
  begin  -- process Ext_Len
    extended_length               <= (others=>'0');
    extended_length(14 downto 7)  <= S_AXI_ALEN;
    extended_length( 6 downto 0)  <= "1111111";
  end process Ext_Len;
  
  -- Figure out the maximum allowed wrap length for the current size.
  Gen_Wrap_Len: process (S_AXI_ASIZE) is
  begin  -- process Gen_Wrap_Len
    if( ( S_AXI_ASIZE = C_NATIVE_SIZE ) and 
        ( C_S_AXI_DATA_WIDTH = C_CACHE_DATA_WIDTH ) and 
        ( C_S_AXI_DATA_WIDTH = C_M_AXI_DATA_WIDTH ) ) then
      allowed_max_wrap_len_cmb  <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH * 4 - 1, ADDR_LENGTH_TYPE'length));
    else
      allowed_max_wrap_len_cmb  <= std_logic_vector(to_unsigned(C_CACHE_DATA_WIDTH / 8 - 1,  ADDR_LENGTH_TYPE'length));
    end if;
  end process Gen_Wrap_Len;
  
  -- Translate in to normalized length in bytesbyte .
  Gen_Real_Len: process (S_AXI_ASIZE, extended_length) is
  begin  -- process Gen_Real_Len
    access_byte_len_cmb <= (others=>'0');
    case S_AXI_ASIZE is
      when C_BYTE_SIZE          =>
        access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
      when C_HALF_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 16 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_HALF_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when C_WORD_SIZE          =>
        if( C_S_AXI_DATA_WIDTH >= 32 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when C_DOUBLE_WORD_SIZE   =>
        if( C_S_AXI_DATA_WIDTH >= 64 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_DOUBLE_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when C_QUAD_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 128 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_QUAD_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when C_OCTA_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 256 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_OCTA_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when C_HEXADECA_WORD_SIZE =>
        if( C_S_AXI_DATA_WIDTH >= 512 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_HEXADECA_WORD_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
      when others               =>
        if( C_S_AXI_DATA_WIDTH >= 1024 ) then
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_TRIACONTADI_MASK_POS);
        else
          access_byte_len_cmb(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        end if;
    end case;
  end process Gen_Real_Len;
  
  -- Generate transaction size mask, stp and rest maximum.
  Gen_Size_Info: process (S_AXI_ASIZE) is
  begin  -- process Gen_Size_Info
    case S_AXI_ASIZE is
      when C_BYTE_SIZE          =>
        access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
        access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
        access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
        full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
      when C_HALF_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 16 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE - 1,        C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   2, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*2 - 1,        C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when C_WORD_SIZE          =>
        if( C_S_AXI_DATA_WIDTH >= 32 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   4, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*1 - 1,        C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when C_DOUBLE_WORD_SIZE   =>
        if( C_S_AXI_DATA_WIDTH >= 64 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE - 1,      C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE,          C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   8, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH/2 - 1,        C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when C_QUAD_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 128 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE - 1,        C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -  16, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH/4 - 1,        C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when C_OCTA_WORD_SIZE     =>
        if( C_S_AXI_DATA_WIDTH >= 256 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE - 1,        C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -  32, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH/8 - 1,        C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when C_HEXADECA_WORD_SIZE =>
        if( C_S_AXI_DATA_WIDTH >= 512 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE - 1,    C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE,        C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -  64, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH/16 - 1,       C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
      when others               =>
        if( C_S_AXI_DATA_WIDTH >= 1024 ) then
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE - 1, C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE,     C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH - 128, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH/32 - 1,       C_BYTE_LENGTH));
        else
          access_size_mask_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE - 1,             C_MAX_ADDR_WIDTH));
          access_stp_bits_cmb   <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          access_rest_max_cmb   <= std_logic_vector(to_unsigned(max_of(2**C_REST_WIDTH -   1, 0), C_REST_WIDTH));
          full_line_beats_cmb   <= std_logic_vector(to_unsigned(C_CACHE_LINE_LENGTH*4 - 1,        C_BYTE_LENGTH));
        end if;
    end case;
  end process Gen_Size_Info;
  
  -- Generate aligned start address.
  aligned_addr_cmb        <= S_AXI_AADDR_I and not access_size_mask_cmb;
  
  -- Mask out bits that are offset in the cache line.
  masked_addr_cmb         <= S_AXI_AADDR_I and C_CACHELINE_MASK;
  
  -- Beats fitting a Cache Line with current transaction size.
  Gen_Transaction_Len_Pre: process (masked_addr_cmb) is
  begin  -- process Gen_Transaction_Len_Pre
    wrap_end_beats_vec(0) <= masked_addr_cmb(7 downto 0);
    if( C_S_AXI_DATA_WIDTH >= 16 ) then
      wrap_end_beats_vec(1) <= masked_addr_cmb(8 downto 1);
    else
      wrap_end_beats_vec(1) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 32 ) then
      wrap_end_beats_vec(2) <= masked_addr_cmb(9 downto 2);
    else
      wrap_end_beats_vec(2) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 64 ) then
      wrap_end_beats_vec(3) <= masked_addr_cmb(10 downto 3);
    else
      wrap_end_beats_vec(3) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 128 ) then
      wrap_end_beats_vec(4) <= masked_addr_cmb(11 downto 4);
    else
      wrap_end_beats_vec(4) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 256 ) then
      wrap_end_beats_vec(5) <= masked_addr_cmb(12 downto 5);
    else
      wrap_end_beats_vec(5) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 512 ) then
      wrap_end_beats_vec(6) <= masked_addr_cmb(13 downto 6);
    else
      wrap_end_beats_vec(6) <= masked_addr_cmb(7 downto 0);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 1024 ) then
      wrap_end_beats_vec(7) <= masked_addr_cmb(14 downto 7);
    else
      wrap_end_beats_vec(7) <= masked_addr_cmb(7 downto 0);
    end if;
  end process Gen_Transaction_Len_Pre;
  wrap_end_beats_cmb  <= wrap_end_beats_vec(to_integer(unsigned(S_AXI_ASIZE(C_SIZE_MUX_POS))));
  
  Pre_Decode : process (ACLK) is
  begin  -- process Pre_Decode
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET = '1' ) then             -- synchronous reset (active high)
        access_is_incr        <= '1';
        access_is_wrap        <= '0';
        access_byte_len       <= (others=>'0');
        access_stp_bits       <= (others=>'0');
        access_rest_max       <= (others=>'0');
        aligned_addr          <= (others=>'0');
        full_line_beats       <= (others=>'0');
        wrap_end_beats        <= (others=>'0');
        allowed_max_wrap_len  <= (others=>'0');
        
      elsif( S_AXI_AREADY_I = '1' ) then
        access_is_incr        <= access_is_incr_cmb;
        access_is_wrap        <= access_is_wrap_cmb;
        access_byte_len       <= access_byte_len_cmb;
        access_stp_bits       <= access_stp_bits_cmb;
        access_rest_max       <= access_rest_max_cmb;
        aligned_addr          <= aligned_addr_cmb;
        full_line_beats       <= full_line_beats_cmb;
        wrap_end_beats        <= wrap_end_beats_cmb;
        allowed_max_wrap_len  <= allowed_max_wrap_len_cmb;
        
      end if;
    end if;
  end process Pre_Decode;
  
  
  -----------------------------------------------------------------------------
  -- Decode Transaction Information
  -- 
  -- The static information from the buffered command is decoded, this is then
  -- used to handle the transaction so that it can be forwarded through
  -- the internal interfaces to the affected parts.
  -- 
  -- Transactions can be forwarded either as one part or multiple depending
  -- on the transaction.
  -- 
  -- Much of the decoding has been moved to the dedicated length calculation
  -- module for timing purposes.
  -----------------------------------------------------------------------------
  
  -- Determine if Exclusive access fails because it passes cacheline boundaries.
--  exclusive_too_long  <= S_AXI_ALOCK_q and ( access_cross_line or not access_fit_sys_line );
  FE_Gen_Excl_And_Inst1: carry_and 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => access_cross_line,
      A         => S_AXI_ALOCK_q,
      Carry_OUT => exclusive_too_long
    );
    
  -- Determine if Exclusive access must be killed or not.
--  exclusive_not_killed <= S_AXI_ALOCK_q and not exclusive_too_long;
  FE_Gen_Excl_Latch_And_Inst1: carry_latch_and
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => true
    )
    port map(
      Carry_IN  => exclusive_too_long,
      A         => S_AXI_ALOCK_q,
      O         => exclusive_not_killed,
      Carry_OUT => exclusive_too_long_i
    );
  
  -- Beats fitting a Cache Line with current transaction size.
  Gen_Transaction_Len: process (S_AXI_AADDR_q, access_byte_len) is
  begin  -- process Gen_Transaction_Len
    adjusted_addr_vec(0)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(0)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(1)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(1)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(2)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(2)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(3)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(3)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(4)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(4)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(5)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(5)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(6)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(6)  <= access_byte_len(7 downto 0);
    adjusted_addr_vec(7)    <=   S_AXI_AADDR_q(7 downto 0);
    wrap_split_mask_vec(7)  <= access_byte_len(7 downto 0);
    if( C_S_AXI_DATA_WIDTH >= 16 ) then
      adjusted_addr_vec(1)    <=   S_AXI_AADDR_q( 8 downto 1);
      wrap_split_mask_vec(1)  <= access_byte_len( 8 downto 1);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 32 ) then
      adjusted_addr_vec(2)    <=   S_AXI_AADDR_q( 9 downto 2);
      wrap_split_mask_vec(2)  <= access_byte_len( 9 downto 2);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 64 ) then
      adjusted_addr_vec(3)    <=   S_AXI_AADDR_q(10 downto 3);
      wrap_split_mask_vec(3)  <= access_byte_len(10 downto 3);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 128 ) then
      adjusted_addr_vec(4)    <=   S_AXI_AADDR_q(11 downto 4);
      wrap_split_mask_vec(4)  <= access_byte_len(11 downto 4);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 256 ) then
      adjusted_addr_vec(5)    <=   S_AXI_AADDR_q(12 downto 5);
      wrap_split_mask_vec(5)  <= access_byte_len(12 downto 5);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 512 ) then
      adjusted_addr_vec(6)    <=   S_AXI_AADDR_q(13 downto 6);
      wrap_split_mask_vec(6)  <= access_byte_len(13 downto 6);
    end if;
    if( C_S_AXI_DATA_WIDTH >= 1024 ) then
      adjusted_addr_vec(7)    <=   S_AXI_AADDR_q(14 downto 7);
      wrap_split_mask_vec(7)  <= access_byte_len(14 downto 7);
    end if;
  end process Gen_Transaction_Len;
  adjusted_addr     <= adjusted_addr_vec(to_integer(unsigned(S_AXI_ASIZE_q(C_SIZE_MUX_POS))));
  wrap_split_mask   <= wrap_split_mask_vec(to_integer(unsigned(S_AXI_ASIZE_q(C_SIZE_MUX_POS))));
  wrap_split_beats  <= adjusted_addr and wrap_split_mask;
  
  -- Generate use.
  access_use_bits <= access_byte_len(C_ADDR_BYTE_POS);
    
  
  -----------------------------------------------------------------------------
  -- Handle Internal Transactions
  -- 
  -- Depending on the transaction properties it might need to be manipulated,
  -- split into multiple peices or otherwise changed.
  -- 
  -- Transactions that cross Cache Line boundaries has to be split into 
  -- multiple pieces.
  -- An exclisive transaction cannot be split because it could lead to 
  -- inconsistencies (some parts fail others succeds).
  -- 
  -- Actions depending on burst type:
  -- Fix  - Always flows through untouched (same address, so it can never 
  --        cross cache line boundaries). Fix can appear with length 1-256.
  -- Incr - Never changes type but must be split when crossing a cache line
  --        boundary. Incr can appear with length 1-256.
  -- Wrap - Wrap transactions that cover more than an Lx cacheline has to be 
  --        split into at least two pieces, depending on the length. Otherwise
  --        it can pass untouched. Wrap an appear with length 2-16.
  -----------------------------------------------------------------------------
  
  -- Select transaction address.
  Gen_Addr: process (first_part, S_AXI_AADDR_q, access_is_wrap, sequential_addr, access_byte_len) is
    variable port_access_addr_i       : AXI_ADDR_TYPE;
  begin  -- process Gen_Addr
    port_access_addr_i  := S_AXI_AADDR_q;
    
    if( first_part = '0' ) then
      if( access_is_wrap = '1' ) then
        -- Insert line bits that are covered by the calculated byte length
        for I in access_byte_len'range loop
          if( access_byte_len(I) = '1' ) then
            port_access_addr_i(I)  := sequential_addr(I);
          end if;
        end loop;
        
      else
        -- Incr will use the complete new address
        port_access_addr_i  := sequential_addr;
        
        -- New address will always be on a cacheline boundary.
        port_access_addr_i(C_ADDR_OFFSET_POS) := (others=>'0');
      end if;
    end if;
    
    -- Fix unaffected bits.
    port_access_addr                      <= (others=>'0');
    port_access_addr(C_ADDR_PAGE_NUM_POS) <= S_AXI_AADDR_q(C_ADDR_PAGE_NUM_POS);
    port_access_addr(C_ADDR_PAGE_POS)     <= port_access_addr_i(C_ADDR_PAGE_POS);
    
  end process Gen_Addr;
  
  -- Generate Address step.
  Gen_Addr_Step: process (new_transaction) is
  begin  -- process Gen_Addr_Step
    -- Step by 4 * C_CACHE_LINE_LENGTH when there is a new transaction.
    sequential_addr_step                                <= (others=>'0');
    sequential_addr_step(Log2(4 * C_CACHE_LINE_LENGTH)) <= new_transaction;
  end process Gen_Addr_Step;
  
  -- Keep track of sequential address.
  Address_Handler : process (ACLK) is
  begin  -- process Address_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        sequential_addr_i <= (others=>'0');
      elsif( arbiter_piperun = '1' ) then
        -- Calculate next cache line.
        sequential_addr_i <= std_logic_vector(unsigned(port_access_addr) + unsigned(sequential_addr_step));
        
        -- Lower bits are never used.
        sequential_addr_i(C_ADDR_OFFSET_POS) <= (others=>'0');
      end if;
    end if;
  end process Address_Handler;
  
  -- Fix unaffected bits.
  sequential_addr(C_ADDR_PAGE_NUM_POS)  <= S_AXI_AADDR_q(C_ADDR_PAGE_NUM_POS);
  sequential_addr(C_ADDR_PAGE_POS)      <= sequential_addr_i(C_ADDR_PAGE_POS);
  
  -- Help signal for scaling.
  extended_port_access_len  <= "0000000" & port_access_len;
  
  -- Scale port length and size to internal size.
  Scale_Transaction: process (port_access_q.Size, extended_port_access_len) is
  begin  -- process Scale_Transaction
    case port_access_q.Size is
      when C_BYTE_SIZE          =>
        scaled_port_access_len  <= extended_port_access_len(C_BYTE_RATIO_POS);
        
      when C_HALF_WORD_SIZE     =>
        if( C_CACHE_DATA_WIDTH >= 16 ) then
          scaled_port_access_len  <= extended_port_access_len(C_HALF_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when C_WORD_SIZE          =>
        if( C_CACHE_DATA_WIDTH >= 32 ) then
          scaled_port_access_len  <= extended_port_access_len(C_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when C_DOUBLE_WORD_SIZE   =>
        if( C_CACHE_DATA_WIDTH >= 64 ) then
          scaled_port_access_len  <= extended_port_access_len(C_DOUBLE_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when C_QUAD_WORD_SIZE     =>
        if( C_CACHE_DATA_WIDTH >= 128 ) then
          scaled_port_access_len  <= extended_port_access_len(C_QUAD_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when C_OCTA_WORD_SIZE     =>
        if( C_CACHE_DATA_WIDTH >= 256 ) then
          scaled_port_access_len  <= extended_port_access_len(C_OCTA_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when C_HEXADECA_WORD_SIZE =>
        if( C_CACHE_DATA_WIDTH >= 512 ) then
          scaled_port_access_len  <= extended_port_access_len(C_HEXADECA_WORD_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
      when others               =>
        if( C_CACHE_DATA_WIDTH >= 1024 ) then
          scaled_port_access_len  <= extended_port_access_len(C_TRIACONTADI_RATIO_POS);
        else
          scaled_port_access_len  <= extended_port_access_len(C_DEFAULT_RATIO_POS);
        end if;
        
    end case;
  end process Scale_Transaction;
  
  -- Select transaction address.
  port_access_kind  <= C_KIND_WRAP when wrap_fit_lx_line = '1' else 
                       C_KIND_INCR;
  
  -- Get current ready signal (specialized handling for read and write).
--  port_ready        <= ( wr_port_ready or exclusive_too_long ) when ( C_IS_READ = 0 ) else rd_port_ready;
  Use_Write_Ready: if( C_IS_READ = 0 ) generate
  begin
    FE_Gen_Ready_And_Inst1: carry_or
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => exclusive_too_long_i,
        A         => wr_port_ready,
        Carry_OUT => port_ready
      );
  end generate Use_Write_Ready;
  Use_Read_Ready: if( C_IS_READ /= 0 ) generate
  begin
    port_ready        <= rd_port_ready;
  end generate Use_Read_Ready;
  
  
  -----------------------------------------------------------------------------
  -- Optimized Length Counter
  -----------------------------------------------------------------------------
  
  Len_Gen_Inst: sc_s_axi_length_generation
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      
      -- AXI4 Interface Specific.
      C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
      
      -- System Cache Specific.
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      
      -- Data type and settings specific.
      C_ADDR_LENGTH_HI          => C_ADDR_LENGTH_HI,
      C_ADDR_LENGTH_LO          => C_ADDR_LENGTH_LO,
      C_ADDR_LINE_HI            => C_ADDR_LINE_HI,
      C_ADDR_LINE_LO            => C_ADDR_LINE_LO,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_HI,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_LO,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_HI,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_LO
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
      
      
      -- ---------------------------------------------------
      -- Input Signals.
      
      arbiter_piperun           => arbiter_piperun,
      new_transaction           => new_transaction,
      first_part                => first_part,
      access_is_incr            => access_is_incr,
      access_is_wrap            => access_is_wrap,
      access_byte_len           => access_byte_len,
      aligned_addr              => aligned_addr,
      allowed_max_wrap_len      => allowed_max_wrap_len,
      full_line_beats           => full_line_beats,
      wrap_end_beats            => wrap_end_beats,
      adjusted_addr             => adjusted_addr,
      wrap_split_mask           => wrap_split_mask,
      S_AXI_ALEN_q              => S_AXI_ALEN_q,
      S_AXI_AADDR_q             => S_AXI_AADDR_q(C_S_AXI_ADDR_WIDTH-1 downto 0),
      
      
      -- ---------------------------------------------------
      -- Output Signals.
      
      fit_lx_line               => fit_lx_line,
      wrap_is_aligned           => wrap_is_aligned,
      access_must_split         => access_must_split,
      transaction_start_beats   => transaction_start_beats,
      remaining_length          => remaining_length,
      wrap_fit_lx_line          => wrap_fit_lx_line,
      access_cross_line         => access_cross_line,
      wrap_must_split           => wrap_must_split,
      access_fit_sys_line       => access_fit_sys_line,
      req_last                  => req_last,
      transaction_done          => transaction_done,
      port_access_len           => port_access_len,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => open
    );
  
  
  -----------------------------------------------------------------------------
  -- Move Information to Next Stage
  --
  -- Most registers are instantiated by special registers for timing purposes.
  -----------------------------------------------------------------------------
  
  port_access_valid_i <= '1' when ( C_IS_READ = 1 ) else not exclusive_too_long_i;
  
  Port_Valid_Inst: bit_reg_ce_kill
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      KILL      => port_ready,
      CE        => transaction_and_piperun,
      D         => port_access_valid_i,
      Q         => port_access_valid
    );
    
  queue_done_cmb  <= not ( arbiter_piperun and new_transaction );
        
  Done_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '1',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => "1",
      D         => queue_done_cmb,
      Q         => queue_done
    );
    
  
  transaction_and_piperun <= new_transaction & arbiter_piperun;
  
  Addr_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (AXI_ADDR_TYPE'range=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => AXI_ADDR_TYPE'length
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => port_access_addr,
      Q         => port_access_q.Addr
    );
    
  Kind_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => port_access_kind,
      Q         => port_access_q.Kind
    );
    
  Size_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (AXI_SIZE_TYPE'range=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => AXI_SIZE_TYPE'length
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => S_AXI_ASIZE_q,
      Q         => port_access_q.Size
    );

  DSid_Inst: reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (PARD_DSID_TYPE'range=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => PARD_DSID_TYPE'length
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => S_AXI_AUSER_q,
      Q         => port_access_q.DSid
    );
    
  
  Use_Exclusive: if( C_S_AXI_PROHIBIT_EXCLUSIVE = 0 ) generate
  begin
    Exclusive_Inst: bit_reg_ce
      generic map(
        C_TARGET  => C_TARGET,
        C_IS_SET  => '0',
        C_CE_LOW  => (1 downto 0=>'0'),
        C_NUM_CE  => 2
      )
      port map(
        CLK       => ACLK,
        SR        => ARESET,
        CE        => transaction_and_piperun,
        D         => exclusive_not_killed,
        Q         => port_access_q.Exclusive
      );
  end generate Use_Exclusive;
  No_Exclusive: if( C_S_AXI_PROHIBIT_EXCLUSIVE /= 0 ) generate
  begin
    port_access_q.Exclusive <= '0';
  end generate No_Exclusive;
    
  allocate_i  <= '1' when C_S_AXI_FORCE_ALLOCATE    /= 0 else
                 '0' when C_S_AXI_PROHIBIT_ALLOCATE /= 0 else
                 S_AXI_ACACHE_q(sel(C_IS_READ = 0, C_AWCACHE_WRITE_ALLOCATE_POS, C_ARCACHE_READ_ALLOCATE_POS));
  
--  other_alloc <= '1' when C_S_AXI_FORCE_ALLOCATE    /= 0 else
--                 '0' when C_S_AXI_PROHIBIT_ALLOCATE /= 0 else
--                 S_AXI_ACACHE_q(sel(C_IS_READ = 0, C_AWCACHE_OTHER_ALLOCATE_POS, C_ARCACHE_OTHER_ALLOCATE_POS));
  
  Allocate_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => allocate_i,
      Q         => port_access_q.Allocate
    );
    
--  Other_Allocate_Inst: bit_reg_ce
--    generic map(
--      C_TARGET  => C_TARGET,
--      C_IS_SET  => '0',
--      C_CE_LOW  => (1 downto 0=>'0'),
--      C_NUM_CE  => 2
--    )
--    port map(
--      CLK       => ACLK,
--      SR        => ARESET,
--      CE        => transaction_and_piperun,
--      D         => other_alloc,
--      Q         => port_access_q.Allocate
--    );
    
  bufferable_ii <= bufferable_i;
  bufferable_i  <= '1' when C_S_AXI_FORCE_BUFFER    /= 0 else
                   '0' when C_S_AXI_PROHIBIT_BUFFER /= 0 else
                   S_AXI_ACACHE_q(sel(C_IS_READ = 0, C_AWCACHE_BUFFERABLE_POS, C_ARCACHE_BUFFERABLE_POS));
  
  Bufferable_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => bufferable_ii,
      Q         => port_access_q.Bufferable
    );
    
  Prot_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (AXI_PROT_TYPE'range=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => AXI_PROT_TYPE'length
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => S_AXI_APROT_q,
      Q         => port_access_q.Prot
    );
    
  Req_Last_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => req_last,
      Q         => req_last_q
    );
    
  Too_Long_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => exclusive_too_long_i,
      Q         => exclusive_too_long_q
    );
    
  Stp_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (C_ADDR_BYTE_POS=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => C_ADDR_BYTE_BITS
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => access_stp_bits,
      Q         => access_stp_bits_q
    );
    
  access_use_bits_new <= access_use_bits or (C_ADDR_BYTE_POS=>access_is_incr);

  Use_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (C_ADDR_BYTE_POS=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => C_ADDR_BYTE_BITS
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => access_use_bits_new,
      Q         => access_use_bits_q
    );
    
  ID_Inst: reg_ce 
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (S_AXI_AID_q'range=>'0'),
      C_CE_LOW  => (1 downto 0=>'0'),
      C_NUM_CE  => 2,
      C_SIZE    => C_S_AXI_ID_WIDTH
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET,
      CE        => transaction_and_piperun,
      D         => S_AXI_AID_q,
      Q         => id_q
    );
    
  
  -----------------------------------------------------------------------------
  -- Create Write Transaction
  -- 
  -- There are 4 things needs to be performed when configured for 
  -- Address Write side:
  -- 
  --  * Extract and forward information that might be needed for W-Channel
  --    to manipulate data when necessary (WR interface).
  --  * Forward all transactions to B-Channel for Write Response manipulation.
  --  * Forward all transactions to the Cache on the internal interface.
  --  * Turn of all Read side interface signals (R and internal).
  -----------------------------------------------------------------------------
  
  Use_Write: if( C_IS_READ = 0 ) generate
  begin
    -- ----------------------------------------
    -- Internal Information
    
    port_exist_and_allowed <= S_AXI_AVALID_q and write_req_ready and wr_ready;
    
    FE_Gen_New_And_Inst1: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_ready,
        A         => port_access_valid,
        Carry_OUT => port_ready_with_valid
      );
    
    FE_Gen_New_Or_Inst1: carry_or_n
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_ready_with_valid,
        A_N       => port_access_valid,
        Carry_OUT => port_want_new_access
      );
    
    FE_Gen_New_And_Inst2: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_want_new_access,
        A         => port_exist_and_allowed,
        Carry_OUT => new_transaction
      );
    
    -- Assign output.
    Gen_Trans: process (port_access_q, port_access_valid, port_access_len) is
    begin  -- process Gen_Trans
      wr_port_access.Addr       <= port_access_q.Addr;
      wr_port_access.Kind       <= port_access_q.Kind;
      wr_port_access.Size       <= port_access_q.Size;
      wr_port_access.Exclusive  <= port_access_q.Exclusive;
      wr_port_access.Allocate   <= port_access_q.Allocate;
      wr_port_access.Bufferable <= port_access_q.Bufferable;
      wr_port_access.Prot       <= port_access_q.Prot;
      wr_port_access.DSid       <= port_access_q.DSid;
      
      -- Unused signals.
      wr_port_access.Snoop      <= C_AWSNOOP_WriteUnique;
      wr_port_access.Barrier    <= C_BAR_NORMAL_RESPECTING;
      wr_port_access.Domain     <= C_DOMAIN_INNER_SHAREABLE;
      
      -- Assign values that has been specially handled.
      wr_port_access.Valid      <= port_access_valid;
      wr_port_access.Len        <= port_access_len;
    end process Gen_Trans;
    
    Gen_Wr_ID: process (id_q) is
    begin  -- process Gen_Wr_ID
      wr_port_id              <= (others=>'0');
      wr_port_id(id_q'range)  <= id_q;
    end process Gen_Wr_ID;
    
    
    -- ----------------------------------------
    -- W-Channel Information
    
    -- Handle data manipulation information.
    wr_valid    <= wr_valid_i;
    wr_valid_i  <= not queue_done;
    wr_last     <= req_last_q;
    wr_failed   <= exclusive_too_long_q;
    wr_offset   <= port_access_q.Addr(C_ADDR_BYTE_POS);
    wr_stp      <= access_stp_bits_q;
    wr_use      <= access_use_bits_q;
    wr_len      <= port_access_len;
    
    
    -- ----------------------------------------
    -- B-Channel Information
    
    write_req_valid   <= write_req_valid_i;
    write_req_valid_i <= not queue_done;
    write_req_ID      <= id_q;
    write_req_last    <= req_last_q;
    write_req_failed  <= exclusive_too_long_q;
    
    
    -- ----------------------------------------
    -- Unused port.
    
    read_req_valid            <= '0';
    read_req_valid_i          <= '0';
    read_req_ID               <= (others=>'0');
    read_req_last             <= '0';
    read_req_failed           <= '0';
    read_req_single_i         <= '0';
    read_req_rest_i           <= (others=>'0');
    read_req_rest_q           <= (others=>'0');
    read_req_offset           <= (others=>'0');
    read_req_stp              <= (others=>'0');
    read_req_use              <= (others=>'0');
    read_req_len              <= (others=>'0');
    rd_port_access            <= C_NULL_READ_PORT;
    rd_port_id                <= (others=>'0');
    
  end generate Use_Write;
  
  
  -----------------------------------------------------------------------------
  -- Create Read Transaction
  -- 
  -- There are 3 things needs to be performed when configured for 
  -- Address Read side:
  -- 
  --  * Forward all transactions to R-Channel for Read manipulation.
  --  * Forward all transactions to the Cache on the internal interface.
  --  * Turn of all Write side interface signals (WR, B and internal).
  -----------------------------------------------------------------------------
  
  Use_Read: if( C_IS_READ /= 0 ) generate
  begin
    -- ----------------------------------------
    -- Internal Information
    
    port_exist_and_allowed <= S_AXI_AVALID_q and read_req_ready;
    
    FE_Gen_New_And_Inst1: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_ready,
        A         => port_access_valid,
        Carry_OUT => port_ready_with_valid
      );
    
    FE_Gen_New_Or_Inst1: carry_or_n
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_ready_with_valid,
        A_N       => port_access_valid,
        Carry_OUT => port_want_new_access
      );
    
    FE_Gen_New_And_Inst2: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_want_new_access,
        A         => port_exist_and_allowed,
        Carry_OUT => new_transaction
      );
    
    -- Assign output.
    Gen_Trans: process (port_access_q, port_access_valid, port_access_len, scaled_port_access_len) is
    begin  -- process Gen_Trans
      rd_port_access.Addr       <= port_access_q.Addr;
      rd_port_access.Kind       <= port_access_q.Kind;
      rd_port_access.Size       <= port_access_q.Size;
      rd_port_access.Exclusive  <= port_access_q.Exclusive;
      rd_port_access.Allocate   <= port_access_q.Allocate;
      rd_port_access.Bufferable <= port_access_q.Bufferable;
      rd_port_access.Prot       <= port_access_q.Prot;
      rd_port_access.DSid       <= port_access_q.DSid;
      
      -- Unused signals.
      rd_port_access.Snoop      <= C_ARSNOOP_ReadOnce;
      rd_port_access.Barrier    <= C_BAR_NORMAL_RESPECTING;
      rd_port_access.Domain     <= C_DOMAIN_INNER_SHAREABLE;
      
      -- Assign values that has been specially handled.
      rd_port_access.Valid  <= port_access_valid;
      rd_port_access.Len    <= port_access_len;
      if( port_access_q.Allocate = '1' ) then
        rd_port_access.Len        <= scaled_port_access_len;
        rd_port_access.Size       <= std_logic_vector(to_unsigned(Log2(C_CACHE_DATA_WIDTH/8), 3));
      end if;
    end process Gen_Trans;
    
    Gen_Rd_ID: process (id_q) is
    begin  -- process Gen_Rd_ID
      rd_port_id              <= (others=>'0');
      rd_port_id(id_q'range)  <= id_q;
    end process Gen_Rd_ID;
    
    
    -- ----------------------------------------
    -- R-Channel Information
    
    read_req_valid    <= read_req_valid_i;
    read_req_valid_i  <= not queue_done;
    read_req_ID       <= id_q;
    read_req_last     <= req_last_q;
    read_req_failed   <= exclusive_too_long_q;
    read_req_single_i <= '1' when ( ( port_access_q.Allocate = '0' ) ) else 
                         '0';
    read_req_offset   <= port_access_q.Addr(C_ADDR_BYTE_POS);
    read_req_stp      <= access_stp_bits_q;
    read_req_use      <= access_use_bits_q;
    read_req_len      <= port_access_len;
    
    Rem_Len_Handle : process (S_AXI_ACACHE_q, first_part, access_is_wrap, wrap_must_split, access_rest_max, 
                              S_AXI_AADDR_q, access_byte_len) is
    begin  -- process Rem_Len_Handle
      if( C_CACHE_DATA_WIDTH > C_S_AXI_DATA_WIDTH ) and ( S_AXI_ACACHE_q(C_ARCACHE_READ_ALLOCATE_POS) = '0' ) then
        read_req_rest_i  <= (others=>'0');
      else
        if( first_part = '1' ) then
          if( ( access_is_wrap and not wrap_must_split ) = '1' ) then
            read_req_rest_i  <= access_byte_len(C_REST_POS) and access_rest_max;
          else
            read_req_rest_i  <= std_logic_vector(unsigned(access_rest_max) - 
                                unsigned(S_AXI_AADDR_q(C_REST_POS) and access_rest_max));
          end if;
        else
          read_req_rest_i  <= access_rest_max;
        end if;
      end if;
    end process Rem_Len_Handle;
    
    Rest_Inst: reg_ce 
      generic map(
        C_TARGET  => C_TARGET,
        C_IS_SET  => (C_REST_WIDTH - 1 downto 0=>'0'),
        C_CE_LOW  => (1 downto 0=>'0'),
        C_NUM_CE  => 2,
        C_SIZE    => C_REST_WIDTH
      )
      port map(
        CLK       => ACLK,
        SR        => ARESET,
        CE        => transaction_and_piperun,
        D         => read_req_rest_i,
        Q         => read_req_rest_q
      );
      
    
    -- ----------------------------------------
    -- Unused ports.
    
    wr_valid          <= '0';
    wr_valid_i        <= '0';
    wr_last           <= '0';
    wr_failed         <= '0';
    wr_offset         <= (others=>'0');
    wr_stp            <= (others=>'0');
    wr_use            <= (others=>'0');
    wr_len            <= (others=>'0');
    write_req_valid   <= '0';
    write_req_valid_i <= '0';
    write_req_ID      <= (others=>'0');
    write_req_last    <= '0';
    write_req_failed  <= '0';
    wr_port_access    <= C_NULL_WRITE_PORT;
    wr_port_id        <= (others=>'0');
    
  end generate Use_Read;
  
  -- Assign external.
  read_req_single <= read_req_single_i;
  read_req_rest   <= read_req_rest_q;
  
  
  -----------------------------------------------------------------------------
  -- Coherency Support
  -----------------------------------------------------------------------------
  
  No_Coherency: if( C_ENABLE_COHERENCY = 0 ) generate
  begin
  end generate No_Coherency;
  
  Use_Coherency: if( C_ENABLE_COHERENCY /= 0 ) generate
  begin
  end generate Use_Coherency;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_s_axi_gen_segments      <= C_NULL_STAT_POINT;
    
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    signal segment_update             : std_logic;
    signal segment_new                : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal segment_cnt                : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
  begin
    
    Trans_Handle : process (ACLK) is
    begin  -- process Trans_Handle
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( stat_reset = '1' ) then         -- synchronous reset (active high)
          segment_update  <= '0';
          segment_new     <= (others=>'0');
          segment_cnt     <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
          
        else
          segment_update  <= '0';
          if( arbiter_piperun = '1' and new_transaction = '1' ) then
            if( req_last = '1' ) then
              segment_update  <= '1';
              segment_new     <= segment_cnt;
              segment_cnt     <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
            else
              segment_cnt     <= std_logic_vector(unsigned(segment_cnt) + 1);
            end if;
          end if;
        end if;
      end if;
    end process Trans_Handle;
    
    Segment_Inst: sc_stat_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_SIMPLE_COUNTER     => 0,
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Counter Interface
        
        update                    => segment_update,
        counter                   => segment_new,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
      
        stat_data                 => stat_s_axi_gen_segments
      );
      
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_REST    : natural := min_of(5, C_REST_WIDTH);
    constant C_MY_BYTES   : natural := min_of(5, C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1);
    constant C_MY_LEN     : natural := min_of(8, C_LEN_WIDTH);
    constant C_MY_ID      : natural := min_of(4, C_S_AXI_ID_WIDTH);
    constant C_MY_ADDR    : natural := min_of(12, C_S_AXI_ADDR_WIDTH);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          IF_DEBUG  <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG      <= (others=>'0');
          
          -- AXI4/ACE Slave Interface Signals.
          IF_DEBUG(                              0) <= S_AXI_AVALID;
          IF_DEBUG(                              1) <= S_AXI_AREADY_I;
          
          if( C_IS_READ = 0 ) then
            -- Internal Interface Signals (Write data).
            IF_DEBUG(                             35) <= wr_valid_i;
            IF_DEBUG( 15 + C_MY_BYTES - 1 downto  15) <= port_access_q.Addr(C_MY_BYTES - 1 downto 0);  -- wr_offset
            IF_DEBUG( 20 + 3          - 1 downto  20) <= S_AXI_ASIZE_q;                           
            IF_DEBUG( 25 + C_MY_LEN   - 1 downto  25) <= port_access_len(C_MY_LEN - 1 downto 0);  -- wr_len
            IF_DEBUG(                             36) <= wr_ready;
            
            -- Write Response Information Interface Signals.
            IF_DEBUG(                              2) <= write_req_valid_i;
            IF_DEBUG(  3 + C_MY_ID    - 1 downto   3) <= id_q(C_MY_ID - 1 downto 0);        -- write_req_ID
            IF_DEBUG(                              7) <= req_last_q;                        -- write_req_last
            IF_DEBUG(                              8) <= exclusive_too_long_q;              -- write_req_failed
            IF_DEBUG(                             33) <= write_req_ready;
            
            -- Internal Interface Signals (Write request).
            IF_DEBUG(                             34) <= wr_port_ready;
          else
            -- Read Information Interface Signals.
            IF_DEBUG(                              2) <= read_req_valid_i;
            IF_DEBUG(  3 + C_MY_ID    - 1 downto   3) <= id_q(C_MY_ID - 1 downto 0);        -- read_req_ID
            IF_DEBUG(                              7) <= req_last_q;                        -- read_req_last
            IF_DEBUG(                              8) <= exclusive_too_long_q;              -- read_req_failed
            IF_DEBUG(                              9) <= read_req_single_i;
            IF_DEBUG( 10 + C_MY_REST  - 1 downto  10) <= read_req_rest_q(C_MY_REST - 1 downto 0);
            IF_DEBUG( 15 + C_MY_BYTES - 1 downto  15) <= port_access_q.Addr(C_MY_BYTES - 1 downto 0); 
                                                                                                      -- read_req_offset
            IF_DEBUG( 20 + C_MY_BYTES - 1 downto  20) <= access_stp_bits_q(C_MY_BYTES - 1 downto 0);  -- read_req_stp
            IF_DEBUG( 25 + C_MY_LEN   - 1 downto  25) <= port_access_len(C_MY_LEN - 1 downto 0);      -- read_req_len
            IF_DEBUG(                             33) <= read_req_ready;
            
            -- Internal Interface Signals (Read request).
            IF_DEBUG(                             34) <= rd_port_ready;
            IF_DEBUG(                             35) <= '0';
            IF_DEBUG(                             36) <= '0';
          end if;
          
          -- Buffer Incomming Transaction Information (AW, AR)
          IF_DEBUG(                             37) <= S_AXI_AVALID_q;
          IF_DEBUG(                             38) <= first_part;
          
          -- Decode Transaction Information
          IF_DEBUG(                             39) <= access_is_wrap;
          IF_DEBUG(                             40) <= fit_lx_line;
          IF_DEBUG(                             41) <= wrap_fit_lx_line;
          IF_DEBUG(                             42) <= wrap_is_aligned;
          IF_DEBUG(                             43) <= access_fit_sys_line;
          IF_DEBUG(                             44) <= access_cross_line;
          IF_DEBUG(                             45) <= exclusive_too_long_i;
          IF_DEBUG(                             46) <= wrap_must_split;
          IF_DEBUG(                             47) <= access_must_split;
          IF_DEBUG( 48 + C_MY_LEN   - 1 downto  48) <= wrap_end_beats(C_MY_LEN - 1 downto 0);
          IF_DEBUG( 56 + C_MY_LEN   - 1 downto  56) <= transaction_start_beats(C_MY_LEN - 1 downto 0);
          IF_DEBUG( 64 + C_MY_LEN   - 1 downto  64) <= S_AXI_ALEN_q(C_MY_LEN - 1 downto 0); 
                                                       -- wrap_tot_beats(C_MY_LEN - 1 downto 0);
          IF_DEBUG( 72 + C_MY_LEN   - 1 downto  72) <= wrap_split_beats(C_MY_LEN - 1 downto 0);
          IF_DEBUG( 80 + C_MY_ADDR  - 1 downto  80) <= access_byte_len(C_MY_ADDR - 1 downto 0);
          
          -- Handle Internal Transactions
          IF_DEBUG( 92 + C_MY_ADDR  - 1 downto  92) <= sequential_addr(C_MY_ADDR - 1 downto 0);
          IF_DEBUG(104 + C_MY_LEN   - 1 downto 104) <= (others=>'0'); -- remaining_length_new(C_MY_LEN - 1 downto 0);
          
          IF_DEBUG(                            104) <= port_access_valid;
          IF_DEBUG(                            105) <= port_exist_and_allowed;
          IF_DEBUG(                            106) <= '0';
          IF_DEBUG(                            107) <= '0';
          IF_DEBUG(                            108) <= '0';
          IF_DEBUG(                            109) <= '0';
          IF_DEBUG(                            110) <= '0';
          IF_DEBUG(                            111) <= port_ready;
          
          IF_DEBUG(112 + C_MY_LEN   - 1 downto 112) <= remaining_length(C_MY_LEN - 1 downto 0);
          IF_DEBUG(                            120) <= port_access_kind;
          IF_DEBUG(                            121) <= new_transaction;
          IF_DEBUG(                            122) <= arbiter_piperun;
          IF_DEBUG(                            123) <= transaction_done;
          IF_DEBUG(                            124) <= port_ready;
          
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- None.
  
  
end architecture IMP;






    
    
    
    
