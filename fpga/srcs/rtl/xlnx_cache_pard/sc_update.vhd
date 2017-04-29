-------------------------------------------------------------------------------
-- sc_update.vhd - Entity and architecture
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
-- Filename:        sc_update.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_update.vhd
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
use work.system_cache_queue_pkg.all;


entity sc_update is
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
    backend_wr_resp_DSid      : out std_logic_vector(C_DSID_WIDTH - 1 downto 0);
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
end entity sc_update;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_update is

  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_RI_QUEUE_ERROR            : natural :=  0;
  constant C_ASSERT_R_QUEUE_ERROR             : natural :=  1;
  constant C_ASSERT_E_QUEUE_ERROR             : natural :=  2;
  constant C_ASSERT_BS_QUEUE_ERROR            : natural :=  3;
  constant C_ASSERT_WM_QUEUE_ERROR            : natural :=  4;
  constant C_ASSERT_WMA_QUEUE_ERROR           : natural :=  5;
  constant C_ASSERT_WMAD_QUEUE_ERROR          : natural :=  6;
  constant C_ASSERT_NO_RI_INFO                : natural :=  7;
  constant C_ASSERT_NO_BS_INFO                : natural :=  8;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  9;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_SET_BITS                 : natural := Log2(C_NUM_SETS);
  constant C_SERIAL_SET_BITS          : natural := sel(C_NUM_SERIAL_SETS   = 1, 0, Log2(C_NUM_SERIAL_SETS));
  constant C_PARALLEL_SET_BITS        : natural := sel(C_NUM_PARALLEL_SETS = 1, 0, Log2(C_NUM_PARALLEL_SETS));
  
  constant C_NATIVE_SIZE_BITS         : std_logic_vector(C_ADDR_WORD_HI downto C_ADDR_BYTE_LO) :=
                                                   std_logic_vector(to_unsigned((C_EXTERNAL_DATA_WIDTH/8) - 1, 
                                                   C_ADDR_WORD_HI - C_ADDR_BYTE_LO + 1));
  
  constant C_RRESP_WIDTH              : integer := 2 + 2 * C_ENABLE_COHERENCY;
  
  
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
  subtype C_RRESP_POS                 is natural range C_RRESP_WIDTH - 1              downto 0;
  subtype TAG_TYPE                    is std_logic_vector(C_TAG_POS);
  subtype BE_TYPE                     is std_logic_vector(C_BE_POS);
  subtype DATA_TYPE                   is std_logic_vector(C_DATA_POS);
  subtype EXT_BE_TYPE                 is std_logic_vector(C_EXT_BE_POS);
  subtype EXT_DATA_TYPE               is std_logic_vector(C_EXT_DATA_POS);
  subtype RRESP_TYPE                  is std_logic_vector(C_RRESP_POS);
  
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
  
  type ALL_TAG_TYPE                   is array(C_SET_POS) of TAG_TYPE;
  type PARALLEL_TAG_TYPE              is array(C_PARALLEL_SET_POS) of TAG_TYPE;
  type PARALLEL_EXT_DATA_TYPE         is array(C_PARALLEL_SET_POS) of EXT_DATA_TYPE;
  
  -- Address related.
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI   downto C_ADDR_INTERNAL_LO;
  subtype C_ADDR_DIRECT_POS           is natural range C_ADDR_DIRECT_HI     downto C_ADDR_DIRECT_LO;
  subtype C_ADDR_EXT_DATA_POS         is natural range C_ADDR_EXT_DATA_HI   downto C_ADDR_EXT_DATA_LO;
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
  subtype ADDR_TAG_TYPE               is std_logic_vector(C_ADDR_TAG_POS);
  subtype ADDR_FULL_LINE_TYPE         is std_logic_vector(C_ADDR_FULL_LINE_POS);
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_EXT_WORD_TYPE          is std_logic_vector(C_ADDR_EXT_WORD_POS);
  subtype ADDR_WORD_TYPE              is std_logic_vector(C_ADDR_WORD_POS);
  subtype ADDR_EXT_BYTE_TYPE          is std_logic_vector(C_ADDR_EXT_BYTE_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);

  constant addr_word_zero_vec : ADDR_WORD_TYPE := (others => '0');
  constant addr_byte_zero_vec : ADDR_BYTE_TYPE := (others => '0');
  
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
  
  constant C_ADDR_INTERNAL_BITS       : natural := C_ADDR_INTERNAL_HI - C_ADDR_INTERNAL_LO + 1;
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Types for Queue Length.
  constant C_DATA_QUEUE_LINE_LENGTH   : integer:= 32 * C_CACHE_LINE_LENGTH / C_EXTERNAL_DATA_WIDTH;
  constant C_DATA_QUEUE_LENGTH        : integer:= max_of(16, 2 * C_DATA_QUEUE_LINE_LENGTH);
  constant C_DATA_QUEUE_LENGTH_BITS   : integer:= log2(C_DATA_QUEUE_LENGTH);
  subtype DATA_QUEUE_ADDR_POS         is natural range C_DATA_QUEUE_LENGTH - 1 downto 0;
  subtype DATA_QUEUE_ADDR_TYPE        is std_logic_vector(C_DATA_QUEUE_LENGTH_BITS - 1 downto 0);
  
  
  -- Custom data structures.
  type E_TYPE is record
    Set               : SET_BIT_TYPE;
    Offset            : ADDR_LINE_TYPE;
  end record E_TYPE;
  
  type WM_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Offset            : ADDR_OFFSET_TYPE;
    Use_Bits          : ADDR_OFFSET_TYPE;
    Stp_Bits          : ADDR_OFFSET_TYPE;
    Evict             : std_logic;
    Will_Use          : std_logic;
    Kind              : std_logic;
    Allocate          : std_logic;
    Allow             : std_logic;
    DSid              : PARD_DSID_TYPE;
  end record WM_TYPE;
  
  type WMA_TYPE is record
    Last              : std_logic;
    Strb              : EXT_BE_TYPE;
    Data              : EXT_DATA_TYPE;
  end record WMA_TYPE;
  
  type BS_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Internal          : std_logic;
    Insert            : std_logic;
    Addr              : ADDR_INTERNAL_TYPE;
    DSid              : std_logic_vector(C_TAG_DSID_POS);
    Set_ExOk          : std_logic;
  end record BS_TYPE;
  
  type RI_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Hot_Port          : PORT_TYPE;
    Set               : SET_BIT_TYPE;
    Addr              : ADDR_INTERNAL_TYPE;
    Use_Bits          : ADDR_OFFSET_TYPE;
    Stp_Bits          : ADDR_OFFSET_TYPE;
    Kind              : std_logic;
    Len               : AXI_LENGTH_TYPE;
    Allocate          : std_logic;
    Evicted_Line      : std_logic;
    Write_Merge       : std_logic;
    PassDirty         : std_logic;
    IsShared          : std_logic;
    Exclusive         : std_logic;
    DSid              : PARD_DSID_TYPE;
  end record RI_TYPE;
  
  type R_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Hot_Port          : PORT_TYPE;
    Last              : std_logic;
    Data              : EXT_DATA_TYPE;
    RResp             : RRESP_TYPE;
    Addr              : ADDR_INTERNAL_TYPE;
    Use_Bits          : ADDR_OFFSET_TYPE;
    Stp_Bits          : ADDR_OFFSET_TYPE;
    Kind              : std_logic;
    Len               : AXI_LENGTH_TYPE;
    Allocate          : std_logic;
    PassDirty         : std_logic;
    IsShared          : std_logic;
  end record R_TYPE;
  
  -- Empty data structures.
  constant C_NULL_E                   : E_TYPE    := (Set=>(others=>'0'),  Offset=>(others=>'0'));
  constant C_NULL_WM                  : WM_TYPE   := (Port_Num=>0, Offset=>(others=>'0'), Use_Bits=>(others=>'0'),  
                                                      Stp_Bits=>(others=>'0'), Evict=>'0', Will_Use=>'0', 
                                                      Kind=>'0', Allocate=>'0', Allow=>'1', DSid=>(others=>'0'));
  constant C_NULL_WMA                 : WMA_TYPE  := (Last=>'0', Strb=>(others=>'0'), Data=>(others=>'0'));
  constant C_NULL_BS                  : BS_TYPE   := (Port_Num=>0, Internal=>'0', Insert=>'0', Addr=>(others=>'0'),
                                                      Set_ExOk=>'0', DSid=>(others=>'0'));
  constant C_NULL_RI                  : RI_TYPE   := (Port_Num=>0, Hot_Port=>(others=>'0'), Set=>(others=>'0'), 
                                                      Addr=>(others=>'0'),
                                                      Use_Bits=>(others=>'0'), Stp_Bits=>(others=>'0'), 
                                                      Kind=>'0', Len=>(others=>'0'), Allocate=>'0', 
                                                      Evicted_Line=>'0', Write_Merge=>'0', 
                                                      PassDirty=>'0', IsShared=>'0', Exclusive => '0',
                                                      DSid=>(others=>'0'));
  constant C_NULL_R                   : R_TYPE    := (Port_Num=>0, Hot_Port=>(others=>'0'), Last=>'0', 
                                                      Data=>(others=>'0'), RResp=>(others=>'0'), Addr=>(others=>'0'), 
                                                      Use_Bits=>(others=>'0'), Stp_Bits=>(others=>'0'), 
                                                      Kind=>'0', Len=>(others=>'0'), Allocate=>'0', 
                                                      PassDirty=>'0', IsShared=>'0');
  
  -- Types for information queue storage.
  type E_FIFO_MEM_TYPE                is array(QUEUE_ADDR_POS)      of E_TYPE;
  type WM_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS)      of WM_TYPE;
  type WMA_FIFO_MEM_TYPE              is array(DATA_QUEUE_ADDR_POS) of WMA_TYPE;
  type BS_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS)      of BS_TYPE;
  type RI_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS)      of RI_TYPE;
  type R_FIFO_MEM_TYPE                is array(DATA_QUEUE_ADDR_POS) of R_TYPE;
  
  
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
  
  component carry_select_and is
    generic (
      C_KEEP    : boolean:= false;
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
  
  component carry_latch_and_n is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE;
      C_NUM_PAD : natural;
      C_INV_C   : boolean
    );
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      O         : out std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_latch_and_n;
  
  component carry_compare is
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
  end component carry_compare;
  
  component carry_piperun_step is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET  : TARGET_FAMILY_TYPE
    );
    port (
      Carry_IN  : in  std_logic;
      Need      : in  std_logic;
      Stall     : in  std_logic;
      Done      : in  std_logic;
      Carry_OUT : out std_logic
    );
  end component carry_piperun_step;
  
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
  
  component sc_srl_fifo_counter is
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
  end component sc_srl_fifo_counter;
  
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
  -- Detect Address Conflicts
  
  signal update_match_DSid          : std_logic;
  signal update_match_addr          : std_logic;
  signal update_tag_conflict_i      : std_logic;
  
  
  -- ----------------------------------------
  -- Update Pipeline Stage: Update
  
  signal update_piperun_pre5        : std_logic;
  signal update_piperun_pre4        : std_logic;
  signal update_piperun_pre3        : std_logic;
  signal update_piperun_pre2        : std_logic;
  signal update_piperun_pre1        : std_logic;
  signal update_piperun_i           : std_logic;
  signal update_stall               : std_logic;
  signal update_port_i              : natural range 0 to C_NUM_PORTS - 1;
  signal update_cur_tag_set         : SET_BIT_TYPE;
  signal update_allocate_write_miss : std_logic;
  signal update_need_tag_write_pre5 : std_logic;
  signal update_need_tag_write_pre4 : std_logic;
  signal update_need_tag_write_pre3 : std_logic;
  signal update_need_tag_write_pre2 : std_logic;
  signal update_need_tag_write_pre1 : std_logic;
  signal update_need_tag_write_carry: std_logic;
  signal update_done_bs             : std_logic;
  signal update_done_ar             : std_logic;
  signal update_done_aw             : std_logic;
  signal update_done_evict          : std_logic;
  signal update_done_tag_write      : std_logic;
  signal update_stall_bs            : std_logic;
  signal update_stall_ar            : std_logic;
  signal update_stall_aw            : std_logic;
  signal update_stall_evict         : std_logic;
  signal update_stall_tag_write     : std_logic;
  signal update_tag_write_ignore    : std_logic;
  signal read_req_valid_i           : std_logic;
  signal read_req_exclusive_i       : std_logic;
  signal read_req_kind_i            : std_logic;
  signal update_evict               : std_logic;
  signal update_tag_write_raw       : std_logic;
  signal update_tag_write_raw_lvec  : PARALLEL_SET_TYPE;
  signal update_tag_write_raw_vec   : PARALLEL_SET_TYPE;
  signal update_tag_write           : std_logic;
  signal update_block_lookup        : std_logic;
  signal update_new_tag_valid       : std_logic;
  signal update_new_tag_reused      : std_logic;
  signal update_new_tag_locked      : std_logic;
  signal update_new_tag_dirty       : std_logic;
  signal write_req_valid_i          : std_logic;
  
  signal update_new_tag_addr        : TAG_ADDR_TYPE;
  signal update_new_tag_DSid        : PARD_DSID_TYPE;
  
  
  -- ----------------------------------------
  -- Detect LRU Changes
  
  signal lru_update_prev_lru_set_i  : C_SET_POS;
  signal lru_update_new_lru_set_i   : C_SET_POS;
  signal update_all_tags_i          : ALL_TAG_TYPE;
  signal update_all_tag_valid       : SET_TYPE;
  
  
  -- ----------------------------------------
  -- Generate Data for Write Request
  
  signal write_req_exclusive_i      : std_logic;
  signal write_req_kind_i           : std_logic;
  signal write_req_line_only_i      : std_logic;
  
  
  -- ----------------------------------------
  -- End of Transaction
  
  signal update_read_done_i : std_logic;
  signal update_write_done_i : std_logic;
  
  
  -----------------------------------------------------------------------------
  -- Set Handling
  
  signal update_tag_trans_addr      : ADDR_FULL_LINE_TYPE;
  signal update_tag_unlock_addr     : ADDR_FULL_LINE_TYPE;
  signal update_data_line           : ADDR_FULL_LINE_TYPE;
  signal update_cur_tag_par_set     : C_PARALLEL_SET_POS;
  signal update_cur_tag_rd_par_set  : C_PARALLEL_SET_POS;
  signal update_cur_data_par_set    : C_PARALLEL_SET_POS;
  signal update_cur_evict_par_set   : C_PARALLEL_SET_POS;
  signal update_cur_evict_par_set_d1: C_PARALLEL_SET_POS;
  
  
  -- ----------------------------------------
  -- Check Locked Tag
  
  signal update_readback_tag_en     : std_logic;
  signal update_readback_allowed    : std_logic;
  signal update_readback_possible   : std_logic;
  signal update_readback_available  : std_logic;
  signal update_readback_done       : std_logic;
  signal update_readback_tag        : TAG_TYPE;
  signal update_locked_tag_match    : std_logic;
  signal update_locked_tag_is_dead  : std_logic;
  signal update_remove_locked       : std_logic;
  signal update_remove_locked_safe  : std_logic;
  signal update_remove_locked_2nd_cycle : std_logic;
  signal update_rb_pos_phase        : std_logic;
  signal update_first_word_safe     : std_logic;
  
  
  -- ----------------------------------------
  -- Control Update TAG
  
  signal update_tag_addr_i          : ADDR_FULL_LINE_TYPE;
  signal update_tag_en_i            : std_logic;
  signal update_select_readback     : PARALLEL_SET_TYPE;
  signal update_sel_readback_tag    : PARALLEL_SET_TYPE;
  signal update_tag_match           : PARALLEL_SET_TYPE;
  signal update_DSid_match	    : PARALLEL_SET_TYPE;
  signal update_tag_DSid_match      : PARALLEL_SET_TYPE;
  signal update_tag_is_alive        : PARALLEL_SET_TYPE;
  signal update_tag_remove_lock     : PARALLEL_SET_TYPE;
  signal update_tag_we_i            : PARALLEL_SET_TYPE;
  signal update_new_tag             : TAG_TYPE;
  signal update_tag_current_word_i  : PARALLEL_TAG_TYPE;
  
  -- ----------------------------------------
  -- Control Update DATA
  
  signal update_data_addr_i         : ADDR_EXT_DATA_TYPE;
  signal update_data_en_ii          : std_logic_vector(C_NUM_PARALLEL_SETS downto 0);
  signal update_data_en_sel_n       : PARALLEL_SET_TYPE;
  signal update_data_en_i           : PARALLEL_SET_TYPE;
  signal update_data_current_word_i : PARALLEL_EXT_DATA_TYPE;
  
  
  -- ----------------------------------------
  -- Queue for Data Eviction (Read Miss Dirty and Evict)
  
  signal update_e_push              : std_logic;
  signal update_e_pop               : std_logic;
  signal e_read_fifo_addr           : QUEUE_ADDR_TYPE;
  signal e_fifo_mem                 : E_FIFO_MEM_TYPE;
  signal e_fifo_full                : std_logic;
  signal e_fifo_empty               : std_logic;
  signal e_set                      : SET_BIT_TYPE;
  signal e_offset                   : ADDR_LINE_TYPE;
  signal e_assert                   : std_logic;
  
  
  -- ----------------------------------------
  -- Queue for Evict Done
  
  signal ed_push                    : std_logic;
  signal ed_pop                     : std_logic;
  signal ed_fifo_full               : std_logic;
  signal ed_fifo_empty              : std_logic;
  signal ed_assert                  : std_logic;
  
  
  -- ----------------------------------------
  -- Update Data Pointer
  
  signal update_rd_cnt_en           : std_logic;
  signal update_wr_cnt_en           : std_logic;
  signal update_word_cnt_en         : std_logic;
  signal update_word_cnt            : ADDR_EXT_WORD_TYPE;
  signal update_word_cnt_next       : ADDR_EXT_WORD_TYPE;
  signal update_word_cnt_len        : ADDR_EXT_WORD_TYPE;
  signal update_cur_data_set        : SET_BIT_TYPE;
  signal update_data_base_line      : ADDR_LINE_TYPE;
  signal update_word_cnt_first      : std_logic;
  signal update_word_cnt_almost_last: std_logic;
  signal update_word_cnt_last       : std_logic;
  signal update_read_miss_safe      : std_logic;
  signal update_read_miss_wma_safe  : std_logic;
  signal update_read_miss_start_ok  : std_logic;
  signal update_read_miss_start     : std_logic;
  signal update_evict_start         : std_logic;
  signal update_read_miss_stop      : std_logic;
  signal update_evict_stop          : std_logic;
  signal update_evict_ongoing       : std_logic;
  signal update_evict_busy          : std_logic;
  signal update_read_miss_ongoing   : std_logic;
  signal update_rm_alloc_ongoing    : std_logic;
  signal update_evict_valid         : std_logic;
  signal update_evict_last          : std_logic;
  signal update_evict_word          : EXT_DATA_TYPE;
  signal write_data_full_d1         : std_logic;
  signal update_evict_stop_d1       : std_logic;
  signal update_read_miss_use_ok    : std_logic;
  signal update_read_miss_use_bypass: std_logic;
  
  
  -- ----------------------------------------
  -- Optimized Read Miss Use OK:
  
  signal ud_rm_available_sel        : std_logic;
  signal ud_rm_available            : std_logic;
  signal ud_rm_use_sel              : std_logic;
  signal ud_rm_use_pre_safe         : std_logic;
  signal ud_rm_use_safe             : std_logic;
  signal ud_rm_use_and_lock_safe    : std_logic;
  signal ud_rm_sel_wr_cnt_en        : std_logic;
  
  signal ud_rm_resize_part_sel      : std_logic;
  signal ud_rm_use_resize_part_ok   : std_logic;
  signal ud_rm_port_forward         : PORT_TYPE;
  signal update_read_miss_resize_ok : std_logic;
  signal update_read_resize_selected_vec : PORT_TYPE;
  signal update_read_resize_finish_vec   : PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Queue for Write Extraction (Write Miss)
  
  signal update_write_miss_busy_i   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_wm_push             : std_logic; 
  signal update_wm_pop_evict        : std_logic; 
  signal update_wm_pop_evict_hold   : std_logic;
  signal update_wm_pop_normal       : std_logic; 
  signal update_wm_pop_normal_hold  : std_logic;
  signal update_wm_pop_allocate     : std_logic;
  signal update_wm_pop              : std_logic; 
  signal wm_read_fifo_addr          : QUEUE_ADDR_TYPE;
  signal wm_fifo_mem                : WM_FIFO_MEM_TYPE;
  signal wm_fifo_full               : std_logic; 
  signal wm_fifo_almost_empty       : std_logic; 
  signal wm_fifo_empty              : std_logic;
  signal wm_exist                   : std_logic;
  signal wm_refresh_reg             : std_logic;
  signal wm_port                    : natural range 0 to C_NUM_PORTS - 1;
  signal wm_allocate                : std_logic;
  signal wm_evict                   : std_logic;
  signal wm_will_use                : std_logic;
  signal wm_kind                    : std_logic;
  signal wm_offset                  : ADDR_OFFSET_TYPE;
  signal wm_DSid                    : PARD_DSID_TYPE;
  signal wm_use_bits                : ADDR_OFFSET_TYPE;
  signal wm_stp_bits                : ADDR_OFFSET_TYPE;
  signal wm_local_wrap              : std_logic;
  signal wm_remove_unaligned        : ADDR_OFFSET_TYPE;
  signal wm_allow                   : std_logic;
  signal wm_allow_vec               : BE_TYPE;
  signal wm_assert                  : std_logic;
  signal update_use_write_word      : std_logic; 
  signal update_write_miss_ongoing  : std_logic; 
  signal update_write_port_i        : C_PORT_POS; 
  signal update_ack_write_ext       : std_logic; 
  signal update_ack_write_alloc     : std_logic; 
  signal update_ack_write_word      : std_logic; 
  signal update_ack_write_word_vec  : PORT_TYPE;
  signal update_write_data_ready_i  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_wr_miss_valid       : std_logic; 
  signal update_wr_miss_last        : std_logic; 
  signal update_wr_miss_be          : BE_TYPE; 
  signal update_wr_miss_word        : DATA_TYPE; 
  
  
  -- ----------------------------------------
  -- Write Size Conversion
  
  signal update_wr_miss_word_done   : std_logic; 
  signal update_wr_miss_throttle    : std_logic; 
  signal update_wr_miss_restart_word: std_logic;
  signal update_wr_miss_rs_valid    : std_logic;
  signal update_wr_miss_rs_last     : std_logic;
  signal update_wr_miss_rs_be       : EXT_BE_TYPE;
  signal update_wr_miss_rs_word     : EXT_DATA_TYPE;
  signal update_wr_offset           : ADDR_OFFSET_TYPE;
  signal update_wr_offset_cnt       : ADDR_OFFSET_TYPE;
  signal update_wr_offset_cnt_cmb   : ADDR_OFFSET_TYPE;
  signal update_wr_next_word_addr   : ADDR_OFFSET_TYPE;
  
  
  -- ----------------------------------------
  -- Write Miss Allocate Data Processing
  
  signal update_wma_insert_dummy    : std_logic;
  signal update_wma_select_port     : std_logic;
  signal update_wma_data_valid      : std_logic;
  signal update_wma_fifo_stall      : std_logic;
  signal update_wma_throttle        : std_logic;
  signal update_wma_last            : std_logic;
  signal update_wma_strb            : EXT_BE_TYPE;
  signal update_wma_data            : EXT_DATA_TYPE;
  signal wma_word_done              : std_logic;
  signal wma_word_done_d1           : std_logic;
  
  
  -- ----------------------------------------
  -- Queue for Write Miss Allocate
  
  signal wma_push                   : std_logic;
  signal wma_sel_pop_n              : std_logic;
  signal wma_pop                    : std_logic;
  signal wma_fifo_almost_full       : std_logic;
  signal wma_fifo_full              : std_logic;
  signal wma_fifo_empty             : std_logic;
  signal wma_read_fifo_addr         : DATA_QUEUE_ADDR_TYPE:= (others=>'1');
  signal wma_fifo_mem               : WMA_FIFO_MEM_TYPE; -- := (others=>C_NULL_WMA);
  signal wma_last                   : std_logic;
  signal wma_strb                   : EXT_BE_TYPE;
  signal wma_data                   : EXT_DATA_TYPE;
  signal wma_merge_done             : std_logic;
  signal wma_assert                 : std_logic;
  
  
  -- ----------------------------------------
  -- Queue for Write Miss Allocate Done
  
  signal wmad_done                  : std_logic;
  signal wmad_push                  : std_logic;
  signal wmad_pop                   : std_logic;
  signal wmad_fifo_full             : std_logic;
  signal wmad_fifo_empty            : std_logic;
  signal wmad_assert                : std_logic;
  
  
  -- ----------------------------------------
  -- Write Data Mux
  
  signal write_data_valid_i         : std_logic;
  signal write_data_last_i          : std_logic;
  
  
  -- ----------------------------------------
  -- Read Information Buffer
  
  signal ri_push                    : std_logic;
  signal ri_pop                     : std_logic;
  signal ri_refresh_reg             : std_logic;
  signal ri_read_fifo_addr          : QUEUE_ADDR_TYPE:= (others=>'1');
  signal ri_fifo_mem                : RI_FIFO_MEM_TYPE; -- := (others=>C_NULL_RI);
  signal ri_fifo_full               : std_logic;
  signal ri_fifo_empty              : std_logic;
  signal ri_exist                   : std_logic;
  signal ri_port                    : natural range 0 to C_NUM_PORTS - 1;
  signal ri_hot_port                : PORT_TYPE;
  signal ri_set                     : SET_BIT_TYPE;
  signal ri_addr                    : ADDR_INTERNAL_TYPE;
  signal ri_use                     : ADDR_OFFSET_TYPE;
  signal ri_stp                     : ADDR_OFFSET_TYPE;
  signal ri_kind                    : std_logic;
  signal ri_len                     : AXI_LENGTH_TYPE;
  signal ri_allocate                : std_logic;
  signal ri_evicted                 : std_logic;
  signal ri_merge                   : std_logic;
  signal ri_isshared                : std_logic;
  signal ri_passdirty               : std_logic;
  signal ri_assert                  : std_logic;
  signal ri_exclusive               : std_logic;
  signal ri_DSid                    : PARD_DSID_TYPE;
  
  
  -- ----------------------------------------
  -- Read Data Forwarding
  
  
  signal backend_rd_data_last_n     : std_logic;
  signal backend_rd_data_use_ii     : std_logic;
  signal backend_rd_data_use_i      : std_logic;
  signal backend_rd_data_use        : std_logic;
  signal backend_rd_data_pop        : std_logic;
  signal backend_rd_data_real_rresp : std_logic_vector(2 - 1 downto 0);
  signal backend_rd_data_ready_i    : std_logic;
  signal update_read_forward_ready  : std_logic;
  signal update_read_resize_valid   : std_logic;
  signal update_read_resize_last    : std_logic;
  signal update_read_resize_port    : rinteger range 0 to C_NUM_PORTS - 1;
  signal update_read_resize_hot_port: PORT_TYPE; 
  signal update_read_resize_addr    : ADDR_INTERNAL_TYPE;
  signal update_read_resize_offset  : ADDR_OFFSET_TYPE;
  signal update_read_resize_use_bits: ADDR_OFFSET_TYPE;
  signal update_read_resize_stp_bits: ADDR_OFFSET_TYPE;
  signal update_read_resize_kind    : std_logic;
  signal update_read_resize_len     : AXI_LENGTH_TYPE;
  signal update_read_resize_allocate: std_logic;
  signal update_read_resize_word    : EXT_DATA_TYPE;
  signal update_read_resize_rresp   : RRESP_TYPE;
  signal update_read_resize_used    : std_logic;
  signal update_read_resize_ready   : std_logic;
  signal r_assert                   : std_logic;
  
  
  -- ----------------------------------------
  -- Read Size Conversion
  
  signal update_rd_offset           : ADDR_OFFSET_TYPE;
  signal update_rd_offset_cnt       : ADDR_OFFSET_TYPE;
  signal update_rd_offset_cnt_next  : ADDR_OFFSET_TYPE;
  signal update_rd_len              : AXI_LENGTH_TYPE;
  signal update_rd_len_cnt          : AXI_LENGTH_TYPE;
  signal update_rd_len_cnt_next     : AXI_LENGTH_TYPE;
  signal update_read_resize_first   : std_logic;
  signal update_read_resize_finish  : std_logic;
  signal update_read_resize_selected: std_logic;
  signal update_read_resize_sel_wrap: std_logic;
  signal update_rd_incr_ok          : std_logic;
  signal update_rd_wrap_ok          : std_logic;
  signal update_rd_miss_th_incr     : std_logic;
  signal update_rd_miss_th_wrap     : std_logic;
  signal update_rd_miss_throttle    : std_logic;
  signal update_read_data_valid_i   : std_logic;
  signal update_read_data_valid_vec : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_read_data_valid_ii  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_read_data_last_i    : std_logic;
  signal update_read_data_resp_i    : std_logic_vector(C_MAX_RRESP_WIDTH - 1 downto 0);
  
  
  -- ----------------------------------------
  -- Write Response Handling
  
  signal update_bs_push             : std_logic;
  signal update_bs_pop              : std_logic;
  signal bs_refresh_reg             : std_logic;
  signal backend_wr_resp_valid_hold : std_logic;
  signal backend_wr_resp_port_ready : std_logic;
  signal backend_wr_resp_wma_ready  : std_logic;
  signal backend_wr_resp_ready_i    : std_logic;
  signal bs_read_fifo_addr          : QUEUE_ADDR_TYPE;
  signal bs_fifo_mem                : BS_FIFO_MEM_TYPE;
  signal bs_fifo_full               : std_logic;
  signal bs_exist                   : std_logic;
  signal bs_internal                : std_logic;
  signal bs_insert                  : std_logic;
  signal bs_port_num                : natural range 0 to C_NUM_PORTS - 1;
  signal bs_addr                    : ADDR_INTERNAL_TYPE;
  signal bs_DSid                    : std_logic_vector(C_TAG_DSID_POS);
  signal bs_exok                    : std_logic;
  signal bs_assert                  : std_logic;
  signal update_ext_bresp_wma       : std_logic;
  signal update_ext_bresp_normal    : std_logic;
  signal update_ext_bresp_any       : std_logic;
  signal update_ext_bresp_any_vec   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  signal update_ext_bresp_valid_i   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  --signal temp                       : std_logic_vector(C_NUM_PARALLEL_SETS - 1 downto 0) := ( C_NUM_PARALLEL_SETS - 1 => '0', others=>'0');
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  
  -----------------------------------------------------------------------------
  -- Attributes
  -----------------------------------------------------------------------------
  
  
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
  -- Detect Address Conflicts
  -- 
  -- Detect any address conflicts with current transactions against earlier
  -- Updates.
  -----------------------------------------------------------------------------
  
  -- Conflict because of current TAG Update, i.e. hit/miss move here or removal of Locked.
--  update_tag_conflict_i       <= access_valid and update_need_tag_write 
--                                        when lookup_new_addr = update_info.Addr(C_ADDR_LINE_POS) else 
--                                 '0';
  UD_TagConf_Compare_Inst1: carry_compare
    generic map(
      C_TARGET  => C_TARGET,
      C_SIZE    => C_ADDR_LINE_BITS
    )
    port map(
      Carry_In  => update_need_tag_write_carry,
      A_Vec     => lookup_new_addr,
      B_Vec     => update_info.Addr(C_ADDR_LINE_POS),
      Carry_Out => update_match_addr
    );
  
  UD_TagConf_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_match_addr,
      A         => access_valid,
      Carry_OUT => update_tag_conflict_i
    );
  
  -- Detect any Update TAG update conflicts with Access.
  update_tag_conflict         <= update_tag_conflict_i;
  
  
  -----------------------------------------------------------------------------
  -- Update Pipeline Stage: Update
  -- 
  -- Handle all events that are passed on from Lookup to Update by manipulating:
  --  * BP  - BRESP Port queue(s)
  --  * BS  - BREPS Source queue
  --  * AR  - Read Address queue
  --  * AW  - Write Address queue
  --  * E   - Evict queue
  --  * Tag - Update Tag bit(s)
  -- 
  -- Actions taken per event:
  --  * Write Miss      - Push to BP and BS queue
  --  * Write Hit       - Push to BP queue, Set Dirty bit in Tag
  --  * Write Hit Dirty - Push to BP queue
  --  * Evict           - Write data if dirty (and push to BS queue), 
  --                      Always Invalidate Tag
  --  * WriteBack       - Write data if dirty (and push to BS queue), 
  --                      Remove dirty bit from Tag (if set)
  --  * Read Hit        - N/A
  --  * Read Miss       - Set Locked Valid in Tag
  --                      Remove Locked when data is returned 
  --  * Read Miss Dirty - Push to BS queue, Write data if dirty, 
  --                      Set Locked Valid in Tag
  --                      Remove Locked when data is returned 
  -- 
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
  update_piperun          <= update_piperun_i;
--  update_piperun_i        <= not update_stall;
  
  -- Stall Update stage if not ready.
  update_stall            <= ( update_valid and 
                               ( ( update_need_bs        and update_stall_bs        and not update_done_bs        ) or
                                 ( update_need_ar        and update_stall_ar        and not update_done_ar        ) or
                                 ( update_need_aw        and update_stall_aw        and not update_done_aw        ) or
                                 ( update_need_evict     and update_stall_evict     and not update_done_evict     ) or
                                 ( update_need_tag_write and update_stall_tag_write and not update_done_tag_write ) )
                              ) or update_block_lookup;
  
  -- Create PipeRun on carry chain.
  UD_PR_Comp_Inst1: carry_piperun_step
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => '1',
      Need      => update_need_tag_write,
      Stall     => update_stall_tag_write,
      Done      => update_done_tag_write,
      Carry_OUT => update_piperun_pre5
    );
  UD_PR_Comp_Inst2: carry_piperun_step
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun_pre5,
      Need      => update_need_evict,
      Stall     => update_stall_evict,
      Done      => update_done_evict,
      Carry_OUT => update_piperun_pre4
    );
  UD_PR_Comp_Inst4: carry_piperun_step
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun_pre4,
      Need      => update_need_bs,
      Stall     => update_stall_bs,
      Done      => update_done_bs,
      Carry_OUT => update_piperun_pre3
    );
  UD_PR_Comp_Inst5: carry_piperun_step
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun_pre3,
      Need      => update_need_aw,
      Stall     => update_stall_aw,
      Done      => update_done_aw,
      Carry_OUT => update_piperun_pre2
    );
  UD_PR_Comp_Inst6: carry_piperun_step
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun_pre2,
      Need      => update_need_ar,
      Stall     => update_stall_ar,
      Done      => update_done_ar,
      Carry_OUT => update_piperun_pre1
    );
  UD_PR_Comp_Inst7: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_piperun_pre1,
      A_N       => update_block_lookup,
      Carry_OUT => update_piperun_i
    );
  
  -- Select set depending on current actions.
  update_cur_tag_set      <= ri_set when ( update_readback_possible or update_readback_available ) = '1' else 
                             update_set;
  
  -- Get current port.
  update_port_i           <= get_port_num(update_info.Port_Num, C_NUM_PORTS);
  
  -- Extra Need Tag Write decoding for quicker tag conflict.
  update_allocate_write_miss  <= ( update_write_miss and update_info.Allocate );
  UD_TagWrite_Or_Inst1: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => '0',
      A         => update_info.Allocate,
      Carry_OUT => update_need_tag_write_pre5
    );
  UD_TagWrite_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_need_tag_write_pre5,
      A         => update_read_miss,
      Carry_OUT => update_need_tag_write_pre4
    );
  UD_TagWrite_Or_Inst2: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_need_tag_write_pre4,
      A         => update_info.Evict,
      Carry_OUT => update_need_tag_write_pre3
    );
  UD_TagWrite_Or_Inst3: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_need_tag_write_pre3,
      A         => update_first_write_hit,
      Carry_OUT => update_need_tag_write_pre2
    );
  UD_TagWrite_Or_Inst4: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_need_tag_write_pre2,
      A         => update_allocate_write_miss,
      Carry_OUT => update_need_tag_write_pre1
    );
  UD_TagWrite_And_Inst2: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_need_tag_write_pre1,
      A         => update_valid,
      Carry_OUT => update_need_tag_write_carry
    );
  
  -- Stall conditions.
  update_stall_bs         <= bs_fifo_full;
  update_stall_ar         <= not read_req_ready or ri_fifo_full;
  update_stall_aw         <= not write_req_ready;
  update_stall_evict      <= e_fifo_full;
  update_stall_tag_write  <= update_readback_available;
  
  -- Allowed actions.
  update_bs_push          <= ( update_need_bs        and not update_done_bs        and not update_stall_bs );
  read_req_valid_i        <= ( update_need_ar        and not update_done_ar        and not update_stall_ar );
  write_req_valid_i       <= ( update_need_aw        and not update_done_aw        and not update_stall_aw );
  update_evict            <= ( update_need_evict     and not update_done_evict     and not update_stall_evict );
  update_tag_write_raw    <= ( update_need_tag_write and not update_done_tag_write and not update_stall_tag_write );
  update_tag_write        <= update_tag_write_raw or
                             update_remove_locked;
  
  -- Ignore or completed.
  update_tag_write_ignore <= ( update_need_tag_write and ( update_done_tag_write or update_stall_tag_write ) ) or 
                             not update_need_tag_write;
  
  -- Vectorize Raw Tag write.
  update_tag_write_raw_lvec <= (others => update_tag_write_raw);
  update_tag_write_raw_vec  <= update_tag_write_raw_lvec and std_logic_vector(to_unsigned(2 ** update_cur_tag_par_set, C_NUM_PARALLEL_SETS));
  
  -- Handle Update action Done status.
  Pipeline_Stage_Done_Handle : process (ACLK) is
  begin  -- process Pipeline_Stage_Done_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        update_done_bs        <= '0';
        update_done_ar        <= '0';
        update_done_aw        <= '0';
        update_done_evict     <= '0';
        update_done_tag_write <= '0';
      else
        if( update_piperun_i = '1' ) then
          update_done_bs        <= '0';
        elsif( update_bs_push = '1' ) then
          update_done_bs        <= '1';
        end if;
        
        if( update_piperun_i = '1' ) then
          update_done_ar        <= '0';
        elsif( read_req_valid_i = '1' ) then
          update_done_ar        <= '1';
        end if;
        
        if( update_piperun_i = '1' ) then
          update_done_aw        <= '0';
        elsif( write_req_valid_i = '1' ) then
          update_done_aw        <= '1';
        end if;
        
        if( update_piperun_i = '1' ) then
          update_done_evict     <= '0';
        elsif( update_evict = '1' ) then
          update_done_evict     <= '1';
        end if;
        
        if( update_piperun_i = '1' ) then
          update_done_tag_write <= '0';
        elsif( ( update_tag_write and update_tag_write_raw ) = '1' ) then
          update_done_tag_write <= '1';
        end if;
      end if;
    end if;
  end process Pipeline_Stage_Done_Handle;
  
  
  -----------------------------------------------------------------------------
  -- Detect LRU Changes
  -----------------------------------------------------------------------------
  
  -- Split tag information to array.
  Gen_Tag: for I in 0 to C_NUM_SETS - 1 generate
  begin
    -- Vectorize Tag.
    update_all_tags_i(I)      <= update_all_tags((I+1)*C_TAG_SIZE - 1 downto I*C_TAG_SIZE);
    update_all_tag_valid(I)   <= update_all_tags_i(I)(C_TAG_VALID_POS);
  end generate Gen_Tag;
  
  -- Convert to integer.
  lru_update_prev_lru_set_i <= to_integer(unsigned(lru_update_prev_lru_set));
  lru_update_new_lru_set_i  <= to_integer(unsigned(lru_update_new_lru_set));
  
  -- Check if all Ways are Valid.
  
  -- Detect if Line needs to be scheduled for referesh.
  -- Autoclean if new LRU line is Valid and Dirty, it is only needed if the new LRU is actually different from 
  -- the last LRU. 
  -- Issuing a write-back of this line will remove any need for evict when there is a Miss on this Set.
  update_auto_clean_push    <= update_refreshed_lru and 
                               reduce_and(update_all_tag_valid) and
                               update_all_tags_i(lru_update_new_lru_set_i)(C_TAG_DIRTY_POS) when 
                                      ( lru_update_prev_lru_set_i /= lru_update_new_lru_set_i ) else
                               '0';
  
  -- Create address to be automatically refreshed.
  process (update_all_tags_i, lru_update_new_lru_set_i, update_info) is 
  begin  
    update_auto_clean_addr    <= (others=>'0');
    update_auto_clean_addr(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO)
                              <= ( update_all_tags_i(lru_update_new_lru_set_i)(C_TAG_ADDR_POS) & 
                                   update_info.Addr(C_ADDR_LINE_POS) & 
                                   addr_word_zero_vec & 
                                   addr_byte_zero_vec );
    update_auto_clean_DSid	  <= update_all_tags_i(lru_update_new_lru_set_i)(C_TAG_DSID_POS);
  end process;
    
    
  -----------------------------------------------------------------------------
  -- New Tag Settings
  -----------------------------------------------------------------------------
  
  update_new_tag_valid    <= not ( update_valid and update_info.Evict and not update_info.Allocate ) 
                                                              when update_readback_available = '0' else
                             '1';
  update_new_tag_reused   <= update_reused_tag and not update_readback_available;
  update_new_tag_locked   <= update_miss and not update_readback_available;
  update_new_tag_dirty    <= ( update_first_write_hit and not update_readback_available ) or
                             ( update_write_miss and update_info.Allocate and not update_readback_available ) or
                             ( ri_merge and update_readback_available );
  update_new_tag_addr     <= update_info.Addr(C_ADDR_TAG_POS) when update_readback_available = '0' else
                             ri_addr(C_ADDR_TAG_POS);
  update_new_tag_DSid     <= update_info.DSid when update_readback_available = '0' else
                             ri_DSid;
  
  
  -----------------------------------------------------------------------------
  -- Generate Data for Read Request
  -----------------------------------------------------------------------------
  
  -- Unmodified signals.
  read_req_valid          <= read_req_valid_i;
  read_req_port           <= update_port_i;
  read_req_exclusive      <= read_req_exclusive_i;
  read_req_kind           <= read_req_kind_i;
  
  -- Generate adjusted read length and size.
  Gen_Read_Request: process (update_info) is
  begin  -- process Gen_Read_Request
    -- Default values (allocating).
    read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS);
    read_req_DSid           <= update_info.DSid;
    read_req_len            <= std_logic_vector(to_unsigned((4*C_CACHE_LINE_LENGTH) / (C_EXTERNAL_DATA_WIDTH/8)-1, 8));
    read_req_size           <= std_logic_vector(to_unsigned(Log2(C_EXTERNAL_DATA_WIDTH/8), 3));
    read_req_exclusive_i    <= C_LOCK_NORMAL;
    if( C_EXTERNAL_DATA_WIDTH = ( 32 * C_CACHE_LINE_LENGTH ) ) then
      read_req_kind_i         <= C_KIND_INCR;
    else
      read_req_kind_i         <= C_KIND_WRAP;
    end if;

    
    if( update_info.Allocate = '0' ) then
      -- Non Allocating transaction, propagate information from original transaction.
--      if( is_on(C_ENABLE_COHERENCY + C_ENABLE_EX_MON) = 0 ) then
--        read_req_exclusive_i    <= update_info.Exclusive;
--      end if;
      read_req_kind_i         <= update_info.Kind;
      read_req_len            <= update_info.Len;
      read_req_size           <= update_info.Size;
      if( ( to_integer(unsigned(update_info.Len)) = 0 ) and ( update_info.Kind = C_KIND_WRAP ) ) then
        read_req_kind_i         <= C_KIND_INCR;
        read_req_DSid           <= update_info.DSid;
        case update_info.Size is
          when C_BYTE_SIZE          =>
            null;
          when C_HALF_WORD_SIZE     =>
            if( C_CACHE_DATA_WIDTH >= 16 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE - 1,        
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when C_WORD_SIZE          =>
            if( C_CACHE_DATA_WIDTH >= 32 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_WORD_STEP_SIZE - 1,             
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when C_DOUBLE_WORD_SIZE   =>
            if( C_CACHE_DATA_WIDTH >= 64 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE - 1,      
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when C_QUAD_WORD_SIZE     =>
            if( C_CACHE_DATA_WIDTH >= 128 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE - 1,        
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when C_OCTA_WORD_SIZE     =>
            if( C_CACHE_DATA_WIDTH >= 256 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE - 1,        
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when C_HEXADECA_WORD_SIZE =>
            if( C_CACHE_DATA_WIDTH >= 512 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE - 1,    
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
          when others               =>
            if( C_CACHE_DATA_WIDTH >= 1024 ) then
              read_req_addr           <= update_info.Addr(C_ADDR_INTERNAL_POS) and
                                         not std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE - 1, 
                                                                          C_ADDR_INTERNAL_BITS));
            end if;
        end case;
      end if;
    else
      -- Default wrap transactions shall be aligned to native size boundary.
      read_req_addr(C_EXT_DATA_ADDR_POS)  <= (others=>'0');
      read_req_DSid                       <= update_info.DSid;
    end if;
  end process Gen_Read_Request;
  
  
  -----------------------------------------------------------------------------
  -- Generate Data for Write Request
  -----------------------------------------------------------------------------
  
  -- Unmodified signals.
  write_req_valid         <= write_req_valid_i;
  write_req_port          <= update_port_i;
  write_req_internal      <= update_need_evict;
  write_req_exclusive     <= write_req_exclusive_i;
  write_req_kind          <= write_req_kind_i;
  write_req_line_only     <= write_req_line_only_i;
  
  -- Generate adjusted read length and size.
  Gen_Write_Request: process (update_need_evict, update_info, update_old_tag) is
  begin  -- process Gen_Write_Request
    -- Default values (evicting).
    if( update_info.Evict = '1' ) then
      write_req_addr                  <= update_info.Addr(C_ADDR_INTERNAL_POS);
      write_req_addr(C_ADDR_WORD_POS) <= addr_word_zero_vec;
      write_req_addr(C_ADDR_BYTE_POS) <= addr_byte_zero_vec;
      write_req_line_only_i           <= '1';
      write_req_DSid                  <= update_info.DSid;
    else
      write_req_addr                  <= ( update_old_tag(C_TAG_ADDR_POS) & update_info.Addr(C_ADDR_LINE_POS) & 
                                           addr_word_zero_vec & addr_byte_zero_vec );
      write_req_line_only_i           <= '0';
      write_req_DSid                  <= update_old_tag(C_TAG_DSID_POS);
    end if;
    write_req_len           <= std_logic_vector(to_unsigned((4*C_CACHE_LINE_LENGTH) / (C_EXTERNAL_DATA_WIDTH/8)-1, 8));
    write_req_size          <= std_logic_vector(to_unsigned(Log2(C_EXTERNAL_DATA_WIDTH/8), 3));
    write_req_exclusive_i   <= C_LOCK_NORMAL;
    write_req_kind_i        <= C_KIND_INCR;
    
    if( update_need_evict = '0' ) then
      -- Non Evicting transaction, propagate information from original transaction.
      write_req_addr          <= update_info.Addr(C_ADDR_INTERNAL_POS);
--      if( is_on(C_ENABLE_COHERENCY + C_ENABLE_EX_MON) = 0 ) then
--        write_req_exclusive_i   <= update_info.Exclusive;
--      end if;
      write_req_kind_i        <= update_info.Kind;
      write_req_DSid          <= update_info.DSid;
      
      -- Adjust transaction for external interface.
      case update_info.Size is
        when C_BYTE_SIZE          =>
          write_req_len           <= update_info.Len;
          write_req_size          <= update_info.Size;
        when C_HALF_WORD_SIZE     =>
          write_req_len           <= update_info.Len;
          write_req_size          <= update_info.Size;
        when C_WORD_SIZE          =>
          write_req_len           <= update_info.Len;
          write_req_size          <= update_info.Size;
        when C_DOUBLE_WORD_SIZE   =>
          if( C_EXTERNAL_DATA_WIDTH < C_DOUBLE_WORD_WIDTH ) then
            write_req_len           <= 
                update_info.Len(AXI_LENGTH_TYPE'left - Log2(C_DOUBLE_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) downto 0) & 
                (Log2(C_DOUBLE_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) - 1 downto 0=>'1');
          else
            write_req_len           <= update_info.Len;
            write_req_size          <= update_info.Size;
          end if;
        when C_QUAD_WORD_SIZE     =>
          if( C_EXTERNAL_DATA_WIDTH < C_QUAD_WORD_WIDTH ) then
            write_req_len           <= 
                update_info.Len(AXI_LENGTH_TYPE'left - Log2(C_QUAD_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) downto 0) & 
                (Log2(C_QUAD_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) - 1 downto 0=>'1');
          else
            write_req_len           <= update_info.Len;
            write_req_size          <= update_info.Size;
          end if;
        when C_OCTA_WORD_SIZE     =>
          if( C_EXTERNAL_DATA_WIDTH < C_OCTA_WORD_WIDTH ) then
            write_req_len           <= 
                update_info.Len(AXI_LENGTH_TYPE'left - Log2(C_OCTA_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) downto 0) & 
                (Log2(C_OCTA_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) - 1 downto 0=>'1');
          else
            write_req_len           <= update_info.Len;
            write_req_size          <= update_info.Size;
          end if;
        when C_HEXADECA_WORD_SIZE =>
          if( C_EXTERNAL_DATA_WIDTH < C_HEXADECA_WORD_WIDTH ) then
            write_req_len           <= 
                update_info.Len(AXI_LENGTH_TYPE'left - Log2(C_HEXADECA_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) downto 0) & 
                (Log2(C_HEXADECA_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) - 1 downto 0=>'1');
          else
            write_req_len           <= update_info.Len;
            write_req_size          <= update_info.Size;
          end if;
        when others               =>
          if( C_EXTERNAL_DATA_WIDTH < C_TRIACONTADI_WORD_WIDTH ) then
            write_req_len           <= 
                update_info.Len(AXI_LENGTH_TYPE'left - Log2(C_TRIACONTADI_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) downto 0) & 
                (Log2(C_TRIACONTADI_WORD_WIDTH/C_EXTERNAL_DATA_WIDTH) - 1 downto 0=>'1');
          else
            write_req_len           <= update_info.Len;
            write_req_size          <= update_info.Size;
          end if;
      end case;
    end if;
  end process Gen_Write_Request;
  
  
  -----------------------------------------------------------------------------
  -- End of Transaction
  -----------------------------------------------------------------------------
  
  -- Determine when it is done.
  update_read_done_i  <= update_read_resize_valid and update_read_resize_last and update_read_resize_ready;
  update_write_done_i <= update_wm_pop_normal;
  
  
  -----------------------------------------------------------------------------
  -- Set Handling
  -- 
  -- Manipulate address and Set information to create/extract relevant
  -- addresses to Tag and Data.
  -----------------------------------------------------------------------------
  
  Use_Serial_Assoc: if( C_NUM_SERIAL_SETS > 1 ) generate
  begin
    -- Generate Tag address with serial set information.
    update_tag_trans_addr     <= update_cur_tag_set(C_SERIAL_SET_BIT_POS)  & update_info.Addr(C_ADDR_LINE_POS);
    update_tag_unlock_addr    <= ri_set(C_SERIAL_SET_BIT_POS) & ri_addr(C_ADDR_LINE_POS);
    update_data_line          <= update_cur_data_set(C_SERIAL_SET_BIT_POS) & update_data_base_line;
    
    Use_Parallel_Assoc: if( C_NUM_PARALLEL_SETS > 1 ) generate
    begin
      update_cur_tag_par_set    <= to_integer(unsigned(update_cur_tag_set(C_PARALLEL_SET_BIT_POS)));
      update_cur_data_par_set   <= to_integer(unsigned(update_cur_data_set(C_PARALLEL_SET_BIT_POS)));
      update_cur_evict_par_set  <= to_integer(unsigned(e_set(C_PARALLEL_SET_BIT_POS)));
    end generate Use_Parallel_Assoc;
    No_Parallel_Assoc: if( C_NUM_PARALLEL_SETS = 1 ) generate
    begin
      update_cur_tag_par_set    <= 0;
      update_cur_data_par_set   <= 0;
      update_cur_evict_par_set  <= 0;
    end generate No_Parallel_Assoc;
  end generate Use_Serial_Assoc;
  
  No_Serial_Assoc: if( C_NUM_SERIAL_SETS = 1 ) generate
  begin
    update_tag_trans_addr     <= update_info.Addr(C_ADDR_LINE_POS);
    update_tag_unlock_addr    <= ri_addr(C_ADDR_LINE_POS);
    update_data_line          <= update_data_base_line;
    update_cur_tag_par_set    <= to_integer(unsigned(update_cur_tag_set));
    update_cur_data_par_set   <= to_integer(unsigned(update_cur_data_set));
    update_cur_evict_par_set  <= to_integer(unsigned(e_set));
  end generate No_Serial_Assoc;
  
  
  -----------------------------------------------------------------------------
  -- Check Locked Tag
  -- 
  -- Control the readback of the Tag to check that it is still supposed to go 
  -- into the Cache and Tag.
  -----------------------------------------------------------------------------
  
  Single_External_Beat: if( C_EXTERNAL_DATA_WIDTH = 32 * C_CACHE_LINE_LENGTH ) generate
  begin
    -- Enable Tag for read back.
    update_readback_tag_en    <= update_rb_pos_phase;
  
    -- Determine if the Tag interface is free for use.
    update_rb_pos_phase       <= ri_exist and ri_allocate and not update_remove_locked_2nd_cycle;
    
    -- Determine if it is ok to proceed with read.
    update_remove_locked_safe <= ( ri_exist and not ri_allocate ) or
                                 ( ri_exist and     ri_allocate and update_remove_locked_2nd_cycle );
    
    -- Sequence handler for allocating
    Readback_Handle : process (ACLK) is
    begin  -- process Readback_Handle
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          update_remove_locked_2nd_cycle <= '0';
        else
          update_remove_locked_2nd_cycle <= backend_rd_data_valid and update_readback_possible and ri_exist and  
                                            ri_allocate and not update_remove_locked_2nd_cycle;
        end if;
      end if;
    end process Readback_Handle;
    
    -- Unused signal.
    update_first_word_safe          <= '1';
    
  end generate Single_External_Beat;
  
  Short_External_Burst: if( update_word_cnt_len'length < 2 ) and ( C_EXTERNAL_DATA_WIDTH < 32 * C_CACHE_LINE_LENGTH ) generate
  begin
    -- Enable Tag for read back.
    update_readback_tag_en    <= update_rb_pos_phase;
  
    -- Determine if the Tag interface is free for use.
    update_rb_pos_phase       <= update_read_miss_start and not update_readback_available;
    
    -- First word is also safe if one cacheline is two words.
    update_first_word_safe    <= update_read_miss_start_ok and update_readback_allowed when 
                                      ( C_EXTERNAL_DATA_WIDTH / C_CACHE_DATA_WIDTH > 1 ) else 
                                 '0';
    
    -- Determine if it is ok to proceed with read.
    update_remove_locked_safe <= ( ri_exist and not ri_allocate ) or
                                 ( ri_exist and     ri_allocate and 
                                   ( update_readback_available or update_first_word_safe ) );
    
    -- Unused signal.
    update_remove_locked_2nd_cycle  <= '0';
    
  end generate Short_External_Burst;
  
  Long_External_Burst: if( update_word_cnt_len'length >= 2 ) generate
  begin
    -- Enable Tag for read back.
    update_readback_tag_en    <= update_word_cnt_almost_last;
  
    -- Determine if the Tag interface is free for use.
    Update_Word_Cnt_Handle : process (ACLK) is
    begin  -- process Update_Word_Cnt_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if ARESET_I = '1' then                      -- synchronous reset (active high)
          update_rb_pos_phase <= '0';
          
        elsif( update_word_cnt_en = '1' ) then
          -- Detect if this was the last word for this evict/read miss.
          if( update_word_cnt_len = std_logic_vector(to_unsigned(2, update_word_cnt_len'length)) ) then
            update_rb_pos_phase <= ri_allocate and update_read_miss_ongoing;
          else
            update_rb_pos_phase <= '0';
          end if;
          
        end if;
      end if;
    end process Update_Word_Cnt_Handle;
    
    -- Determine if it is ok to proceed with read.
    update_remove_locked_safe <= ( ( update_readback_possible or update_readback_available or 
                                     update_tag_write_ignore or not update_word_cnt_almost_last ) and
                                   ( update_rm_alloc_ongoing ) ) or
                                 not update_rm_alloc_ongoing;
    
    -- Unused signal.
    update_first_word_safe          <= '1';
    update_remove_locked_2nd_cycle  <= '0';
  
  end generate Long_External_Burst;
  
  -- Determine if the Tag interface is free for use.
  update_readback_allowed   <= ( ( update_valid and not update_need_tag_write ) or 
                                 update_tag_write_ignore or not update_valid );
  update_readback_possible  <= update_readback_allowed and update_rb_pos_phase;
  
  -- Determine when the readback Tag is available.
  Tag_Readback_Handle : process (ACLK) is
  begin  -- process Tag_Readback_Handle
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_readback_available <= '0';
        update_readback_done      <= '0';
        update_cur_tag_rd_par_set <= 0;
      else
        if( update_readback_possible = '1' ) then
          update_readback_available <= '1';
          update_cur_tag_rd_par_set <= update_cur_tag_par_set;
        elsif( backend_rd_data_pop = '1' ) then
          update_readback_available <= '0';
        end if;
        
        if( backend_rd_data_pop = '1' ) then
          update_readback_done      <= '0';
        elsif( update_remove_locked = '1' ) then
          update_readback_done      <= '1';
        end if;
      end if;
    end if;
  end process Tag_Readback_Handle;
  
  -- Get the current Tag.
  update_readback_tag       <= update_tag_current_word_i(update_cur_tag_rd_par_set);
  
  -- Check if Tag in the current set matches the returned data.
  update_locked_tag_match   <= '1' when (ri_addr(C_ADDR_TAG_POS) = update_readback_tag(C_TAG_ADDR_POS) and ri_DSid = update_readback_tag(C_TAG_DSID_POS)) else '0';
  update_locked_tag_is_dead <= update_readback_available and not update_locked_tag_match;
  
  -- Determine when it is ok to remove a lock for readback Tag.
  update_remove_locked      <= ( update_readback_available and not update_locked_tag_is_dead ) and
                               ( ri_allocate ) and
                               ( backend_rd_data_pop );
  
  -- Insert read updates when safe.
  update_block_lookup       <= ( update_readback_possible and update_read_miss_ongoing );
  
  
  -----------------------------------------------------------------------------
  -- Control Update TAG
  -- 
  -- Refresh Tag when needed and readback old Tag for Locked checks.
  -----------------------------------------------------------------------------
  
  -- Create the new tag contents.
  update_new_tag(C_TAG_VALID_POS)   <= update_new_tag_valid;
  update_new_tag(C_TAG_REUSED_POS)  <= update_new_tag_reused;
  update_new_tag(C_TAG_DIRTY_POS)   <= update_new_tag_dirty;
  update_new_tag(C_TAG_LOCKED_POS)  <= update_new_tag_locked;
  update_new_tag(C_TAG_ADDR_POS)    <= update_new_tag_addr;
  update_new_tag(C_TAG_DSID_POS)    <= update_new_tag_DSid;
  
  -- Assign external signals.
  update_tag_addr_i     <= update_tag_unlock_addr when ( update_readback_possible or update_readback_available ) = '1' else
                           update_tag_trans_addr;
  Gen_Clean_Tag_Addr: for I in update_tag_addr'range generate
  begin
    update_tag_addr(I)    <= '1' when update_tag_addr_i(I) = '1' else '0';
  end generate Gen_Clean_Tag_Addr;
  update_tag_en         <= update_tag_en_i;
  update_tag_en_i       <= update_tag_write_raw or update_readback_available or update_readback_tag_en;
  update_tag_we         <= update_tag_we_i;
--  update_tag_we_i       <= (C_PARALLEL_SET_POS=>update_tag_write) and 
--                           std_logic_vector(to_unsigned(2 ** update_cur_tag_par_set, C_NUM_PARALLEL_SETS));
  
  Gen_Parallel_Tag: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    -- Is this the selected read-back parallel set?
--    update_sel_readback_tag(I)  <= ri_allocate when ( update_cur_tag_rd_par_set = I ) else
--                                   '0';

    update_select_readback(I) <= '1' when ( update_cur_tag_rd_par_set = I ) else '0';
    UD_Tag_And_Inst1: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => ri_allocate,
        A         => update_select_readback(I),
        Carry_OUT => update_sel_readback_tag(I)
      );
    
    -- Does the address still match?
    update_tag_match(I)         <= update_sel_readback_tag(I) when (ri_addr(C_ADDR_TAG_POS) = update_tag_current_word_i(I)(C_TAG_ADDR_POS) and
                                                                   ri_DSid                = update_tag_current_word_i(I)(C_TAG_DSID_POS)) else '0';
--    UD_Tag_Compare_Inst1: carry_compare
--      generic map(
--        C_TARGET  => C_TARGET,
--        C_SIZE    => C_NUM_ADDR_TAG_BITS
--      )
--      port map(
--       A_Vec     => ri_addr(C_ADDR_TAG_POS),
--        B_Vec     => update_tag_current_word_i(I)(C_TAG_ADDR_POS),
--        Carry_In  => update_sel_readback_tag(I),
 --       Carry_Out => update_tag_match(I)
--      );
    
    -- Are this the right phase?
--    update_tag_is_alive(I)      <= update_tag_match(I) and update_readback_available;
    UD_Tag_And_Inst2: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => update_tag_match(I),
        A         => update_readback_available,
        Carry_OUT => update_tag_is_alive(I)
      );
    
    -- Is the last word used?
--    update_tag_remove_lock(I)   <= update_tag_is_alive(I) and backend_rd_data_pop;
    UD_Tag_And_Inst3: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => update_tag_is_alive(I),
        A         => backend_rd_data_pop,
        Carry_OUT => update_tag_remove_lock(I)
      );
    
    -- Merge with normal tag write.
--    update_tag_we_i(I)          <= update_tag_remove_lock(I) or update_tag_write_raw_vec(I);
    UD_Tag_Or_Inst1: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => update_tag_remove_lock(I),
        A         => update_tag_write_raw_vec(I),
        Carry_OUT => update_tag_we_i(I)
      );
        
    -- Concatenate new Tag.
    update_tag_new_word((I+1)*C_TAG_SIZE - 1 downto I*C_TAG_SIZE) <= update_new_tag;
    
    -- Vectorize Tag.
    update_tag_current_word_i(I)  <= update_tag_current_word((I+1)*C_TAG_SIZE - 1 downto I*C_TAG_SIZE);
  end generate Gen_Parallel_Tag;

  
  -----------------------------------------------------------------------------
  -- Control Update DATA
  -- 
  -- Enable the parallel set pointed out by the current operation.
  -- 
  -- Concatenate to form new Data to be written for Read Miss, and vectorize
  -- current data for Evict.
  -----------------------------------------------------------------------------
  
  update_data_addr_i    <= update_data_line & update_word_cnt;
  Gen_Clean_Data_Addr: for I in update_data_addr'range generate
  begin
    update_data_addr(I)     <= '1' when update_data_addr_i(I) = '1' else '0';
  end generate Gen_Clean_Data_Addr;
  update_data_en_ii(0)  <= update_word_cnt_en;
--  update_data_en_i      <= (C_PARALLEL_SET_POS=>update_data_en_ii) and
--                           std_logic_vector(to_unsigned(2 ** update_cur_data_par_set, C_NUM_PARALLEL_SETS));
  Gen_Parallel_Data_En: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    update_data_en_sel_n(I) <= '0' when ( update_cur_data_par_set = I ) else
                               '1';
    
    UD_RD_And_Inst10: carry_latch_and_n
      generic map(
        C_TARGET  => C_TARGET,
        C_NUM_PAD => min_of(4, 2 + I * 4),
        C_INV_C   => false
      )
      port map(
        Carry_IN  => update_data_en_ii(I),
        A_N       => update_data_en_sel_n(I),
        O         => update_data_en_i(I),
        Carry_OUT => update_data_en_ii(I+1)
      );
  end generate Gen_Parallel_Data_En;
  
  update_data_en        <= update_data_en_i;

  update_data_we        <= (others=>update_wr_cnt_en);
  
  Gen_Merged_Data: for I in wma_strb'range generate
  begin
    update_data_new_word((I+1)*8 -1 downto I*8)  <= backend_rd_data_word((I+1)*8 -1 downto I*8) 
                                                          when ( ri_merge       = '0' ) or 
                                                               ( wma_strb(I)    = '0' ) or 
                                                               ( wma_merge_done = '1' ) else
                                                    wma_data((I+1)*8 -1 downto I*8);
  end generate Gen_Merged_Data;
  
  Gen_Parallel_Data: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    -- Vectorize Data.
    update_data_current_word_i(I) <= 
                update_data_current_word((I+1)*C_EXTERNAL_DATA_WIDTH - 1 downto I*C_EXTERNAL_DATA_WIDTH);
  end generate Gen_Parallel_Data;
  
  
  -----------------------------------------------------------------------------
  -- Queue for Data Eviction (Read Miss Dirty and Evict)
  --
  -- Store Set and Offset information in the Evict queue in order to free up
  -- the more critical part that relies on Tag access.
  -- 
  -- The que will be used by the data pointer controller in order to push
  -- data into the Write Data buffer. This is synchronized with Write Miss.
  -----------------------------------------------------------------------------
  
  -- Generate control signals.
  update_e_push     <= update_evict;
  update_e_pop      <= update_evict_stop and not e_fifo_empty;
  
  FIFO_E_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => false,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => update_e_push,
      queue_pop                 => update_e_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => e_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => e_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => e_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_ud_e,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => e_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for Evict FIFO.
  FIFO_Evict_Memory : process (ACLK) is
  begin  -- process FIFO_Evict_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( update_e_push = '1' ) then
        -- Insert new item.
        e_fifo_mem(0).Set       <= update_set;
        e_fifo_mem(0).Offset    <= update_info.Addr(C_ADDR_LINE_POS);
        
        -- Shift FIFO contents.
        e_fifo_mem(e_fifo_mem'left downto 1) <= e_fifo_mem(e_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_Evict_Memory;
  
  -- Rename signals.
  e_set                 <= e_fifo_mem(to_integer(unsigned(e_read_fifo_addr))).Set;
  e_offset              <= e_fifo_mem(to_integer(unsigned(e_read_fifo_addr))).Offset;
  
  
  -----------------------------------------------------------------------------
  -- Queue for Evict Done
  -- 
  -----------------------------------------------------------------------------
  
  -- Control Queue of completed WMA.
  ed_push <= update_e_pop and wm_evict and wm_will_use;
  ed_pop  <= ri_pop and ri_evicted;
  
  FIFO_ED_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => false,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => ed_push,
      queue_pop                 => ed_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => ed_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => ed_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => open,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => open,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => ed_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
  
  
  -----------------------------------------------------------------------------
  -- Update Data Pointer
  -- 
  -- Select if Evict or Read Miss (highest priority) shall have access to the 
  -- Data port.
  -- Cuurent Set and Line information is used from respective command.
  -- 
  -- Evict data is read and pushed to the Write Data buffer as quickly as 
  -- possible. Evict has to be synchronized with the Write Miss queue in order 
  -- to maintain the order relative to Write Address.
  -- 
  -- Read Miss data is written to the Data memory in the speed permitted by the 
  -- slave that provides it, and possibly throttled by any size conversions 
  -- needed.
  -----------------------------------------------------------------------------
  
  -- Generate control signals for counter.
  update_rd_cnt_en    <= ( ( wm_evict and wm_exist ) and (not e_fifo_empty) ) and 
                         ( not ( update_read_miss_start or update_read_miss_ongoing ) ) and
                         ( not update_wm_pop_evict_hold ) and 
                         ( not ( backend_rd_data_valid and ri_evicted and not ed_fifo_empty and 
                                 not update_evict_ongoing) ) and 
                         ( ( not write_data_almost_full and not write_data_full ) or 
                           ( write_data_full_d1         and not write_data_full ) );
  
  -- Select the current word offset to the Data memory.
  Update_Word_Cnt_Gen: process (update_word_cnt_first, backend_rd_data_valid, ri_addr, 
                                update_word_cnt_next, update_evict_ongoing, ri_set, 
                                e_set, e_offset, update_read_miss_wma_safe,
                                update_read_miss_safe, ri_allocate) is
  begin  -- process Update_Word_Cnt_Gen
    -- Determine base address for this transaction.
    if ( update_word_cnt_first = '1' ) then
      if ( ( backend_rd_data_valid and ri_allocate and update_read_miss_safe and update_read_miss_wma_safe ) = '1' ) then
        update_word_cnt <= ri_addr(C_ADDR_EXT_WORD_POS);
      else
        update_word_cnt <= (others=>'0');
      end if;
    else
      update_word_cnt <= update_word_cnt_next;
    end if;
    
    if ( ( backend_rd_data_valid and ri_allocate and update_read_miss_safe and not update_evict_ongoing and update_read_miss_wma_safe ) = '1' ) then
      -- Use line and set for read miss.
      update_cur_data_set   <= ri_set;
      update_data_base_line <= ri_addr(C_ADDR_LINE_POS);
    else
      -- Use evict queue information when not running read miss data.
      update_cur_data_set   <= e_set;
      update_data_base_line <= e_offset;
    end if;
  end process Update_Word_Cnt_Gen;
  
  -- Handle counter and flags.
  Update_Word_Cnt_Handle : process (ACLK) is
  begin  -- process Update_Word_Cnt_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        update_word_cnt_first       <= '1';
        update_word_cnt_last        <= '0';
        update_word_cnt_almost_last <= sel(update_word_cnt_len'length = 1, '1', '0');
        update_word_cnt_next        <= (others => '0');
        update_word_cnt_len         <= (others => '1');
        
      elsif( update_word_cnt_en = '1' ) then
        -- Handle first word status. Next is marked as first when last beat is used.
        if( update_word_cnt_last = '1' ) then
          update_word_cnt_first   <= '1';
        else
          update_word_cnt_first   <= '0';
        end if;
        
        -- Detect if this was the last word for this evict/read miss.
        if( update_word_cnt_len = std_logic_vector(to_unsigned(2, update_word_cnt_len'length)) ) then
          update_word_cnt_almost_last <= '1';
        else
          update_word_cnt_almost_last <= '0';
        end if;
        if( update_word_cnt_len = std_logic_vector(to_unsigned(1, update_word_cnt_len'length)) ) then
          update_word_cnt_last    <= '1';
        else
          update_word_cnt_last    <= '0';
        end if;
        
        -- Update remaining length and counter.
        update_word_cnt_next  <= std_logic_vector(unsigned(update_word_cnt) + 1);
        update_word_cnt_len   <= std_logic_vector(unsigned(update_word_cnt_len) - 1);
        
      end if;
    end if;
  end process Update_Word_Cnt_Handle;
  
  -- Detect when it is safe to start to use read miss data.
  update_read_miss_safe     <= ( ( ri_evicted and not ed_fifo_empty ) or not ri_evicted or update_read_miss_ongoing );
  update_read_miss_wma_safe <= ( ( ri_merge and ( wma_merge_done or not wma_fifo_empty ) ) or not ri_merge );
  
  -- Detect when a read miss is allowed to start.
  update_read_miss_start    <= backend_rd_data_valid and update_read_miss_start_ok;
  
  -- Start Evict counting when there is no read miss data avialable and there is available evict.
  update_evict_start        <= (wm_evict and wm_exist) and (not e_fifo_empty) and 
                               ( not ( backend_rd_data_valid and ri_evicted and not ed_fifo_empty ) ) and
                               ( not update_wm_pop_evict_hold ) and 
                               ( ((not backend_rd_data_valid) and (not update_read_miss_ongoing)) or
                                 ( ri_exist and ri_merge and wma_fifo_empty and not update_read_miss_ongoing) or
                                 ( ri_evicted and not update_read_miss_ongoing ) or
                                 not ri_allocate );
  
  -- Stop when last element has been processed.
  update_read_miss_stop     <= update_word_cnt_last and update_wr_cnt_en and update_read_miss_ongoing
                                      when ( C_EXTERNAL_DATA_WIDTH < 32 * C_CACHE_LINE_LENGTH ) else
                               update_word_cnt_last and update_wr_cnt_en;
  update_evict_stop         <= update_word_cnt_last and update_rd_cnt_en and update_evict_ongoing
                                      when ( C_EXTERNAL_DATA_WIDTH < 32 * C_CACHE_LINE_LENGTH ) else
                               update_word_cnt_last and update_rd_cnt_en and update_evict_start;
  
  -- Control the evict and read miss states.
  Update_Word_State_Handle : process (ACLK) is
  begin  -- process Update_Word_State_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        update_read_miss_ongoing  <= '0';
        update_rm_alloc_ongoing   <= '0';
        update_evict_ongoing      <= '0';
        update_evict_busy         <= '0';
        
      elsif( update_word_cnt_en = '1' ) then
        -- Start and stop of Read Miss Ongoing.
        if( update_read_miss_stop = '1' ) then
          update_read_miss_ongoing  <= '0';
          update_rm_alloc_ongoing   <= '0';
        elsif( update_read_miss_start = '1' ) then
          update_read_miss_ongoing  <= '1';
          update_rm_alloc_ongoing   <= ri_allocate;
        end if;
        
        -- Start and stop of Evict Ongoing.
        if( update_evict_stop = '1' ) then
          update_evict_ongoing      <= '0';
        elsif( update_evict_start = '1' ) then
          update_evict_ongoing      <= '1';
        end if;
      end if;
        
      -- Start and stop of Evict Busy.
      if( C_EXTERNAL_DATA_WIDTH < 32 * C_CACHE_LINE_LENGTH ) then
        if( ( update_evict_stop_d1 = '1' ) and not ( ( update_evict_start and update_word_cnt_en ) = '1' )  )then
          update_evict_busy         <= '0';
        elsif( update_evict_start = '1' ) and ( update_word_cnt_en = '1' ) then
          update_evict_busy         <= '1';
        end if;
      else
        update_evict_busy         <= update_evict_start and update_word_cnt_en;
      end if;
    end if;
  end process Update_Word_State_Handle;
  
  -- Set up Evict data stream to Write buffer.
  Update_Evict_Data_Handle : process (ACLK) is
  begin  -- process Update_Evict_Data_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        update_evict_valid          <= '0';
        update_evict_last           <= '0';
        write_data_full_d1          <= '0';
        update_evict_stop_d1        <= '0';
        update_cur_evict_par_set_d1 <= 0;
        
      else
        update_evict_valid          <= update_rd_cnt_en;
        update_evict_last           <= update_evict_stop;
        write_data_full_d1          <= write_data_full;
        update_evict_stop_d1        <= update_evict_stop;
        update_cur_evict_par_set_d1 <= update_cur_evict_par_set;
        
      end if;
    end if;
  end process Update_Evict_Data_Handle;
  
  -- Assign data from the correct set.
  update_evict_word           <= update_data_current_word_i(update_cur_evict_par_set_d1);
  
  -- Signal when the read miss data has been used.
  update_read_miss_use_bypass <= ( not ri_allocate ) when ri_exist = '1' else '0';
  
  
  -----------------------------------------------------------------------------
  -- Optimized Read Miss Use OK:
  -----------------------------------------------------------------------------
  
  -- Detect when a read miss is allowed to start.
  update_read_miss_start_ok <= ( ri_allocate and not update_evict_ongoing ) and 
                               ( update_read_miss_safe ) and ( update_read_miss_wma_safe )
                                    when ri_exist = '1' else 
                               '0';
  ud_rm_available_sel <= ri_exist and ri_allocate and not update_evict_ongoing;
  UD_RD_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => '1',
      A         => ud_rm_available_sel,
      Carry_OUT => ud_rm_available
    );
  
--  update_read_miss_use_ok     <= ( update_read_miss_start_ok or update_read_miss_ongoing ) or 
--                                 update_read_miss_use_bypass;
  ud_rm_use_sel <= update_read_miss_ongoing or update_read_miss_use_bypass;
  UD_RD_Or_Inst1: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => ud_rm_available,
      A         => ud_rm_use_sel,
      Carry_OUT => update_read_miss_use_ok
    );
  
  --
  -- Carry-chain continues and returns from R Queue region (for part of update_read_forward_ready).  
  --
  -- Leaves as: update_read_miss_use_ok
  -- Return as: update_read_miss_resize_ok
  --
    
  UD_RD_And_Inst4: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_read_miss_resize_ok,
      A         => update_read_miss_wma_safe,
      Carry_OUT => ud_rm_use_pre_safe
    );
  
  UD_RD_And_Inst5: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => ud_rm_use_pre_safe,
      A         => update_read_miss_safe,
      Carry_OUT => ud_rm_use_safe
    );
  
  UD_RD_And_Inst6: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => ud_rm_use_safe,
      A         => update_remove_locked_safe,
      Carry_OUT => ud_rm_use_and_lock_safe
    );
  
  -- Acknowledge external data.
--  backend_rd_data_ready_i <= update_read_miss_use_ok and update_read_forward_ready;
  UD_RD_And_Inst7: carry_and_n
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => ud_rm_use_and_lock_safe,
      A_N       => ARESET_I,
      Carry_OUT => backend_rd_data_ready_i
    );
  
  --
  -- Carry-chain continues and returns from Read Data Forwarding.  
  --
  -- Leaves as: backend_rd_data_ready_i
  -- Return as: backend_rd_data_use
  --
    
--  update_wr_cnt_en    <= ri_allocate and backend_rd_data_use and not update_evict_ongoing;
  ud_rm_sel_wr_cnt_en <= ri_allocate and not update_evict_ongoing;
  UD_RD_And_Inst9: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => backend_rd_data_use,
      A         => ud_rm_sel_wr_cnt_en,
      Carry_OUT => update_wr_cnt_en
    );
  
--  update_word_cnt_en  <= update_rd_cnt_en or update_wr_cnt_en;
  UD_RD_Or_Inst2: carry_or
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => update_wr_cnt_en,
      A         => update_rd_cnt_en,
      Carry_OUT => update_word_cnt_en
    );
  
  
  -----------------------------------------------------------------------------
  -- Queue for Write Extraction (Write Miss)
  -- 
  -- Write Miss transactions are queued so that Lookup doesn't stall.
  -- 
  -- Sequentially transfers data from ports according to queue order.
  -- Read Miss Dirty (evict bit) is used to synchronize the Evicted data with
  -- Write Miss data in the Write queues.
  -----------------------------------------------------------------------------
  
  
  -- Generate control signals.
  update_wm_push        <= lookup_push_write_miss;
  update_wm_pop_evict   <= update_evict_stop      and wm_exist;
  update_wm_pop_normal  <= update_use_write_word and access_data_last(update_write_port_i);
  update_wm_pop_allocate<= ( ( wm_evict and ( update_wm_pop_evict or update_wm_pop_evict_hold ) ) or not wm_evict ) and 
                           ( update_wm_pop_normal or update_wm_pop_normal_hold );
  update_wm_pop         <= ( update_wm_pop_evict    and not wm_allocate ) or 
                           ( update_wm_pop_normal   and not wm_allocate ) or
                           ( update_wm_pop_allocate );
  
  -- Keep track of busy status per port.
  Write_Miss_Handle : process (ACLK) is
  begin  -- process Write_Miss_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        update_write_miss_busy_i  <= (others=>'0');
      else
        for I in update_write_miss_busy_i'range loop
          if( update_wm_push = '1' and I = get_port_num(lookup_wm_info.Port_Num, C_NUM_PORTS) ) then
            update_write_miss_busy_i(I) <= '1';
          elsif( ( wm_exist and wm_fifo_empty and update_wm_pop ) = '1' ) then
            update_write_miss_busy_i(I) <= '0';
          end if;
        end loop;
      end if;
    end if;
  end process Write_Miss_Handle;
  
  update_write_miss_busy  <= update_write_miss_busy_i;
  
  FIFO_WM_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => true,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => update_wm_push,
      queue_pop                 => update_wm_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => wm_refresh_reg,
      
      queue_almost_full         => open,
      queue_full                => wm_fifo_full,
      queue_almost_empty        => wm_fifo_almost_empty,
      queue_empty               => wm_fifo_empty,
      queue_exist               => wm_exist,
      queue_line_fit            => open,
      queue_index               => wm_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_ud_wm,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => wm_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for Write Miss FIFO.
  FIFO_WM_Memory : process (ACLK) is
  begin  -- process FIFO_WM_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( update_wm_push = '1' ) then
        -- Insert new item.
        wm_fifo_mem(0).Port_Num <= get_port_num(lookup_wm_info.Port_Num, C_NUM_PORTS);
        wm_fifo_mem(0).Allocate <= lookup_wm_allocate;
        wm_fifo_mem(0).Evict    <= lookup_wm_evict;
        wm_fifo_mem(0).Will_Use <= lookup_wm_will_use;
        wm_fifo_mem(0).Kind     <= lookup_wm_info.Kind;
        wm_fifo_mem(0).Offset   <= lookup_wm_info.Addr(C_ADDR_OFFSET_POS);
        wm_fifo_mem(0).DSid     <= lookup_wm_info.DSid;
        wm_fifo_mem(0).Use_Bits <= lookup_wm_use_bits;
        wm_fifo_mem(0).Stp_Bits <= lookup_wm_stp_bits;
        wm_fifo_mem(0).Allow    <= lookup_wm_allow_write;
        
        -- Shift FIFO contents.
        wm_fifo_mem(wm_fifo_mem'left downto 1) <= wm_fifo_mem(wm_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_WM_Memory;
  
  -- Extract current Write Miss information.
  -- Store WM in register for good timing.
  WM_Data_Registers : process (ACLK) is
  begin  -- process WM_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        wm_port             <= C_NULL_WM.Port_Num;
        wm_allocate         <= C_NULL_WM.Allocate;
        wm_evict            <= C_NULL_WM.Evict;
        wm_will_use         <= C_NULL_WM.Will_Use;
        wm_offset           <= C_NULL_WM.Offset;
        wm_DSid             <= C_NULL_WM.DSid;
        wm_kind             <= C_NULL_WM.Kind;
        wm_use_bits         <= C_NULL_WM.Use_Bits;
        wm_stp_bits         <= C_NULL_WM.Stp_Bits;
        wm_local_wrap       <= '0';
        wm_allow            <= C_NULL_WM.Allow;
        wm_remove_unaligned <= (others=>'1');
        
      elsif( wm_refresh_reg = '1' ) then
        wm_port             <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Port_Num;
        wm_allocate         <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Allocate;
        wm_evict            <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Evict;
        wm_will_use         <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Will_Use;
        wm_offset           <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Offset;
        wm_DSid             <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).DSid;
        wm_kind             <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Kind;
        wm_use_bits         <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Use_Bits;
        wm_stp_bits         <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Stp_Bits;
        if( ( to_integer(unsigned(wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Use_Bits)) <
              (  C_EXTERNAL_DATA_WIDTH / 8 ) ) or 
            ( C_EXTERNAL_DATA_WIDTH = ( 32 * C_CACHE_LINE_LENGTH ) ) ) then
          wm_local_wrap       <= '1';
        else
          wm_local_wrap       <= '0';
        end if;
        wm_allow      <= wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Allow;
        if( ( wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Kind     = C_KIND_INCR ) and
            ( wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Allocate = '1'         ) )then
          wm_remove_unaligned <= not std_logic_vector(unsigned(wm_fifo_mem(to_integer(unsigned(wm_read_fifo_addr))).Stp_Bits) - 1);
        else
          wm_remove_unaligned <= (others=>'1');
        end if;
        
      end if;
    end if;
  end process WM_Data_Registers;
  
  -- Rename to external signal
  update_write_miss_full  <= wm_fifo_full;
  
  -- Handle Status of Write Miss Data popping.
  Write_Miss_Sequence_Handler : process (ACLK) is
  begin  -- process Write_Miss_Sequence_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_write_miss_ongoing <= '0';
      else
        if ( update_wm_pop_normal = '1' ) then
          update_write_miss_ongoing <= '0';
        elsif ( update_use_write_word = '1' ) then
          update_write_miss_ongoing <= '1';
        end if;
      end if;
    end if;
  end process Write_Miss_Sequence_Handler;
  
  -- Get the current port.
  update_write_port_i       <= wm_port;
  
  -- Determine when a data word is used.
  update_use_write_word     <= access_data_valid(update_write_port_i) and update_ack_write_word;
  
  -- Control popping of Write Miss data.
  update_ack_write_ext      <= ( not wm_allocate and not update_wr_miss_throttle );
  update_ack_write_alloc    <= (     wm_allocate and not update_wma_throttle );
  update_ack_write_word     <= ( wm_allocate or not wm_evict ) and 
                               ( not update_wm_pop_normal_hold ) and
                               ( wm_exist ) and 
                               ( wm_allocate or not update_evict_busy ) and 
                               ( update_ack_write_ext or update_ack_write_alloc );
  update_write_data_ready   <= update_write_data_ready_i;
  update_ack_write_word_vec <= (others => update_ack_write_word);
  update_write_data_ready_i <= update_ack_write_word_vec and 
                               std_logic_vector(to_unsigned(2 ** update_write_port_i, C_NUM_PORTS));
  
  -- Forward the write data for size manipulation.
  update_wr_miss_valid      <= update_use_write_word;
  
  wm_allow_vec              <= (others => wm_allow);

  -- Generate mux structures for write data.
  Use_Multi_WrData: if( C_NUM_PORTS > 1 ) generate
    signal access_be_word_i           : PORT_BE_TYPE;
    signal access_data_word_i         : PORT_DATA_TYPE;
  begin
    -- Split to local array.
    Gen_Port_Data_Array: for I in 0 to C_NUM_PORTS - 1 generate
    begin
      access_be_word_i(I)   <= access_data_be((I+1) * C_CACHE_DATA_WIDTH/8 - 1 downto I * C_CACHE_DATA_WIDTH/8);
      access_data_word_i(I) <= access_data_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
      
    end generate Gen_Port_Data_Array;
    
    -- Select hit data.
    update_wr_miss_last <= access_data_last(update_write_port_i);
    update_wr_miss_be   <= access_be_word_i(update_write_port_i) and wm_allow_vec;
    update_wr_miss_word <= access_data_word_i(update_write_port_i);
    
  end generate Use_Multi_WrData;
  
  -- Only one possible source for data.
  No_Multi_WrData: if( C_NUM_PORTS = 1 ) generate
  begin
    update_wr_miss_last <= access_data_last(0);
    update_wr_miss_be   <= access_data_be and wm_allow_vec;
    update_wr_miss_word <= access_data_word;
    
  end generate No_Multi_WrData;
  
  
  -----------------------------------------------------------------------------
  -- Write Size Conversion
  -- 
  -- Depending on the internal and interface data widths it is sometimes 
  -- necessary to perform width conversion:
  -- 
  -- Internal < Interface
  --   Write data mirroring and steering of the BE bit. No Data compression.
  -- 
  -- Internal = Interface
  --   Pass-through
  -- 
  -- Internal > Interface
  --   Multiplex data in sequence. The transaction also needs modification on  
  --   the AW channel.
  -- 
  -----------------------------------------------------------------------------
  
  -- Select current offset.
  update_wr_offset        <= wm_offset when ( update_write_miss_ongoing = '0' ) else update_wr_offset_cnt;
  
  -- Handle next offset that should be used.
  Write_Miss_Part_Handler : process (ACLK) is
  begin  -- process Write_Miss_Part_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_wr_offset_cnt <= (others=>'0');
      elsif( ( ( update_wr_miss_rs_valid ) = '1' ) or
             ( ( update_wma_insert_dummy ) = '1' ) ) then
        update_wr_offset_cnt <= update_wr_offset_cnt_cmb;
      end if;
    end if;
  end process Write_Miss_Part_Handler;
  
  -- Generate next value.
  -- Also, compensate for unaligned incr with native size.
  WM_Offset_Select: process (update_wr_offset, wm_offset, wm_use_bits, wm_stp_bits, wm_kind, wm_allocate,
                             wm_remove_unaligned) is
    variable update_wr_offset_cnt_next  : ADDR_OFFSET_TYPE;
  begin  -- process WM_Offset_Select
    update_wr_offset_cnt_next  := std_logic_vector(unsigned(update_wr_offset) + unsigned(wm_stp_bits));
    
    for I in update_wr_offset_cnt_cmb'range loop
      if( ( wm_use_bits(I) = '0' ) and 
          ( wm_kind = C_KIND_WRAP ) and
          ( ( C_CACHE_DATA_WIDTH < C_EXTERNAL_DATA_WIDTH ) or
            ( C_CACHE_DATA_WIDTH = C_EXTERNAL_DATA_WIDTH and ( wm_allocate = '0' ) ) ) ) then
        update_wr_offset_cnt_cmb(I) <= wm_offset(I);
      else
        update_wr_offset_cnt_cmb(I) <= update_wr_offset_cnt_next(I) and wm_remove_unaligned(I);
      end if;
    end loop;
  end process WM_Offset_Select;
  
  -- Detect if next word will be first part of next larger word.
  update_wr_next_word_addr    <= update_wr_offset_cnt_cmb and C_NATIVE_SIZE_BITS;
  update_wr_miss_restart_word <= '1' when ( to_integer(unsigned(update_wr_next_word_addr)) = 0 ) and 
                                          ( ( wm_kind = C_KIND_INCR ) or 
                                            ( wm_kind = C_KIND_WRAP and wm_local_wrap = '0' ) ) else 
                                 '0';
  
  Write_Internal_Same: if( C_CACHE_DATA_WIDTH = C_EXTERNAL_DATA_WIDTH ) generate
  begin
    -- No Throttle needed (besides FIFO full).
    update_wr_miss_word_done    <= '1';
    update_wr_miss_throttle     <= write_data_full;
    
    -- No translation needed.
    update_wr_miss_rs_valid     <= update_wr_miss_valid;
    update_wr_miss_rs_last      <= update_wr_miss_last;
    update_wr_miss_rs_be        <= update_wr_miss_be;
    update_wr_miss_rs_word      <= update_wr_miss_word;
    
  end generate Write_Internal_Same;
  
  Write_Internal_Different: if( C_CACHE_DATA_WIDTH /= C_EXTERNAL_DATA_WIDTH ) generate
    constant C_RATIO          : natural := max_of(C_CACHE_DATA_WIDTH, C_EXTERNAL_DATA_WIDTH) / 
                                           min_of(C_CACHE_DATA_WIDTH, C_EXTERNAL_DATA_WIDTH);
    subtype C_RATIO_POS       is natural range 0 to C_RATIO - 1;
    subtype RATIO_TYPE        is std_logic_vector(C_RATIO_POS);
    constant C_RATIO_BITS     : natural := Log2(C_RATIO);
    
    signal update_wr_miss_sel       : rinteger range 0 to C_RATIO - 1;
  begin
    -- Unique part for upsizing.
    Write_Internal_Narrow: if( C_CACHE_DATA_WIDTH < C_EXTERNAL_DATA_WIDTH ) generate
      subtype C_RATIO_BITS_POS  is natural range C_ADDR_EXT_BYTE_HI downto C_ADDR_EXT_BYTE_HI - C_RATIO_BITS + 1;
      subtype RATIO_BITS_TYPE   is std_logic_vector(C_RATIO_BITS_POS);
      
      signal update_wr_miss_sel_s     : RATIO_BITS_TYPE;
    begin
      -- Word selector.
      update_wr_miss_sel_s    <= update_wr_offset(C_RATIO_BITS_POS);
      update_wr_miss_sel      <= to_integer(unsigned(update_wr_miss_sel_s));
      
      -- Forward data valid.
      update_wr_miss_rs_valid <= update_wr_miss_valid;
      
      -- No Throttle needed.
      update_wr_miss_word_done<= '1';
      update_wr_miss_throttle <= write_data_full;
      
      -- Untouched last signal.
      update_wr_miss_rs_last  <= update_wr_miss_last;
      
      Gen_Mirror: for I in 0 to C_EXTERNAL_DATA_WIDTH / C_CACHE_DATA_WIDTH - 1 generate
      begin
        -- Generate mirrored data and steer byte enable.
        update_wr_miss_rs_be((I+1) * C_CACHE_DATA_WIDTH/8 - 1 downto I * C_CACHE_DATA_WIDTH/8)
                          <= update_wr_miss_be when ( update_wr_miss_sel = I ) 
                             else (others=>'0');
        update_wr_miss_rs_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH)
                          <= update_wr_miss_word;
      end generate Gen_Mirror;
      
    end generate Write_Internal_Narrow;
    
    -- Unique part for downsizing.
    Write_Internal_Wide: if( C_CACHE_DATA_WIDTH > C_EXTERNAL_DATA_WIDTH ) generate
      
      type RATIO_BE_TYPE               is array(C_RATIO_POS) of BE_TYPE;
      type RATIO_DATA_TYPE             is array(C_RATIO_POS) of DATA_TYPE;
      
      subtype C_RATIO_BITS_POS  is natural range C_ADDR_BYTE_HI downto C_ADDR_BYTE_HI - C_RATIO_BITS + 1;
      subtype RATIO_BITS_TYPE   is std_logic_vector(C_RATIO_BITS_POS);

      constant ratio_bits_one_vec : RATIO_BITS_TYPE := (others => '1');
      
      signal update_wr_miss_sel_s   : RATIO_BITS_TYPE;
      signal update_wr_miss_be_i    : RATIO_BE_TYPE; 
      signal update_wr_miss_word_i  : RATIO_DATA_TYPE; 
    begin
      -- Word selector.
      update_wr_miss_sel_s    <= update_wr_offset(C_RATIO_BITS_POS);
      update_wr_miss_sel      <= to_integer(unsigned(update_wr_miss_sel_s));
      
      -- Forward data valid.
      update_wr_miss_rs_valid <= update_wr_miss_valid;
      
      -- Throttle until last part of word.
      update_wr_miss_word_done<= '1' when (update_wr_miss_sel_s = ratio_bits_one_vec ) else '0';
      update_wr_miss_throttle <= write_data_full or not update_wr_miss_word_done;
      
      -- Mask last signal.
      update_wr_miss_rs_last  <= update_wr_miss_last when (update_wr_miss_sel_s = ratio_bits_one_vec ) else '0';
      
      -- Vectorize input.
      Gen_Vectorization: for I in 0 to C_EXTERNAL_DATA_WIDTH / C_CACHE_DATA_WIDTH - 1 generate
      begin
        -- Generate mirrored data and steer byte enable.
        update_wr_miss_be_i(I)    <= update_wr_miss_be((I+1) * C_EXTERNAL_DATA_WIDTH/8 - 1 downto 
                                                           I * C_EXTERNAL_DATA_WIDTH/8);
        update_wr_miss_word_i(I)  <= update_wr_miss_word((I+1) * C_EXTERNAL_DATA_WIDTH - 1 downto 
                                                             I * C_EXTERNAL_DATA_WIDTH);
      end generate Gen_Vectorization;
      
      -- Select be and data parts.
      update_wr_miss_rs_be    <= update_wr_miss_be_i(update_wr_miss_sel);
      update_wr_miss_rs_word  <= update_wr_miss_word_i(update_wr_miss_sel);
      
    end generate Write_Internal_Wide;
    
  end generate Write_Internal_Different;
  
  
  -----------------------------------------------------------------------------
  -- Write Miss Allocate Data Processing
  -- 
  -----------------------------------------------------------------------------
  
  -- Keep track if dummy data should be inserted.
  update_wma_select_port <= '1' when ( wm_kind = C_KIND_WRAP ) and
                                     ( ( ( update_wr_offset and not wm_use_bits ) = 
                                         ( wm_offset        and not wm_use_bits ) ) or
                                       ( wm_local_wrap = '1' ) ) else
                            '1' when ( wm_kind = C_KIND_INCR ) else
                            '0';
                            
  -- Insert dummy words.
  update_wma_insert_dummy <= ( wm_allocate and wm_exist and not update_wma_select_port ) and
                             ( not update_wma_fifo_stall );
  
  -- WMA data piece available.
  update_wma_data_valid   <= ( update_wr_miss_rs_valid and wm_allocate and update_wma_select_port ) or 
                             update_wma_insert_dummy;
  
  -- Throttle WM because FIFO is full.
  update_wma_fifo_stall   <= wma_fifo_almost_full or wma_fifo_full;
  update_wma_throttle     <= update_wma_fifo_stall or not update_wr_miss_word_done or 
                             not update_wma_select_port;
  
  -- Merge data into a word with full external width.
  WMA_Assembly_Handler : process (ACLK) is
  begin  -- process WMA_Assembly_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        wma_word_done_d1  <= '0';
        update_wma_last   <= '0';
        update_wma_strb   <= (others=>'0');
        update_wma_data   <= (others=>'0');
        
      else
        wma_word_done_d1  <= '0';
        
        -- Prepare for next word.
        if ( wma_word_done_d1 = '1' ) then
          update_wma_strb <= (others=>'0');
        end if;
        
        if( update_wma_data_valid = '1' ) then
          -- Delay done signal to clear next cycle.
          wma_word_done_d1  <= wma_word_done;
          
          -- Update last flag.
          update_wma_last   <= update_wr_miss_rs_last and update_wma_select_port;
          
          -- Insert new data, one byte at the time.
          for I in update_wr_miss_rs_be'range loop
            if( update_wr_miss_rs_be(I) = '1' ) then
              update_wma_strb(I)                      <= update_wr_miss_rs_be(I) and update_wma_select_port;
              update_wma_data((I+1)*8 -1 downto I*8)  <= update_wr_miss_rs_word((I+1)*8 -1 downto I*8);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process WMA_Assembly_Handler;
  
  -- Detect when word is complete.
  wma_word_done   <= update_wr_miss_restart_word or update_wr_miss_rs_last;
  
  -- Generate control signals.
  wma_push        <= wma_word_done_d1;
  
  
  -----------------------------------------------------------------------------
  -- Queue for Write Miss Allocate
  -- 
  -----------------------------------------------------------------------------
  
  -- Use data for merge.
--  wma_pop   <= backend_rd_data_use and ri_merge and not wma_fifo_empty and not wma_merge_done;
  wma_sel_pop_n <= not ( ri_merge and not wma_fifo_empty and not wma_merge_done );
  UD_RD_And_Inst8c: carry_latch_and_n
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 4,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => backend_rd_data_use_i,
      A_N       => wma_sel_pop_n,
      O         => wma_pop,
      Carry_OUT => backend_rd_data_use
    );
  
  
  FIFO_WMA_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => false,
      C_QUEUE_ADDR_WIDTH        => C_DATA_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => C_DATA_QUEUE_LINE_LENGTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => wma_push,
      queue_pop                 => wma_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => wma_fifo_almost_full,
      queue_full                => wma_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => wma_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => wma_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_ud_wma,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => wma_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for Write Miss Allocate FIFO.
  FIFO_WMA_Memory : process (ACLK) is
  begin  -- process FIFO_WMA_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( wma_push = '1' ) then
        -- Insert new item.
        wma_fifo_mem(0).Last  <= update_wma_last;
        wma_fifo_mem(0).Strb  <= update_wma_strb;
        wma_fifo_mem(0).Data  <= update_wma_data;
        
        -- Shift FIFO contents.
        wma_fifo_mem(wma_fifo_mem'left downto 1) <= wma_fifo_mem(wma_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_WMA_Memory;
  
  -- Extract current Write Miss information.
  wma_last  <= wma_fifo_mem(to_integer(unsigned(wma_read_fifo_addr))).Last;
  wma_strb  <= wma_fifo_mem(to_integer(unsigned(wma_read_fifo_addr))).Strb;
  wma_data  <= wma_fifo_mem(to_integer(unsigned(wma_read_fifo_addr))).Data;
  
  -- Handle merge sequence.
  WMA_Merge_Sequence_Handler : process (ACLK) is
  begin  -- process WMA_Merge_Sequence_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        wma_merge_done  <= '0';
        
      else
        if( (backend_rd_data_pop ) = '1' ) then
          -- Last word of read burst releases end of merge.
          wma_merge_done  <= '0';
          
        elsif( wmad_done = '1' ) then
          -- Last word in write data burst sets end of merge.
          wma_merge_done  <= '1';
          
        end if;
      end if;
    end if;
  end process WMA_Merge_Sequence_Handler;
  
  --
  WM_Pop_Handler : process (ACLK) is
  begin  -- process WM_Pop_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_wm_pop_evict_hold  <= '0';
        update_wm_pop_normal_hold <= '0';
        
      else
        if( update_wm_pop = '1' ) then
          -- All relevant sources has occured, go back to idle state.
          update_wm_pop_evict_hold  <= '0';
          
        elsif( ( update_wm_pop_evict ) = '1' ) then
          -- Evict is completed but still waiting for WMA data to complete.
          update_wm_pop_evict_hold  <= '1';
          
        end if;
        
        if( update_wm_pop = '1' ) then
          -- All relevant sources has occured, go back to idle state.
          update_wm_pop_normal_hold <= '0';
          
        elsif( ( update_wm_pop_normal ) = '1' ) then
          -- WMA burst has completed but still waiting for Evict to complete.
          update_wm_pop_normal_hold <= '1';
          
        end if;
        
      end if;
    end if;
  end process WM_Pop_Handler;
  
    
  -----------------------------------------------------------------------------
  -- Queue for Write Miss Allocate Done
  -- 
  -----------------------------------------------------------------------------
  
  -- Control Queue of completed WMA.
  wmad_done <= ( wma_pop and wma_last );
  wmad_push <= update_wm_pop_normal and wm_allocate and wm_evict;
  wmad_pop  <= bs_insert and update_bs_pop;
  
  FIFO_WMAD_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => false,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => wmad_push,
      queue_pop                 => wmad_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => wmad_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => wmad_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => open,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => open,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => wmad_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
  
  
  -----------------------------------------------------------------------------
  -- Write Data Mux
  -- 
  -- Select if the Write Miss data or Evicted data should be forwarded to the
  -- Write data queue.
  -----------------------------------------------------------------------------
  
  -- Select data source for Write Data buffer.
  write_data_valid_i  <= ( update_wr_miss_rs_valid and not wm_allocate ) 
                                                 when ( update_evict_busy = '0' ) else update_evict_valid;
  write_data_valid    <= write_data_valid_i;
  write_data_last_i   <= update_wr_miss_rs_last  when ( update_evict_busy = '0' ) else update_evict_last;
  write_data_last     <= write_data_last_i;
  write_data_be       <= update_wr_miss_rs_be    when ( update_evict_busy = '0' ) else (others=>'1');
  write_data_word     <= update_wr_miss_rs_word  when ( update_evict_busy = '0' ) else update_evict_word;
  
  
  -----------------------------------------------------------------------------
  -- Read Information Buffer
  -----------------------------------------------------------------------------
  
  -- Control signals for read data info buffer.
  ri_push           <= read_req_valid_i;
  ri_pop            <= backend_rd_data_valid and backend_rd_data_last and backend_rd_data_ready_i;
  
  FIFO_RI_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => true,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => ri_push,
      queue_pop                 => ri_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => ri_refresh_reg,
      
      queue_almost_full         => open,
      queue_full                => ri_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => ri_fifo_empty,
      queue_exist               => ri_exist,
      queue_line_fit            => open,
      queue_index               => ri_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_ud_ri,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => ri_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for RI Channel FIFO.
  FIFO_RI_Memory : process (ACLK) is
  begin  -- process FIFO_RI_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( ri_push = '1' ) then
        -- Insert new item.
        ri_fifo_mem(0).Port_Num     <= get_port_num(update_info.Port_Num, C_NUM_PORTS);
        ri_fifo_mem(0).Set          <= update_set;
        ri_fifo_mem(0).Addr         <= update_info.Addr(C_ADDR_INTERNAL_POS);
        ri_fifo_mem(0).Use_Bits     <= update_use_bits;
        ri_fifo_mem(0).Stp_Bits     <= update_stp_bits;
        ri_fifo_mem(0).Kind         <= update_info.Kind;
        ri_fifo_mem(0).Len          <= update_info.Len;
        ri_fifo_mem(0).Allocate     <= update_info.Allocate;
        ri_fifo_mem(0).Evicted_Line <= update_need_evict;
        ri_fifo_mem(0).Write_Merge  <= update_info.Wr;
        ri_fifo_mem(0).IsShared     <= update_info.IsShared;
        ri_fifo_mem(0).PassDirty    <= update_info.PassDirty;
        ri_fifo_mem(0).Exclusive    <= update_info.Exclusive;
        ri_fifo_mem(0).DSid         <= update_info.DSid;
        
        -- Shift FIFO contents.
        ri_fifo_mem(ri_fifo_mem'left downto 1) <= ri_fifo_mem(ri_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_RI_Memory;

  -- Store RI in register for good timing.
  RI_Data_Registers : process (ACLK) is
  begin  -- process RI_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        ri_port       <= C_NULL_RI.Port_Num;
        ri_hot_port   <= C_NULL_RI.Hot_Port;
        ri_set        <= C_NULL_RI.Set;
        ri_addr       <= C_NULL_RI.Addr;
        ri_use        <= C_NULL_RI.Use_Bits;
        ri_stp        <= C_NULL_RI.Stp_Bits;
        ri_kind       <= C_NULL_RI.Kind;
        ri_len        <= C_NULL_RI.Len;
        ri_allocate   <= C_NULL_RI.Allocate;
        ri_evicted    <= C_NULL_RI.Evicted_Line;
        ri_merge      <= C_NULL_RI.Write_Merge;
        ri_isshared   <= C_NULL_RI.IsShared;
        ri_passdirty  <= C_NULL_RI.PassDirty;
        ri_exclusive  <= C_NULL_RI.Exclusive;
        ri_DSid       <= C_NULL_RI.DSid;
        
      elsif( ri_refresh_reg = '1' ) then
        ri_port     <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Port_Num;
        ri_hot_port <= std_logic_vector(to_unsigned(2 ** ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Port_Num, 
                                                    C_NUM_PORTS));
        ri_set        <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Set;
        ri_addr       <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Addr;
        ri_use        <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Use_Bits;
        ri_stp        <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Stp_Bits;
        ri_kind       <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Kind;
        ri_len        <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Len;
        ri_allocate   <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Allocate;
        ri_evicted    <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Evicted_Line;
        ri_merge      <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Write_Merge;
        ri_isshared   <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).IsShared;
        ri_passdirty  <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).PassDirty;
        ri_exclusive  <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Exclusive;
        ri_DSid       <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).DSid;
        
      end if;
    end if;
  end process RI_Data_Registers;
  
  
  -----------------------------------------------------------------------------
  -- Read Data Forwarding
  -- 
  -- Handle the forwarding of data to both the Data memory and the source port
  -- via any potential resizing.
  -- 
  -- Wider external data is buffered in order to stall the Data memory.
  -----------------------------------------------------------------------------
  
  -- Flow control for read miss data.
--  backend_rd_data_use     <= backend_rd_data_valid and backend_rd_data_ready_i;
  UD_RD_And_Inst8: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => backend_rd_data_ready_i,
      A         => backend_rd_data_valid,
      Carry_OUT => backend_rd_data_use_ii
    );
  
--  backend_rd_data_pop     <= backend_rd_data_use and backend_rd_data_last;
  backend_rd_data_last_n  <= not backend_rd_data_last;
  UD_RD_And_Inst8b: carry_latch_and_n
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => backend_rd_data_use_ii,
      A_N       => backend_rd_data_last_n,
      O         => backend_rd_data_pop,
      Carry_OUT => backend_rd_data_use_i
    );
  
  -- Acknowledge external data.
  backend_rd_data_ready   <= backend_rd_data_ready_i;
  
  -- Handle RRESP.
  backend_rd_data_real_rresp  <= C_RRESP_EXOKAY(1 downto 0) when 
                                         ( ( ri_exclusive = '1' ) and
                                         ( backend_rd_data_rresp /= C_RRESP_DECERR(1 downto 0) ) and 
                                         ( backend_rd_data_rresp /= C_RRESP_SLVERR(1 downto 0) ) and 
                                         ( is_on(C_ENABLE_COHERENCY + C_ENABLE_EX_MON) /= 0 ) ) else
                                 backend_rd_data_rresp;
  
  -- Buffer read data stream.
  Use_Read_FIFO: if( C_CACHE_DATA_WIDTH < C_EXTERNAL_DATA_WIDTH ) generate
  
    signal r_push                     : std_logic;
    signal r_pop                      : std_logic;
    signal r_read_fifo_addr           : DATA_QUEUE_ADDR_TYPE:= (others=>'1');
    signal r_fifo_mem                 : R_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
    signal r_fifo_almost_full         : std_logic;
    signal r_fifo_full                : std_logic;
    signal r_fifo_almost_empty        : std_logic;
    signal r_fifo_empty               : std_logic;
    
    
  begin
    -- Control signals for read data queue.
    r_push            <= backend_rd_data_use and not ri_merge;
    r_pop             <= update_read_resize_valid and update_read_resize_ready;
    
    FIFO_R_Pointer: sc_srl_fifo_counter
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
        
        -- Configuration.
        C_PUSH_ON_CARRY           => false,
        C_POP_ON_CARRY            => false,
        C_ENABLE_PROTECTION       => false,
        C_USE_QUALIFIER           => false,
        C_QUALIFIER_LEVEL         => 0,
        C_USE_REGISTER_OUTPUT     => false,
        C_QUEUE_ADDR_WIDTH        => C_DATA_QUEUE_LENGTH_BITS,
        C_LINE_LENGTH             => C_DATA_QUEUE_LINE_LENGTH
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET_I,
    
        -- ---------------------------------------------------
        -- Queue Counter Interface
        
        queue_push                => r_push,
        queue_pop                 => r_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => open,
        queue_full                => r_fifo_full,
        queue_almost_empty        => open,
        queue_empty               => r_fifo_empty,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => r_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => stat_ud_r,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => r_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Handle memory for R Channel FIFO.
    FIFO_R_Memory : process (ACLK) is
    begin  -- process FIFO_R_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( r_push = '1') then
          -- Insert new item.
          r_fifo_mem(0).Last      <= backend_rd_data_last;
          r_fifo_mem(0).Port_Num  <= ri_port;
          r_fifo_mem(0).Hot_Port  <= ri_hot_port;
          r_fifo_mem(0).Addr      <= ri_addr;
          r_fifo_mem(0).Data      <= backend_rd_data_word;
          r_fifo_mem(0).Rresp(backend_rd_data_rresp'range)  <= backend_rd_data_real_rresp;
          if( C_ENABLE_COHERENCY /= 0 ) then
            r_fifo_mem(0).Rresp(C_RRESP_ISSHARED_POS)       <= ri_isshared;
            r_fifo_mem(0).Rresp(C_RRESP_PASSDIRTY_POS)      <= ri_passdirty;
          end if;
          r_fifo_mem(0).Use_Bits  <= ri_use;
          r_fifo_mem(0).Stp_Bits  <= ri_stp;
          r_fifo_mem(0).Kind      <= ri_kind;
          r_fifo_mem(0).Len       <= ri_len;
          r_fifo_mem(0).Allocate  <= ri_allocate;
          
          -- Shift FIFO contents.
          r_fifo_mem(r_fifo_mem'left downto 1) <= r_fifo_mem(r_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_R_Memory;
    
    -- FIFO output.
    update_read_resize_valid    <= not r_fifo_empty;
    update_read_resize_last     <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Last;
    update_read_resize_port     <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Port_Num;
    update_read_resize_hot_port <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Hot_Port;
    update_read_resize_addr     <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Addr;
    update_read_resize_offset   <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Addr(C_ADDR_OFFSET_POS);
    update_read_resize_use_bits <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Use_Bits;
    update_read_resize_stp_bits <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Stp_Bits;
    update_read_resize_kind     <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Kind;
    update_read_resize_len      <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Len;
    update_read_resize_allocate <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Allocate;
    update_read_resize_word     <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Data;
    update_read_resize_rresp    <= r_fifo_mem(to_integer(unsigned(r_read_fifo_addr))).Rresp;
    
    -- Trottle data with FIFO Full.
    update_read_forward_ready   <= update_remove_locked_safe and update_read_miss_safe and update_read_miss_wma_safe and 
                                   not r_fifo_full;
    
    -- Enter as: update_read_miss_use_ok
    -- Leave as: update_read_miss_resize_ok
    
    UD_RD_USE_R_And_Inst1: carry_and_n
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => update_read_miss_use_ok,
        A_N       => r_fifo_full,
        Carry_OUT => update_read_miss_resize_ok
      );
    
  end generate Use_Read_FIFO;
  
  -- No FIFO used to prevent slowing down write to Data BRAM.
  No_Read_FIFO: if( C_CACHE_DATA_WIDTH >= C_EXTERNAL_DATA_WIDTH ) generate
  begin
    -- Forward read data untouched.
    update_read_resize_valid    <= backend_rd_data_valid and update_remove_locked_safe and update_read_miss_safe and 
                                   not ( ri_allocate and update_evict_ongoing ) and 
                                   not ri_merge;
    update_read_resize_last     <= backend_rd_data_last;
    update_read_resize_port     <= ri_port;
    update_read_resize_hot_port <= ri_hot_port;
    update_read_resize_addr     <= ri_addr;
    update_read_resize_offset   <= ri_addr(C_ADDR_OFFSET_POS);
    update_read_resize_use_bits <= ri_use;
    update_read_resize_stp_bits <= ri_stp;
    update_read_resize_kind     <= ri_kind;
    update_read_resize_len      <= ri_len;
    update_read_resize_allocate <= ri_allocate;
    update_read_resize_word     <= backend_rd_data_word;
    update_read_resize_rresp(backend_rd_data_real_rresp'range) <= backend_rd_data_real_rresp;
    Use_RRESP_Extra_Bits: if( C_ENABLE_COHERENCY /= 0 ) generate
    begin
      update_read_resize_rresp(C_RRESP_ISSHARED_POS)  <= ri_isshared;
      update_read_resize_rresp(C_RRESP_PASSDIRTY_POS) <= ri_passdirty;
    end generate Use_RRESP_Extra_Bits;
    
    -- Directly return ready.
    update_read_forward_ready   <= update_remove_locked_safe and update_read_miss_safe and 
                                   update_read_miss_wma_safe and update_read_resize_ready;
    
    -- No FIFO.
    stat_ud_r <= C_NULL_STAT_FIFO;
    r_assert  <= '0';
    
    -- Enter as: update_read_miss_use_ok
    -- Leave as: update_read_miss_resize_ok
    
--    update_read_resize_used     <= ( ( update_read_resize_selected and update_read_data_ready(update_read_resize_port) ) or
--                                     ( not update_read_resize_selected ) or 
--                                     ( update_read_resize_finish ) ) ;
--    update_read_resize_ready    <= ( update_read_resize_used and 
--                                     ( update_read_resize_finish or 
--                                       not update_read_resize_allocate or 
--                                       not update_rd_miss_throttle ) );
    ud_rm_resize_part_sel <= ( update_read_resize_finish or 
                               not update_read_resize_allocate or 
                               not update_rd_miss_throttle );
    update_read_resize_selected_vec <= (others => update_read_resize_selected);
    update_read_resize_finish_vec   <= (others => update_read_resize_finish);
    ud_rm_port_forward  <= ( ( update_read_resize_selected_vec and update_read_data_ready ) or
                             not update_read_resize_selected_vec or 
                             update_read_resize_finish_vec );
    
    UD_RD_NO_R_And_Inst1: carry_and
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => update_read_miss_use_ok,
        A         => ud_rm_resize_part_sel,
        Carry_OUT => ud_rm_use_resize_part_ok
      );
    
    UD_RD_NO_R_And_Inst2: carry_select_and
      generic map(
        C_TARGET  => C_TARGET,
        C_SIZE    => C_NUM_PORTS
      )
      port map(
        Carry_In  => ud_rm_use_resize_part_ok,
        No        => update_read_resize_port,
        A_Vec     => ud_rm_port_forward,
        Carry_Out => update_read_miss_resize_ok
      );
    
  end generate No_Read_FIFO;
  
  
  -----------------------------------------------------------------------------
  -- Read Size Conversion
  -- 
  -- Depending on the internal and interface data widths it is sometimes 
  -- necessary to perform width conversion:
  -- 
  -- Internal < Interface
  --   Multiplex data in sequence. The transaction also needs modification on  
  --   the AR channel.
  -- 
  -- Internal = Interface
  --   Pass-through
  -- 
  -- Internal > Interface
  --   Read data mirroring.
  -- 
  -----------------------------------------------------------------------------
  
  -- Select current offset.
  update_rd_offset          <= update_read_resize_offset when ( update_read_resize_first = '1' ) else 
                               update_rd_offset_cnt;
  
  -- Select current length.
  update_rd_len             <= update_read_resize_len    when ( update_read_resize_first = '1' ) else 
                               update_rd_len_cnt;
  
  -- Calculate next offset.
  RM_Offset_Select: process (update_rd_offset, update_read_resize_offset, 
                                 update_read_resize_kind, update_read_resize_allocate, 
                                 update_read_resize_use_bits, update_read_resize_stp_bits) is
    variable update_rd_offset_cnt_next_cmb  : ADDR_OFFSET_TYPE;
  begin  -- process RM_Offset_Select
    update_rd_offset_cnt_next_cmb     := std_logic_vector(unsigned(update_rd_offset) + 
                                                          unsigned(update_read_resize_stp_bits));
    
    for I in update_rd_offset_cnt_next'range loop
      if( ( update_read_resize_use_bits(I) = '0' )  and 
          ( update_read_resize_kind = C_KIND_WRAP ) and 
          ( ( C_CACHE_DATA_WIDTH < C_EXTERNAL_DATA_WIDTH ) or
            ( C_CACHE_DATA_WIDTH = C_EXTERNAL_DATA_WIDTH and ( update_read_resize_allocate = '0' ) ) ) ) then
        update_rd_offset_cnt_next(I)  <= update_read_resize_offset(I);
        
      else
        update_rd_offset_cnt_next(I)  <= update_rd_offset_cnt_next_cmb(I);
        
      end if;
    end loop;
  end process RM_Offset_Select;
  
  -- Calculate next length.
  update_rd_len_cnt_next    <= std_logic_vector(unsigned(update_rd_len) - 1);
  
  -- Handle next offset that should be used.
  Read_Miss_Part_Handler : process (ACLK) is
  begin  -- process Read_Miss_Part_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_rd_offset_cnt      <= (others=>'0');
        update_read_resize_first  <= '1';
        update_read_resize_finish <= '0';
        
      elsif ( ( update_read_resize_valid and     update_read_resize_selected and update_read_resize_used ) = '1' ) or 
            ( ( update_read_resize_valid and not update_read_resize_selected ) = '1' ) then
        update_rd_offset_cnt      <= update_rd_offset_cnt_next;
        update_read_resize_first  <= update_read_resize_last and update_read_resize_ready;
        
        if( update_read_resize_last = '1' ) then
          update_read_resize_finish <= '0';
          
        elsif( update_read_data_last_i = '1' ) and 
             ( ( update_read_resize_kind /= C_KIND_WRAP ) or 
               ( update_read_resize_selected = '1' and update_read_resize_kind = C_KIND_WRAP ) ) then
          update_read_resize_finish <= '1';
          
        end if;
      end if;
    end if;
  end process Read_Miss_Part_Handler;
  
  -- Handle next length that should be used.
  Read_Miss_Length_Handler : process (ACLK) is
  begin  -- process Read_Miss_Length_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_rd_len_cnt         <= (others=>'0');
        
      elsif ( update_read_resize_valid and update_read_resize_selected and update_read_resize_used ) = '1' then
        update_rd_len_cnt         <= update_rd_len_cnt_next;
        
      end if;
    end if;
  end process Read_Miss_Length_Handler;
  
  -- Handle data for Incr.
  Read_Incr_Handler : process (ACLK) is
  begin  -- process Read_Incr_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_rd_incr_ok <= '1';
        
      elsif( update_read_resize_valid = '1' ) then
        if( ( update_read_resize_last and update_read_resize_ready ) = '1' ) then
          update_rd_incr_ok <= '1';
          
        elsif( ( update_read_data_last_i and update_read_resize_ready ) = '1' ) then
          update_rd_incr_ok <= '0';
          
        end if;
      end if;
    end if;
  end process Read_Incr_Handler;
  
  -- Handle data for Wrap.
  Read_Wrap_Handler : process (ACLK) is
  begin  -- process Read_Wrap_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_rd_wrap_ok <= '1';
        
      elsif( ( update_read_resize_valid and update_read_resize_ready ) = '1' ) then
        if( ( update_read_resize_sel_wrap or update_read_resize_last ) = '1' ) then
          update_rd_wrap_ok <= '1';
          
        elsif( update_read_resize_sel_wrap = '0' ) then
          update_rd_wrap_ok <= '0';
          
        end if;
      end if;
    end if;
  end process Read_Wrap_Handler;
  
  -- Response handling.
  No_Rd_Coherent: if( C_ENABLE_COHERENCY = 0 ) generate
  begin
    update_read_data_resp_i(3 downto 2)  <= (others=>'0');
  end generate No_Rd_Coherent;
  update_read_data_resp_i(update_read_resize_rresp'range)  <= update_read_resize_rresp;
  update_read_data_resp       <= update_read_data_resp_i;
  
  -- Determine if this word shall be forwarded as a valid read miss data.
  update_read_resize_sel_wrap <= not update_read_resize_finish when
                                   ( update_read_resize_kind = C_KIND_WRAP ) and
                                   ( ( update_rd_offset_cnt_next and not update_read_resize_use_bits ) = 
                                     ( update_read_resize_offset and not update_read_resize_use_bits ) ) else
                                 '0';
--  update_read_resize_selected <= update_rd_incr_ok when ( update_read_resize_kind = C_KIND_INCR ) else 
--                                 update_rd_wrap_ok;
  -- Handle data for Wrap.
  Read_Select_Handler : process (ACLK) is
  begin  -- process Read_Select_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        update_read_resize_selected <= '1';
        
      elsif( ( update_read_resize_valid and update_read_resize_ready ) = '1' ) then
        if( update_read_resize_kind = C_KIND_INCR ) then
          -- Incr
          if( ( update_read_resize_last ) = '1' ) then
            update_read_resize_selected <= '1';
            
          elsif( ( update_read_data_last_i ) = '1' ) then
            update_read_resize_selected <= '0';
            
          end if;
          
        else
          -- Wrap
          if( ( update_read_resize_sel_wrap or update_read_resize_last ) = '1' ) then
            update_read_resize_selected <= '1';
            
          elsif( update_read_resize_sel_wrap = '0' ) then
            update_read_resize_selected <= '0';
            
          end if;
        end if;
      end if;
    end if;
  end process Read_Select_Handler;
  
  -- Size matches, just forward all signals.
  update_read_data_valid_i    <= ( update_read_resize_selected and update_read_resize_valid and 
                                   not update_read_resize_finish);
  update_read_data_valid_vec  <= (others => update_read_data_valid_i);
  update_read_data_valid_ii   <= update_read_data_valid_vec and 
                                 update_read_resize_hot_port;
  update_read_data_valid      <= update_read_data_valid_ii;
  
  -- Generate last bit.
  update_read_data_last_i     <= '1' when to_integer(unsigned(update_rd_len)) = 0 else '0';
  
  -- Data throttling.
  update_read_resize_used     <= ( ( update_read_resize_selected and update_read_data_ready(update_read_resize_port) ) or
                                   ( not update_read_resize_selected ) or 
                                   ( update_read_resize_finish ) ) ;
  update_read_resize_ready    <= ( update_read_resize_used and 
                                   ( update_read_resize_finish or 
                                     not update_read_resize_allocate or 
                                     not update_rd_miss_throttle ) );
  
  
  -- Handle read miss data sequence.
  Read_Internal_Same_Or_Wide: if( C_CACHE_DATA_WIDTH >= C_EXTERNAL_DATA_WIDTH ) generate
  begin
    -- Data forward including mirroring when necessary.
    Gen_Mirror: for I in 0 to C_CACHE_DATA_WIDTH / C_EXTERNAL_DATA_WIDTH - 1 generate
    begin
      -- Generate mirrored data and steer byte enable.
      update_read_data_word((I+1) * C_EXTERNAL_DATA_WIDTH - 1 downto I * C_EXTERNAL_DATA_WIDTH)
                        <= update_read_resize_word;
    end generate Gen_Mirror;
    
    -- Data word throttling.
    update_rd_miss_throttle   <= '0';
    
    -- Unused.
    update_rd_miss_th_incr  <= '0';
    update_rd_miss_th_wrap  <= '0';
    
  end generate Read_Internal_Same_Or_Wide;
  
  
  Read_Internal_Narrow: if( C_CACHE_DATA_WIDTH < C_EXTERNAL_DATA_WIDTH ) generate
  
    constant C_RATIO          : natural := max_of(C_CACHE_DATA_WIDTH, C_EXTERNAL_DATA_WIDTH) / 
                                           min_of(C_CACHE_DATA_WIDTH, C_EXTERNAL_DATA_WIDTH);
    subtype C_RATIO_POS       is natural range 0 to C_RATIO - 1;
    subtype RATIO_TYPE        is std_logic_vector(C_RATIO_POS);
    constant C_RATIO_BITS     : natural := Log2(C_RATIO);
    subtype C_RATIO_BITS_POS  is natural range C_ADDR_EXT_BYTE_HI downto C_ADDR_EXT_BYTE_HI - C_RATIO_BITS + 1;
    subtype RATIO_BITS_TYPE   is std_logic_vector(C_RATIO_BITS_POS);
    
    type RATIO_DATA_TYPE             is array(C_RATIO_POS) of DATA_TYPE;

    constant ratio_bits_one_vec : RATIO_BITS_TYPE := (others => '1');
    
    signal update_rd_miss_sel_s     : RATIO_BITS_TYPE;
    signal update_rd_miss_sel       : C_RATIO_POS;
    signal update_rd_miss_word_i    : RATIO_DATA_TYPE; 
    
  begin
    -- Vectorize input.
    Gen_Vectorization: for I in 0 to C_EXTERNAL_DATA_WIDTH / C_CACHE_DATA_WIDTH - 1 generate
    begin
      -- Generate vectorized data.
      update_rd_miss_word_i(I) <= update_read_resize_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
    end generate Gen_Vectorization;
    
    -- Word selector.
    update_rd_miss_sel_s    <= update_rd_offset(C_RATIO_BITS_POS);
    update_rd_miss_sel      <= to_integer(unsigned(update_rd_miss_sel_s));
    
    -- Throttle until last part of word.
    update_rd_miss_th_incr  <= (not update_read_data_last_i) when (update_rd_miss_sel_s /= ratio_bits_one_vec ) else 
                               '0';
    update_rd_miss_th_wrap  <= not update_read_data_last_i;
    update_rd_miss_throttle <= update_rd_miss_th_wrap when ( update_read_resize_kind = C_KIND_WRAP ) else 
                               update_rd_miss_th_incr;
      
    -- Select current data part.
    update_read_data_word   <= update_rd_miss_word_i(update_rd_miss_sel);
  
  end generate Read_Internal_Narrow;
  
  -- Assign external.
  update_read_data_last     <= update_read_data_last_i;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Handling
  -- 
  -- Keep track of the source of the BRESP, i.e if it is internal or which port
  -- the response shall be forwarded to in the external case.
  -- 
  -- There are multiple sources and destinations that need too be handled BRESP
  -- handling:
  --  BS   - BRESP Source
  --  BE   - Backend (Valid, Ready)
  --  WMAD - Write Miss Allocate Done (Exist, Pop)
  --  Port - Active Port (Valid, Ready)
  -- 
  --  Insert | Internal | Valid     | Ready         | BS Pop    | WMAD Pop
  -- --------+----------+-----------+---------------+-----------+----------
  --       0 |        0 | BE        | Port          | BE & Port | '0'
  --       0 |        1 | '0'       | '1'           | BE        | '0'
  --       1 |        0 | '0'       | '0'           | '0'       | '0'       Note: Impossible because allocate set both
  --       1 |        1 | WMAD & BE | Port & done_n | BE & WMAD | BS Pop
  -- 
  -----------------------------------------------------------------------------
  
  -- Generate control signals.
  update_bs_pop               <= update_ext_bresp_normal and backend_wr_resp_port_ready 
                                                              when ( not bs_insert and not bs_internal ) = '1' else
                                 update_ext_bresp_normal
                                                              when ( not bs_insert and     bs_internal ) = '1' else
                                 '0'
                                                              when (     bs_insert and not bs_internal ) = '1' else
                                 update_ext_bresp_wma and update_ext_bresp_normal;
  
  -- Generate ready for internal and write miss.
  backend_wr_resp_port_ready  <= update_ext_bresp_ready(bs_port_num);
  backend_wr_resp_wma_ready   <= not wmad_fifo_empty;
  
  backend_wr_resp_ready   <= backend_wr_resp_ready_i;
  backend_wr_resp_ready_i <= backend_wr_resp_port_ready and not backend_wr_resp_valid_hold
                                                              when ( not bs_insert and not bs_internal ) = '1' else
                             not backend_wr_resp_valid_hold
                                                              when ( not bs_insert and     bs_internal ) = '1' else
                             '0'                        
                                                              when (     bs_insert and not bs_internal ) = '1' else
                             not backend_wr_resp_valid_hold;
  
  FIFO_BS_Pointer: sc_srl_fifo_counter
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
      
      -- Configuration.
      C_PUSH_ON_CARRY           => false,
      C_POP_ON_CARRY            => false,
      C_ENABLE_PROTECTION       => false,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => true,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => update_bs_push,
      queue_pop                 => update_bs_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => bs_refresh_reg,
      
      queue_almost_full         => open,
      queue_full                => bs_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => open,
      queue_exist               => bs_exist,
      queue_line_fit            => open,
      queue_index               => bs_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_ud_bs,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => bs_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for Write Response Source FIFO.
  FIFO_BS_Memory : process (ACLK) is
  begin  -- process FIFO_BS_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( update_bs_push = '1' ) then
        -- Insert new item.
        bs_fifo_mem(0).Port_Num <= update_port_i;
        bs_fifo_mem(0).Internal <= ( update_need_evict and not ( update_write_hit and not update_early_bresp ) )or 
                                   ( update_info.Wr and update_early_bresp );
        bs_fifo_mem(0).Insert   <= update_write_miss and update_info.Allocate;
        bs_fifo_mem(0).Addr     <= update_info.Addr(C_ADDR_INTERNAL_POS);
        bs_fifo_mem(0).DSid     <= update_info.DSid;
        if( C_ENABLE_EX_MON > 0 ) then
          bs_fifo_mem(0).Set_ExOk  <= update_info.Exclusive and update_exclusive_hit;
        else
          bs_fifo_mem(0).Set_ExOk  <= C_NULL_BS.Set_ExOk;
        end if;
        
        -- Shift FIFO contents.
        bs_fifo_mem(bs_fifo_mem'left downto 1) <= bs_fifo_mem(bs_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_BS_Memory;
  
  -- Store BS in register for good timing.
  BS_Data_Registers : process (ACLK) is
  begin  -- process BS_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        bs_internal <= C_NULL_BS.Internal;
        bs_insert   <= C_NULL_BS.Insert;
        bs_port_num <= C_NULL_BS.Port_Num;
        bs_addr     <= C_NULL_BS.Addr;
        bs_DSid     <= C_NULL_BS.DSid;
        bs_exok     <= C_NULL_BS.Set_ExOk;
      elsif( bs_refresh_reg = '1' ) then
        bs_internal <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).Internal;
        bs_insert   <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).Insert;
        bs_port_num <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).Port_Num;
        bs_addr     <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).Addr;
        bs_DSid     <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).DSid;
        if( C_ENABLE_EX_MON > 0 ) then
          bs_exok     <= bs_fifo_mem(to_integer(unsigned(bs_read_fifo_addr))).Set_ExOk;
        else
          bs_exok     <= C_NULL_BS.Set_ExOk;
        end if;
      end if;
    end if;
  end process BS_Data_Registers;
  
  -- Forward information to Backend for Re-Ordering handling.
  backend_wr_resp_port      <= bs_port_num;
  backend_wr_resp_internal  <= bs_internal;
  backend_wr_resp_addr      <= bs_addr;
  backend_wr_resp_DSid      <= bs_DSid;
  
  -- Generate valid BRESP
  update_ext_bresp_wma      <= ( bs_insert and bs_exist and not wmad_fifo_empty );
  update_ext_bresp_normal   <= ( ( backend_wr_resp_valid or backend_wr_resp_valid_hold ) and bs_exist );
  update_ext_bresp_any      <= update_ext_bresp_normal and not bs_insert and not bs_internal;
  
  -- Generate BRESP queues per port.
  update_ext_bresp_valid    <= update_ext_bresp_valid_i;
  update_ext_bresp_any_vec  <= (others => update_ext_bresp_any);
  update_ext_bresp_valid_i  <= std_logic_vector(to_unsigned(2 ** bs_port_num, C_NUM_PORTS)) and 
                               update_ext_bresp_any_vec;
  
  -- Forward RESP from Backend or insert OKAY from WMA.
  update_ext_bresp          <= C_BRESP_EXOKAY        when bs_exok   = '1' else
                               backend_wr_resp_bresp when bs_insert = '0' else
                               C_BRESP_OKAY;
  
  
  --
  BS_Pop_Handler : process (ACLK) is
  begin  -- process BS_Pop_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        backend_wr_resp_valid_hold  <= '0';
        
      else
        if( update_bs_pop = '1' ) then
          -- BS has been forwarded, no need to hold.
          backend_wr_resp_valid_hold  <= '0';
          
        elsif( ( backend_wr_resp_valid and backend_wr_resp_ready_i ) = '1' ) then
          -- Hold a fake internal Valid so that that the BRESP can be released quickly.
          -- When WMA forced Evict the BRESP needs to be acknowledged quickly to not cause any
          -- delay for ordering in Backend.
          backend_wr_resp_valid_hold  <= '1';
          
        end if;
      end if;
    end if;
  end process BS_Pop_Handler;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_ud_stall     <= C_NULL_STAT_POINT;
    stat_ud_tag_free  <= C_NULL_STAT_POINT;
    stat_ud_data_free <= C_NULL_STAT_POINT;
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    signal stat_tag_free  : std_logic;
    signal stat_data_free : std_logic;
    signal stat_stall     : std_logic;
  begin
    
    Stat_Handle : process (ACLK) is
    begin  -- process Stat_Handle
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( stat_reset = '1' ) then         -- synchronous reset (active high)
          stat_tag_free   <= '0';
          stat_data_free  <= '0';
          stat_stall      <= '0';
          
        else
          stat_tag_free   <= not update_tag_en_i;
          stat_data_free  <= not update_data_en_ii(0);
          stat_stall      <= update_stall;
            
        end if;
      end if;
    end process Stat_Handle;
    
    Tag_Free_Inst: sc_stat_event
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
        
        probe                     => stat_tag_free,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
      
        stat_data                 => stat_ud_tag_free
      );
      
    Data_Free_Inst: sc_stat_event
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
        
        probe                     => stat_data_free,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_ud_data_free
      );
      
    Stall_Inst: sc_stat_event
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
        
        probe                     => stat_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_ud_stall
      );
      
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    UPDATE_DEBUG1 <= (others=>'0');
    UPDATE_DEBUG2 <= (others=>'0');
  end generate No_Debug;
  
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_PORTS   : natural := min_of( 4, C_NUM_PORTS);
    constant C_MY_WPORT   : natural := min_of( 2, Log2(C_NUM_PORTS));
    constant C_MY_OFF     : natural := min_of( 6, C_ADDR_OFFSET_HI - C_ADDR_OFFSET_LO + 1);
    constant C_MY_LEN     : natural := min_of( 6, C_AXI_LENGTH_WIDTH);
    constant C_MY_TLINE   : natural := min_of(10, C_ADDR_FULL_LINE_HI - C_ADDR_FULL_LINE_LO + 1);
    constant C_MY_LINE    : natural := min_of(10, C_ADDR_LINE_HI - C_ADDR_LINE_LO + 1);
    constant C_MY_DLINE   : natural := min_of(14, C_ADDR_EXT_DATA_HI - C_ADDR_EXT_DATA_LO + 1);
    constant C_MY_WORD    : natural := min_of( 5, C_ADDR_EXT_WORD_HI - C_ADDR_EXT_WORD_LO + 1);
    constant C_MY_PSET    : natural := min_of( 2, Log2(C_NUM_PARALLEL_SETS));
    constant C_MY_HOTSET  : natural := min_of( 2, C_NUM_PARALLEL_SETS);
    constant C_MY_SET     : natural := min_of( 2, C_SET_BIT_HI - C_SET_BIT_LO + 1);
    constant C_MY_TAG     : natural := min_of(18, C_TAG_SIZE);
    constant C_MY_QCNT    : natural := min_of( 4, C_QUEUE_LENGTH_BITS);
    constant C_MY_EXTBE   : natural := min_of(32, C_EXTERNAL_DATA_WIDTH)/8;
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          UPDATE_DEBUG1 <= (others=>'0');
          UPDATE_DEBUG2 <= (others=>'0');
        else
          -- Default assignment.
          UPDATE_DEBUG1                                   <= (others=>'0');
          UPDATE_DEBUG2                                   <= (others=>'0');
          
          -- Access signals.
          UPDATE_DEBUG1(  0 + C_MY_PORTS - 1 downto   0)  <= access_data_valid(C_MY_PORTS - 1 downto 0);
          UPDATE_DEBUG1(  4 + C_MY_PORTS - 1 downto   4)  <= access_data_last(C_MY_PORTS - 1 downto 0);
          
          -- Lookup signals.
          UPDATE_DEBUG1(                              8)  <= lookup_push_write_miss;
          UPDATE_DEBUG1(                              9)  <= lookup_wm_evict;
          UPDATE_DEBUG1( 10 + C_MY_OFF   - 1 downto  10)  <= lookup_wm_use_bits(C_MY_OFF - 1 downto 0);
          UPDATE_DEBUG1( 16 + C_MY_OFF   - 1 downto  16)  <= lookup_wm_stp_bits(C_MY_OFF - 1 downto 0);
          
          -- Update transaction.
          UPDATE_DEBUG1(                             22)  <= update_valid;
          UPDATE_DEBUG1( 23 + C_MY_PSET  - 1 downto  23)  <= update_set(C_MY_PSET - 1 downto 0);
          UPDATE_DEBUG1( 25 + C_MY_OFF   - 1 downto  25)  <= update_use_bits(C_MY_OFF - 1 downto 0);
          UPDATE_DEBUG1( 31 + C_MY_OFF   - 1 downto  31)  <= update_stp_bits(C_MY_OFF - 1 downto 0);
          UPDATE_DEBUG1(                             37)  <= update_hit;
          UPDATE_DEBUG1(                             38)  <= update_miss;
          UPDATE_DEBUG1(                             39)  <= update_read_hit;
          UPDATE_DEBUG1(                             40)  <= update_read_miss;
          UPDATE_DEBUG1(                             41)  <= update_read_miss_dirty;
          UPDATE_DEBUG1(                             42)  <= update_write_hit;
          UPDATE_DEBUG1(                             43)  <= update_write_miss;
          UPDATE_DEBUG1(                             44)  <= update_locked_write_hit;
          UPDATE_DEBUG1(                             45)  <= update_locked_read_hit;
          UPDATE_DEBUG1(                             46)  <= update_first_write_hit;
          UPDATE_DEBUG1(                             47)  <= '0';
          UPDATE_DEBUG1( 48 + C_MY_TAG   - 1 downto  48)  <= update_old_tag(C_MY_TAG - 1 downto 0);
          
          -- Backend signals.
          UPDATE_DEBUG1(                             64)  <= backend_wr_resp_valid;
          UPDATE_DEBUG1( 65 + C_MY_WPORT - 1 downto  65)  <= std_logic_vector(to_unsigned(bs_port_num, 
                                                                                         C_MY_WPORT)); -- backend_wr_resp_port
          UPDATE_DEBUG1(                             67)  <= bs_internal; -- backend_wr_resp_internal;
          UPDATE_DEBUG1(                             68)  <= backend_wr_resp_ready_i;
          UPDATE_DEBUG1(                             69)  <= backend_rd_data_valid;
          UPDATE_DEBUG1(                             70)  <= backend_rd_data_last;
          UPDATE_DEBUG1( 71 + 2          - 1 downto  71)  <= backend_rd_data_real_rresp(2 - 1 downto 0);
          UPDATE_DEBUG1(                             73)  <= backend_rd_data_ready_i;
          
          -- Update signals (to Arbiter).
          UPDATE_DEBUG1( 74 + C_MY_WPORT - 1 downto  74)  <= (others=>'0');
          UPDATE_DEBUG1( 76 + C_MY_WPORT - 1 downto  76)  <= std_logic_vector(to_unsigned(update_write_port_i,
                                                                                         C_MY_WPORT));
          UPDATE_DEBUG1( 78 + C_MY_WPORT - 1 downto  78)  <= std_logic_vector(to_unsigned(update_port_i,
                                                                                         C_MY_WPORT));
          UPDATE_DEBUG1(                             80)  <= update_read_done_i;
          UPDATE_DEBUG1(                             81)  <= update_write_done_i;
          
          -- Update signals (to Frontend).
          UPDATE_DEBUG1( 82 + C_MY_PORTS - 1 downto  82)  <= update_read_data_valid_ii(C_MY_PORTS - 1 downto 0);
          UPDATE_DEBUG1(                             86)  <= update_read_data_last_i;
          UPDATE_DEBUG1( 87 + 4          - 1 downto  87)  <= update_read_data_resp_i;
          UPDATE_DEBUG1( 91 + C_MY_PORTS - 1 downto  91)  <= update_read_data_ready(C_MY_PORTS - 1 downto 0);
          
          -- Write Miss
          UPDATE_DEBUG1( 95 + C_MY_PORTS - 1 downto  95)  <= update_write_data_ready_i(C_MY_PORTS - 1 downto 0);
          
          -- Write response
          UPDATE_DEBUG1( 99 + C_MY_PORTS - 1 downto  99)  <= (others=>'0');
          UPDATE_DEBUG1(                            103)  <= '0';
          UPDATE_DEBUG1(104 + C_MY_PORTS - 1 downto 104)  <= (others=>'0');
          
          -- Write miss response
          UPDATE_DEBUG1(108 + C_MY_PORTS - 1 downto 108)  <= update_ext_bresp_valid_i(C_MY_PORTS - 1 downto 0);
          UPDATE_DEBUG1(112 + 2          - 1 downto 112)  <= backend_wr_resp_bresp; -- update_ext_bresp;
          UPDATE_DEBUG1(114 + C_MY_PORTS - 1 downto 114)  <= update_ext_bresp_ready(C_MY_PORTS - 1 downto 0);
          
          -- Update signals (to Lookup).
          UPDATE_DEBUG1(                            118)  <= update_tag_conflict_i;
          UPDATE_DEBUG1(                            119)  <= update_piperun_i;
          UPDATE_DEBUG1(                            120)  <= wm_fifo_full; -- update_write_miss_full;
          UPDATE_DEBUG1(121 + C_MY_PORTS - 1 downto 121)  <= update_write_miss_busy_i(C_MY_PORTS - 1 downto 0);
          
          -- Update signals (to Tag & Data).
          UPDATE_DEBUG1(125 + C_MY_TLINE - 1 downto 125)  <= update_tag_addr_i(C_ADDR_FULL_LINE_LO + C_MY_TLINE - 1 downto 
                                                                              C_ADDR_FULL_LINE_LO);
          UPDATE_DEBUG1(135 + C_MY_HOTSET- 1 downto 135)  <= update_tag_we_i(C_MY_HOTSET - 1 downto 0);
          UPDATE_DEBUG1(137 + C_MY_TAG   - 1 downto 137)  <= update_new_tag(C_MY_TAG - 1 downto 0); 
                                                            -- update_tag_new_word;
          UPDATE_DEBUG1(155 + C_MY_TAG   - 1 downto 155)  <= update_readback_tag(C_MY_TAG - 1 downto 0); 
                                                            -- update_tag_current_word_i(0)(C_MY_TAG - 1 downto 0);
          
          UPDATE_DEBUG1(173 + C_MY_DLINE - 1 downto 173)  <= update_data_addr_i(C_ADDR_EXT_DATA_LO + C_MY_DLINE - 1 downto 
                                                                               C_ADDR_EXT_DATA_LO);
          UPDATE_DEBUG1(187 + C_MY_HOTSET- 1 downto 187)  <= update_data_en_i(C_MY_HOTSET - 1 downto 0);
          UPDATE_DEBUG1(                            189)  <= update_wr_cnt_en; -- update_data_we(0);
          
          -- Update signals (to Backend).
          UPDATE_DEBUG1(                            190)  <= read_req_valid_i;
          UPDATE_DEBUG1(                            191)  <= read_req_exclusive_i;
          UPDATE_DEBUG1(                            192)  <= read_req_kind_i;
          UPDATE_DEBUG1(                            193)  <= read_req_ready;
          
          UPDATE_DEBUG1(                            194)  <= write_req_valid_i;
          UPDATE_DEBUG1(                            195)  <= update_need_evict; -- write_req_internal
          UPDATE_DEBUG1(                            196)  <= write_req_exclusive_i;
          UPDATE_DEBUG1(                            197)  <= write_req_kind_i;
          UPDATE_DEBUG1(                            198)  <= write_req_ready;
          
          UPDATE_DEBUG1(                            199)  <= write_data_valid_i;
          UPDATE_DEBUG1(                            200)  <= write_data_last_i;
          UPDATE_DEBUG1(                            201)  <= write_data_ready;
          UPDATE_DEBUG1(                            202)  <= write_data_almost_full;
          UPDATE_DEBUG1(                            203)  <= write_data_full;
          
          -- Detect Address Conflicts: 1+1 = 2
          UPDATE_DEBUG1(                            204)  <= write_req_line_only_i;
          
          -- Update Pipeline Stage: Update: 31
          UPDATE_DEBUG1(                            205)  <= not update_piperun_i; -- update_stall;
          UPDATE_DEBUG1(206 + C_MY_SET   - 1 downto 206)  <= update_cur_tag_set(C_MY_SET - 1 downto 0);
          UPDATE_DEBUG1(                            208)  <= '0';
          UPDATE_DEBUG1(                            209)  <= update_need_bs;
          UPDATE_DEBUG1(                            210)  <= update_need_ar;
          UPDATE_DEBUG1(                            211)  <= update_need_aw;
          UPDATE_DEBUG1(                            212)  <= update_need_evict;
          UPDATE_DEBUG1(                            213)  <= update_need_tag_write;
          UPDATE_DEBUG1(                            214)  <= '0';
          UPDATE_DEBUG1(                            215)  <= update_done_bs;
          UPDATE_DEBUG1(                            216)  <= update_done_ar;
          UPDATE_DEBUG1(                            217)  <= update_done_aw;
          UPDATE_DEBUG1(                            218)  <= update_done_evict;
          UPDATE_DEBUG1(                            219)  <= update_done_tag_write;
          UPDATE_DEBUG1(                            220)  <= update_new_tag_reused;
          UPDATE_DEBUG1(                            221)  <= update_stall_bs;
          UPDATE_DEBUG1(                            222)  <= update_stall_ar;
          UPDATE_DEBUG1(                            223)  <= update_stall_aw;
          UPDATE_DEBUG1(                            224)  <= update_stall_evict;
          UPDATE_DEBUG1(                            225)  <= update_stall_tag_write;
          UPDATE_DEBUG1(                            226)  <= update_evict;
          UPDATE_DEBUG1(                            227)  <= update_tag_write_raw;
          UPDATE_DEBUG1(                            228)  <= update_tag_write;
          UPDATE_DEBUG1(                            229)  <= update_block_lookup;
          UPDATE_DEBUG1(                            230)  <= update_new_tag_valid;
          UPDATE_DEBUG1(                            231)  <= update_new_tag_locked;
          UPDATE_DEBUG1(                            232)  <= update_new_tag_dirty;
          
          -- Check Locked Tag
          UPDATE_DEBUG1(                            233)  <= update_readback_possible;
          UPDATE_DEBUG1(                            234)  <= update_readback_available;
          UPDATE_DEBUG1(                            235)  <= update_readback_done;
          UPDATE_DEBUG1(                            236)  <= update_locked_tag_match;
          UPDATE_DEBUG1(                            237)  <= update_locked_tag_is_dead;
          UPDATE_DEBUG1(                            238)  <= update_remove_locked;
          UPDATE_DEBUG1(                            239)  <= update_remove_locked_safe;
          UPDATE_DEBUG1(                            240)  <= update_word_cnt_almost_last;
          UPDATE_DEBUG1(                            241)  <= update_rb_pos_phase;
          UPDATE_DEBUG1(                            242)  <= update_first_word_safe;
          UPDATE_DEBUG1(                            243)  <= update_read_miss_safe;
          UPDATE_DEBUG1(                            244)  <= ri_evicted;
          
          -- Queue for Data Eviction (Read Miss Dirty and Evict)
          UPDATE_DEBUG2(                              0)  <= update_e_push;
          UPDATE_DEBUG2(                              1)  <= update_e_pop;
          UPDATE_DEBUG2(                              2)  <= lookup_wm_allocate;
          UPDATE_DEBUG2(  3 + C_MY_QCNT  - 1 downto   3)  <= e_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          UPDATE_DEBUG2(                              7)  <= e_fifo_full;
          UPDATE_DEBUG2(                              8)  <= e_fifo_empty;
          UPDATE_DEBUG2(  9 + C_MY_SET   - 1 downto   9)  <= e_set(C_MY_SET - 1 downto 0);
          
          UPDATE_DEBUG2( 11 + C_MY_LINE  - 1 downto  11)  <= e_offset(C_ADDR_FULL_LINE_LO + C_MY_LINE - 1 downto 
                                                                      C_ADDR_FULL_LINE_LO);
          
          -- Update Data Pointer
          UPDATE_DEBUG2(                             21)  <= update_rd_cnt_en;
          UPDATE_DEBUG2(                             22)  <= update_word_cnt_en;
          UPDATE_DEBUG2( 23 + C_MY_WORD  - 1 downto  23)  <= update_word_cnt(C_ADDR_EXT_WORD_LO + C_MY_WORD - 1 downto
                                                                             C_ADDR_EXT_WORD_LO);
          UPDATE_DEBUG2( 28 + C_MY_WORD  - 1 downto  28)  <= update_word_cnt_len(C_ADDR_EXT_WORD_LO + C_MY_WORD - 1 downto
                                                                                 C_ADDR_EXT_WORD_LO);
          UPDATE_DEBUG2( 33 + C_MY_SET   - 1 downto  33)  <= update_cur_data_set(C_MY_SET - 1 downto 0);
          UPDATE_DEBUG2(                             35)  <= update_word_cnt_first;
          UPDATE_DEBUG2(                             36)  <= update_word_cnt_last;
          UPDATE_DEBUG2(                             37)  <= update_read_miss_start_ok;
          UPDATE_DEBUG2(                             38)  <= update_read_miss_start;
          UPDATE_DEBUG2(                             39)  <= update_evict_start;
          UPDATE_DEBUG2(                             40)  <= update_read_miss_stop;
          UPDATE_DEBUG2(                             41)  <= update_evict_stop;
          UPDATE_DEBUG2(                             42)  <= update_evict_ongoing;
          UPDATE_DEBUG2(                             43)  <= update_evict_busy;
          UPDATE_DEBUG2(                             44)  <= update_read_miss_ongoing;
          UPDATE_DEBUG2(                             45)  <= update_evict_valid;
          UPDATE_DEBUG2(                             46)  <= update_evict_last;
          UPDATE_DEBUG2(                             47)  <= write_data_full_d1;
          UPDATE_DEBUG2(                             48)  <= update_evict_stop_d1;
          UPDATE_DEBUG2(                             49)  <= update_read_miss_use_ok;
          UPDATE_DEBUG2(                             50)  <= update_read_miss_use_bypass;
          
          -- Queue for Write Extraction (Write Miss)
          UPDATE_DEBUG2(                             51)  <= update_wm_push;
          UPDATE_DEBUG2(                             52)  <= update_wm_pop_evict;
          UPDATE_DEBUG2(                             53)  <= update_wm_pop_normal;
          UPDATE_DEBUG2(                             54)  <= update_wm_pop;
          UPDATE_DEBUG2(                             55)  <= update_wm_pop_allocate;
          UPDATE_DEBUG2( 56 + C_MY_QCNT  - 1 downto  56)  <= wm_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          UPDATE_DEBUG2(                             60)  <= '0';
          UPDATE_DEBUG2(                             61)  <= wm_fifo_full; 
          UPDATE_DEBUG2(                             62)  <= wm_fifo_almost_empty;
          UPDATE_DEBUG2(                             63)  <= wm_exist;
          UPDATE_DEBUG2(                             64)  <= wm_evict;
          UPDATE_DEBUG2(                             65)  <= wm_kind;
          UPDATE_DEBUG2(                             66)  <= update_use_write_word;
          UPDATE_DEBUG2(                             67)  <= update_write_miss_ongoing;
          UPDATE_DEBUG2(                             68)  <= update_ack_write_word; 
          UPDATE_DEBUG2(                             69)  <= update_wr_miss_valid; 
          UPDATE_DEBUG2(                             70)  <= update_wr_miss_last; 
          
          -- Write Size Conversion
          UPDATE_DEBUG2(                             71)  <= update_wr_miss_throttle; 
          UPDATE_DEBUG2(                             72)  <= update_wr_miss_rs_valid;
          UPDATE_DEBUG2(                             73)  <= update_wr_miss_rs_last;
          UPDATE_DEBUG2( 74 + C_MY_OFF   - 1 downto  74)  <= update_wr_offset(C_MY_OFF - 1 downto 0);
          
          -- Read Information Buffer
          UPDATE_DEBUG2(                             80)  <= ri_push;
          UPDATE_DEBUG2(                             81)  <= ri_pop;
          UPDATE_DEBUG2(                             82)  <= ri_merge;
          UPDATE_DEBUG2(                             83)  <= ri_refresh_reg;
          UPDATE_DEBUG2( 84 + C_MY_QCNT  - 1 downto  84)  <= ri_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          UPDATE_DEBUG2(                             88)  <= ri_exist;
          UPDATE_DEBUG2( 89 + C_MY_WPORT - 1 downto  89)  <= std_logic_vector(to_unsigned(ri_port,
                                                                                          C_MY_WPORT));
          UPDATE_DEBUG2(                             93)  <= ri_kind;
          UPDATE_DEBUG2(                             94)  <= ri_allocate;
          
          -- Read Data Forwarding
          UPDATE_DEBUG2(                             95)  <= backend_rd_data_use;
          UPDATE_DEBUG2(                             96)  <= backend_rd_data_pop;
          UPDATE_DEBUG2(                             97)  <= update_read_forward_ready;
          UPDATE_DEBUG2(                             98)  <= update_read_resize_valid;
          UPDATE_DEBUG2( 99 + C_MY_SET   - 1 downto  99)  <= (others=>'0');
          UPDATE_DEBUG2(                            101)  <= update_read_resize_last;
          UPDATE_DEBUG2(102 + C_MY_WPORT - 1 downto 102)  <= std_logic_vector(to_unsigned(update_read_resize_port,
                                                                                          C_MY_WPORT));
          UPDATE_DEBUG2(                            104)  <= update_read_resize_kind;
          UPDATE_DEBUG2(105 + C_MY_LEN   - 1 downto 105)  <= update_read_resize_len(C_MY_LEN - 1 downto 0);
          UPDATE_DEBUG2(                            111)  <= update_read_resize_allocate;
          UPDATE_DEBUG2(                            112)  <= update_read_resize_used;
          UPDATE_DEBUG2(                            113)  <= update_read_resize_ready;
          
          -- Read Size Conversion
          UPDATE_DEBUG2(114 + C_MY_OFF   - 1 downto 114)  <= update_rd_offset(C_MY_OFF - 1 downto 0);
          UPDATE_DEBUG2(                            120)  <= update_readback_tag_en;
          UPDATE_DEBUG2(121 + C_MY_OFF   - 2 downto 121)  <= (others=>'0');
          UPDATE_DEBUG2(126 + C_MY_LEN   - 1 downto 126)  <= update_rd_len(C_MY_LEN - 1 downto 0);
          UPDATE_DEBUG2(                            132)  <= update_read_resize_first;
          UPDATE_DEBUG2(                            133)  <= update_read_resize_finish;
          UPDATE_DEBUG2(                            134)  <= update_read_resize_selected;
          UPDATE_DEBUG2(                            135)  <= update_rd_wrap_ok;
          UPDATE_DEBUG2(                            136)  <= update_read_resize_sel_wrap;
          UPDATE_DEBUG2(                            137)  <= update_rd_incr_ok;
          UPDATE_DEBUG2(                            138)  <= update_rd_miss_th_incr;
          UPDATE_DEBUG2(                            139)  <= update_rd_miss_th_wrap;
          UPDATE_DEBUG2(                            140)  <= update_rd_miss_throttle;
          
          -- Write Response Handling
          UPDATE_DEBUG2(                            141)  <= update_bs_push;
          UPDATE_DEBUG2(                            142)  <= update_bs_pop;
          UPDATE_DEBUG2(143 + C_MY_QCNT  - 1 downto 143)  <= bs_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          UPDATE_DEBUG2(                            147)  <= bs_fifo_full;
          UPDATE_DEBUG2(                            148)  <= bs_exist;
          UPDATE_DEBUG2(                            149)  <= update_readback_possible;
          UPDATE_DEBUG2(                            150)  <= update_word_cnt_almost_last;
          UPDATE_DEBUG2(                            151)  <= update_remove_locked_safe;
          UPDATE_DEBUG2(                            152)  <= backend_rd_data_valid;
          UPDATE_DEBUG2(                            153)  <= backend_rd_data_last;
          UPDATE_DEBUG2(                            154)  <= backend_rd_data_ready_i;
          UPDATE_DEBUG2(                            155)  <= update_readback_available;
          UPDATE_DEBUG2(                            156)  <= update_rb_pos_phase;
          UPDATE_DEBUG2(                            157)  <= update_first_word_safe;
          UPDATE_DEBUG2(                            158)  <= update_readback_allowed;
          UPDATE_DEBUG2(                            159)  <= update_read_miss_safe;
          UPDATE_DEBUG2(                            160)  <= ri_evicted;
          UPDATE_DEBUG2(                            161)  <= update_write_miss_dirty;
          UPDATE_DEBUG2(                            162)  <= update_allocate_write_miss;
          UPDATE_DEBUG2(                            163)  <= '0';
          UPDATE_DEBUG2(                            164)  <= update_read_miss_wma_safe;
          UPDATE_DEBUG2(                            165)  <= update_wm_pop_evict_hold;
          UPDATE_DEBUG2(                            166)  <= update_wm_pop_normal_hold;
          UPDATE_DEBUG2(                            167)  <= wm_allocate;
          UPDATE_DEBUG2(                            168)  <= wm_local_wrap;
          UPDATE_DEBUG2(                            169)  <= update_ack_write_ext; 
          UPDATE_DEBUG2(                            170)  <= update_ack_write_alloc; 
          UPDATE_DEBUG2(                            171)  <= update_wr_miss_word_done; 
          UPDATE_DEBUG2(                            172)  <= update_wr_miss_restart_word;
          UPDATE_DEBUG2(                            173)  <= backend_wr_resp_valid_hold;
          UPDATE_DEBUG2(                            174)  <= backend_wr_resp_port_ready;
          UPDATE_DEBUG2(                            175)  <= backend_wr_resp_wma_ready;
          UPDATE_DEBUG2(                            176)  <= bs_insert;
          UPDATE_DEBUG2(                            177)  <= update_ext_bresp_wma;
          UPDATE_DEBUG2(                            178)  <= update_ext_bresp_normal;
          UPDATE_DEBUG2(                            179)  <= update_ext_bresp_any;
          UPDATE_DEBUG2(                            180)  <= update_wma_insert_dummy;
          UPDATE_DEBUG2(                            181)  <= update_wma_select_port;
          UPDATE_DEBUG2(                            182)  <= update_wma_data_valid;
          UPDATE_DEBUG2(                            183)  <= update_wma_fifo_stall;
          UPDATE_DEBUG2(                            184)  <= update_wma_throttle;
          UPDATE_DEBUG2(                            185)  <= update_wma_last;
          UPDATE_DEBUG2(                            186)  <= wma_word_done;
          UPDATE_DEBUG2(                            187)  <= wma_word_done_d1;
          UPDATE_DEBUG2(                            188)  <= wma_push;
          UPDATE_DEBUG2(                            189)  <= wma_pop;
          UPDATE_DEBUG2(                            190)  <= wma_fifo_almost_full;
          UPDATE_DEBUG2(                            191)  <= wma_fifo_full;
          UPDATE_DEBUG2(                            192)  <= wma_fifo_empty;
          UPDATE_DEBUG2(                            193)  <= wma_last;
          UPDATE_DEBUG2(                            194)  <= wma_merge_done;
          UPDATE_DEBUG2(                            195)  <= wmad_push;
          UPDATE_DEBUG2(                            196)  <= wmad_pop;
          UPDATE_DEBUG2(                            197)  <= wmad_fifo_full;
          UPDATE_DEBUG2(                            198)  <= wmad_fifo_empty;
          UPDATE_DEBUG2(199 + C_MY_OFF   - 1 downto 199)  <= update_wr_next_word_addr(C_MY_OFF - 1 downto 0);
          UPDATE_DEBUG2(205 + C_MY_QCNT  - 1 downto 205)  <= wma_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          UPDATE_DEBUG2(209 + C_MY_EXTBE - 1 downto 209)  <= update_wma_strb(C_MY_EXTBE-1 downto 0);
          UPDATE_DEBUG2(213 + C_MY_EXTBE - 1 downto 213)  <= wma_strb(C_MY_EXTBE-1 downto 0);
          UPDATE_DEBUG2(                            217)  <= backend_wr_resp_valid;
          UPDATE_DEBUG2(                            218)  <= bs_internal;
          UPDATE_DEBUG2(                            219)  <= backend_wr_resp_ready_i;
          UPDATE_DEBUG2(                            220)  <= ed_push;
          UPDATE_DEBUG2(                            221)  <= ed_pop;
          UPDATE_DEBUG2(                            222)  <= ed_fifo_full;
          UPDATE_DEBUG2(                            223)  <= ed_fifo_empty;
          UPDATE_DEBUG2(                            224)  <= ed_assert;
          UPDATE_DEBUG2(                            225)  <= update_tag_write_ignore;
          UPDATE_DEBUG2(                            226)  <= update_remove_locked_2nd_cycle;
          UPDATE_DEBUG2(                            227)  <= wmad_done;
          
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
    assert_err(C_ASSERT_RI_QUEUE_ERROR)   <= ri_assert   when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_R_QUEUE_ERROR)    <= r_assert    when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_E_QUEUE_ERROR)    <= e_assert    when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_BS_QUEUE_ERROR)   <= bs_assert   when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_WM_QUEUE_ERROR)   <= wm_assert   when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_WMA_QUEUE_ERROR)  <= wma_assert  when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_WMAD_QUEUE_ERROR) <= wmad_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_NO_RI_INFO)       <= backend_rd_data_valid and not ri_exist when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_NO_BS_INFO)       <= backend_wr_resp_valid and not bs_exist when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_RI_QUEUE_ERROR)   /= '1' 
      report "Update: Erroneous handling of RI Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_R_QUEUE_ERROR)    /= '1' 
      report "Update: Erroneous handling of R Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_E_QUEUE_ERROR)    /= '1' 
      report "Update: Erroneous handling of E Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BS_QUEUE_ERROR)   /= '1' 
      report "Update: Erroneous handling of BS Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_WM_QUEUE_ERROR)   /= '1' 
      report "Update: Erroneous handling of WM Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_WMA_QUEUE_ERROR)  /= '1' 
      report "Update: Erroneous handling of WMA Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_WMAD_QUEUE_ERROR) /= '1' 
      report "Update: Erroneous handling of WMAD Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_NO_RI_INFO)       /= '1' 
      report "Update: No RI Information available when read data arrives."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_NO_BS_INFO)       /= '1' 
      report "Update: No BS Information available when write response arrives."
        severity error;
    
    -- pragma translate_on
  end block Assertions;
  
  
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
