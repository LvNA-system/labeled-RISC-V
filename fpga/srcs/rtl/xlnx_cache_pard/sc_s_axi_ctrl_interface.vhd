-------------------------------------------------------------------------------
-- sc_s_axi_ctrl_interface.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_ctrl_interface.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_ctrl_interface.vhd
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

entity sc_s_axi_ctrl_interface is
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
    C_ENABLE_CTRL             : natural range  0 to    1      :=  0;
    C_ENABLE_AUTOMATIC_CLEAN  : natural range  0 to    1      :=  0;
    C_AUTOMATIC_CLEAN_MODE    : natural range  0 to    1      :=  0;
    C_DSID_WIDTH              : natural range  0 to   32      := 16;
    
    -- Data type and settings specific.
    C_ADDR_ALL_SETS_HI        : natural range  4 to   31      := 14;
    C_ADDR_ALL_SETS_LO        : natural range  4 to   31      :=  7;
    
    -- IP Specific.
    C_ENABLE_STATISTICS       : natural range  0 to  255      := 255;
    C_ENABLE_VERSION_REGISTER : natural range  0 to    3      :=  0;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
    C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
    C_ENABLE_EXCLUSIVE        : natural range  0 to    1      :=  0;
    C_NUM_SETS                : natural range  2 to   32      :=  2;
    C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
    C_CACHE_SIZE              : natural                       := 32768;
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  4;
    C_Lx_CACHE_SIZE           : natural                       := 1024;
    C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    
    -- AXI4-Lite Interface Specific.
    C_S_AXI_CTRL_BASEADDR     : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
    C_S_AXI_CTRL_HIGHADDR     : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
    C_S_AXI_CTRL_DATA_WIDTH   : natural range 32 to   64      := 32;
    C_S_AXI_CTRL_ADDR_WIDTH   : natural                       := 32
    
  );
  port (
    -- ---------------------------------------------------
    -- Common signals
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- AXI4-Lite Slave Interface Signals
    
    -- AW-Channel
    S_AXI_CTRL_AWADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_AWVALID             : in  std_logic;
    S_AXI_CTRL_AWREADY             : out std_logic;

    -- W-Channel
    S_AXI_CTRL_WDATA               : in  std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_WVALID              : in  std_logic;
    S_AXI_CTRL_WREADY              : out std_logic;

    -- B-Channel
    S_AXI_CTRL_BRESP               : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_BVALID              : out std_logic;
    S_AXI_CTRL_BREADY              : in  std_logic;

    -- AR-Channel
    S_AXI_CTRL_ARADDR              : in  std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    S_AXI_CTRL_ARVALID             : in  std_logic;
    S_AXI_CTRL_ARREADY             : out std_logic;

    -- R-Channel
    S_AXI_CTRL_RDATA               : out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
    S_AXI_CTRL_RRESP               : out std_logic_vector(1 downto 0);
    S_AXI_CTRL_RVALID              : out std_logic;
    S_AXI_CTRL_RREADY              : in  std_logic;

    
    -- ---------------------------------------------------
    -- Control If Transactions.
    
    ctrl_init_done                  : out std_logic;
    ctrl_access                     : out ARBITRATION_TYPE;
    ctrl_ready                      : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Automatic Clean Information.
    
    update_auto_clean_push          : in  std_logic;
    update_auto_clean_addr          : in  AXI_ADDR_TYPE;
    update_auto_clean_DSid          : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    -- General.
    
    stat_reset                      : out std_logic;
    stat_enable                     : out std_logic;
    
    -- Optimized ports.
    stat_s_axi_rd_segments          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_wr_segments          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_rip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_r                    : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_bip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_bp                   : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wip                  : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_w                    : in  STAT_FIFO_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_rd_latency           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wr_latency           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_rd_latency_conf      : out STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wr_latency_conf      : out STAT_CONF_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);

    -- Generic ports.
    stat_s_axi_gen_rd_segments      : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_gen_wr_segments      : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0); -- Per transaction
    stat_s_axi_gen_rip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_r                : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_bip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_bp               : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wip              : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_w                : in  STAT_FIFO_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_rd_latency       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wr_latency       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_rd_latency_conf  : out STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wr_latency_conf  : out STAT_CONF_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    
    -- Arbiter
    stat_arb_valid                  : in  STAT_POINT_TYPE;    -- Time valid transactions exist
    stat_arb_concurrent_accesses    : in  STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
    stat_arb_opt_read_blocked       : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
    stat_arb_gen_read_blocked       : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                              -- Time valid read is blocked by prohibit
    
    -- Access
    stat_access_valid               : in  STAT_POINT_TYPE;    -- Time valid per transaction
    stat_access_stall               : in  STAT_POINT_TYPE;    -- Time stalled per transaction
    stat_access_fetch_stall         : in  STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
    stat_access_req_stall           : in  STAT_POINT_TYPE;    -- Time stalled per transaction (req)
    stat_access_act_stall           : in  STAT_POINT_TYPE;    -- Time stalled per transaction (act)
    
    -- Lookup
    stat_lu_opt_write_hit           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss          : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_write_miss_dirty    : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_hit            : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss           : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_read_miss_dirty     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_write_hit    : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_locked_read_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_lu_opt_first_write_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    
    stat_lu_gen_write_hit           : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss          : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_write_miss_dirty    : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_hit            : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss           : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_read_miss_dirty     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_write_hit    : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_locked_read_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_lu_gen_first_write_hit     : in  STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);
    
    stat_lu_stall                   : in  STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_fetch_stall             : in  STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_mem_stall               : in  STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_stall              : in  STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_hit_stall          : in  STAT_POINT_TYPE;    -- Time per occurance
    stat_lu_data_miss_stall         : in  STAT_POINT_TYPE;    -- Time per occurance
    
    -- Update
    stat_ud_stall                   : in  STAT_POINT_TYPE;    -- Time transactions are stalled
    stat_ud_tag_free                : in  STAT_POINT_TYPE;    -- Cycles tag is free
    stat_ud_data_free               : in  STAT_POINT_TYPE;    -- Cycles data is free
    stat_ud_ri                      : in  STAT_FIFO_TYPE;     -- Read Information
    stat_ud_r                       : in  STAT_FIFO_TYPE;     -- Read data (optional)
    stat_ud_e                       : in  STAT_FIFO_TYPE;     -- Evict
    stat_ud_bs                      : in  STAT_FIFO_TYPE;     -- BRESP Source
    stat_ud_wm                      : in  STAT_FIFO_TYPE;     -- Write Miss
    stat_ud_wma                     : in  STAT_FIFO_TYPE;     -- Write Miss Allocate (reserved)
    
    -- Backend
    stat_be_aw                      : in  STAT_FIFO_TYPE;     -- Write Address
    stat_be_w                       : in  STAT_FIFO_TYPE;     -- Write Data
    stat_be_ar                      : in  STAT_FIFO_TYPE;     -- Read Address
    stat_be_ar_search_depth         : in  STAT_POINT_TYPE;    -- Average search depth
    stat_be_ar_stall                : in  STAT_POINT_TYPE;    -- Average total stall
    stat_be_ar_protect_stall        : in  STAT_POINT_TYPE;    -- Average protected stall
    stat_be_rd_latency              : in  STAT_POINT_TYPE;    -- External Read Latency
    stat_be_wr_latency              : in  STAT_POINT_TYPE;    -- External Write Latency
    stat_be_rd_latency_conf         : out STAT_CONF_TYPE;     -- External Read Latency Configuration
    stat_be_wr_latency_conf         : out STAT_CONF_TYPE;     -- External Write Latency Configuration
    
    
    -- ---------------------------------------------------
    -- Debug Signals
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_ctrl_interface;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_ctrl_interface is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Control interface for statistics and configuration.
  -- Statistics read data are pipelined to ensure timing.
  -- 
  
    
  -----------------------------------------------------------------------------
  -- Custom types (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural:= 18;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ENABLE_STATISTICS_MASK   : std_logic_vector(7 downto 0) := int_to_std(C_ENABLE_STATISTICS, 8);
  
  
  subtype C_VERSION_REGISTER_POS      is natural range 31 downto 0;
  
  subtype VERSION_REGISTER_TYPE       is std_logic_vector(C_VERSION_REGISTER_POS);
  
  type VERSION_REGISTER_MEM_TYPE      is array (0 to 1) of VERSION_REGISTER_TYPE;
  
  constant C_NULL_VR                  : VERSION_REGISTER_TYPE     := (others=>'0');
  constant C_NULL_VR_MEM              : VERSION_REGISTER_MEM_TYPE := (others=>C_NULL_VR);
  
  function Populate_VR return VERSION_REGISTER_MEM_TYPE is
    variable VR : VERSION_REGISTER_MEM_TYPE := C_NULL_VR_MEM;
  begin
    -- VR0:
      VR(0)(31) := '0';  -- reserved
    if C_ENABLE_VERSION_REGISTER > 1 then
      VR(0)(30) := '1';
    else 
      VR(0)(30) := '0';
    end if;
    VR(0)(29 downto 25)  := int_to_std(C_NUM_GENERIC_PORTS,             5);
    VR(0)(24 downto 20)  := int_to_std(C_NUM_OPTIMIZED_PORTS,           5);
    VR(0)(19 downto 18)  := int_to_std(C_ENABLE_EXCLUSIVE,              2);
    VR(0)(17 downto 16)  := int_to_std(C_ENABLE_COHERENCY,              2);
    VR(0)(15 downto  8)  := C_ENABLE_STATISTICS_MASK;
    VR(0)( 7 downto  0)  := int_to_std(C_SYSTEM_CACHE_VERSION,          8);
    
    
    -- VR1:
    VR(1)(31 downto 22)  := int_to_std(0,                              10); -- reserved
    VR(1)(21 downto 19)  := int_to_std(Log2(C_Lx_CACHE_LINE_LENGTH/4),  3);
    VR(1)(18 downto 15)  := int_to_std(Log2(C_Lx_CACHE_SIZE/64),        4);
    VR(1)(14 downto 12)  := int_to_std(Log2(C_CACHE_LINE_LENGTH/4),     3);
    VR(1)(11 downto  8)  := int_to_std(Log2(C_CACHE_SIZE/64),           4);
    VR(1)( 7 downto  5)  := int_to_std(Log2(C_CACHE_DATA_WIDTH/8),      3);
    VR(1)( 4 downto  2)  := int_to_std(Log2(C_M_AXI_DATA_WIDTH/8),      3);
    VR(1)( 1 downto  0)  := int_to_std(Log2(C_NUM_SETS/2),              2);

    return VR;
  end;
  
  constant C_VERSION_REGISTER         : VERSION_REGISTER_MEM_TYPE    := Populate_VR;
  
  
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  subtype C_ADDR_ALL_SETS_POS         is natural range C_ADDR_ALL_SETS_HI downto C_ADDR_ALL_SETS_LO;
  
  subtype ADDR_ALL_SETS_TYPE          is std_logic_vector(C_ADDR_ALL_SETS_POS);
  
  constant C_INIT_CNT_MAX             : ADDR_ALL_SETS_TYPE := (others=>'1');
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------

  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  
  -- 
  -- Address bit utilization for statistics addresses (category 0 to 6):
  -- 
  --   16           14 13      13 12         10 9         5 4        3 2         2 1   0
  --  |_______________|__________|_____________|___________|__________|___________|_____
  --  |_______________|__________|_____________|___________|__________|___________|_____|
  --                             
  --   \_____________/ \________/ \___________/ \_________/ \________/ \_________/ \___/
  --    |               |          |             |           |          |           |                 
  --    Category Addr   Reserved   Number Addr   Info Addr   Sub Addr   Word Addr   Byte Addr
  -- 
  -- 
  -- Category - The category group: Ports, pipelinestages and configuration.
  -- Number   - Port number.
  -- Info     - Statistics information type.
  -- Sub      - Sub element of information type.
  -- Word     - High/Low word in statistics data.
  -- 
  -- 
  -- 
  -- Address bit utilization for configuration addresses (category 7):
  -- 
  --   16           14 13                             6 5            3 2         2 1   0
  --  |_______________|________________________________|______________|___________|_____
  --  |_______________|________________________________|______________|___________|_____|
  --                                                            
  --   \_____________/ \______________________________/ \____________/ \_________/ \___/
  --    |               |                                |              |           |                 
  --    Category Addr   Reserved                         Config Addr    Word Addr   Byte Addr
  -- 
  -- 
  -- Config    - Configuration parameter address.
  -- 
  -- 
  
  subtype C_STAT_CATEGORY_ADDR_POS    is natural range 16 downto 14;
  subtype C_STAT_NUMBER_ADDR_POS      is natural range 12 downto 10;
  subtype C_STAT_INFO_ADDR_POS        is natural range  9 downto  5;
  subtype C_STAT_SUB_ADDR_POS         is natural range  4 downto  3;
  subtype C_STAT_CONFIG_ADDR_POS      is natural range  5 downto  3;
  subtype C_STAT_WORD_ADDR_POS        is natural range  2 downto  2;
  
  subtype STAT_CATEGORY_ADDR_TYPE     is std_logic_vector(C_STAT_CATEGORY_ADDR_POS);
  subtype STAT_NUMBER_ADDR_TYPE       is std_logic_vector(C_STAT_NUMBER_ADDR_POS);
  subtype STAT_INFO_ADDR_TYPE         is std_logic_vector(C_STAT_INFO_ADDR_POS);
  subtype STAT_SUB_ADDR_TYPE          is std_logic_vector(C_STAT_SUB_ADDR_POS);
  subtype STAT_CONFIG_ADDR_TYPE       is std_logic_vector(C_STAT_CONFIG_ADDR_POS);
  subtype STAT_WORD_ADDR_TYPE         is std_logic_vector(C_STAT_WORD_ADDR_POS);
  
  constant C_STAT_CATEGORY_NUM        : natural := 2 ** (STAT_CATEGORY_ADDR_TYPE'high - STAT_CATEGORY_ADDR_TYPE'low + 1);
  constant C_STAT_NUMBER_NUM          : natural := 2 ** (STAT_NUMBER_ADDR_TYPE'high   - STAT_NUMBER_ADDR_TYPE'low + 1);
  constant C_STAT_INFO_NUM            : natural := 2 ** (STAT_INFO_ADDR_TYPE'high     - STAT_INFO_ADDR_TYPE'low + 1);
  constant C_STAT_SUB_NUM             : natural := 2 ** (STAT_SUB_ADDR_TYPE'high      - STAT_SUB_ADDR_TYPE'low + 1);
  constant C_STAT_CONFIG_NUM          : natural := 2 ** (STAT_CONFIG_ADDR_TYPE'high   - STAT_CONFIG_ADDR_TYPE'low + 1);
  constant C_STAT_WORD_NUM            : natural := 2 ** (STAT_WORD_ADDR_TYPE'high     - STAT_WORD_ADDR_TYPE'low + 1);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  type AC_TYPE is record
    Addr              : AXI_ADDR_TYPE;
    DSid			  : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  end record AC_TYPE;
  
  constant C_NULL_AC                : AC_TYPE    := (Addr=>(others=>'0'), DSid=>(others=>'0'));
  
  type AC_FIFO_MEM_TYPE             is array(QUEUE_ADDR_POS)      of AC_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
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
      C_QUEUE_ADDR_WIDTH        : natural range  2 to    8      :=  5;
      C_LINE_LENGTH             : natural range  1 to  128      :=  4
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
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Local Reset
  
  signal ARESET_I                   : std_logic;
--  attribute dont_touch              : string;
--  attribute dont_touch              of Reset_Inst     : label is "true";
  
  
  -- ----------------------------------------
  -- Initilization Handler
  
  signal ctrl_init_done_i           : std_logic;
  signal ctrl_init_cnt              : ADDR_ALL_SETS_TYPE;
  
  
  -- ----------------------------------------
  -- Automatic Clean handling
  
  signal ac_valid                   : std_logic;
  signal ac_addr                    : AXI_ADDR_TYPE;
  signal ac_DSid                    : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  signal ac_scaler                  : std_logic_vector(9 downto 0);
  signal ac_cnt                     : ADDR_ALL_SETS_TYPE;
  
  signal ac_push                    : std_logic;
  signal ac_pop                     : std_logic;
  signal ac_fifo_empty              : std_logic;
  signal ac_read_fifo_addr          : QUEUE_ADDR_TYPE;
  signal ac_fifo_mem                : AC_FIFO_MEM_TYPE;
  
  
  -- ----------------------------------------
  -- Transaction Handler
  
  signal ctrl_access_i              : ARBITRATION_TYPE;
  
  
  -- ----------------------------------------
  -- Write Handling
  
  signal write_ongoing              : std_logic;
  signal write_1st_cycle            : std_logic;
  signal write_2nd_cycle            : std_logic;
  signal w_data                     : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
  signal S_AXI_CTRL_BVALID_I        : std_logic;
  
  
  -- ----------------------------------------
  -- Read Handling
  
  signal read_ongoing               : std_logic;
  signal read_ongoing_d1            : std_logic;
  signal read_ongoing_d2            : std_logic;
  signal read_ongoing_d3            : std_logic;
  signal read_ongoing_d4            : std_logic;
  signal S_AXI_CTRL_RVALID_I        : std_logic;
  signal S_AXI_CTRL_RDATA_I         : std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
  
  
  -- ----------------------------------------
  -- Command registers (Read/Write)
  
  signal wr_word_idx                : natural range 0 to 2 ** STAT_WORD_ADDR_TYPE'length - 1;
  signal wr_cfg_idx                 : natural range 0 to 2 ** STAT_CONFIG_ADDR_TYPE'length - 1;
  signal wr_sub_idx                 : natural range 0 to 2 ** STAT_SUB_ADDR_TYPE'length - 1;
  signal wr_info_idx                : natural range 0 to 2 ** STAT_INFO_ADDR_TYPE'length - 1;
  signal wr_num_idx                 : natural range 0 to 2 ** STAT_NUMBER_ADDR_TYPE'length - 1;
  signal wr_cat_idx                 : natural range 0 to 2 ** STAT_CATEGORY_ADDR_TYPE'length - 1;
  
  signal stat_s_axi_rd_latency_conf_i     : STAT_CONF_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_wr_latency_conf_i     : STAT_CONF_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_s_axi_gen_rd_latency_conf_i : STAT_CONF_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_s_axi_gen_wr_latency_conf_i : STAT_CONF_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_be_rd_latency_conf_i        : STAT_CONF_TYPE;
  signal stat_be_wr_latency_conf_i        : STAT_CONF_TYPE;
  signal stat_ctrl_conf_i                 : STAT_CONF_TYPE;
  signal stat_ctrl_version_register_0     : STAT_CONF_TYPE := Stat_Conf_Set_Register(C_VERSION_REGISTER(0), 32);
  signal stat_ctrl_version_register_1     : STAT_CONF_TYPE := Stat_Conf_Set_Register(C_VERSION_REGISTER(1), 32);
    
    
  -- ----------------------------------------
  -- Statistics registers (Read)
  
  signal word_idx                   : natural range 0 to 2 ** STAT_WORD_ADDR_TYPE'length - 1;
  signal cfg_idx                    : natural range 0 to 2 ** STAT_CONFIG_ADDR_TYPE'length - 1;
  signal sub_idx                    : natural range 0 to 2 ** STAT_SUB_ADDR_TYPE'length - 1;
  signal info_idx                   : natural range 0 to 2 ** STAT_INFO_ADDR_TYPE'length - 1;
  signal num_idx                    : natural range 0 to 2 ** STAT_NUMBER_ADDR_TYPE'length - 1;
  signal cat_idx                    : natural range 0 to 2 ** STAT_CATEGORY_ADDR_TYPE'length - 1;
  
  signal stat_opt_rd_segments       : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
  signal stat_opt_wr_segments       : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0); -- Per transaction
  signal stat_opt_rip               : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_r                 : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_bip               : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_bp                : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_wip               : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_w                 : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_rd_latency        : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_wr_latency        : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_rd_latency_conf   : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_wr_latency_conf   : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt                   : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_gen_rd_segments       : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0); -- Per transaction
  signal stat_gen_wr_segments       : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0); -- Per transaction
  signal stat_gen_rip               : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_r                 : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_bip               : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_bp                : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_wip               : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_w                 : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_rd_latency        : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_wr_latency        : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_rd_latency_conf   : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_wr_latency_conf   : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen                   : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_arb_opt_rd_blocked    : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_arb_gen_rd_blocked    : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_arbiter               : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_access                : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_opt_write_hit         : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_write_miss        : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_write_miss_dirty  : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_read_hit          : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_read_miss         : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_read_miss_dirty   : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_locked_write_hit  : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_locked_read_hit   : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_opt_first_write_hit   : STAT_VECTOR_TYPE(C_MAX_OPTIMIZED_PORTS - 1 downto 0);
  signal stat_gen_write_hit         : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_write_miss        : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_write_miss_dirty  : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_read_hit          : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_read_miss         : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_read_miss_dirty   : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_locked_write_hit  : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_locked_read_hit   : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_gen_first_write_hit   : STAT_VECTOR_TYPE(C_MAX_GENERIC_PORTS - 1 downto 0);
  signal stat_lookup                : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_update                : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_backend               : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_ctrl                  : STAT_VECTOR_TYPE(C_STAT_INFO_NUM - 1 downto 0);
  
  signal stat_result                : STAT_VECTOR_TYPE(C_STAT_CATEGORY_NUM - 1 downto 0);
  
  signal stat_reset_i               : std_logic;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1             : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
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
  -- Initilization Handler
  -----------------------------------------------------------------------------
  
  Initialization_Handle : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active true)
        ctrl_init_done_i  <= '0';
        ctrl_init_cnt     <= (others=>'0');
        
      else
        -- Handle counting.
        if( ( ctrl_init_done_i = '0' ) and ( ctrl_ready = '1' ) ) then
          ctrl_init_cnt     <= std_logic_vector(unsigned(ctrl_init_cnt) + 1);
          
          -- Handle status.
          if( ctrl_init_cnt = C_INIT_CNT_MAX ) then
            ctrl_init_done_i  <= '1';
            
          end if;
          
        end if;
        
      end if;
    end if;
  end process Initialization_Handle;
  
  ctrl_init_done  <= ctrl_init_done_i;
  
  
  -----------------------------------------------------------------------------
  -- Transaction Handler
  -----------------------------------------------------------------------------
  
  Transaction_Handle : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active true)
        ctrl_access_i                     <= C_NULL_ARBITRATION;
        
      else
        if( ( wr_cat_idx = C_STAT_ADDR_CTRL_CATEGORY ) and 
            ( ( wr_cfg_idx = C_STAT_ADDR_CTRL_CLEAN ) or ( wr_cfg_idx = C_STAT_ADDR_CTRL_FLUSH ) ) and
            ( write_1st_cycle = '1' ) and
            ( C_ENABLE_STATISTICS > 0 ) ) then
          -- Starting a transaction.
          ctrl_access_i.Valid         <= '1';
          ctrl_access_i.Wr            <= '0';
          ctrl_access_i.Port_Num      <= (others=>'0');
          ctrl_access_i.Addr          <= fit_vec(w_data, C_MAX_ADDR_WIDTH);
          ctrl_access_i.Len           <= NULL_AXI_LENGTH;
          ctrl_access_i.Kind          <= C_KIND_WRAP;
          ctrl_access_i.Exclusive     <= '0';
          ctrl_access_i.Allocate      <= '0';
          ctrl_access_i.Bufferable    <= '0';
          ctrl_access_i.Evict         <= '1';
          ctrl_access_i.Prot          <= NULL_AXI_PROT;
          if( wr_cfg_idx = C_STAT_ADDR_CTRL_CLEAN ) then
            ctrl_access_i.Snoop         <= C_ARSNOOP_MakeInvalid;
            ctrl_access_i.Ignore_Data   <= '1';
          else
            ctrl_access_i.Snoop         <= C_ARSNOOP_CleanInvalid;
            ctrl_access_i.Ignore_Data   <= '0';
          end if;
          ctrl_access_i.Force_Hit     <= '0';
          ctrl_access_i.Internal_Cmd  <= '1';
          ctrl_access_i.Barrier       <= C_BAR_NORMAL_RESPECTING;
          ctrl_access_i.Domain        <= C_DOMAIN_INNER_SHAREABLE;
          ctrl_access_i.Size          <= C_WORD_SIZE;
          
        elsif( ( ( ctrl_access_i.Valid = '0' ) or ( ctrl_ready = '1' ) ) and 
               ( ctrl_init_done_i = '0' ) ) then 
          -- Generating init sequence transactions.
          ctrl_access_i.Valid         <= '1';
          ctrl_access_i.Wr            <= '0';
          ctrl_access_i.Port_Num      <= (others=>'0');
          ctrl_access_i.Addr          <= (others=>'0');
          ctrl_access_i.Addr(C_ADDR_ALL_SETS_POS)
                                      <= ctrl_init_cnt;
          ctrl_access_i.Len           <= NULL_AXI_LENGTH;
          ctrl_access_i.Kind          <= C_KIND_WRAP;
          ctrl_access_i.Exclusive     <= '0';
          ctrl_access_i.Allocate      <= '0';
          ctrl_access_i.Bufferable    <= '0';
          ctrl_access_i.Evict         <= '1';
          ctrl_access_i.Prot          <= NULL_AXI_PROT;
          ctrl_access_i.Snoop         <= C_ARSNOOP_MakeInvalid;
          ctrl_access_i.Ignore_Data   <= '1';
          ctrl_access_i.Force_Hit     <= '1';
          ctrl_access_i.Internal_Cmd  <= '1';
          ctrl_access_i.Barrier       <= C_BAR_NORMAL_RESPECTING;
          ctrl_access_i.Domain        <= C_DOMAIN_INNER_SHAREABLE;
          ctrl_access_i.Size          <= C_WORD_SIZE;
          
        elsif( ( ( ctrl_access_i.Valid = '0' ) or ( ctrl_ready = '1' ) ) and 
               ( ctrl_init_done_i = '1' ) and ( ac_valid = '1' ) and 
               ( C_ENABLE_AUTOMATIC_CLEAN > 0 ) ) then 
          -- Generating init sequence transactions.
          ctrl_access_i.Valid         <= '1';
          ctrl_access_i.Wr            <= '0';
          ctrl_access_i.Port_Num      <= (others=>'0');
          ctrl_access_i.Addr          <= ac_addr;
          ctrl_access_i.DSid          <= ac_DSid;
          ctrl_access_i.Len           <= NULL_AXI_LENGTH;
          ctrl_access_i.Kind          <= C_KIND_WRAP;
          ctrl_access_i.Exclusive     <= '0';
          ctrl_access_i.Allocate      <= '1';
          ctrl_access_i.Bufferable    <= '0';
          ctrl_access_i.Evict         <= '1';
          ctrl_access_i.Prot          <= NULL_AXI_PROT;
          ctrl_access_i.Snoop         <= C_ARSNOOP_CleanInvalid;
          ctrl_access_i.Ignore_Data   <= '0';
          ctrl_access_i.Force_Hit     <= '0';
          ctrl_access_i.Internal_Cmd  <= '1';
          ctrl_access_i.Barrier       <= C_BAR_NORMAL_RESPECTING;
          ctrl_access_i.Domain        <= C_DOMAIN_INNER_SHAREABLE;
          ctrl_access_i.Size          <= C_WORD_SIZE;
          
        elsif( ctrl_ready = '1' ) then
          -- End transaction.
          ctrl_access_i.Valid       <= '0';
          
        end if;
        
      end if;
    end if;
  end process Transaction_Handle;
  
  ctrl_access                     <= ctrl_access_i;
  
  
  -----------------------------------------------------------------------------
  -- Automatic Clean handling
  -----------------------------------------------------------------------------
  
  Use_AC: if ( C_ENABLE_AUTOMATIC_CLEAN > 0 ) generate
  begin
  
    Use_Mode_0: if ( C_AUTOMATIC_CLEAN_MODE /= 1 ) generate
    begin
      -- Unused signals
      ac_push           <= '0';
      ac_pop            <= '0';
      ac_fifo_empty     <= '1';
      ac_read_fifo_addr <= (others=>'0');
      
      ac_scaler         <= (others=>'0');
      ac_cnt            <= (others=>'0');
      
      ac_valid          <= '0';
      ac_addr           <= (others=>'0');
      ac_DSid           <= (others=>'0');
    end generate Use_Mode_0;
    
    Use_Mode_1: if ( C_AUTOMATIC_CLEAN_MODE = 1 ) generate
      signal wma_fifo_mem               : AC_FIFO_MEM_TYPE; -- := (others=>C_NULL_AC);
    begin
      
      ac_push <= update_auto_clean_push;
      ac_pop  <= ac_valid and ctrl_ready;
      
      FIFO_AC_Pointer: sc_srl_fifo_counter
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
          C_ENABLE_PROTECTION       => true,
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
          
          queue_push                => ac_push,
          queue_pop                 => ac_pop,
          queue_push_qualifier      => '0',
          queue_pop_qualifier       => '0',
          queue_refresh_reg         => open,
          
          queue_almost_full         => open,
          queue_full                => open,
          queue_almost_empty        => open,
          queue_empty               => ac_fifo_empty,
          queue_exist               => open,
          queue_line_fit            => open,
          queue_index               => ac_read_fifo_addr,
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_reset                => stat_reset_i,
          stat_enable               => stat_ctrl_conf_i(C_CTRL_CONF_ENABLE),
          
          stat_data                 => open,
          
          
          -- ---------------------------------------------------
          -- Assert Signals
          
          assert_error              => open,
          
          
          -- ---------------------------------------------------
          -- Debug Signals
          
          DEBUG                     => open
        );
      
      -- Handle memory for Write Miss Allocate FIFO.
      FIFO_AC_Memory : process (ACLK) is
      begin  -- process FIFO_AC_Memory
        if (ACLK'event and ACLK = '1') then    -- rising clock edge
          if ( ac_push = '1' ) then
            -- Insert new item.
            ac_fifo_mem(0).Addr <= update_auto_clean_addr;
            ac_fifo_mem(0).DSid <= update_auto_clean_DSid;
            -- Shift FIFO contents.
            ac_fifo_mem(ac_fifo_mem'left downto 1) <= ac_fifo_mem(ac_fifo_mem'left-1 downto 0);
          end if;
        end if;
      end process FIFO_AC_Memory;
      
      ac_valid      <= not ac_fifo_empty;
      
      -- Extract current Write Miss information.
      ac_addr       <= ac_fifo_mem(to_integer(unsigned(ac_read_fifo_addr))).Addr;
      ac_DSid	    <= ac_fifo_mem(to_integer(unsigned(ac_read_fifo_addr))).DSid;
      -- Unused
      ac_scaler     <= (others=>'0');
      ac_cnt        <= (others=>'0');
      
    end generate Use_Mode_1;
  
  end generate Use_AC;
  
  No_AC: if ( C_ENABLE_AUTOMATIC_CLEAN < 1 ) generate
  begin
    
    -- Unused signals
    ac_push           <= '0';
    ac_pop            <= '0';
    ac_fifo_empty     <= '1';
    ac_read_fifo_addr <= (others=>'0');
    ac_scaler         <= (others=>'0');
    ac_cnt            <= (others=>'0');
    ac_valid          <= '0';
    ac_addr           <= (others=>'0');
    ac_DSid           <= (others=>'0');
  end generate No_AC;
  
  
  -----------------------------------------------------------------------------
  -- Statistics handling
  -----------------------------------------------------------------------------
  
  Use_Ctrl: if ( C_ENABLE_CTRL > 0 ) generate
    
    signal aw_addr                    : std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    signal ar_addr                    : std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
    
  begin
    
    -----------------------------------------------------------------------------
    -- Write Handling
    -----------------------------------------------------------------------------
    
    Write_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          write_ongoing       <= '0';
          write_1st_cycle     <= '0';
          write_2nd_cycle     <= '0';
          S_AXI_CTRL_BVALID_I <= '0';
          aw_addr             <= (others=>'0');
          w_data              <= (others=>'0');
          
        else
          -- Default assignment.
          write_1st_cycle     <= '0';
          write_2nd_cycle     <= write_1st_cycle;
          
          -- Control response.
          if( S_AXI_CTRL_BVALID_I = '1' and S_AXI_CTRL_BREADY = '1' ) then
            S_AXI_CTRL_BVALID_I <= '0';
            
          elsif( ( ( ctrl_access_i.Valid = '0' ) and ( write_2nd_cycle = '1' ) ) or 
                 ( ( ctrl_access_i.Valid = '1' ) and ( ctrl_ready      = '1' ) and 
                    ( ctrl_init_done_i   = '1' ) and ( write_ongoing   = '1' ) ) ) then
            S_AXI_CTRL_BVALID_I <= '1';
            
          end if;
          
          -- Control write sequence.
          if( S_AXI_CTRL_BVALID_I = '1' and S_AXI_CTRL_BREADY = '1' ) then
            write_ongoing       <= '0';
            write_1st_cycle     <= '0';
            
          elsif( S_AXI_CTRL_AWVALID = '1' and  S_AXI_CTRL_WVALID = '1' and write_ongoing = '0' and 
                 ctrl_init_done_i = '1' ) then
            write_ongoing       <= '1';
            write_1st_cycle     <= '1';
            
          end if;
          
          -- Capture data and address.
          if( S_AXI_CTRL_AWVALID = '1' and  S_AXI_CTRL_WVALID = '1' and write_ongoing = '0' ) then
            aw_addr             <= S_AXI_CTRL_AWADDR;
            w_data              <= S_AXI_CTRL_WDATA;
            
          end if;
          
        end if;
      end if;
    end process Write_Handle;
    
    -- AW-Channel.
    S_AXI_CTRL_AWREADY  <= write_1st_cycle;
  
    -- W-Channel.
    S_AXI_CTRL_WREADY   <= write_1st_cycle;
  
    -- B-Channel.
    S_AXI_CTRL_BRESP    <= C_BRESP_OKAY;
  
    
    -----------------------------------------------------------------------------
    -- Read Handling
    -----------------------------------------------------------------------------
    
    Read_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          read_ongoing    <= '0';
          read_ongoing_d1 <= '0';
          read_ongoing_d2 <= '0';
          read_ongoing_d3 <= '0';
          read_ongoing_d4 <= '0';
          ar_addr         <= (others=>'0');
        else
          read_ongoing_d1 <= read_ongoing;
          read_ongoing_d2 <= read_ongoing_d1;
          read_ongoing_d3 <= read_ongoing_d2;
          read_ongoing_d4 <= read_ongoing_d3;
        
          if( S_AXI_CTRL_RVALID_I = '1' and S_AXI_CTRL_RREADY = '1' ) then
            read_ongoing    <= '0';
            read_ongoing_d1 <= '0';
            read_ongoing_d2 <= '0';
            read_ongoing_d3 <= '0';
            read_ongoing_d4 <= '0';
          elsif( S_AXI_CTRL_ARVALID = '1' and read_ongoing = '0' ) then
            read_ongoing    <= '1';
            ar_addr         <= S_AXI_CTRL_ARADDR;
          end if;
        end if;
      end if;
    end process Read_Handle;
    
    -- AR-Channel.
    S_AXI_CTRL_ARREADY  <= not read_ongoing;
  
    -- R-Channel.
    S_AXI_CTRL_RVALID_I <= read_ongoing_d4;
    S_AXI_CTRL_RRESP    <= (others=>'0');
    
    
    -----------------------------------------------------------------------------
    -- Command registers (Read/Write)
    -----------------------------------------------------------------------------
    
    -- Extract index from address.
    wr_word_idx <= to_integer(unsigned(aw_addr(C_STAT_WORD_ADDR_POS)));
    wr_cfg_idx  <= to_integer(unsigned(aw_addr(C_STAT_CONFIG_ADDR_POS)));
    wr_sub_idx  <= to_integer(unsigned(aw_addr(C_STAT_SUB_ADDR_POS)));
    wr_info_idx <= to_integer(unsigned(aw_addr(C_STAT_INFO_ADDR_POS)));
    wr_num_idx  <= to_integer(unsigned(aw_addr(C_STAT_NUMBER_ADDR_POS)));
    wr_cat_idx  <= to_integer(unsigned(aw_addr(C_STAT_CATEGORY_ADDR_POS)));
    
    
    -- Register bank.
    Register_Bank : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          stat_s_axi_rd_latency_conf_i      <= (others=>Stat_Conf_Set_Register(C_STAT_DEFAULT_RD_LAT_CONF, 
                                                                               C_RD_LATENCY_WIDTH));
          stat_s_axi_wr_latency_conf_i      <= (others=>Stat_Conf_Set_Register(C_STAT_DEFAULT_WR_LAT_CONF, 
                                                                               C_WR_LATENCY_WIDTH));
          stat_s_axi_gen_rd_latency_conf_i  <= (others=>Stat_Conf_Set_Register(C_STAT_DEFAULT_RD_LAT_CONF, 
                                                                               C_RD_LATENCY_WIDTH));
          stat_s_axi_gen_wr_latency_conf_i  <= (others=>Stat_Conf_Set_Register(C_STAT_DEFAULT_WR_LAT_CONF, 
                                                                               C_WR_LATENCY_WIDTH));
          stat_be_rd_latency_conf_i         <= Stat_Conf_Set_Register(C_STAT_DEFAULT_RD_LAT_CONF, C_RD_LATENCY_WIDTH);
          stat_be_wr_latency_conf_i         <= Stat_Conf_Set_Register(C_STAT_DEFAULT_WR_LAT_CONF, C_WR_LATENCY_WIDTH);
          
          stat_ctrl_conf_i                  <= Stat_Conf_Set_Register(C_STAT_DEFAULT_CTRL_CONF, C_CTRL_CONF_WIDTH);
          
        elsif( write_1st_cycle = '1' ) then
          -- Select Optimized type stat (Clk 1).
          for I in 0 to C_NUM_OPTIMIZED_PORTS - 1 loop
            if( I = wr_num_idx ) then
              if( ( wr_cat_idx = C_STAT_ADDR_OPT_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_OPT_RD_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_OPT_CATEGORY) = '1' ) ) then
                stat_s_axi_rd_latency_conf_i(I) <= Stat_Conf_Set_Register(w_data, C_RD_LATENCY_WIDTH);
              end if;
              if( ( wr_cat_idx = C_STAT_ADDR_OPT_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_OPT_WR_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_OPT_CATEGORY) = '1' ) ) then
                stat_s_axi_wr_latency_conf_i(I) <= Stat_Conf_Set_Register(w_data, C_WR_LATENCY_WIDTH);
              end if;
            end if;
          end loop;
      
          -- Select Genereic type stat.
          for I in 0 to C_MAX_GENERIC_PORTS - 1 loop
            if( I = wr_num_idx ) then
              if( ( wr_cat_idx = C_STAT_ADDR_GEN_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_GEN_RD_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_GEN_CATEGORY) = '1' ) ) then
                stat_s_axi_gen_rd_latency_conf_i(I) <= Stat_Conf_Set_Register(w_data, C_RD_LATENCY_WIDTH);
              end if;
              if( ( wr_cat_idx = C_STAT_ADDR_GEN_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_GEN_WR_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_GEN_CATEGORY) = '1' ) ) then
                stat_s_axi_gen_wr_latency_conf_i(I) <= Stat_Conf_Set_Register(w_data, C_WR_LATENCY_WIDTH);
              end if;
            end if;
          end loop;
          
          -- M_AXI.
          if( ( wr_cat_idx = C_STAT_ADDR_BE_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_BE_RD_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_BE_CATEGORY) = '1' ) ) then
            stat_be_rd_latency_conf_i  <= Stat_Conf_Set_Register(w_data, C_RD_LATENCY_WIDTH);
          end if;
          if( ( wr_cat_idx = C_STAT_ADDR_BE_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_BE_WR_LAT_CONF ) and
                  ( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_BE_CATEGORY) = '1' ) ) then
            stat_be_wr_latency_conf_i  <= Stat_Conf_Set_Register(w_data, C_WR_LATENCY_WIDTH);
          end if;
          
          -- Ctrl.
          if( ( wr_cat_idx = C_STAT_ADDR_CTRL_CATEGORY ) and ( wr_cfg_idx = C_STAT_ADDR_CTRL_ENABLE ) and
              ( C_ENABLE_STATISTICS > 0 ) ) then
              stat_ctrl_conf_i         <= Stat_Conf_Set_Register(w_data, C_CTRL_CONF_WIDTH);
          end if;
          
        end if;
      end if;
    end process Register_Bank;
    
    -- Assign external signals.
    stat_s_axi_rd_latency_conf      <= stat_s_axi_rd_latency_conf_i(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_wr_latency_conf      <= stat_s_axi_wr_latency_conf_i(C_NUM_OPTIMIZED_PORTS - 1 downto 0);
    stat_s_axi_gen_rd_latency_conf  <= stat_s_axi_gen_rd_latency_conf_i(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_s_axi_gen_wr_latency_conf  <= stat_s_axi_gen_wr_latency_conf_i(C_NUM_GENERIC_PORTS - 1 downto 0);
    stat_be_rd_latency_conf         <= stat_be_rd_latency_conf_i;
    stat_be_wr_latency_conf         <= stat_be_wr_latency_conf_i;
    
    stat_enable                     <= stat_ctrl_conf_i(C_CTRL_CONF_ENABLE);
    
    
    -----------------------------------------------------------------------------
    -- Statistics reset
    -----------------------------------------------------------------------------
    
    Reset_Handler : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ( wr_cat_idx = C_STAT_ADDR_CTRL_CATEGORY ) and ( wr_info_idx = C_STAT_ADDR_CTRL_RESET ) ) then
          stat_reset_i  <= ARESET_I or write_1st_cycle or not ctrl_init_done_i;
        else
          stat_reset_i  <= ARESET_I or not ctrl_init_done_i;
        end if;
      end if;
    end process Reset_Handler;
    
    stat_reset  <= stat_reset_i;
    
    
    -----------------------------------------------------------------------------
    -- Statistics registers (Read)
    -----------------------------------------------------------------------------
    
    -- Extract index from address.
    word_idx  <= to_integer(unsigned(ar_addr(C_STAT_WORD_ADDR_POS)));
    cfg_idx   <= to_integer(unsigned(ar_addr(C_STAT_CONFIG_ADDR_POS)));
    sub_idx   <= to_integer(unsigned(ar_addr(C_STAT_SUB_ADDR_POS)));
    info_idx  <= to_integer(unsigned(ar_addr(C_STAT_INFO_ADDR_POS)));
    num_idx   <= to_integer(unsigned(ar_addr(C_STAT_NUMBER_ADDR_POS)));
    cat_idx   <= to_integer(unsigned(ar_addr(C_STAT_CATEGORY_ADDR_POS)));
    
    Read_Mux : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          for I in 0 to C_MAX_OPTIMIZED_PORTS - 1 loop
            stat_opt_rd_segments(I)       <= (others=>'0');
            stat_opt_wr_segments(I)       <= (others=>'0');
            stat_opt_rip(I)               <= (others=>'0');
            stat_opt_r(I)                 <= (others=>'0');
            stat_opt_bip(I)               <= (others=>'0');
            stat_opt_bp(I)                <= (others=>'0');
            stat_opt_wip(I)               <= (others=>'0');
            stat_opt_w(I)                 <= (others=>'0');
            stat_opt_rd_latency(I)        <= (others=>'0');
            stat_opt_wr_latency(I)        <= (others=>'0');
            stat_opt_rd_latency_conf(I)   <= (others=>'0');
            stat_opt_wr_latency_conf(I)   <= (others=>'0');
            stat_arb_opt_rd_blocked(I)    <= (others=>'0');
            stat_opt_write_hit(I)         <= (others=>'0');
            stat_opt_write_miss(I)        <= (others=>'0');
            stat_opt_write_miss_dirty(I)  <= (others=>'0');
            stat_opt_read_hit(I)          <= (others=>'0');
            stat_opt_read_miss(I)         <= (others=>'0');
            stat_opt_read_miss_dirty(I)   <= (others=>'0');
            stat_opt_locked_write_hit(I)  <= (others=>'0');
            stat_opt_locked_read_hit(I)   <= (others=>'0');
            stat_opt_first_write_hit(I)   <= (others=>'0');
          end loop;
          for I in 0 to C_MAX_GENERIC_PORTS - 1 loop
            stat_gen_rd_segments(I)       <= (others=>'0');
            stat_gen_wr_segments(I)       <= (others=>'0');
            stat_gen_rip(I)               <= (others=>'0');
            stat_gen_r(I)                 <= (others=>'0');
            stat_gen_bip(I)               <= (others=>'0');
            stat_gen_bp(I)                <= (others=>'0');
            stat_gen_wip(I)               <= (others=>'0');
            stat_gen_w(I)                 <= (others=>'0');
            stat_gen_rd_latency(I)        <= (others=>'0');
            stat_gen_wr_latency(I)        <= (others=>'0');
            stat_gen_rd_latency_conf(I)   <= (others=>'0');
            stat_gen_wr_latency_conf(I)   <= (others=>'0');
            stat_arb_gen_rd_blocked(I)    <= (others=>'0');
            stat_gen_write_hit(I)         <= (others=>'0');
            stat_gen_write_miss(I)        <= (others=>'0');
            stat_gen_write_miss_dirty(I)  <= (others=>'0');
            stat_gen_read_hit(I)          <= (others=>'0');
            stat_gen_read_miss(I)         <= (others=>'0');
            stat_gen_read_miss_dirty(I)   <= (others=>'0');
            stat_gen_locked_write_hit(I)  <= (others=>'0');
            stat_gen_locked_read_hit(I)   <= (others=>'0');
            stat_gen_first_write_hit(I)   <= (others=>'0');
          end loop;
          stat_opt                                      <= (others=>(others=>'0'));
          stat_gen                                      <= (others=>(others=>'0'));
          stat_arbiter                                  <= (others=>(others=>'0'));
          stat_access                                   <= (others=>(others=>'0'));
          stat_lookup                                   <= (others=>(others=>'0'));
          stat_update                                   <= (others=>(others=>'0'));
          stat_backend                                  <= (others=>(others=>'0'));
          stat_ctrl                                     <= (others=>(others=>'0'));
          stat_result                                   <= (others=>(others=>'0'));
        
          S_AXI_CTRL_RDATA_I                            <= (others=>'0');
        else
          -- Default assignment.
          
          -- Select Optimized type stat (Clk 1).
          for I in 0 to C_MAX_OPTIMIZED_PORTS - 1 loop
            if( I < C_NUM_OPTIMIZED_PORTS ) then
              stat_opt_rd_segments(I)       <= Stat_Point_Get_Register(stat_s_axi_rd_segments(I),       sub_idx);
              stat_opt_wr_segments(I)       <= Stat_Point_Get_Register(stat_s_axi_wr_segments(I),       sub_idx);
              stat_opt_rip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_rip(I),                sub_idx);
              stat_opt_r(I)                 <= Stat_FIFO_Get_Register(stat_s_axi_r(I),                  sub_idx);
              stat_opt_bip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_bip(I),                sub_idx);
              stat_opt_bp(I)                <= Stat_FIFO_Get_Register(stat_s_axi_bp(I),                 sub_idx);
              stat_opt_wip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_wip(I),                sub_idx);
              stat_opt_w(I)                 <= Stat_FIFO_Get_Register(stat_s_axi_w(I),                  sub_idx);
              stat_opt_rd_latency(I)        <= Stat_Point_Get_Register(stat_s_axi_rd_latency(I),        sub_idx);
              stat_opt_wr_latency(I)        <= Stat_Point_Get_Register(stat_s_axi_wr_latency(I),        sub_idx);
              stat_opt_rd_latency_conf(I)   <= Stat_Conf_Get_Register(stat_s_axi_rd_latency_conf_i(I));
              stat_opt_wr_latency_conf(I)   <= Stat_Conf_Get_Register(stat_s_axi_wr_latency_conf_i(I));
              stat_arb_opt_rd_blocked(I)    <= Stat_Point_Get_Register(stat_arb_opt_read_blocked(I),    sub_idx);
              stat_opt_write_hit(I)         <= Stat_Point_Get_Register(stat_lu_opt_write_hit(I),        sub_idx);
              stat_opt_write_miss(I)        <= Stat_Point_Get_Register(stat_lu_opt_write_miss(I),       sub_idx);
              stat_opt_write_miss_dirty(I)  <= Stat_Point_Get_Register(stat_lu_opt_write_miss_dirty(I), sub_idx);
              stat_opt_read_hit(I)          <= Stat_Point_Get_Register(stat_lu_opt_read_hit(I),         sub_idx);
              stat_opt_read_miss(I)         <= Stat_Point_Get_Register(stat_lu_opt_read_miss(I),        sub_idx);
              stat_opt_read_miss_dirty(I)   <= Stat_Point_Get_Register(stat_lu_opt_read_miss_dirty(I),  sub_idx);
              stat_opt_locked_write_hit(I)  <= Stat_Point_Get_Register(stat_lu_opt_locked_write_hit(I), sub_idx);
              stat_opt_locked_read_hit(I)   <= Stat_Point_Get_Register(stat_lu_opt_locked_read_hit(I),  sub_idx);
              stat_opt_first_write_hit(I)   <= Stat_Point_Get_Register(stat_lu_opt_first_write_hit(I),  sub_idx);
            else
              stat_opt_rd_segments(I)       <= (others=>'0');
              stat_opt_wr_segments(I)       <= (others=>'0');
              stat_opt_rip(I)               <= (others=>'0');
              stat_opt_r(I)                 <= (others=>'0');
              stat_opt_bip(I)               <= (others=>'0');
              stat_opt_bp(I)                <= (others=>'0');
              stat_opt_wip(I)               <= (others=>'0');
              stat_opt_w(I)                 <= (others=>'0');
              stat_opt_rd_latency(I)        <= (others=>'0');
              stat_opt_wr_latency(I)        <= (others=>'0');
              stat_opt_rd_latency_conf(I)   <= (others=>'0');
              stat_opt_wr_latency_conf(I)   <= (others=>'0');
              stat_arb_opt_rd_blocked(I)    <= (others=>'0');
              stat_opt_write_hit(I)         <= (others=>'0');
              stat_opt_write_miss(I)        <= (others=>'0');
              stat_opt_write_miss_dirty(I)  <= (others=>'0');
              stat_opt_read_hit(I)          <= (others=>'0');
              stat_opt_read_miss(I)         <= (others=>'0');
              stat_opt_read_miss_dirty(I)   <= (others=>'0');
              stat_opt_locked_write_hit(I)  <= (others=>'0');
              stat_opt_locked_read_hit(I)   <= (others=>'0');
              stat_opt_first_write_hit(I)   <= (others=>'0');
            end if;
          end loop;
      
          -- Select Genereic type stat (Clk 1).
          for I in 0 to C_MAX_GENERIC_PORTS - 1 loop
            if( I < C_NUM_GENERIC_PORTS ) then
              stat_gen_rd_segments(I)       <= Stat_Point_Get_Register(stat_s_axi_gen_rd_segments(I),       sub_idx);
              stat_gen_wr_segments(I)       <= Stat_Point_Get_Register(stat_s_axi_gen_wr_segments(I),       sub_idx);
              stat_gen_rip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_gen_rip(I),                sub_idx);
              stat_gen_r(I)                 <= Stat_FIFO_Get_Register(stat_s_axi_gen_r(I),                  sub_idx);
              stat_gen_bip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_gen_bip(I),                sub_idx);
              stat_gen_bp(I)                <= Stat_FIFO_Get_Register(stat_s_axi_gen_bp(I),                 sub_idx);
              stat_gen_wip(I)               <= Stat_FIFO_Get_Register(stat_s_axi_gen_wip(I),                sub_idx);
              stat_gen_w(I)                 <= Stat_FIFO_Get_Register(stat_s_axi_gen_w(I),                  sub_idx);
              stat_gen_rd_latency(I)        <= Stat_Point_Get_Register(stat_s_axi_gen_rd_latency(I),        sub_idx);
              stat_gen_wr_latency(I)        <= Stat_Point_Get_Register(stat_s_axi_gen_wr_latency(I),        sub_idx);
              stat_gen_rd_latency_conf(I)   <= Stat_Conf_Get_Register(stat_s_axi_gen_rd_latency_conf_i(I));
              stat_gen_wr_latency_conf(I)   <= Stat_Conf_Get_Register(stat_s_axi_gen_wr_latency_conf_i(I));
              stat_arb_gen_rd_blocked(I)    <= Stat_Point_Get_Register(stat_arb_gen_read_blocked(I),        sub_idx);
              stat_gen_write_hit(I)         <= Stat_Point_Get_Register(stat_lu_gen_write_hit(I),            sub_idx);
              stat_gen_write_miss(I)        <= Stat_Point_Get_Register(stat_lu_gen_write_miss(I),           sub_idx);
              stat_gen_write_miss_dirty(I)  <= Stat_Point_Get_Register(stat_lu_gen_write_miss_dirty(I),     sub_idx);
              stat_gen_read_hit(I)          <= Stat_Point_Get_Register(stat_lu_gen_read_hit(I),             sub_idx);
              stat_gen_read_miss(I)         <= Stat_Point_Get_Register(stat_lu_gen_read_miss(I),            sub_idx);
              stat_gen_read_miss_dirty(I)   <= Stat_Point_Get_Register(stat_lu_gen_read_miss_dirty(I),      sub_idx);
              stat_gen_locked_write_hit(I)  <= Stat_Point_Get_Register(stat_lu_gen_locked_write_hit(I),     sub_idx);
              stat_gen_locked_read_hit(I)   <= Stat_Point_Get_Register(stat_lu_gen_locked_read_hit(I),      sub_idx);
              stat_gen_first_write_hit(I)   <= Stat_Point_Get_Register(stat_lu_gen_first_write_hit(I),      sub_idx);
            else
              stat_gen_rd_segments(I)       <= (others=>'0');
              stat_gen_wr_segments(I)       <= (others=>'0');
              stat_gen_rip(I)               <= (others=>'0');
              stat_gen_r(I)                 <= (others=>'0');
              stat_gen_bip(I)               <= (others=>'0');
              stat_gen_bp(I)                <= (others=>'0');
              stat_gen_wip(I)               <= (others=>'0');
              stat_gen_w(I)                 <= (others=>'0');
              stat_gen_rd_latency(I)        <= (others=>'0');
              stat_gen_wr_latency(I)        <= (others=>'0');
              stat_gen_rd_latency_conf(I)   <= (others=>'0');
              stat_gen_wr_latency_conf(I)   <= (others=>'0');
              stat_arb_gen_rd_blocked(I)    <= (others=>'0');
              stat_gen_write_hit(I)         <= (others=>'0');
              stat_gen_write_miss(I)        <= (others=>'0');
              stat_gen_write_miss_dirty(I)  <= (others=>'0');
              stat_gen_read_hit(I)          <= (others=>'0');
              stat_gen_read_miss(I)         <= (others=>'0');
              stat_gen_read_miss_dirty(I)   <= (others=>'0');
              stat_gen_locked_write_hit(I)  <= (others=>'0');
              stat_gen_locked_read_hit(I)   <= (others=>'0');
              stat_gen_first_write_hit(I)   <= (others=>'0');
            end if;
          end loop;
          
          -- Select Optimized type stat (Clk 2).
          stat_opt                                      <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_OPT_CATEGORY) = '1' ) then
            stat_opt(C_STAT_ADDR_OPT_RD_SEGMENTS)         <= Stat_Get_Register(stat_opt_rd_segments,      num_idx);
            stat_opt(C_STAT_ADDR_OPT_WR_SEGMENTS)         <= Stat_Get_Register(stat_opt_wr_segments,      num_idx);
            stat_opt(C_STAT_ADDR_OPT_RIP)                 <= Stat_Get_Register(stat_opt_rip,              num_idx);
            stat_opt(C_STAT_ADDR_OPT_R)                   <= Stat_Get_Register(stat_opt_r,                num_idx);
            stat_opt(C_STAT_ADDR_OPT_BIP)                 <= Stat_Get_Register(stat_opt_bip,              num_idx);
            stat_opt(C_STAT_ADDR_OPT_BP)                  <= Stat_Get_Register(stat_opt_bp,               num_idx);
            stat_opt(C_STAT_ADDR_OPT_WIP)                 <= Stat_Get_Register(stat_opt_wip,              num_idx);
            stat_opt(C_STAT_ADDR_OPT_W)                   <= Stat_Get_Register(stat_opt_w,                num_idx);
            stat_opt(C_STAT_ADDR_OPT_READ_BLOCK)          <= Stat_Get_Register(stat_arb_opt_rd_blocked,   num_idx);
            stat_opt(C_STAT_ADDR_OPT_WRITE_HIT)           <= Stat_Get_Register(stat_opt_write_hit,        num_idx);
            stat_opt(C_STAT_ADDR_OPT_WRITE_MISS)          <= Stat_Get_Register(stat_opt_write_miss,       num_idx);
            stat_opt(C_STAT_ADDR_OPT_WRITE_MISS_DIRTY)    <= Stat_Get_Register(stat_opt_write_miss_dirty, num_idx);
            stat_opt(C_STAT_ADDR_OPT_READ_HIT)            <= Stat_Get_Register(stat_opt_read_hit,         num_idx);
            stat_opt(C_STAT_ADDR_OPT_READ_MISS)           <= Stat_Get_Register(stat_opt_read_miss,        num_idx);
            stat_opt(C_STAT_ADDR_OPT_READ_MISS_DIRTY)     <= Stat_Get_Register(stat_opt_read_miss_dirty,  num_idx);
            stat_opt(C_STAT_ADDR_OPT_LOCKED_WRITE_HIT)    <= Stat_Get_Register(stat_opt_locked_write_hit, num_idx);
            stat_opt(C_STAT_ADDR_OPT_LOCKED_READ_HIT)     <= Stat_Get_Register(stat_opt_locked_read_hit,  num_idx);
            stat_opt(C_STAT_ADDR_OPT_FIRST_WRITE_HIT)     <= Stat_Get_Register(stat_opt_first_write_hit,  num_idx);
            stat_opt(C_STAT_ADDR_OPT_RD_LATENCY)          <= Stat_Get_Register(stat_opt_rd_latency,       num_idx);
            stat_opt(C_STAT_ADDR_OPT_WR_LATENCY)          <= Stat_Get_Register(stat_opt_wr_latency,       num_idx);
            stat_opt(C_STAT_ADDR_OPT_RD_LAT_CONF)         <= Stat_Get_Register(stat_opt_rd_latency_conf,  num_idx);
            stat_opt(C_STAT_ADDR_OPT_WR_LAT_CONF)         <= Stat_Get_Register(stat_opt_wr_latency_conf,  num_idx);
          end if;
          
          -- Select Genereic type stat (Clk 2).
          stat_gen                                      <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_GEN_CATEGORY) = '1' ) then
            stat_gen(C_STAT_ADDR_GEN_RD_SEGMENTS)         <= Stat_Get_Register(stat_gen_rd_segments,      num_idx);
            stat_gen(C_STAT_ADDR_GEN_WR_SEGMENTS)         <= Stat_Get_Register(stat_gen_wr_segments,      num_idx);
            stat_gen(C_STAT_ADDR_GEN_RIP)                 <= Stat_Get_Register(stat_gen_rip,              num_idx);
            stat_gen(C_STAT_ADDR_GEN_R)                   <= Stat_Get_Register(stat_gen_r,                num_idx);
            stat_gen(C_STAT_ADDR_GEN_BIP)                 <= Stat_Get_Register(stat_gen_bip,              num_idx);
            stat_gen(C_STAT_ADDR_GEN_BP)                  <= Stat_Get_Register(stat_gen_bp,               num_idx);
            stat_gen(C_STAT_ADDR_GEN_WIP)                 <= Stat_Get_Register(stat_gen_wip,              num_idx);
            stat_gen(C_STAT_ADDR_GEN_W)                   <= Stat_Get_Register(stat_gen_w,                num_idx);
            stat_gen(C_STAT_ADDR_GEN_READ_BLOCK)          <= Stat_Get_Register(stat_arb_gen_rd_blocked,   num_idx);
            stat_gen(C_STAT_ADDR_GEN_WRITE_HIT)           <= Stat_Get_Register(stat_gen_write_hit,        num_idx);
            stat_gen(C_STAT_ADDR_GEN_WRITE_MISS)          <= Stat_Get_Register(stat_gen_write_miss,       num_idx);
            stat_gen(C_STAT_ADDR_GEN_WRITE_MISS_DIRTY)    <= Stat_Get_Register(stat_gen_write_miss_dirty, num_idx);
            stat_gen(C_STAT_ADDR_GEN_READ_HIT)            <= Stat_Get_Register(stat_gen_read_hit,         num_idx);
            stat_gen(C_STAT_ADDR_GEN_READ_MISS)           <= Stat_Get_Register(stat_gen_read_miss,        num_idx);
            stat_gen(C_STAT_ADDR_GEN_READ_MISS_DIRTY)     <= Stat_Get_Register(stat_gen_read_miss_dirty,  num_idx);
            stat_gen(C_STAT_ADDR_GEN_LOCKED_WRITE_HIT)    <= Stat_Get_Register(stat_gen_locked_write_hit, num_idx);
            stat_gen(C_STAT_ADDR_GEN_LOCKED_READ_HIT)     <= Stat_Get_Register(stat_gen_locked_read_hit,  num_idx);
            stat_gen(C_STAT_ADDR_GEN_FIRST_WRITE_HIT)     <= Stat_Get_Register(stat_gen_first_write_hit,  num_idx);
            stat_gen(C_STAT_ADDR_GEN_RD_LATENCY)          <= Stat_Get_Register(stat_gen_rd_latency,       num_idx);
            stat_gen(C_STAT_ADDR_GEN_WR_LATENCY)          <= Stat_Get_Register(stat_gen_wr_latency,       num_idx);
            stat_gen(C_STAT_ADDR_GEN_RD_LAT_CONF)         <= Stat_Get_Register(stat_gen_rd_latency_conf,  num_idx);
            stat_gen(C_STAT_ADDR_GEN_WR_LAT_CONF)         <= Stat_Get_Register(stat_gen_wr_latency_conf,  num_idx);
          end if;
          
          -- Arbiter (Clk 2).
          stat_arbiter                                  <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_ARB_CATEGORY) = '1' ) then
            stat_arbiter(C_STAT_ADDR_ARB_VALID)           <= Stat_Point_Get_Register(stat_arb_valid,               sub_idx);
            stat_arbiter(C_STAT_ADDR_ARB_CON_ACCESS)      <= Stat_Point_Get_Register(stat_arb_concurrent_accesses, sub_idx);
          end if;
          
          -- Access (Clk 2).
          stat_access                                   <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_ACS_CATEGORY) = '1' ) then
            stat_access(C_STAT_ADDR_ACS_VALID)            <= Stat_Point_Get_Register(stat_access_valid,       sub_idx);
            stat_access(C_STAT_ADDR_ACS_STALL)            <= Stat_Point_Get_Register(stat_access_stall,       sub_idx);
            stat_access(C_STAT_ADDR_ACS_FETCH_STALL)      <= Stat_Point_Get_Register(stat_access_fetch_stall, sub_idx);
            stat_access(C_STAT_ADDR_ACS_REQ_STALL)        <= Stat_Point_Get_Register(stat_access_req_stall,   sub_idx);
            stat_access(C_STAT_ADDR_ACS_ACT_STALL)        <= Stat_Point_Get_Register(stat_access_act_stall,   sub_idx);
          end if;
          
          -- Lookup (Clk 2).
          stat_lookup                                   <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_LU_CATEGORY) = '1' ) then
            stat_lookup(C_STAT_ADDR_LU_STALL)             <= Stat_Point_Get_Register(stat_lu_stall,             sub_idx);
            stat_lookup(C_STAT_ADDR_LU_FETCH_STALL)       <= Stat_Point_Get_Register(stat_lu_fetch_stall,       sub_idx);
            stat_lookup(C_STAT_ADDR_LU_MEM_STALL)         <= Stat_Point_Get_Register(stat_lu_mem_stall,         sub_idx);
            stat_lookup(C_STAT_ADDR_LU_DATA_STALL)        <= Stat_Point_Get_Register(stat_lu_data_stall,        sub_idx);
            stat_lookup(C_STAT_ADDR_LU_DATA_HIT_STALL)    <= Stat_Point_Get_Register(stat_lu_data_hit_stall,    sub_idx);
            stat_lookup(C_STAT_ADDR_LU_DATA_MISS_STALL)   <= Stat_Point_Get_Register(stat_lu_data_miss_stall,   sub_idx);
          end if;
          
          -- Update (Clk 2).
          stat_update                                   <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_UD_CATEGORY) = '1' ) then
            stat_update(C_STAT_ADDR_UD_STALL)             <= Stat_Point_Get_Register(stat_ud_stall,     sub_idx);
            stat_update(C_STAT_ADDR_UD_TAG_FREE)          <= Stat_Point_Get_Register(stat_ud_tag_free,  sub_idx);
            stat_update(C_STAT_ADDR_UD_DATA_FREE)         <= Stat_Point_Get_Register(stat_ud_data_free, sub_idx);
            stat_update(C_STAT_ADDR_UD_RI)                <= Stat_FIFO_Get_Register(stat_ud_ri,         sub_idx);
            stat_update(C_STAT_ADDR_UD_R)                 <= Stat_FIFO_Get_Register(stat_ud_r,          sub_idx);
            stat_update(C_STAT_ADDR_UD_E)                 <= Stat_FIFO_Get_Register(stat_ud_e,          sub_idx);
            stat_update(C_STAT_ADDR_UD_BS)                <= Stat_FIFO_Get_Register(stat_ud_bs,         sub_idx);
            stat_update(C_STAT_ADDR_UD_WM)                <= Stat_FIFO_Get_Register(stat_ud_wm,         sub_idx);
            stat_update(C_STAT_ADDR_UD_WMA)               <= Stat_FIFO_Get_Register(stat_ud_wma,        sub_idx);
          end if;
          
          -- Backend (Clk 2).
          stat_backend                                  <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS_MASK(C_STAT_ADDR_BE_CATEGORY) = '1' ) then
            stat_backend(C_STAT_ADDR_BE_AW)               <= Stat_FIFO_Get_Register(stat_be_aw,                 sub_idx);
            stat_backend(C_STAT_ADDR_BE_W)                <= Stat_FIFO_Get_Register(stat_be_w,                  sub_idx);
            stat_backend(C_STAT_ADDR_BE_AR)               <= Stat_FIFO_Get_Register(stat_be_ar,                 sub_idx);
            stat_backend(C_STAT_ADDR_BE_AR_SEARCH_DEPTH)  <= Stat_Point_Get_Register(stat_be_ar_search_depth,   sub_idx);
            stat_backend(C_STAT_ADDR_BE_AR_STALL)         <= Stat_Point_Get_Register(stat_be_ar_stall,          sub_idx);
            stat_backend(C_STAT_ADDR_BE_AR_PROTECT_STALL) <= Stat_Point_Get_Register(stat_be_ar_protect_stall,  sub_idx);
            stat_backend(C_STAT_ADDR_BE_RD_LATENCY)       <= Stat_Point_Get_Register(stat_be_rd_latency,        sub_idx);
            stat_backend(C_STAT_ADDR_BE_WR_LATENCY)       <= Stat_Point_Get_Register(stat_be_wr_latency,        sub_idx);
            stat_backend(C_STAT_ADDR_BE_RD_LAT_CONF)      <= Stat_Conf_Get_Register(stat_be_rd_latency_conf_i);
            stat_backend(C_STAT_ADDR_BE_WR_LAT_CONF)      <= Stat_Conf_Get_Register(stat_be_wr_latency_conf_i);
          end if;
          
          -- Control (Clk 2).
          stat_ctrl                                     <= (others=>(others=>'0'));
          if( C_ENABLE_STATISTICS > 0 ) then
            stat_ctrl(C_STAT_ADDR_CTRL_ENABLE)            <= Stat_Conf_Get_Register(stat_ctrl_conf_i);
          end if;
          if( C_ENABLE_VERSION_REGISTER > 0 ) then
            stat_ctrl(C_STAT_ADDR_CTRL0_VERSION)          <= Stat_Conf_Get_Register(stat_ctrl_version_register_0);
          end if;
          if( C_ENABLE_VERSION_REGISTER > 1 ) then
            stat_ctrl(C_STAT_ADDR_CTRL1_VERSION)          <= Stat_Conf_Get_Register(stat_ctrl_version_register_1);
          end if;
          
          
          -- Stat per source (Clk 3).
          stat_result                                   <= (others=>(others=>'0'));
          stat_result(C_STAT_ADDR_OPT_CATEGORY)         <= Stat_Get_Register(stat_opt,      info_idx);
          stat_result(C_STAT_ADDR_GEN_CATEGORY)         <= Stat_Get_Register(stat_gen,      info_idx);
          stat_result(C_STAT_ADDR_ARB_CATEGORY)         <= Stat_Get_Register(stat_arbiter,  info_idx);
          stat_result(C_STAT_ADDR_ACS_CATEGORY)         <= Stat_Get_Register(stat_access,   info_idx);
          stat_result(C_STAT_ADDR_LU_CATEGORY)          <= Stat_Get_Register(stat_lookup,   info_idx);
          stat_result(C_STAT_ADDR_UD_CATEGORY)          <= Stat_Get_Register(stat_update,   info_idx);
          stat_result(C_STAT_ADDR_BE_CATEGORY)          <= Stat_Get_Register(stat_backend,  info_idx);
          stat_result(C_STAT_ADDR_CTRL_CATEGORY)        <= Stat_Get_Register(stat_ctrl,     cfg_idx);
          
          -- Last stage (Clk 4).
          if( C_S_AXI_CTRL_DATA_WIDTH > 32 ) then
            S_AXI_CTRL_RDATA_I                            <= Stat_Get_Register_64bit(stat_result, cat_idx);
          else
            S_AXI_CTRL_RDATA_I                            <= Stat_Get_Register_32bit(stat_result, cat_idx, word_idx);
          end if;
          
        end if;
      end if;
    end process Read_Mux;
    
  end generate Use_Ctrl;
  
  No_Ctrl: if ( C_ENABLE_CTRL < 1 ) generate
  begin
    S_AXI_CTRL_AWREADY              <= '0';
    S_AXI_CTRL_WREADY               <= '0';
    S_AXI_CTRL_BRESP                <= (others=>'0');
    S_AXI_CTRL_BVALID_I             <= '0';
    S_AXI_CTRL_ARREADY              <= '0';
    S_AXI_CTRL_RDATA_I              <= (others=>'0');
    S_AXI_CTRL_RRESP                <= (others=>'0');
    S_AXI_CTRL_RVALID_I             <= '0';
    
    stat_enable                     <= '0';
    stat_reset                      <= '0';
    
    write_ongoing                   <= '0';
    write_1st_cycle                 <= '0';
    write_2nd_cycle                 <= '0';
    w_data                          <= (others=>'0');
    
    read_ongoing                    <= '0';
    read_ongoing_d1                 <= '0';
    read_ongoing_d2                 <= '0';
    read_ongoing_d3                 <= '0';
    read_ongoing_d4                 <= '0';
  
    Using_Opt: if ( C_NUM_OPTIMIZED_PORTS > 0 ) generate
    begin
    stat_s_axi_rd_latency_conf      <= (C_NUM_OPTIMIZED_PORTS - 1 downto 0=>(C_STAT_CONF_POS=>'0'));
    stat_s_axi_wr_latency_conf      <= (C_NUM_OPTIMIZED_PORTS - 1 downto 0=>(C_STAT_CONF_POS=>'0'));
    end generate Using_Opt;
    Using_Gen: if ( C_NUM_GENERIC_PORTS > 0 ) generate
    begin
    stat_s_axi_gen_rd_latency_conf  <= (C_NUM_GENERIC_PORTS - 1 downto 0=>(C_STAT_CONF_POS=>'0'));
    stat_s_axi_gen_wr_latency_conf  <= (C_NUM_GENERIC_PORTS - 1 downto 0=>(C_STAT_CONF_POS=>'0'));
    end generate Using_Gen;
    stat_be_rd_latency_conf         <= (C_STAT_CONF_POS=>'0');
    stat_be_wr_latency_conf         <= (C_STAT_CONF_POS=>'0');
    
  end generate No_Ctrl;
  
  S_AXI_CTRL_RVALID <= S_AXI_CTRL_RVALID_I;
  S_AXI_CTRL_RDATA  <= S_AXI_CTRL_RDATA_I;
  
  S_AXI_CTRL_BVALID <= S_AXI_CTRL_BVALID_I;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_CNT     : natural := min_of(20, C_ADDR_ALL_SETS_HI - C_ADDR_ALL_SETS_LO + 1);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          IF_DEBUG                  <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG                  <= (others=>'0');
          
          IF_DEBUG( 31 downto   0)  <= fit_vec(S_AXI_CTRL_ARADDR,  32);
          IF_DEBUG( 63 downto  32)  <= fit_vec(S_AXI_CTRL_RDATA_I, 32);
          IF_DEBUG( 95 downto  64)  <= fit_vec(S_AXI_CTRL_AWADDR,  32);
          IF_DEBUG(127 downto  96)  <= fit_vec(S_AXI_CTRL_WDATA,   32);
          
          IF_DEBUG(159 downto 128)  <= ctrl_access_i.Addr(32 - 1 downto 0);
          IF_DEBUG(167 downto 160)  <= ctrl_access_i.Len;
          IF_DEBUG(171 downto 168)  <= ctrl_access_i.Snoop;
          IF_DEBUG(173 downto 172)  <= ctrl_access_i.Barrier;
          IF_DEBUG(175 downto 174)  <= ctrl_access_i.Domain;
          IF_DEBUG(178 downto 176)  <= ctrl_access_i.Prot;
          IF_DEBUG(181 downto 179)  <= ctrl_access_i.Size;
          IF_DEBUG(           182)  <= ctrl_access_i.Valid;
          IF_DEBUG(           183)  <= ctrl_access_i.Kind;
          IF_DEBUG(           184)  <= ctrl_access_i.Exclusive;
          IF_DEBUG(           185)  <= ctrl_access_i.Allocate;
          IF_DEBUG(           186)  <= ctrl_access_i.Bufferable;
          IF_DEBUG(           187)  <= ctrl_access_i.Evict;
          IF_DEBUG(           188)  <= ctrl_access_i.Ignore_Data;
          IF_DEBUG(           189)  <= ctrl_access_i.Force_Hit;
          
          IF_DEBUG(           190)  <= S_AXI_CTRL_AWVALID;
          IF_DEBUG(           191)  <= write_1st_cycle; -- S_AXI_CTRL_AWREADY
          IF_DEBUG(           192)  <= S_AXI_CTRL_WVALID;
          IF_DEBUG(           193)  <= write_1st_cycle; -- S_AXI_CTRL_WREADY
          IF_DEBUG(           194)  <= S_AXI_CTRL_BVALID_I;
          IF_DEBUG(           195)  <= S_AXI_CTRL_BREADY;
          IF_DEBUG(           196)  <= S_AXI_CTRL_ARVALID;
          IF_DEBUG(           197)  <= not read_ongoing; -- S_AXI_CTRL_ARREADY
          IF_DEBUG(           198)  <= S_AXI_CTRL_RVALID_I;
          IF_DEBUG(           199)  <= S_AXI_CTRL_RREADY;

          IF_DEBUG(           200)  <= ctrl_init_done_i;
          IF_DEBUG(           201)  <= ctrl_ready;
          
          IF_DEBUG(           202)  <= write_ongoing;
          IF_DEBUG(           203)  <= write_1st_cycle;
          IF_DEBUG(           204)  <= write_2nd_cycle;
          
          IF_DEBUG(           205)  <= read_ongoing;
          IF_DEBUG(           206)  <= read_ongoing_d1;
          IF_DEBUG(           207)  <= read_ongoing_d2;
          IF_DEBUG(           208)  <= read_ongoing_d3;
          IF_DEBUG(           209)  <= read_ongoing_d4;

          IF_DEBUG(           210)  <= ac_valid;
          IF_DEBUG(           211)  <= ac_push;
          IF_DEBUG(           212)  <= ac_pop;
          IF_DEBUG(           213)  <= ac_fifo_empty;
          
          IF_DEBUG(           214)  <= stat_reset_i;

          IF_DEBUG(220 + C_MY_CNT - 1 downto 220)  <= ctrl_init_cnt(C_ADDR_ALL_SETS_LO + C_MY_CNT - 1 downto C_ADDR_ALL_SETS_LO);
                        
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
    
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  
  -- Clocked to remove glites in simulation
  Delay_Assertions : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      assert_err_1  <= assert_err;
    end if;
  end process Delay_Assertions;
  
  
end architecture IMP;


