-------------------------------------------------------------------------------
-- sc_s_axi_gen_interface.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_gen_interface.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_gen_interface.vhd
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


entity sc_s_axi_gen_interface is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    C_USE_ASSERTIONS          : boolean                       := false;
    C_USE_STATISTICS          : boolean                       := false;
    C_STAT_GEN_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_GEN_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
    C_STAT_BITS               : natural range  1 to   64      := 32;
    C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
    C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
    C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
    C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
    
    -- AXI4 Interface Specific.
    C_S_AXI_BASEADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
    C_S_AXI_HIGHADDR          : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
    C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_S_AXI_ADDR_WIDTH        : natural                       := 32;
    C_S_AXI_ID_WIDTH          : natural                       :=  4;
    C_S_AXI_FORCE_READ_ALLOCATE     : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_READ_ALLOCATE  : natural range  0 to    1      :=  0;
    C_S_AXI_FORCE_WRITE_ALLOCATE    : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_WRITE_ALLOCATE : natural range  0 to    1      :=  0;
    C_S_AXI_FORCE_READ_BUFFER       : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_READ_BUFFER    : natural range  0 to    1      :=  0;
    C_S_AXI_FORCE_WRITE_BUFFER      : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_WRITE_BUFFER   : natural range  0 to    1      :=  0;
    C_S_AXI_PROHIBIT_EXCLUSIVE      : natural range  0 to    1      :=  1;
    
    -- Data type and settings specific.
    C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
    C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
    C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
    C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
    
    -- Lx Cache Specific.
    C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
    C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
    C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
    C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
    C_Lx_ADDR_OFFSET_HI       : natural range  2 to   63      :=  6;
    C_Lx_ADDR_OFFSET_LO       : natural range  0 to   63      :=  0;
    C_Lx_ADDR_BYTE_HI         : natural range  0 to   63      :=  1;
    C_Lx_ADDR_BYTE_LO         : natural range  0 to   63      :=  0;
    C_Lx_CACHE_SIZE           : natural                       := 1024;
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
    
    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- System Cache Specific.
    C_PIPELINE_LU_READ_DATA   : boolean                       := false;
    C_ID_WIDTH                : natural range  1 to   32      :=  4;
    C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_PORTS               : natural range  1 to   32      :=  1;
    C_PORT_NUM                : natural range  0 to   32      :=  0;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
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
    S_AXI_AWID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_AWADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_AWLEN               : in  std_logic_vector(7 downto 0);
    S_AXI_AWSIZE              : in  std_logic_vector(2 downto 0);
    S_AXI_AWBURST             : in  std_logic_vector(1 downto 0);
    S_AXI_AWLOCK              : in  std_logic;
    S_AXI_AWCACHE             : in  std_logic_vector(3 downto 0);
    S_AXI_AWPROT              : in  std_logic_vector(2 downto 0);
    S_AXI_AWQOS               : in  std_logic_vector(3 downto 0);
    S_AXI_AWVALID             : in  std_logic;
    S_AXI_AWREADY             : out std_logic;
    S_AXI_AWUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD 

    -- W-Channel
    S_AXI_WDATA               : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_WSTRB               : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    S_AXI_WLAST               : in  std_logic;
    S_AXI_WVALID              : in  std_logic;
    S_AXI_WREADY              : out std_logic;

    -- B-Channel
    S_AXI_BRESP               : out std_logic_vector(1 downto 0);
    S_AXI_BID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_BVALID              : out std_logic;
    S_AXI_BREADY              : in  std_logic;

    -- AR-Channel
    S_AXI_ARID                : in  std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_ARADDR              : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_ARLEN               : in  std_logic_vector(7 downto 0);
    S_AXI_ARSIZE              : in  std_logic_vector(2 downto 0);
    S_AXI_ARBURST             : in  std_logic_vector(1 downto 0);
    S_AXI_ARLOCK              : in  std_logic;
    S_AXI_ARCACHE             : in  std_logic_vector(3 downto 0);
    S_AXI_ARPROT              : in  std_logic_vector(2 downto 0);
    S_AXI_ARQOS               : in  std_logic_vector(3 downto 0);
    S_AXI_ARVALID             : in  std_logic;
    S_AXI_ARREADY             : out std_logic;
    S_AXI_ARUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD 

    -- R-Channel
    S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP               : out std_logic_vector(1 downto 0);
    S_AXI_RLAST               : out std_logic;
    S_AXI_RVALID              : out std_logic;
    S_AXI_RREADY              : in  std_logic;
    
    
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
    -- Internal Interface Signals (Snoop communication).
    
    snoop_fetch_piperun       : in  std_logic;
    snoop_fetch_valid         : in  std_logic;
    snoop_fetch_addr          : in  AXI_ADDR_TYPE;
    snoop_fetch_myself        : in  std_logic;
    snoop_fetch_sync          : in  std_logic;
    snoop_fetch_pos_hazard    : out std_logic;
    
    snoop_req_piperun         : in  std_logic;
    snoop_req_valid           : in  std_logic;
    snoop_req_write           : in  std_logic;
    snoop_req_size            : in  AXI_SIZE_TYPE;
    snoop_req_addr            : in  AXI_ADDR_TYPE;
    snoop_req_snoop           : in  AXI_SNOOP_TYPE;
    snoop_req_myself          : in  std_logic;
    snoop_req_always          : in  std_logic;
    snoop_req_update_filter   : in  std_logic;
    snoop_req_want            : in  std_logic;
    snoop_req_complete        : in  std_logic;
    snoop_req_complete_target : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    snoop_act_piperun         : in  std_logic;
    snoop_act_valid           : in  std_logic;
    snoop_act_waiting_4_pipe  : in  std_logic;
    snoop_act_write           : in  std_logic;
    snoop_act_addr            : in  AXI_ADDR_TYPE;
    snoop_act_prot            : in  AXI_PROT_TYPE;
    snoop_act_snoop           : in  AXI_SNOOP_TYPE;
    snoop_act_myself          : in  std_logic;
    snoop_act_always          : in  std_logic;
    snoop_act_tag_valid       : out std_logic;
    snoop_act_tag_unique      : out std_logic;
    snoop_act_tag_dirty       : out std_logic;
    snoop_act_done            : out std_logic;
    snoop_act_use_external    : out std_logic;
    snoop_act_write_blocking  : out std_logic;
    
    snoop_info_tag_valid      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_info_tag_unique     : out std_logic;
    snoop_info_tag_dirty      : out std_logic;
    
    snoop_resp_valid          : out std_logic;
    snoop_resp_crresp         : out AXI_CRRESP_TYPE;
    snoop_resp_ready          : in  std_logic;
    
    read_data_ex_rack         : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write Data).
    
    wr_port_data_valid        : out std_logic;
    wr_port_data_last         : out std_logic;
    wr_port_data_be           : out std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
    wr_port_data_word         : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
    wr_port_data_ready        : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write response).
    
    access_bp_push            : in  std_logic;
    access_bp_early           : in  std_logic;
    
    update_ext_bresp_valid    : in  std_logic;
    update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
    update_ext_bresp_ready    : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read request).
    
    lookup_read_data_new      : in  std_logic;
    lookup_read_data_hit      : in  std_logic;
    lookup_read_data_snoop    : in  std_logic;
    lookup_read_data_allocate : in  std_logic;
    
    
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
    
    stat_reset                      : in  std_logic;
    stat_enable                     : in  std_logic;
    
    stat_s_axi_gen_rd_segments      : out STAT_POINT_TYPE; -- Per transaction
    stat_s_axi_gen_wr_segments      : out STAT_POINT_TYPE; -- Per transaction
    stat_s_axi_gen_rip              : out STAT_FIFO_TYPE;
    stat_s_axi_gen_r                : out STAT_FIFO_TYPE;
    stat_s_axi_gen_bip              : out STAT_FIFO_TYPE;
    stat_s_axi_gen_bp               : out STAT_FIFO_TYPE;
    stat_s_axi_gen_wip              : out STAT_FIFO_TYPE;
    stat_s_axi_gen_w                : out STAT_FIFO_TYPE;
    stat_s_axi_gen_rd_latency       : out STAT_POINT_TYPE;
    stat_s_axi_gen_wr_latency       : out STAT_POINT_TYPE;
    stat_s_axi_gen_rd_latency_conf  : in  STAT_CONF_TYPE;
    stat_s_axi_gen_wr_latency_conf  : in  STAT_CONF_TYPE;
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_gen_interface;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_gen_interface is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Top level for the Generic AXI4 port. No actual logic only connection
  -- between the different AXI channel modules.
  -- 
  --  ____                          ___________         
  -- | W  |----------------------->| W Channel |------------------------->
  -- |____|                        |___________|        
  --                                      ^
  --  ____            ___________         |
  -- | AW |--------->| A Channel |--------+          
  -- |____|          |___________|        |
  --                                      v
  --  ____                          ___________ 
  -- | B  |<-----------------------| B Channel |<-------------------------
  -- |____|                        |___________|
  -- 
  --  ____                          ___________ 
  -- | R  |<-----------------------| R Channel |<-------------------------
  -- |____|                        |___________|
  --                                      ^
  --  ____            ___________         |
  -- | AR |--------->| A Channel |--------|              
  -- |____|          |___________|  
  -- 
  -- 
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_W_CHANNEL_ERROR           : natural :=  0;
  constant C_ASSERT_B_CHANNEL_ERROR           : natural :=  1;
  constant C_ASSERT_R_CHANNEL_ERROR           : natural :=  2;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  3;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  constant C_REAL_CACHE_LINE_LENGTH   : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_CACHE_LINE_LENGTH, 
                                                                               C_CACHE_LINE_LENGTH);
  constant C_REAL_ADDR_LINE_HI        : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_LINE_HI,
                                                                               C_ADDR_LINE_HI);
  constant C_REAL_ADDR_LINE_LO        : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_LINE_LO,
                                                                               C_ADDR_LINE_LO);
  constant C_REAL_ADDR_OFFSET_HI      : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_OFFSET_HI,
                                                                               C_ADDR_OFFSET_HI);
  constant C_REAL_ADDR_OFFSET_LO      : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_OFFSET_LO,
                                                                               C_ADDR_OFFSET_LO);
  constant C_REAL_ADDR_BYTE_HI        : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_BYTE_HI,
                                                                               C_ADDR_BYTE_HI);
  constant C_REAL_ADDR_BYTE_LO        : natural := sel(C_ENABLE_COHERENCY = 1, C_Lx_ADDR_BYTE_LO,
                                                                               C_ADDR_BYTE_LO);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  
  -- Address related.
  subtype C_ADDR_LINE_POS             is natural range C_REAL_ADDR_LINE_HI    downto C_REAL_ADDR_LINE_LO;
  subtype C_ADDR_OFFSET_POS           is natural range C_REAL_ADDR_OFFSET_HI  downto C_REAL_ADDR_OFFSET_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_REAL_ADDR_BYTE_HI    downto C_REAL_ADDR_BYTE_LO;
  
  -- Subtypes for address parts.
  subtype ADDR_LINE_TYPE              is std_logic_vector(C_ADDR_LINE_POS);
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  -- Address related.
  subtype C_Lx_ADDR_DIRECT_POS        is natural range C_Lx_ADDR_DIRECT_HI    downto C_Lx_ADDR_DIRECT_LO;
  subtype C_Lx_ADDR_LINE_POS          is natural range C_Lx_ADDR_LINE_HI      downto C_Lx_ADDR_LINE_LO;
  subtype C_Lx_ADDR_OFFSET_POS        is natural range C_Lx_ADDR_OFFSET_HI    downto C_Lx_ADDR_OFFSET_LO;
  subtype C_Lx_ADDR_BYTE_POS          is natural range C_Lx_ADDR_BYTE_HI      downto C_Lx_ADDR_BYTE_LO;
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Size)
  -----------------------------------------------------------------------------
  
  -- Size related.
  subtype C_BYTE_MASK_POS             is natural range C_ADDR_OFFSET_HI + 7 downto 7;
  subtype C_HALF_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 6 downto 6;
  subtype C_WORD_MASK_POS             is natural range C_ADDR_OFFSET_HI + 5 downto 5;
  subtype C_DOUBLE_WORD_MASK_POS      is natural range C_ADDR_OFFSET_HI + 4 downto 4;
  subtype C_QUAD_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 3 downto 3;
  subtype C_OCTA_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 2 downto 2;
  subtype C_HEXADECA_WORD_MASK_POS    is natural range C_ADDR_OFFSET_HI + 1 downto 1;
  subtype C_TRIACONTADI_MASK_POS      is natural range C_ADDR_OFFSET_HI + 0 downto 0;
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ADDR_OFFSET_BITS         : natural := C_ADDR_OFFSET_HI - C_ADDR_OFFSET_LO + 1;
  constant C_ADDR_BYTE_BITS           : natural := C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1;
  
  constant C_LEN_WIDTH                : natural := 8;
  constant C_REST_WIDTH               : natural := Log2(C_CACHE_DATA_WIDTH/8);
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component sc_s_axi_a_channel is
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
      C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
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
      C_ID_WIDTH                : natural range  1 to   32      :=  4;
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
  end component sc_s_axi_a_channel;
  
  component sc_s_axi_w_channel is
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
      
      -- AXI4 Interface Specific.
      C_S_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      
      -- Data type and settings specific.
      C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
      C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
      
      -- System Cache Specific.
      C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- AXI4 Slave Interface Signals.
      
      -- W-Channel
      S_AXI_WDATA               : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_WSTRB               : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      S_AXI_WLAST               : in  std_logic;
      S_AXI_WVALID              : in  std_logic;
      S_AXI_WREADY              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write data).
      
      wr_valid                  : in  std_logic;
      wr_last                   : in  std_logic;
      wr_failed                 : in  std_logic;
      wr_offset                 : in  std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
      wr_stp                    : in  std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
      wr_use                    : in  std_logic_vector(C_ADDR_BYTE_HI downto C_ADDR_BYTE_LO);
      wr_len                    : in  AXI_LENGTH_TYPE;
      wr_ready                  : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        : out std_logic;
      wr_port_data_last         : out std_logic;
      wr_port_data_be           : out std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
      wr_port_data_word         : out std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
      wr_port_data_ready        : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Synchronization).
      
      wc_valid                  : out std_logic;
      wc_ready                  : in  std_logic;
      
      write_fail_completed      : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      stat_s_axi_wip            : out STAT_FIFO_TYPE;
      stat_s_axi_w              : out STAT_FIFO_TYPE;
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  : out std_logic_vector(255 downto 0)
    );
  end component sc_s_axi_w_channel;
  
  component sc_s_axi_b_channel is
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
      
      -- AXI4 Interface Specific.
      C_S_AXI_ID_WIDTH          : natural                       :=  4
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- B-Channel
      S_AXI_BRESP               : out std_logic_vector(1 downto 0);
      S_AXI_BID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_BVALID              : out std_logic;
      S_AXI_BREADY              : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Write Response Information Interface Signals.
      
      write_req_valid           : in  std_logic;
      write_req_ID              : in  std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
      write_req_last            : in  std_logic;
      write_req_failed          : in  std_logic;
      write_req_ready           : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_ready             : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Synchronization).
      
      wc_valid                  : in  std_logic;
      wc_ready                  : out std_logic;
      
      write_fail_completed      : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write response).
      
      access_bp_push            : in  std_logic;
      access_bp_early           : in  std_logic;
      
      update_ext_bresp_valid    : in  std_logic;
      update_ext_bresp          : in  std_logic_vector(2 - 1 downto 0);
      update_ext_bresp_ready    : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      stat_s_axi_bip            : out STAT_FIFO_TYPE;
      stat_s_axi_bp             : out STAT_FIFO_TYPE;
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              : out std_logic;
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  : out std_logic_vector(255 downto 0)
    );
  end component sc_s_axi_b_channel;
  
  component sc_s_axi_r_channel is
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
      S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      S_AXI_RRESP               : out std_logic_vector(C_S_AXI_RESP_WIDTH-1 downto 0);
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
  end component sc_s_axi_r_channel;
  
  component sc_stat_latency is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      
      -- Configuration.
      C_STAT_LATENCY_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_LATENCY_WR_DEPTH   : natural range  1 to   32      := 16;
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
      
      ar_start                  : in  std_logic;
      ar_ack                    : in  std_logic;
      rd_valid                  : in  std_logic;
      rd_last                   : in  std_logic;
      aw_start                  : in  std_logic;
      aw_ack                    : in  std_logic;
      wr_valid                  : in  std_logic;
      wr_last                   : in  std_logic;
      wr_resp                   : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_enable               : in  std_logic;
      
      stat_rd_latency           : out STAT_POINT_TYPE;    -- External Read Latency
      stat_wr_latency           : out STAT_POINT_TYPE;    -- External Write Latency
      stat_rd_latency_conf      : in  STAT_CONF_TYPE;     -- External Read Latency Configuration
      stat_wr_latency_conf      : in  STAT_CONF_TYPE      -- External Write Latency Configuration
    );
  end component sc_stat_latency;
  
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
  -- Control AW-Channel
  
  signal AWIF_DEBUG                 : std_logic_vector(255 downto 0);
  signal S_AXI_AWREADY_I            : std_logic;
  
  
  -- ----------------------------------------
  -- Control AW-Channel
  
  signal ARIF_DEBUG                 : std_logic_vector(255 downto 0);
  signal S_AXI_ARREADY_I            : std_logic;
  
  
  -- ----------------------------------------
  -- Control W-Channel
  
  signal wr_valid                   : std_logic;
  signal wr_last                    : std_logic;
  signal wr_failed                  : std_logic;
  signal wr_offset                  : ADDR_BYTE_TYPE;
  signal wr_stp                     : ADDR_BYTE_TYPE;
  signal wr_use                     : ADDR_BYTE_TYPE;
  signal wr_len                     : AXI_LENGTH_TYPE;
  signal wr_ready                   : std_logic;
  signal wc_valid                   : std_logic;
  signal wc_ready                   : std_logic;
  signal write_fail_completed       : std_logic;
  signal WIF_DEBUG                  : std_logic_vector(255 downto 0);
  signal w_assert                   : std_logic;
  signal S_AXI_WREADY_I             : std_logic;
  
  
  -- ----------------------------------------
  -- Control B-Channel
  
  signal write_req_valid            : std_logic;
  signal write_req_ID               : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal write_req_last             : std_logic;
  signal write_req_failed           : std_logic;
  signal write_req_ready            : std_logic;
  signal BIF_DEBUG                  : std_logic_vector(255 downto 0);
  signal b_assert                   : std_logic;
  signal S_AXI_BVALID_I             : std_logic;
  
  
  -- ----------------------------------------
  -- Control R-Channel
  
  signal read_req_valid             : std_logic;
  signal read_req_ID                : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal read_req_last              : std_logic;
  signal read_req_failed            : std_logic;
  signal read_req_single            : std_logic;
  signal read_req_rest              : std_logic_vector(C_REST_WIDTH - 1 downto 0);
  signal read_req_offset            : ADDR_BYTE_TYPE;
  signal read_req_stp               : ADDR_BYTE_TYPE;
  signal read_req_use               : ADDR_BYTE_TYPE;
  signal read_req_len               : std_logic_vector(C_LEN_WIDTH - 1  downto 0);
  signal read_req_ready             : std_logic;
  signal RIF_DEBUG                  : std_logic_vector(255 downto 0);
  signal r_assert                   : std_logic;
  signal S_AXI_RVALID_I             : std_logic;
  signal S_AXI_RLAST_I              : std_logic;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  
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
  -- AW-Channel
  -----------------------------------------------------------------------------
  
  AW_Channel: sc_s_axi_a_channel
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- AXI4 Interface Specific.
      C_S_AXI_BASEADDR          => C_S_AXI_BASEADDR,
      C_S_AXI_HIGHADDR          => C_S_AXI_HIGHADDR,
      C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH,
      C_S_AXI_FORCE_ALLOCATE    => C_S_AXI_FORCE_WRITE_ALLOCATE,
      C_S_AXI_PROHIBIT_ALLOCATE => C_S_AXI_PROHIBIT_WRITE_ALLOCATE,
      C_S_AXI_FORCE_BUFFER      => C_S_AXI_FORCE_WRITE_BUFFER,
      C_S_AXI_PROHIBIT_BUFFER   => C_S_AXI_PROHIBIT_WRITE_BUFFER,
      C_S_AXI_PROHIBIT_EXCLUSIVE=> C_S_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Configuration.
      C_IS_READ                 => 0,
      C_LEN_WIDTH               => C_LEN_WIDTH,
      C_REST_WIDTH              => C_REST_WIDTH,
      
      -- Data type and settings specific.
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      
      -- PARD Specific.
      C_DSID_WIDTH              => C_DSID_WIDTH,
      
      -- System Cache Specific.
      C_ID_WIDTH                => C_ID_WIDTH,
      C_CACHE_LINE_LENGTH       => C_REAL_CACHE_LINE_LENGTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
  
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- AW-Channel
      S_AXI_AID                 => S_AXI_AWID,
      S_AXI_AADDR               => S_AXI_AWADDR,
      S_AXI_ALEN                => S_AXI_AWLEN,
      S_AXI_ASIZE               => S_AXI_AWSIZE,
      S_AXI_ABURST              => S_AXI_AWBURST,
      S_AXI_ALOCK               => S_AXI_AWLOCK,
      S_AXI_ACACHE              => S_AXI_AWCACHE,
      S_AXI_APROT               => S_AXI_AWPROT,
      S_AXI_AQOS                => S_AXI_AWQOS,
      S_AXI_AVALID              => S_AXI_AWVALID,
      S_AXI_AREADY              => S_AXI_AWREADY_I,
      S_AXI_AUSER               => S_AXI_AWUSER,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write data).
      
      wr_valid                  => wr_valid,
      wr_last                   => wr_last,
      wr_failed                 => wr_failed,
      wr_offset                 => wr_offset,
      wr_stp                    => wr_stp,
      wr_use                    => wr_use,
      wr_len                    => wr_len,
      wr_ready                  => wr_ready,
      
      
      -- ---------------------------------------------------
      -- Write Response Information Interface Signals.
      
      write_req_valid           => write_req_valid,
      write_req_ID              => write_req_ID,
      write_req_last            => write_req_last,
      write_req_failed          => write_req_failed,
      write_req_ready           => write_req_ready,
      
      
      -- ---------------------------------------------------
      -- Read Information Interface Signals.
      
      read_req_valid            => open,
      read_req_ID               => open,
      read_req_last             => open,
      read_req_failed           => open,
      read_req_single           => open,
      read_req_rest             => open,
      read_req_offset           => open,
      read_req_stp              => open,
      read_req_use              => open,
      read_req_len              => open,
      read_req_ready            => '1',
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      arbiter_piperun           => arbiter_piperun,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            => wr_port_access,
      wr_port_id                => wr_port_id,
      wr_port_ready             => wr_port_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            => open,
      rd_port_id                => open,
      rd_port_ready             => rd_port_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_gen_segments   => stat_s_axi_gen_wr_segments,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => AWIF_DEBUG
    );
  
  S_AXI_AWREADY <= S_AXI_AWREADY_I;
  
  
  -----------------------------------------------------------------------------
  -- AR-Channel
  -----------------------------------------------------------------------------
  
  AR_Channel: sc_s_axi_a_channel
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_DEBUG               => C_USE_DEBUG,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- AXI4 Interface Specific.
      C_S_AXI_BASEADDR          => C_S_AXI_BASEADDR,
      C_S_AXI_HIGHADDR          => C_S_AXI_HIGHADDR,
      C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
      C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH,
      C_S_AXI_FORCE_ALLOCATE    => C_S_AXI_FORCE_READ_ALLOCATE,
      C_S_AXI_PROHIBIT_ALLOCATE => C_S_AXI_PROHIBIT_READ_ALLOCATE,
      C_S_AXI_FORCE_BUFFER      => C_S_AXI_FORCE_READ_BUFFER,
      C_S_AXI_PROHIBIT_BUFFER   => C_S_AXI_PROHIBIT_READ_BUFFER,
      C_S_AXI_PROHIBIT_EXCLUSIVE=> C_S_AXI_PROHIBIT_EXCLUSIVE,
      
      -- Configuration.
      C_IS_READ                 => 1,
      C_LEN_WIDTH               => C_LEN_WIDTH,
      C_REST_WIDTH              => C_REST_WIDTH,
      
      -- Data type and settings specific.
      C_ADDR_LINE_HI            => C_ADDR_LINE_POS'high,
      C_ADDR_LINE_LO            => C_ADDR_LINE_POS'low,
      C_ADDR_OFFSET_HI          => C_ADDR_OFFSET_POS'high,
      C_ADDR_OFFSET_LO          => C_ADDR_OFFSET_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      
      -- PARD Specific.
      C_DSID_WIDTH              => C_DSID_WIDTH,
      
      -- System Cache Specific.
      C_ID_WIDTH                => C_ID_WIDTH,
      C_CACHE_LINE_LENGTH       => C_REAL_CACHE_LINE_LENGTH,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
  
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- AW-Channel
      S_AXI_AID                 => S_AXI_ARID,
      S_AXI_AADDR               => S_AXI_ARADDR,
      S_AXI_ALEN                => S_AXI_ARLEN,
      S_AXI_ASIZE               => S_AXI_ARSIZE,
      S_AXI_ABURST              => S_AXI_ARBURST,
      S_AXI_ALOCK               => S_AXI_ARLOCK,
      S_AXI_ACACHE              => S_AXI_ARCACHE,
      S_AXI_APROT               => S_AXI_ARPROT,
      S_AXI_AQOS                => S_AXI_ARQOS,
      S_AXI_AVALID              => S_AXI_ARVALID,
      S_AXI_AREADY              => S_AXI_ARREADY_I,
      S_AXI_AUSER               => S_AXI_ARUSER,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write data).
      
      wr_valid                  => open,
      wr_last                   => open,
      wr_failed                 => open,
      wr_offset                 => open,
      wr_stp                    => open,
      wr_use                    => open,
      wr_len                    => open,
      wr_ready                  => '1',
      
      
      -- ---------------------------------------------------
      -- Write Response Information Interface Signals.
      
      write_req_valid           => open,
      write_req_ID              => open,
      write_req_last            => open,
      write_req_failed          => open,
      write_req_ready           => '1',
      
      
      -- ---------------------------------------------------
      -- Read Information Interface Signals.
      
      read_req_valid            => read_req_valid,
      read_req_ID               => read_req_ID,
      read_req_last             => read_req_last,
      read_req_failed           => read_req_failed,
      read_req_single           => read_req_single,
      read_req_rest             => read_req_rest,
      read_req_offset           => read_req_offset,
      read_req_stp              => read_req_stp,
      read_req_use              => read_req_use,
      read_req_len              => read_req_len,
      read_req_ready            => read_req_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (All request).
      
      arbiter_piperun           => arbiter_piperun,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_access            => open,
      wr_port_id                => open,
      wr_port_ready             => wr_port_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_access            => rd_port_access,
      rd_port_id                => rd_port_id,
      rd_port_ready             => rd_port_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_gen_segments   => stat_s_axi_gen_rd_segments,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => ARIF_DEBUG
    );
  
  S_AXI_ARREADY <= S_AXI_ARREADY_I;
  
  
  -----------------------------------------------------------------------------
  -- Control W-Channel
  -----------------------------------------------------------------------------
  
  W_Channel: sc_s_axi_w_channel
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
      
      -- AXI4 Interface Specific.
      C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
      
      -- Data type and settings specific.
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      
      -- System Cache Specific.
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
      
      -- ---------------------------------------------------
      -- AXI4 Slave Interface Signals.
      
      -- W-Channel
      S_AXI_WDATA               => S_AXI_WDATA,
      S_AXI_WSTRB               => S_AXI_WSTRB,
      S_AXI_WLAST               => S_AXI_WLAST,
      S_AXI_WVALID              => S_AXI_WVALID,
      S_AXI_WREADY              => S_AXI_WREADY_I,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write data).
      
      wr_valid                  => wr_valid,
      wr_last                   => wr_last,
      wr_failed                 => wr_failed,
      wr_offset                 => wr_offset,
      wr_stp                    => wr_stp,
      wr_use                    => wr_use,
      wr_len                    => wr_len,
      wr_ready                  => wr_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write Data).
      
      wr_port_data_valid        => wr_port_data_valid,
      wr_port_data_last         => wr_port_data_last,
      wr_port_data_be           => wr_port_data_be,
      wr_port_data_word         => wr_port_data_word,
      wr_port_data_ready        => wr_port_data_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Synchronization).
      
      wc_valid                  => wc_valid,
      wc_ready                  => wc_ready,
      
      write_fail_completed      => write_fail_completed,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_wip            => stat_s_axi_gen_wip,
      stat_s_axi_w              => stat_s_axi_gen_w,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => w_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => WIF_DEBUG
    );
  
  S_AXI_WREADY  <= S_AXI_WREADY_I;
  
  
  -----------------------------------------------------------------------------
  -- Control B-Channel
  -----------------------------------------------------------------------------
  
  B_Channel: sc_s_axi_b_channel
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
      
      -- AXI4 Interface Specific.
      C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
      
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- B-Channel
      S_AXI_BRESP               => S_AXI_BRESP,
      S_AXI_BID                 => S_AXI_BID,
      S_AXI_BVALID              => S_AXI_BVALID_I,
      S_AXI_BREADY              => S_AXI_BREADY,
      
      
      -- ---------------------------------------------------
      -- Write Response Information Interface Signals.
      
      write_req_valid           => write_req_valid,
      write_req_ID              => write_req_ID,
      write_req_last            => write_req_last,
      write_req_failed          => write_req_failed,
      write_req_ready           => write_req_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write request).
      
      wr_port_ready             => wr_port_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Synchronization).
      
      wc_valid                  => wc_valid,
      wc_ready                  => wc_ready,
      
      write_fail_completed      => write_fail_completed,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Write response).
      
      access_bp_push            => access_bp_push,
      access_bp_early           => access_bp_early,
      
      update_ext_bresp_valid    => update_ext_bresp_valid,
      update_ext_bresp          => update_ext_bresp,
      update_ext_bresp_ready    => update_ext_bresp_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_bip            => stat_s_axi_gen_bip,
      stat_s_axi_bp             => stat_s_axi_gen_bp,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => b_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => BIF_DEBUG
    );
  
  S_AXI_BVALID  <= S_AXI_BVALID_I;
  
  
  -----------------------------------------------------------------------------
  -- Control R-Channel
  -----------------------------------------------------------------------------
  
  R_Channel: sc_s_axi_r_channel
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
      
      -- AXI4 Interface Specific.
      C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH,
      C_S_AXI_RESP_WIDTH        => 2,
      
      -- Configuration.
      C_SUPPORT_SUBSIZED        => true,
      C_LEN_WIDTH               => C_LEN_WIDTH,
      C_REST_WIDTH              => C_REST_WIDTH,
      
      -- Data type and settings specific.
      C_Lx_ADDR_DIRECT_HI       => C_Lx_ADDR_DIRECT_POS'high,
      C_Lx_ADDR_DIRECT_LO       => C_Lx_ADDR_DIRECT_POS'low,
      C_Lx_ADDR_LINE_HI         => C_Lx_ADDR_LINE_POS'high,
      C_Lx_ADDR_LINE_LO         => C_Lx_ADDR_LINE_POS'low,
      C_ADDR_BYTE_HI            => C_ADDR_BYTE_POS'high,
      C_ADDR_BYTE_LO            => C_ADDR_BYTE_POS'low,
      
      -- L1 Cache Specific.
      C_Lx_CACHE_LINE_LENGTH    => C_Lx_CACHE_LINE_LENGTH,
      
      -- System Cache Specific.
      C_PIPELINE_LU_READ_DATA   => C_PIPELINE_LU_READ_DATA,
      C_NUM_PARALLEL_SETS       => C_NUM_PARALLEL_SETS,
      C_CACHE_DATA_WIDTH        => C_CACHE_DATA_WIDTH,
      C_ENABLE_HAZARD_HANDLING  => 0,
      C_ENABLE_COHERENCY        => C_ENABLE_COHERENCY
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
      
      -- ---------------------------------------------------
      -- AXI4/ACE Slave Interface Signals.
      
      -- R-Channel
      S_AXI_RID                 => S_AXI_RID,
      S_AXI_RDATA               => S_AXI_RDATA,
      S_AXI_RRESP               => S_AXI_RRESP,
      S_AXI_RLAST               => S_AXI_RLAST_I,
      S_AXI_RVALID              => S_AXI_RVALID_I,
      S_AXI_RREADY              => S_AXI_RREADY,
      S_AXI_RACK                => '1',
      
      
      -- ---------------------------------------------------
      -- Read Information Interface Signals.
      
      read_req_valid            => read_req_valid,
      read_req_ID               => read_req_ID,
      read_req_last             => read_req_last,
      read_req_failed           => read_req_failed,
      read_req_single           => read_req_single,
      read_req_dvm              => '0',
      read_req_addr             => (C_Lx_ADDR_DIRECT_HI downto C_Lx_ADDR_DIRECT_LO=>'0'),
      read_req_rest             => read_req_rest,
      read_req_offset           => read_req_offset,
      read_req_stp              => read_req_stp,
      read_req_use              => read_req_use,
      read_req_len              => read_req_len,
      read_req_ready            => read_req_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      rd_port_ready             => rd_port_ready,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read request).
      
      lookup_read_data_new      => lookup_read_data_new,
      lookup_read_data_hit      => lookup_read_data_hit,
      lookup_read_data_snoop    => lookup_read_data_snoop,
      lookup_read_data_allocate => lookup_read_data_allocate,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Hazard).
      
      snoop_req_piperun         => '0',
      snoop_act_set_read_hazard => '0',
      snoop_act_rst_read_hazard => '0',
      snoop_act_read_hazard     => '0',
      snoop_act_kill_locked     => '0',
      snoop_act_kill_addr       => (C_Lx_ADDR_DIRECT_HI downto C_Lx_ADDR_DIRECT_LO=>'0'),
      
      read_data_fetch_addr      => (C_Lx_ADDR_DIRECT_HI downto C_Lx_ADDR_DIRECT_LO=>'0'),
      read_data_req_addr        => (C_Lx_ADDR_DIRECT_HI downto C_Lx_ADDR_DIRECT_LO=>'0'),
      read_data_act_addr        => (C_Lx_ADDR_DIRECT_HI downto C_Lx_ADDR_DIRECT_LO=>'0'),
      
      read_data_fetch_match     => open,
      read_data_req_match       => open,
      read_data_ongoing         => open,
      read_data_block_nested    => open,
      read_data_release_block   => open,
      read_data_fetch_line_match=> open,
      read_data_req_line_match  => open,
      read_data_act_line_match  => open,
      
      read_data_fud_we          => open,
      read_data_fud_addr        => open,
      read_data_fud_tag_valid   => open,
      read_data_fud_tag_unique  => open,
      read_data_fud_tag_dirty   => open,
      
      read_data_ex_rack         => open,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Read Data).
      
      read_info_almost_full     => read_info_almost_full,
      read_info_full            => read_info_full,
      read_data_hit_pop         => read_data_hit_pop,
      read_data_hit_almost_full => read_data_hit_almost_full,
      read_data_hit_full        => read_data_hit_full,
      read_data_hit_fit         => read_data_hit_fit,
      read_data_miss_full       => read_data_miss_full,
      
      
      -- ---------------------------------------------------
      -- Snoop signals (Read Data & response).
      
      snoop_read_data_valid     => snoop_read_data_valid,
      snoop_read_data_last      => snoop_read_data_last,
      snoop_read_data_resp      => snoop_read_data_resp,
      snoop_read_data_word      => snoop_read_data_word,
      snoop_read_data_ready     => snoop_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (Read Data).
      
      lookup_read_data_valid    => lookup_read_data_valid,
      lookup_read_data_last     => lookup_read_data_last,
      lookup_read_data_resp     => lookup_read_data_resp,
      lookup_read_data_set      => lookup_read_data_set,
      lookup_read_data_word     => lookup_read_data_word,
      lookup_read_data_ready    => lookup_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Update signals (Read Data).
      
      update_read_data_valid    => update_read_data_valid,
      update_read_data_last     => update_read_data_last,
      update_read_data_resp     => update_read_data_resp,
      update_read_data_word     => update_read_data_word,
      update_read_data_ready    => update_read_data_ready,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_rip            => stat_s_axi_gen_rip,
      stat_s_axi_r              => stat_s_axi_gen_r,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => r_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => RIF_DEBUG 
    );
  
  S_AXI_RVALID  <= S_AXI_RVALID_I;
  S_AXI_RLAST   <= S_AXI_RLAST_I;
  
  
  -----------------------------------------------------------------------------
  -- Coherency: Not supported
  -----------------------------------------------------------------------------
  
  snoop_fetch_pos_hazard    <= '0';
  snoop_act_tag_valid       <= '0';
  snoop_act_tag_unique      <= '0';
  snoop_act_tag_dirty       <= '0';
  snoop_act_done            <= '1';
  snoop_act_use_external    <= '0';
  snoop_act_write_blocking  <= '0';
  snoop_info_tag_unique     <= '0';
  snoop_info_tag_dirty      <= '0';
  
  snoop_resp_valid          <= '1';
  snoop_resp_crresp         <= (others=>'0');
  
  read_data_ex_rack         <= '0';
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_s_axi_gen_rd_latency       <= C_NULL_STAT_POINT;
    stat_s_axi_gen_wr_latency       <= C_NULL_STAT_POINT;
    
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    signal ar_start                   : std_logic;
    signal ar_done                    : std_logic;
    signal ar_ack                     : std_logic;
    signal rd_valid                   : std_logic;
    signal rd_last                    : std_logic;
    signal aw_start                   : std_logic;
    signal aw_done                    : std_logic;
    signal aw_ack                     : std_logic;
    signal wr_valid                   : std_logic;
    signal wr_last                    : std_logic;
    signal wr_resp                    : std_logic;
  begin
    
    -- Detect conditions.
    Trans_Handle : process (ACLK) is
    begin  -- process Trans_Handle
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( stat_reset = '1' ) then         -- synchronous reset (active high)
          ar_start  <= '0';
          ar_done   <= '0';
          ar_ack    <= '0';
          rd_valid  <= '0';
          rd_last   <= '0';
          aw_start  <= '0';
          aw_done   <= '0';
          aw_ack    <= '0';
          wr_valid  <= '0';
          wr_last   <= '0';
          wr_resp   <= '0';
          
        else
          ar_start  <= S_AXI_ARVALID  and not ar_done;
          ar_ack    <= S_AXI_ARVALID  and S_AXI_ARREADY_I;
          rd_valid  <= S_AXI_RVALID_I and S_AXI_RREADY;
          rd_last   <= S_AXI_RVALID_I and S_AXI_RREADY and S_AXI_RLAST_I;
          
          aw_start  <= S_AXI_AWVALID  and not aw_done;
          aw_ack    <= S_AXI_AWVALID  and S_AXI_AWREADY_I;
          wr_valid  <= S_AXI_WVALID   and S_AXI_WREADY_I;
          wr_last   <= S_AXI_WVALID   and S_AXI_WREADY_I and S_AXI_WLAST ;
          wr_resp   <= S_AXI_BVALID_I and S_AXI_BREADY;
          
          if( S_AXI_ARREADY_I = '1' ) then
            ar_done   <= '0';
          elsif( S_AXI_ARVALID = '1' ) then
            ar_done   <= '1';
          end if;
          
          if( S_AXI_AWREADY_I = '1' ) then
            aw_done   <= '0';
          elsif( S_AXI_AWVALID = '1' ) then
            aw_done   <= '1';
          end if;
          
        end if;
      end if;
    end process Trans_Handle;
    
    Latency_Inst: sc_stat_latency
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_LATENCY_RD_DEPTH   => C_STAT_GEN_LAT_RD_DEPTH,
        C_STAT_LATENCY_WR_DEPTH   => C_STAT_GEN_LAT_WR_DEPTH,
        C_STAT_BITS               => C_STAT_BITS,
        C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
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
        
        ar_start                  => ar_start,
        ar_ack                    => ar_ack,
        rd_valid                  => rd_valid,
        rd_last                   => rd_last,
        aw_start                  => aw_start,
        aw_ack                    => aw_ack,
        wr_valid                  => wr_valid,
        wr_last                   => wr_last,
        wr_resp                   => wr_resp,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_rd_latency           => stat_s_axi_gen_rd_latency,
        stat_wr_latency           => stat_s_axi_gen_wr_latency,
        stat_rd_latency_conf      => stat_s_axi_gen_rd_latency_conf,
        stat_wr_latency_conf      => stat_s_axi_gen_wr_latency_conf
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
  begin
--    IF_DEBUG(255 downto 128)  <= ARIF_DEBUG(127 downto   0);
--    IF_DEBUG(127 downto   0)  <= AWIF_DEBUG(127 downto   0);
--    IF_DEBUG(123 downto 0)  <= ARIF_DEBUG(123 downto 0);
--    IF_DEBUG(255 downto 124)  <= RIF_DEBUG(255 downto 124);
    IF_DEBUG  <= RIF_DEBUG;
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect behaviour
  
  Assertions: block
  begin
    -- Detect condition
    assert_err(C_ASSERT_W_CHANNEL_ERROR)  <= w_assert when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_B_CHANNEL_ERROR)  <= b_assert when C_USE_ASSERTIONS else '0';
    assert_err(C_ASSERT_R_CHANNEL_ERROR)  <= r_assert when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_W_CHANNEL_ERROR) /= '1' 
      report "Generic AXI: W Channel error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_B_CHANNEL_ERROR) /= '1' 
      report "Generic AXI: B Channel error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_R_CHANNEL_ERROR) /= '1' 
      report "Generic AXI: R Channel error."
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






    
    
    
    
