-------------------------------------------------------------------------------
-- sc_s_axi_r_channel.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_r_channel.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_r_channel.vhd
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

entity sc_s_axi_r_channel is
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
    C_DSID_WIDTH              : natural range  0 to   32      := 16;
    
    -- AXI4 Interface Specific.
    C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_S_AXI_ID_WIDTH          : natural                       :=  4;
    C_S_AXI_RESP_WIDTH        : natural                       :=  2;
    
    -- Configuration.
    C_SUPPORT_SUBSIZED        : boolean                       := false;
    C_LEN_WIDTH               : natural range  0 to    8      :=  2;
    C_REST_WIDTH              : natural range  0 to    7      :=  2;
    
    -- Data type and settings specific.
    C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
    C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
    C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
    C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
    
    -- Lx Cache Specific.
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
    
    -- System Cache Specific.
    C_PIPELINE_LU_READ_DATA   : boolean                       := false;
    C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_ENABLE_HAZARD_HANDLING  : natural range  0 to    1      :=  0;
    C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- AXI4/ACE Slave Interface Signals.
    
    -- R-Channel
    S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
    S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    S_AXI_RRESP               : out std_logic_vector(C_S_AXI_RESP_WIDTH - 1 downto 0);
    S_AXI_RLAST               : out std_logic;
    S_AXI_RVALID              : out std_logic;
    S_AXI_RREADY              : in  std_logic;
    S_AXI_RACK                : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Read Information Interface Signals.
    
    read_req_valid            : in  std_logic;
    read_req_ID               : in  std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
    read_req_last             : in  std_logic;
    read_req_failed           : in  std_logic;
    read_req_single           : in  std_logic;
    read_req_dvm              : in  std_logic;
    read_req_addr             : in  std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    read_req_DSid             : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    read_req_rest             : in  std_logic_vector(C_REST_WIDTH - 1 downto 0);
    read_req_offset           : in  std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_stp              : in  std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_use              : in  std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
    read_req_len              : in  std_logic_vector(C_LEN_WIDTH - 1  downto 0);
    read_req_ready            : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read request).
    
    rd_port_ready             : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read request).
    
    lookup_read_data_new      : in  std_logic;
    lookup_read_data_hit      : in  std_logic;
    lookup_read_data_snoop    : in  std_logic;
    lookup_read_data_allocate : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Hazard).
    
    snoop_req_piperun         : in  std_logic;
    snoop_act_set_read_hazard : in  std_logic;
    snoop_act_rst_read_hazard : in  std_logic;
    snoop_act_read_hazard     : in  std_logic;
    snoop_act_kill_locked     : in  std_logic;
    snoop_act_kill_addr       : in  std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    
    read_data_fetch_addr      : in  std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    read_data_req_addr        : in  std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    read_data_act_addr        : in  std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    
    read_data_fetch_match     : out std_logic;
    read_data_req_match       : out std_logic;
    read_data_ongoing         : out std_logic;
    read_data_block_nested    : out std_logic;
    read_data_release_block   : out std_logic;
    read_data_fetch_line_match: out std_logic;
    read_data_req_line_match  : out std_logic;
    read_data_act_line_match  : out std_logic;
    
    read_data_fud_we          : out std_logic;
    read_data_fud_addr        : out std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    read_data_fud_tag_valid   : out std_logic;
    read_data_fud_tag_unique  : out std_logic;
    read_data_fud_tag_dirty   : out std_logic;
    
    read_data_ex_rack         : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read Data).
    
    read_info_almost_full     : out std_logic;
    read_info_full            : out std_logic;
    read_data_hit_pop         : out std_logic;
    read_data_hit_almost_full : out std_logic;
    read_data_hit_full        : out std_logic;
    read_data_hit_fit         : out std_logic;
    read_data_miss_full       : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Snoop signals (Read Data & response).
    
    snoop_read_data_valid     : in  std_logic;
    snoop_read_data_last      : in  std_logic;
    snoop_read_data_resp      : in  AXI_RRESP_TYPE;
    snoop_read_data_word      : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    snoop_read_data_ready     : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Lookup signals (Read Data).
    
    lookup_read_data_valid    : in  std_logic;
    lookup_read_data_last     : in  std_logic;
    lookup_read_data_resp     : in  AXI_RRESP_TYPE;
    lookup_read_data_set      : in  natural range 0 to C_NUM_PARALLEL_SETS - 1;
    lookup_read_data_word     : in  std_logic_vector(C_NUM_PARALLEL_SETS * C_CACHE_DATA_WIDTH - 1 downto 0);
    lookup_read_data_ready    : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Update signals (Read Data).
    
    update_read_data_valid    : in  std_logic;
    update_read_data_last     : in  std_logic;
    update_read_data_resp     : in  AXI_RRESP_TYPE;
    update_read_data_word     : in  std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    update_read_data_ready    : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    stat_s_axi_rip            : out STAT_FIFO_TYPE;
    stat_s_axi_r              : out STAT_FIFO_TYPE;
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_r_channel;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_r_channel is

  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_COLLIDING_DATA            : natural :=  0;
  constant C_ASSERT_RIP_QUEUE_ERROR           : natural :=  1;
  constant C_ASSERT_RI_QUEUE_ERROR            : natural :=  2;
  constant C_ASSERT_NO_RIP_INFO               : natural :=  3;
  constant C_ASSERT_NO_RI_INFO                : natural :=  4;
  constant C_ASSERT_RON_QUEUE_ERROR           : natural :=  5;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  6;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_MAX_PENDING_RACK         : natural             := 4;
    
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  -- Types for AXI and port related signals (use S0 as reference, all has to be equal).
  constant C_RRESP_WIDTH              : integer             := C_S_AXI_RESP_WIDTH;
  
  subtype ID_TYPE                     is std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
  subtype RRESP_TYPE                  is std_logic_vector(C_RRESP_WIDTH - 1 downto 0);
  subtype CACHE_DATA_TYPE             is std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
  subtype DATA_TYPE                   is std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------

  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  -- Subtypes of the address from all points of view.
  
  -- Address related.
  subtype C_Lx_ADDR_DIRECT_POS        is natural range C_Lx_ADDR_DIRECT_HI  downto C_Lx_ADDR_DIRECT_LO;
  subtype C_Lx_ADDR_LINE_POS          is natural range C_Lx_ADDR_LINE_HI          downto C_Lx_ADDR_LINE_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  
  -- Subtypes for address parts.
  subtype Lx_ADDR_DIRECT_TYPE         is std_logic_vector(C_Lx_ADDR_DIRECT_POS);
  subtype Lx_ADDR_LINE_TYPE           is std_logic_vector(C_Lx_ADDR_LINE_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  -- Set related.
  subtype C_PARALLEL_SET_POS          is natural range C_NUM_PARALLEL_SETS - 1 downto 0;
  
  subtype PARALLEL_SET_TYPE           is std_logic_vector(C_PARALLEL_SET_POS);
  
  type PARALLEL_CACHE_DATA_TYPE       is array(C_PARALLEL_SET_POS) of CACHE_DATA_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  -- Types for Queue Length.
  constant C_DATA_QUEUE_LINE_LENGTH   : integer := ( 32 * C_Lx_CACHE_LINE_LENGTH / C_CACHE_DATA_WIDTH );
  constant C_DATA_QUEUE_LENGTH        : integer := max_of(16, 2 * C_DATA_QUEUE_LINE_LENGTH);
  constant C_DATA_QUEUE_LENGTH_BITS   : integer := log2(C_DATA_QUEUE_LENGTH);

  constant C_LINE_LENGTH              : integer := max_of(1, C_DATA_QUEUE_LINE_LENGTH / 4);
  
  subtype RON_ADDR_POS                is natural range C_MAX_PENDING_RACK - 1 downto 0;
  subtype RON_ADDR_TYPE               is std_logic_vector(Log2(C_MAX_PENDING_RACK) - 1 downto 0);
  
  subtype DATA_QUEUE_ADDR_POS         is natural range C_DATA_QUEUE_LENGTH - 1 downto 0;
  subtype DATA_QUEUE_ADDR_TYPE        is std_logic_vector(C_DATA_QUEUE_LENGTH_BITS - 1 downto 0);
  
  constant C_HIT_QUEUE_LENGTH         : integer := ( 3 - C_ENABLE_COHERENCY ) * C_DATA_QUEUE_LENGTH / 4;
  constant C_HIT_QUEUE_LENGTH_BITS    : integer := log2(C_HIT_QUEUE_LENGTH + C_ENABLE_COHERENCY);
  subtype HIT_QUEUE_ADDR_POS          is natural range C_HIT_QUEUE_LENGTH - 1 downto 0;
  subtype HIT_QUEUE_ADDR_TYPE         is std_logic_vector(C_HIT_QUEUE_LENGTH_BITS - 1 downto 0);
  
  constant C_SNOOP_QUEUE_LENGTH       : integer := 1 * C_DATA_QUEUE_LENGTH / 4;
  constant C_SNOOP_QUEUE_LENGTH_BITS  : integer := log2(C_SNOOP_QUEUE_LENGTH);
  subtype SNOOP_QUEUE_ADDR_POS        is natural range C_SNOOP_QUEUE_LENGTH - 1 downto 0;
  subtype SNOOP_QUEUE_ADDR_TYPE       is std_logic_vector(C_SNOOP_QUEUE_LENGTH_BITS - 1 downto 0);
  
  constant C_MISS_QUEUE_LENGTH        : integer := 1 * C_DATA_QUEUE_LENGTH / 4;
  constant C_MISS_QUEUE_LENGTH_BITS   : integer := log2(C_MISS_QUEUE_LENGTH);
  subtype MISS_QUEUE_ADDR_POS         is natural range C_MISS_QUEUE_LENGTH - 1 downto 0;
  subtype MISS_QUEUE_ADDR_TYPE        is std_logic_vector(C_MISS_QUEUE_LENGTH_BITS - 1 downto 0);
  
  -- Levels for Hit counters.
  constant C_HIT_QUEUE_EMPTY          : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(0,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_HIT_QUEUE_ALMOST_EMPTY   : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(2,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_HIT_QUEUE_ALMOST_FULL    : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_HIT_QUEUE_LENGTH - 3,                  C_DATA_QUEUE_LENGTH_BITS));
  constant C_HIT_QUEUE_LINE_LEVEL_UP  : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_HIT_QUEUE_LENGTH - C_LINE_LENGTH - 2,  C_DATA_QUEUE_LENGTH_BITS));
  constant C_HIT_QUEUE_LINE_LEVEL_DN  : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_HIT_QUEUE_LENGTH - C_LINE_LENGTH + 1,  C_DATA_QUEUE_LENGTH_BITS));
  constant C_HIT_WRAP_LEVEL           : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_HIT_QUEUE_LENGTH - 1,                  C_DATA_QUEUE_LENGTH_BITS));
  
  -- Levels for Snoop counters.
  constant C_SNOOP_QUEUE_EMPTY         : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(0,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_SNOOP_QUEUE_ALMOST_EMPTY  : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(2,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_SNOOP_QUEUE_ALMOST_FULL   : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_SNOOP_QUEUE_LENGTH - 3,                C_DATA_QUEUE_LENGTH_BITS));
  constant C_SNOOP_QUEUE_LINE_LEVEL_UP : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_SNOOP_QUEUE_LENGTH - C_LINE_LENGTH - 2,C_DATA_QUEUE_LENGTH_BITS));
  constant C_SNOOP_QUEUE_LINE_LEVEL_DN : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_SNOOP_QUEUE_LENGTH - C_LINE_LENGTH + 1,C_DATA_QUEUE_LENGTH_BITS));
  constant C_SNOOP_WRAP_LEVEL          : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - C_MISS_QUEUE_LENGTH - 1,
                                                                                            C_DATA_QUEUE_LENGTH_BITS));
  
  -- Levels for Miss counters.
  constant C_MISS_QUEUE_EMPTY         : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(0,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_MISS_QUEUE_ALMOST_EMPTY  : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(2,                                       C_DATA_QUEUE_LENGTH_BITS));
  constant C_MISS_QUEUE_ALMOST_FULL   : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_MISS_QUEUE_LENGTH - 3,                 C_DATA_QUEUE_LENGTH_BITS));
  constant C_MISS_QUEUE_LINE_LEVEL_UP : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_MISS_QUEUE_LENGTH - C_LINE_LENGTH - 2, C_DATA_QUEUE_LENGTH_BITS));
  constant C_MISS_QUEUE_LINE_LEVEL_DN : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_MISS_QUEUE_LENGTH - C_LINE_LENGTH + 1, C_DATA_QUEUE_LENGTH_BITS));
  constant C_MISS_WRAP_LEVEL          : DATA_QUEUE_ADDR_TYPE := 
                      std_logic_vector(to_unsigned(C_DATA_QUEUE_LENGTH - 1,                 C_DATA_QUEUE_LENGTH_BITS));
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Interface ratio.
  constant C_RATIO                    : natural := C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH;
  
  -- Local length.
  subtype C_LEN_POS                   is natural range C_LEN_WIDTH - 1 downto 0;
  subtype LEN_TYPE                    is std_logic_vector(C_LEN_POS);
  
  -- Local rest.
  subtype C_REST_POS                  is natural range C_REST_WIDTH - 1 downto 0;
  subtype REST_TYPE                   is std_logic_vector(C_REST_POS);
  
  -- RI response data.
  type RI_TYPE is record
    Hit               : std_logic;
    Snoop             : std_logic;
    Allocate          : std_logic;
  end record RI_TYPE;
  
  -- RON response data.
  type RON_TYPE is record
    Exclusive         : std_logic;
  end record RON_TYPE;
  
  -- R response data.
  type R_TYPE is record
    Last              : std_logic;
    Data              : CACHE_DATA_TYPE;
    Resp              : RRESP_TYPE;
  end record R_TYPE;
  
  -- RIP response information.
  type RIP_TYPE is record
    ID                : ID_TYPE;
    Last              : std_logic;
    Single            : std_logic;
    Rest              : REST_TYPE;
    Offset            : ADDR_BYTE_TYPE;
    Stp_Bits          : ADDR_BYTE_TYPE;
    Use_Bits          : ADDR_BYTE_TYPE;
    Len               : LEN_TYPE;
    DVM               : std_logic;
    Addr              : Lx_ADDR_DIRECT_TYPE;
    DSid              : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  end record RIP_TYPE;
  
  -- RK data.
  type RK_TYPE is record
    Addr              : Lx_ADDR_LINE_TYPE;
  end record RK_TYPE;
  
  -- Empty data structures.
  constant C_NULL_RI                  : RI_TYPE  := (Hit=>'0', Snoop=>'0', Allocate=>'0');
  constant C_NULL_RON                 : RON_TYPE := (Exclusive=>'0');
  constant C_NULL_R                   : R_TYPE   := (Last=>'0', Data=>(others=>'0'), Resp=>(others=>'0'));
  constant C_NULL_RIP                 : RIP_TYPE := (ID=>(others=>'0'), Last=>'0', Single=>'0', Rest=>(others=>'0'), 
                                                     Offset=>(others=>'0'), Stp_Bits=>(others=>'0'), 
                                                     Use_Bits=>(others=>'0'), Len=>(others=>'0'), DSid=>(others=>'0'),
                                                     DVM=>'0', Addr=>(others=>'0'));
  constant C_NULL_RK                  : RK_TYPE  := (Addr=>(others=>'0'));
  
  -- Types for information queue storage.
  type RI_FIFO_MEM_TYPE           is array(QUEUE_ADDR_POS)      of RI_TYPE;
  type RON_FIFO_MEM_TYPE          is array(RON_ADDR_POS)        of RON_TYPE;
  type R_FIFO_MEM_TYPE            is array(DATA_QUEUE_ADDR_POS) of R_TYPE;
  type RL_FIFO_MEM_TYPE           is array(DATA_QUEUE_ADDR_POS) of std_logic;
  type RW_FIFO_MEM_TYPE           is array(DATA_QUEUE_ADDR_POS) of CACHE_DATA_TYPE;
  type RR_FIFO_MEM_TYPE           is array(DATA_QUEUE_ADDR_POS) of RRESP_TYPE;
  type RIP_FIFO_MEM_TYPE          is array(QUEUE_ADDR_POS)      of RIP_TYPE;
  type RK_FIFO_MEM_TYPE           is array(QUEUE_ADDR_POS)      of RK_TYPE;
  
  
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
  
  component carry_compare_const is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE;
      C_SIGNALS : natural := 1;
      C_SIZE   : natural;
      B_Vec    : std_logic_vector);
    port (
      A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_In  : in  std_logic;
      Carry_Out : out std_logic);
  end component carry_compare_const;
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Prepare Lookup Read data
  
  signal lookup_data_word           : PARALLEL_CACHE_DATA_TYPE;
  signal lookup_read_data_word_i    : CACHE_DATA_TYPE;
  
  
  -- ----------------------------------------
  -- Read Hit/Miss Queue Handling
  
  signal ri_push                  : std_logic;
  signal ri_pop                   : std_logic;
  signal ri_exist                 : std_logic;
  signal ri_empty                 : std_logic;
  signal ri_refresh_reg           : std_logic;
  signal ri_read_fifo_addr        : QUEUE_ADDR_TYPE:= (others=>'1');
  signal ri_fifo_mem              : RI_FIFO_MEM_TYPE; -- := (others=>C_NULL_RI);
  signal next_ri_hit              : std_logic;
  signal next_ri_snoop            : std_logic;
  signal next_ri_allocate         : std_logic;
  signal ri_hit                   : std_logic;
  signal ri_snoop                 : std_logic;
  signal ri_allocate              : std_logic;
  signal ri_assert                : std_logic;
  
  
  -- ----------------------------------------
  -- Read Queue Handling (Queue/Buffer)
  
  signal r_hit_push               : std_logic;
  signal r_snoop_push             : std_logic;
  signal r_miss_push              : std_logic;
  signal r_push_safe              : std_logic;
  signal r_push_safe_vec          : std_logic_vector(0 downto 0);
  signal r_info_exist             : std_logic;
  signal r_pop_valid              : std_logic;
  signal r_pop                    : std_logic;
  signal r_pop_snoop_not_empty    : std_logic;
  signal r_pop_miss_not_empty     : std_logic;
  signal r_hit_pop                : std_logic;
  signal r_snoop_pop              : std_logic;
  signal r_miss_pop               : std_logic;
  signal r_pop_sel_safe           : std_logic;
  signal r_pop_safe_i             : std_logic;
  signal r_pop_safe               : std_logic;
  signal r_hit_refresh            : std_logic;
  signal r_snoop_refresh          : std_logic;
  signal r_miss_refresh           : std_logic;
  signal r_fifo_mem               : R_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
  signal rl_fifo_mem              : RL_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
  signal rl_snoop_fifo_mem        : RL_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
  signal rw_fifo_mem              : RW_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
  signal rr_fifo_mem              : RR_FIFO_MEM_TYPE; -- := (others=>C_NULL_R);
  signal r_fifo_almost_full       : std_logic;
  signal r_fifo_full              : std_logic;
  signal r_fifo_true_empty        : std_logic;
  signal r_fifo_empty             : std_logic;
  signal r_assert                 : std_logic;
  signal r_hit_last               : std_logic;
  signal r_snoop_last             : std_logic;
  signal r_miss_last              : std_logic;
  signal r_last                   : std_logic;
  signal r_data                   : CACHE_DATA_TYPE;
  signal r_rresp                  : RRESP_TYPE;
  
  signal new_read_data_last       : std_logic;
  signal new_read_data_word       : CACHE_DATA_TYPE;
  signal new_read_data_resp       : RRESP_TYPE;
  
  attribute ram_style             : string;
  attribute ram_style             of r_fifo_mem         : signal is "distributed";
  attribute ram_style             of rl_fifo_mem        : signal is "distributed";
  attribute ram_style             of rl_snoop_fifo_mem  : signal is "distributed";
  attribute ram_style             of rw_fifo_mem        : signal is "distributed";
  attribute ram_style             of rr_fifo_mem        : signal is "distributed";
  
  
  -- ----------------------------------------
  -- Read Queue Hazard Handling
  
  signal rd_on_push                 : std_logic;
  signal rd_on_pop                  : std_logic;
  signal ron_almost_full            : std_logic;
  signal ron_full                   : std_logic;
  signal ron_almost_empty           : std_logic;
  signal ron_empty                  : std_logic;
  signal ron_read_fifo_addr         : RON_ADDR_TYPE;
  signal ron_fifo_mem               : RON_FIFO_MEM_TYPE; -- := (others=>C_NULL_RON);
  signal ron_exclusive              : std_logic;
  signal rd_active_push             : std_logic;
  signal rd_active_pop              : std_logic;
  signal read_data_cnt_ongoing      : rinteger range 0 to C_MAX_PENDING_RACK - 1; 
  signal read_data_any_running      : std_logic;
  signal read_data_started          : std_logic;
  signal read_data_possible_nested  : std_logic;
  signal set_max_concurrent         : std_logic;
  signal read_data_max_concurrent   : std_logic;
  signal read_data_release_block_i  : std_logic;
  signal ron_assert                 : std_logic;
  
  
  -- ----------------------------------------
  -- Read Queue Handling (Pointer & Flags)
  
  signal r_hit_write_fifo_addr    : HIT_QUEUE_ADDR_TYPE   := (others=>'0');
  signal r_snoop_write_fifo_addr  : SNOOP_QUEUE_ADDR_TYPE := (others=>'0');
  signal r_miss_write_fifo_addr   : MISS_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_write_fifo_addr        : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_hit_read_fifo_addr     : HIT_QUEUE_ADDR_TYPE   := (others=>'0');
  signal r_snoop_read_fifo_addr   : SNOOP_QUEUE_ADDR_TYPE := (others=>'0');
  signal r_miss_read_fifo_addr    : MISS_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_snoop_full_fifo_addr   : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_miss_full_fifo_addr    : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_read_fifo_addr         : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  
  signal r_hit_fifo_len           : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_snoop_fifo_len         : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  signal r_miss_fifo_len          : DATA_QUEUE_ADDR_TYPE  := (others=>'0');
  
  signal r_hit_almost_full_cmb    : std_logic;
  signal r_hit_almost_empty_cmb   : std_logic;
  signal r_hit_line_fit_up_cmb    : std_logic;
  signal r_hit_line_fit_dn_cmb    : std_logic;
  signal r_snoop_almost_full_cmb  : std_logic;
  signal r_snoop_almost_empty_cmb : std_logic;
  signal r_snoop_line_fit_up_cmb  : std_logic;
  signal r_snoop_line_fit_dn_cmb  : std_logic;
  signal r_miss_almost_full_cmb   : std_logic;
  signal r_miss_almost_empty_cmb  : std_logic;
  signal r_miss_line_fit_up_cmb   : std_logic;
  signal r_miss_line_fit_dn_cmb   : std_logic;
  
  signal r_hit_fifo_almost_full   : std_logic;
  signal r_hit_fifo_full          : std_logic;
  signal r_hit_fifo_almost_empty  : std_logic;
  signal r_hit_fifo_empty         : std_logic;
  signal r_hit_line_fit           : std_logic;
  signal r_snoop_fifo_almost_full : std_logic;
  signal r_snoop_fifo_full        : std_logic;
  signal r_snoop_fifo_almost_empty: std_logic;
  signal r_snoop_fifo_empty       : std_logic;
  signal r_snoop_line_fit         : std_logic;
  signal r_miss_fifo_almost_full  : std_logic;
  signal r_miss_fifo_full         : std_logic;
  signal r_miss_fifo_almost_empty : std_logic;
  signal r_miss_fifo_empty        : std_logic;
  signal r_miss_line_fit          : std_logic;
  
  
  -- ----------------------------------------
  -- Read Information Queue Handling
  
  signal rip_push                 : std_logic;
  signal rip_push_safe            : std_logic;
  signal rip_pop                  : std_logic;
  signal rip_refresh_reg          : std_logic;
  signal rip_read_fifo_addr       : QUEUE_ADDR_TYPE:= (others=>'1');
  signal rip_fifo_mem             : RIP_FIFO_MEM_TYPE; -- := (others=>C_NULL_RIP);
  signal rip_fifo_almost_full     : std_logic;
  signal rip_fifo_full            : std_logic;
  signal rip_exist                : std_logic;
  signal rip_id                   : ID_TYPE;
  signal rip_last                 : std_logic;
  signal rip_offset               : ADDR_BYTE_TYPE;
  signal rip_stp                  : ADDR_BYTE_TYPE;
  signal rip_use                  : ADDR_BYTE_TYPE;
  signal rip_single               : std_logic;
  signal rip_dvm                  : std_logic;
  signal rip_addr                 : Lx_ADDR_DIRECT_TYPE;
  signal rip_DSid                 : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  signal rip_assert               : std_logic;
  
  
  -- ----------------------------------------
  -- Read Port Handling
  
  signal S_AXI_RLAST_I            : std_logic;
  signal S_AXI_RDATA_I            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal rd_pop                   : std_logic;
  signal rd_done                  : std_logic;
  
  
  -- ----------------------------------------
  -- 
  
  signal rk_empty                 : std_logic;
  signal read_data_fetch_line_match_i : std_logic;
  signal read_data_req_line_match_i   : std_logic;
  signal read_data_act_line_match_i   : std_logic;
  signal read_data_fud_is_dead    : std_logic;
  
    
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Prepare Lookup Read data
  -----------------------------------------------------------------------------
  
  -- Split to local array.
  Gen_Parallel_Data_Array: for I in 0 to C_NUM_PARALLEL_SETS - 1 generate
  begin
    lookup_data_word(I) <= lookup_read_data_word((I+1) * C_CACHE_DATA_WIDTH - 1 downto I * C_CACHE_DATA_WIDTH);
    
  end generate Gen_Parallel_Data_Array;
  
  -- Non-pipelined read data has to be MUXed.
  No_Rd_Pipeline: if( not C_PIPELINE_LU_READ_DATA ) generate
  begin
    lookup_read_data_word_i <= lookup_data_word(lookup_read_data_set);
    
  end generate No_Rd_Pipeline;
  
  -- Pipeline data can be ORed together, save resources and improves timing.
  Use_Rd_Pipeline: if( C_PIPELINE_LU_READ_DATA ) generate
  begin
    process(lookup_data_word) is
      variable lookup_read_data_word_ii : CACHE_DATA_TYPE;
    begin
      lookup_read_data_word_ii := (others=>'0');
      for I in 0 to C_NUM_PARALLEL_SETS - 1 loop
        lookup_read_data_word_ii := lookup_read_data_word_ii or lookup_data_word(I);
      end loop;
      
      lookup_read_data_word_i <= lookup_read_data_word_ii;
    end process;
    
  end generate Use_Rd_Pipeline;
  
  
  -----------------------------------------------------------------------------
  -- Read Hit/Miss Queue Handling
  -- 
  -- Push Hit/Miss information into queue to determine which portion that shall
  -- be use the next time.
  -- 
  -----------------------------------------------------------------------------
  
  -- Control signals for read info queue.
  ri_push         <= lookup_read_data_new;
  ri_pop          <= rip_pop;

  FIFO_RI_Pointer: sc_srl_fifo_counter
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
      C_USE_STATISTICS          => false,
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
      C_USE_REGISTER_OUTPUT     => C_PIPELINE_LU_READ_DATA,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => ri_push,
      queue_pop                 => ri_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => ri_refresh_reg,
      
      queue_almost_full         => read_info_almost_full,
      queue_full                => read_info_full,
      queue_almost_empty        => open,
      queue_empty               => ri_empty,
      queue_exist               => ri_exist,
      queue_line_fit            => open,
      queue_index               => ri_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => open,
      
      
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
      if ( ri_push = '1') then
        ri_fifo_mem(0).Hit      <= lookup_read_data_hit;
        ri_fifo_mem(0).Snoop    <= lookup_read_data_snoop;
        ri_fifo_mem(0).Allocate <= lookup_read_data_allocate;
        
        -- Shift FIFO contents.
        ri_fifo_mem(ri_fifo_mem'left downto 1) <= ri_fifo_mem(ri_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_RI_Memory;
  
  -- Get next transaction info.
  next_ri_hit       <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Hit;
  next_ri_snoop     <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Snoop;
  next_ri_allocate  <= ri_fifo_mem(to_integer(unsigned(ri_read_fifo_addr))).Allocate;
    
  -- Rename or pipeline signals.
  No_Rd_Ctrl_Pipeline: if( not C_PIPELINE_LU_READ_DATA ) generate
  begin
    ri_hit              <= next_ri_hit;
    ri_snoop            <= next_ri_snoop;
    ri_allocate         <= next_ri_allocate;
    
    -- Select current read address depending on what is available from RI Queue.
    r_read_fifo_addr      <=   r_hit_read_fifo_addr when ( ri_hit   = '1' ) else
                             r_snoop_full_fifo_addr when ( ri_snoop = '1' ) else
                              r_miss_full_fifo_addr;
    
  end generate No_Rd_Ctrl_Pipeline;
  Use_Rd_Ctrl_Pipeline: if( C_PIPELINE_LU_READ_DATA ) generate
    signal r_next_fifo_addr         : DATA_QUEUE_ADDR_TYPE:= (others=>'0');
  begin
    -- Store RI in register for good timing.
    RI_Data_Registers : process (ACLK) is
    begin  -- process RI_Data_Registers
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
          ri_hit      <= C_NULL_RI.Hit;
          ri_snoop    <= C_NULL_RI.Snoop;
          ri_allocate <= C_NULL_RI.Allocate;
          
        elsif( ri_refresh_reg = '1' ) then
          ri_hit      <= next_ri_hit;
          ri_snoop    <= next_ri_snoop;
          ri_allocate <= next_ri_allocate;
          
        end if;
      end if;
    end process RI_Data_Registers;
    
    -- Select current read address depending on what is available from RI Queue.
    RI_Addr_Registers : process (ACLK) is
    begin  -- process RI_Addr_Registers
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
          r_read_fifo_addr  <= (others=>'0');
        else
          if( ri_refresh_reg = '1' ) then
            if( next_ri_hit = '1' ) then
              if( r_pop_safe = '1' and ri_hit = '1' ) then
                r_read_fifo_addr  <= r_next_fifo_addr;
              else
                r_read_fifo_addr  <= r_hit_read_fifo_addr;
              end if;
            elsif( next_ri_snoop = '1' ) then
              if( r_pop_safe = '1' and ri_snoop = '1' ) then
                r_read_fifo_addr  <= r_next_fifo_addr;
              else
                r_read_fifo_addr  <= r_snoop_full_fifo_addr;
              end if;
            else
              if( r_pop_safe = '1' and ri_hit = '0' and ri_snoop = '0' ) then
                r_read_fifo_addr  <= r_next_fifo_addr;
              else
                r_read_fifo_addr  <= r_miss_full_fifo_addr;
              end if;
            end if;
          elsif( r_pop_safe = '1' ) then
            r_read_fifo_addr  <= r_next_fifo_addr;
          end if;
        end if;
      end if;
    end process RI_Addr_Registers;
    
    -- Generate next counter value.
    process(r_read_fifo_addr, ri_hit, ri_snoop) is
    begin
      if( ri_hit = '1' ) then
        if( r_read_fifo_addr = C_HIT_WRAP_LEVEL ) then
          r_next_fifo_addr  <= (others=>'0');
        else
          r_next_fifo_addr  <= std_logic_vector(unsigned(r_read_fifo_addr) + 1);
        end if;
      elsif( ri_snoop = '1' ) then
        if( r_read_fifo_addr = C_SNOOP_WRAP_LEVEL ) then
          r_next_fifo_addr  <= (others=>'0');
          r_next_fifo_addr(r_next_fifo_addr'left downto r_next_fifo_addr'left-1)  <= "10";
        else
          r_next_fifo_addr  <= std_logic_vector(unsigned(r_read_fifo_addr) + 1);
        end if;
      else
        if( r_read_fifo_addr = C_MISS_WRAP_LEVEL ) then
          r_next_fifo_addr  <= (others=>'0');
          r_next_fifo_addr(r_next_fifo_addr'left downto r_next_fifo_addr'left-1)  <= "11";
        else
          r_next_fifo_addr  <= std_logic_vector(unsigned(r_read_fifo_addr) + 1);
        end if;
      end if;
    end process;
    
    
  end generate Use_Rd_Ctrl_Pipeline;
  
  
  -----------------------------------------------------------------------------
  -- Read Queue Handling (Queue/Buffer)
  -- 
  -- Push read data into the queue/buffer together with all control information 
  -- needed.
  -- 
  -- There are two possible data sources for the read data:
  --  * Lookup (read hit)
  --  * Update (read miss)
  -----------------------------------------------------------------------------
  
  -- Control signals for read data buffer.
  Use_RTL_1: if( C_TARGET = RTL or C_ENABLE_COHERENCY /= 0 ) generate
  begin
    r_hit_push      <= lookup_read_data_valid and not   r_hit_fifo_full;
    r_miss_push     <= update_read_data_valid and not  r_miss_fifo_full and 
                       not   r_hit_push;
    r_snoop_push    <= snoop_read_data_valid  and not r_snoop_fifo_full and 
                       not   r_hit_push and 
                       not  r_miss_push;
    r_push_safe     <= r_hit_push or r_snoop_push or r_miss_push;
    
    r_hit_refresh   <=   r_hit_push xor   r_hit_pop;
    r_snoop_refresh <= r_snoop_push xor r_snoop_pop;
    r_miss_refresh  <=  r_miss_push xor  r_miss_pop;
    
  end generate Use_RTL_1;
  
  Use_FPGA_1: if( C_TARGET /= RTL and C_ENABLE_COHERENCY = 0  ) generate
  begin
    LUT_Hit_Inst: LUT6_2
      generic map(
        INIT => X"2222D22222222222"
      )
      port map(
        O5 => r_hit_push,                   -- [out std_logic]
        O6 => r_hit_refresh,                -- [out std_logic]
        I0 => lookup_read_data_valid,       -- [in  std_logic]
        I1 => r_hit_fifo_full,              -- [in  std_logic]
        I2 => r_pop,                        -- [in  std_logic]
        I3 => ri_hit,                       -- [in  std_logic]
        I4 => r_hit_fifo_empty,             -- [in  std_logic]
        I5 => '1'                           -- [in  std_logic]
      );
      
    LUT_Refresh_Inst: LUT6_2
      generic map(
        INIT => X"0D000D00F2FF0D00"
      )
      port map(
        O5 => open,                         -- [out std_logic]
        O6 => r_miss_refresh,               -- [out std_logic]
        I0 => lookup_read_data_valid,       -- [in  std_logic]
        I1 => r_hit_fifo_full,              -- [in  std_logic]
        I2 => r_miss_fifo_full,             -- [in  std_logic]
        I3 => update_read_data_valid,       -- [in  std_logic]
        I4 => r_pop_miss_not_empty,         -- [in  std_logic]
        I5 => ri_hit                        -- [in  std_logic]
      );
      
    LUT_Push_Inst: LUT6_2
      generic map(
        INIT => X"2F222F220D000D00"
      )
      port map(
        O5 => r_miss_push,                  -- [out std_logic]
        O6 => r_push_safe,                  -- [out std_logic]
        I0 => lookup_read_data_valid,       -- [in  std_logic]
        I1 => r_hit_fifo_full,              -- [in  std_logic]
        I2 => r_miss_fifo_full,             -- [in  std_logic]
        I3 => update_read_data_valid,       -- [in  std_logic]
        I4 => '0',                          -- [in  std_logic]
        I5 => '1'                           -- [in  std_logic]
      );
      
    -- Unused signals.
    r_snoop_push    <= '0';
    r_snoop_refresh <= '0';
    
  end generate Use_FPGA_1;
  
  r_push_safe_vec <= (others=>r_push_safe);
  
--  r_pop           <= ( S_AXI_RREADY and rd_done ) and ri_exist and rip_exist;
  r_info_exist  <= ri_exist and rip_exist and not snoop_act_read_hazard and not read_data_max_concurrent;
  RC_And_Inst3: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => rd_done,
      A         => r_info_exist,
      Carry_OUT => r_pop_valid
    );
  
  RC_And_Inst4: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => r_pop_valid,
      A         => S_AXI_RREADY,
      Carry_OUT => r_pop
    );
  
--  r_hit_pop       <= ( r_pop and     ri_hit                  ) and not   r_hit_fifo_empty;
--  r_snoop_pop     <= ( r_pop and                    ri_snoop ) and not r_snoop_fifo_empty;
--  r_miss_pop      <= ( r_pop and not ri_hit and not ri_snoop ) and not  r_miss_fifo_empty;
  r_snoop_pop     <= ( r_pop_snoop_not_empty and                    ri_snoop );
  r_miss_pop      <= ( r_pop_miss_not_empty  and not ri_hit and not ri_snoop );
--  r_pop_safe      <= r_hit_pop or r_snoop_pop or r_miss_pop;
  r_pop_sel_safe  <=   r_hit_fifo_empty when ( ri_hit   = '1' ) else 
                     r_snoop_fifo_empty when ( ri_snoop = '1' ) else 
                      r_miss_fifo_empty;
  RC_And_Inst5: carry_and_n
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => r_pop,
      A_N       => r_pop_sel_safe,
      Carry_OUT => r_pop_safe_i
    );
  
  r_pop_snoop_not_empty <= r_pop_safe;
  r_pop_miss_not_empty  <= r_pop_safe;
      
  RC_Latch_Inst1: carry_latch_and
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => r_pop_safe_i,
      A         => ri_hit,
      O         => r_hit_pop,
      Carry_OUT => r_pop_safe
    );
  
  
  -- Select current write address depending on what Queue levels and whats available.
  r_write_fifo_addr <=          r_hit_write_fifo_addr when ( r_hit_push   = '1' ) else
                       "10" & r_snoop_write_fifo_addr when ( r_snoop_push = '1' ) else
                       "11" &  r_miss_write_fifo_addr;
  
  -- Select data for R Channel FIFO.
  Sel_R_Data : process (r_hit_push, r_snoop_push, 
                        lookup_read_data_last, lookup_read_data_word_i, lookup_read_data_resp, 
                        snoop_read_data_last,  snoop_read_data_word,    snoop_read_data_resp,
                        update_read_data_last, update_read_data_word,   update_read_data_resp) is
  begin  -- process Sel_R_Data
    -- Insert new item.
    if( r_hit_push = '1' ) then
      new_read_data_last  <= lookup_read_data_last;
      new_read_data_word  <= lookup_read_data_word_i;
      new_read_data_resp  <= lookup_read_data_resp(C_RRESP_WIDTH - 1 downto 0);
      
    elsif( r_snoop_push = '1' ) then
      new_read_data_last  <= snoop_read_data_last;
      new_read_data_word  <= snoop_read_data_word;
      new_read_data_resp  <= snoop_read_data_resp(C_RRESP_WIDTH - 1 downto 0);
      
    else
      new_read_data_last  <= update_read_data_last;
      new_read_data_word  <= update_read_data_word;
      new_read_data_resp  <= update_read_data_resp(C_RRESP_WIDTH - 1 downto 0);
      
    end if;
  end process Sel_R_Data;
  
  -- Handle memory for R Channel FIFO.
  FIFO_R_Memory_Last : process (ACLK) is
  begin  -- process FIFO_R_Memory_Last
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( r_push_safe = '1') then
        -- Insert new item.
        rl_fifo_mem(to_integer(unsigned(r_write_fifo_addr)))  <= new_read_data_last;
      end if;
    end if;
  end process FIFO_R_Memory_Last;
  
  FIFO_R_Snoop_Memory_Last : process (ACLK) is
  begin  -- process FIFO_R_Snoop_Memory_Last
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( r_push_safe = '1') then
        -- Insert new item.
        rl_snoop_fifo_mem(to_integer(unsigned(r_write_fifo_addr)))  <= new_read_data_last;
      end if;
    end if;
  end process FIFO_R_Snoop_Memory_Last;
  
  FIFO_R_Memory_Word : process (ACLK) is
  begin  -- process FIFO_R_Memory_Word
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( r_push_safe = '1') then
        -- Insert new item.
        rw_fifo_mem(to_integer(unsigned(r_write_fifo_addr)))  <= new_read_data_word;
      end if;
    end if;
  end process FIFO_R_Memory_Word;
  
  FIFO_R_Memory_Resp : process (ACLK) is
  begin  -- process FIFO_R_Memory_Resp
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( r_push_safe = '1') then
        -- Insert new item.
        rr_fifo_mem(to_integer(unsigned(r_write_fifo_addr)))  <= new_read_data_resp;
      end if;
    end if;
  end process FIFO_R_Memory_Resp;
  
  -- Rename signals.
--  r_last                <= rl_fifo_mem(to_integer(unsigned(r_hit_read_fifo_addr)))    when ( ri_hit   = '1' ) else
--                           rl_fifo_mem(to_integer(unsigned(r_snoop_read_fifo_addr)))  when ( ri_snoop = '1' ) else
--                           rl_fifo_mem(to_integer(unsigned(r_miss_full_fifo_addr)));
  r_hit_last            <=       rl_fifo_mem(to_integer(unsigned(  r_hit_read_fifo_addr)));
  r_snoop_last          <= rl_snoop_fifo_mem(to_integer(unsigned(r_snoop_full_fifo_addr)));
  r_miss_last           <=       rl_fifo_mem(to_integer(unsigned( r_miss_full_fifo_addr)));
  r_last                <= r_hit_last   when ( ri_hit   = '1' ) else
                           r_snoop_last when ( ri_snoop = '1' ) else
                           r_miss_last;
  r_data                <= rw_fifo_mem(to_integer(unsigned(r_read_fifo_addr)));
  r_rresp               <= rr_fifo_mem(to_integer(unsigned(r_read_fifo_addr)));
    
  -- Determine if there are data in any one of the queues.
  -- For the coherent case will a snoop-data hazard force a virtually empty queue when there is a 
  -- risk for returning data in the forbidden window.
  r_fifo_true_empty     <= ( (     ri_hit                  and   r_hit_fifo_empty ) or 
                             (                    ri_snoop and r_snoop_fifo_empty ) or 
                             ( not ri_hit and not ri_snoop and  r_miss_fifo_empty ) ) or 
                           ( not ri_exist );
  r_fifo_empty          <= r_fifo_true_empty or snoop_act_read_hazard or read_data_max_concurrent;
  
  
  -----------------------------------------------------------------------------
  -- Read Queue Hazard Handling
  -- 
  -- Track read data flow:
  --  * Ongoing - Data is flowing, between first word and master ack
  --  * Active  - Data is flowing, between first word and last word
  -----------------------------------------------------------------------------
  
  
  rd_on_push      <= ( not r_fifo_empty) and S_AXI_RREADY and ( not read_data_started );
  rd_on_pop       <= S_AXI_RACK;
  
  rd_active_push  <= rd_on_push;
  rd_active_pop   <= ri_pop;
  
  No_Hazard_Handling: if(C_ENABLE_HAZARD_HANDLING = 0 ) generate
  begin
    read_data_cnt_ongoing       <= 0;
    read_data_any_running       <= '0';
    read_data_started           <= '0';
    read_data_possible_nested   <= '0';
    set_max_concurrent          <= '0';
    read_data_max_concurrent    <= '0';
    read_data_fetch_match       <= '0';
    read_data_req_match         <= '0';
    read_data_ongoing           <= '0';
    read_data_release_block_i   <= '0';
    read_data_block_nested      <= '0';
    read_data_req_line_match_i  <= '0';
    read_data_act_line_match_i  <= '0';
    read_data_fud_we            <= '0';
    read_data_fud_addr          <= (others=>'0');
    read_data_fud_tag_valid     <= '0';
    read_data_fud_tag_unique    <= '0';
    read_data_fud_tag_dirty     <= '0';
    read_data_fetch_line_match  <= '0';
    read_data_req_line_match    <= '0';
    read_data_act_line_match    <= '0';
    read_data_ex_rack           <= '0';
    
  end generate No_Hazard_Handling;
  
  Use_Hazard_Handling: if( C_ENABLE_HAZARD_HANDLING /= 0  ) generate
    
    signal rk_push                : std_logic;
    signal rk_pop                 : std_logic;
    signal rk_almost_full         : std_logic;
    signal rk_full                : std_logic;
    signal rk_read_fifo_addr      : QUEUE_ADDR_TYPE:= (others=>'1');
    signal rk_fifo_mem            : RK_FIFO_MEM_TYPE; -- := (others=>C_NULL_RK);
    signal rk_addr                : Lx_ADDR_LINE_TYPE;
    signal rk_assert              : std_logic;
    
  begin
    
    FIFO_RON_Pointer: sc_srl_fifo_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => false,
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
        C_QUEUE_ADDR_WIDTH        => Log2(C_MAX_PENDING_RACK),
        C_LINE_LENGTH             => 1
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- Queue Counter Interface
        
        queue_push                => rd_on_push,
        queue_pop                 => rd_on_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => ron_almost_full,
        queue_full                => ron_full,
        queue_almost_empty        => ron_almost_empty,
        queue_empty               => ron_empty,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => ron_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => open,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => ron_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Handle memory for RON Channel FIFO.
    FIFO_RON_Memory : process (ACLK) is
    begin  -- process FIFO_RON_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( rd_on_push = '1') then
          if( r_rresp = C_RRESP_EXOKAY(r_rresp'range) ) then
            ron_fifo_mem(0).Exclusive <= '1';
          else
            ron_fifo_mem(0).Exclusive <= '0';
          end if;
          
          -- Shift FIFO contents.
          ron_fifo_mem(ron_fifo_mem'left downto 1) <= ron_fifo_mem(ron_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_RON_Memory;
    
    -- Get current Exclusive status.
    ron_exclusive <= ron_fifo_mem(to_integer(unsigned(ron_read_fifo_addr))).Exclusive;
        
    Track_Ongoing : process (ACLK) is
    begin  -- process Track_Ongoing
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
--          read_data_cnt_ongoing     <= 0;
          read_data_any_running     <= '0';
          read_data_started         <= '0';
          read_data_possible_nested <= '0';
          read_data_max_concurrent  <= '0';
          
        else
--          -- Count ongoing read data transactions that have RACK pending.
--          if( rd_on_push = '1' and rd_on_pop = '0' ) then
--            read_data_cnt_ongoing     <= read_data_cnt_ongoing + 1;
--          elsif( rd_on_push = '0' and rd_on_pop = '1' ) then
--            read_data_cnt_ongoing     <= read_data_cnt_ongoing - 1;
--          end if;
          
--          -- Status bit for any ongoing transactions.
--          if( rd_on_push = '0' and rd_on_pop = '1' and read_data_cnt_ongoing = 1 ) then
--            read_data_any_running     <= '0';
--          elsif( rd_on_push = '1' ) then
--            read_data_any_running     <= '1';
--          end if;
          
          -- Track data flow from first to last bit.
          if( rd_active_push = '1' and rd_active_pop = '0' ) then
            read_data_started         <= '1';
          elsif( rd_active_push = '0' and rd_active_pop = '1' ) then
            read_data_started         <= '0';
          end if;
          
          -- Determine if this is nested read situation.
          if( read_data_release_block_i = '1' ) then
            read_data_possible_nested  <= '0';
          elsif( rd_active_pop = '1' ) then
            read_data_possible_nested  <= '1';
          end if;
          
          -- Detect if maximum ongoing read data transactions has been reached.
          if( read_data_release_block_i = '1' ) then
            read_data_max_concurrent  <= '0';
          elsif( set_max_concurrent = '1' ) then
            read_data_max_concurrent  <= '1';
          end if;
     
        end if;
      end if;
    end process Track_Ongoing;
    
    read_data_ex_rack         <= rd_on_pop and ron_exclusive;
    
    -- Evaluate condition to set
--    set_max_concurrent        <= rd_on_push when ( read_data_cnt_ongoing = C_MAX_PENDING_RACK - 2 ) else 
--                                 '0';
    set_max_concurrent        <= rd_on_push and ron_almost_full;
    
    -- Detect if this is a hit for the pending or ongoing read data.
    read_data_fetch_match     <= '1' when ( ri_exist = '1' ) and
                                          ( rip_addr(C_Lx_ADDR_DIRECT_POS) = read_data_fetch_addr ) and
                                          ( rip_dvm = '0' ) else
                                 '0';
    read_data_req_match       <= '1' when ( ri_exist = '1' ) and
                                          ( rip_addr(C_Lx_ADDR_DIRECT_POS) = read_data_req_addr   ) and
                                          ( rip_dvm = '0' ) else
                                 '0';
     
    -- Determine if any data is ongoing.
--    read_data_ongoing         <= read_data_any_running or not r_fifo_empty;
    read_data_ongoing         <= not ron_empty or not r_fifo_empty;
    
    -- Determine when it is possible to release the block of nested.
--    read_data_release_block_i <= rd_on_pop and not rd_on_push when ( read_data_cnt_ongoing = 1 ) else
--                                 '0';
    read_data_release_block_i <= rd_on_pop and not rd_on_push and ron_almost_empty;
    
    -- Determine if the read data hazard windows are still nested.
    read_data_block_nested    <= ( read_data_possible_nested and not read_data_release_block_i );
    
    -- Determine if snoop filter should be updated.
    read_data_fud_we          <= ri_pop and ri_allocate and not read_data_fud_is_dead;
    
    -- Tag information.
    read_data_fud_tag_valid   <= '1';
    No_Coherency_Bits: if( C_RRESP_WIDTH <= 2  ) generate
    begin
      read_data_fud_tag_unique  <= '0';
      read_data_fud_tag_dirty   <= '0';
    end generate No_Coherency_Bits;
    Use_Coherency_Bits: if( C_RRESP_WIDTH > 2  ) generate
    begin
      read_data_fud_tag_unique  <= r_rresp(C_RRESP_ISSHARED_POS);
      read_data_fud_tag_dirty   <= r_rresp(C_RRESP_PASSDIRTY_POS);
    end generate Use_Coherency_Bits;
    read_data_fud_addr        <= rip_addr;
    
    
    -----------------------------------------------------------------------------
    -- Read Lock Killed Queue
    -- 
    -- Handle Read requests that has been killed due to reuse of cache line.
    -- 
    -----------------------------------------------------------------------------
    
    -- Control signals for read info queue.
    rk_push         <= snoop_act_kill_locked;
    rk_pop          <= read_data_fud_is_dead and ri_pop;
  
    FIFO_RK_Pointer: sc_srl_fifo_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        C_USE_DEBUG               => C_USE_DEBUG,
        C_USE_ASSERTIONS          => C_USE_ASSERTIONS,
        C_USE_STATISTICS          => false,
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
        C_USE_REGISTER_OUTPUT     => C_PIPELINE_LU_READ_DATA,
        C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
        C_LINE_LENGTH             => 1
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- Queue Counter Interface
        
        queue_push                => rk_push,
        queue_pop                 => rk_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => rk_almost_full,
        queue_full                => rk_full,
        queue_almost_empty        => open,
        queue_empty               => rk_empty,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => rk_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => open,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => rk_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Handle memory for RI Channel FIFO.
    FIFO_RI_Memory : process (ACLK) is
    begin  -- process FIFO_RI_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( rk_push = '1') then
          rk_fifo_mem(0).Addr <= snoop_act_kill_addr(C_Lx_ADDR_LINE_POS);
          
          -- Shift FIFO contents.
          rk_fifo_mem(rk_fifo_mem'left downto 1) <= rk_fifo_mem(rk_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_RI_Memory;
    
    -- Get cacheline address that has been killed.
    rk_addr                       <= rk_fifo_mem(to_integer(unsigned(rk_read_fifo_addr))).Addr;
    
    -- Detect if this is a conflict with current read address.
    read_data_fud_is_dead         <= not rk_empty when ( rk_addr = rip_addr(C_Lx_ADDR_LINE_POS) ) else 
                                     '0';
    
    -- Detect that there is a line conflict.
    read_data_fetch_line_match_i  <= '1' when 
                                          ( ri_exist = '1' ) and
                                          ( rip_addr(C_Lx_ADDR_LINE_POS) = read_data_fetch_addr(C_Lx_ADDR_LINE_POS) ) 
                                         else '0';
    read_data_req_line_match_i    <= '1' when
                                          ( ri_exist = '1' ) and
                                          ( rip_addr(C_Lx_ADDR_LINE_POS) = read_data_req_addr(C_Lx_ADDR_LINE_POS) ) 
                                         else '0';
    read_data_act_line_match_i    <= '1' when 
                                          ( ri_exist = '1' ) and
                                          ( rip_addr(C_Lx_ADDR_LINE_POS) = read_data_act_addr(C_Lx_ADDR_LINE_POS) ) 
                                         else '0';
    
    -- Assign output.
    read_data_fetch_line_match    <= read_data_fetch_line_match_i;
    read_data_req_line_match      <= read_data_req_line_match_i;
    read_data_act_line_match      <= read_data_act_line_match_i;
    
    
  end generate Use_Hazard_Handling;
  

  -- Assign external signal.
  read_data_release_block   <= read_data_release_block_i;
  
  
  -----------------------------------------------------------------------------
  -- Read Queue Handling (Pointer & Flags)
  -- 
  -- Push read data into the queue/buffer together with all control information 
  -- needed.
  -- 
  -- There are two possible data sources for the read data:
  --  * Lookup (read hit)
  --  * Update (read miss)
  -----------------------------------------------------------------------------
  
  -- Handle pointers to Queue.
  FIFO_WR_Hit_Pointer : process (ACLK) is
  begin  -- process FIFO_WR_Hit_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_hit_write_fifo_addr  <= (others=>'0');
      elsif( r_hit_push = '1' ) then
        if( r_hit_write_fifo_addr = C_HIT_WRAP_LEVEL ) then
          r_hit_write_fifo_addr  <= (others=>'0');
        else
          r_hit_write_fifo_addr  <= std_logic_vector(unsigned(r_hit_write_fifo_addr) + 1);
        end if;
      end if;
    end if;
  end process FIFO_WR_Hit_Pointer;
  
  FIFO_WR_Snoop_Pointer : process (ACLK) is
  begin  -- process FIFO_WR_Snoop_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_snoop_write_fifo_addr  <= (others=>'0');
      elsif( r_snoop_push = '1' ) then
        r_snoop_write_fifo_addr  <= std_logic_vector(unsigned(r_snoop_write_fifo_addr) + 1);
      end if;
    end if;
  end process FIFO_WR_Snoop_Pointer;
  
  FIFO_WR_Miss_Pointer : process (ACLK) is
  begin  -- process FIFO_WR_Miss_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_miss_write_fifo_addr  <= (others=>'0');
      elsif( r_miss_push = '1' ) then
        r_miss_write_fifo_addr  <= std_logic_vector(unsigned(r_miss_write_fifo_addr) + 1);
      end if;
    end if;
  end process FIFO_WR_Miss_Pointer;
  
  FIFO_RD_Hit_Pointer : process (ACLK) is
  begin  -- process FIFO_RD_Hit_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_hit_read_fifo_addr  <= (others=>'0');
      elsif( r_hit_pop = '1' ) then
        if( r_hit_read_fifo_addr = C_HIT_WRAP_LEVEL ) then
          r_hit_read_fifo_addr  <= (others=>'0');
        else
          r_hit_read_fifo_addr  <= std_logic_vector(unsigned(r_hit_read_fifo_addr) + 1);
        end if;
      end if;
    end if;
  end process FIFO_RD_Hit_Pointer;
  
  FIFO_RD_Snoop_Pointer : process (ACLK) is
  begin  -- process FIFO_RD_Snoop_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_snoop_read_fifo_addr  <= (others=>'0');
      elsif( r_snoop_pop = '1' ) then
        r_snoop_read_fifo_addr  <= std_logic_vector(unsigned(r_snoop_read_fifo_addr) + 1);
      end if;
    end if;
  end process FIFO_RD_Snoop_Pointer;
  
  r_snoop_full_fifo_addr <= "10" & r_snoop_read_fifo_addr;
  
  FIFO_RD_Miss_Pointer : process (ACLK) is
  begin  -- process FIFO_RD_Miss_Pointer
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_miss_read_fifo_addr <= (others=>'0');
      elsif( r_miss_pop = '1' ) then
        r_miss_read_fifo_addr <= std_logic_vector(unsigned(r_miss_read_fifo_addr) + 1);
      end if;
    end if;
  end process FIFO_RD_Miss_Pointer;
  
  r_miss_full_fifo_addr <= "11" & r_miss_read_fifo_addr;
  
  FIFO_Hit_Length : process (ACLK) is
  begin  -- process FIFO_Hit_Length
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_hit_fifo_len  <= (others=>'0');
      elsif( r_hit_refresh = '1' ) then
        if ( r_hit_push = '1' ) then
          r_hit_fifo_len  <= std_logic_vector(unsigned(r_hit_fifo_len) + 1);
        else
          r_hit_fifo_len  <= std_logic_vector(unsigned(r_hit_fifo_len) - 1);
        end if;
      end if;
    end if;
  end process FIFO_Hit_Length;
  
  FIFO_Snoop_Length : process (ACLK) is
  begin  -- process FIFO_Snoop_Length
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_snoop_fifo_len <= (others=>'0');
      elsif( r_snoop_refresh = '1' ) then
        if ( r_snoop_push = '1' ) then
          r_snoop_fifo_len  <= std_logic_vector(unsigned(r_snoop_fifo_len) + 1);
        else
          r_snoop_fifo_len  <= std_logic_vector(unsigned(r_snoop_fifo_len) - 1);
        end if;
      end if;
    end if;
  end process FIFO_Snoop_Length;
  
  FIFO_Miss_Length : process (ACLK) is
  begin  -- process FIFO_Miss_Length
    if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
      if( ARESET = '1' ) then              -- synchronous reset (active high)
        r_miss_fifo_len <= (others=>'0');
      elsif( r_miss_refresh = '1' ) then
        if ( r_miss_push = '1' ) then
          r_miss_fifo_len <= std_logic_vector(unsigned(r_miss_fifo_len) + 1);
        else
          r_miss_fifo_len <= std_logic_vector(unsigned(r_miss_fifo_len) - 1);
        end if;
      end if;
    end if;
  end process FIFO_Miss_Length;
  
  -- Calculate Queue Status.
  r_hit_almost_full_cmb     <= '1' when (r_hit_fifo_len   =  C_HIT_QUEUE_ALMOST_FULL)     else '0';
  r_hit_almost_empty_cmb    <= '1' when (r_hit_fifo_len   =  C_HIT_QUEUE_ALMOST_EMPTY)    else '0';
  r_hit_line_fit_up_cmb     <= '1' when (r_hit_fifo_len   =  C_HIT_QUEUE_EMPTY) or         
                                        (r_hit_fifo_len   <  C_HIT_QUEUE_LINE_LEVEL_UP)   else '0';
  r_hit_line_fit_dn_cmb     <= '1' when (r_hit_fifo_len   <  C_HIT_QUEUE_LINE_LEVEL_DN)   else '0';
  
  r_snoop_almost_full_cmb   <= '1' when (r_snoop_fifo_len =  C_SNOOP_QUEUE_ALMOST_FULL)   else '0';
  r_snoop_almost_empty_cmb  <= '1' when (r_snoop_fifo_len =  C_SNOOP_QUEUE_ALMOST_EMPTY)  else '0';
  r_snoop_line_fit_up_cmb   <= '1' when (r_snoop_fifo_len =  C_SNOOP_QUEUE_EMPTY) or         
                                        (r_snoop_fifo_len <  C_SNOOP_QUEUE_LINE_LEVEL_UP) else '0';
  r_snoop_line_fit_dn_cmb   <= '1' when (r_snoop_fifo_len <  C_SNOOP_QUEUE_LINE_LEVEL_DN) else '0';
  
  r_miss_almost_full_cmb    <= '1' when (r_miss_fifo_len  = C_MISS_QUEUE_ALMOST_FULL)     else '0';
  r_miss_almost_empty_cmb   <= '1' when (r_miss_fifo_len  = C_MISS_QUEUE_ALMOST_EMPTY)    else '0';
  r_miss_line_fit_up_cmb    <= '1' when (r_miss_fifo_len  = C_MISS_QUEUE_EMPTY) or         
                                        (r_miss_fifo_len  < C_MISS_QUEUE_LINE_LEVEL_UP)   else '0';
  r_miss_line_fit_dn_cmb    <= '1' when (r_miss_fifo_len  < C_MISS_QUEUE_LINE_LEVEL_DN)   else '0';
  
  Use_RTL_Flag: if( C_TARGET = RTL ) generate
  begin
    -- Handle flags to Miss Queue.
    Miss_Flag_Handling : process (ACLK) is
    begin  -- process Miss_Flag_Handling
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          r_miss_fifo_almost_full   <= '0';
          r_miss_fifo_full          <= '0';
          r_miss_fifo_almost_empty  <= '0';
          r_miss_fifo_empty         <= '1';
          if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH - 1 ) then
            r_miss_line_fit           <= '0';
          else
            r_miss_line_fit           <= '1';
          end if;
          
        elsif( r_miss_refresh = '1' ) then
          if ( r_miss_push = '1' ) then
            r_miss_fifo_almost_full   <= r_miss_almost_full_cmb;
            r_miss_fifo_full          <= r_miss_fifo_almost_full;
            r_miss_fifo_almost_empty  <= r_miss_fifo_empty;
            r_miss_fifo_empty         <= '0';
            if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH - 1 ) then
              r_miss_line_fit           <= '0';
            else
              r_miss_line_fit           <= r_miss_line_fit_up_cmb;
            end if;
            
          else
            r_miss_fifo_almost_full   <= r_miss_fifo_full;
            r_miss_fifo_full          <= '0';
            r_miss_fifo_almost_empty  <= r_miss_almost_empty_cmb;
            r_miss_fifo_empty         <= r_miss_fifo_almost_empty;
            if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH - 1 ) then
              r_miss_line_fit           <= '0';
            else
              r_miss_line_fit           <= r_miss_line_fit_dn_cmb;
            end if;
            
          end if;
        end if;
      end if;
    end process Miss_Flag_Handling;
    
    -- Handle flags to Snoop Queue.
    Snoop_Flag_Handling : process (ACLK) is
    begin  -- process Snoop_Flag_Handling
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          r_snoop_fifo_almost_full  <= '0';
          r_snoop_fifo_full         <= '0';
          r_snoop_fifo_almost_empty <= '0';
          r_snoop_fifo_empty        <= '1';
          if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) then
            r_snoop_line_fit          <= '0';
          else
            r_snoop_line_fit          <= '1';
          end if;
          
        elsif( r_snoop_refresh = '1' ) then
          if ( r_snoop_push = '1' ) then
            r_snoop_fifo_almost_full  <= r_snoop_almost_full_cmb;
            r_snoop_fifo_full         <= r_snoop_fifo_almost_full;
            r_snoop_fifo_almost_empty <= r_snoop_fifo_empty;
            r_snoop_fifo_empty        <= '0';
            if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) then
              r_snoop_line_fit          <= '0';
            else
              r_snoop_line_fit          <= r_snoop_line_fit_up_cmb;
            end if;
            
          else
            r_snoop_fifo_almost_full  <= r_snoop_fifo_full;
            r_snoop_fifo_full         <= '0';
            r_snoop_fifo_almost_empty <= r_snoop_almost_empty_cmb;
            r_snoop_fifo_empty        <= r_snoop_fifo_almost_empty;
            if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) then
              r_snoop_line_fit          <= '0';
            else
              r_snoop_line_fit          <= r_snoop_line_fit_dn_cmb;
            end if;
            
          end if;
        end if;
      end if;
    end process Snoop_Flag_Handling;
      
    -- Handle flags to Hit Queue.
    Hit_Flag_Handling : process (ACLK) is
    begin  -- process Hit_Flag_Handling
      if( ACLK'event and ACLK = '1' ) then   -- rising clock edge
        if( ARESET = '1' ) then              -- synchronous reset (active high)
          r_hit_fifo_almost_full  <= '0';
          r_hit_fifo_full         <= '0';
          r_hit_fifo_almost_empty <= '0';
          r_hit_fifo_empty        <= '1';
          if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) then
            r_hit_line_fit          <= '0';
          else
            r_hit_line_fit          <= '1';
          end if;
          
        elsif( r_hit_refresh = '1' ) then
          if ( r_hit_push = '1' ) then
            r_hit_fifo_almost_full  <= r_hit_almost_full_cmb;
            r_hit_fifo_full         <= r_hit_fifo_almost_full;
            r_hit_fifo_almost_empty <= r_hit_fifo_empty;
            r_hit_fifo_empty        <= '0';
            if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) then
              r_hit_line_fit          <= '0';
            else
              r_hit_line_fit          <= r_hit_line_fit_up_cmb;
            end if;
            
          else
            r_hit_fifo_almost_full  <= r_hit_fifo_full;
            r_hit_fifo_full         <= '0';
            r_hit_fifo_almost_empty <= r_hit_almost_empty_cmb;
            r_hit_fifo_empty        <= r_hit_fifo_almost_empty;
            if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) then
              r_hit_line_fit          <= '0';
            else
              r_hit_line_fit          <= r_hit_line_fit_dn_cmb;
            end if;
            
          end if;
        end if;
      end if;
    end process Hit_Flag_Handling;
      
  end generate Use_RTL_Flag;
  
  Use_FPGA_Flag_Hit: if( C_TARGET /= RTL ) generate
    signal queue_almost_full_next   : std_logic;
    signal queue_full_next          : std_logic;
    signal queue_almost_empty_next  : std_logic;
    signal queue_empty_next         : std_logic;
    signal queue_line_fit_next      : std_logic;
    
  begin
    
    -- Handle flags to Queue.
    Flag_Handling : process (r_hit_refresh, r_hit_push, 
                             r_hit_fifo_full, 
                             r_hit_almost_full_cmb, r_hit_fifo_almost_full, 
                             r_hit_almost_empty_cmb, r_hit_fifo_almost_empty, 
                             r_hit_fifo_empty, 
                             r_hit_line_fit_up_cmb, r_hit_line_fit_dn_cmb, r_hit_line_fit) is
    begin  -- process Flag_Handling
      if( r_hit_refresh = '1' ) then
        if ( r_hit_push = '1' ) then
          queue_almost_full_next  <= r_hit_almost_full_cmb;
          queue_full_next         <= r_hit_fifo_almost_full;
          queue_almost_empty_next <= r_hit_fifo_empty;
          queue_empty_next        <= '0';
          if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_hit_line_fit_up_cmb;
          end if;
          
        else
          queue_almost_full_next  <= r_hit_fifo_full;
          queue_full_next         <= '0';
          queue_almost_empty_next <= r_hit_almost_empty_cmb;
          queue_empty_next        <= r_hit_fifo_almost_empty;
          if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_hit_line_fit_dn_cmb;
          end if;
          
        end if;
      else
        queue_almost_full_next  <= r_hit_fifo_almost_full;
        queue_full_next         <= r_hit_fifo_full;
        queue_almost_empty_next <= r_hit_fifo_almost_empty;
        queue_empty_next        <= r_hit_fifo_empty;
        queue_line_fit_next     <= r_hit_line_fit;
      end if;
    end process Flag_Handling;
      
    Almost_Full_Inst : FDR
      port map (
        Q  => r_hit_fifo_almost_full,       -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_full_next,       -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Full_Inst : FDR
      port map (
        Q  => r_hit_fifo_full,              -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_full_next,              -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Almost_Empty_Inst : FDR
      port map (
        Q  => r_hit_fifo_almost_empty,      -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_empty_next,      -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Empty_Inst : FDS
      port map (
        Q  => r_hit_fifo_empty,             -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_empty_next,             -- [in  std_logic]
        S  => ARESET                        -- [in  std_logic]
      );
    
    Use_Normal_Line: if( C_LINE_LENGTH < C_HIT_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDS
        port map (
          Q  => r_hit_line_fit,               -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Normal_Line;
    Use_Long_Line: if( C_LINE_LENGTH >= C_HIT_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDR
        port map (
          Q  => r_hit_line_fit,               -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          R  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Long_Line;
  end generate Use_FPGA_Flag_Hit;
  
  Use_FPGA_Flag_Snoop: if( C_TARGET /= RTL ) generate
    signal queue_almost_full_next   : std_logic;
    signal queue_full_next          : std_logic;
    signal queue_almost_empty_next  : std_logic;
    signal queue_empty_next         : std_logic;
    signal queue_line_fit_next      : std_logic;
    
  begin
    
    -- Handle flags to Queue.
    Flag_Handling : process (r_snoop_refresh, r_snoop_push, 
                             r_snoop_fifo_full, 
                             r_snoop_almost_full_cmb, r_snoop_fifo_almost_full, 
                             r_snoop_almost_empty_cmb, r_snoop_fifo_almost_empty, 
                             r_snoop_fifo_empty, 
                             r_snoop_line_fit_up_cmb, r_snoop_line_fit_dn_cmb, r_snoop_line_fit) is
    begin  -- process Flag_Handling
      if( r_snoop_refresh = '1' ) then
        if ( r_snoop_push = '1' ) then
          queue_almost_full_next  <= r_snoop_almost_full_cmb;
          queue_full_next         <= r_snoop_fifo_almost_full;
          queue_almost_empty_next <= r_snoop_fifo_empty;
          queue_empty_next        <= '0';
          if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_snoop_line_fit_up_cmb;
          end if;
          
        else
          queue_almost_full_next  <= r_snoop_fifo_full;
          queue_full_next         <= '0';
          queue_almost_empty_next <= r_snoop_almost_empty_cmb;
          queue_empty_next        <= r_snoop_fifo_almost_empty;
          if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_snoop_line_fit_dn_cmb;
          end if;
          
        end if;
      else
        queue_almost_full_next  <= r_snoop_fifo_almost_full;
        queue_full_next         <= r_snoop_fifo_full;
        queue_almost_empty_next <= r_snoop_fifo_almost_empty;
        queue_empty_next        <= r_snoop_fifo_empty;
        queue_line_fit_next     <= r_snoop_line_fit;
      end if;
    end process Flag_Handling;
      
    Almost_Full_Inst : FDR
      port map (
        Q  => r_snoop_fifo_almost_full,       -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_full_next,       -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Full_Inst : FDR
      port map (
        Q  => r_snoop_fifo_full,            -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_full_next,              -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Almost_Empty_Inst : FDR
      port map (
        Q  => r_snoop_fifo_almost_empty,    -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_empty_next,      -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Empty_Inst : FDS
      port map (
        Q  => r_snoop_fifo_empty,           -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_empty_next,             -- [in  std_logic]
        S  => ARESET                        -- [in  std_logic]
      );
    
    Use_Normal_Line: if( C_LINE_LENGTH < C_SNOOP_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDS
        port map (
          Q  => r_snoop_line_fit,             -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Normal_Line;
    Use_Long_Line: if( C_LINE_LENGTH >= C_SNOOP_QUEUE_LENGTH - 1 ) generate
    begin
      Line_Fit_Inst : FDR
        port map (
          Q  => r_snoop_line_fit,             -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          R  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Long_Line;
  end generate Use_FPGA_Flag_Snoop;
  
  Use_FPGA_Flag_Miss: if( C_TARGET /= RTL ) generate
    signal queue_almost_full_next   : std_logic;
    signal queue_full_next          : std_logic;
    signal queue_almost_empty_next  : std_logic;
    signal queue_empty_next         : std_logic;
    signal queue_line_fit_next      : std_logic;
    
  begin
    
    -- Handle flags to Queue.
    Flag_Handling : process (r_miss_refresh, r_miss_push, 
                             r_miss_fifo_full, 
                             r_miss_almost_full_cmb, r_miss_fifo_almost_full, 
                             r_miss_almost_empty_cmb, r_miss_fifo_almost_empty, 
                             r_miss_fifo_empty, 
                             r_miss_line_fit_up_cmb, r_miss_line_fit_dn_cmb, r_miss_line_fit) is
    begin  -- process Flag_Handling
      if( r_miss_refresh = '1' ) then
        if ( r_miss_push = '1' ) then
          queue_almost_full_next  <= r_miss_almost_full_cmb;
          queue_full_next         <= r_miss_fifo_almost_full;
          queue_almost_empty_next <= r_miss_fifo_empty;
          queue_empty_next        <= '0';
          if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH_BITS - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_miss_line_fit_up_cmb;
          end if;
          
        else
          queue_almost_full_next  <= r_miss_fifo_full;
          queue_full_next         <= '0';
          queue_almost_empty_next <= r_miss_almost_empty_cmb;
          queue_empty_next        <= r_miss_fifo_almost_empty;
          if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH_BITS - 1 ) then
            queue_line_fit_next     <= '0';
          else
            queue_line_fit_next     <= r_miss_line_fit_dn_cmb;
          end if;
          
        end if;
      else
        queue_almost_full_next  <= r_miss_fifo_almost_full;
        queue_full_next         <= r_miss_fifo_full;
        queue_almost_empty_next <= r_miss_fifo_almost_empty;
        queue_empty_next        <= r_miss_fifo_empty;
        queue_line_fit_next     <= r_miss_line_fit;
      end if;
    end process Flag_Handling;
      
    Almost_Full_Inst : FDR
      port map (
        Q  => r_miss_fifo_almost_full,      -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_full_next,       -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Full_Inst : FDR
      port map (
        Q  => r_miss_fifo_full,             -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_full_next,              -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Almost_Empty_Inst : FDR
      port map (
        Q  => r_miss_fifo_almost_empty,     -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_almost_empty_next,      -- [in  std_logic]
        R  => ARESET                        -- [in  std_logic]
      );
          
    Empty_Inst : FDS
      port map (
        Q  => r_miss_fifo_empty,            -- [out std_logic]
        C  => ACLK,                         -- [in  std_logic]
        D  => queue_empty_next,             -- [in  std_logic]
        S  => ARESET                        -- [in  std_logic]
      );
    
    Use_Normal_Line: if( C_LINE_LENGTH < C_MISS_QUEUE_LENGTH_BITS - 1 ) generate
    begin
      Line_Fit_Inst : FDS
        port map (
          Q  => r_miss_line_fit,              -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          S  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Normal_Line;
    Use_Long_Line: if( C_LINE_LENGTH >= C_MISS_QUEUE_LENGTH_BITS - 1 ) generate
    begin
      Line_Fit_Inst : FDR
        port map (
          Q  => r_miss_line_fit,              -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => queue_line_fit_next,          -- [in  std_logic]
          R  => ARESET                        -- [in  std_logic]
        );
    end generate Use_Long_Line;
    
  end generate Use_FPGA_Flag_Miss;
  
  -- Assign external signals.
  read_data_hit_pop         <= r_hit_pop;
  read_data_hit_almost_full <= r_hit_fifo_almost_full;
  read_data_hit_full        <= r_hit_fifo_full;
  read_data_hit_fit         <= r_hit_line_fit;
-- TODO: looks like it is unused...  
  read_data_miss_full       <= r_miss_fifo_full or r_snoop_push or r_hit_push;
  
  -- Return ready signal for throttling.
  lookup_read_data_ready  <= not r_hit_fifo_full;
  update_read_data_ready  <= not r_miss_fifo_full and 
                             not ( lookup_read_data_valid and not   r_hit_fifo_full );
  snoop_read_data_ready   <= not r_snoop_fifo_full and 
                             not ( update_read_data_valid and not  r_miss_fifo_full ) and 
                             not ( lookup_read_data_valid and not   r_hit_fifo_full );
  
  
  -----------------------------------------------------------------------------
  -- Read Information Queue Handling
  -- 
  -- Push all control information needed into the queue to be able to do the 
  -- port specific modifications of the returned data.
  -----------------------------------------------------------------------------
  
  -- Control signals for read data queue.
  rip_push      <= read_req_valid;
  rip_push_safe <= rip_push and not rip_fifo_full;
--  rip_pop       <= r_pop_safe and r_last;
  RC_And_Inst6: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => r_pop_safe,
      A         => r_last,
      Carry_OUT => rip_pop
    );
  
  FIFO_RIP_Pointer: sc_srl_fifo_counter
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
      C_POP_ON_CARRY            => true,
      C_ENABLE_PROTECTION       => true,
      C_USE_QUALIFIER           => false,
      C_QUALIFIER_LEVEL         => 0,
      C_USE_REGISTER_OUTPUT     => true,
      C_QUEUE_ADDR_WIDTH        => C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 2
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => rip_push,
      queue_pop                 => rip_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => rip_refresh_reg,
      
      queue_almost_full         => rip_fifo_almost_full,
      queue_full                => rip_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => open,
      queue_exist               => rip_exist,
      queue_line_fit            => read_req_ready,
      queue_index               => rip_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_s_axi_rip,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => rip_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for RIP Channel FIFO.
  FIFO_RIP_Memory : process (ACLK) is
  begin  -- process FIFO_RIP_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( rip_push_safe = '1') then
        -- Insert new item.
        rip_fifo_mem(0).ID        <= read_req_ID;
        rip_fifo_mem(0).Last      <= read_req_last;
        rip_fifo_mem(0).Offset    <= read_req_offset;
        rip_fifo_mem(0).Rest      <= read_req_rest;
        rip_fifo_mem(0).Stp_Bits  <= read_req_stp;
        rip_fifo_mem(0).Use_Bits  <= read_req_use;
        rip_fifo_mem(0).Len       <= read_req_len;
        rip_fifo_mem(0).Single    <= read_req_single;
        rip_fifo_mem(0).DVM       <= read_req_dvm;
        rip_fifo_mem(0).Addr      <= read_req_addr;
        rip_fifo_mem(0).DSid	  <= read_req_DSid;
        
        -- Shift FIFO contents.
        rip_fifo_mem(rip_fifo_mem'left downto 1) <= rip_fifo_mem(rip_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_RIP_Memory;
  
  -- Store RIP in register for good timing.
  RIP_Data_Registers : process (ACLK) is
  begin  -- process RIP_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        rip_id      <= C_NULL_RIP.ID;
        rip_last    <= C_NULL_RIP.Last;
        rip_offset  <= C_NULL_RIP.Offset;
        rip_stp     <= C_NULL_RIP.Stp_Bits;
        rip_use     <= C_NULL_RIP.Use_Bits;
        rip_single  <= C_NULL_RIP.Single;
        rip_dvm     <= C_NULL_RIP.DVM;
        rip_addr    <= C_NULL_RIP.Addr;
        
      elsif( rip_refresh_reg = '1' ) then
        rip_id      <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).ID;
        rip_last    <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Last;
        rip_offset  <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Offset;
        rip_stp     <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Stp_Bits;
        rip_use     <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Use_Bits;
        rip_single  <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Single;
        rip_dvm     <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).DVM;
        rip_addr    <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Addr;
        rip_DSid    <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).DSid;
      end if;
    end if;
  end process RIP_Data_Registers;
  
  
  -----------------------------------------------------------------------------
  -- Read Port Handling
  -- 
  -- Serialize read data when neccessary.
  -- 
  -- Input data signals for serialization
  -- rip_offset - Contains starting point in the internal word
  -- rip_last   - If this is the last part of a split transaction (only generic
  --              has the capability to split)
  -- rip_stp    - Size of each part that shall be extracted (only generic
  --              has the capability to use non 32bit words)
  -- rip_rest   - How much that remains of the first word. Set to non-max for
  --              unaligned transactions. Max value together with rip_offset
  --              can be used to create wrap access, but that only works for
  --              one word MicroBlaze wrap (longer wrap are not supported
  --              internally).
  -- rip_len    - Total number of data beats that are needed.
  -----------------------------------------------------------------------------
  
  -- Expand for narrow interface.
  Read_External_Narrow: if( C_S_AXI_DATA_WIDTH < C_CACHE_DATA_WIDTH or C_SUPPORT_SUBSIZED ) generate
  
    subtype RATIO_POS                   is natural range C_RATIO - 1 downto 0;
    subtype R_DATA_TYPE                 is std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
    type R_DATA_MUX_TYPE                is array(RATIO_POS) of R_DATA_TYPE;
    
    subtype C_RATIO_BITS_POS            is natural range Log2(C_CACHE_DATA_WIDTH/8) - 1 downto 
                                                         Log2(C_S_AXI_DATA_WIDTH/8);
    subtype RATIO_BITS_TYPE             is std_logic_vector(C_RATIO_BITS_POS);
    
    signal offset_cnt_next              : ADDR_BYTE_TYPE;
    signal offset                       : ADDR_BYTE_TYPE;
    signal length_cnt                   : LEN_TYPE;
    signal rd_length                    : LEN_TYPE;
    signal rest_cnt                     : REST_TYPE;
    signal rd_rest                      : REST_TYPE;
    signal r_data_i                     : R_DATA_MUX_TYPE;
    
    signal rd_length_zero               : std_logic;
    signal rd_rest_zero                 : std_logic;
    signal rd_pop_part                  : std_logic;
    
  begin
    Data_Offset : process (ACLK) is
    begin  -- process Data_Offset
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
          offset    <= C_NULL_RIP.Offset;
          rd_length <= C_NULL_RIP.Len;
          rd_rest   <= C_NULL_RIP.Rest;
        else
          if( rip_refresh_reg = '1' ) then
            offset    <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Offset;
            rd_length <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Len;
            rd_rest   <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).Rest;
          elsif( ( S_AXI_RREADY and not r_fifo_empty ) = '1' ) then
            offset    <= offset_cnt_next;
            rd_length <= std_logic_vector(unsigned(rd_length) - 1);
            rd_rest   <= std_logic_vector(unsigned(rd_rest)   - unsigned(rip_stp));
          end if;
        end if;
      end if;
    end process Data_Offset;
  
    -- Generate next offset including wrap.
    Update_Offset_Select: process (offset, rip_stp, rip_use, rip_offset) is
      variable offset_cnt_next_cmb  : ADDR_BYTE_TYPE;
    begin  -- process Update_Offset_Select
      offset_cnt_next_cmb     := std_logic_vector(unsigned(offset) + unsigned(rip_stp));
      
      for I in offset_cnt_next_cmb'range loop
        if( rip_use(I) = '0' ) then
          offset_cnt_next(I)  <= rip_offset(I);
          
        else
          offset_cnt_next(I)  <= offset_cnt_next_cmb(I);
          
        end if;
      end loop;
    end process Update_Offset_Select;
    
    -- Determine if this data word has been completely used.
--    rd_done   <= '1' when to_integer(unsigned(rd_length)) = 0 else rd_pop;
--    rd_pop    <= '1' when to_integer(unsigned(rd_rest))   = 0 else rip_single;
    rd_rest_zero    <= '1' when to_integer(unsigned(rd_rest))   = 0 else '0';
    RC_And_Inst1: carry_compare_const
      generic map(
        C_TARGET  => C_TARGET,
        C_SIGNALS => 1,
        C_SIZE    => LEN_TYPE'length,
        B_Vec     => (C_LEN_POS=>'0')
      )
      port map(
        Carry_In  => '1',                 -- [in  std_logic]
        A_Vec     => rd_length,           -- [in  std_logic_vector]
        Carry_Out => rd_length_zero       -- [out std_logic]
      );
    RC_Or_Inst1: carry_or 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => rd_length_zero,
        A         => rd_rest_zero,
        Carry_OUT => rd_pop
      );
    RC_Or_Inst2: carry_or 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => rd_pop,
        A         => rip_single,
        Carry_OUT => rd_done
      );
      
    -- Generate array for easy extraction.
    Gen_Read_Array: for I in 0 to C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH - 1 generate
    begin
      -- Generate mirrored data and steer byte enable.
      r_data_i(I) <= r_data((I+1) * C_S_AXI_DATA_WIDTH - 1 downto I * C_S_AXI_DATA_WIDTH);
    end generate Gen_Read_Array;
    
    -- Generate output.
    S_AXI_RLAST_I <= r_last and rd_done and rip_last;
    S_AXI_RDATA_I <= r_data_i(to_integer(unsigned(offset(C_RATIO_BITS_POS))));
    
    Use_Debug: if( C_USE_DEBUG ) generate
      constant C_MY_DATA    : natural := min_of(32, C_S_AXI_DATA_WIDTH);
      constant C_MY_RESP    : natural := min_of( 4, C_S_AXI_RESP_WIDTH);
      constant C_MY_ID      : natural := min_of( 4, C_S_AXI_ID_WIDTH);
      constant C_MY_REST    : natural := min_of( 6, C_REST_WIDTH);
      constant C_MY_OFF     : natural := min_of( 6, C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1);
      constant C_MY_LEN     : natural := min_of( 6, C_LEN_WIDTH);
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET = '1') then              -- synchronous reset (active true)
            IF_DEBUG(255 downto 196)                  <= (others=>'0');
          else
            -- Default assignment.
            IF_DEBUG(255 downto 196)                  <= (others=>'0');
            
            IF_DEBUG(196 + C_MY_OFF   - 1 downto 196) <= rip_use(C_MY_OFF - 1 downto 0);
            IF_DEBUG(202 + C_MY_OFF   - 1 downto 202) <= rip_stp(C_MY_OFF - 1 downto 0);
            IF_DEBUG(208 + C_MY_OFF   - 1 downto 208) <= rip_offset(C_MY_OFF - 1 downto 0);
            IF_DEBUG(                            214) <= rip_last;
            IF_DEBUG(                            215) <= rip_single;
            IF_DEBUG(216 + C_MY_OFF   - 1 downto 216) <= offset(C_MY_OFF - 1 downto 0);
            IF_DEBUG(222 + C_MY_LEN   - 1 downto 222) <= rd_length(C_MY_LEN - 1 downto 0);
            IF_DEBUG(228 + C_MY_REST  - 1 downto 228) <= rd_rest(C_MY_REST - 1 downto 0);
            IF_DEBUG(                            234) <= rd_pop;
            IF_DEBUG(                            235) <= rd_done;
            IF_DEBUG(                            236) <= r_last;
            IF_DEBUG(                            237) <= ri_allocate;
            IF_DEBUG(                            238) <= ri_hit;
            IF_DEBUG(                            239) <= ri_snoop;
            IF_DEBUG(                            240) <= lookup_read_data_new;
            IF_DEBUG(                            241) <= lookup_read_data_hit;
            IF_DEBUG(                            242) <= lookup_read_data_snoop;
            IF_DEBUG(                            243) <= lookup_read_data_allocate;
            
          end if;
        end if;
      end process Debug_Handle;
    end generate Use_Debug;
  end generate Read_External_Narrow;
  
  Read_External_Same: if( C_S_AXI_DATA_WIDTH = C_CACHE_DATA_WIDTH  and not C_SUPPORT_SUBSIZED) generate
  begin
    -- Same size, word is always done.
    rd_done       <= '1';
    
    -- Size matches, just forward all signals.
    S_AXI_RLAST_I <= r_last and rip_last;
    S_AXI_RDATA_I <= r_data;
    
    Use_Debug: if( C_USE_DEBUG ) generate
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET = '1') then              -- synchronous reset (active true)
            IF_DEBUG(255 downto 196)                  <= (others=>'0');
          else
            -- Default assignment.
            IF_DEBUG(255 downto 196)                  <= (others=>'0');
            
            IF_DEBUG(                            214) <= rip_last;
            IF_DEBUG(                            235) <= rd_done;
            IF_DEBUG(                            236) <= r_last;
            IF_DEBUG(                            237) <= ri_allocate;
            IF_DEBUG(                            238) <= ri_hit;
            IF_DEBUG(                            239) <= ri_snoop;
            IF_DEBUG(                            240) <= lookup_read_data_new;
            IF_DEBUG(                            241) <= lookup_read_data_hit;
            IF_DEBUG(                            242) <= lookup_read_data_snoop;
            IF_DEBUG(                            243) <= lookup_read_data_allocate;
            
          end if;
        end if;
      end process Debug_Handle;
    end generate Use_Debug;
  end generate Read_External_Same;
  
  Use_RTL_2: if( C_TARGET = RTL ) generate
  begin
    S_AXI_RVALID  <= not r_fifo_empty;
    
  end generate Use_RTL_2;
  
  Use_FPGA_2: if( C_TARGET /= RTL ) generate
    
    signal ri_miss                  : std_logic;
    signal next_ri_miss             : std_logic;
    signal r_hit_one                : std_logic;
    signal r_snoop_one              : std_logic;
    signal r_miss_one               : std_logic;
    signal r_hit_exist              : std_logic;
    signal r_snoop_exist            : std_logic;
    signal r_miss_exist             : std_logic;
    signal r_hit_available          : std_logic;
    signal r_snoop_available        : std_logic;
    signal r_miss_available         : std_logic;
    signal r_next_hit_available     : std_logic;
    signal r_next_snoop_available   : std_logic;
    signal r_next_miss_available    : std_logic;
    
  begin
--    r_fifo_true_empty     <= ( (     ri_hit                  and   r_hit_fifo_empty ) or 
--                               (                    ri_snoop and r_snoop_fifo_empty ) or 
--                               ( not ri_hit and not ri_snoop and  r_miss_fifo_empty ) ) or 
--                             ( not ri_exist );
--    r_fifo_empty          <= r_fifo_true_empty or snoop_act_read_hazard or read_data_max_concurrent;
    
    -- Help signals for non-hit and non-snoop => miss. 
    ri_miss                 <= not      ri_hit and not      ri_snoop; 
    next_ri_miss            <= not next_ri_hit and not next_ri_snoop; 
    
    -- Only one data word available (this word).
    r_hit_one               <= r_hit_fifo_almost_empty;
    r_snoop_one             <= r_snoop_fifo_almost_empty;
    r_miss_one              <= r_miss_fifo_almost_empty;
    
    -- Help signal for data available.
    r_hit_exist             <= not r_hit_fifo_empty;
    r_snoop_exist           <= not r_snoop_fifo_empty;
    r_miss_exist            <= not r_miss_fifo_empty;
    
    -- Detect if data is available per type.
    --  * Push will always make data available, regardless of current depth.
    --  * Data is also available if the last item isn't pop'ed this cycle (with no new arriving).
    r_hit_available         <= ( r_hit_push   or ( r_hit_exist   and not ( r_hit_pop   and r_hit_one   ) ) ) and 
                               ri_hit;
    r_snoop_available       <= ( r_snoop_push or ( r_snoop_exist and not ( r_snoop_pop and r_snoop_one ) ) ) and 
                               ri_snoop;
    r_miss_available        <= ( r_miss_push  or ( r_miss_exist  and not ( r_miss_pop  and r_miss_one  ) ) ) and 
                               ri_miss;
    
    r_next_hit_available    <= ( r_hit_push   or ( r_hit_exist   and not ( r_hit_pop   and r_hit_one   ) ) ) and 
                               next_ri_hit;
    r_next_snoop_available  <= ( r_snoop_push or ( r_snoop_exist and not ( r_snoop_pop and r_snoop_one ) ) ) and 
                               next_ri_snoop;
    r_next_miss_available   <= ( r_miss_push  or ( r_miss_exist  and not ( r_miss_pop  and r_miss_one  ) ) ) and 
                               next_ri_miss;
    
    Data_Offset : process (ACLK) is
    begin  -- process Data_Offset
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active high)
          S_AXI_RVALID  <= '0';
        else
          if( ( (                               snoop_act_set_read_hazard and     snoop_req_piperun ) = '1' ) or
              ( ( snoop_act_read_hazard and not snoop_act_rst_read_hazard and not snoop_req_piperun ) = '1' ) or
              ( ( set_max_concurrent       and not read_data_release_block_i ) = '1' ) or
              ( ( read_data_max_concurrent and not read_data_release_block_i ) = '1' ) ) then
            -- The equivalent of having "snoop_act_read_hazard or read_data_max_concurrent" in the empty expression
            -- => Turn off valid until it is safe again. 
            S_AXI_RVALID  <= '0';
            
          else
            -- There is the posiblity of data from RI Queue may have information of next data.
            if( ( ri_exist = '0' ) or ( ri_pop = '1') ) then
              -- Information must come from the Next stage because of non existant or used information i Reg stage.
              if( ri_empty = '1' ) then
                -- No Information => No data.
                S_AXI_RVALID  <= '0';
                
              else
                -- If data is available or will become available next cycle.
                S_AXI_RVALID  <= r_next_hit_available or r_next_snoop_available or r_next_miss_available;
                
              end if;
            else
              -- Pipeline information exist that can be used to determine if data is available or 
              -- will become available next cycle.
              S_AXI_RVALID  <= r_hit_available or r_snoop_available or r_miss_available;
              
            end if;
          end if;
        end if;
      end if;
    end process Data_Offset;
  end generate Use_FPGA_2;
  
  -- Forward untouche signals (width independent).
  S_AXI_RLAST   <= S_AXI_RLAST_I;
  S_AXI_RID     <= rip_id;
  S_AXI_RRESP   <= r_rresp;
  S_AXI_RDATA   <= S_AXI_RDATA_I;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Statistics: if( not C_USE_STATISTICS ) generate
  begin
    stat_s_axi_r  <= C_NULL_STAT_FIFO;
  end generate No_Statistics;
  
  Use_Statistics: if( C_USE_STATISTICS ) generate
  begin
    Fake_FIFO_R_Pointer: sc_srl_fifo_counter
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
        C_LINE_LENGTH             => 2
      )
      port map(
        -- ---------------------------------------------------
        -- Common signals.
        
        ACLK                      => ACLK,
        ARESET                    => ARESET,
    
        -- ---------------------------------------------------
        -- Queue Counter Interface
        
        queue_push                => r_push_safe,
        queue_pop                 => r_pop_safe_i,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => open,
        queue_full                => open,
        queue_almost_empty        => open,
        queue_empty               => open,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => open,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => stat_s_axi_r,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => open,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
  end generate Use_Statistics;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_DATA    : natural := min_of(32, C_S_AXI_DATA_WIDTH);
    constant C_MY_RESP    : natural := min_of( 4, C_S_AXI_RESP_WIDTH);
    constant C_MY_ID      : natural := min_of( 4, C_S_AXI_ID_WIDTH);
    constant C_MY_REST    : natural := min_of( 6, C_REST_WIDTH);
    constant C_MY_OFF     : natural := min_of( 6, C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1);
    constant C_MY_LEN     : natural := min_of( 6, C_LEN_WIDTH);
    constant C_MY_DQ      : natural := min_of( 6, C_DATA_QUEUE_LENGTH_BITS);
    constant C_MY_HQ      : natural := min_of( 6, C_HIT_QUEUE_LENGTH_BITS);
    constant C_MY_MQ      : natural := min_of( 4, C_MISS_QUEUE_LENGTH_BITS);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          IF_DEBUG(195 downto 0)                    <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG(195 downto 0)                    <= (others=>'0');
          
          -- R-Channel
          IF_DEBUG(  0 + C_MY_ID    - 1 downto   0) <= rip_fifo_mem(to_integer(unsigned(rip_read_fifo_addr))).ID(C_MY_ID - 1 downto 0); -- S_AXI_RID
          IF_DEBUG(  4 + C_MY_DATA  - 1 downto   4) <= S_AXI_RDATA_I(C_MY_DATA - 1 downto 0);
          IF_DEBUG( 36 + C_MY_RESP  - 1 downto  36) <= rr_fifo_mem(to_integer(unsigned(r_read_fifo_addr)))(C_MY_RESP - 1 downto 0); -- S_AXI_RRESP
          IF_DEBUG(                             40) <= S_AXI_RLAST_I;
          IF_DEBUG(                             41) <= not r_fifo_empty; -- S_AXI_RVALID
          IF_DEBUG(                             42) <= S_AXI_RREADY;
          
          -- Read Information Interface Signals.
          IF_DEBUG(                             43) <= read_req_valid;
          IF_DEBUG( 44 + C_MY_ID    - 1 downto  44) <= read_req_ID(C_MY_ID - 1 downto 0);
          IF_DEBUG(                             48) <= read_req_last;
          IF_DEBUG(                             49) <= read_req_failed;
          IF_DEBUG(                             50) <= read_req_single;
          IF_DEBUG( 51 + C_MY_REST  - 1 downto  51) <= read_req_rest(C_MY_REST - 1 downto 0);
          IF_DEBUG( 57 + C_MY_OFF   - 1 downto  57) <= read_req_offset(C_MY_OFF - 1 downto 0);
          IF_DEBUG( 63 + C_MY_OFF   - 1 downto  63) <= read_req_stp(C_MY_OFF - 1 downto 0);
          IF_DEBUG( 69 + C_MY_LEN   - 1 downto  69) <= read_req_len(C_MY_LEN - 1 downto 0);
          IF_DEBUG(                             75) <= not rip_fifo_full; -- read_req_ready;
          
          -- Internal Interface Signals (Read request).
          IF_DEBUG(                             76) <= rd_port_ready;
          
          -- Internal Interface Signals (Read Data).
          IF_DEBUG(                             77) <= r_fifo_almost_full; -- read_data_almost_full
          IF_DEBUG(                             78) <= r_fifo_full; -- read_data_full
          
          -- Lookup signals (Read Data).
          IF_DEBUG(                             79) <= lookup_read_data_valid;
          IF_DEBUG(                             80) <= lookup_read_data_last;
          IF_DEBUG( 81 + C_MY_RESP  - 1 downto  81) <= lookup_read_data_resp(C_MY_RESP - 1 downto 0);
          IF_DEBUG( 85 + C_MY_DATA  - 1 downto  85) <= lookup_read_data_word_i(C_MY_DATA - 1 downto 0);
          IF_DEBUG(                            117) <= not r_hit_fifo_full; -- lookup_read_data_ready
          
          -- Update signals (Read Data).
          IF_DEBUG(                            118) <= update_read_data_valid;
          IF_DEBUG(                            119) <= update_read_data_last;
          IF_DEBUG(120 + C_MY_RESP  - 1 downto 120) <= update_read_data_resp(C_MY_RESP - 1 downto 0);
          IF_DEBUG(124 + C_MY_DATA  - 1 downto 124) <= update_read_data_word(C_MY_DATA - 1 downto 0);
          IF_DEBUG(                            156) <= not r_miss_fifo_full and not ( lookup_read_data_valid and not r_hit_fifo_full ); 
                                                       -- update_read_data_ready
          
          -- Access signals (Read Data).
--          IF_DEBUG(                            157) <= '0'; -- snoop_read_data_valid;
--          IF_DEBUG(                            158) <= '0'; -- snoop_read_data_last;
--          IF_DEBUG(159 + C_MY_RESP  - 1 downto 159) <= (others=>'0'); -- snoop_read_data_resp(C_MY_RESP - 1 downto 0);
--          IF_DEBUG(163 + C_MY_DATA  - 1 downto 163) <= (others=>'0'); -- snoop_read_data_word(C_MY_DATA - 1 downto 0);
--          IF_DEBUG(                            195) <= not r_fifo_full; -- snoop_read_data_ready
          
          IF_DEBUG(                            157) <= ri_push;
          IF_DEBUG(                            158) <= ri_pop;
          IF_DEBUG(                            159) <= ri_exist;
          IF_DEBUG(                            160) <= ri_hit;
  
          IF_DEBUG(                            161) <= r_hit_push;
          IF_DEBUG(                            162) <= r_miss_push;
          IF_DEBUG(                            163) <= r_push_safe;
          IF_DEBUG(                            164) <= r_pop;
          IF_DEBUG(                            165) <= r_hit_pop;
          IF_DEBUG(                            166) <= r_miss_pop;
          IF_DEBUG(                            167) <= r_pop_safe;
          IF_DEBUG(                            168) <= r_hit_refresh;
          IF_DEBUG(                            169) <= r_miss_refresh;
  
          IF_DEBUG(                            170) <= r_hit_fifo_almost_full;
          IF_DEBUG(                            171) <= r_hit_fifo_full;
          IF_DEBUG(                            172) <= r_hit_fifo_almost_empty;
          IF_DEBUG(                            173) <= r_hit_fifo_empty;
          IF_DEBUG(                            174) <= r_hit_line_fit;
          IF_DEBUG(                            175) <= r_miss_fifo_almost_full;
          IF_DEBUG(                            176) <= r_miss_fifo_full;
          IF_DEBUG(                            177) <= r_miss_fifo_almost_empty;
          IF_DEBUG(                            178) <= r_miss_fifo_empty;
          IF_DEBUG(                            179) <= r_miss_line_fit;
  
          IF_DEBUG(                            180) <= ri_assert;
          IF_DEBUG(                            181) <= rip_assert;
          IF_DEBUG(                            182) <= assert_err(C_ASSERT_NO_RI_INFO);
  
          IF_DEBUG(124 + 6          - 1 downto 124) <= (others=>'0');
          IF_DEBUG(130 + 6          - 1 downto 130) <= (others=>'0');
          IF_DEBUG(136 + 4          - 1 downto 136) <= (others=>'0');
          IF_DEBUG(140 + 6          - 1 downto 140) <= (others=>'0');
          IF_DEBUG(146 + 4          - 1 downto 146) <= (others=>'0');
          IF_DEBUG(124 + C_MY_DQ    - 1 downto 124) <= ri_read_fifo_addr(C_MY_DQ - 1 downto 0);
          IF_DEBUG(130 + C_MY_HQ    - 1 downto 130) <= r_hit_write_fifo_addr(C_MY_HQ - 1 downto 0);
          IF_DEBUG(136 + C_MY_MQ    - 1 downto 136) <= r_miss_write_fifo_addr(C_MY_MQ - 1 downto 0);
          IF_DEBUG(140 + C_MY_HQ    - 1 downto 140) <= r_hit_read_fifo_addr(C_MY_HQ - 1 downto 0);
          IF_DEBUG(146 + C_MY_MQ    - 1 downto 146) <= r_miss_read_fifo_addr(C_MY_MQ - 1 downto 0);
          IF_DEBUG(                            150) <= rk_empty;
          IF_DEBUG(                            151) <= read_data_fud_is_dead;
          IF_DEBUG(                            152) <= read_data_fetch_line_match_i;
          IF_DEBUG(                            153) <= read_data_req_line_match_i;
          IF_DEBUG(                            154) <= read_data_act_line_match_i;
          
          
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
    assert_err(C_ASSERT_COLLIDING_DATA)   <= ( lookup_read_data_valid and update_read_data_valid ) when
                                                  C_USE_ASSERTIONS else
                                             '0';
    
    -- Detect condition
    assert_err(C_ASSERT_RIP_QUEUE_ERROR)  <= rip_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_RI_QUEUE_ERROR)   <= ri_assert  when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_NO_RIP_INFO)      <= ( lookup_read_data_valid or 
                                               update_read_data_valid ) and not rip_exist when 
                                                  C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_NO_RI_INFO)       <= ( not r_hit_fifo_empty or 
                                               not r_miss_fifo_empty ) and not ri_exist when 
                                                  C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_RON_QUEUE_ERROR)  <= ron_assert when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_COLLIDING_DATA) /= '1' 
      report "AXI R Channel: Read data collision, multiple sources are streaming data simultaneously."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_RIP_QUEUE_ERROR) /= '1' 
      report "AXI R Channel: Erroneous handling of RIP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_RI_QUEUE_ERROR) /= '1' 
      report "AXI R Channel: Erroneous handling of RI Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_NO_RIP_INFO) /= '1' 
      report "AXI R Channel: No RIP Information available when read data arrives."
        severity error;
    
    assert assert_err_1(C_ASSERT_NO_RI_INFO) /= '1' 
      report "AXI R Channel: No RI Information available when read data present."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_RON_QUEUE_ERROR) /= '1' 
      report "AXI R Channel: Erroneous handling of RON Queue, read from empty or push to full."
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
  
  
end architecture IMP;



