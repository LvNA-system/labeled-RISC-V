		-------------------------------------------------------------------------------
-- sc_lookup.vhd - Entity and architecture
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
-- Filename:        sc_lookup.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_lookup.vhd
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


entity sc_lookup is
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
    C_ID_WIDTH                : natural range  1 to   32      :=  1;
    
    -- Data type and settings specific.
    C_TAG_SIZE                : natural range  3 to   96      := 15;
    C_NUM_STATUS_BITS         : natural range  4 to    4      :=  4;
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- For PARD
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_CACHE_DATA_ADDR_WIDTH   : natural range  2 to    7      :=  2;
    C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
    C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
    C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
    C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
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
    C_ADDR_WORD_HI            : natural range  2 to   63      :=  6;
    C_ADDR_WORD_LO            : natural range  2 to   63      :=  2;
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
    access_info               : in  ACCESS_TYPE;
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
    
    
    -- ---------------------------------------------------
    -- Update signals.
    
    update_tag_conflict       : in  std_logic;
    update_piperun            : in  std_logic;
    update_write_miss_full    : in  std_logic;
    update_write_miss_busy    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to Access).
    lu_check_valid_to_stab            : out std_logic;
    lookup_DSid_to_stab               : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    lookup_hit_to_stab                : out std_logic;
    lookup_miss_to_stab               : out std_logic;
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
    -- Lookup signals (to Tag & Data).
    
    lookup_tag_addr           : out std_logic_vector(C_ADDR_FULL_LINE_HI downto C_ADDR_FULL_LINE_LO);
    lookup_tag_en             : out std_logic;
    lookup_tag_we             : out std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
    lookup_tag_new_word       : out std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
    lookup_tag_current_word   : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
    
    lookup_data_addr          : out std_logic_vector(C_ADDR_DATA_HI downto C_ADDR_DATA_LO);
    lookup_data_en            : out std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
    lookup_data_we            : out std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
    lookup_data_new_word      : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    lookup_data_current_word  : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to Arbiter).
    
    lookup_read_done          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to LRU).
    
    -- Pipe control.
    lookup_fetch_piperun      : out std_logic;
    lookup_mem_piperun        : out std_logic;
    
    -- Peek LRU.
    lru_fetch_line_addr       : out std_logic_vector(C_ADDR_LINE_HI downto C_ADDR_LINE_LO);
    lru_check_next_set        : in  std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
    lru_check_next_hot_set    : in  std_logic_vector(C_NUM_SETS - 1 downto 0);
    
    -- Control LRU.
    lru_check_use_lru         : out std_logic;
    lru_check_line_addr       : out std_logic_vector(C_ADDR_LINE_HI downto C_ADDR_LINE_LO);
    lru_check_used_set        : out std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to Update).
    
    lookup_new_addr           : out std_logic_vector(C_ADDR_LINE_HI downto C_ADDR_LINE_LO);
    
    lookup_push_write_miss    : out std_logic;
    lookup_wm_allocate        : out std_logic;
    lookup_wm_evict           : out std_logic;
    lookup_wm_will_use        : out std_logic;
    lookup_wm_info            : out ACCESS_TYPE;
    lookup_wm_use_bits        : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    lookup_wm_stp_bits        : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    lookup_wm_allow_write     : out std_logic;
    
    update_valid              : out std_logic;
    update_set                : out std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
    update_info               : out ACCESS_TYPE;
    update_use_bits           : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    update_stp_bits           : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    update_hit                : out std_logic;
    update_miss               : out std_logic;
    update_read_hit           : out std_logic;
    update_read_miss          : out std_logic;
    update_read_miss_dirty    : out std_logic;
    update_write_hit          : out std_logic;
    update_write_miss         : out std_logic;
    update_write_miss_dirty   : out std_logic;
    update_locked_write_hit   : out std_logic;
    update_locked_read_hit    : out std_logic;
    update_first_write_hit    : out std_logic;
    update_evict_hit          : out std_logic;
    update_exclusive_hit      : out std_logic;
    update_early_bresp        : out std_logic;
    update_need_bs            : out std_logic;
    update_need_ar            : out std_logic;
    update_need_aw            : out std_logic;
    update_need_evict         : out std_logic;
    update_need_tag_write     : out std_logic;
    update_reused_tag         : out std_logic;
    update_old_tag            : out std_logic_vector(C_TAG_SIZE - 1 downto 0);
    update_refreshed_lru      : out std_logic;
    update_all_tags           : out std_logic_vector(C_NUM_SETS * C_TAG_SIZE - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    -- Number of Transactions
    stat_lu_opt_write_hit         : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss        : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss_dirty  : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_hit          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss         : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss_dirty   : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_write_hit  : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_read_hit   : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_first_write_hit   : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    
    stat_lu_gen_write_hit         : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss        : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss_dirty  : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_hit          : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss         : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss_dirty   : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_write_hit  : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_read_hit   : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_first_write_hit   : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    
    stat_lu_stall             : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_fetch_stall       : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_mem_stall         : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_stall        : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_hit_stall    : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_miss_stall   : out STAT_POINT_TYPE;    -- Time per occurance
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    LOOKUP_DEBUG              : out std_logic_vector(255 downto 0)
  );
end entity sc_lookup;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_lookup is

  -----------------------------------------------------------------------------
  -- Phases for Lookup:
  --  ______________   _____________   ______________
  -- | Lookup Fetch | | Lookup Mem  | | Lookup Check |
  -- |______________| |_____________| |______________|
  -- 
  -- Access is used directly in Lookup Addr.
  -- 
  -- Lookup Fetch:
  --   Address for TAG RAM input: new access, next serial set or tag write address.
  --   
  -- Lookup Memory:
  --   Tag information available from BRAM, not much left of the timing budget 
  --   left to do any thing beside some pre decoding for Hit/Miss detection.
  --   
  -- Lookup Check:
  --   All or partial TAG information (depending on current set for serial) 
  --   available with good timing.
  -- 
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_MULTIPLE_HIT              : natural :=  0;
  constant C_ASSERT_FIFO_FULL_VIOLATION       : natural :=  1;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  2;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_INT_LEN                  : natural := 8;
  constant C_SET_BITS                 : natural := Log2(C_NUM_SETS);
  constant C_SERIAL_SET_BITS          : natural := sel(C_NUM_SERIAL_SETS   = 1, 0, Log2(C_NUM_SERIAL_SETS));
  constant C_PARALLEL_SET_BITS        : natural := sel(C_NUM_PARALLEL_SETS = 1, 0, Log2(C_NUM_PARALLEL_SETS));
  constant C_SINGLE_BEAT              : std_logic_vector(C_INT_LEN-1 downto 0) := (others=>'0');
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
--  subtype C_PORT_BITS_POS             is natural range Log2(C_NUM_PORTS) - 1 downto 0;
  
  -- Data related.
  subtype C_TAG_POS                   is natural range C_TAG_SIZE - 1              downto 0;
  subtype C_BE_POS                    is natural range C_CACHE_DATA_WIDTH/8 - 1    downto 0;
  subtype C_DATA_POS                  is natural range C_CACHE_DATA_WIDTH - 1      downto 0;
  subtype C_CACHE_DATA_ADDR_POS       is natural range C_CACHE_DATA_ADDR_WIDTH - 1 downto 0;
  subtype TAG_TYPE                    is std_logic_vector(C_TAG_POS);
  subtype BE_TYPE                     is std_logic_vector(C_BE_POS);
  subtype DATA_TYPE                   is std_logic_vector(C_DATA_POS);
  
  -- Port related.
  subtype C_PORT_POS                  is rinteger range C_NUM_PORTS - 1 downto 0;
  subtype PORT_TYPE                   is std_logic_vector(C_PORT_POS);
  type PORT_BE_TYPE                   is array(C_PORT_POS) of BE_TYPE;
  type PORT_DATA_TYPE                 is array(C_PORT_POS) of DATA_TYPE;
  
  -- Set related.
  subtype C_SET_POS                   is natural range C_NUM_SETS - 1          downto 0;
  subtype C_SERIAL_SET_POS            is natural range C_NUM_SERIAL_SETS - 1   downto 0;
  subtype C_PARALLEL_SET_POS          is natural range C_NUM_PARALLEL_SETS - 1 downto 0;
  subtype C_SET_BIT_POS               is natural range C_SET_BIT_HI            downto C_SET_BIT_LO;
  subtype C_SERIAL_SET_BIT_POS        is natural range C_SET_BITS - 1          downto C_SET_BITS - C_SERIAL_SET_BITS;
  subtype C_PARALLEL_SET_BIT_POS      is natural range C_PARALLEL_SET_BITS - 1 downto 0;

  subtype SET_TYPE                    is std_logic_vector(C_SET_POS);
  subtype SERIAL_SET_TYPE             is std_logic_vector(C_SERIAL_SET_POS);
  subtype PARALLEL_SET_TYPE           is std_logic_vector(C_PARALLEL_SET_POS);
  subtype SET_BIT_TYPE                is std_logic_vector(C_SET_BIT_POS);
  subtype SERIAL_SET_BIT_TYPE         is std_logic_vector(C_SERIAL_SET_BIT_POS);
  subtype PARALLEL_SET_BIT_TYPE       is std_logic_vector(C_PARALLEL_SET_BIT_POS);
  
  type PARALLEL_TAG_TYPE              is array(C_PARALLEL_SET_POS) of TAG_TYPE;
  type PARALLEL_DATA_TYPE             is array(C_PARALLEL_SET_POS) of DATA_TYPE;
  
  type SET_TAG_TYPE                   is array(C_SET_POS) of TAG_TYPE;
  
  constant set_pos_one_vec            : SET_TYPE := (others => '1');

  -- Address related.
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI   downto C_ADDR_INTERNAL_LO;
  subtype C_ADDR_DIRECT_POS           is natural range C_ADDR_DIRECT_HI     downto C_ADDR_DIRECT_LO;
  subtype C_ADDR_DATA_POS             is natural range C_ADDR_DATA_HI       downto C_ADDR_DATA_LO;
  subtype C_ADDR_TAG_POS              is natural range C_ADDR_TAG_HI        downto C_ADDR_TAG_LO;
  subtype C_ADDR_FULL_LINE_POS        is natural range C_ADDR_FULL_LINE_HI  downto C_ADDR_FULL_LINE_LO;
  subtype C_ADDR_LINE_POS             is natural range C_ADDR_LINE_HI       downto C_ADDR_LINE_LO;
  subtype C_ADDR_OFFSET_POS           is natural range C_ADDR_WORD_HI       downto C_ADDR_BYTE_LO;
  subtype C_ADDR_WORD_POS             is natural range C_ADDR_WORD_HI       downto C_ADDR_WORD_LO;
  subtype ADDR_INTERNAL_TYPE          is std_logic_vector(C_ADDR_INTERNAL_POS);
  subtype ADDR_DIRECT_TYPE            is std_logic_vector(C_ADDR_DIRECT_POS);
  subtype ADDR_DATA_TYPE              is std_logic_vector(C_ADDR_DATA_POS);
  subtype ADDR_TAG_TYPE               is std_logic_vector(C_ADDR_TAG_POS);
  subtype ADDR_FULL_LINE_TYPE         is std_logic_vector(C_ADDR_FULL_LINE_POS);
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_WORD_TYPE              is std_logic_vector(C_ADDR_WORD_POS);
  
  -- Internal AXI derived.
  subtype C_INT_LEN_POS               is natural range C_INT_LEN - 1 downto 0;
  subtype INT_LEN_TYPE                is std_logic_vector(C_INT_LEN_POS);
  
  -- Ranges for TAG information parts.
  constant C_NUM_ADDR_TAG_BITS        : natural := C_TAG_SIZE - C_NUM_STATUS_BITS - C_DSID_WIDTH;
  constant C_TAG_VALID_POS            : natural := C_NUM_ADDR_TAG_BITS + 3;
  constant C_TAG_REUSED_POS           : natural := C_NUM_ADDR_TAG_BITS + 2;
  constant C_TAG_DIRTY_POS            : natural := C_NUM_ADDR_TAG_BITS + 1;
  constant C_TAG_LOCKED_POS           : natural := C_NUM_ADDR_TAG_BITS + 0;
  subtype C_TAG_ADDR_POS              is natural range C_NUM_ADDR_TAG_BITS - 1 downto 0;
  subtype TAG_ADDR_TYPE               is std_logic_vector(C_TAG_ADDR_POS);

  subtype C_TAG_DSID_POS              is natural range C_TAG_SIZE - 1 downto C_NUM_ADDR_TAG_BITS + C_NUM_STATUS_BITS;
  subtype TAG_DSID_TYPE               is std_logic_vector(C_TAG_DSID_POS);
  type PARALLEL_TAG_DSID_TYPE         is array(C_PARALLEL_SET_POS) of TAG_DSID_TYPE;
  
  constant C_ADDR_LINE_BITS           : natural := C_ADDR_LINE_HI - C_ADDR_LINE_LO + 1;
  
  subtype ID_TYPE                     is std_logic_vector(C_ID_WIDTH - 1 downto 0);
  
  type EX_MON_TYPE is record
    Valid             : std_logic;
    ID                : ID_TYPE;
    Addr              : ADDR_INTERNAL_TYPE;
  end record EX_MON_TYPE;
  
  type PORT_EX_MON_TYPE               is array(C_PORT_POS) of EX_MON_TYPE;
  
  constant C_NULL_EX_MON              : EX_MON_TYPE := (Valid=>'0', ID=>(others=>'0'), Addr=>(others=>'0'));
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component carry_and_di is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      DI        : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_and_di;
  
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
  
  component carry_latch_or is
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
  end component carry_latch_or;
  
  component carry_select_and is
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
  end component carry_select_and;
  
  component carry_select_and_n is
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
  end component carry_select_and_n;
  
  component carry_select_or is
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
  end component carry_select_or;
  
  component carry_select_or_n is
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
  end component carry_select_or_n;
  
  component carry_vec_or is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_INPUTS  : natural;
      C_SIZE    : natural
    );
    port (
      Carry_IN  : in  std_logic;
      A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_OUT : out std_logic
    );
  end component carry_vec_or;
  
  component carry_compare_const is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE;
      C_SIGNALS : natural := 1;
      C_SIZE   : natural;
      B_Vec    : std_logic_vector);
    port (
      A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_In  : in  std_logic;
      Carry_Out : out std_logic);
  end component carry_compare_const;
  
  component carry_compare is
    generic (
      C_KEEP   : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_SIZE    : natural
    );
    port (
      A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      B_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_In  : in  std_logic;
      Carry_Out : out std_logic
    );
  end component carry_compare;
  
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
  
  component sc_stat_event is
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
  end component sc_stat_event;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Local Reset
  
  signal ARESET_I                   : std_logic;
--  attribute dont_touch              : string;
--  attribute dont_touch              of Reset_Inst     : label is "true";
  -- ----------------------------------------
  -- Lookup Pipeline Stage: Access
  
  signal lookup_piperun_pre2        : std_logic;
  signal lookup_piperun_pre1        : std_logic;
  signal lookup_piperun_i           : std_logic;
  signal lookup_stall               : std_logic;
  
  
  -- ----------------------------------------
  -- Lookup pipe stage: Fetch
  
  signal lu_fetch_piperun_pre3      : std_logic;
  signal lu_fetch_piperun_pre2      : std_logic;
  signal lu_fetch_piperun_pre1      : std_logic;
  signal lu_fetch_piperun           : std_logic;
  signal lu_fetch_piperun_i         : std_logic;
  signal lu_fetch_valid             : std_logic;
  signal lu_fetch_stall             : std_logic;
  signal lu_fetch_info              : ACCESS_TYPE;
  signal lu_fetch_set_id            : std_logic;
  signal lu_fetch_flush_pipe        : std_logic;
  signal lu_fetch_flush_done        : std_logic;
  signal lu_fetch_protect_conflict  : std_logic;
  signal lu_fetch_last_set          : std_logic;
  signal lu_fetch_tag_addr          : ADDR_FULL_LINE_TYPE;
  signal lu_fetch_use_bits          : ADDR_OFFSET_TYPE;
  signal lu_fetch_stp_bits          : ADDR_OFFSET_TYPE;
  signal lu_fetch_info_id           : ID_TYPE;
  signal lu_fetch_same_set_as_check : std_logic;
  signal lu_fetch_same_set_as_mem   : std_logic;
  signal lu_fetch_restart_or_lck_wr_conf  : std_logic;
  signal lu_fetch_force_ser_hit     : std_logic;
  signal lu_fetch_force_par_set     : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  
  
  -- ----------------------------------------
  -- Lookup pipe stage: Memory
  
  signal lu_mem_piperun_pre3        : std_logic;
  signal lu_mem_piperun_pre2        : std_logic;
  signal lu_mem_piperun_pre1        : std_logic;
  signal lu_mem_piperun             : std_logic;
  signal lu_mem_piperun_i           : std_logic;
  signal lu_mem_piperun_vec         : std_logic_vector(0 downto 0);
  signal lu_mem_piperun_or_conflict : std_logic;
  signal lu_mem_piperun_or_conf_vec : std_logic_vector(0 downto 0);
  signal lu_mem_valid               : std_logic;
  signal lu_mem_stall               : std_logic;
  signal lu_mem_info                : ACCESS_TYPE;
  signal lu_mem_set_id              : std_logic;
  signal lu_mem_flush_pipe          : std_logic;
  signal lu_mem_flush_done          : std_logic;
  signal lu_mem_protect_conflict    : std_logic;
  signal lu_mem_protect_conflict_d1 : std_logic;
  signal lu_mem_prot_conf_edge      : std_logic;
  signal lu_mem_last_set            : std_logic;
  signal lu_mem_tag_addr            : ADDR_FULL_LINE_TYPE;
  signal lu_mem_data_addr           : ADDR_DATA_TYPE;
  signal lu_mem_use_bits            : ADDR_OFFSET_TYPE;
  signal lu_mem_stp_bits            : ADDR_OFFSET_TYPE;
  signal lu_mem_same_set_as_check   : std_logic;
  signal lu_mem_read_port           : C_PORT_POS;
  signal lu_mem_single_beat         : std_logic;
  signal lu_mem_info_id             : ID_TYPE;
  signal lu_mem_write_alloc         : std_logic;
  signal lu_mem_match_addr          : std_logic;
  signal lu_mem_tag_check_valid     : std_logic;
  signal lu_mem_match_addr_valid    : std_logic;
  signal lu_mem_force_ser_hit       : std_logic;
  signal lu_mem_force_par_set       : C_PARALLEL_SET_POS;
  
  
  -- ----------------------------------------
  -- Lookup pipe stage: Check
  
  signal lu_check_piperun_pre1      : std_logic;
  signal lu_check_piperun           : std_logic;
  signal lu_check_piperun_i         : std_logic;
  signal lu_check_valid_cmb         : std_logic;
  signal lu_check_valid             : std_logic;
  signal lu_check_completed         : std_logic;
  signal lu_check_done              : std_logic;
  signal lu_check_valid_delayed     : std_logic;
  signal lu_check_stall             : std_logic;
  signal lu_check_info              : ACCESS_TYPE;
  signal lu_check_info_delayed      : ACCESS_TYPE;
  signal lookup_read_hit_d1         : std_logic;
  signal lookup_locked_read_hit_d1  : std_logic;
  signal lu_check_wait_for_update   : std_logic;
  signal lu_check_wr_already_pushed : std_logic;
  signal lu_check_need_move2update  : std_logic;
  signal lu_check_keep_allocate     : std_logic;
  signal lu_check_possible_evict    : std_logic;
  signal lu_check_early_bresp       : std_logic;
  signal lu_check_set_id            : std_logic;
  signal lu_check_last_set          : std_logic;
  signal lu_check_lru_ser_set_match : std_logic;
  signal lu_check_tag_addr          : ADDR_FULL_LINE_TYPE;
  signal lu_check_data_addr         : ADDR_DATA_TYPE;
  signal lu_check_use_bits          : ADDR_OFFSET_TYPE;
  signal lu_check_stp_bits          : ADDR_OFFSET_TYPE;
  signal lu_check_lru_par_set       : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lu_check_par_set           : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lu_check_protected_par_set : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lu_check_old_tag_idx       : C_SET_POS;
  signal lu_check_tag_word          : PARALLEL_TAG_TYPE;
  signal lu_check_miss_next_ser     : std_logic;
  signal lu_check_read_port         : rinteger range 0 to C_NUM_PORTS - 1; -- Change type due to NCSim issues.
  signal lu_check_single_beat       : std_logic;
  signal lu_check_multi_beat        : std_logic;
  signal lu_check_port_one_hot      : PORT_TYPE;
  signal lu_check_allow_write       : std_logic;
  signal lu_check_write_alloc       : std_logic;
  signal lu_check_read_info_done    : std_logic;
  signal lu_check_enable_wr_lru     : std_logic;
  signal lu_check_match_addr        : std_logic;
  signal lu_check_tag_check_valid   : std_logic;
  signal lu_check_match_addr_valid  : std_logic;
  signal lookup_next_data_late      : std_logic;
  signal lookup_access_data_late    : std_logic;
  signal lookup_access_data_late_d1 : std_logic;
  signal lookup_protect_conflict    : std_logic;
  signal lookup_conflict_addr       : ADDR_FULL_LINE_TYPE;
  signal lookup_restart_mem         : std_logic;
  signal lookup_restart_mem_done    : std_logic;
  signal lookup_flush_pipe          : std_logic;
  signal lookup_push_write_miss_i   : std_logic;
  signal lookup_wm_allocate_i       : std_logic;
  signal lookup_wm_evict_i          : std_logic;
  
  
  -- ----------------------------------------
  -- Optimized WM
  
  signal wm_sel                     : std_logic;
  signal whne_sel                   : std_logic;
  signal lookup_md_or_wm            : std_logic;
  signal lookup_md_or_wm_or_whne    : std_logic;
  signal lookup_md_wm_whne_valid    : std_logic;
  signal lookup_push_write_miss_pre : std_logic;
  
  
  -- ----------------------------------------
  -- Detect Dirty Miss
  
  signal lru_md_set                 : rinteger range 0 to C_NUM_SETS - 1;
  signal lru_dirty_bit              : std_logic;
  signal dirty_bit_miss             : std_logic;
  signal dirty_bit_miss_valid       : std_logic;
  signal lu_check_valid_vec         : SET_TYPE;
  signal md_valid_qualified         : SET_TYPE;
  signal md_valid_alloc_miss        : std_logic;
  signal dirty_miss_valid           : std_logic;
  signal md_hit_dirty               : PARALLEL_SET_TYPE;
  signal dirty_bit                  : std_logic;
  signal lu_check_info_evict_vec    : PARALLEL_SET_TYPE;
  signal md_valid_hit_miss          : PARALLEL_SET_TYPE;
  signal md_check_valid             : std_logic;
  signal dirty_bit_valid            : std_logic;
  signal lookup_miss_dirty_pre      : std_logic;
  
  
  -- ----------------------------------------
  -- Detect Protected Conflict
  
  signal lru_pc_set                 : rinteger range 0 to C_NUM_SETS - 1;
  signal lru_protected_bit          : std_logic;
  signal protected_bit_miss         : std_logic;
  signal protected_bit_miss_valid   : std_logic;
  signal pc_valid_alloc_miss        : std_logic;
  signal protected_miss_valid       : std_logic;
  signal pc_hit_protected           : PARALLEL_SET_TYPE;
  signal protected_bit              : std_logic;
  signal lu_mem_protect_conflict_d1_vec : PARALLEL_SET_TYPE;
  signal pc_filter                  : PARALLEL_SET_TYPE;
  signal filtered_protection_bit    : std_logic;
  
  
  -- ----------------------------------------
  -- Update Pipeline Stage
  
  signal update_valid_cmb           : std_logic;
  signal update_need_bs_cmb         : std_logic;
  signal update_need_ar_cmb         : std_logic;
  signal update_need_aw_cmb         : std_logic;
  signal update_need_evict_cmb      : std_logic;
  signal update_need_tag_write_cmb  : std_logic;
  signal update_valid_i             : std_logic;
  signal update_need_bs_i           : std_logic;
  signal update_need_ar_i           : std_logic;
  signal update_need_aw_i           : std_logic;
  signal update_need_evict_i        : std_logic;
  signal update_need_tag_write_i    : std_logic;
  
  
  -- ----------------------------------------
  -- Read Transaction Properties
  
  signal lookup_read_data_new_i     : std_logic;
  signal lookup_read_data_new_vec   : PORT_TYPE;
  signal lookup_read_data_hit_i     : std_logic;
  signal lookup_read_done_i         : std_logic;
  signal lookup_read_done_vec       : PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Exclusive Monitor
  
  signal lookup_exclusive_monitor   : PORT_EX_MON_TYPE;
  signal lu_mem_ex_mon_match        : PORT_TYPE;
  signal lu_mem_ex_mon_hit          : std_logic;
  
  
  -- ----------------------------------------
  -- LRU Handling
  
  signal lru_check_use_lru_i        : std_logic;
  signal lookup_invalid_exist       : std_logic;
  signal lookup_first_invalid       : std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
  signal lookup_new_tag_assoc_set   : std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
  signal lookup_new_tag_assoc_par_set : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lru_tag_assoc_set          : std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
  signal lru_tag_assoc_par_set      : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  
  
  -- ----------------------------------------
  -- Stall Detection 
  
  signal update_write_miss_true_busy  : PORT_TYPE;
  signal lu_check_wait_for_update_vec : PORT_TYPE;
  signal lookup_data_hit_stall        : std_logic;
  signal lookup_push_wm_stall         : std_logic;
  signal lookup_data_miss_stall       : std_logic;
  
  
  -- ----------------------------------------
  -- TAG Conflict 
  
  signal lu_mem_tag_conflict        : std_logic;
  signal lu_check_tag_conflict      : std_logic;
  signal lookup_tag_conflict        : std_logic;
  
  
  -- ----------------------------------------
  -- Data Offset Counter
  
  signal lookup_use_bits            : ADDR_OFFSET_TYPE;
  signal lookup_stp_bits            : ADDR_OFFSET_TYPE;
  signal lookup_kind                : std_logic;
  signal lookup_step_last           : std_logic;
  signal lookup_base_offset         : ADDR_OFFSET_TYPE;
  signal lookup_word_offset         : ADDR_OFFSET_TYPE;
  signal lookup_offset_len          : INT_LEN_TYPE;
  signal lookup_offset_len_cmb      : INT_LEN_TYPE;
  signal lookup_offset_len_cnt      : INT_LEN_TYPE;
  signal lookup_last_beat           : std_logic;
  signal lookup_next_is_last_beat   : std_logic;
  signal lookup_offset_first        : std_logic;
  signal lookup_force_first         : std_logic;
  signal lookup_offset_all_first    : std_logic;
  signal lookup_offset_last         : std_logic;
  signal lookup_offset_cnt          : ADDR_OFFSET_TYPE;
  signal lookup_offset_cnt_cmb      : ADDR_OFFSET_TYPE;
  signal lookup_data_stall          : std_logic;
  
  signal access_data_valid_stall      : PORT_TYPE;
  signal lu_check_info_wr_vec         : PORT_TYPE;
  signal access_data_conflict_stall   : PORT_TYPE;
  signal read_locked_vector           : PARALLEL_SET_TYPE;
  signal lu_check_info_wr_pspvec      : PARALLEL_SET_TYPE;
  signal lu_io_selected_full          : std_logic;
  signal lu_io_valid_read             : std_logic;
  signal lu_io_full_block_read        : std_logic;
  signal lu_io_write_blocked          : std_logic;
  signal lu_io_lud_stall_pipe         : std_logic;
  
  signal lookup_io_stall_carry        : std_logic;
  signal lookup_io_stall_carry_no_wait: std_logic;
  signal lookup_io_and_conflict_stall : std_logic;
  signal lookup_io_stall_hit_carry    : std_logic;
  signal lu_ds_no_last                : std_logic;
  signal lookup_io_stall_hit_carry_no_last : std_logic;
  signal lookup_io_stall_pre_valid    : std_logic;
  signal lookup_io_stall_valid        : std_logic;
  signal lookup_io_data_stall         : std_logic;
  
  signal lu_ds_last_beat_multi_start  : std_logic;
  signal lu_ds_last_beat_sel_first    : std_logic;
  signal lu_ds_last_beat_next_last_n  : std_logic;
  signal lu_ds_last_beat              : std_logic;
  signal lu_ds_last_beat_no_wait      : std_logic;
  signal lu_ds_last_beat_all_tag_hit  : std_logic;
  signal lu_ds_last_beat_hit          : std_logic;
  signal lu_ds_last_beat_valid_hit    : std_logic;
  signal lu_ds_last_beat_valid        : std_logic;
  signal lu_ds_last_beat_rd_locked    : PARALLEL_SET_TYPE;
--  signal lu_ds_lb_delayed_restart     : std_logic;
  signal lu_ds_lb_delayed_restart_normal    : std_logic;
  signal lud_step_allow_read_step_normal    : std_logic;
--  signal lud_step_allow_read_step_conf      : std_logic;
  signal lu_ds_rs_miss                : std_logic;
  signal lu_ds_rs_read_valid          : std_logic;
  signal lu_ds_rs_read_miss           : std_logic;
  signal lu_ds_rs_new_valid           : std_logic;
  signal lu_ds_rs_new_read_no_rs      : std_logic;
  signal lu_ds_rs_valid_restart       : std_logic;
  signal lu_ds_rs_valid_mem_restart   : std_logic;
  signal lu_ds_rs_del_restart_no_rs   : std_logic;
  signal lu_ds_lb_delayed_restart_conflict  : std_logic;
  signal lu_ds_last_beat_stall_pre    : std_logic;
  signal lu_ds_last_beat_stall        : std_logic;
  
  
  -- ----------------------------------------
  -- Control Lookup TAG
  
  signal lookup_tag_addr_i          : ADDR_FULL_LINE_TYPE;
  signal lookup_tag_en_i            : std_logic;
  
  
  -- ----------------------------------------
  -- Control Lookup DATA
  
  signal lookup_data_addr_i         : ADDR_DATA_TYPE;
  signal lookup_data_en_sel         : PARALLEL_SET_TYPE;
  signal lookup_data_en_i           : PARALLEL_SET_TYPE;
  signal lookup_write_hit_valid_vec : BE_TYPE;
  signal lu_check_allow_write_vec   : BE_TYPE;
  signal lu_check_wait_for_update_bevec : BE_TYPE;
  signal lookup_data_we_i           : BE_TYPE;
  
  
  -- ----------------------------------------
  -- Control Lookup DATA
  
  signal lookup_data_sel_check_addr : std_logic;
  signal lu_mem_info_wr_vec         : PARALLEL_SET_TYPE;
  signal lud_mem_waiting_for_pipe_vec : PARALLEL_SET_TYPE;
  signal lookup_data_en_read        : PARALLEL_SET_TYPE;
  signal lookup_data_en_write       : PARALLEL_SET_TYPE;
  signal lu_check_wait_for_update_pspvec : PARALLEL_SET_TYPE;
  
  
  -- ----------------------------------------
  -- Cache Hit & Miss Detect (Mem)
  
  signal lu_mem_valid_or_conflict   : std_logic;
  signal par_mem_cur_write          : std_logic;
  signal par_mem_cur_force_hit      : std_logic;
  signal par_mem_cur_force_hit_vec  : PARALLEL_SET_TYPE;
  signal par_mem_cur_wr_allocate    : std_logic;
  signal par_mem_cur_addr           : ADDR_TAG_TYPE;
  signal par_mem_cur_DSid           : PARD_DSID_TYPE;
  signal par_mem_tag_word           : PARALLEL_TAG_TYPE;
  signal par_mem_DSid_word          : PARALLEL_TAG_DSID_TYPE;
  signal par_mem_valid_carry        : PARALLEL_SET_TYPE;
  signal par_mem_DSid_valid_tag     : PARALLEL_SET_TYPE;
  signal par_mem_pure_valid_tag     : PARALLEL_SET_TYPE;
  signal par_mem_real_valid_tag     : PARALLEL_SET_TYPE;
  signal par_mem_masked_valid_tag   : PARALLEL_SET_TYPE;
  signal par_mem_valid_tag          : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit            : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_pc    : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_md    : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_wm    : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_ds    : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_lb    : PARALLEL_SET_TYPE;
  signal par_mem_tag_hit_copy_rs    : PARALLEL_SET_TYPE;
  signal par_mem_tag_miss           : PARALLEL_SET_TYPE;
  signal par_mem_sel_locked         : PARALLEL_SET_TYPE;
  signal par_mem_locked_hit         : PARALLEL_SET_TYPE;
  signal par_mem_locked_hit_copy_lb : PARALLEL_SET_TYPE;
  signal par_mem_locked_write       : PARALLEL_SET_TYPE;
  signal par_mem_valid_protect      : PARALLEL_SET_TYPE;
  signal par_mem_other_protect      : PARALLEL_SET_TYPE;
  signal par_mem_protected_pre1     : PARALLEL_SET_TYPE;
  signal par_mem_protected          : PARALLEL_SET_TYPE;
  signal par_mem_valid_bits         : PARALLEL_SET_TYPE;
  signal par_mem_reused_bits        : PARALLEL_SET_TYPE;
  signal par_mem_dirty_bits         : PARALLEL_SET_TYPE;
  signal par_mem_locked_bits        : PARALLEL_SET_TYPE;
  signal par_mem_force_valid        : PARALLEL_SET_TYPE;
  
  
  -- ----------------------------------------
  -- Cache Hit & Miss Detect (Check)
  
  signal par_check_valid_tag        : PARALLEL_SET_TYPE;
  signal par_check_tag_hit          : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_pc  : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_md  : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_wm  : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_ds  : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_lb  : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_copy_rs  : PARALLEL_SET_TYPE;
  signal par_check_tag_miss         : PARALLEL_SET_TYPE;
  signal par_check_locked_hit_copy_lb : PARALLEL_SET_TYPE;
  signal par_check_locked_hit       : PARALLEL_SET_TYPE;
  signal par_check_locked_write     : PARALLEL_SET_TYPE;
  signal par_check_protected        : PARALLEL_SET_TYPE;
  signal par_check_valid_bits       : PARALLEL_SET_TYPE;
  signal par_check_reused_bits_cmb  : PARALLEL_SET_TYPE;
  signal par_check_dirty_bits_cmb   : PARALLEL_SET_TYPE;
  signal par_check_locked_bits_cmb  : PARALLEL_SET_TYPE;
  signal par_check_reused_bits      : PARALLEL_SET_TYPE;
  signal par_check_dirty_bits       : PARALLEL_SET_TYPE;
  signal par_check_locked_bits      : PARALLEL_SET_TYPE;
  signal par_check_tag_hit_all      : std_logic;
  signal par_check_tag_hit_all_copy_ds  : std_logic;
  signal par_check_tag_miss_all     : std_logic;
  signal lookup_raw_hit             : std_logic;
  signal lookup_hit                 : std_logic;
  signal lookup_raw_miss            : std_logic;
  signal lookup_miss                : std_logic;
  signal lookup_miss_dirty          : std_logic;
  signal lookup_evict_hit           : std_logic;
  signal lookup_read_hit            : std_logic;
  signal lookup_read_miss           : std_logic;
  signal lookup_read_miss_dirty     : std_logic;
  signal lookup_write_hit           : std_logic;
  signal lookup_locked_wr_hit_raw   : std_logic;
  signal lookup_locked_write_hit    : std_logic;
  signal lookup_locked_read_hit     : std_logic;
  signal lookup_true_locked_read    : std_logic;
  signal lookup_block_reuse         : std_logic;
  signal lookup_first_write_hit     : std_logic;
  signal lookup_write_miss          : std_logic;
  signal lookup_write_miss_dirty    : std_logic;
  signal lookup_hit_par_set         : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lookup_hit_par_set_delayed : natural range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lookup_tag_assoc_set       : std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
  

  -- ----------------------------------------
  -- Detect Write Hit
  
  signal par_check_tag_hit_all_carry  : std_logic;
  signal lookup_raw_hit_carry2        : std_logic;
  signal lookup_hit_carry             : std_logic;
  signal lookup_write_hit_carry       : std_logic;
  signal lookup_write_hit_no_busy     : std_logic;
  signal lookup_write_hit_no_conflict : std_logic;
  signal lookup_write_hit_valid       : std_logic;
  
  
  -- ----------------------------------------
  -- All Set Information
  
  signal lookup_all_dirty_bits      : SET_TYPE;
  signal lookup_all_valid_bits      : SET_TYPE;
  signal lookup_all_reused_bits     : SET_TYPE;
  signal lookup_all_locked_bits     : SET_TYPE;
  signal lookup_all_protected       : SET_TYPE;
  signal lookup_all_tag_bits        : SET_TAG_TYPE;
  
  
  -- ----------------------------------------
  -- Read Data Forwarding
  
  signal lookup_read_data_valid_i   : PORT_TYPE;
  signal lookup_read_port           : C_PORT_POS;
  signal lookup_read_pipeline_port  : C_PORT_POS;
  signal lookup_read_stall_port     : C_PORT_POS;
  
  
  -- ----------------------------------------
  -- Data Pipeline Stage: Step (virtual stage)
  
  signal lud_step_use_check         : std_logic;
  signal lud_step_offset_is_read    : std_logic;
  signal lud_step_is_read           : std_logic;
  signal lud_step_write_port_num    : C_PORT_POS;
  signal lud_step_allow_write_step  : std_logic;
  signal lud_step_allow_read_step   : std_logic;
  signal lud_step_offset            : std_logic;
  signal lud_step_stall             : std_logic;
  signal lud_step_pos_read_in_mem   : std_logic;
  signal lud_step_want_check_step   : std_logic;
  signal lud_step_want_mem_step     : std_logic;
  signal lud_step_want_restart      : std_logic;
  signal lud_step_delayed_restart   : std_logic;
  signal lud_step_want_read_step    : std_logic;
  signal lud_step_want_write_step   : std_logic;
  signal lud_step_want_step_offset  : std_logic;
  signal lud_step_want_stall        : std_logic;
  signal lookup_data_en_ii          : std_logic_vector(C_NUM_PARALLEL_SETS downto 0);
  
  
  -- ----------------------------------------
  -- Data Pipeline Stage: Address
  
  signal lud_addr_piperun_pre1      : std_logic;
  signal lud_addr_piperun_pre2      : std_logic;
  signal lud_addr_rerun_after_conf  : std_logic;
  signal lud_addr_piperun           : std_logic;
  signal lud_addr_stall             : std_logic;
  signal lud_addr_pipeline_full     : std_logic;
  
  
  -- ----------------------------------------
  -- Data Pipeline Stage: Memory
  
  signal lud_mem_piperun            : std_logic;
  signal lud_mem_speculative_valid  : std_logic;
  signal lud_mem_valid_pipe         : std_logic;
  signal lud_mem_valid              : std_logic;
  signal lud_mem_stall              : std_logic;
  signal lud_mem_rresp              : AXI_RRESP_TYPE;
  signal lud_mem_port_num           : C_PORT_POS;
  signal lud_mem_port_one_hot       : PORT_TYPE;
  signal lud_mem_completed          : std_logic;
  signal lud_mem_use_spec_cmb       : std_logic;
  signal lud_mem_use_speculative    : std_logic;
  signal lud_mem_last               : std_logic;
  signal lud_mem_delayed_read_data  : std_logic;
  signal lud_mem_set                : rinteger range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lud_mem_set_d1             : natural range 0 to C_NUM_PARALLEL_SETS - 1;
  signal lud_mem_conflict           : std_logic;
  signal lud_mem_waiting_for_pipe   : std_logic;
  signal lud_mem_already_used       : std_logic;
  signal lud_mem_keep_single_during_stall : std_logic;
  
  
  -- ----------------------------------------
  -- Data Pipeline Stage: Pipeline
  
  signal lud_reg_piperun_pre1       : std_logic;
  signal lud_reg_piperun            : std_logic;
  signal lud_reg_valid              : std_logic;
  signal lud_mem_valid_vec          : PORT_TYPE;
  signal lud_reg_valid_one_hot      : PORT_TYPE;
  signal lud_reg_last               : std_logic;
  signal lud_reg_rresp              : AXI_RRESP_TYPE;
  signal lud_reg_port_num           : rinteger range 0 to C_NUM_PORTS - 1; -- Change type due to NCSim issues.
  
  
  -- ----------------------------------------
  -- Write Data Forwarding

  signal lookup_write_data_ready_vec : PORT_TYPE;
  signal lookup_write_data_ready_i  : PORT_TYPE;
  signal access_be_word_i           : BE_TYPE;
  signal lookup_data_new_word_i     : DATA_TYPE;
  signal lookup_write_port          : rinteger range 0 to C_NUM_PORTS - 1; -- Change type due to NCSim issues.
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  signal lu_check_stat_done_for_pard : std_logic;
  signal valid_new_stat_for_pard     : std_logic;
  signal new_hit_for_pard                     : std_logic;
  signal new_miss_for_pard                    : std_logic;
  -----------------------------------------------------------------------------
  -- Attributes
  -----------------------------------------------------------------------------
  attribute mark_debug              : string;
  attribute mark_debug              of new_hit_for_pard     : signal is "true";
  attribute mark_debug              of new_miss_for_pard     : signal is "true";
  attribute mark_debug              of lu_check_info     : signal is "true";
  
begin  -- architecture IMP

  -----------------------------------------------------------------------------
  -- Internal Reset Fan-Out
  -----------------------------------------------------------------------------
  
  Reset_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => '0',
      CE        => "1",
      D         => ARESET,
      Q         => ARESET_I
    );
  
  
  -----------------------------------------------------------------------------
  -- New Access Handle 
  -----------------------------------------------------------------------------
  
  -- Select source of fetch.
  lu_fetch_info     <= access_info;
  lu_fetch_use_bits <= access_use;
  lu_fetch_stp_bits <= access_stp;
  lu_fetch_info_id  <= access_id;
  
  -----------------------------------------------------------------------------
  -- Lookup Pipeline Stage: Access
  -- 
  -- Propagate Piperun signal when last serial set has been reached and there
  -- are no tag address conflicts or other stalls prohibiting progress.
  -----------------------------------------------------------------------------
  
  
  -- Move this stage when there is no stall or there is a bubble to fill.
  lookup_piperun    <= lookup_piperun_i;
--  lookup_piperun_i  <= ( lu_fetch_piperun_i or lu_fetch_flush_pipe or not access_valid ) and not lookup_stall;
  LU_PR_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_fetch_piperun_i,
      A         => lu_fetch_flush_pipe,
      Carry_OUT => lookup_piperun_pre2
    );
  LU_PR_Or_Inst2: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_piperun_pre2,
      A_N       => access_valid,
      Carry_OUT => lookup_piperun_pre1
    );
  LU_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_piperun_pre1,
      A_N       => lookup_stall,
      Carry_OUT => lookup_piperun_i
    );
  
  -- Stall to Access when it is not possible to continue because of conflicts.
  lookup_stall      <= access_valid and not lu_fetch_last_set and not lu_fetch_flush_pipe;
  
  -- Block flush signal when stage has been flushed.
  Fetch_Flush_Control : process (ACLK) is
  begin  -- process Fetch_Flush_Control
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_fetch_flush_done <= '0';
      else
        if( lu_check_piperun = '1' ) then
          lu_fetch_flush_done <= '0';
        elsif( lookup_piperun_i = '1' ) then
          lu_fetch_flush_done <= lu_fetch_flush_pipe;
        end if;
      end if;
    end if;
  end process Fetch_Flush_Control;
  
  
  -----------------------------------------------------------------------------
  -- Control Serial Association
  -- 
  -- Control the serial Tag search and handling of the associative bit in the 
  -- address.
  -- 
  -- It possible to configure in two static modes:
  --  * Pure Parallel Association
  --  * Mixed Association
  -- 
  -- The Locked, Dirty and Valid bits are collected during a serial search
  -- to make the handling in Check state more efficient, i.e. no need to 
  -- re-read Tag for Read Miss and such.
  -----------------------------------------------------------------------------
  
  
  Use_Serial_Assoc: if( C_NUM_SERIAL_SETS > 1 ) generate
  
    subtype C_ADDR_SER_SET_POS              is natural range C_ADDR_FULL_LINE_HI  downto C_ADDR_LINE_HI + 1;
    
    -- Address bit extraction.
    subtype C_SET_SERIAL_POS            is natural range C_SET_BITS - 1          downto C_SET_BITS - C_SERIAL_SET_BITS;
    subtype C_SET_PARALLEL_POS          is natural range C_PARALLEL_SET_BITS - 1 downto 0;
    subtype SET_SERIAL_TYPE             is std_logic_vector(C_SET_SERIAL_POS);
    subtype SET_PARALLEL_TYPE           is std_logic_vector(C_SET_PARALLEL_POS);
    
    -- Data Dirty and Shared serial position.
    subtype C_SERIAL_VRDLP_DATA_POS     is natural range (C_NUM_SERIAL_SETS-1)*C_NUM_PARALLEL_SETS-1 downto 0;
    subtype SERIAL_VRDLP_DATA_TYPE      is std_logic_vector(C_SERIAL_VRDLP_DATA_POS);
    type SERIAL_VRDLP_TAG_TYPE          is array(C_SERIAL_VRDLP_DATA_POS) of TAG_TYPE;
    
    -- End of serial sweep.
    constant C_ALMOST_LAST_SET  : SET_SERIAL_TYPE := 
                                        std_logic_vector(to_unsigned(C_NUM_SERIAL_SETS - 2, C_SERIAL_SET_BITS));
    constant C_LAST_SET         : SET_SERIAL_TYPE := 
                                        std_logic_vector(to_unsigned(C_NUM_SERIAL_SETS - 1, C_SERIAL_SET_BITS));
    
    -- Shift registers for Dirty and Shared.
    signal lookup_ser_valid_bits    : SERIAL_VRDLP_DATA_TYPE;
    signal lookup_ser_reused_bits   : SERIAL_VRDLP_DATA_TYPE;
    signal lookup_ser_dirty_bits    : SERIAL_VRDLP_DATA_TYPE;
    signal lookup_ser_locked_bits   : SERIAL_VRDLP_DATA_TYPE;
    signal lookup_ser_protected     : SERIAL_VRDLP_DATA_TYPE;
    signal lookup_ser_tag_bits      : SERIAL_VRDLP_TAG_TYPE;
    
    -- Serial set counter.
    signal serial_set_cnt           : SET_SERIAL_TYPE;
    signal serial_set_cnt_new       : SET_SERIAL_TYPE;
    signal ser_mem_set_cnt          : SET_SERIAL_TYPE;
    signal ser_check_set_cnt        : SET_SERIAL_TYPE;
    
  begin
    -- Sweep through all serial association address bits.
    Serial_Assoc_Cnt_Handle : process (ACLK) is
    begin  -- process Serial_Assoc_Cnt_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if ARESET_I = '1' then                      -- synchronous reset (active high)
          serial_set_cnt    <= (others => '0');
          lu_fetch_last_set <= '0';
          lu_fetch_set_id   <= '0';
        else
          if( lu_fetch_piperun = '1' ) then
            if lu_fetch_flush_pipe = '1' then
              serial_set_cnt    <= (others => '0');
              lu_fetch_last_set <= '0';
              lu_fetch_set_id   <= not lu_fetch_set_id;
            elsif( lu_fetch_valid = '1' ) then
              -- Count serial set
              serial_set_cnt    <= serial_set_cnt_new;
              
              -- Determine last.
              if( serial_set_cnt_new = C_LAST_SET ) then
                lu_fetch_last_set <= '1';
              else
                lu_fetch_last_set <= '0';
              end if;
              
              -- Control set ID so that different sets can be distinguised in the pipe.
              if( lu_fetch_last_set = '1' ) then
                lu_fetch_set_id   <= not lu_fetch_set_id;
              end if;
            end if;
          end if;
        end if;
      end if;
    end process Serial_Assoc_Cnt_Handle;
    
    Pipeline_Stage_Mem_Ser : process (ACLK) is
    begin  -- process Pipeline_Stage_Mem_Ser
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          ser_mem_set_cnt <= (others => '0');
        elsif( lu_fetch_piperun = '1' ) then
          ser_mem_set_cnt <= serial_set_cnt;
        end if;
      end if;
    end process Pipeline_Stage_Mem_Ser;
    
    Pipeline_Stage_Check_Ser : process (ACLK) is
    begin  -- process Pipeline_Stage_Check_Ser
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          ser_check_set_cnt <= (others => '0');
        elsif( lu_mem_piperun = '1' ) then
          ser_check_set_cnt <= ser_mem_set_cnt;
        end if;
      end if;
    end process Pipeline_Stage_Check_Ser;
    
    -- Select current length value.
    serial_set_cnt_new  <= std_logic_vector(unsigned(serial_set_cnt) + 1);
    
    -- Capture Valid, Dirty and Locked bits from the TAGs. 
    Serial_Assoc_VDL_Handle : process (ACLK) is
    begin  -- process Serial_Assoc_VDL_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if ARESET_I = '1' then                      -- synchronous reset (active high)
          lookup_ser_valid_bits   <= (others => '0');
          lookup_ser_reused_bits  <= (others => '0');
          lookup_ser_dirty_bits   <= (others => '0');
          lookup_ser_locked_bits  <= (others => '0');
          lookup_ser_protected    <= (others => '0');
        else
          if ( lu_check_completed = '1' ) then
            for i in 0 to C_NUM_SERIAL_SETS - 2 loop
              lookup_ser_valid_bits(C_NUM_PARALLEL_SETS*(i+1)-1 downto C_NUM_PARALLEL_SETS*i)  <= 
                      lookup_all_valid_bits(C_NUM_PARALLEL_SETS*(i+2)-1 downto C_NUM_PARALLEL_SETS*(i+1));
              lookup_ser_reused_bits(C_NUM_PARALLEL_SETS*(i+1)-1 downto C_NUM_PARALLEL_SETS*i)  <= 
                      lookup_all_reused_bits(C_NUM_PARALLEL_SETS*(i+2)-1 downto C_NUM_PARALLEL_SETS*(i+1));
              lookup_ser_dirty_bits(C_NUM_PARALLEL_SETS*(i+1)-1 downto C_NUM_PARALLEL_SETS*i)  <= 
                      lookup_all_dirty_bits(C_NUM_PARALLEL_SETS*(i+2)-1 downto C_NUM_PARALLEL_SETS*(i+1));
              lookup_ser_locked_bits(C_NUM_PARALLEL_SETS*(i+1)-1 downto C_NUM_PARALLEL_SETS*i) <= 
                      lookup_all_locked_bits(C_NUM_PARALLEL_SETS*(i+2)-1 downto C_NUM_PARALLEL_SETS*(i+1));
              lookup_ser_protected(C_NUM_PARALLEL_SETS*(i+1)-1 downto C_NUM_PARALLEL_SETS*i) <= 
                      lookup_all_protected(C_NUM_PARALLEL_SETS*(i+2)-1 downto C_NUM_PARALLEL_SETS*(i+1));
              for j in 0 to C_NUM_PARALLEL_SETS - 1 loop
                lookup_ser_tag_bits(C_NUM_PARALLEL_SETS*i + j) <= lookup_all_tag_bits(C_NUM_PARALLEL_SETS*(i+1) + j);
              end loop;
            end loop;
          end if;
        end if;
      end if;
    end process Serial_Assoc_VDL_Handle;
    
    -- Combine serial bits with current information.
    lookup_all_valid_bits   <= par_check_valid_bits   & lookup_ser_valid_bits;
    lookup_all_reused_bits  <= par_check_reused_bits  & lookup_ser_reused_bits;
    lookup_all_dirty_bits   <= par_check_dirty_bits   & lookup_ser_dirty_bits;
    lookup_all_locked_bits  <= par_check_locked_bits  & lookup_ser_locked_bits;
    lookup_all_protected    <= par_check_protected    & lookup_ser_protected;
    Assign_Tag: process (lu_check_tag_word, lookup_ser_tag_bits) is
    begin  -- process Assign_Tag
      for i in 0 to C_NUM_SERIAL_SETS - 1 loop
        for j in 0 to C_NUM_PARALLEL_SETS - 1 loop
          if( i = C_NUM_SERIAL_SETS - 1 ) then
            lookup_all_tag_bits(C_NUM_PARALLEL_SETS*i + j)  <= lu_check_tag_word(j);
          else
            lookup_all_tag_bits(C_NUM_PARALLEL_SETS*i + j)  <= lookup_ser_tag_bits(C_NUM_PARALLEL_SETS*i + j);
          end if;
        end loop;
      end loop;
    end process Assign_Tag;
    
    -- Tag address part.
    lu_fetch_tag_addr       <= serial_set_cnt & lu_fetch_info.Addr(C_ADDR_LINE_POS);
    
    -- Adjust serial set for Conflict when it is a Miss.
    lookup_conflict_addr(C_ADDR_FULL_LINE_HI downto C_ADDR_LINE_HI + 1) <= 
                                             lu_check_tag_addr(C_ADDR_FULL_LINE_HI downto C_ADDR_LINE_HI + 1) 
                                                  when ( lookup_raw_hit = '1' ) else
                                             lookup_new_tag_assoc_set(C_SERIAL_SET_BIT_POS);
    lookup_conflict_addr(C_ADDR_LINE_POS) <= lu_check_tag_addr(C_ADDR_LINE_POS);
      
    -- Determine if this is the serial set pointed out by the LRU.
    lu_check_lru_ser_set_match  <= '1' when ser_check_set_cnt = lru_check_next_set(C_SERIAL_SET_BIT_POS) else '0';
    
    -- Mark which set is selected by address for forcing.
    lu_fetch_force_ser_hit      <= '1' when ( lu_fetch_info.Addr(C_ADDR_SER_SET_POS) = serial_set_cnt ) else 
                                   '0';
    
    Use_Parallel_Assoc: if( C_NUM_PARALLEL_SETS > 1 ) generate
      subtype C_ADDR_PAR_SET_POS              is natural range C_ADDR_TAG_LO - 1    downto C_ADDR_FULL_LINE_HI + 1;
    begin
      -- Mark which set is selected by address (par).
      lu_fetch_force_par_set      <= to_integer(unsigned(lu_fetch_info.Addr(C_ADDR_PAR_SET_POS)));
      
      -- Complete set (serial and parallel).
      lookup_tag_assoc_set        <= ser_check_set_cnt & 
                                     std_logic_vector(to_unsigned(lookup_hit_par_set, C_PARALLEL_SET_BITS));
      lru_tag_assoc_par_set       <= to_integer(unsigned(lru_tag_assoc_set(C_PARALLEL_SET_BIT_POS)));
      
      lu_check_par_set            <= lookup_hit_par_set;
      lu_check_lru_par_set        <= to_integer(unsigned(lru_check_next_set(C_PARALLEL_SET_BIT_POS)));
      lookup_new_tag_assoc_par_set<= to_integer(unsigned(lookup_new_tag_assoc_set(C_PARALLEL_SET_BIT_POS)));
    end generate Use_Parallel_Assoc;
    No_Parallel_Assoc: if( C_NUM_PARALLEL_SETS = 1 ) generate
    begin
      -- Mark which set is selected by address (par).
      lu_fetch_force_par_set      <= 0;
      
      -- Complete set (serial only).
      lookup_tag_assoc_set        <= ser_check_set_cnt;
      lru_tag_assoc_par_set       <= 0;
      
      lu_check_par_set            <= 0;
      lu_check_lru_par_set        <= 0;
      lookup_new_tag_assoc_par_set<= 0;
    end generate No_Parallel_Assoc;
    
    -- Check if this is still the same set.
    lu_fetch_same_set_as_check  <= '1' when lu_fetch_set_id = lu_check_set_id else '0';
    lu_fetch_same_set_as_mem    <= '1' when lu_fetch_set_id = lu_mem_set_id   else '0';
    lu_mem_same_set_as_check    <= '1' when lu_mem_set_id   = lu_check_set_id else '0';
    
  end generate Use_Serial_Assoc;

  
  No_Serial_Assoc: if( C_NUM_SERIAL_SETS = 1 ) generate
      subtype C_ADDR_PAR_SET_POS              is natural range C_ADDR_TAG_LO - 1    downto C_ADDR_FULL_LINE_HI + 1;
  begin
    -- Combine serial bits with current information.
    lookup_all_valid_bits       <= par_check_valid_bits;
    lookup_all_reused_bits      <= par_check_reused_bits;
    lookup_all_dirty_bits       <= par_check_dirty_bits;
    lookup_all_locked_bits      <= par_check_locked_bits;
    lookup_all_protected        <= par_check_protected;
    Assign_Tag: for i in 0 to C_NUM_PARALLEL_SETS - 1 generate
    begin
      lookup_all_tag_bits(i)      <= lu_check_tag_word(i);
    end generate Assign_Tag;
    
    -- Static ID when no serial.
    lu_fetch_set_id             <= '0';
    lu_fetch_same_set_as_check  <= '0';
    lu_fetch_same_set_as_mem    <= '0';
    lu_mem_same_set_as_check    <= '0';
  
    -- There is only one serial set.
    lu_fetch_last_set           <= '1';
    lu_check_lru_ser_set_match  <= '1';
    
    -- Tag address part with no serial bits.
    lu_fetch_tag_addr           <= lu_fetch_info.Addr(C_ADDR_LINE_POS);
    
    -- Mark which set is selected by address for forcing.
    lu_fetch_force_ser_hit      <= '1';
    lu_fetch_force_par_set      <= to_integer(unsigned(lu_fetch_info.Addr(C_ADDR_PAR_SET_POS)));
    
    -- Conflict address is same as Check because al sets are available.
    lookup_conflict_addr        <= lu_check_tag_addr;
      
    -- Complete set (parallel only).
    lookup_tag_assoc_set        <= std_logic_vector(to_unsigned(lookup_hit_par_set, C_SET_BITS));
    lru_tag_assoc_par_set       <= to_integer(unsigned(lru_tag_assoc_set(C_PARALLEL_SET_BIT_POS)));
    
    -- Always multiple parallel sets.
    lu_check_par_set            <= lookup_hit_par_set;
    lu_check_lru_par_set        <= to_integer(unsigned(lru_check_next_set(C_PARALLEL_SET_BIT_POS)));
    lookup_new_tag_assoc_par_set<= to_integer(unsigned(lookup_new_tag_assoc_set(C_PARALLEL_SET_BIT_POS)));
    
  end generate No_Serial_Assoc;
  
  -- Data address part.
  lu_mem_data_addr        <= lu_mem_tag_addr   & lookup_word_offset(C_ADDR_WORD_POS);
  lu_check_data_addr      <= lu_check_tag_addr & lookup_word_offset(C_ADDR_WORD_POS);
  
  
  -----------------------------------------------------------------------------
  -- Lookup Pipeline Stage: Fetch
  -- 
  -- Move transaction information to Memory stage when pipe is able to move.
  -- 
  -- Also maintain the Locked Write Hit bypass signals.
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall, there is a bubble to fill or previous next stage is flushed.
  -- Start with one padding to keep latch-as-logic in separate slices.
--  lu_fetch_piperun  <= ( lu_mem_piperun_i or lu_mem_flush_pipe or not lu_mem_valid ) and not lu_fetch_stall;
  LU_Fetch_PR_And_Inst1: carry_and 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_piperun_i,
      A         => '1',
      Carry_OUT => lu_fetch_piperun_pre3
    );
  LU_Fetch_PR_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_fetch_piperun_pre3,
      A         => lu_mem_flush_pipe,
      Carry_OUT => lu_fetch_piperun_pre2
    );
  LU_Fetch_PR_Or_Inst2: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_fetch_piperun_pre2,
      A_N       => lu_mem_valid,
      Carry_OUT => lu_fetch_piperun_pre1
    );
  LU_Fetch_PR_And_Inst2: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_fetch_piperun_pre1,
      A_N       => lu_fetch_stall,
      Carry_OUT => lu_fetch_piperun
    );
  
  -- Stall Fetch stage if not ready.
  lu_fetch_stall    <= lookup_tag_conflict                                        or 
                       ( update_tag_conflict and not lu_fetch_flush_pipe )        or 
                       ( lu_fetch_protect_conflict and not lu_fetch_flush_pipe )  or 
                       lookup_restart_mem;
  
  -- New access without conflicting stall.
  -- Locked Write enables Memory through other means.
  lu_fetch_valid    <= ( access_valid and not lu_fetch_stall );
  
  -- Propagate to next stage when possible.
  Pipeline_Stage_Mem_Valid : process (ACLK) is
  begin  -- process Pipeline_Stage_Mem_Valid
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_mem_valid    <= '0';
      else
        -- Forward Fetch to Memory if pipe can move, clear for move without new.
        if( lu_fetch_piperun = '1' ) then
          lu_mem_valid    <= lu_fetch_valid and not lu_fetch_flush_pipe;
        elsif( lu_mem_piperun = '1' ) then
          lu_mem_valid    <= '0';
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Mem_Valid;
  
  Pipeline_Stage_Mem : process (ACLK) is
  begin  -- process Pipeline_Stage_Mem
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_mem_info           <= C_NULL_ACCESS;
        lu_mem_set_id         <= '0';
        lu_mem_last_set       <= '1';
        lu_mem_tag_addr       <= (others=>'0');
        lu_mem_use_bits       <= (others=>'0');
        lu_mem_stp_bits       <= (others=>'0');
        lu_mem_single_beat    <= '0';
        lu_mem_info_id        <= (others=>'0');
        lu_mem_force_ser_hit  <= '0';
        lu_mem_force_par_set  <= 0;
        lu_mem_write_alloc    <= '0';
        
      else
        -- Forward Fetch to Memory if pipe can move, clear for move without new.
        if( lu_fetch_piperun = '1' ) then
          lu_mem_info           <= lu_fetch_info;
          lu_mem_set_id         <= lu_fetch_set_id;
          lu_mem_last_set       <= lu_fetch_last_set;
          lu_mem_tag_addr       <= lu_fetch_tag_addr;
          lu_mem_use_bits       <= lu_fetch_use_bits;
          lu_mem_stp_bits       <= lu_fetch_stp_bits;
          if( to_integer(unsigned(lu_fetch_info.Len(C_INT_LEN_POS))) = 0 ) then
            lu_mem_single_beat    <= '1';
          else
            lu_mem_single_beat    <= '0';
          end if;
          lu_mem_info_id        <= lu_fetch_info_id;
          lu_mem_force_ser_hit  <= lu_fetch_force_ser_hit;
          lu_mem_force_par_set  <= lu_fetch_force_par_set;
          lu_mem_write_alloc    <= lu_fetch_info.Wr and lu_fetch_info.Allocate;
          
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Mem;
  
  -- Assign Locked Write Hit signal for this stage.
  lu_fetch_protect_conflict <= lookup_protect_conflict;
  
  -- Propagate to next stage when possible.
  Pipeline_Stage_Mem_Tag : process (ACLK) is
  begin  -- process Pipeline_Stage_Mem_Tag
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_mem_protect_conflict     <= '0';
        lu_mem_protect_conflict_d1  <= '0';
      else
        lu_mem_protect_conflict     <= lu_fetch_protect_conflict;
        lu_mem_protect_conflict_d1  <= lu_mem_protect_conflict;
      end if;
    end if;
  end process Pipeline_Stage_Mem_Tag;
  
  -- Block flush signal when stage has been flushed.
  Mem_Flush_Control : process (ACLK) is
  begin  -- process Mem_Flush_Control
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_mem_flush_done <= '0';
      else
        if( lu_check_piperun = '1' ) then
          lu_mem_flush_done <= '0';
        elsif( lu_fetch_piperun = '1' ) then
          lu_mem_flush_done <= lu_mem_flush_pipe;
        end if;
      end if;
    end if;
  end process Mem_Flush_Control;
  
  -- Flush Fetch after hit if the same set is still searched.
  lu_fetch_flush_pipe <= lookup_flush_pipe and not lu_fetch_flush_done and lu_fetch_same_set_as_check;
  
  
  -----------------------------------------------------------------------------
  -- Lookup Pipeline Stage: Memory
  -- 
  -- Move transaction information to Check when pipe is able to move, this
  -- includes the ordinary information and any predeoceded Hit/Miss results.
  -- 
  -- Detemine if the transaction in will be in Normal or Late state when it 
  -- reaches Check.
  -- 
  -- There is a bypass mode for the Hit/Miss predecoding to be able to detect
  -- when a Locked Write Hit has been resolved, i.e. when the Read Miss that
  -- caused the Lock has been stored in the Cache.
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  lu_mem_piperun  <= ( lu_check_piperun_i or lu_check_completed or lu_check_done or not lu_check_valid ) and 
--                     not lu_mem_stall;
  LU_Mem_PR_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_check_piperun_i,
      A         => lu_check_completed,
      Carry_OUT => lu_mem_piperun_pre3
    );
  LU_Mem_PR_Or_Inst2: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_piperun_pre3,
      A         => lu_check_done,
      Carry_OUT => lu_mem_piperun_pre2
    );
  LU_Mem_PR_Or_Inst3: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_piperun_pre2,
      A_N       => lu_check_valid,
      Carry_OUT => lu_mem_piperun_pre1
    );
  LU_Mem_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_piperun_pre1,
      A_N       => lu_mem_stall,
      Carry_OUT => lu_mem_piperun
    );
  
  -- Generate new control set for write conflict handling.
--  lu_mem_piperun_or_conflict <= lu_mem_piperun or lu_mem_protect_conflict;
  LU_Mem_PR_Latch_Inst1: carry_latch_or
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => lu_mem_piperun,
      A         => lu_mem_protect_conflict,
      O         => lu_mem_piperun_or_conflict,
      Carry_OUT => lu_mem_piperun_i
    );
  
  -- Stall Memory stage if not ready.
  lu_mem_stall    <= lookup_restart_mem or 
                     ( lu_mem_valid and not lu_mem_info.Wr and
                       ( read_info_almost_full(lu_mem_read_port) or 
                         read_info_full(lu_mem_read_port) ) );
  
  -- Evaluate if next valid will be late or not.
  lookup_next_data_late <= lu_mem_valid and not lu_mem_flush_pipe and 
                           ( lu_mem_info.Wr or 
                             ( not lud_step_want_mem_step and not lud_mem_waiting_for_pipe ) or
                             (     lud_step_want_mem_step and not lud_addr_piperun         ) );
  
  -- Propagate status to next stage when possible.
  Pipeline_Stage_Check_Valid : process (lu_mem_piperun, lu_mem_valid, lu_mem_flush_pipe, 
                                        lu_check_piperun, lu_check_done, lu_check_valid) is
  begin  -- process Pipeline_Stage_Check_Valid
    -- Forward Mem to Check if pipe can move, clear for move without new.
    if( lu_mem_piperun = '1' ) then
      lu_check_valid_cmb  <= lu_mem_valid and not lu_mem_flush_pipe;
    elsif( lu_check_piperun = '1' or lu_check_done = '1' ) then
      lu_check_valid_cmb  <= '0';
    else
      lu_check_valid_cmb  <= lu_check_valid;
    end if;
  end process Pipeline_Stage_Check_Valid;
  
  Chk_Valid_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => lu_check_valid_cmb,
      Q         => lu_check_valid
    );
  
  Pipeline_Stage_Check : process (ACLK) is
  begin  -- process Pipeline_Stage_Check
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_check_info           <= C_NULL_ACCESS;
        lu_check_set_id         <= '0';
        lu_check_last_set       <= '1';
        lu_check_tag_addr       <= (others=>'0');
        lu_check_use_bits       <= (others=>'0');
        lu_check_stp_bits       <= (others=>'0');
        lu_check_single_beat    <= '0';
        lu_check_multi_beat     <= '1';
        lu_check_port_one_hot   <= (others=>'0');
        lu_check_allow_write    <= '0';
        lu_check_write_alloc    <= '0';
        
      elsif( lu_mem_piperun = '1' ) then
        lu_check_info           <= lu_mem_info;
        lu_check_set_id         <= lu_mem_set_id;
        lu_check_last_set       <= lu_mem_last_set;
        lu_check_tag_addr       <= lu_mem_tag_addr;
        lu_check_use_bits       <= lu_mem_use_bits;
        lu_check_stp_bits       <= lu_mem_stp_bits;
        lu_check_single_beat    <= lu_mem_single_beat;
        lu_check_multi_beat     <= not lu_mem_single_beat;
        lu_check_port_one_hot   <= std_logic_vector(to_unsigned(2 ** lu_mem_read_port, C_NUM_PORTS));
        lu_check_allow_write    <= ( not lu_mem_info.Exclusive ) or
                                   ( lu_mem_info.Exclusive and lu_mem_ex_mon_hit ) ;
        lu_check_write_alloc    <= lu_mem_write_alloc;
        
      end if;
    end if;
  end process Pipeline_Stage_Check;
  
  lu_mem_piperun_vec    <= (0 downto 0=>lu_mem_piperun);
  lu_mem_prot_conf_edge <= lu_mem_protect_conflict and not lu_mem_protect_conflict_d1;
  
  Late_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '1',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => lu_mem_prot_conf_edge,
      CE        => lu_mem_piperun_vec,
      D         => lookup_next_data_late,
      Q         => lookup_access_data_late
    );
  
  -- Read Hit done handling (information sent but pipe stage still active).
  Pipeline_Check_Done_Handle : process (ACLK) is
  begin  -- process Pipeline_Check_Done_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_check_read_info_done <= '0';
      else
        if( lu_mem_piperun = '1' ) then
          lu_check_read_info_done <= '0';
          
        elsif( lookup_read_data_new_i = '1' ) then
          lu_check_read_info_done <= '1';
          
        end if;
      end if;
    end if;
  end process Pipeline_Check_Done_Handle;
  
  -- Modify TAG inforamation if required.
  lu_mem_piperun_or_conf_vec  <= (0 downto 0=>lu_mem_piperun_or_conflict);
  par_mem_cur_force_hit_vec   <= (others => par_mem_cur_force_hit);
  par_check_reused_bits_cmb   <= par_mem_reused_bits and not par_mem_cur_force_hit_vec;
  par_check_dirty_bits_cmb    <= par_mem_dirty_bits  and not par_mem_cur_force_hit_vec;
  par_check_locked_bits_cmb   <= par_mem_locked_bits and not par_mem_cur_force_hit_vec;
  
  Par_Reuse_Inst: reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (C_PARALLEL_SET_POS=>'0'),
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => lu_mem_piperun_or_conf_vec,
      D         => par_check_reused_bits_cmb,
      Q         => par_check_reused_bits
    );
  Par_Dirty_Inst: reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (C_PARALLEL_SET_POS=>'0'),
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => lu_mem_piperun_or_conf_vec,
      D         => par_check_dirty_bits_cmb,
      Q         => par_check_dirty_bits
    );
  Par_Locked_Inst: reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => (C_PARALLEL_SET_POS=>'0'),
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => lu_mem_piperun_or_conf_vec,
      D         => par_check_locked_bits_cmb,
      Q         => par_check_locked_bits
    );
  
  -- Move Tag information to next stage.
  Pipeline_Stage_Check_Tag : process (ACLK) is
  begin  -- process Pipeline_Stage_Check_Tag
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        par_check_valid_tag           <= (others=>'0');
        par_check_tag_hit             <= (others=>'0');
        par_check_tag_hit_copy_pc     <= (others=>'0');
        par_check_tag_hit_copy_md     <= (others=>'0');
        par_check_tag_hit_copy_wm     <= (others=>'0');
        par_check_tag_hit_copy_ds     <= (others=>'0');
        par_check_tag_hit_copy_lb     <= (others=>'0');
        par_check_tag_hit_copy_rs     <= (others=>'0');
        par_check_tag_miss            <= (others=>'0');
        par_check_locked_hit          <= (others=>'0');
        par_check_locked_hit_copy_lb  <= (others=>'0');
        par_check_locked_write        <= (others=>'0');
        par_check_protected           <= (others=>'0');
        par_check_valid_bits          <= (others=>'0');
        lu_check_tag_word             <= (others=>(others=>'0'));
      elsif( lu_mem_piperun_or_conflict = '1' ) then
        par_check_valid_tag           <= par_mem_valid_tag;
        par_check_tag_hit             <= par_mem_tag_hit;
        par_check_tag_hit_copy_pc     <= par_mem_tag_hit_copy_pc;
        par_check_tag_hit_copy_md     <= par_mem_tag_hit_copy_md;
        par_check_tag_hit_copy_wm     <= par_mem_tag_hit_copy_wm;
        par_check_tag_hit_copy_ds     <= par_mem_tag_hit_copy_ds;
        par_check_tag_hit_copy_lb     <= par_mem_tag_hit_copy_lb;
        par_check_tag_hit_copy_rs     <= par_mem_tag_hit_copy_rs;
        par_check_tag_miss            <= par_mem_tag_miss;
        par_check_locked_hit          <= par_mem_locked_hit;
        par_check_locked_hit_copy_lb  <= par_mem_locked_hit_copy_lb;
        par_check_locked_write        <= par_mem_locked_write;
        par_check_protected           <= par_mem_protected;
        par_check_valid_bits          <= par_mem_valid_bits;
        lu_check_tag_word             <= par_mem_tag_word;
      end if;
    end if;
  end process Pipeline_Stage_Check_Tag;
  
  Pipeline_Stage_Check_Protected : process (ACLK) is
  begin  -- process Pipeline_Stage_Check_Protected
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_check_protected_par_set  <= 0;
      elsif( lookup_protect_conflict = '1' ) then
        if( lookup_raw_hit = '1' ) then
          lu_check_protected_par_set  <= lu_check_par_set;
        else
          lu_check_protected_par_set  <= lookup_new_tag_assoc_par_set;
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Check_Protected;
  
  -- Automatically proceed to next serial set even if Update is stalled.
  lu_check_miss_next_ser  <= lu_check_valid and not lu_check_last_set and not lookup_hit and 
                             not lookup_protect_conflict;
  
  -- Flush Mem after hit if the same set is still searched.
  lu_mem_flush_pipe       <= lookup_flush_pipe and not lu_mem_flush_done and lu_mem_same_set_as_check;
  
  -- Port for current transaction.
  lu_mem_read_port        <= get_port_num(lu_mem_info.Port_Num, C_NUM_PORTS);
  
  
  -----------------------------------------------------------------------------
  -- Lookup Pipeline Stage: Check
  -- 
  -- During this pipeline stage will Read Hit and Write Hit data use the 
  -- selected set.
  -- 
  -- When all reading and writing to the Data memory on the Lookup port has 
  -- been completed will the transaction be forwarded to Update for any 
  -- scheduled Tag manipulation.
  -- 
  -- Read and Write Misses are also forwarded to the data related part of 
  -- Update to get the missing data from external memory or update the external 
  -- memory with the new data.
  -- 
  -- This Pipeline stage can be in two states: Normal or Late (delayed).
  --  * Normal is when the pipe is able to perform speculative read, i.e. first
  --    address phase in Mem stage.
  --  * Late is when all the address phases of the Data transactions are in 
  --    the Check stage (default for Write and read following Write without 
  --    bubble).
  -- 
  -- Some data structures needs to be delayed in order to support the Late 
  -- phase for Read.
  -- 
  -- A Locked Write Hit will stall Pipe and restart the next scheduled
  -- transaction.
  -- 
  -- Write miss information must be updated directly from Check Pipeline Stage
  -- or a conflicting write from the same port can slip pass.
  -- A Read Miss Dirty is also written to the Write Miss Queue in order to 
  -- synchronize eviction in the Write queues.
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  lu_check_piperun          <= ( update_piperun or not update_valid_i ) and not lu_check_stall;
  LU_Check_PR_Or_Inst1: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun,
      A_N       => update_valid_i,
      Carry_OUT => lu_check_piperun_pre1
    );
  LU_Check_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lu_check_piperun_pre1,
      A_N       => lu_check_stall,
      Carry_OUT => lu_check_piperun
    );
  
  -- Stall Check when 
  -- For timing purposes has part of the hit stall moved to data stall => only conflict remains.
  -- (they are still together in the original stall signal)
  lu_check_stall            <= lookup_data_stall or lookup_protect_conflict or lookup_data_miss_stall;
  
  --  Determine if this iteration is complete in Check.
  lu_check_completed        <= lu_check_miss_next_ser;
  lu_check_done             <= not lu_check_need_move2update and not lu_check_stall;
  
  -- Detemine if transactions needs to be moved to update.
  lu_check_need_move2update <= ( lookup_write_hit or ( lookup_write_hit and not lu_check_early_bresp ) or 
                                 lookup_write_miss or lookup_true_locked_read or lookup_read_miss or
                                 lookup_evict_hit ) and 
                                 not ( lu_check_info.KillHit and lu_check_info.SnoopResponse and 
                                       not lu_check_info.Evict);
  
  -- Determine if the Alocate flag shall be kept when moving to Update.
  lu_check_keep_allocate    <= lu_check_info.Allocate and not lookup_true_locked_read and not lookup_block_reuse;
  
  -- Determine if data shall be evicted from line.
  lu_check_possible_evict   <= ( lu_check_info.Evict or lu_check_keep_allocate ) and 
                               not lu_check_info.Ignore_Data;
  
  -- Determine if there has been an early BRESP.
  lu_check_early_bresp      <= lu_check_info.Allocate or lu_check_info.Bufferable;
  
  -- Propagate status to next stage when possible.
  Pipeline_Stage_Update_Valid : process (lu_check_piperun, update_piperun, lu_check_need_move2update, lu_check_info, 
                                         lu_check_possible_evict, lu_check_keep_allocate, lu_check_early_bresp, 
                                         lookup_read_miss, lookup_read_miss_dirty, 
                                         lookup_write_miss, lookup_write_miss_dirty, 
                                         lookup_write_hit, lookup_first_write_hit, 
                                         lookup_true_locked_read, lookup_miss, 
                                         update_valid_i, update_need_bs_i, update_need_ar_i, update_need_aw_i, 
                                         update_need_evict_i, update_need_tag_write_i) is
  begin  -- process Pipeline_Stage_Update_Valid
    -- Forward Check to Update if pipe can move, clear for move without new.
    if( lu_check_piperun = '1' ) then
      update_valid_cmb          <= lu_check_need_move2update;
      
      update_need_bs_cmb        <= lu_check_need_move2update and 
                               ( ( lookup_read_miss_dirty  and     lu_check_possible_evict ) or 
                                 ( lookup_write_miss       and not lu_check_keep_allocate  ) or
                                 ( lookup_write_miss_dirty and     lu_check_keep_allocate  ) or 
                                 ( lookup_write_hit        and not lu_check_early_bresp    ) );
      update_need_ar_cmb        <= lu_check_need_move2update and 
                               ( ( lookup_read_miss ) or 
                                 ( lookup_true_locked_read ) or
                                 ( lookup_write_miss and lu_check_keep_allocate ) );
      update_need_aw_cmb        <= lu_check_need_move2update and 
                               ( ( lookup_read_miss_dirty  and     lu_check_possible_evict ) or 
                                 ( lookup_write_miss       and not lu_check_keep_allocate  ) or
                                 ( lookup_write_miss_dirty and     lu_check_keep_allocate  ) or 
                                 ( lookup_write_hit        and not lu_check_early_bresp    ) );
      update_need_evict_cmb     <= lu_check_need_move2update and 
                               ( ( lookup_read_miss_dirty  and     lu_check_possible_evict ) or
                                 ( lookup_write_miss_dirty and     lu_check_keep_allocate  ) or 
                                 ( lookup_write_hit        and not lu_check_early_bresp    ) );
      update_need_tag_write_cmb <= lu_check_need_move2update and 
                               ( ( lu_check_info.Evict ) or 
                                 ( lookup_first_write_hit ) or 
                                 ( lookup_write_hit and not lu_check_early_bresp ) or
                                 ( lookup_miss and lu_check_keep_allocate ) );
      
    elsif( update_piperun = '1' ) then
      update_valid_cmb          <= '0';
      update_need_bs_cmb        <= '0';
      update_need_ar_cmb        <= '0';
      update_need_aw_cmb        <= '0';
      update_need_evict_cmb     <= '0';
      update_need_tag_write_cmb <= '0';
      
    else
      update_valid_cmb          <= update_valid_i;
      update_need_bs_cmb        <= update_need_bs_i;
      update_need_ar_cmb        <= update_need_ar_i;
      update_need_aw_cmb        <= update_need_aw_i;
      update_need_evict_cmb     <= update_need_evict_i;
      update_need_tag_write_cmb <= update_need_tag_write_i;
      
    end if;
  end process Pipeline_Stage_Update_Valid;
  
  Ud_Valid_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_valid_cmb,
      Q         => update_valid_i
    );
    
  BS_Need_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_need_bs_cmb,
      Q         => update_need_bs_i
    );
    
  AR_Need_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_need_ar_cmb,
      Q         => update_need_ar_i
    );
    
  AW_Need_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_need_aw_cmb,
      Q         => update_need_aw_i
    );
    
  E_Need_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_need_evict_cmb,
      Q         => update_need_evict_i
    );
    
  TAG_Need_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => update_need_tag_write_cmb,
      Q         => update_need_tag_write_i
    );
  
  Pipeline_Stage_Update : process (ACLK) is
  begin  -- process Pipeline_Stage_Update
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        update_set                <= (others=>'0');
        update_info               <= C_NULL_ACCESS;
        update_use_bits           <= (others=>'0');
        update_stp_bits           <= (others=>'0');
        update_hit                <= '0';
        update_miss               <= '0';
        update_read_hit           <= '0';
        update_read_miss          <= '0';
        update_read_miss_dirty    <= '0';
        update_write_hit          <= '0';
        update_write_miss         <= '0';
        update_write_miss_dirty   <= '0';
        update_locked_write_hit   <= '0';
        update_locked_read_hit    <= '0';
        update_first_write_hit    <= '0';
        update_evict_hit          <= '0';
        update_exclusive_hit      <= '0';
        update_early_bresp        <= '0';
        update_reused_tag         <= '0';
        
      else
        -- Forward Check to Update if pipe can move, clear for move without new.
        if( lu_check_piperun = '1' ) then
          update_set                <= lru_tag_assoc_set;
          update_info               <= lu_check_info;
          if( ( lookup_true_locked_read = '1' ) or ( lookup_block_reuse = '1' ) ) then
            -- A Locked read hit is not allowed to update the cache because data is already on the way due to 
            -- earlier transactions.
            -- Or, cache line is being reused for another address, it is not allowed to allocate this line to other
            -- addresses until this has been solved (otherwise it might create a false temporary ownership
            -- if reused back to an earlier address, i.e. A-B-A miss scenario)
            update_info.Allocate      <= '0';
          end if;
          if( ( lookup_write_hit and not lu_check_early_bresp ) = '1' ) then
            -- Set that this is a transaction that write back data (because it need external bresp). 
            -- If the allocate bit is asserted will the line be evicted instead. 
            update_info.Evict         <= '1';
          end if;
          update_use_bits           <= lu_check_use_bits;
          update_stp_bits           <= lu_check_stp_bits;
          update_hit                <= lookup_hit;
          update_miss               <= lookup_miss;
          update_read_hit           <= lookup_read_hit;
          update_read_miss          <= lookup_read_miss;
          update_read_miss_dirty    <= lookup_read_miss_dirty;
          update_write_hit          <= lookup_write_hit;
          update_write_miss         <= lookup_write_miss;
          update_write_miss_dirty   <= lookup_write_miss_dirty;
          update_locked_write_hit   <= lookup_locked_write_hit;
          update_locked_read_hit    <= lookup_true_locked_read;
          update_first_write_hit    <= lookup_first_write_hit;
          update_evict_hit          <= lookup_evict_hit;
          update_exclusive_hit      <= lu_check_info.Exclusive and lu_check_allow_write;
          update_early_bresp        <= lu_check_early_bresp;
          if( ( ( lookup_read_miss = '1' ) or ( lookup_write_miss = '1' ) ) and 
              ( lookup_all_locked_bits(lu_check_old_tag_idx) = '1' ) and
              ( lookup_all_tag_bits(lu_check_old_tag_idx)(C_TAG_ADDR_POS) /= lu_check_info.Addr(C_ADDR_TAG_POS) ) ) or
              ( lookup_all_tag_bits(lu_check_old_tag_idx)(C_TAG_DSID_POS) /= lu_check_info.DSid)

               then
            -- Reusning the cache line to another address will mark it as reused, this is to prevent fake ownership
            -- in the A-B-A reuse scenario.
            update_reused_tag         <= lu_check_info.Allocate;
          else
            update_reused_tag         <= '0';
          end if;
          
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Update;
  
  -- Propagate that the LRU has been updated.
  Update_LRU_Refresh_Handle : process (ACLK) is
  begin  -- process Update_LRU_Refresh_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        update_refreshed_lru  <= '0';
        update_all_tags       <= (others=>'0');
        
      else
        update_refreshed_lru  <= lru_check_use_lru_i;
        for I in 0 to C_NUM_SETS - 1 loop
          update_all_tags((I+1) * C_TAG_SIZE - 1 downto I * C_TAG_SIZE) 
                                <= lookup_all_tag_bits(I);
        end loop;
        
      end if;
    end if;
  end process Update_LRU_Refresh_Handle;
  
  -- Detect that Check completed but was unable to move because Update was stalling.
  Pipeline_Check_Complete_Handle : process (ACLK) is
  begin  -- process Pipeline_Check_Complete_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_check_wait_for_update  <= '0';
        
      else
        if( lu_check_piperun = '1' ) then
          lu_check_wait_for_update  <= '0';
          
        elsif( ( lu_check_valid and lu_check_need_move2update and 
                 not update_piperun and not lu_check_stall ) = '1' ) then
          lu_check_wait_for_update  <= '1';
          
        end if;
      end if;
    end if;
  end process Pipeline_Check_Complete_Handle;
  
  -- .
  Pipeline_Check_Push_Handle : process (ACLK) is
  begin  -- process Pipeline_Check_Push_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          lu_check_wr_already_pushed  <= '0';
        
      else
        if( lu_check_piperun = '1' ) then
          lu_check_wr_already_pushed  <= '0';
          
        elsif( lookup_push_write_miss_i = '1' ) then
          lu_check_wr_already_pushed  <= '1';
          
        end if;
      end if;
    end if;
  end process Pipeline_Check_Push_Handle;
  
  -- Assign output.
  update_valid            <= update_valid_i;
  update_need_bs          <= update_need_bs_i;
  update_need_ar          <= update_need_ar_i;
  update_need_aw          <= update_need_aw_i;
  update_need_evict       <= update_need_evict_i;
  update_need_tag_write   <= update_need_tag_write_i;
  
  -- Get index for old Tag extraction.
  lu_check_old_tag_idx  <= to_integer(unsigned(lookup_tag_assoc_set)) when lookup_first_write_hit = '1' else 
                           to_integer(unsigned(lru_check_next_set));
  
  -- Get old Tag information.
  Pipeline_Stage_Old_Tag_Handle : process (ACLK) is
  begin  -- process Pipeline_Stage_Old_Tag_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        update_old_tag  <= (others=>'0');
      else
        if( lu_check_piperun = '1' ) then
          update_old_tag  <= lookup_all_tag_bits(lu_check_old_tag_idx);
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Old_Tag_Handle;
  
  -- Delay pipe status for late read handling.
  Pipeline_Stage_Check_Delayed : process (ACLK) is
  begin  -- process Pipeline_Stage_Check_Delayed
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lu_check_valid_delayed      <= '0';
        lu_check_info_delayed       <= C_NULL_ACCESS;
        lookup_read_hit_d1          <= '0';
        lookup_locked_read_hit_d1   <= '0';
        lookup_access_data_late_d1  <= '0';
      else
        lu_check_valid_delayed      <= lu_check_valid;
        lu_check_info_delayed       <= lu_check_info;
        lookup_read_hit_d1          <= lookup_read_hit;
        lookup_locked_read_hit_d1   <= lookup_locked_read_hit;
        lookup_access_data_late_d1  <= lookup_access_data_late;
      end if;
    end if;
  end process Pipeline_Stage_Check_Delayed;
  
  -- Make sure Mem is only refresed once.
  Handle_Mem_Restart : process (ACLK) is
  begin  -- process Handle_Mem_Restart
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lookup_restart_mem_done <= '0';
      else
        if( lu_mem_piperun = '1' ) then
          lookup_restart_mem_done <= '0';
        elsif( lookup_restart_mem = '1' ) then
          lookup_restart_mem_done <= '1';
        end if;
      end if;
    end if;
  end process Handle_Mem_Restart;
  
  -- Signal to restart Mem when Locked stall is solved, new tag is clean but earlier stage is still marked.
  lookup_restart_mem      <= lu_mem_protect_conflict and not lookup_protect_conflict and 
                             not lu_mem_flush_pipe and not lookup_restart_mem_done;
  
  -- Flush when there is a hit before last set has been searched.
  lookup_flush_pipe         <= lookup_raw_hit and not lookup_protect_conflict and not lu_check_last_set;
  
  -- Internal write signal to write miss queue.
--  lookup_push_write_miss_i  <= ( lookup_write_miss or lookup_miss_dirty or 
--                                 ( lookup_write_hit and not lu_check_early_bresp ) ) and
--                               not lookup_protect_conflict  and
--                               not lu_check_wait_for_update;
  
  wm_sel  <= lu_check_info.Wr and lu_check_last_set and not reduce_or(par_check_tag_hit_copy_wm);
  LU_WM_Or_Inst1: carry_or
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_miss_dirty,
      A         => wm_sel,
      Carry_OUT => lookup_md_or_wm
    );
  
  whne_sel  <= lu_check_info.Wr and reduce_or(par_check_tag_hit_copy_wm) and not lu_check_early_bresp;
  LU_WM_Or_Inst2: carry_or
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_md_or_wm,
      A         => '0',
      Carry_OUT => lookup_md_or_wm_or_whne
    );
  
  LU_WM_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_md_or_wm_or_whne,
      A         => lu_check_valid,
      Carry_OUT => lookup_md_wm_whne_valid
    );
  LU_WM_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_md_wm_whne_valid,
      A_N       => lu_check_wait_for_update,
      Carry_OUT => lookup_push_write_miss_pre
    );
  lookup_push_write_miss_i  <= ( lookup_push_write_miss_pre or 
                                 ( lu_check_valid and whne_sel and not lu_check_wait_for_update and 
                                   not lookup_data_stall) ) and 
                               not lookup_protect_conflict and not update_write_miss_full and 
                               not lu_check_wr_already_pushed;
  
  -- Information to write miss queue.
  lookup_push_write_miss    <= lookup_push_write_miss_i;
  lookup_wm_allocate_i      <= lu_check_info.Wr and lu_check_info.Allocate;
  lookup_wm_allocate        <= lookup_wm_allocate_i;
  lookup_wm_evict_i         <= lookup_miss_dirty or ( lookup_write_hit and not lu_check_early_bresp );
  lookup_wm_evict           <= lookup_wm_evict_i;
  lookup_wm_will_use        <= not ( lookup_write_hit and not lu_check_early_bresp ) and
                               not ( lookup_evict_hit );
  lookup_wm_info            <= lu_check_info;
  lookup_wm_use_bits        <= lu_check_use_bits;
  lookup_wm_stp_bits        <= lu_check_stp_bits;
  lookup_wm_allow_write     <= lu_check_allow_write;
  
  -- Port for current transaction.
  lu_check_read_port        <= get_port_num(lu_check_info.Port_Num, C_NUM_PORTS);
  
  
  -----------------------------------------------------------------------------
  -- Exclusive Monitor
  -----------------------------------------------------------------------------
  
  Exclusive_Monitor : process (ACLK) is
  begin  -- process Exclusive_Monitor
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' or 
          C_ENABLE_EX_MON = 0 ) then      -- synchronous reset (active high)
        lookup_exclusive_monitor  <= (others=>C_NULL_EX_MON);
        
      elsif( lu_mem_piperun = '1' ) then
        if( lu_mem_info.Exclusive = '1' ) then
          if( lu_mem_info.Wr = '0' ) then
            -- Activate monitor for this port.
            lookup_exclusive_monitor(lu_mem_read_port).Valid    <= '1';
            lookup_exclusive_monitor(lu_mem_read_port).ID       <= lu_mem_info_id;
            lookup_exclusive_monitor(lu_mem_read_port).Addr     <= lu_mem_info.Addr(C_ADDR_INTERNAL_POS);
            
          elsif( lu_mem_ex_mon_hit = '1'  ) then
            -- Sequence completed => turn off monitor.
            lookup_exclusive_monitor(lu_mem_read_port).Valid    <= '0';
            
            for I in 0 to C_NUM_PORTS - 1 loop
              if( ( lu_mem_read_port       /=  I  ) and
                  ( lu_mem_ex_mon_match(I)  = '1' ) ) then
                -- Turn off all monitors on other ports that match this address,
                -- since this port was able to complete first.
                lookup_exclusive_monitor(I).Valid    <= '0';
              end if;
            end loop;
            
          end if;
        end if;
      end if;
    end if;
  end process Exclusive_Monitor;
  
  -- Detet match with any port.
  Gen_Port_Mon_Match: for I in 0 to C_NUM_PORTS - 1 generate
  begin
    lu_mem_ex_mon_match(I)  <= lookup_exclusive_monitor(I).Valid when
                                  ( ( C_ENABLE_EX_MON                   = 1                                     ) and
                                    ( lookup_exclusive_monitor(I).Addr  = lu_mem_info.Addr(C_ADDR_INTERNAL_POS) ) ) else
                               '0';
    
  end generate Gen_Port_Mon_Match;
  
  -- Detect if this is a Hit for the current port.
  lu_mem_ex_mon_hit <= lu_mem_ex_mon_match(lu_mem_read_port) when
                          ( ( C_ENABLE_EX_MON                                  = 1                              ) and
                            ( lookup_exclusive_monitor(lu_mem_read_port).ID    = lu_mem_info_id                 ) ) else
                       '0';
  
  
  -----------------------------------------------------------------------------
  -- Read Transaction Properties
  -----------------------------------------------------------------------------
  
  -- Push hit/miss information to queue.
  lookup_read_data_new_i    <= ( ( lookup_read_miss ) or 
                                 ( lookup_read_hit and     lookup_true_locked_read and not lookup_protect_conflict ) or 
                                 ( lookup_read_hit and not lookup_locked_read_hit ) or 
                                 ( lookup_miss     and     lu_check_info.SnoopResponse ) ) and 
                               not lu_check_read_info_done and not lu_check_wait_for_update;
  lookup_read_data_new_vec  <= (others => lookup_read_data_new_i);
  lookup_read_data_new      <= lookup_read_data_new_vec and
                               lu_check_port_one_hot;
  
  lookup_read_data_hit_i    <= lookup_read_hit and not lookup_locked_read_hit;
  lookup_read_data_hit      <= lookup_read_data_hit_i;
  lookup_read_data_snoop    <= lu_check_info.SnoopResponse  when C_ENABLE_COHERENCY /= 0 else
                               '0';
  lookup_read_data_allocate <= lu_check_info.Lx_Allocate    when C_ENABLE_COHERENCY /= 0 else
                               '0';
  
  -- Determine when it is done.
  lookup_read_done_i        <= lookup_read_data_new_i;
  
  -- Assign external signals.
  lookup_read_done_vec      <= (others => lookup_read_done_i);
  lookup_read_done          <= lookup_read_done_vec and 
                               lu_check_port_one_hot;
  
  
  -----------------------------------------------------------------------------
  -- LRU Handling
  -- 
  -- The LRU is updated for almost all accesses, to make sure that it is as
  -- accurate as possible.
  -- The only exceptions are:
  --  Write Miss - Because this passes right through without touching affecting 
  --               the Tag.
  --  Evict      - Because it doesn't use or affect the Cache contents.
  -- 
  -- The LRU is only use for Read Miss with no invalid set.
  -----------------------------------------------------------------------------
  
  -- Pipe control signals.
  lookup_fetch_piperun    <= lu_fetch_piperun;
  lookup_mem_piperun      <= lu_mem_piperun;
    
  -- Peek on current LRU value and let it flow through the pipe.
  lru_fetch_line_addr     <= lu_fetch_tag_addr(C_ADDR_LINE_POS);
  
  -- Update LRU when relevant transaction is moved to update.
  lru_check_use_lru       <= lru_check_use_lru_i;
  
  lu_check_enable_wr_lru  <= ( lu_check_valid and not lu_check_info.KillHit and 
                               ( lookup_hit or ( lookup_read_miss and lu_check_info.Allocate ) ) );
  
  LU_LRU_Latch_Inst1: carry_latch_and
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => lu_check_piperun,
      A         => lu_check_enable_wr_lru,
      O         => lru_check_use_lru_i,
      Carry_OUT => lu_check_piperun_i
    );
  
  lru_check_line_addr   <= lu_check_tag_addr(C_ADDR_LINE_POS);
  
  -- Update with current set for Hit and LRU for Miss.
  lru_check_used_set    <= lru_tag_assoc_set;
  lru_tag_assoc_set     <= lookup_tag_assoc_set      when lookup_raw_hit = '1' else 
                           lookup_new_tag_assoc_set;
  
  -- Detect if there are any invalid lines available.
  lookup_invalid_exist  <= '0' when lookup_all_valid_bits = set_pos_one_vec else '1';
  
  -- Finding the first invalid line.
  process(lookup_all_valid_bits) is
    variable temp : natural range 0 to C_NUM_SETS - 1;
  begin
    temp := 0;
    for I in 0 to C_NUM_SETS - 1 loop
      if lookup_all_valid_bits(I) = '0' then
        temp := I;
        exit;
      end if;
    end loop;
    lookup_first_invalid <= std_logic_vector(to_unsigned(temp, C_SET_BITS));
  end process;
  
  -- Select an invalid if it exist or the one pointer out by the LRU in other cases.
  lookup_new_tag_assoc_set  <= lookup_first_invalid when ( lookup_invalid_exist ) = '1' else 
                               lru_check_next_set;
  
  
  -----------------------------------------------------------------------------
  -- Stall detection
  -- 
  -- Detect if a Write Hit has currently ongoing/queued Write Miss, in that 
  -- case must the write be stalled to prevent popping data prematurely. Or
  -- otherwise corrupting the write data stream.
  -- 
  -- Stall write miss until there is room in the Write Miss queue.
  -----------------------------------------------------------------------------
  
  -- Previous write miss for this port is still working or there is a locked hit situation.
  -- Also includes stalling for protected misses as well.
--  lookup_data_hit_stall   <= lookup_protect_conflict or
--                             ( lookup_write_hit and not lu_check_wait_for_update
--                               update_write_miss_busy(get_port_num(lu_check_info.Port_Num, C_NUM_PORTS)) );

  lu_check_wait_for_update_vec <= (others => lu_check_wait_for_update);
  update_write_miss_true_busy <= update_write_miss_busy and not lu_check_wait_for_update_vec;
  
  LU_DHS_Or_Inst1: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => lookup_protect_conflict,
      No        => lookup_write_port,
      A_Vec     => update_write_miss_true_busy,
      Carry_Out => lookup_data_hit_stall
    );
  
  -- No room for new write miss.
--  lookup_data_miss_stall  <= lookup_push_write_miss_i and update_write_miss_full;
  LU_WMS_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_push_write_miss_pre,
      A         => update_write_miss_full,
      Carry_OUT => lookup_push_wm_stall
    );
  lookup_data_miss_stall  <= lookup_push_wm_stall and not lookup_protect_conflict;
  
  
  -----------------------------------------------------------------------------
  -- TAG Conflict 
  -- 
  -- Detect any address conflict in order to be able to stall Access, and
  -- preventing any BRAM conflicts that could arise.
  -----------------------------------------------------------------------------
  
  -- Detect any Lookup TAG address conflicts with Access.
  -- Unconditional stall because it is not known if they will update the TAG or not.
--  lu_mem_tag_conflict   <= access_valid and lu_mem_valid and not lu_fetch_same_set_as_mem when 
--                              access_info.Addr(C_ADDR_LINE_POS) = lu_mem_info.Addr(C_ADDR_LINE_POS) and
--                              access_info.DSid = lu_mem_info.DSid   else 
--                           '0';

  LU_Mem_TagConf_Compare_Inst1: carry_compare
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_ADDR_LINE_BITS
    )
    port map(
      Carry_In  => '1',
      A_Vec     => access_info.Addr(C_ADDR_LINE_POS),
      B_Vec     => lu_mem_info.Addr(C_ADDR_LINE_POS),
      Carry_Out => lu_mem_match_addr
    );

  lu_mem_tag_check_valid  <= access_valid and lu_mem_valid;

  LU_Mem_TagConf_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_match_addr,
      A         => lu_mem_tag_check_valid,
      Carry_OUT => lu_mem_match_addr_valid
    );
    
  LU_Mem_TagConf_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_mem_match_addr_valid,
      A_N       => lu_fetch_same_set_as_mem,
      Carry_OUT => lu_mem_tag_conflict
    );
    
--  lu_check_tag_conflict <= access_valid and lu_check_valid and not lu_fetch_same_set_as_check when 
--                              access_info.Addr(C_ADDR_LINE_POS) = lu_check_info.Addr(C_ADDR_LINE_POS) and else '0';

  LU_Check_TagConf_Compare_Inst1: carry_compare
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_ADDR_LINE_BITS
    )
    port map(
      Carry_In  => '1',
      A_Vec     => access_info.Addr(C_ADDR_LINE_POS),
      B_Vec     => lu_check_info.Addr(C_ADDR_LINE_POS),
      Carry_Out => lu_check_match_addr
    );
  
  lu_check_tag_check_valid  <= access_valid and lu_check_valid;
  LU_Check_TagConf_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_check_match_addr,
      A         => lu_check_tag_check_valid,
      Carry_OUT => lu_check_match_addr_valid
    );
    
  LU_Check_TagConf_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_check_match_addr_valid,
      A_N       => lu_fetch_same_set_as_check,
      Carry_OUT => lu_check_tag_conflict
    );
  
  lookup_tag_conflict   <= lu_mem_tag_conflict or lu_check_tag_conflict;
  
  -- Provide address to check if there are conflicts with Update
  lookup_new_addr       <= access_info.Addr(C_ADDR_LINE_POS);
  
  -----------------------------------------------------------------------------
  -- Data Offset Counter
  -- 
  -- Access all words that are needed for Read or Write Hit.
  -- 
  -- Read are speculatively accessed during Memory stage if the Pipeline isn't
  -- in late mode (due to earlier Write without buble cycles).
  -- Speculative read has to return to idle state if there is a Miss, this
  -- applies to searching Tags serially.
  -- 
  -- Write are accessed from Check stage because it must be known if it is a 
  -- hit or not.
  -----------------------------------------------------------------------------

  -- Use information from Check stage for: write and delayed read.
  -- Select Use and Step data.
  lookup_use_bits     <= lu_mem_use_bits  when ( lud_step_use_check ) = '0' else 
                         lu_check_use_bits;
  lookup_stp_bits     <= lu_mem_stp_bits  when ( lud_step_use_check ) = '0' else 
                         lu_check_stp_bits;
  lookup_kind         <= lu_mem_info.Kind when ( lud_step_use_check ) = '0' else 
                         lu_check_info.Kind;
  
  -- Select the current word that should be read from lookup port.
  Lookup_Offset_Gen: process (lookup_offset_all_first, lookup_offset_cnt, lud_step_use_check, 
                              lu_mem_info, lu_check_info, lookup_offset_len_cnt,
                              lookup_next_is_last_beat, lu_mem_single_beat, lu_check_single_beat) is
  begin  -- process Lookup_Offset_Gen
    -- Determine base address for this transaction.
    if ( ( lud_step_use_check ) = '0' ) then
      lookup_base_offset    <= lu_mem_info.Addr(C_ADDR_OFFSET_POS);
    else
      lookup_base_offset    <= lu_check_info.Addr(C_ADDR_OFFSET_POS);
    end if;
    
    -- Determine the adress thet is going used this cycle.
    if( lookup_offset_all_first = '0' ) then
      lookup_word_offset  <= lookup_offset_cnt;
      lookup_offset_len   <= lookup_offset_len_cnt;
      lookup_last_beat    <= lookup_next_is_last_beat;
    else
      if ( ( lud_step_use_check ) = '0' ) then
        lookup_word_offset  <= lu_mem_info.Addr(C_ADDR_OFFSET_POS);
        lookup_offset_len   <= lu_mem_info.Len(C_INT_LEN_POS);
        lookup_last_beat    <= lu_mem_single_beat;
      else
        lookup_word_offset  <= lu_check_info.Addr(C_ADDR_OFFSET_POS);
        lookup_offset_len   <= lu_check_info.Len(C_INT_LEN_POS);
        lookup_last_beat    <= lu_check_single_beat;
      end if;
    end if;
  end process Lookup_Offset_Gen;
  
  -- Detect failing speculative read and force first to restart.
  lookup_force_first      <= lu_check_valid and not lu_check_info.Wr and not lookup_read_hit and 
                             not lud_mem_waiting_for_pipe;
  lookup_offset_all_first <= lookup_offset_first or lookup_force_first;
  
  -- Loop through all words in Slave line length.
  Lookup_Offset_First_Handle : process (ACLK) is
  begin  -- process Lookup_Offset_First_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        lookup_offset_first       <= '1';
        
      elsif( ( lud_step_offset = '1' ) and 
             ( ( lookup_locked_read_hit = '0' ) or ( lud_step_use_check = '0' ) ) ) then
        -- Handle first word status. Next is marked as first when last beat is used.
        if( lookup_step_last = '1' ) then
          lookup_offset_first       <= '1';
        else
          lookup_offset_first       <= '0';
        end if;
        
      elsif( ( lookup_locked_read_hit = '1' and lud_mem_waiting_for_pipe = '0' ) or 
             ( lookup_force_first = '1' ) or 
             ( lud_mem_conflict = '1' ) )then
        -- Need to restore speculative read (non late) that ended up being Locked Read Hit.
        lookup_offset_first   <= '1';
        
      end if;
    end if;
  end process Lookup_Offset_First_Handle;
  
  -- Loop through all words in Slave line length.
  Lookup_Offset_Handle : process (ACLK) is
  begin  -- process Lookup_Offset_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        lookup_offset_len_cnt       <= (others => '0');
        lookup_offset_cnt           <= (others => '0');
        lookup_next_is_last_beat    <= '0';
        lu_ds_last_beat_next_last_n <= '1';
        
      elsif( ( lud_step_offset = '1' ) and 
             ( ( lookup_locked_read_hit = '0' ) or ( lud_step_use_check = '0' ) ) ) then
        -- Update remaining length and counter.
        lookup_offset_len_cnt       <= lookup_offset_len_cmb;
        lookup_offset_cnt           <= lookup_offset_cnt_cmb;
        
        -- Update if next is expected to be last.
        if( to_integer(unsigned(lookup_offset_len)) = 1 ) then
          lookup_next_is_last_beat    <= '1';
          lu_ds_last_beat_next_last_n <= '0';
        else
          lookup_next_is_last_beat    <= '0';
          lu_ds_last_beat_next_last_n <= '1';
        end if;
        
      end if;
    end if;
  end process Lookup_Offset_Handle;
  
  -- Last step in burst.
  lookup_step_last      <= lookup_last_beat;
  
  -- Decrease when used.
  lookup_offset_len_cmb <= std_logic_vector(unsigned(lookup_offset_len) - 1);
  
  -- Generate next value.
  Lookup_Offset_Select: process (lookup_word_offset, lookup_use_bits, lookup_stp_bits, 
                                 lookup_base_offset, lookup_kind) is
    variable lookup_offset_cnt_next : ADDR_OFFSET_TYPE;
  begin  -- process Lookup_Offset_Select
    lookup_offset_cnt_next  := std_logic_vector(unsigned(lookup_word_offset) + unsigned(lookup_stp_bits));
    
    for I in lookup_base_offset'range loop
      if( lookup_use_bits(I) = '0' ) and ( lookup_kind = C_KIND_WRAP ) then
        lookup_offset_cnt_cmb(I) <= lookup_base_offset(I);
      else
        lookup_offset_cnt_cmb(I) <= lookup_offset_cnt_next(I);
      end if;
    end loop;
  end process Lookup_Offset_Select;
  
  -- Signal when data offset counter is busy.
--  lookup_data_stall <= ( lookup_hit and not lookup_locked_read_hit and not lu_check_wait_for_update and 
--                         not lookup_step_last ) or
--                       ( lookup_read_hit and not lookup_locked_read_hit and not lu_check_wait_for_update and 
--                         ( read_data_hit_almost_full(lu_check_read_port) or read_data_hit_full(lu_check_read_port) ) ) or 
--                       ( lookup_write_hit and not lu_check_wait_for_update and
--                         not access_data_valid(get_port_num(lu_check_info.Port_Num, C_NUM_PORTS)) );
  lookup_data_stall <= ( lu_ds_last_beat_stall ) or
                       ( lookup_io_data_stall  );
  
  
  -----------------------------------------------------------------------------
  -- Optimized Data Stall:
  -- 
  -- IO Stall with Busy
  -----------------------------------------------------------------------------
  
  
  -- Prepare vectors.
  lu_check_info_wr_vec         <=     (others => lu_check_info.Wr);
  access_data_valid_stall      <=     lu_check_info_wr_vec      and not access_data_valid;
  access_data_conflict_stall   <=     lu_check_info_wr_vec      and     update_write_miss_busy and 
                                  not lu_check_wait_for_update_vec;
  lu_check_info_wr_pspvec      <=     (others => lu_check_info.Wr);
  read_locked_vector           <= not lu_check_info_wr_pspvec   and     par_check_locked_hit;
  
  
--  lu_io_lud_stall_pipe  <= ( ( lud_addr_pipeline_full and read_data_hit_full(lud_reg_port_num) ) and 
--                             ( not lud_mem_completed or lud_mem_keep_single_during_stall ) and 
--                             not lu_check_info.Wr ) or
--                           ( lu_check_valid and lu_check_info.Wr and lud_addr_pipeline_full );
  
  LU_DS_IO_Or_Inst1: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => '0',
      No        => lud_reg_port_num,
      A_Vec     => read_data_hit_full,
      Carry_Out => lu_io_selected_full
    );
  
  lu_io_valid_read  <= ( lud_addr_pipeline_full and 
                         ( not lud_mem_completed or lud_mem_keep_single_during_stall ) and 
                         not lu_check_info.Wr );
  LU_DS_IO_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_io_selected_full,
      A         => lu_io_valid_read,
      Carry_OUT => lu_io_full_block_read
    );
  
  lu_io_write_blocked <= ( lu_check_valid and lu_check_info.Wr and lud_addr_pipeline_full );
  LU_DS_IO_Or_Inst2: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_io_full_block_read,
      A         => lu_io_write_blocked,
      Carry_OUT => lu_io_lud_stall_pipe
    );
  
  LU_DS_IO_Or_Inst3: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => lu_io_lud_stall_pipe,
      No        => lookup_write_port,
      A_Vec     => access_data_valid_stall,
      Carry_Out => lookup_io_stall_carry
    );
  
  LU_DS_IO_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_io_stall_carry,
      A_N       => lu_check_wait_for_update,
      Carry_OUT => lookup_io_stall_carry_no_wait
    );
  
  LU_DS_IO_Or_Inst4: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => lookup_io_stall_carry_no_wait,
      No        => lookup_write_port,
      A_Vec     => access_data_conflict_stall,
      Carry_Out => lookup_io_and_conflict_stall
    );
  
  par_check_tag_hit_all_copy_ds <= reduce_or(par_check_tag_hit_copy_ds);
  LU_DS_IO_And_Inst3: carry_and
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_io_and_conflict_stall,
      A         => par_check_tag_hit_all_copy_ds,
      Carry_OUT => lookup_io_stall_hit_carry
    );
  
  lu_ds_no_last <=  ( not lu_check_info.Wr and lud_mem_speculative_valid and lud_mem_last and 
                      not lookup_access_data_late ) or 
                    lud_mem_already_used; 
  LU_DS_IO_And_Inst4: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_io_stall_hit_carry,
      A_N       => lu_ds_no_last,
      Carry_OUT => lookup_io_stall_hit_carry_no_last
    );
  
  LU_DS_IO_And_Inst5: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_io_stall_hit_carry_no_last,
      A         => lu_check_valid,
      Carry_OUT => lookup_io_stall_pre_valid
    );
  
  LU_DS_IO_And_Inst6: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_io_stall_pre_valid,
      A_N       => lu_check_info.KillHit,
      Carry_OUT => lookup_io_stall_valid
    );
  
  LU_DS_IO_And_Inst7: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 2,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => lookup_io_stall_valid,     -- [in  std_logic]
      A_Vec     => read_locked_vector,        -- [in  std_logic_vector]
      Carry_Out => lookup_io_data_stall       -- [out std_logic]
    );
  
  -----------------------------------------------------------------------------
  -- Optimized Data Stall:
  -- 
  -- Last Beat
  -----------------------------------------------------------------------------
  
  lu_ds_last_beat_rd_locked   <= not lu_check_info_wr_pspvec and par_check_locked_hit_copy_lb;
  
  lu_ds_last_beat_sel_first   <= lookup_offset_first or 
                                 ( lookup_access_data_late and lu_check_valid_delayed and 
                                   not lu_check_info_delayed.wr and not lookup_read_hit_d1 );
  
  LU_DS_LB_And_Inst0: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => '1',
      A         => lu_check_multi_beat,
      Carry_OUT => lu_ds_last_beat_multi_start
    );
  
  LU_DS_LB_And_Inst1: carry_and_di
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_last_beat_multi_start,
      A         => lu_ds_last_beat_sel_first,
      DI        => lu_ds_last_beat_next_last_n,
      Carry_OUT => lu_ds_last_beat
    );
  
  LU_DS_LB_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_last_beat,
      A_N       => lu_check_wait_for_update,
      Carry_OUT => lu_ds_last_beat_no_wait
    );
  
  lu_ds_last_beat_all_tag_hit <= reduce_or(par_check_tag_hit_copy_lb);
  LU_DS_LB_And_Inst3: carry_and
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_last_beat_no_wait,
      A         => lu_ds_last_beat_all_tag_hit,
      Carry_OUT => lu_ds_last_beat_hit
    );
  
  LU_DS_LB_And_Inst4: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_last_beat_hit,
      A         => lu_check_valid,
      Carry_OUT => lu_ds_last_beat_valid_hit
    );
  
  LU_DS_LB_And_Inst5: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_last_beat_valid_hit,
      A_N       => lu_check_info.KillHit,
      Carry_OUT => lu_ds_last_beat_valid
    );
  
  LU_DS_LB_And_Inst6: carry_compare_const
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET,
      C_SIGNALS => 2,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => lu_ds_last_beat_valid,      -- [in  std_logic]
      A_Vec     => lu_ds_last_beat_rd_locked,  -- [in  std_logic_vector]
      Carry_Out => lu_ds_last_beat_stall_pre   -- [out std_logic]
    );
  
--  lu_ds_lb_delayed_restart <= ( ( lud_step_allow_read_step and lud_mem_conflict ) or 
--                                ( lud_step_delayed_restart                      ) ) and 
--                              lud_addr_pipeline_full;
--  LU_DS_LB_Or_Inst0: carry_or
--    generic map(
--      C_TARGET  => C_TARGET
--    )
--    port map(
--      Carry_IN  => lu_ds_last_beat_stall_pre,
--      A         => lu_ds_lb_delayed_restart,
--      Carry_OUT => lu_ds_last_beat_stall
--    );
  -- lud_step_allow_read_step contains conflict signal wich prevents it from 
  -- being used as an input to the carry chain. Must be appended with regular
  -- or to avoid frequency regression.
  -- Create several local partial expressions in order to guide synthesis toward
  -- a bettter implementation.

  lu_ds_last_beat_stall <= lu_ds_last_beat_stall_pre or 
                           lu_ds_lb_delayed_restart_normal or 
                           ( lu_ds_lb_delayed_restart_conflict and not lookup_protect_conflict) ;

  lud_step_allow_read_step_normal <= ( lookup_read_hit and not lookup_true_locked_read and not lud_mem_already_used ) or 
                                     ( lud_step_want_mem_step );
                                     
  lu_ds_lb_delayed_restart_normal <= ( ( lud_step_allow_read_step_normal and lud_mem_conflict ) or 
                                       ( lud_step_delayed_restart                      ) ) and 
                                     lud_addr_pipeline_full;

--  lud_step_allow_read_step_conf   <= ( lookup_read_miss and lu_mem_valid and not lu_mem_info.Wr and lookup_restart_mem );
--  lu_ds_lb_delayed_restart_conflict <= lud_step_allow_read_step_conf and lud_mem_conflict and lud_addr_pipeline_full;

  -- Check for Miss.
  LU_DS_RS_And_Inst1: carry_compare_const
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => '1',                       -- [in  std_logic]
      A_Vec     => par_check_tag_hit_copy_rs, -- [in  std_logic_vector]
      Carry_Out => lu_ds_rs_miss              -- [out std_logic]
    );
  
  -- Check for read miss.
  lu_ds_rs_read_valid <= lu_check_valid and lu_check_last_set and not lu_check_info.Wr and not lu_check_info.KillHit;
  
  LU_DS_RS_And_Inst2: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_rs_miss,
      A         => lu_ds_rs_read_valid,
      Carry_OUT => lu_ds_rs_read_miss
    );
  
  -- Check for Allow Read Step (with no Mem restart).
  lu_ds_rs_new_valid  <= lu_mem_valid and not lu_mem_info.Wr;
  
  LU_DS_RS_And_Inst3: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_rs_read_miss,
      A         => lu_ds_rs_new_valid,
      Carry_OUT => lu_ds_rs_new_read_no_rs
    );

  -- Check for Delayed Restart (with no Mem restart).
  lu_ds_rs_valid_restart  <= lud_mem_conflict and lud_addr_pipeline_full;

  LU_DS_RS_And_Inst4: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_rs_new_read_no_rs,
      A         => lu_ds_rs_valid_restart,
      Carry_OUT => lu_ds_rs_del_restart_no_rs
    );

  -- Apply Mem restart qulifier.
  -- lookup_restart_mem      <= lu_mem_protect_conflict and not lookup_protect_conflict and 
  --                            not lu_mem_flush_pipe and not lookup_restart_mem_done;

  lu_ds_rs_valid_mem_restart  <= lu_mem_protect_conflict and not lu_mem_flush_pipe and not lookup_restart_mem_done;

  LU_DS_RS_And_Inst5: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lu_ds_rs_del_restart_no_rs,
      A         => lu_ds_rs_valid_mem_restart,
      Carry_OUT => lu_ds_lb_delayed_restart_conflict
    );

  
  -----------------------------------------------------------------------------
  -- Control Lookup TAG
  -- 
  -- Generate normal Fetch or Locked Write bypass Tag address that shall be
  -- looked up.
  -----------------------------------------------------------------------------
  
  lookup_tag_addr       <= lookup_tag_addr_i;
  lookup_tag_addr_i     <= lookup_conflict_addr when ( lu_fetch_protect_conflict = '1' ) else 
                           lu_mem_tag_addr      when ( lookup_restart_mem        = '1' ) else 
                           lu_fetch_tag_addr;
  lookup_tag_en         <= lookup_tag_en_i;
  
--  lookup_tag_en_i       <= lu_fetch_piperun or lu_fetch_protect_conflict or lookup_restart_mem;
  lu_fetch_restart_or_lck_wr_conf  <= lu_fetch_protect_conflict or lookup_restart_mem;
  LU_Tag_En_Latch_Inst1: carry_latch_or
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => lu_fetch_piperun,
      A         => lu_fetch_restart_or_lck_wr_conf,
      O         => lookup_tag_en_i,
      Carry_OUT => lu_fetch_piperun_i
    );
  
  lookup_tag_we         <= (others=>'0');
  lookup_tag_new_word   <= (others=>'0');

  
  -----------------------------------------------------------------------------
  -- Control Lookup DATA
  -- 
  -- Control the Lookup ports of Data memory for all parallel set, i.e. Read
  -- and Write to the set that has the Hit/Miss.
  -- 
  -- The Data Line and Set addresses is not the same as the Tag Line and Set 
  -- addresses because the Data Memory is accessed in different pipe stages
  -- (Mem & Check) compared to the Tag Memory (Fetch).
  -- 
  -- Read Sets has to be activated early if the pipe is not in delayed read 
  -- mode. 
  -- 
  -- Write has to be delayed until any Lock has been resolved (to avoid
  -- corrupting the BRAM contents due to multiple write).
  -----------------------------------------------------------------------------
  
  lookup_data_sel_check_addr  <= ( lookup_access_data_late ) or 
                                 ( lookup_read_hit         );
  lookup_data_addr            <= lookup_data_addr_i;
  lookup_data_addr_i          <= lu_mem_data_addr when lud_step_use_check = '0' else 
                                 lu_check_data_addr;
  lu_mem_info_wr_vec          <= (others => lu_mem_info.Wr);
  lud_mem_waiting_for_pipe_vec <= (others => lud_mem_waiting_for_pipe);
  lookup_data_en_read         <= ( par_check_tag_hit )
                                    when ( lud_step_use_check = '1' ) else 
                                 ( not lu_mem_info_wr_vec and
                                   not lud_mem_waiting_for_pipe_vec );
  lu_check_wait_for_update_pspvec <= (others => lu_check_wait_for_update);
  lookup_data_en_write        <= par_check_tag_hit and 
                                 not lu_check_wait_for_update_pspvec;
  lookup_data_en              <= lookup_data_en_i;
  lookup_data_en_sel          <= lookup_data_en_read or lookup_data_en_write;
  lookup_data_we              <= lookup_data_we_i;
  lookup_write_hit_valid_vec  <= (others => lookup_write_hit_valid);
  lu_check_allow_write_vec    <= (others => lu_check_allow_write);
  lu_check_wait_for_update_bevec <= (others => lu_check_wait_for_update);
  lookup_data_we_i            <= access_be_word_i and lookup_write_hit_valid_vec and 
                                 lu_check_allow_write_vec and 
                                 not lu_check_wait_for_update_bevec;
  lookup_data_new_word        <= lookup_data_new_word_i;
  
  LU_Data_WE_Or_Inst1: carry_vec_or
    generic map(
      C_TARGET  => C_TARGET,
      C_INPUTS  => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      Carry_IN  => '0',
      A_Vec     => par_check_tag_hit,
      Carry_OUT => par_check_tag_hit_all_carry
    );
  
  LU_Data_WE_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => par_check_tag_hit_all_carry,
      A         => lu_check_valid,
      Carry_OUT => lookup_raw_hit_carry2
    );
  
  LU_Data_WE_And_Inst2: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_raw_hit_carry2,
      A_N       => '0',
      Carry_OUT => lookup_hit_carry
    );
  
  LU_Data_WE_And_Inst3: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => lookup_hit_carry,
      A         => lu_check_info.Wr,
      Carry_OUT => lookup_write_hit_carry
    );
  
  LU_Data_WE_And_Inst4: carry_select_and_n
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => lookup_write_hit_carry,
      No        => lookup_write_port,
      A_Vec     => update_write_miss_busy,
      Carry_Out => lookup_write_hit_no_busy
    );
  
  LU_Data_WE_Const_Inst1: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => lookup_write_hit_no_busy,    -- [in  std_logic]
      A_Vec     => par_check_locked_write,      -- [in  std_logic_vector]
      Carry_Out => lookup_write_hit_no_conflict -- [out std_logic]
    );
  
  LU_Data_WE_And_Inst5: carry_select_and
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => lookup_write_hit_no_conflict,
      No        => lookup_write_port,
      A_Vec     => access_data_valid,
      Carry_Out => lookup_write_hit_valid
    );
  
  
  -----------------------------------------------------------------------------
  -- Cache Hit & Miss Detect (Memory)
  -- 
  -- Pre-decode all parallel sets separately from storage before forwarding to 
  -- the next pipeline stage.
  -----------------------------------------------------------------------------
  
  -- Generate current address to check against because Mem can be poisoned by next transaction.
  par_mem_cur_wr_allocate   <= lu_check_write_alloc               when ( lu_mem_protect_conflict ) = '1' else 
                               lu_mem_write_alloc;
  par_mem_cur_force_hit     <= lu_check_info.Force_Hit            when ( lu_mem_protect_conflict ) = '1' else 
                               lu_mem_info.Force_Hit;
  par_mem_cur_write         <= lu_check_info.Wr                   when ( lu_mem_protect_conflict ) = '1' else 
                               lu_mem_info.Wr;
  par_mem_cur_addr          <= lu_check_info.Addr(C_ADDR_TAG_POS) when ( lu_mem_protect_conflict ) = '1' else 
                               lu_mem_info.Addr(C_ADDR_TAG_POS);
  par_mem_cur_DSid          <= lu_check_info.DSid                 when ( lu_mem_protect_conflict ) = '1' else 
                               lu_mem_info.DSid;
  lu_mem_valid_or_conflict  <= ( lu_mem_valid or lu_mem_protect_conflict );
  
  -- Instantiate TAG Checks for all parallel sets.
  Gen_Parallel_Cachehit_Mem: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    -- Split to local signals.
    par_mem_tag_word(I)     <= lookup_tag_current_word((I+1) * C_TAG_SIZE - 1 downto I * C_TAG_SIZE);
    
    -- Extract Tag status bits.
    par_mem_valid_bits(I)   <= par_mem_tag_word(I)(C_TAG_VALID_POS);
    par_mem_reused_bits(I)  <= par_mem_tag_word(I)(C_TAG_REUSED_POS);
    par_mem_dirty_bits(I)   <= par_mem_tag_word(I)(C_TAG_DIRTY_POS);
    par_mem_locked_bits(I)  <= par_mem_tag_word(I)(C_TAG_LOCKED_POS);

    -- Extract Tag DSid word
    par_mem_DSid_word(I)    <= par_mem_tag_word(I)(C_TAG_DSID_POS);
    
    -- Check cacheline address and valid (force hit when requested).
--    par_mem_valid_tag(I)    <= par_mem_valid_bits(I) when 
--                                 par_mem_cur_addr = par_mem_tag_word(I)(C_TAG_ADDR_POS) and
--                                 par_mem_cur_force_hit = '0' else
--                               '1' when 
--                                 ( par_mem_cur_force_hit and lu_mem_force_ser_hit and lu_mem_force_par_set = I )
--                               else '0';
    LU_Tag_And_Inst1: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => '1',
        A         => par_mem_valid_bits(I),
        Carry_OUT => par_mem_valid_carry(I)
      );

    LU_Tag_Compare_DSid_Inst1: carry_compare		-- Compare DSid
      generic map(
        C_TARGET  => C_TARGET,
        C_SIZE    => C_DSID_WIDTH
      )
      port map(
        A_Vec     => par_mem_cur_DSid,
        B_Vec     => par_mem_DSid_word(I),
        Carry_In  => par_mem_valid_carry(I),
        Carry_Out => par_mem_DSid_valid_tag(I)
      );
    
    LU_Tag_Compare_Inst1: carry_compare
      generic map(
        C_TARGET  => C_TARGET,
        C_SIZE    => C_NUM_ADDR_TAG_BITS
      )
      port map(
        A_Vec     => par_mem_cur_addr,
        B_Vec     => par_mem_tag_word(I)(C_TAG_ADDR_POS),
        Carry_In  => par_mem_valid_carry(I),
        Carry_Out => par_mem_pure_valid_tag(I)
      );
    
    par_mem_real_valid_tag(I) <= par_mem_pure_valid_tag(I) and par_mem_DSid_valid_tag(I);	-- real valid = VALID && addr match && DSid match
    par_mem_force_valid(I)  <= lu_mem_force_ser_hit and par_mem_cur_force_hit when ( lu_mem_force_par_set = I ) else 
                               '0';

    LU_Tag_And_Inst2: carry_and_n
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_real_valid_tag(I),
        A_N       => par_mem_cur_force_hit,
        Carry_OUT => par_mem_masked_valid_tag(I)
      );
    
    LU_Tag_Or_Inst1: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_masked_valid_tag(I),
        A         => par_mem_force_valid(I),
        Carry_OUT => par_mem_valid_tag(I)
      );
    
    -- Determine if hit.
--    par_mem_tag_hit(I)      <= ( lu_mem_valid or lu_mem_protect_conflict ) and par_mem_valid_tag(I);
    LU_Tag_And_Inst3: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_valid_tag(I),
        A         => lu_mem_valid_or_conflict,
        Carry_OUT => par_mem_tag_hit(I)
      );
    LU_Tag_And_Inst3b: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_pc(I)
      );
    LU_Tag_And_Inst3c: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_pc(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_md(I)
      );
    LU_Tag_And_Inst3d: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_md(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_wm(I)
      );
    LU_Tag_And_Inst3e: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_wm(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_ds(I)
      );
    LU_Tag_And_Inst3f: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_ds(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_lb(I)
      );
    LU_Tag_And_Inst3g: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_lb(I),
        A         => '1',
        Carry_OUT => par_mem_tag_hit_copy_rs(I)
      );
    
    -- Determine if miss.
    par_mem_tag_miss(I)     <= ( lu_mem_valid or lu_mem_protect_conflict ) and not par_mem_valid_tag(I) and 
                               not par_mem_cur_force_hit;
    
    -- Determine if locked hit (but not for forced hit).
--    par_mem_locked_hit(I)   <= par_mem_locked_bits(I) and par_mem_tag_hit(I) and not par_mem_cur_force_hit;
    par_mem_sel_locked(I) <= par_mem_locked_bits(I) and not par_mem_cur_force_hit;
    LU_Tag_And_Inst4: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_tag_hit_copy_rs(I),
        A         => par_mem_sel_locked(I),
        Carry_OUT => par_mem_locked_hit(I)
      );
    LU_Tag_And_Inst4b: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_locked_hit(I),
        A         => '1',
        Carry_OUT => par_mem_locked_hit_copy_lb(I)
      );
    
    -- Determine Write Locked hit.
--    par_mem_locked_write(I) <= par_mem_cur_write and par_mem_locked_hit(I);
    LU_Tag_And_Inst5: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_locked_hit_copy_lb(I),
        A         => par_mem_cur_write,
        Carry_OUT => par_mem_locked_write(I)
      );
    
    -- Determine if Line is Protected.
--    par_mem_protected(I) <= par_mem_locked_write(I) or 
--                            ( ( lu_mem_valid or lu_mem_protect_conflict ) and not par_mem_cur_force_hit and 
--                              ( par_mem_valid_bits(I) and par_mem_locked_bits(I) and par_mem_dirty_bits(I) ) );
    par_mem_valid_protect(I)  <= ( ( lu_mem_valid or lu_mem_protect_conflict ) and not par_mem_cur_force_hit and 
                                   ( par_mem_valid_bits(I) and par_mem_locked_bits(I) and par_mem_dirty_bits(I) ) );
    LU_Tag_Or_Inst2: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_locked_write(I),
        A         => par_mem_valid_protect(I),
        Carry_OUT => par_mem_protected_pre1(I)
      );
    
    par_mem_other_protect(I)  <= ( ( lu_mem_valid or lu_mem_protect_conflict ) and 
                                   ( par_mem_cur_wr_allocate and par_mem_valid_bits(I) and par_mem_reused_bits(I)) );
    LU_Tag_Or_Inst3: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => par_mem_protected_pre1(I),
        A         => par_mem_other_protect(I),
        Carry_OUT => par_mem_protected(I)
      );
    
  end generate Gen_Parallel_Cachehit_Mem;
  
  
  -----------------------------------------------------------------------------
  -- Cache Hit & Miss Detect (Check)
  -- 
  -- Generate hit and miss information for all associative sets in the
  -- Check pipe stage, such as:
  --  * Hit or Miss
  --  * Hit set number
  --  * Type of Hit or Miss: read, write, locked, dirty
  -- 
  -- Event              Action
  --  Write Miss        N/A
  --  Write Hit (first) Update Tag:
  --                      Read to get information (Addr)
  --                      Write to make it dirty (keeping the Addr)
  --  Write Hit         N/A
  --  Read Hit          N/A
  --  Read Miss         Write new contents (Locked)
  --  Read Miss Dirty   Swap Tag:
  --                      Read to get address for the Evicted data
  --                      Write new Address etc. (Locked)
  --  
  -----------------------------------------------------------------------------
  
  -- Add remaining parallel hit signals
  par_check_tag_hit_all   <= reduce_or(par_check_tag_hit);
  par_check_tag_miss_all  <= not par_check_tag_hit_all;
  
  -- Detect cacheline status.
  lookup_raw_hit          <= lu_check_valid and par_check_tag_hit_all;
  lookup_hit              <= lookup_raw_hit and not lu_check_info.KillHit;
  lookup_raw_miss         <= ( lu_check_valid and lu_check_last_set and par_check_tag_miss_all );
-- TODO: possible to remove lookup_raw_hit from equation?
  lookup_miss             <= lookup_raw_miss or 
                             ( lookup_raw_hit and lu_check_info.KillHit );
  
  lookup_evict_hit        <= lookup_raw_hit and lu_check_info.Evict;
  
  lookup_read_hit         <= lookup_hit  and not lu_check_info.Wr and not lu_check_info.KillHit;
  lookup_read_miss        <= lookup_miss and not lu_check_info.Wr and not lu_check_info.KillHit;
  lookup_read_miss_dirty  <= lookup_miss_dirty and not lu_check_info.Wr;
  
  lookup_write_hit        <= lookup_hit  and lu_check_info.Wr;
  lookup_write_miss       <= lookup_miss and lu_check_info.Wr;
  lookup_write_miss_dirty <= lookup_miss_dirty and lu_check_info.Wr;
  
  lookup_locked_wr_hit_raw<= lookup_raw_hit and lu_check_info.Wr and reduce_or(par_check_locked_write);
  lookup_locked_write_hit <= lookup_hit  and lu_check_info.Wr and reduce_or(par_check_locked_write);
  lookup_locked_read_hit  <= lookup_read_hit and ( lookup_protect_conflict or reduce_or(par_check_locked_hit) );
  lookup_first_write_hit  <= lookup_write_hit and not par_check_dirty_bits(lu_check_par_set);
  
  lookup_true_locked_read <= ( lookup_read_hit and reduce_or(par_check_locked_hit) );
  
  lookup_block_reuse      <= lookup_read_miss and lookup_all_reused_bits(lu_check_old_tag_idx);
    
  
  -----------------------------------------------------------------------------
  -- Detect Miss Dirty
  -----------------------------------------------------------------------------
  
--  lookup_miss_dirty       <= lookup_miss and 
--                             ( ( lu_check_info.Allocate and not lookup_raw_hit and 
--                                 lookup_all_dirty_bits(to_integer(unsigned(lookup_new_tag_assoc_set))) ) or
--                               ( lookup_raw_hit and  par_check_dirty_bits(lu_check_par_set) ) );
  
  -- Generate Dirty for fully utilized sets.
  lru_md_set <= to_integer(unsigned(lru_check_next_set));
  LU_MD_Or_Inst1: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_SETS
    )
    port map(
      Carry_In  => '0',
      No        => lru_md_set,
      A_Vec     => lookup_all_dirty_bits,
      Carry_Out => lru_dirty_bit
    );
  
  -- Turn off Full LRU if there is (at least) one free set.
  lu_check_valid_vec  <= (others => lu_check_valid);
  md_valid_qualified  <= lu_check_valid_vec and lookup_all_valid_bits;
  LU_MD_And_Inst1: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_SETS,
      B_Vec     => (C_SET_POS=>'1')
    )
    port map(
      Carry_In  => lru_dirty_bit,             -- [in  std_logic]
      A_Vec     => md_valid_qualified,     -- [in  std_logic_vector]
      Carry_Out => dirty_bit_miss             -- [out std_logic]
    );
  
  -- Turn off Miss related dirty bit if this is a hit.
  LU_MD_And_Inst2: carry_compare_const
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => dirty_bit_miss,            -- [in  std_logic]
      A_Vec     => par_check_tag_hit_copy_md, -- [in  std_logic_vector]
      Carry_Out => dirty_bit_miss_valid       -- [out std_logic]
    );
  
  -- Help signal for Valid pipestage with allocating transaction (miss).
  md_valid_alloc_miss <= lu_check_valid and lu_check_last_set and lu_check_info.Allocate;
  
  -- Valid dirty bit for a miss.
  LU_MD_And_Inst3: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => dirty_bit_miss_valid,      -- [in  std_logic]
      A         => md_valid_alloc_miss,       -- [in  std_logic]
      Carry_OUT => dirty_miss_valid           -- [out std_logic]
    );
  
  -- Generate help signal for dirty hit.
  md_hit_dirty  <= par_check_tag_hit_copy_md and par_check_dirty_bits;
  
  -- Valid dirty bit for hit or miss.
  LU_MD_Or_Inst3: carry_vec_or
    generic map(
      C_TARGET  => C_TARGET,
      C_INPUTS  => 2,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      Carry_IN  => dirty_miss_valid,
      A_Vec     => md_hit_dirty,
      Carry_OUT => dirty_bit
    );
  
  -- Help signal for detecting if this is a valid hit ot miss.
  lu_check_info_evict_vec <= (others => lu_check_info.Evict);
  md_valid_hit_miss <= par_check_tag_hit and not lu_check_info_evict_vec;
  
  -- Generate valid dirty bit.
  LU_MD_And_Inst4: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 2,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => dirty_bit,                 -- [in  std_logic]
      A_Vec     => md_valid_hit_miss,         -- [in  std_logic_vector]
      Carry_Out => dirty_bit_valid            -- [out std_logic]
    );
  
  -- Validate (step 1/2)
  md_check_valid <= ( lu_check_last_set or lu_check_info.Evict ) and 
                    not ( lu_check_info.KillHit and lu_check_info.SnoopResponse );
  LU_MD_And_Inst5: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => dirty_bit_valid,           -- [in  std_logic]
      A         => md_check_valid,            -- [in  std_logic]
      Carry_OUT => lookup_miss_dirty_pre      -- [out std_logic]
    );
  
  -- Validate (step 2/2)
  LU_MD_And_Inst6: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_miss_dirty_pre,     -- [in  std_logic]
      A         => lu_check_valid,            -- [in  std_logic]
      Carry_OUT => lookup_miss_dirty          -- [out std_logic]
    );
  
  
  -----------------------------------------------------------------------------
  -- Detect Protected Conflict
  -----------------------------------------------------------------------------
  
--  lookup_protect_conflict <= lu_check_valid and 
--                             ( ( lu_check_info.Allocate and lookup_raw_miss and 
--                                 lookup_all_protected(to_integer(unsigned(lookup_new_tag_assoc_set))) ) or
--                               ( lookup_raw_hit and par_check_protected(lu_check_par_set) ) ) and
--                             not ( lu_mem_protect_conflict_d1 and not par_check_protected(lu_check_protected_par_set) );
  
  lru_pc_set <= to_integer(unsigned(lru_check_next_set));
  LU_PC_Or_Inst1: carry_select_or
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_SETS
    )
    port map(
      Carry_In  => '0',
      No        => lru_pc_set,
      A_Vec     => lookup_all_protected,
      Carry_Out => lru_protected_bit
    );
  
  LU_PC_And_Inst1: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_SETS,
      B_Vec     => (C_SET_POS=>'1')
    )
    port map(
      Carry_In  => lru_protected_bit,         -- [in  std_logic]
      A_Vec     => lookup_all_valid_bits,     -- [in  std_logic_vector]
      Carry_Out => protected_bit_miss         -- [out std_logic]
    );
  
  LU_PC_And_Inst2: carry_compare_const
    generic map(
      C_KEEP    => true,
      C_TARGET  => C_TARGET,
      C_SIGNALS => 1,
      C_SIZE    => C_NUM_PARALLEL_SETS,
      B_Vec     => (C_PARALLEL_SET_POS=>'0')
    )
    port map(
      Carry_In  => protected_bit_miss,        -- [in  std_logic]
      A_Vec     => par_check_tag_hit_copy_pc, -- [in  std_logic_vector]
      Carry_Out => protected_bit_miss_valid   -- [out std_logic]
    );
  
  pc_valid_alloc_miss <= lu_check_valid and lu_check_last_set and lu_check_info.Allocate;
  LU_PC_And_Inst3: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => protected_bit_miss_valid,  -- [in  std_logic]
      A         => pc_valid_alloc_miss,       -- [in  std_logic]
      Carry_OUT => protected_miss_valid       -- [out std_logic]
    );
  
  pc_hit_protected  <= par_check_tag_hit and par_check_protected;
  LU_PC_Or_Inst3: carry_vec_or
    generic map(
      C_TARGET  => C_TARGET,
      C_INPUTS  => 2,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      Carry_IN  => protected_miss_valid,
      A_Vec     => pc_hit_protected,
      Carry_OUT => protected_bit
    );

  lu_mem_protect_conflict_d1_vec <= (others => lu_mem_protect_conflict_d1);
  pc_filter <= ( lu_mem_protect_conflict_d1_vec and not par_check_protected );
  LU_PC_And_Inst4: carry_select_and_n
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PARALLEL_SETS
    )
    port map(
      Carry_In  => protected_bit,
      No        => lu_check_protected_par_set,
      A_Vec     => pc_filter,
      Carry_Out => filtered_protection_bit
    );
  
  LU_PC_And_Inst5: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => filtered_protection_bit,   -- [in  std_logic]
      A         => lu_check_valid,            -- [in  std_logic]
      Carry_OUT => lookup_protect_conflict    -- [out std_logic]
    );
  
  
  -----------------------------------------------------------------------------
  -- Read Data Forwarding
  -- 
  -- Select data from current hit and forward it to the current port.
  -----------------------------------------------------------------------------
  
  -- Generate mux structures for read data.
  Use_Par_RdData: if( C_NUM_PARALLEL_SETS > 1 ) generate
  begin
    Use_RTL: if( C_TARGET = RTL ) generate
    begin
      -- Calculate the parallel association address.
      Cachehit_Assoc_Set_Gen: process (par_check_tag_hit) is
      begin  -- process Cachehit_Assoc_Set_Gen
        lookup_hit_par_set  <= 0;
        for i in 1 to C_NUM_PARALLEL_SETS - 1 loop
          if( par_check_tag_hit(i) = '1' ) then
            lookup_hit_par_set <= i;
          end if;
        end loop; 
      end process Cachehit_Assoc_Set_Gen;
      
      -- Get current set for hit data.
      lud_mem_set           <= lud_mem_set_d1     when ( lud_mem_keep_single_during_stall = '1' ) or
                                                       ( lud_mem_delayed_read_data        = '1' ) else 
                               lookup_hit_par_set;
      
    end generate Use_RTL;
    
    Use_FPGA: if( C_TARGET /= RTL ) generate
    begin
      Use_2: if( C_NUM_PARALLEL_SETS = 2 ) generate
      begin
        -- Calculate the parallel association address.
        lookup_hit_par_set <= 1 when par_check_tag_hit(1) = '1' else 0;
        
        -- Get current set for hit data.
        lud_mem_set           <= lud_mem_set_d1     when ( lud_mem_keep_single_during_stall = '1' ) or
                                                         ( lud_mem_delayed_read_data        = '1' ) else 
                                 lookup_hit_par_set;
        
      end generate Use_2;
      
      Use_4_8: if( C_NUM_PARALLEL_SETS = 4 or C_NUM_PARALLEL_SETS = 8 ) generate
      
        subtype C_HIT_DETECT_POS            is natural range 3 downto 0;
        subtype HIT_DETECT_TYPE             is std_logic_vector(C_HIT_DETECT_POS);
        type PARALLEL_HIT_DETECT_TYPE       is array(C_PARALLEL_SET_BIT_POS) of HIT_DETECT_TYPE;
        
        signal par_hit_array     : PARALLEL_HIT_DETECT_TYPE;
        
        signal par_set_delayed   : PARALLEL_SET_BIT_TYPE;
        signal read_idx_i0       : PARALLEL_SET_BIT_TYPE;
        signal hit_par_set_i     : PARALLEL_SET_BIT_TYPE;
        signal read_idx_i        : PARALLEL_SET_BIT_TYPE;
      begin
        -- Type conversion.
        par_set_delayed   <= std_logic_vector(to_unsigned(lud_mem_set_d1, C_PARALLEL_SET_BITS));
        
        -- Generate input to optimized detection.
        Use_4: if( C_NUM_PARALLEL_SETS = 4 ) generate
        begin
          par_hit_array(1)  <= '0' & '0' & par_check_tag_hit(3) & par_check_tag_hit(2);
          par_hit_array(0)  <= '0' & '0' & par_check_tag_hit(3) & par_check_tag_hit(1);
        end generate Use_4;
        Use_8: if( C_NUM_PARALLEL_SETS = 8 ) generate
        begin
          par_hit_array(2)  <= par_check_tag_hit(7) & par_check_tag_hit(6) & par_check_tag_hit(5) & par_check_tag_hit(4);
          par_hit_array(1)  <= par_check_tag_hit(7) & par_check_tag_hit(6) & par_check_tag_hit(3) & par_check_tag_hit(2);
          par_hit_array(0)  <= par_check_tag_hit(7) & par_check_tag_hit(5) & par_check_tag_hit(3) & par_check_tag_hit(1);
        end generate Use_8;
        
        -- Instantiate detection logic.
        Gen_Detect: for I in C_PARALLEL_SET_BIT_POS generate
        begin
          LUT_Inst: LUT6_2
            generic map(
              INIT => X"FFFF0000FFFEFFFE"
            )
            port map(
              O5 => hit_par_set_i(I),                 -- [out]
              O6 => read_idx_i0(I),                   -- [out]
              I0 => par_hit_array(I)(0),              -- [in]
              I1 => par_hit_array(I)(1),              -- [in]
              I2 => par_hit_array(I)(2),              -- [in]
              I3 => par_hit_array(I)(3),              -- [in]
              I4 => par_set_delayed(I),               -- [in]
              I5 => lud_mem_keep_single_during_stall  -- [in]
            );
            
          MUXF7_Inst: MUXF7
            port map (
              O  => read_idx_i(I),                -- [out std_logic]
              I0 => read_idx_i0(I),               -- [in  std_logic]
              I1 => par_set_delayed(I),           -- [in  std_logic]
              S  => lud_mem_delayed_read_data);   -- [in  std_logic]
          
        end generate Gen_Detect;
        
        -- Type conversion.
        lookup_hit_par_set  <= to_integer(unsigned(hit_par_set_i));
        lud_mem_set         <= to_integer(unsigned(read_idx_i));
        
      end generate Use_4_8;

      Use_16_32: if( C_NUM_PARALLEL_SETS = 16 or C_NUM_PARALLEL_SETS = 32 ) generate
		begin
        -- Calculate the parallel association address.
            Cachehit_Assoc_Set_Gen: process (par_check_tag_hit) is
            begin  -- process Cachehit_Assoc_Set_Gen
				lookup_hit_par_set  <= 0;
                    for i in 1 to C_NUM_PARALLEL_SETS - 1 loop
                      if( par_check_tag_hit(i) = '1' ) then
                        lookup_hit_par_set <= i;
                      end if;
                    end loop;
            end process Cachehit_Assoc_Set_Gen;

       -- Get current set for hit data.
       lud_mem_set           <= lud_mem_set_d1     when ( lud_mem_keep_single_during_stall = '1' ) or ( lud_mem_delayed_read_data        = '1' ) else 
                                                          lookup_hit_par_set;
     end generate Use_16_32;

    end generate Use_FPGA;
    
  end generate Use_Par_RdData;
  
  -- Only one possible source for data.
  No_Par_RdData: if( C_NUM_PARALLEL_SETS = 1 ) generate
  begin
    lookup_hit_par_set      <= 0;
    lud_mem_set             <= 0;
    
  end generate No_Par_RdData;
  
  lookup_read_data_set  <= lud_mem_set;
  
  
  -----------------------------------------------------------------------------
  -- Data Pipeline Stage: Step (virtual stage)
  -- 
  -- 
  -----------------------------------------------------------------------------
  
  -- Determine if current beat is read.
--  lud_step_offset_is_read   <= ( lud_step_offset and lud_step_is_read );
  lud_step_is_read          <= ( not lu_check_info.Wr ) when ( lud_step_use_check = '1' ) else
                               ( not lu_mem_info.Wr );
  LUD_Read_PR_And_Inst1: carry_and 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_step_offset,
      A         => lud_step_is_read,
      Carry_OUT => lud_step_offset_is_read
    );
  
  -- Detect when information from Check stage is used.
  lud_step_use_check        <= lookup_hit and not lu_check_wait_for_update and not lud_mem_already_used and 
                               ( not lud_mem_use_speculative or lu_check_info.Wr );
  
  -- Get current write port number.
  lud_step_write_port_num   <= get_port_num(lu_check_info.Port_Num, C_NUM_PORTS);
  
  -- Detect when it is allowed to step.
  lud_step_allow_write_step <= ( lookup_write_hit and not lookup_data_hit_stall and not lu_check_wait_for_update and  
                                 access_data_valid(lud_step_write_port_num) );
  lud_step_allow_read_step  <= ( lookup_read_hit and not lookup_true_locked_read and not lud_mem_already_used ) or 
                               ( lookup_read_miss and lu_mem_valid and not lu_mem_info.Wr and lookup_restart_mem ) or
                               ( lud_step_want_mem_step );
  
  -- Generate step for data handling.
--  lud_step_offset           <= ( lud_step_want_step_offset ) and 
--                               not lud_step_stall;
  LUD_Step_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_data_en_ii(C_NUM_PARALLEL_SETS),
      A_N       => lud_step_stall,
      Carry_OUT => lud_step_offset
    );
  
  -- Stall Data Step stage if not ready.
  lud_step_stall            <= not ( lud_step_allow_write_step or lud_step_allow_read_step );
  
  
  -- Want read step when (read data is filtered via valid bit instead):
  --  * Read in Check with data remaining 
  --     - Not waiting for Update
  --  * Read in Mem with nothing or done in Check
  -- 
  -- Want write step when:
  --  * Write in Check with data remaining
  --     - Not waiting for Update
  
  lud_step_pos_read_in_mem  <= lu_mem_valid and not lu_mem_info.Wr and not lud_mem_conflict and 
                               not lud_mem_waiting_for_pipe and
                               ( not lookup_write_hit or lu_check_wait_for_update or lud_mem_already_used );
  lud_step_want_check_step  <= ( lu_check_valid and not lu_check_info.Wr and not lud_mem_use_speculative and 
                                 not lu_check_wait_for_update and not lud_mem_already_used and 
                                 not lud_mem_waiting_for_pipe and not lud_mem_conflict );
  lud_step_want_mem_step    <= ( lud_step_pos_read_in_mem and lu_check_wait_for_update ) or 
                               ( lud_step_pos_read_in_mem and not lookup_hit ) or 
--                               ( lud_step_pos_read_in_mem and lookup_true_locked_read ) or 
                               ( lud_step_pos_read_in_mem and lud_mem_already_used ) or 
                               ( lud_step_pos_read_in_mem and lud_mem_use_speculative ) or 
                               ( lud_step_pos_read_in_mem and not lu_check_valid );
  lud_step_want_restart     <= ( ( lud_step_allow_read_step and lud_mem_conflict ) or lud_step_delayed_restart ) and 
                               not lud_addr_pipeline_full;
  lud_step_want_read_step   <= lud_step_want_check_step or
                               lud_step_want_mem_step;
  
  lud_step_want_write_step  <= ( lu_check_valid and lu_check_info.Wr and not lu_check_wait_for_update and 
                                 not lud_addr_pipeline_full );
  
  
--  lud_step_want_step_offset <= ( lud_addr_piperun or lud_step_want_write_step ) and 
--                               not lud_step_want_stall;
  LUD_WStep_PR_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_addr_piperun,
      A         => lud_step_want_write_step,
      Carry_OUT => lud_step_want_step_offset
    );
-- Disable since no event need to stall
--  LUD_WStep_PR_And_Inst1: carry_and_n 
--    generic map(
--      C_TARGET => C_TARGET
--    )
--    port map(
--      Carry_IN  => lud_step_want_step_pre1,
--      A_N       => lud_step_want_stall,
--      Carry_OUT => lud_step_want_step_offset
--    );
  
  -- Stall Data Step stage if not ready.
  lud_step_want_stall       <= '0';
  
  lookup_data_en_ii(0)      <= lud_step_want_step_offset;
  Gen_Parallel_Data_En: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    LUD_WStep_PR_And_Inst1: carry_latch_and
      generic map(
        C_TARGET  => C_TARGET,
        C_NUM_PAD => min_of(4, I * 4),
        C_INV_C   => false
      )
      port map(
        Carry_IN  => lookup_data_en_ii(I),
        A         => lookup_data_en_sel(I),
        O         => lookup_data_en_i(I),
        Carry_OUT => lookup_data_en_ii(I+1)
      );
  end generate Gen_Parallel_Data_En;
  
  -- .
  Data_Pipeline_Stage_Step_Restart : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Step_Restart
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_step_delayed_restart  <= '0';
        
      elsif( lud_step_offset = '1' ) then
        lud_step_delayed_restart  <= '0';
        
      elsif( ( lud_step_allow_read_step and lud_mem_conflict and lud_addr_pipeline_full ) = '1' ) then
        lud_step_delayed_restart  <= '1';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Step_Restart;
  
  
  -----------------------------------------------------------------------------
  -- Data Pipeline Stage: Address
  -- 
  -- 
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  lud_addr_piperun  <= ( lud_mem_piperun or not lud_mem_valid or
--                          lud_addr_rerun_after_conf) and 
--                       not lud_addr_stall;
-- Instead of including 'lud_addr_rerun_after_conf' (i.e. 'lud_step_want_restart') in 
-- the 'lud_step_want_read_step' (i.e. 'lud_addr_stall') is it move after the and_n gate, 
-- to have simpler logic for the and_n and or gates.
  LUD_Addr_PR_Or_Inst1: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_mem_piperun,
      A_N       => lud_mem_valid_pipe,
      Carry_OUT => lud_addr_piperun_pre1
    );
  lud_addr_rerun_after_conf <= lud_step_want_restart;
  LUD_Addr_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_addr_piperun_pre1,
      A_N       => lud_addr_stall,
      Carry_OUT => lud_addr_piperun_pre2
    );
  LUD_Addr_PR_Or_Inst2: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_addr_piperun_pre2,
      A         => lud_addr_rerun_after_conf,
      Carry_OUT => lud_addr_piperun
    );
  
  -- Stall Data Address stage if not ready.
  lud_addr_stall    <= not lud_step_want_read_step;
  
  -- Propagate status to next stage when possible.
  Data_Pipeline_Stage_Mem_Valid : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Valid
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_speculative_valid <= '0';
        
      elsif( lud_addr_piperun = '1' ) then
        lud_mem_speculative_valid <= '1';
        
      elsif( lud_mem_piperun = '1' ) then
        lud_mem_speculative_valid <= '0';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Valid;
  
  -- Move information to next stage when possible.
  Data_Pipeline_Stage_Mem : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_rresp             <= C_RRESP_OKAY;
        lud_mem_port_num          <= 0;
        lud_mem_port_one_hot      <= (others=>'0');
        lud_mem_last              <= '0';
        lud_mem_delayed_read_data <= '0';
        
      elsif( lud_addr_piperun = '1' ) then
        lud_mem_rresp             <= C_RRESP_OKAY;
        if( lud_step_use_check = '0' ) then
          if( is_on(C_ENABLE_COHERENCY + C_ENABLE_EX_MON) = 1 ) then
            if( lu_mem_info.Exclusive = '1' ) then
              lud_mem_rresp             <= C_RRESP_EXOKAY;
            end if;
          end if;
          if( C_ENABLE_COHERENCY /= 0 ) then
            lud_mem_rresp(C_RRESP_ISSHARED_POS)   <= lu_mem_info.IsShared;
            lud_mem_rresp(C_RRESP_PASSDIRTY_POS)  <= lu_mem_info.PassDirty;
          end if;
          lud_mem_port_num          <= get_port_num(lu_mem_info.Port_Num, C_NUM_PORTS);
          lud_mem_port_one_hot      <= std_logic_vector(to_unsigned(2 ** get_port_num(lu_mem_info.Port_Num, C_NUM_PORTS), 
                                                                    C_NUM_PORTS));
        else
          if( is_on(C_ENABLE_COHERENCY + C_ENABLE_EX_MON) = 1 ) then
            if( lu_check_info.Exclusive = '1' ) then
              lud_mem_rresp             <= C_RRESP_EXOKAY;
            end if;
          end if;
          if( C_ENABLE_COHERENCY /= 0 ) then
            lud_mem_rresp(C_RRESP_ISSHARED_POS)   <= lu_check_info.IsShared;
            lud_mem_rresp(C_RRESP_PASSDIRTY_POS)  <= lu_check_info.PassDirty;
          end if;
          lud_mem_port_num          <= get_port_num(lu_check_info.Port_Num, C_NUM_PORTS);
          lud_mem_port_one_hot      <= std_logic_vector(to_unsigned(2 ** get_port_num(lu_check_info.Port_Num, C_NUM_PORTS), 
                                                                    C_NUM_PORTS));
        end if;
        lud_mem_last              <= lookup_step_last;
        lud_mem_delayed_read_data <= ( ( lud_step_use_check and lookup_step_last ) or 
                                       (  lookup_access_data_late ) ) and 
                                     ( lookup_read_hit and not lookup_locked_read_hit and not lud_mem_already_used );
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem;
  
  -- .
  Data_Pipeline_Stage_Set : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Set
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_set_d1            <= 0;
        
      elsif( ( lud_addr_piperun = '1' ) or
             ( lud_mem_completed and not lud_mem_piperun and not lud_mem_keep_single_during_stall and
               lookup_read_hit and not lookup_locked_read_hit ) = '1' ) then
        lud_mem_set_d1            <= lookup_hit_par_set;
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Set;
  
  --
  Data_Pipeline_Stage_Mem_Single_Beat : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Single_Beat
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_completed         <= '0';
        
      elsif( lud_addr_piperun = '1' ) then
        lud_mem_completed         <= lu_mem_valid and not lu_mem_info.Wr and lookup_step_last and 
                                     not lud_step_use_check and not lookup_protect_conflict;
        
      elsif( ( lookup_protect_conflict = '1' ) or ( lud_mem_piperun = '1' ) )then
        lud_mem_completed         <= '0';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Single_Beat;
  
  -- Need to control if speculative read in Mem is allowed:
  --  * Speculative read of last (and only beat) directly
  --  * Sliding speculative read of last (and only beat)
  Data_Pipeline_Stage_Mem_Stop_Spec : process (lud_addr_piperun, lu_mem_piperun_i, lookup_protect_conflict, 
                                               lu_mem_valid, lu_mem_info, lookup_step_last, lud_step_use_check, 
                                               lud_mem_waiting_for_pipe, lud_mem_completed, 
                                               lud_mem_use_speculative) is
  begin  -- process Data_Pipeline_Stage_Mem_Stop_Spec
    if( lud_addr_piperun = '1' ) then
      lud_mem_use_spec_cmb  <= lu_mem_valid and not lu_mem_info.Wr and lookup_step_last and 
                               not lud_step_use_check and not lookup_protect_conflict;
      
    elsif( lu_mem_piperun_i = '1' )then
      lud_mem_use_spec_cmb  <= lud_mem_waiting_for_pipe and lud_mem_completed;
      
    elsif( lookup_protect_conflict = '1' )then
      lud_mem_use_spec_cmb  <= '0';
      
    else
      lud_mem_use_spec_cmb  <= lud_mem_use_speculative;
    end if;
  end process Data_Pipeline_Stage_Mem_Stop_Spec;
  
  USpec_Inst: bit_reg_ce
    generic map(
      C_TARGET  => C_TARGET,
      C_IS_SET  => '0',
      C_CE_LOW  => (0 downto 0=>'0'),
      C_NUM_CE  => 1
    )
    port map(
      CLK       => ACLK,
      SR        => ARESET_I,
      CE        => "1",
      D         => lud_mem_use_spec_cmb,
      Q         => lud_mem_use_speculative
    );
  
  -- 
  Data_Pipeline_Stage_Mem_Prefetch : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Prefetch
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_waiting_for_pipe  <= '0';
        
      elsif( ( lud_addr_piperun and not lud_mem_waiting_for_pipe ) = '1' ) then
        lud_mem_waiting_for_pipe  <= lu_mem_valid and not lu_mem_info.Wr and lookup_offset_all_first and 
                                     not lookup_protect_conflict and not lud_step_use_check and not lu_mem_piperun_i;
        
      elsif( lu_mem_piperun_i = '1' ) then
        lud_mem_waiting_for_pipe  <= '0';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Prefetch;
  
  -- Propagate status to next stage when possible.
  Data_Pipeline_Stage_Mem_Done : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Done
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_already_used  <= '0';
        
      elsif( lu_mem_piperun_i = '1' ) then
        lud_mem_already_used  <= '0';
        
      elsif( ( lud_step_offset and not lookup_locked_read_hit and lud_step_use_check and lookup_step_last and
               lu_check_valid and not lu_check_info.Wr ) = '1' ) then
        lud_mem_already_used  <= '1';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Done;
  
  -- 
  Data_Pipeline_Stage_Mem_Keep : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Keep
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_keep_single_during_stall  <= '0';
        
      elsif( ( lud_mem_completed and not lud_mem_piperun and
               lookup_read_hit and not lookup_locked_read_hit ) = '1' ) then
        lud_mem_keep_single_during_stall  <= '1';
        
      elsif( lud_mem_piperun = '1' ) then
        lud_mem_keep_single_during_stall  <= '0';
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Keep;
  
  --
  Data_Pipeline_Stall : process (ACLK) is
  begin  -- process Data_Pipeline_Stall
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_addr_pipeline_full  <= '0';
        
      else
        lud_addr_pipeline_full  <= -- Data doesn't move and fifo is almost full 
                                   -- => Pipe will be full next cycle.
                                   ( lud_mem_valid and lud_reg_valid and 
                                     read_data_hit_almost_full(lud_reg_port_num) and 
                                     not read_data_hit_pop(lud_reg_port_num) ) or
                                   -- Data doesn't move and last empty stage will get new data 
                                   -- => Pipe will be full next cycle.
                                   ( lud_step_offset_is_read and not lookup_locked_read_hit and 
                                     not lud_mem_valid and lud_reg_valid and 
                                     read_data_hit_full(lud_reg_port_num) and 
                                     not read_data_hit_pop(lud_reg_port_num) ) or
                                   -- Data doesn't move and last empty stage will speculatively get new data 
                                   -- => Pipe will be full next cycle.
                                   ( lud_step_offset_is_read and lud_step_want_mem_step and not lud_step_use_check and 
                                     not lud_mem_valid and lud_reg_valid and 
                                     read_data_hit_full(lud_reg_port_num) and 
                                     not read_data_hit_pop(lud_reg_port_num) ) or
                                   -- Data (Reg) can move but fifo for Mem is full and doesn't move
                                   -- => Pipe will be full next cycle. 
                                   ( lud_mem_valid and lud_reg_valid and 
                                     read_data_hit_full(lud_mem_port_num) and 
                                     not read_data_hit_pop(lud_mem_port_num) ) or
                                   -- Hole in data pipe is filled and data doesn't move 
                                   -- => Pipe will be full next cycle. 
                                   ( lud_step_offset_is_read and not lookup_locked_read_hit and 
                                     lud_mem_valid and not lud_reg_valid and 
                                     read_data_hit_full(lud_mem_port_num) and 
                                     not read_data_hit_pop(lud_mem_port_num) ) or
                                   -- Hole in data pipe is speculatively filled and data doesn't move 
                                   -- => Pipe will be full next cycle. 
                                   ( lud_step_offset_is_read and lud_step_want_mem_step and not lud_step_use_check and 
                                     lud_mem_valid and not lud_reg_valid and 
                                     read_data_hit_full(lud_mem_port_num) and 
                                     not read_data_hit_pop(lud_mem_port_num) ) or
                                   -- Keep until data can move.
                                   ( lud_addr_pipeline_full and 
                                     read_data_hit_full(lud_reg_port_num) );
        
      end if;
    end if;
  end process Data_Pipeline_Stall;
  
  
  -----------------------------------------------------------------------------
  -- Data Pipeline Stage: Memory
  -- 
  -- 
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  lud_mem_piperun <= ( lud_reg_piperun or not lud_reg_valid ) and 
--                     not lud_mem_stall;
  LUD_Mem_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_reg_piperun,
      A_N       => lud_mem_stall,
      Carry_OUT => lud_mem_piperun
    );
  
  -- Stall Data Memory stage if not ready.
  lud_mem_stall       <= lud_mem_waiting_for_pipe;
  
  -- Determine if stage is truly valid (from a pipeline utilization point-of-view).
  lud_mem_valid_pipe  <= lud_mem_speculative_valid and
                         ( ( lookup_read_hit and not lookup_true_locked_read and not lud_mem_conflict and 
                             not lookup_access_data_late ) or
                           ( lud_mem_delayed_read_data ) or
                           ( lud_mem_keep_single_during_stall ) );
  
  -- Determine if stage is truly valid.
  lud_mem_valid       <= lud_mem_speculative_valid and
                         ( ( lookup_read_hit and not lookup_locked_read_hit and not lud_mem_conflict and 
                             not lookup_access_data_late ) or
                           ( lud_mem_delayed_read_data ) or
                           ( lud_mem_keep_single_during_stall ) );
  
  -- Detect if this was a speculative read with a conflict (potentially old data read).
  Data_Pipeline_Stage_Mem_Conflict : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Mem_Conflict
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_mem_conflict  <= '0';
        
      else
        lud_mem_conflict  <= lookup_protect_conflict;
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Mem_Conflict;

  lud_mem_valid_vec <= (others => lud_mem_valid);

  -- Propagate status to next stage when possible.
  Data_Pipeline_Stage_Reg_Valid : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Reg_Valid
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_reg_valid         <= '0';
        lud_reg_valid_one_hot <= (others=>'0');
        
      elsif( lud_mem_piperun = '1' ) then
        lud_reg_valid         <= lud_mem_valid;
        lud_reg_valid_one_hot <= lud_mem_valid_vec and 
                                 lud_mem_port_one_hot;
        
      elsif( lud_reg_piperun = '1' ) then
        lud_reg_valid         <= '0';
        lud_reg_valid_one_hot <= (others=>'0');
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Reg_Valid;
  
  -- Move information to next stage when possible.
  Data_Pipeline_Stage_Reg : process (ACLK) is
  begin  -- process Data_Pipeline_Stage_Reg
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        lud_reg_rresp         <= C_RRESP_OKAY;
        lud_reg_port_num      <= 0;
        lud_reg_last          <= '0';
        
      elsif( lud_mem_piperun = '1' ) then
        lud_reg_rresp         <= lud_mem_rresp;
        lud_reg_port_num      <= lud_mem_port_num;
        lud_reg_last          <= lud_mem_last;
        
      end if;
    end if;
  end process Data_Pipeline_Stage_Reg;
  
  -- Select data from this pipestage.
  No_Rd_Pipeline: if( not C_PIPELINE_LU_READ_DATA ) generate
  begin
    lookup_read_data_valid_i  <= lud_mem_valid_vec and 
                                 lud_mem_port_one_hot;
    
    lookup_read_data_last     <= lud_mem_last;
    lookup_read_data_word     <= lookup_data_current_word;
    lookup_read_data_resp     <= lud_mem_rresp;
  end generate No_Rd_Pipeline;
  
  Use_Rd_Pipeline: if( C_PIPELINE_LU_READ_DATA ) generate
  begin
    lookup_read_data_valid_i  <= lud_reg_valid_one_hot;
    lookup_read_data_last     <= lud_reg_last;
    lookup_read_data_resp     <= lud_reg_rresp;
    
    -- Split to local array.
    Gen_Parallel_Data_Array: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
    begin
      Rd_Pipeline : process (ACLK) is
      begin  -- process Rd_Pipeline
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if( lud_mem_piperun = '1' and lud_mem_set /= I  and C_NUM_PARALLEL_SETS > 1 ) then  -- synchronous reset (active high)
            lookup_read_data_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH) <= (others=>'0');
          elsif( lud_mem_piperun = '1' ) then
            lookup_read_data_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH) <= 
                                lookup_data_current_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
          end if;
        end if;
      end process Rd_Pipeline;
      
    end generate Gen_Parallel_Data_Array;
    
  end generate Use_Rd_Pipeline;
  
  -- Assign external.
  lookup_read_data_valid  <= lookup_read_data_valid_i;
  
  
  -----------------------------------------------------------------------------
  -- Data Pipeline Stage: Pipeline
  -- 
  -- Optional pipeline stage that keeps data in one register per set.
  -- Only one register at the time is allowed to contain data, enabling the 
  -- possibility to use or instead of muxing data.
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  lud_reg_piperun <= not lud_reg_stall;
  
  -- Stall Data Register stage if not ready.
--  lud_reg_stall   <= lud_reg_valid and read_data_hit_full(lud_reg_port_num);
  
  LUD_Reg_PR_Or_Inst1: carry_select_or_n
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_NUM_PORTS
    )
    port map(
      Carry_In  => '0',
      No        => lud_reg_port_num,
      A_Vec     => read_data_hit_full,
      Carry_Out => lud_reg_piperun_pre1
    );
  LUD_Reg_PR_Or_Inst2: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lud_reg_piperun_pre1,
      A_N       => lud_reg_valid,
      Carry_OUT => lud_reg_piperun
    );
  
  
  -----------------------------------------------------------------------------
  -- Write Data Forwarding
  -- 
  -- Select data that shall be forwarded to the memory to be written. Takes 
  -- data form the currently active port and writtes it to the parallel set 
  -- for the hit. 
  -----------------------------------------------------------------------------
  
  -- Generate mux structures for write data.
  Use_Multi_WrData: if( C_NUM_PORTS > 1 ) generate
    signal access_be_word_ii          : PORT_BE_TYPE;
    signal access_data_word_i         : PORT_DATA_TYPE;
  begin
    -- Split to local array.
    Gen_Port_Data_Array: for I in 0 to C_NUM_PORTS - 1 generate
    begin
      access_be_word_ii(I)    <= access_data_be((I+1) * C_CACHE_DATA_WIDTH/8 - 1 downto I * C_CACHE_DATA_WIDTH/8);
      access_data_word_i(I)   <= access_data_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
      
    end generate Gen_Port_Data_Array;
    
    -- Source port for write data
    lookup_write_port       <= get_port_num(lu_check_info.Port_Num, C_NUM_PORTS);
    
    -- Select hit data.
    access_be_word_i        <= access_be_word_ii(lookup_write_port);
    lookup_data_new_word_i  <= access_data_word_i(lookup_write_port);
    
  end generate Use_Multi_WrData;
  
  -- Only one possible source for data.
  No_Multi_WrData: if( C_NUM_PORTS = 1 ) generate
  begin
    lookup_write_port       <= 0;
    access_be_word_i        <= access_data_be;
    lookup_data_new_word_i  <= access_data_word;
    
  end generate No_Multi_WrData;
  
  -- Acknowledge port.
  lookup_write_data_ready   <= lookup_write_data_ready_i;
  lookup_write_data_ready_vec <= (others => (lookup_write_hit and not lookup_data_hit_stall and 
                                             not lu_check_wait_for_update and not lud_addr_pipeline_full));
  lookup_write_data_ready_i <= lookup_write_data_ready_vec and 
                               std_logic_vector(to_unsigned(2 ** lookup_write_port, C_NUM_PORTS));
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_lu_opt_write_hit         <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_write_miss        <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_write_miss_dirty  <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_read_hit          <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_read_miss         <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_read_miss_dirty   <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_locked_write_hit  <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_locked_read_hit   <= (others=>C_NULL_STAT_POINT);
    stat_lu_opt_first_write_hit   <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_write_hit         <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_write_miss        <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_write_miss_dirty  <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_read_hit          <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_read_miss         <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_read_miss_dirty   <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_locked_write_hit  <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_locked_read_hit   <= (others=>C_NULL_STAT_POINT);
    stat_lu_gen_first_write_hit   <= (others=>C_NULL_STAT_POINT);
    stat_lu_stall                 <= C_NULL_STAT_POINT;
    stat_lu_fetch_stall           <= C_NULL_STAT_POINT;
    stat_lu_mem_stall             <= C_NULL_STAT_POINT;
    stat_lu_data_stall            <= C_NULL_STAT_POINT;
    stat_lu_data_hit_stall        <= C_NULL_STAT_POINT;
    stat_lu_data_miss_stall       <= C_NULL_STAT_POINT;
    
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    
    signal valid_new_stat         : std_logic;
    signal lu_check_stat_done     : std_logic;
    
    signal det_lu_stall           : std_logic;
    signal det_lu_fetch_stall     : std_logic;
    signal det_lu_mem_stall       : std_logic;
    signal det_lu_data_stall      : std_logic;
    signal det_lu_data_hit_stall  : std_logic;
    signal det_lu_data_miss_stall : std_logic;
    
  begin
    valid_new_stat  <= lu_check_valid and not lu_check_stat_done;
    
    Stat_Control : process (ACLK) is
    begin  -- process Stat_Control
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( stat_reset = '1' ) then         -- synchronous reset (active high)
          lu_check_stat_done  <= '1';
        else
          lu_check_stat_done  <= '1';
          
          if( lu_mem_piperun = '1' ) then
            lu_check_stat_done  <= not (lu_mem_valid and not lu_mem_flush_pipe);
          end if;
        end if;
      end if;
    end process Stat_Control;
    
    Stat_Handle : process (ACLK) is
    begin  -- process Stat_Handle
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( stat_reset = '1' ) then         -- synchronous reset (active high)
          -- Stall information.
          det_lu_stall            <= '0';
          det_lu_fetch_stall      <= '0';
          det_lu_mem_stall        <= '0';
          det_lu_data_stall       <= '0';
          det_lu_data_hit_stall   <= '0';
          det_lu_data_miss_stall  <= '0';
        else
          -- Stall information.
          det_lu_stall            <= lookup_stall;
          det_lu_fetch_stall      <= lu_fetch_valid and lu_fetch_stall;
          det_lu_mem_stall        <= lu_mem_valid   and lu_mem_stall;
          det_lu_data_stall       <= lu_check_valid and lookup_data_stall and not lookup_data_hit_stall;
          det_lu_data_hit_stall   <= lu_check_valid and lookup_data_hit_stall;
          det_lu_data_miss_stall  <= lu_check_valid and lookup_data_miss_stall;
        end if;
      end if;
    end process Stat_Handle;
    
    Gen_Per_Port: for I in 0 to C_NUM_PORTS - 1 generate
      signal new_read_hit               : std_logic;
      signal new_read_miss              : std_logic;
      signal new_read_miss_dirty        : std_logic;
      signal new_write_hit              : std_logic;
      signal new_write_miss             : std_logic;
      signal new_write_miss_dirty       : std_logic;
      signal new_locked_write_hit       : std_logic;
      signal new_locked_read_hit        : std_logic;
      signal new_first_write_hit        : std_logic;
      
      signal stat_lu_write_hit          : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_write_miss         : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_write_miss_dirty   : STAT_POINT_TYPE;    -- Number of transactions (future use)
      signal stat_lu_read_hit           : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_read_miss          : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_read_miss_dirty    : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_locked_write_hit   : STAT_POINT_TYPE;    -- Number of transactions 
      signal stat_lu_locked_read_hit    : STAT_POINT_TYPE;    -- Number of Transactions
      signal stat_lu_first_write_hit    : STAT_POINT_TYPE;    -- Number of Transactions
    begin
    
      Stat_Port_Handle : process (ACLK) is
      begin  -- process Stat_Port_Handle
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if( stat_reset = '1' ) then         -- synchronous reset (active high)
            -- Hit/Miss information.
            new_read_hit            <= '0';
            new_read_miss           <= '0';
            new_read_miss_dirty     <= '0';
            new_write_hit           <= '0';
            new_write_miss          <= '0';
            new_write_miss_dirty    <= '0';
            new_locked_write_hit    <= '0';
            new_locked_read_hit     <= '0';
            new_first_write_hit     <= '0';
            
          else
            -- Hit/Miss information.
            if( get_port_num(lu_check_info.Port_Num, C_NUM_PORTS) = I ) then
              new_read_hit            <= valid_new_stat and lookup_read_hit;
              new_read_miss           <= valid_new_stat and lookup_read_miss;
              new_read_miss_dirty     <= valid_new_stat and lookup_read_miss_dirty and not lu_check_info.Evict;
              new_write_hit           <= valid_new_stat and lookup_write_hit;
              new_write_miss          <= valid_new_stat and lookup_write_miss;
              new_write_miss_dirty    <= valid_new_stat and lookup_write_miss_dirty;
              new_locked_write_hit    <= valid_new_stat and lookup_locked_write_hit;
              new_locked_read_hit     <= valid_new_stat and lookup_locked_read_hit;
              new_first_write_hit     <= valid_new_stat and lookup_first_write_hit;
            else
              new_read_hit            <= '0';
              new_read_miss           <= '0';
              new_read_miss_dirty     <= '0';
              new_write_hit           <= '0';
              new_write_miss          <= '0';
              new_write_miss_dirty    <= '0';
              new_locked_write_hit    <= '0';
              new_locked_read_hit     <= '0';
              new_first_write_hit     <= '0';
            end if;
              
          end if;
        end if;
      end process Stat_Port_Handle;
      
      Write_Hit_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_write_hit,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_write_hit
        );
        
      Write_Miss_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_write_miss,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_write_miss
        );
        
      Write_Miss_Dirty_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_write_miss_dirty,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_write_miss_dirty
        );
        
      Read_Hit_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_read_hit,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_read_hit
        );
        
      Read_Miss_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_read_miss,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_read_miss
        );
        
      Read_Miss_Dirty_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_read_miss_dirty,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_read_miss_dirty
        );
        
      Locked_Write_Hit_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_locked_write_hit,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_locked_write_hit
        );
        
      Locked_Read_Hit_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_locked_read_hit,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_locked_read_hit
        );
        
      First_Write_Hit_Inst: sc_stat_counter
        generic map(
          -- General.
          C_TARGET                  => C_TARGET,
          
          -- Configuration.
          C_STAT_SIMPLE_COUNTER     => 1,
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
          
          update                    => new_first_write_hit,
          counter                   => (C_STAT_COUNTER_BITS-1 downto 0=>'0'),
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_lu_first_write_hit
        );
      -- Assign depending on category.
      Use_Opt: if( I < C_NUM_OPTIMIZED_PORTS ) generate
      begin
        stat_lu_opt_write_hit(I)                                <= stat_lu_write_hit;
        stat_lu_opt_write_miss(I)                               <= stat_lu_write_miss;
        stat_lu_opt_write_miss_dirty(I)                         <= stat_lu_write_miss_dirty;
        stat_lu_opt_read_hit(I)                                 <= stat_lu_read_hit;
        stat_lu_opt_read_miss(I)                                <= stat_lu_read_miss;
        stat_lu_opt_read_miss_dirty(I)                          <= stat_lu_read_miss_dirty;
        stat_lu_opt_locked_write_hit(I)                         <= stat_lu_locked_write_hit;
        stat_lu_opt_locked_read_hit(I)                          <= stat_lu_locked_read_hit;
        stat_lu_opt_first_write_hit(I)                          <= stat_lu_first_write_hit;
        
      end generate Use_Opt;
      Use_Gen: if( I >= C_NUM_OPTIMIZED_PORTS ) generate
      begin
        stat_lu_gen_write_hit(I - C_NUM_OPTIMIZED_PORTS)        <= stat_lu_write_hit;
        stat_lu_gen_write_miss(I - C_NUM_OPTIMIZED_PORTS)       <= stat_lu_write_miss;
        stat_lu_gen_write_miss_dirty(I - C_NUM_OPTIMIZED_PORTS) <= stat_lu_write_miss_dirty;
        stat_lu_gen_read_hit(I - C_NUM_OPTIMIZED_PORTS)         <= stat_lu_read_hit;
        stat_lu_gen_read_miss(I - C_NUM_OPTIMIZED_PORTS)        <= stat_lu_read_miss;
        stat_lu_gen_read_miss_dirty(I - C_NUM_OPTIMIZED_PORTS)  <= stat_lu_read_miss_dirty;
        stat_lu_gen_locked_write_hit(I - C_NUM_OPTIMIZED_PORTS) <= stat_lu_locked_write_hit;
        stat_lu_gen_locked_read_hit(I - C_NUM_OPTIMIZED_PORTS)  <= stat_lu_locked_read_hit;
        stat_lu_gen_first_write_hit(I - C_NUM_OPTIMIZED_PORTS)  <= stat_lu_first_write_hit;
      end generate Use_Gen;
    end generate Gen_Per_Port;
    
    LS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_stall
      );
      
    FS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_fetch_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_fetch_stall
      );
      
    MS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_mem_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_mem_stall
      );
      
    DS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_data_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_data_stall
      );
      
    DHS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_data_hit_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_data_hit_stall
      );
      
    DMS_Inst: sc_stat_event
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
        ARESET                    => stat_reset,
        
        
        -- ---------------------------------------------------
        -- Probe Interface
        
        probe                     => det_lu_data_miss_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_lu_data_miss_stall
      );
      
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    LOOKUP_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_PORTS   : natural := min_of( 4, C_NUM_PORTS);
    constant C_MY_WPORT   : natural := min_of( 2, Log2(C_NUM_PORTS));
    constant C_MY_WORD    : natural := min_of( 6, C_ADDR_WORD_HI - C_ADDR_BYTE_LO + 1);
    constant C_MY_TLINE   : natural := min_of(10, C_ADDR_FULL_LINE_HI - C_ADDR_FULL_LINE_LO + 1);
    constant C_MY_DLINE   : natural := min_of(14, C_ADDR_DATA_HI - C_ADDR_DATA_LO + 1);
    constant C_MY_PSET    : natural := min_of( 4, C_NUM_PARALLEL_SETS);
    constant C_MY_SET     : natural := min_of( 2, C_SET_BIT_HI - C_SET_BIT_LO + 1);
    constant C_MY_TAG     : natural := min_of(16, C_TAG_SIZE);
    constant C_MY_WE      : natural := min_of( 4, C_CACHE_DATA_WIDTH/8);
    constant C_MY_2ND_SET : natural := min_of( 1, C_NUM_PARALLEL_SETS - 1);
    constant C_MY_OFF     : natural := min_of( 6, C_ADDR_WORD_HI - C_ADDR_BYTE_LO + 1);
    constant C_MY_LEN     : natural := min_of( 6, C_INT_LEN);
    constant C_MY_DATA    : natural := min_of(32, C_CACHE_DATA_WIDTH);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          LOOKUP_DEBUG  <= (others=>'0');
        else
          -- Default assignment.
          LOOKUP_DEBUG      <= (others=>'0');
          
          -- Access signals: 1+6+6 + 4+4 = 13 + 8 (limited scope 9->6, 9->4)
--          LOOKUP_DEBUG(                              0)  <= access_valid;
--          LOOKUP_DEBUG(  1 + C_MY_WORD  - 1 downto   1)  <= access_use(C_MY_WORD - 1 downto 0);
--          LOOKUP_DEBUG(  7 + C_MY_WORD  - 1 downto   7)  <= access_stp(C_MY_WORD - 1 downto 0);
--          LOOKUP_DEBUG( 13 + C_MY_PORTS - 1 downto  13)  <= access_data_valid(C_MY_PORTS - 1 downto 0);
--          LOOKUP_DEBUG( 17 + C_MY_PORTS - 1 downto  17)  <= access_data_last(C_MY_PORTS - 1 downto 0);

--          LOOKUP_DEBUG(                              0)  <= lud_step_use_check         : std_logic;
          LOOKUP_DEBUG(                              0)  <= lud_step_allow_write_step;
          LOOKUP_DEBUG(                              1)  <= lud_step_allow_read_step;
--          LOOKUP_DEBUG(                              0)  <= lud_step_offset            : std_logic;
--          LOOKUP_DEBUG(                              2)  <= lud_step_stall             : std_logic;
          LOOKUP_DEBUG(                              2)  <= lud_step_pos_read_in_mem;
          LOOKUP_DEBUG(                              3)  <= lud_step_want_check_step;
          LOOKUP_DEBUG(                              4)  <= lud_step_want_mem_step;
          LOOKUP_DEBUG(                              5)  <= lud_step_want_read_step;
          LOOKUP_DEBUG(                              6)  <= lud_step_want_write_step;
          LOOKUP_DEBUG(                              7)  <= lud_step_want_step_offset;
          LOOKUP_DEBUG(                              8)  <= lud_step_want_stall;
          LOOKUP_DEBUG(                              9)  <= lud_addr_piperun;
          LOOKUP_DEBUG(                             10)  <= lud_addr_stall;
          LOOKUP_DEBUG(                             11)  <= lud_mem_piperun;
--          LOOKUP_DEBUG(                              0)  <= lud_mem_speculative_valid  : std_logic;
--          LOOKUP_DEBUG(                              0)  <= lud_mem_valid              : std_logic;
          LOOKUP_DEBUG(                             12)  <= lud_mem_stall;
          LOOKUP_DEBUG(                             13)  <= lud_mem_completed;
          LOOKUP_DEBUG(                             14)  <= lud_mem_delayed_read_data;
          LOOKUP_DEBUG(                             15)  <= lud_mem_conflict;
          LOOKUP_DEBUG(                             16)  <= lud_mem_waiting_for_pipe;
          LOOKUP_DEBUG(                             17)  <= lud_reg_piperun;
          LOOKUP_DEBUG(                             18)  <= lud_reg_valid;
          LOOKUP_DEBUG(                             19)  <= '0';
          LOOKUP_DEBUG(                             20)  <= lud_reg_last;
          
          -- Internal Interface Signals (Read Data): 4+4 = 8 (limited scope 9->4)
          LOOKUP_DEBUG( 21 + C_MY_PORTS - 1 downto  21)  <= read_data_hit_almost_full(C_MY_PORTS - 1 downto 0);
          LOOKUP_DEBUG( 25 + C_MY_PORTS - 1 downto  25)  <= read_data_hit_full(C_MY_PORTS - 1 downto 0);
          
          -- Update signals: 1+1+1+1+1 = 5 (limited scope 9->1, current selected)
          LOOKUP_DEBUG(                             29)  <= update_tag_conflict;
          LOOKUP_DEBUG(                             30)  <= update_piperun;
          LOOKUP_DEBUG(                             31)  <= '0';
          LOOKUP_DEBUG(                             32)  <= update_write_miss_full;
          LOOKUP_DEBUG(                             33)  <= update_write_miss_busy(get_port_num(lu_check_info.Port_Num, C_NUM_PORTS));
          
          -- Lookup signals (to Access): 1
          LOOKUP_DEBUG(                             34)  <= lookup_piperun_i;
          
          -- Lookup signals (to Frontend): 4+1+4 = 9 (limited scope 9->4)
          LOOKUP_DEBUG( 35 + C_MY_PORTS - 1 downto  35)  <= lookup_read_data_valid_i(C_MY_PORTS - 1 downto 0);
          LOOKUP_DEBUG(                             39)  <= lud_mem_use_speculative;
          LOOKUP_DEBUG( 40 + C_MY_PORTS - 1 downto  40)  <= lookup_write_data_ready_i(C_MY_PORTS - 1 downto 0);
          
          
          -- Lookup signals (to Tag & Data): 10+1+16*2 + 14+4+4 = 43 + 22 (limited scope 8->4)
          LOOKUP_DEBUG( 44 + C_MY_TLINE - 1 downto  44)  <= lookup_tag_addr_i(C_ADDR_FULL_LINE_LO + C_MY_TLINE - 1 downto 
                                                                              C_ADDR_FULL_LINE_LO);
          LOOKUP_DEBUG(                             54)  <= lookup_tag_en_i;
          LOOKUP_DEBUG( 55 + C_MY_TAG   - 1 downto  55)  <= par_mem_tag_word(0)(C_TAG_SIZE - 1 downto C_TAG_SIZE - C_MY_TAG);
          LOOKUP_DEBUG( 71 + C_MY_TAG   - 1 downto  71)  <= par_mem_tag_word(C_MY_2ND_SET)(C_TAG_SIZE - 1 downto C_TAG_SIZE - C_MY_TAG);
          LOOKUP_DEBUG( 87 + C_MY_DLINE - 1 downto  87)  <= lookup_data_addr_i(C_ADDR_DATA_LO + C_MY_DLINE - 1 downto 
                                                                               C_ADDR_DATA_LO);
          LOOKUP_DEBUG(101 + C_MY_PSET  - 1 downto 101)  <= lookup_data_en_i(C_MY_PSET - 1 downto 0);
          LOOKUP_DEBUG(105 + C_MY_WE    - 1 downto 105)  <= lookup_data_we_i(C_MY_WE - 1 downto 0);
          
          -- Lookup signals (to Arbiter): 2+1+1 = 4 (limited scope 4->2)
          LOOKUP_DEBUG(                            109)  <= lookup_io_data_stall;
          LOOKUP_DEBUG(                            110)  <= lu_ds_last_beat_stall;
          LOOKUP_DEBUG(                            111)  <= lookup_read_done_i;
          LOOKUP_DEBUG(                            112)  <= lookup_read_data_new_i;
          
          -- Lookup signals (to LRU): 1+2+2 = 5 (limited scope 3->2)
          LOOKUP_DEBUG(                            113)  <= lru_check_use_lru_i;

          LOOKUP_DEBUG(114 + C_MY_SET   - 1 downto 114)  <= lru_tag_assoc_set(C_SET_BIT_LO + C_MY_SET - 1 downto 
                                                                              C_SET_BIT_LO); 
                                                            -- lru_check_used_set, update_set
          LOOKUP_DEBUG(116 + C_MY_SET   - 1 downto 116)  <= lru_check_next_set(C_SET_BIT_LO + C_MY_SET - 1 downto 
                                                                               C_SET_BIT_LO);
            
          -- Lookup signals (to Update): 1+1+1 = 3
          LOOKUP_DEBUG(                            118)  <= lookup_push_write_miss_i;
          LOOKUP_DEBUG(                            119)  <= lookup_wm_evict_i;
          LOOKUP_DEBUG(                            120)  <= update_valid_i;
          
          -- Lookup Pipeline Stage: Access : 1
          LOOKUP_DEBUG(                            121)  <= lookup_stall;
          
          -- Lookup pipe stage: Fetch : 7
          LOOKUP_DEBUG(                            122)  <= lu_fetch_piperun;
          LOOKUP_DEBUG(                            123)  <= lu_fetch_valid;
          LOOKUP_DEBUG(                            124)  <= lu_fetch_stall;
          LOOKUP_DEBUG(                            125)  <= lu_fetch_set_id;
          LOOKUP_DEBUG(                            126)  <= lu_fetch_flush_pipe;
          LOOKUP_DEBUG(                            127)  <= lu_fetch_protect_conflict;
          LOOKUP_DEBUG(                            128)  <= lu_fetch_last_set;
          
          -- Lookup pipe stage: Memory : 7
          LOOKUP_DEBUG(                            129)  <= lu_mem_piperun;
          LOOKUP_DEBUG(                            130)  <= lu_mem_valid;
          LOOKUP_DEBUG(                            131)  <= lu_mem_stall;
          LOOKUP_DEBUG(                            132)  <= lu_mem_set_id;
          LOOKUP_DEBUG(                            133)  <= lu_mem_flush_pipe;
          LOOKUP_DEBUG(                            134)  <= lu_mem_protect_conflict;
          LOOKUP_DEBUG(                            135)  <= lu_mem_last_set;
          
          -- Lookup pipe stage: Check : 15
          LOOKUP_DEBUG(                            136)  <= lu_check_piperun;
          LOOKUP_DEBUG(                            137)  <= lu_check_valid;
          LOOKUP_DEBUG(                            138)  <= lu_check_stall;
          LOOKUP_DEBUG(                            139)  <= lu_check_wait_for_update;
          LOOKUP_DEBUG(                            140)  <= lu_check_need_move2update;
          LOOKUP_DEBUG(                            141)  <= lu_check_set_id;
          LOOKUP_DEBUG(                            142)  <= lu_check_last_set;
          LOOKUP_DEBUG(                            143)  <= lookup_access_data_late;
          LOOKUP_DEBUG(                            144)  <= lookup_protect_conflict;
          LOOKUP_DEBUG(                            145)  <= lookup_restart_mem;
          LOOKUP_DEBUG(                            146)  <= lookup_flush_pipe;
          LOOKUP_DEBUG(                            147)  <= lu_mem_flush_done;
          LOOKUP_DEBUG(                            148)  <= lookup_evict_hit;
          LOOKUP_DEBUG(                            149)  <= lookup_true_locked_read;
          LOOKUP_DEBUG(                            150)  <= lu_check_read_info_done;
          
          -- LRU Handling: 1
          LOOKUP_DEBUG(                            151)  <= lookup_invalid_exist;
          
          -- TAG Conflict: 1+1+1 = 3
          LOOKUP_DEBUG(                            152)  <= lu_mem_tag_conflict;
          LOOKUP_DEBUG(                            153)  <= lu_check_tag_conflict;
          LOOKUP_DEBUG(                            154)  <= lookup_tag_conflict;
          
          -- Data Offset Counter: 16 + 6*4 = 40 (limited scope max 6bit)
          LOOKUP_DEBUG(                            155)  <= lud_step_use_check;
          LOOKUP_DEBUG(                            156)  <= lookup_kind;
          LOOKUP_DEBUG(                            157)  <= lud_mem_already_used;
          LOOKUP_DEBUG(                            158)  <= lud_step_stall;
          LOOKUP_DEBUG(                            159)  <= lud_step_offset;
          LOOKUP_DEBUG(                            160)  <= lookup_step_last;
          LOOKUP_DEBUG(                            161)  <= lud_mem_keep_single_during_stall;
          LOOKUP_DEBUG(162 + C_MY_OFF   - 1 downto 162)  <= lookup_base_offset(C_ADDR_BYTE_LO + C_MY_OFF - 1 downto 
                                                                               C_ADDR_BYTE_LO);
          LOOKUP_DEBUG(168 + C_MY_OFF   - 1 downto 168)  <= lookup_word_offset(C_ADDR_BYTE_LO + C_MY_OFF - 1 downto 
                                                                               C_ADDR_BYTE_LO);
          LOOKUP_DEBUG(174 + C_MY_LEN   - 1 downto 174)  <= lookup_offset_len(C_MY_LEN - 1 downto 0);
          LOOKUP_DEBUG(                            180)  <= lookup_offset_first;
          LOOKUP_DEBUG(                            181)  <= lookup_force_first;
          LOOKUP_DEBUG(                            182)  <= lookup_offset_all_first;
          LOOKUP_DEBUG(                            183)  <= lu_check_early_bresp;
          LOOKUP_DEBUG(184 + C_MY_OFF   - 1 downto 184)  <= lookup_offset_cnt(C_ADDR_BYTE_LO + C_MY_OFF - 1 downto 
                                                                              C_ADDR_BYTE_LO);
          LOOKUP_DEBUG(                            190)  <= lookup_data_stall;
          LOOKUP_DEBUG(                            191)  <= lud_mem_speculative_valid;
          LOOKUP_DEBUG(                            192)  <= lud_mem_valid;
          LOOKUP_DEBUG(                            193)  <= lud_addr_pipeline_full;
          LOOKUP_DEBUG(                            194)  <= lud_mem_last;
          
          -- Cache Hit & Miss Detect (Check): 13
          LOOKUP_DEBUG(                            195)  <= par_check_tag_hit_all;
          LOOKUP_DEBUG(                            196)  <= par_check_tag_miss_all;
          LOOKUP_DEBUG(                            197)  <= lookup_raw_hit;
          LOOKUP_DEBUG(                            198)  <= lookup_hit;
          LOOKUP_DEBUG(                            199)  <= lookup_miss;
          LOOKUP_DEBUG(                            200)  <= lookup_read_hit;
          LOOKUP_DEBUG(                            201)  <= lookup_read_miss;
          LOOKUP_DEBUG(                            202)  <= lookup_read_miss_dirty;
          LOOKUP_DEBUG(                            203)  <= lookup_write_hit;
          LOOKUP_DEBUG(                            204)  <= lookup_locked_write_hit;
          LOOKUP_DEBUG(                            205)  <= lookup_locked_read_hit;
          LOOKUP_DEBUG(                            206)  <= lookup_first_write_hit;
          LOOKUP_DEBUG(                            207)  <= lookup_write_miss;
          LOOKUP_DEBUG(                            208)  <= lookup_data_hit_stall;
          LOOKUP_DEBUG(                            209)  <= lookup_data_miss_stall;
          LOOKUP_DEBUG(                            210)  <= lu_fetch_info.Wr;
          LOOKUP_DEBUG(                            211)  <= lu_mem_info.Wr;
          LOOKUP_DEBUG(                            212)  <= lu_check_info.Wr;
          LOOKUP_DEBUG(                            213)  <= lu_check_lru_ser_set_match;
          LOOKUP_DEBUG(                            214)  <= lookup_read_data_hit_i;
          LOOKUP_DEBUG(215 + C_MY_PSET  - 1 downto 215)  <= lookup_all_valid_bits(C_MY_PSET  - 1 downto 0);
          LOOKUP_DEBUG(219 + C_MY_PSET  - 1 downto 219)  <= lookup_all_dirty_bits(C_MY_PSET  - 1 downto 0);
          LOOKUP_DEBUG(223 + C_MY_PSET  - 1 downto 223)  <= lookup_all_locked_bits(C_MY_PSET  - 1 downto 0);
          LOOKUP_DEBUG(227 + C_MY_SET   - 1 downto 227)  <= lookup_new_tag_assoc_set(C_SET_BIT_LO + C_MY_SET - 1 downto 
                                                                                     C_SET_BIT_LO);
          LOOKUP_DEBUG(229 + C_MY_SET   - 1 downto 229)  <= lookup_tag_assoc_set(C_SET_BIT_LO + C_MY_SET - 1 downto 
                                                                                 C_SET_BIT_LO);
          LOOKUP_DEBUG(                            231)  <= lu_fetch_flush_done;
          LOOKUP_DEBUG(                            232)  <= lu_check_miss_next_ser;
          LOOKUP_DEBUG(                            233)  <= lu_check_completed;
          LOOKUP_DEBUG(                            234)  <= lu_check_done;
          LOOKUP_DEBUG(                            235)  <= reduce_or(assert_err);
          LOOKUP_DEBUG(                            236)  <= lookup_write_miss_dirty;
          LOOKUP_DEBUG(237 + C_MY_PSET  - 1 downto 237)  <= lookup_all_protected(C_MY_PSET  - 1 downto 0);
          LOOKUP_DEBUG(                            241)  <= lookup_wm_allocate_i;
          LOOKUP_DEBUG(                            242)  <= lookup_block_reuse;
          LOOKUP_DEBUG(                            243)  <= lookup_miss_dirty;
          LOOKUP_DEBUG(244 + C_MY_SET   - 1 downto 244)  <= std_logic_vector(to_unsigned(lu_check_protected_par_set,
                                                                                         C_MY_SET));
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  Assertions: block
  begin
    -- ----------------------------------------
    -- Never detect multiple hits for the same address.
    
    Assert_Cachehit: process (par_check_tag_hit) is
      variable detect_hit : std_logic;
    begin  -- process Assert_Cachehit
      detect_hit                        := '0';
      assert_err(C_ASSERT_MULTIPLE_HIT) <= '0';
      
      for i in par_check_tag_hit'range loop
        if( par_check_tag_hit(i) = '1' ) then
          if( detect_hit = '1' and C_USE_ASSERTIONS ) then
            assert_err(C_ASSERT_MULTIPLE_HIT) <= '1';
          end if;
          detect_hit  := '1';
        end if;
      end loop; 
    end process Assert_Cachehit;
    
    -- ----------------------------------------
    -- Never push Read Data to full FIFO.
    
    Assert_Full_FIFO: process (read_data_hit_full, lookup_read_data_valid_i) is
    begin  -- process Assert_Full_FIFO
      assert_err(C_ASSERT_FIFO_FULL_VIOLATION)  <= '0';
      
      for i in lookup_read_data_valid_i'range loop
        if( ( lookup_read_data_valid_i(i) and read_data_hit_full(i) ) = '1' and C_USE_ASSERTIONS ) then
          assert_err(C_ASSERT_FIFO_FULL_VIOLATION)  <= '1';
        end if;
      end loop; 
    end process Assert_Full_FIFO;
    
    
    -- ----------------------------------------
    -- Messages.
    
    -- pragma translate_off
      
    assert assert_err_1(C_ASSERT_FIFO_FULL_VIOLATION) = '0' 
      report "Lookup: Write to Full FIFO Detected."
        severity error;
    
    assert assert_err_1(C_ASSERT_MULTIPLE_HIT) = '0' 
      report "Lookup: Illegal Multiple Hit Detected."
        severity error;
    
    -- pragma translate_on
  end block Assertions;
  
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


--For PARD stab
  Stat_Control_For_PARD : process (ACLK) is
      begin  -- process Stat_Control
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if( ARESET = '1' ) then         -- synchronous reset (active high)
            lu_check_stat_done_for_pard  <= '1';
          else
            lu_check_stat_done_for_pard  <= '1';          
            if( lu_mem_piperun = '1' ) then
              lu_check_stat_done_for_pard  <= not (lu_mem_valid and not lu_mem_flush_pipe);
            end if;
          end if;
        end if;
      end process Stat_Control_For_PARD;
 
 Stat_Port_Handle_For_PARD : process (ACLK) is
     begin  -- process Stat_Port_Handle
        if ACLK'event and ACLK = '1' then     -- rising clock edge
         if( ARESET = '1' ) then         -- synchronous reset (active high)
            -- Hit/Miss information.
            new_hit_for_pard            <= '0';
            new_miss_for_pard           <= '0';

         else

            new_hit_for_pard            <= valid_new_stat_for_pard and lookup_hit and not lu_check_info.KillHit;
            new_miss_for_pard           <= valid_new_stat_for_pard and lookup_miss and not lu_check_info.KillHit;

         end if;
       end if;
     end process Stat_Port_Handle_For_PARD; 
  
valid_new_stat_for_pard  <= lu_check_valid and not lu_check_stat_done_for_pard;
  
  --For PARD stab
  lu_check_valid_to_stab <= lu_check_valid;
  lookup_DSid_to_stab    <= lu_check_info.DSid;
  lookup_hit_to_stab     <= new_hit_for_pard;
  lookup_miss_to_stab    <= new_miss_for_pard;
  
  
end architecture IMP;
