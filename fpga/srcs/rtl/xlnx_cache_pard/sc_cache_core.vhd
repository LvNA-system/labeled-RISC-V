-------------------------------------------------------------------------------
-- sc_cache_core.vhd - Entity and architecture
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
-- Filename:        sc_cache_core.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_cache_core.vhd
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


entity sc_cache_core is
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
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
    C_ID_WIDTH                : natural range  1 to   32      :=  1;
    
    -- Data type and settings specific.
    C_LRU_ADDR_BITS           : natural range  4 to   63      := 13;
    C_TAG_SIZE                : natural range  3 to   96      := 15;
    C_NUM_STATUS_BITS         : natural range  4 to    4      :=  4;
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- For PARD
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_CACHE_DATA_ADDR_WIDTH   : natural range  2 to    7      :=  2;
    C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
    C_EXTERNAL_DATA_ADDR_WIDTH: natural range  2 to    7      :=  2;
    C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
    C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
    C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
    C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
    C_ADDR_EXT_DATA_HI        : natural range  2 to   63      := 14;
    C_ADDR_EXT_DATA_LO        : natural range  2 to   63      :=  2;
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
    C_ADDR_EXT_WORD_HI        : natural range  2 to   63      :=  6;
    C_ADDR_EXT_WORD_LO        : natural range  2 to   63      :=  2;
    C_ADDR_WORD_HI            : natural range  2 to   63      :=  6;
    C_ADDR_WORD_LO            : natural range  2 to   63      :=  2;
    C_ADDR_EXT_BYTE_HI        : natural range  0 to   63      :=  1;
    C_ADDR_EXT_BYTE_LO        : natural range  0 to   63      :=  0;
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
    read_data_miss_full       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to Access).
    
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
    -- Lookup signals (to Arbiter).
    
    lookup_read_done          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Update signals (to Frontend).
    
    -- Read miss
    update_read_data_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    update_read_data_last     : out std_logic;
    update_read_data_resp     : out std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
    update_read_data_word     : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    update_read_data_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    -- Write Miss
    update_write_data_ready   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    -- Write miss response
    update_ext_bresp_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    update_ext_bresp          : out std_logic_vector(2 - 1 downto 0);
    update_ext_bresp_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Automatic Clean Information.
    
    update_auto_clean_push    : out std_logic;
    update_auto_clean_addr    : out AXI_ADDR_TYPE;
    update_auto_clean_DSid    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    -- ---------------------------------------------------
    -- Update signals (to Backend).
    
    read_req_valid            : out std_logic;
    read_req_port             : out natural range 0 to C_NUM_PORTS - 1;
    read_req_addr             : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    read_req_len              : out std_logic_vector(8 - 1 downto 0);
    read_req_size             : out std_logic_vector(3 - 1 downto 0);
    read_req_exclusive        : out std_logic;
    read_req_kind             : out std_logic;
    read_req_ready            : in  std_logic;
    read_req_DSid             : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    write_req_valid           : out std_logic;
    write_req_port            : out natural range 0 to C_NUM_PORTS - 1;
    write_req_internal        : out std_logic;
    write_req_addr            : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    write_req_len             : out std_logic_vector(8 - 1 downto 0);
    write_req_size            : out std_logic_vector(3 - 1 downto 0);
    write_req_exclusive       : out std_logic;
    write_req_kind            : out std_logic;
    write_req_line_only       : out std_logic;
    write_req_ready           : in  std_logic;
    write_req_DSid            : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    write_data_valid          : out std_logic;
    write_data_last           : out std_logic;
    write_data_be             : out std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
    write_data_word           : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
    write_data_ready          : in  std_logic;
    write_data_almost_full    : in  std_logic;
    write_data_full           : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Backend signals.
    
    backend_wr_resp_valid     : in  std_logic;
    backend_wr_resp_port      : out natural range 0 to C_NUM_PORTS - 1;
    backend_wr_resp_internal  : out std_logic;
    backend_wr_resp_addr      : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    backend_wr_resp_bresp     : in  std_logic_vector(2 - 1 downto 0);
    backend_wr_resp_ready     : out std_logic;
    
    backend_rd_data_valid     : in  std_logic;
    backend_rd_data_last      : in  std_logic;
    backend_rd_data_word      : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
    backend_rd_data_rresp     : in  std_logic_vector(2 - 1 downto 0);
    backend_rd_data_ready     : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                      : in  std_logic;
    stat_enable                     : in  std_logic;
    
    -- Lookup
    stat_lu_opt_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    
    stat_lu_gen_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    
    stat_lu_stall                   : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_fetch_stall             : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_mem_stall               : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_stall              : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_hit_stall          : out STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_miss_stall         : out STAT_POINT_TYPE;    -- Time per occurance
    
    -- Update
    stat_ud_stall                   : out STAT_POINT_TYPE;    -- Time transactions are stalled
    stat_ud_tag_free                : out STAT_POINT_TYPE;    -- Cycles tag is free
    stat_ud_data_free               : out STAT_POINT_TYPE;    -- Cycles data is free
    stat_ud_ri                      : out STAT_FIFO_TYPE;     -- Read Information
    stat_ud_r                       : out STAT_FIFO_TYPE;     -- Read data (optional)
    stat_ud_e                       : out STAT_FIFO_TYPE;     -- Evict
    stat_ud_bs                      : out STAT_FIFO_TYPE;     -- BRESP Source
    stat_ud_wm                      : out STAT_FIFO_TYPE;     -- Write Miss
    stat_ud_wma                     : out STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    MEMORY_DEBUG1             : out std_logic_vector(255 downto 0);
    MEMORY_DEBUG2             : out std_logic_vector(255 downto 0);
    LOOKUP_DEBUG              : out std_logic_vector(255 downto 0);
    UPDATE_DEBUG1             : out std_logic_vector(255 downto 0);
    UPDATE_DEBUG2             : out std_logic_vector(255 downto 0);

	--For PARD stab
    lookup_valid_to_stab                : out std_logic;
    lookup_DSid_to_stab                 : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    lookup_hit_to_stab          		: out std_logic;
    lookup_miss_to_stab         		: out std_logic;
    update_tag_en_to_stab               : out std_logic;
    update_tag_we_to_stab       		: out std_logic_vector(C_NUM_SETS - 1 downto 0);
    update_tag_old_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    update_tag_new_DSid_vec_to_stab     : out std_logic_vector(C_DSID_WIDTH * C_NUM_SETS - 1 downto 0);
    lru_history_en_to_ptab              : out std_logic;
    lru_dsid_valid_to_ptab              : out std_logic;
    lru_dsid_to_ptab                    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    way_mask_from_ptab                  : in  std_logic_vector(C_NUM_SETS - 1 downto 0)
  );
end entity sc_cache_core;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_cache_core is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- The core of the System Cache functionality is implemented in the 
  -- sub-modules here.
  -- 
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_LOOKUP_ERROR              : natural :=  0;
  constant C_ASSERT_UPDATE_ERROR              : natural :=  1;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  2;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_SET_BITS                 : natural := Log2(C_NUM_SETS);
  constant C_SERIAL_SET_BITS          : natural := sel(C_NUM_SERIAL_SETS   = 1, 0, Log2(C_NUM_SERIAL_SETS));
  constant C_PARALLEL_SET_BITS        : natural := sel(C_NUM_PARALLEL_SETS = 1, 0, Log2(C_NUM_PARALLEL_SETS));
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Data related.
  subtype C_TAG_POS                   is natural range C_TAG_SIZE - 1                 downto 0;
  subtype C_BE_POS                    is natural range C_CACHE_DATA_WIDTH/8 - 1       downto 0;
  subtype C_DATA_POS                  is natural range C_CACHE_DATA_WIDTH - 1         downto 0;
  subtype C_CACHE_DATA_ADDR_POS       is natural range C_CACHE_DATA_ADDR_WIDTH - 1    downto 0;
  subtype C_EXT_BE_POS                is natural range C_EXTERNAL_DATA_WIDTH/8 - 1    downto 0;
  subtype C_EXT_DATA_POS              is natural range C_EXTERNAL_DATA_WIDTH - 1      downto 0;
  subtype C_EXT_DATA_ADDR_POS         is natural range C_EXTERNAL_DATA_ADDR_WIDTH - 1 downto 0;
  subtype TAG_TYPE                    is std_logic_vector(C_TAG_POS);
  subtype BE_TYPE                     is std_logic_vector(C_BE_POS);
  subtype DATA_TYPE                   is std_logic_vector(C_DATA_POS);
  subtype EXT_BE_TYPE                 is std_logic_vector(C_EXT_BE_POS);
  subtype EXT_DATA_TYPE               is std_logic_vector(C_EXT_DATA_POS);
  
  -- Port related.
  subtype C_PORT_POS                  is natural range C_NUM_PORTS - 1 downto 0;
  subtype PORT_TYPE                   is std_logic_vector(C_PORT_POS);
  type PORT_BE_TYPE                   is array(C_PORT_POS) of BE_TYPE;
  type PORT_DATA_TYPE                 is array(C_PORT_POS) of DATA_TYPE;
  
  -- Set related.
  subtype C_SET_POS                   is natural  range C_NUM_SETS - 1          downto 0;
  subtype C_SERIAL_SET_POS            is natural  range C_NUM_SERIAL_SETS - 1   downto 0;
  subtype C_PARALLEL_SET_POS          is rinteger range C_NUM_PARALLEL_SETS - 1 downto 0;
  subtype C_SET_BIT_POS               is natural  range C_SET_BIT_HI            downto C_SET_BIT_LO;
  subtype C_SERIAL_SET_BIT_POS        is natural  range C_SET_BITS - 1          downto C_SET_BITS - C_SERIAL_SET_BITS;
  subtype C_PARALLEL_SET_BIT_POS      is natural  range C_PARALLEL_SET_BITS - 1 downto 0;
  
  subtype SET_TYPE                    is std_logic_vector(C_SET_POS);
  subtype SERIAL_SET_TYPE             is std_logic_vector(C_SERIAL_SET_POS);
  subtype PARALLEL_SET_TYPE           is std_logic_vector(C_PARALLEL_SET_POS);
  subtype SET_BIT_TYPE                is std_logic_vector(C_SET_BIT_POS);
  subtype SERIAL_SET_BIT_TYPE         is std_logic_vector(C_SERIAL_SET_BIT_POS);
  subtype PARALLEL_SET_BIT_TYPE       is std_logic_vector(C_PARALLEL_SET_BIT_POS);
  
  type PARALLEL_TAG_TYPE              is array(C_PARALLEL_SET_POS) of TAG_TYPE;
  type PARALLEL_EXT_DATA_TYPE         is array(C_PARALLEL_SET_POS) of EXT_DATA_TYPE;
  
  -- Address related.
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI   downto C_ADDR_INTERNAL_LO;
  subtype C_ADDR_DIRECT_POS           is natural range C_ADDR_DIRECT_HI     downto C_ADDR_DIRECT_LO;
  subtype C_ADDR_EXT_DATA_POS         is natural range C_ADDR_EXT_DATA_HI   downto C_ADDR_EXT_DATA_LO;
  subtype C_ADDR_DATA_POS             is natural range C_ADDR_DATA_HI       downto C_ADDR_DATA_LO;
  subtype C_ADDR_TAG_POS              is natural range C_ADDR_TAG_HI        downto C_ADDR_TAG_LO;
  subtype C_ADDR_FULL_LINE_POS        is natural range C_ADDR_FULL_LINE_HI  downto C_ADDR_FULL_LINE_LO;
  subtype C_ADDR_LINE_POS             is natural range C_ADDR_LINE_HI       downto C_ADDR_LINE_LO;
  subtype C_ADDR_OFFSET_POS           is natural range C_ADDR_OFFSET_HI     downto C_ADDR_OFFSET_LO;
  subtype C_ADDR_EXT_WORD_POS         is natural range C_ADDR_EXT_WORD_HI   downto C_ADDR_EXT_WORD_LO;
  subtype C_ADDR_WORD_POS             is natural range C_ADDR_WORD_HI       downto C_ADDR_WORD_LO;
  subtype C_ADDR_EXT_BYTE_POS         is natural range C_ADDR_EXT_BYTE_HI   downto C_ADDR_EXT_BYTE_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  subtype ADDR_INTERNAL_TYPE          is std_logic_vector(C_ADDR_INTERNAL_POS);
  subtype ADDR_DIRECT_TYPE            is std_logic_vector(C_ADDR_DIRECT_POS);
  subtype ADDR_EXT_DATA_TYPE          is std_logic_vector(C_ADDR_EXT_DATA_POS);
  subtype ADDR_DATA_TYPE              is std_logic_vector(C_ADDR_DATA_POS);
  subtype ADDR_TAG_TYPE               is std_logic_vector(C_ADDR_TAG_POS);
  subtype ADDR_FULL_LINE_TYPE         is std_logic_vector(C_ADDR_FULL_LINE_POS);
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_EXT_WORD_TYPE          is std_logic_vector(C_ADDR_EXT_WORD_POS);
  subtype ADDR_WORD_TYPE              is std_logic_vector(C_ADDR_WORD_POS);
  subtype ADDR_EXT_BYTE_TYPE          is std_logic_vector(C_ADDR_EXT_BYTE_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  -- Ranges for TAG information parts.
  constant C_NUM_ADDR_TAG_BITS        : natural := C_TAG_SIZE - C_NUM_STATUS_BITS - C_DSID_WIDTH;
  constant C_TAG_VALID_POS            : natural := C_NUM_ADDR_TAG_BITS + 3;
  constant C_TAG_REUSED_POS           : natural := C_NUM_ADDR_TAG_BITS + 2;
  constant C_TAG_DIRTY_POS            : natural := C_NUM_ADDR_TAG_BITS + 1;
  constant C_TAG_LOCKED_POS           : natural := C_NUM_ADDR_TAG_BITS + 0;
  subtype C_TAG_ADDR_POS              is natural range C_NUM_ADDR_TAG_BITS - 1 downto 0;
  subtype TAG_ADDR_TYPE               is std_logic_vector(C_TAG_ADDR_POS);
  subtype C_TAG_DSID_POS              is natural range C_TAG_SIZE - 1 downto C_NUM_ADDR_TAG_BITS + C_NUM_STATUS_BITS;
  
  constant C_TAG_FORCE_BRAM           : boolean := (C_ADDR_FULL_LINE_HI - C_ADDR_FULL_LINE_LO + 1) >= 8;

  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_lookup is
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
      C_NUM_SETS                : natural range  2 to   32      :=  2;
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
      
      lookup_piperun            : out std_logic;
      
      lu_check_valid_to_stab    : out std_logic;
      lookup_DSid_to_stab       : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      lookup_hit_to_stab        : out std_logic;
      lookup_miss_to_stab       : out std_logic;
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
      
      stat_reset                      : in  std_logic;
      stat_enable                     : in  std_logic;
      
      stat_lu_opt_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      stat_lu_opt_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
      
      stat_lu_gen_write_hit           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss          : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_write_miss_dirty    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_hit            : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss           : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_read_miss_dirty     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_write_hit    : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_locked_read_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      stat_lu_gen_first_write_hit     : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
      
      stat_lu_stall                   : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_fetch_stall             : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_mem_stall               : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_stall              : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_hit_stall          : out STAT_POINT_TYPE;    -- Time per occurance
      stat_lu_data_miss_stall         : out STAT_POINT_TYPE;    -- Time per occurance
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      LOOKUP_DEBUG              : out std_logic_vector(255 downto 0)
    );
  end component sc_lookup;
  
  component sc_lru_module is
    generic (
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_ADDR_SIZE_LOG2          : natural := 5;
      C_LINE_SIZE_LOG2          : natural := 2
    );
    port (
      -- Global signals.
      Clk                       : in  std_logic;
      Reset                     : in  std_logic;
      
      -- Pipe control.
      lookup_fetch_piperun      : in  std_logic;
      lookup_mem_piperun        : in  std_logic;
      
      -- Peek LRU.
      lru_fetch_line_addr       : in  std_logic_vector(C_ADDR_SIZE_LOG2 - 1 downto 0);
      lru_check_next_set        : out std_logic_vector(C_LINE_SIZE_LOG2 - 1 downto 0);
      lru_check_next_hot_set    : out std_logic_vector(2**C_LINE_SIZE_LOG2 - 1 downto 0);
      way_mask_from_ptab        : in  std_logic_vector(2**C_LINE_SIZE_LOG2 - 1 downto 0);
      
      -- Control LRU.
      lru_check_use_lru         : in  std_logic;
      lru_check_line_addr       : in  std_logic_vector(C_ADDR_SIZE_LOG2 - 1 downto 0);
      lru_check_used_set        : in  std_logic_vector(C_LINE_SIZE_LOG2 - 1 downto 0);
      
      -- After refresh.
      lru_update_prev_lru_set   : out std_logic_vector(C_LINE_SIZE_LOG2 - 1 downto 0);
      lru_update_new_lru_set    : out std_logic_vector(C_LINE_SIZE_LOG2 - 1 downto 0)
    );
  end component sc_lru_module;
  
  component sc_update is
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
      C_NUM_PORTS               : natural range  1 to   32      :=  1;
      C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
      C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
      C_NUM_SETS                : natural range  1 to   32      :=  2;
      C_NUM_SERIAL_SETS         : natural range  1 to    8      :=  2;
      C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
      C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
      
      -- Data type and settings specific.
      C_TAG_SIZE                : natural range  3 to   96      := 15;
      C_NUM_STATUS_BITS         : natural range  4 to    4      :=  4;
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- For PARD
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_CACHE_DATA_ADDR_WIDTH   : natural range  2 to    7      :=  2;
      C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
      C_EXTERNAL_DATA_ADDR_WIDTH: natural range  2 to    7      :=  2;
      C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
      C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
      C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
      C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
      C_ADDR_EXT_DATA_HI        : natural range  2 to   63      := 14;
      C_ADDR_EXT_DATA_LO        : natural range  2 to   63      :=  2;
      C_ADDR_TAG_HI             : natural range  4 to   63      := 27;
      C_ADDR_TAG_LO             : natural range  4 to   63      := 14;
      C_ADDR_FULL_LINE_HI       : natural range  4 to   63      := 14;
      C_ADDR_FULL_LINE_LO       : natural range  4 to   63      :=  7;
      C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
      C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
      C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
      C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
      C_ADDR_EXT_WORD_HI        : natural range  2 to   63      :=  6;
      C_ADDR_EXT_WORD_LO        : natural range  2 to   63      :=  2;
      C_ADDR_WORD_HI            : natural range  2 to   63      :=  6;
      C_ADDR_WORD_LO            : natural range  2 to   63      :=  2;
      C_ADDR_EXT_BYTE_HI        : natural range  0 to   63      :=  1;
      C_ADDR_EXT_BYTE_LO        : natural range  0 to   63      :=  0;
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
      access_data_valid         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_last          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      access_data_be            : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      access_data_word          : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Lookup signals.
      
      -- Tag Addr Check.
      lookup_new_addr           : in  std_logic_vector(C_ADDR_LINE_HI downto C_ADDR_LINE_LO);
      
      -- Write Miss
      lookup_push_write_miss    : in  std_logic;
      lookup_wm_allocate        : in  std_logic;
      lookup_wm_evict           : in  std_logic;
      lookup_wm_will_use        : in  std_logic;
      lookup_wm_info            : in  ACCESS_TYPE;
      lookup_wm_use_bits        : in  std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      lookup_wm_stp_bits        : in  std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      lookup_wm_allow_write     : in  std_logic;
      
      -- Update transaction.
      update_valid              : in  std_logic;
      update_set                : in  std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
      update_info               : in  ACCESS_TYPE;
      update_use_bits           : in  std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      update_stp_bits           : in  std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
      update_hit                : in  std_logic;
      update_miss               : in  std_logic;
      update_read_hit           : in  std_logic;
      update_read_miss          : in  std_logic;
      update_read_miss_dirty    : in  std_logic;
      update_write_hit          : in  std_logic;
      update_write_miss         : in  std_logic;
      update_write_miss_dirty   : in  std_logic;
      update_locked_write_hit   : in  std_logic;
      update_locked_read_hit    : in  std_logic;
      update_first_write_hit    : in  std_logic;
      update_evict_hit          : in  std_logic;
      update_exclusive_hit      : in  std_logic;
      update_early_bresp        : in  std_logic;
      update_need_bs            : in  std_logic;
      update_need_ar            : in  std_logic;
      update_need_aw            : in  std_logic;
      update_need_evict         : in  std_logic;
      update_need_tag_write     : in  std_logic;
      update_reused_tag         : in  std_logic;
      update_old_tag            : in  std_logic_vector(C_TAG_SIZE - 1 downto 0);
      update_refreshed_lru      : in  std_logic;
      update_all_tags           : in  std_logic_vector(C_NUM_SETS * C_TAG_SIZE - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- LRU signals.
      
      lru_update_prev_lru_set   : in  std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
      lru_update_new_lru_set    : in  std_logic_vector(C_SET_BIT_HI downto C_SET_BIT_LO);
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push    : out std_logic;
      update_auto_clean_addr    : out AXI_ADDR_TYPE;
      update_auto_clean_DSid    : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      -- ---------------------------------------------------
      -- Backend signals.
      
      backend_wr_resp_valid     : in  std_logic;
      backend_wr_resp_port      : out natural range 0 to C_NUM_PORTS - 1;
      backend_wr_resp_internal  : out std_logic;
      backend_wr_resp_addr      : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      backend_wr_resp_bresp     : in  std_logic_vector(2 - 1 downto 0);
      backend_wr_resp_ready     : out std_logic;
      
      backend_rd_data_valid     : in  std_logic;
      backend_rd_data_last      : in  std_logic;
      backend_rd_data_word      : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      backend_rd_data_rresp     : in  std_logic_vector(2 - 1 downto 0);
      backend_rd_data_ready     : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Update signals (to Frontend).
      
      -- Read miss
      update_read_data_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      update_read_data_last     : out std_logic;
      update_read_data_resp     : out std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
      update_read_data_word     : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      update_read_data_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      -- Write Miss
      update_write_data_ready   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      -- Write miss response
      update_ext_bresp_valid    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      update_ext_bresp          : out std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Update signals (to Lookup).
      
      update_tag_conflict       : out std_logic;
      update_piperun            : out std_logic;
      
      update_write_miss_full    : out std_logic;
      update_write_miss_busy    : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Update signals (to Tag & Data).
      
      update_tag_addr           : out std_logic_vector(C_ADDR_FULL_LINE_HI downto C_ADDR_FULL_LINE_LO);
      update_tag_en             : out std_logic;
      update_tag_we             : out std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
      update_tag_new_word       : out std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
      update_tag_current_word   : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
      
      update_data_addr          : out std_logic_vector(C_ADDR_EXT_DATA_HI downto C_ADDR_EXT_DATA_LO);
      update_data_en            : out std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
      update_data_we            : out std_logic_vector(0 downto 0);
      update_data_new_word      : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      update_data_current_word  : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Update signals (to Backend).
      
      read_req_valid            : out std_logic;
      read_req_port             : out natural range 0 to C_NUM_PORTS - 1;
      read_req_addr             : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      read_req_len              : out std_logic_vector(8 - 1 downto 0);
      read_req_size             : out std_logic_vector(3 - 1 downto 0);
      read_req_exclusive        : out std_logic;
      read_req_kind             : out std_logic;
      read_req_ready            : in  std_logic;
      read_req_DSid             : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_req_valid           : out std_logic;
      write_req_port            : out natural range 0 to C_NUM_PORTS - 1;
      write_req_internal        : out std_logic;
      write_req_addr            : out std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      write_req_len             : out std_logic_vector(8 - 1 downto 0);
      write_req_size            : out std_logic_vector(3 - 1 downto 0);
      write_req_exclusive       : out std_logic;
      write_req_kind            : out std_logic;
      write_req_line_only       : out std_logic;
      write_req_ready           : in  std_logic;
      write_req_DSid            : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      write_data_valid          : out std_logic;
      write_data_last           : out std_logic;
      write_data_be             : out std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
      write_data_word           : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      write_data_ready          : in  std_logic;
      write_data_almost_full    : in  std_logic;
      write_data_full           : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      stat_ud_stall             : out STAT_POINT_TYPE;    -- Time transactions are stalled
      stat_ud_tag_free          : out STAT_POINT_TYPE;    -- Cycles tag is free
      stat_ud_data_free         : out STAT_POINT_TYPE;    -- Cycles data is free
      stat_ud_ri                : out STAT_FIFO_TYPE;     -- Read Information
      stat_ud_r                 : out STAT_FIFO_TYPE;     -- Read data (optional)
      stat_ud_e                 : out STAT_FIFO_TYPE;     -- Evict
      stat_ud_bs                : out STAT_FIFO_TYPE;     -- BRESP Source
      stat_ud_wm                : out STAT_FIFO_TYPE;     -- Write Miss
      stat_ud_wma               : out STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      UPDATE_DEBUG1             : out std_logic_vector(255 downto 0);
      UPDATE_DEBUG2             : out std_logic_vector(255 downto 0)
    );
  end component sc_update;
  
  component sc_ram_module is
    generic (
      C_TARGET        : TARGET_FAMILY_TYPE;
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
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- 
  
  -- Update signals.
  signal update_tag_conflict       : std_logic;
  signal update_piperun            : std_logic;
  signal update_write_miss_full    : std_logic;
  signal update_write_miss_busy    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  -- Lookup signals (to Tag & Data).
  signal lookup_tag_addr           : ADDR_FULL_LINE_TYPE;
  signal lookup_tag_en             : std_logic;
  signal lookup_tag_we             : std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
  signal lookup_tag_new_word       : std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
  signal lookup_tag_current_word   : std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
  
  signal lookup_data_addr          : ADDR_DATA_TYPE;
  signal lookup_data_en            : std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
  signal lookup_data_we            : BE_TYPE;
  signal lookup_data_new_word      : DATA_TYPE;
  signal lookup_data_current_word  : std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
  
  
  -- Lookup signals (to LRU).
  signal lookup_fetch_piperun      : std_logic;
  signal lookup_mem_piperun        : std_logic;
  signal lru_fetch_line_addr       : ADDR_LINE_TYPE;
  signal lru_check_next_set        : SET_BIT_TYPE;
  signal lru_check_next_hot_set    : SET_TYPE;
  signal lru_check_use_lru         : std_logic;
  signal lru_check_line_addr       : ADDR_LINE_TYPE;
  signal lru_check_used_set        : SET_BIT_TYPE;
  
  -- LRU signals to update.
  signal lru_update_prev_lru_set   : SET_BIT_TYPE;
  signal lru_update_new_lru_set    : SET_BIT_TYPE;
  
  
  -- Lookup signals (to Update).
  signal lookup_new_addr           : ADDR_LINE_TYPE;
  
  signal lookup_push_write_miss    : std_logic;
  signal lookup_wm_allocate        : std_logic;
  signal lookup_wm_evict           : std_logic;
  signal lookup_wm_will_use        : std_logic;
  signal lookup_wm_info            : ACCESS_TYPE;
  signal lookup_wm_use_bits        : ADDR_OFFSET_TYPE;
  signal lookup_wm_stp_bits        : ADDR_OFFSET_TYPE;
  signal lookup_wm_allow_write     : std_logic;
  
  signal update_valid              : std_logic;
  signal update_set                : SET_BIT_TYPE;
  signal update_info               : ACCESS_TYPE;
  signal update_use_bits           : ADDR_OFFSET_TYPE;
  signal update_stp_bits           : ADDR_OFFSET_TYPE;
  signal update_hit                : std_logic;
  signal update_miss               : std_logic;
  signal update_read_hit           : std_logic;
  signal update_read_miss          : std_logic;
  signal update_read_miss_dirty    : std_logic;
  signal update_write_hit          : std_logic;
  signal update_write_miss         : std_logic;
  signal update_write_miss_dirty   : std_logic;
  signal update_locked_write_hit   : std_logic;
  signal update_locked_read_hit    : std_logic;
  signal update_first_write_hit    : std_logic;
  signal update_evict_hit          : std_logic;
  signal update_exclusive_hit      : std_logic;
  signal update_early_bresp        : std_logic;
  signal update_need_bs            : std_logic;
  signal update_need_ar            : std_logic;
  signal update_need_aw            : std_logic;
  signal update_need_evict         : std_logic;
  signal update_need_tag_write     : std_logic;
  signal update_reused_tag         : std_logic;
  signal update_old_tag            : std_logic_vector(C_TAG_SIZE - 1 downto 0);
  signal update_refreshed_lru      : std_logic;
  signal update_all_tags           : std_logic_vector(C_NUM_SETS * C_TAG_SIZE - 1 downto 0);
  
  
  -- ---------------------------------------------------
  -- 
  
  signal update_tag_addr           : ADDR_FULL_LINE_TYPE;
  signal update_tag_en             : std_logic;
  signal update_tag_we             : std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
  signal update_tag_new_word       : std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
  signal update_tag_current_word   : std_logic_vector(C_NUM_PARALLEL_SETS * C_TAG_SIZE - 1 downto 0);
  
  signal update_data_addr          : ADDR_EXT_DATA_TYPE;
  signal update_data_en            : std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0);
  signal update_data_we            : std_logic_vector(0 downto 0);
  signal update_data_new_word      : EXT_DATA_TYPE;
  signal update_data_current_word  : std_logic_vector(C_NUM_PARALLEL_SETS * C_EXTERNAL_DATA_WIDTH - 1 downto 0);
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal lookup_assert              : std_logic;
  signal update_assert              : std_logic;
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  signal update_tag_current_word_i  : PARALLEL_TAG_TYPE;
  signal update_tag_new_word_i      : PARALLEL_TAG_TYPE;

  signal lu_check_valid_to_stab_wire     : std_logic;
  signal lookup_DSid_to_stab_wire        : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  signal lookup_miss_to_stab_wire        : std_logic;
  signal lookup_hit_to_stab_wire         : std_logic;
  signal update_old_DSid_vec_wire        : std_logic_vector(C_NUM_PARALLEL_SETS * C_DSID_WIDTH - 1 downto 0);
  signal update_new_DSid_vec_wire        : std_logic_vector(C_NUM_PARALLEL_SETS * C_DSID_WIDTH - 1 downto 0);
begin  -- architecture IMP


  -----------------------------------------------------------------------------
  -- Lookup Instance
  -----------------------------------------------------------------------------
  
  LU: sc_lookup
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- IP Specific.
      C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
      C_NUM_OPTIMIZED_PORTS     => C_NUM_OPTIMIZED_PORTS,
      C_NUM_GENERIC_PORTS       => C_NUM_GENERIC_PORTS,
      C_NUM_PORTS               => C_NUM_PORTS,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON,
      C_NUM_SETS                => C_NUM_SETS,
      C_NUM_SERIAL_SETS         => C_NUM_SERIAL_SETS,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_ID_WIDTH                => C_ID_WIDTH,
      
      -- Data type and settings specific.
      C_TAG_SIZE                => C_TAG_SIZE,
      C_NUM_STATUS_BITS         => C_NUM_STATUS_BITS,
      C_DSID_WIDTH              => C_DSID_WIDTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_CACHE_DATA_ADDR_WIDTH   => C_CACHE_DATA_ADDR_WIDTH,
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_POS'high,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_POS'low,
      C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
      C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
      C_ADDR_DATA_HI            => C_ADDR_DATA_POS'high,
      C_ADDR_DATA_LO            => C_ADDR_DATA_POS'low,
      C_ADDR_TAG_HI             => C_ADDR_TAG_POS'high,
      C_ADDR_TAG_LO             => C_ADDR_TAG_POS'low,
      C_ADDR_FULL_LINE_HI       => C_ADDR_FULL_LINE_POS'high,
      C_ADDR_FULL_LINE_LO       => C_ADDR_FULL_LINE_POS'low,
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_WORD_HI            => C_ADDR_WORD_POS'high,
      C_ADDR_WORD_LO            => C_ADDR_WORD_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      C_SET_BIT_HI              => C_SET_BIT_POS'high,
      C_SET_BIT_LO              => C_SET_BIT_POS'low
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Access signals.
      
      access_valid              => access_valid,
      access_info               => access_info,
      access_use                => access_use,
      access_stp                => access_stp,
      access_id                 => access_id,
      
      access_data_valid         => access_data_valid,
      access_data_last          => access_data_last,
      access_data_be            => access_data_be,
      access_data_word          => access_data_word,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      => lookup_read_data_new,
      lookup_read_data_hit      => lookup_read_data_hit,
      lookup_read_data_snoop    => lookup_read_data_snoop,
      lookup_read_data_allocate => lookup_read_data_allocate,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     => read_info_almost_full,
      read_info_full            => read_info_full,
      read_data_hit_pop         => read_data_hit_pop,
      read_data_hit_almost_full => read_data_hit_almost_full,
      read_data_hit_full        => read_data_hit_full,
      read_data_hit_fit         => read_data_hit_fit,
      
      
      -- ---------------------------------------------------
      -- Update signals.
      
      update_tag_conflict       => update_tag_conflict,
      update_piperun            => update_piperun,
      update_write_miss_full    => update_write_miss_full,
      update_write_miss_busy    => update_write_miss_busy,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Access).
      
      lookup_piperun            => lookup_piperun,
      
      lu_check_valid_to_stab    => lu_check_valid_to_stab_wire,
      lookup_DSid_to_stab       => lookup_DSid_to_stab_wire,
      lookup_miss_to_stab       => lookup_miss_to_stab_wire,
      lookup_hit_to_stab        => lookup_hit_to_stab_wire,
      -- ---------------------------------------------------
      -- Lookup signals (to Frontend).
      
      lookup_read_data_valid    => lookup_read_data_valid,
      lookup_read_data_last     => lookup_read_data_last,
      lookup_read_data_resp     => lookup_read_data_resp,
      lookup_read_data_set      => lookup_read_data_set,
      lookup_read_data_word     => lookup_read_data_word,
      
      lookup_write_data_ready   => lookup_write_data_ready,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Tag & Data).
      
      lookup_tag_addr           => lookup_tag_addr,
      lookup_tag_en             => lookup_tag_en,
      lookup_tag_we             => lookup_tag_we,
      lookup_tag_new_word       => lookup_tag_new_word,
      lookup_tag_current_word   => lookup_tag_current_word,
      
      lookup_data_addr          => lookup_data_addr,
      lookup_data_en            => lookup_data_en,
      lookup_data_we            => lookup_data_we,
      lookup_data_new_word      => lookup_data_new_word,
      lookup_data_current_word  => lookup_data_current_word,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to Arbiter).
      
      lookup_read_done          => lookup_read_done,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (to LRU).
      
      -- Pipe control.
      lookup_fetch_piperun      => lookup_fetch_piperun,
      lookup_mem_piperun        => lookup_mem_piperun,
      
      -- Peek LRU.
      lru_fetch_line_addr       => lru_fetch_line_addr,
      lru_check_next_set        => lru_check_next_set,
      lru_check_next_hot_set    => lru_check_next_hot_set,
      
      -- Control LRU.
      lru_check_use_lru         => lru_check_use_lru,
      lru_check_line_addr       => lru_check_line_addr,
      lru_check_used_set        => lru_check_used_set,
        
        
      -- ---------------------------------------------------
      -- Lookup signals (to Update).
      
      lookup_new_addr           => lookup_new_addr,
      
      lookup_push_write_miss    => lookup_push_write_miss,
      lookup_wm_allocate        => lookup_wm_allocate,
      lookup_wm_evict           => lookup_wm_evict,
      lookup_wm_will_use        => lookup_wm_will_use,
      lookup_wm_info            => lookup_wm_info,
      lookup_wm_use_bits        => lookup_wm_use_bits,
      lookup_wm_stp_bits        => lookup_wm_stp_bits,
      lookup_wm_allow_write     => lookup_wm_allow_write,
      
      update_valid              => update_valid,
      update_set                => update_set,
      update_info               => update_info,
      update_use_bits           => update_use_bits,
      update_stp_bits           => update_stp_bits,
      update_hit                => update_hit,
      update_miss               => update_miss,
      update_read_hit           => update_read_hit,
      update_read_miss          => update_read_miss,
      update_read_miss_dirty    => update_read_miss_dirty,
      update_write_hit          => update_write_hit,
      update_write_miss         => update_write_miss,
      update_write_miss_dirty   => update_write_miss_dirty,
      update_locked_write_hit   => update_locked_write_hit,
      update_locked_read_hit    => update_locked_read_hit,
      update_first_write_hit    => update_first_write_hit,
      update_evict_hit          => update_evict_hit,
      update_exclusive_hit      => update_exclusive_hit,
      update_early_bresp        => update_early_bresp,
      update_need_bs            => update_need_bs,
      update_need_ar            => update_need_ar,
      update_need_aw            => update_need_aw,
      update_need_evict         => update_need_evict,
      update_need_tag_write     => update_need_tag_write,
      update_reused_tag         => update_reused_tag,
      update_old_tag            => update_old_tag,
      update_refreshed_lru      => update_refreshed_lru,
      update_all_tags           => update_all_tags,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                      => stat_reset,
      stat_enable                     => stat_enable,
      
      stat_lu_opt_write_hit           => stat_lu_opt_write_hit,
      stat_lu_opt_write_miss          => stat_lu_opt_write_miss,
      stat_lu_opt_write_miss_dirty    => stat_lu_opt_write_miss_dirty,
      stat_lu_opt_read_hit            => stat_lu_opt_read_hit,
      stat_lu_opt_read_miss           => stat_lu_opt_read_miss,
      stat_lu_opt_read_miss_dirty     => stat_lu_opt_read_miss_dirty,
      stat_lu_opt_locked_write_hit    => stat_lu_opt_locked_write_hit,
      stat_lu_opt_locked_read_hit     => stat_lu_opt_locked_read_hit,
      stat_lu_opt_first_write_hit     => stat_lu_opt_first_write_hit,
      
      stat_lu_gen_write_hit           => stat_lu_gen_write_hit,
      stat_lu_gen_write_miss          => stat_lu_gen_write_miss,
      stat_lu_gen_write_miss_dirty    => stat_lu_gen_write_miss_dirty,
      stat_lu_gen_read_hit            => stat_lu_gen_read_hit,
      stat_lu_gen_read_miss           => stat_lu_gen_read_miss,
      stat_lu_gen_read_miss_dirty     => stat_lu_gen_read_miss_dirty,
      stat_lu_gen_locked_write_hit    => stat_lu_gen_locked_write_hit,
      stat_lu_gen_locked_read_hit     => stat_lu_gen_locked_read_hit,
      stat_lu_gen_first_write_hit     => stat_lu_gen_first_write_hit,
      
      stat_lu_stall                   => stat_lu_stall,
      stat_lu_fetch_stall             => stat_lu_fetch_stall,
      stat_lu_mem_stall               => stat_lu_mem_stall,
      stat_lu_data_stall              => stat_lu_data_stall,
      stat_lu_data_hit_stall          => stat_lu_data_hit_stall,
      stat_lu_data_miss_stall         => stat_lu_data_miss_stall,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => lookup_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      LOOKUP_DEBUG              => LOOKUP_DEBUG
    );
  
  
  -----------------------------------------------------------------------------
  -- Update Instance
  -----------------------------------------------------------------------------
  
  UD: sc_update
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- IP Specific.
      C_NUM_PORTS               => C_NUM_PORTS,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY,
      C_ENABLE_EX_MON           => C_ENABLE_EX_MON,
      C_NUM_SETS                => C_NUM_SETS,
      C_NUM_SERIAL_SETS         => C_NUM_SERIAL_SETS,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_CACHE_LINE_LENGTH       => C_CACHE_LINE_LENGTH,
      
      -- Data type and settings specific.
      C_TAG_SIZE                => C_TAG_SIZE,
      C_NUM_STATUS_BITS         => C_NUM_STATUS_BITS,
      C_DSID_WIDTH              => C_DSID_WIDTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_CACHE_DATA_ADDR_WIDTH   => C_CACHE_DATA_ADDR_WIDTH,
      C_EXTERNAL_DATA_WIDTH     => C_EXTERNAL_DATA_WIDTH,
      C_EXTERNAL_DATA_ADDR_WIDTH=> C_EXTERNAL_DATA_ADDR_WIDTH,
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_POS'high,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_POS'low,
      C_ADDR_DIRECT_HI          => C_ADDR_DIRECT_POS'high,
      C_ADDR_DIRECT_LO          => C_ADDR_DIRECT_POS'low,
      C_ADDR_EXT_DATA_HI        => C_ADDR_EXT_DATA_POS'high,
      C_ADDR_EXT_DATA_LO        => C_ADDR_EXT_DATA_POS'low,
      C_ADDR_TAG_HI             => C_ADDR_TAG_POS'high,
      C_ADDR_TAG_LO             => C_ADDR_TAG_POS'low,
      C_ADDR_FULL_LINE_HI       => C_ADDR_FULL_LINE_POS'high,
      C_ADDR_FULL_LINE_LO       => C_ADDR_FULL_LINE_POS'low,
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_EXT_WORD_HI        => C_ADDR_EXT_WORD_POS'high,
      C_ADDR_EXT_WORD_LO        => C_ADDR_EXT_WORD_POS'low,
      C_ADDR_WORD_HI            => C_ADDR_WORD_POS'high,
      C_ADDR_WORD_LO            => C_ADDR_WORD_POS'low,
      C_ADDR_EXT_BYTE_HI        => C_ADDR_EXT_BYTE_POS'high,
      C_ADDR_EXT_BYTE_LO        => C_ADDR_EXT_BYTE_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      C_SET_BIT_HI              => C_SET_BIT_POS'high,
      C_SET_BIT_LO              => C_SET_BIT_POS'low
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
  
      -- ---------------------------------------------------
      -- Access signals.
      
      access_valid              => access_valid,
      access_data_valid         => access_data_valid,
      access_data_last          => access_data_last,
      access_data_be            => access_data_be,
      access_data_word          => access_data_word,
      
      
      -- ---------------------------------------------------
      -- Lookup signals.
      
      -- Tag Addr Check.
      lookup_new_addr           => lookup_new_addr,
      
      -- Write Miss
      lookup_push_write_miss    => lookup_push_write_miss,
      lookup_wm_allocate        => lookup_wm_allocate,
      lookup_wm_evict           => lookup_wm_evict,
      lookup_wm_will_use        => lookup_wm_will_use,
      lookup_wm_info            => lookup_wm_info,
      lookup_wm_use_bits        => lookup_wm_use_bits,
      lookup_wm_stp_bits        => lookup_wm_stp_bits,
      lookup_wm_allow_write     => lookup_wm_allow_write,
      
      -- Update transaction.
      update_valid              => update_valid,
      update_set                => update_set,
      update_info               => update_info,
      update_use_bits           => update_use_bits,
      update_stp_bits           => update_stp_bits,
      update_hit                => update_hit,
      update_miss               => update_miss,
      update_read_hit           => update_read_hit,
      update_read_miss          => update_read_miss,
      update_read_miss_dirty    => update_read_miss_dirty,
      update_write_hit          => update_write_hit,
      update_write_miss         => update_write_miss,
      update_write_miss_dirty   => update_write_miss_dirty,
      update_locked_write_hit   => update_locked_write_hit,
      update_locked_read_hit    => update_locked_read_hit,
      update_first_write_hit    => update_first_write_hit,
      update_evict_hit          => update_evict_hit,
      update_exclusive_hit      => update_exclusive_hit,
      update_early_bresp        => update_early_bresp,
      update_need_bs            => update_need_bs,
      update_need_ar            => update_need_ar,
      update_need_aw            => update_need_aw,
      update_need_evict         => update_need_evict,
      update_need_tag_write     => update_need_tag_write,
      update_reused_tag         => update_reused_tag,
      update_old_tag            => update_old_tag,
      update_refreshed_lru      => update_refreshed_lru,
      update_all_tags           => update_all_tags,
      
      
      -- ---------------------------------------------------
      -- LRU signals.
      
      lru_update_prev_lru_set   => lru_update_prev_lru_set,
      lru_update_new_lru_set    => lru_update_new_lru_set,
      
      
      -- ---------------------------------------------------
      -- Automatic Clean Information.
      
      update_auto_clean_push    => update_auto_clean_push,
      update_auto_clean_addr    => update_auto_clean_addr,
      update_auto_clean_DSid    => update_auto_clean_DSid,
      
      -- ---------------------------------------------------
      -- Backend signals.
      
      backend_wr_resp_valid     => backend_wr_resp_valid,
      backend_wr_resp_port      => backend_wr_resp_port,
      backend_wr_resp_internal  => backend_wr_resp_internal,
      backend_wr_resp_addr      => backend_wr_resp_addr,
      backend_wr_resp_bresp     => backend_wr_resp_bresp,
      backend_wr_resp_ready     => backend_wr_resp_ready,
      
      backend_rd_data_valid     => backend_rd_data_valid,
      backend_rd_data_last      => backend_rd_data_last,
      backend_rd_data_word      => backend_rd_data_word,
      backend_rd_data_rresp     => backend_rd_data_rresp,
      backend_rd_data_ready     => backend_rd_data_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Frontend).
      
      -- Read miss
      update_read_data_valid    => update_read_data_valid,
      update_read_data_last     => update_read_data_last,
      update_read_data_resp     => update_read_data_resp,
      update_read_data_word     => update_read_data_word,
      update_read_data_ready    => update_read_data_ready,
      
      -- Write Miss
      update_write_data_ready   => update_write_data_ready,
      
      -- Write miss response
      update_ext_bresp_valid    => update_ext_bresp_valid,
      update_ext_bresp          => update_ext_bresp,
      update_ext_bresp_ready    => update_ext_bresp_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Lookup).
      
      update_tag_conflict       => update_tag_conflict,
      update_piperun            => update_piperun,
      
      update_write_miss_full    => update_write_miss_full,
      update_write_miss_busy    => update_write_miss_busy,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Tag & Data).
      
      update_tag_addr           => update_tag_addr,
      update_tag_en             => update_tag_en,
      update_tag_we             => update_tag_we,
      update_tag_new_word       => update_tag_new_word,
      update_tag_current_word   => update_tag_current_word,
      
      update_data_addr          => update_data_addr,
      update_data_en            => update_data_en,
      update_data_we            => update_data_we,
      update_data_new_word      => update_data_new_word,
      update_data_current_word  => update_data_current_word,
      
      
      -- ---------------------------------------------------
      -- Update signals (to Backend).
      
      read_req_valid            => read_req_valid,
      read_req_port             => read_req_port,
      read_req_addr             => read_req_addr,
      read_req_len              => read_req_len,
      read_req_size             => read_req_size,
      read_req_exclusive        => read_req_exclusive,
      read_req_kind             => read_req_kind,
      read_req_ready            => read_req_ready,
      read_req_DSid             => read_req_DSid,
      
      write_req_valid           => write_req_valid,
      write_req_port            => write_req_port,
      write_req_internal        => write_req_internal,
      write_req_addr            => write_req_addr,
      write_req_len             => write_req_len,
      write_req_size            => write_req_size,
      write_req_exclusive       => write_req_exclusive,
      write_req_kind            => write_req_kind,
      write_req_line_only       => write_req_line_only,
      write_req_ready           => write_req_ready,
      write_req_DSid            => write_req_DSid,
      
      write_data_valid          => write_data_valid,
      write_data_last           => write_data_last,
      write_data_be             => write_data_be,
      write_data_word           => write_data_word,
      write_data_ready          => write_data_ready,
      write_data_almost_full    => write_data_almost_full,
      write_data_full           => write_data_full,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_ud_stall             => stat_ud_stall,
      stat_ud_tag_free          => stat_ud_tag_free,
      stat_ud_data_free         => stat_ud_data_free,
      stat_ud_ri                => stat_ud_ri,
      stat_ud_r                 => stat_ud_r,
      stat_ud_e                 => stat_ud_e,
      stat_ud_bs                => stat_ud_bs,
      stat_ud_wm                => stat_ud_wm,
      stat_ud_wma               => stat_ud_wma,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => update_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      UPDATE_DEBUG1             => UPDATE_DEBUG1,
      UPDATE_DEBUG2             => UPDATE_DEBUG2
    );
  
  
  -----------------------------------------------------------------------------
  -- LRU Instance
  -----------------------------------------------------------------------------
  
  LRU: sc_lru_module
    generic map(
      C_TARGET                  => C_TARGET,
      C_ADDR_SIZE_LOG2          => C_LRU_ADDR_BITS,
      C_LINE_SIZE_LOG2          => C_SET_BITS
    )
    port map(
      -- Global signals.
      Clk                       => ACLK,
      Reset                     => ARESET,
      
      -- Pipe control.
      lookup_fetch_piperun      => lookup_fetch_piperun,
      lookup_mem_piperun        => lookup_mem_piperun,
      
      -- Peek LRU.
      lru_fetch_line_addr       => lru_fetch_line_addr,
      lru_check_next_set        => lru_check_next_set,
      lru_check_next_hot_set    => lru_check_next_hot_set,
      way_mask_from_ptab        => way_mask_from_ptab,
      
      -- Control LRU.
      lru_check_use_lru         => lru_check_use_lru,
      lru_check_line_addr       => lru_check_line_addr,
      lru_check_used_set        => lru_check_used_set,
      
      -- After refresh.
      lru_update_prev_lru_set   => lru_update_prev_lru_set,
      lru_update_new_lru_set    => lru_update_new_lru_set
    );
  
  
  -----------------------------------------------------------------------------
  -- TAG Instance
  -----------------------------------------------------------------------------
  
  TAG: sc_ram_module 
    generic map(
      C_TARGET                  => C_TARGET,
      C_WE_A_WIDTH              => C_NUM_PARALLEL_SETS,
      C_DATA_A_WIDTH            => C_NUM_PARALLEL_SETS * C_TAG_SIZE,
      C_ADDR_A_WIDTH            => ADDR_FULL_LINE_TYPE'length,
      C_WE_B_WIDTH              => C_NUM_PARALLEL_SETS,
      C_DATA_B_WIDTH            => C_NUM_PARALLEL_SETS * C_TAG_SIZE,
      C_ADDR_B_WIDTH            => ADDR_FULL_LINE_TYPE'length,
      C_FORCE_BRAM              => C_TAG_FORCE_BRAM,
      C_FORCE_LUTRAM            => false
    )
    port map(
      -- PORT A
      CLKA                      => ACLK,
      ENA                       => lookup_tag_en,
      WEA                       => lookup_tag_we,
      ADDRA                     => lookup_tag_addr,
      DATA_INA                  => lookup_tag_new_word,
      DATA_OUTA                 => lookup_tag_current_word,
      -- PORT B
      CLKB                      => ACLK,
      ENB                       => update_tag_en,
      WEB                       => update_tag_we,
      ADDRB                     => update_tag_addr,
      DATA_INB                  => update_tag_new_word,
      DATA_OUTB                 => update_tag_current_word
    );
  
  
  -----------------------------------------------------------------------------
  -- Data Instance(s)
  -----------------------------------------------------------------------------
  
  Gen_Parallel_Data: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    DATA: sc_ram_module 
      generic map(
        C_TARGET                  => C_TARGET,
        C_WE_A_WIDTH              => C_CACHE_DATA_WIDTH / 8,
        C_DATA_A_WIDTH            => C_CACHE_DATA_WIDTH,
        C_ADDR_A_WIDTH            => ADDR_DATA_TYPE'length,
        C_WE_B_WIDTH              => 1,
        C_DATA_B_WIDTH            => C_EXTERNAL_DATA_WIDTH,
        C_ADDR_B_WIDTH            => ADDR_EXT_DATA_TYPE'length,
        C_FORCE_BRAM              => true,
        C_FORCE_LUTRAM            => false
      )
      port map(
        -- PORT A
        CLKA                      => ACLK,
        ENA                       => lookup_data_en(I),
        WEA                       => lookup_data_we,
        ADDRA                     => lookup_data_addr,
        DATA_INA                  => lookup_data_new_word,
        DATA_OUTA                 => lookup_data_current_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto 
                                                                  I * C_CACHE_DATA_WIDTH),
        -- PORT B
        CLKB                      => ACLK,
        ENB                       => update_data_en(I),
        WEB                       => update_data_we,
        ADDRB                     => update_data_addr,
        DATA_INB                  => update_data_new_word,
        DATA_OUTB                 => update_data_current_word((I+1) * C_EXTERNAL_DATA_WIDTH - 1 downto 
                                                                  I * C_EXTERNAL_DATA_WIDTH)
      );
  
  end generate Gen_Parallel_Data;
  
  
  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    MEMORY_DEBUG1 <= (others=>'0');
    MEMORY_DEBUG2 <= (others=>'0');
  end generate No_Debug;
  
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_TLINE   : natural := min_of(10, C_ADDR_FULL_LINE_HI - C_ADDR_FULL_LINE_LO + 1);
    constant C_MY_DLINE   : natural := min_of(14, C_ADDR_DATA_HI - C_ADDR_DATA_LO + 1);
    constant C_MY_DELINE  : natural := min_of(14, C_ADDR_EXT_DATA_HI - C_ADDR_EXT_DATA_LO + 1);
    constant C_MY_TAG     : natural := min_of(16, C_TAG_SIZE);
    constant C_MY_TAGIN   : natural := min_of(32, C_TAG_SIZE);
    constant C_MY_DATA    : natural := min_of(32, C_CACHE_DATA_WIDTH);
    constant C_MY_WE      : natural := min_of( 4, C_CACHE_DATA_WIDTH/8);
    constant C_MY_1ST_SET : natural := min_of( 1, C_NUM_PARALLEL_SETS) - 1;
    constant C_MY_2ND_SET : natural := min_of( 2, C_NUM_PARALLEL_SETS) - 1;
    constant C_MY_3RD_SET : natural := min_of( 3, C_NUM_PARALLEL_SETS) - 1;
    constant C_MY_4TH_SET : natural := min_of( 4, C_NUM_PARALLEL_SETS) - 1;
    constant C_MY_PSET    : natural := min_of( 4, C_NUM_PARALLEL_SETS);
      
    subtype C_PARALLEL_SET_POS          is natural range C_NUM_PARALLEL_SETS - 1 downto 0;
    
    type PARALLEL_TAG_TYPE              is array(C_PARALLEL_SET_POS) of TAG_TYPE;
    type PARALLEL_DATA_TYPE             is array(C_PARALLEL_SET_POS) of DATA_TYPE;
  
    signal lookup_data_word           : PARALLEL_DATA_TYPE;
    signal update_data_word           : PARALLEL_DATA_TYPE;
  
    signal lookup_tag_word            : PARALLEL_TAG_TYPE;
    signal update_tag_word            : PARALLEL_TAG_TYPE;
  begin
    Gen_Parallel_Data_Array: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
    begin
      lookup_data_word(I) <= lookup_data_current_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
      update_data_word(I) <= update_data_current_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
      
      lookup_tag_word(I)  <= lookup_tag_current_word((I+1) * C_TAG_SIZE - 1 downto I * C_TAG_SIZE);
      update_tag_word(I)  <= update_tag_current_word((I+1) * C_TAG_SIZE - 1 downto I * C_TAG_SIZE);
      
    end generate Gen_Parallel_Data_Array;
  
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          MEMORY_DEBUG1     <= (others=>'0');
          MEMORY_DEBUG2     <= (others=>'0');
        else
          -- Default assignment.
          MEMORY_DEBUG1     <= (others=>'0');
          MEMORY_DEBUG2     <= (others=>'0');
          
          -- Access signals: 1+6+6 + 4+4 = 13 + 8 (limited scope 9->6, 9->4)
          MEMORY_DEBUG1(  0 + C_MY_DATA   - 1 downto   0) <= lookup_data_word(C_MY_1ST_SET)(C_MY_DATA - 1 downto 0);
          MEMORY_DEBUG1( 32 + C_MY_DATA   - 1 downto  32) <= lookup_data_word(C_MY_2ND_SET)(C_MY_DATA - 1 downto 0);
          MEMORY_DEBUG1( 64 + C_MY_DATA   - 1 downto  64) <= update_data_word(C_MY_1ST_SET)(C_MY_DATA - 1 downto 0);
          MEMORY_DEBUG1( 96 + C_MY_DATA   - 1 downto  96) <= update_data_word(C_MY_2ND_SET)(C_MY_DATA - 1 downto 0);
          MEMORY_DEBUG1(128 + C_MY_DATA   - 1 downto 128) <= lookup_data_new_word(C_MY_DATA - 1 downto 0);
          MEMORY_DEBUG1(160 + C_MY_DATA   - 1 downto 160) <= update_data_new_word(C_MY_DATA - 1 downto 0);
          
          MEMORY_DEBUG1(192 + C_MY_DLINE  - 1 downto 192) <= lookup_data_addr(C_ADDR_DATA_LO + C_MY_DLINE - 1 downto 
                                                                              C_ADDR_DATA_LO);
          MEMORY_DEBUG1(208 + C_MY_DELINE - 1 downto 208) <= update_data_addr(C_ADDR_EXT_DATA_LO + C_MY_DELINE - 1 downto 
                                                                              C_ADDR_EXT_DATA_LO);
          
          MEMORY_DEBUG1(224 + C_MY_WE     - 1 downto 224) <= lookup_data_we(C_MY_WE - 1 downto 0);
          MEMORY_DEBUG1(                             228) <= update_data_we(0);
          MEMORY_DEBUG1(229 + C_MY_PSET   - 1 downto 229) <= lookup_data_en(C_MY_PSET - 1 downto 0);
          MEMORY_DEBUG1(233 + C_MY_PSET   - 1 downto 233) <= update_data_en(C_MY_PSET - 1 downto 0);
          
          
          MEMORY_DEBUG2(  0 + C_MY_TAG    - 1 downto   0) <= lookup_tag_word(C_MY_1ST_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2( 16 + C_MY_TAG    - 1 downto  16) <= lookup_tag_word(C_MY_2ND_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2( 32 + C_MY_TAG    - 1 downto  32) <= lookup_tag_word(C_MY_3RD_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2( 48 + C_MY_TAG    - 1 downto  48) <= lookup_tag_word(C_MY_4TH_SET)(C_MY_TAG - 1 downto 0);

          MEMORY_DEBUG2( 64 + C_MY_TAG    - 1 downto  64) <= update_tag_word(C_MY_1ST_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2( 80 + C_MY_TAG    - 1 downto  80) <= update_tag_word(C_MY_2ND_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2( 96 + C_MY_TAG    - 1 downto  96) <= update_tag_word(C_MY_3RD_SET)(C_MY_TAG - 1 downto 0);
          MEMORY_DEBUG2(112 + C_MY_TAG    - 1 downto 112) <= update_tag_word(C_MY_4TH_SET)(C_MY_TAG - 1 downto 0);
                    
          MEMORY_DEBUG2(128 + C_MY_TAGIN  - 1 downto 128) <= lookup_tag_new_word(C_MY_TAGIN - 1 downto 0);
          MEMORY_DEBUG2(160 + C_MY_TAGIN  - 1 downto 160) <= update_tag_new_word(C_MY_TAGIN - 1 downto 0);
          
          MEMORY_DEBUG2(192 + C_MY_TLINE  - 1 downto 192) <= lookup_tag_addr(C_ADDR_FULL_LINE_LO + C_MY_TLINE - 1 downto 
                                                                             C_ADDR_FULL_LINE_LO);
          MEMORY_DEBUG2(208 + C_MY_TLINE  - 1 downto 208) <= update_tag_addr(C_ADDR_FULL_LINE_LO + C_MY_TLINE - 1 downto 
                                                                             C_ADDR_FULL_LINE_LO);
          
          MEMORY_DEBUG2(224 + C_MY_PSET   - 1 downto 224) <= lookup_tag_we(C_MY_PSET - 1 downto 0);
          MEMORY_DEBUG2(228 + C_MY_PSET   - 1 downto 228) <= update_tag_we(C_MY_PSET - 1 downto 0);
          MEMORY_DEBUG2(                             232) <= lookup_tag_en;
          MEMORY_DEBUG2(                             233) <= update_tag_en;
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect behaviour
  
  Assertions: block
  begin
    -- Detect condition
    assert_err(C_ASSERT_LOOKUP_ERROR)     <= lookup_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_UPDATE_ERROR)     <= update_assert  when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_LOOKUP_ERROR) /= '1' 
      report "Cache Core: Lookup module error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_UPDATE_ERROR) /= '1' 
      report "Cache Core: Update module error."
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
  

	--For PARD
Gen_Parallel_DSid: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
begin
   update_tag_current_word_i(I)  <= update_tag_current_word((I+1)*C_TAG_SIZE - 1 downto I*C_TAG_SIZE);
       update_tag_new_word_i(I)  <=     update_tag_new_word((I+1)*C_TAG_SIZE - 1 downto I*C_TAG_SIZE);
   update_old_DSid_vec_wire((I+1) * C_DSID_WIDTH - 1 downto I * C_DSID_WIDTH) <= update_tag_current_word_i(I)(C_TAG_DSID_POS);
   update_new_DSid_vec_wire((I+1) * C_DSID_WIDTH - 1 downto I * C_DSID_WIDTH) <=     update_tag_new_word_i(I)(C_TAG_DSID_POS);
end generate Gen_Parallel_DSid;

    lookup_valid_to_stab                <= lu_check_valid_to_stab_wire;
    lookup_DSid_to_stab                 <= lookup_DSid_to_stab_wire;
    lookup_hit_to_stab          		<= lookup_hit_to_stab_wire;
    lookup_miss_to_stab         		<= lookup_miss_to_stab_wire;
    update_tag_en_to_stab               <= update_tag_en;
    update_tag_we_to_stab       		<= update_tag_we;
    update_tag_old_DSid_vec_to_stab     <= update_old_DSid_vec_wire;
    update_tag_new_DSid_vec_to_stab     <= update_new_DSid_vec_wire;
    lru_history_en_to_ptab		        <= lookup_fetch_piperun;
    lru_dsid_valid_to_ptab              <= access_valid;
    lru_dsid_to_ptab                    <= access_info.DSid;

end architecture IMP;
