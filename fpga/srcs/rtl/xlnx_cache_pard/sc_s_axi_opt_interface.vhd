-------------------------------------------------------------------------------
-- sc_s_axi_opt_interface.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_opt_interface.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_opt_interface.vhd
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

entity sc_s_axi_opt_interface is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    C_USE_ASSERTIONS          : boolean                       := false;
    C_USE_STATISTICS          : boolean                       := false;
    C_STAT_OPT_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_OPT_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
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
    C_S_AXI_SUPPORT_UNIQUE    : natural range  0 to    1      :=  1;
    C_S_AXI_SUPPORT_DIRTY     : natural range  0 to    1      :=  0;
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
    C_ADDR_DIRECT_HI          : natural range  4 to   63      := 27;
    C_ADDR_DIRECT_LO          : natural range  4 to   63      :=  7;
    C_ADDR_BYTE_HI            : natural range  0 to   63      :=  1;
    C_ADDR_BYTE_LO            : natural range  0 to   63      :=  0;
    C_Lx_ADDR_REQ_HI          : natural range  2 to   63      := 27;
    C_Lx_ADDR_REQ_LO          : natural range  2 to   63      :=  7;
    C_Lx_ADDR_DIRECT_HI       : natural range  4 to   63      := 27;
    C_Lx_ADDR_DIRECT_LO       : natural range  4 to   63      :=  7;
    C_Lx_ADDR_DATA_HI         : natural range  2 to   63      := 14;
    C_Lx_ADDR_DATA_LO         : natural range  2 to   63      :=  2;
    C_Lx_ADDR_TAG_HI          : natural range  4 to   63      := 27;
    C_Lx_ADDR_TAG_LO          : natural range  4 to   63      := 14;
    C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
    C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
    C_Lx_ADDR_OFFSET_HI       : natural range  2 to   63      :=  6;
    C_Lx_ADDR_OFFSET_LO       : natural range  0 to   63      :=  0;
    C_Lx_ADDR_WORD_HI         : natural range  2 to   63      :=  6;
    C_Lx_ADDR_WORD_LO         : natural range  2 to   63      :=  2;
    C_Lx_ADDR_BYTE_HI         : natural range  0 to   63      :=  1;
    C_Lx_ADDR_BYTE_LO         : natural range  0 to   63      :=  0;
    
    -- Lx Cache Specific.
    C_Lx_CACHE_SIZE           : natural                       := 1024;
    C_Lx_CACHE_LINE_LENGTH    : natural range  4 to   16      :=  8;
    C_Lx_NUM_ADDR_TAG_BITS    : natural range  1 to   63      :=  8;

    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- System Cache Specific.
    C_PIPELINE_LU_READ_DATA   : boolean                       := false;
    C_ID_WIDTH                : natural range  1 to   32      :=  4;
    C_NUM_PARALLEL_SETS       : natural range  1 to   32      :=  1;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_PORTS               : natural range  1 to   32      :=  1;
    C_PORT_NUM                : natural range  0 to   31      :=  0;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 16;
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
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
    S_AXI_AWDOMAIN            : in  std_logic_vector(1 downto 0);                      -- For ACE
    S_AXI_AWSNOOP             : in  std_logic_vector(2 downto 0);                      -- For ACE
    S_AXI_AWBAR               : in  std_logic_vector(1 downto 0);                      -- For ACE
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
    S_AXI_WACK                : in  std_logic;                                         -- For ACE

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
    S_AXI_ARDOMAIN            : in  std_logic_vector(1 downto 0);                      -- For ACE
    S_AXI_ARSNOOP             : in  std_logic_vector(3 downto 0);                      -- For ACE
    S_AXI_ARBAR               : in  std_logic_vector(1 downto 0);                      -- For ACE
    S_AXI_ARUSER              : in  std_logic_vector(C_DSID_WIDTH-1 downto 0);         -- For PARD

    -- R-Channel
    S_AXI_RID                 : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
    S_AXI_RDATA               : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_RRESP               : out std_logic_vector(1+2*C_ENABLE_COHERENCY downto 0);
    S_AXI_RLAST               : out std_logic;
    S_AXI_RVALID              : out std_logic;
    S_AXI_RREADY              : in  std_logic;
    S_AXI_RACK                : in  std_logic;                                         -- For ACE

    -- AC-Channel (coherency only)
    S_AXI_ACVALID             : out std_logic;                                         -- For ACE
    S_AXI_ACADDR              : out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);   -- For ACE
    S_AXI_ACSNOOP             : out std_logic_vector(3 downto 0);                      -- For ACE
    S_AXI_ACPROT              : out std_logic_vector(2 downto 0);                      -- For ACE
    S_AXI_ACREADY             : in  std_logic;                                         -- For ACE

    -- CR-Channel (coherency only)
    S_AXI_CRVALID             : in  std_logic;                                         -- For ACE
    S_AXI_CRRESP              : in  std_logic_vector(4 downto 0);                      -- For ACE
    S_AXI_CRREADY             : out std_logic;                                         -- For ACE

    -- CD-Channel (coherency only)
    S_AXI_CDVALID             : in  std_logic;                                         -- For ACE
    S_AXI_CDDATA              : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);   -- For ACE
    S_AXI_CDLAST              : in  std_logic;                                         -- For ACE
    S_AXI_CDREADY             : out std_logic;                                         -- For ACE
    
    
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
    
    stat_s_axi_rd_segments          : out STAT_POINT_TYPE;
    stat_s_axi_wr_segments          : out STAT_POINT_TYPE;
    stat_s_axi_rip                  : out STAT_FIFO_TYPE;
    stat_s_axi_r                    : out STAT_FIFO_TYPE;
    stat_s_axi_bip                  : out STAT_FIFO_TYPE;
    stat_s_axi_bp                   : out STAT_FIFO_TYPE;
    stat_s_axi_wip                  : out STAT_FIFO_TYPE;
    stat_s_axi_w                    : out STAT_FIFO_TYPE;
    stat_s_axi_rd_latency           : out STAT_POINT_TYPE;
    stat_s_axi_wr_latency           : out STAT_POINT_TYPE;
    stat_s_axi_rd_latency_conf      : in  STAT_CONF_TYPE;
    stat_s_axi_wr_latency_conf      : in  STAT_CONF_TYPE;
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    IF_DEBUG                  : out std_logic_vector(255 downto 0)
  );
end entity sc_s_axi_opt_interface;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_opt_interface is

  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Optimized AXI4/ACE Slave port that only support MicroBlaze like 
  -- transactions, i.e. a MicroBlaze or any other IP that limit it self to
  -- the set of transactions that MicroBlaze can generate under the same  
  -- configuration. 
  -- 
  -- A number of FIFOs/Queues are used to improve throughput and communicate 
  -- between the AXI channels, when required.
  -- 
  -- 
  --  ____            ___________         
  -- | W  |--------->| W   Queue |--------+------------------------------>
  -- |____|          |___________|        |
  --                                      |
  --  ____            ___________         |
  -- | AW |-----+--->| WIP Queue |--------|          
  -- |____|     |    |___________|        
  --            |                         
  --            |     ___________         
  --            |--->| BIP Queue |--|
  --                 |___________|  |     
  --                                |     
  --  ____                          |     ___________ 
  -- | B  |<------------------------+----| BP Queue  |<-------------------
  -- |____|                              |___________|
  -- 
  --  ____          ___________ 
  -- | R  |<-------| R Channel |<-----------------------------------------
  -- |____|        |___________|
  --                     ^
  --  ____               |
  -- | AR |--------------|              
  -- |____|              
  -- 
  -- 
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_WIP_QUEUE_ERROR           : natural :=  0;
  constant C_ASSERT_W_QUEUE_ERROR             : natural :=  1;
  constant C_ASSERT_BIP_QUEUE_ERROR           : natural :=  2;
  constant C_ASSERT_BP_QUEUE_ERROR            : natural :=  3;
  constant C_ASSERT_R_CHANNEL_ERROR           : natural :=  4;
  constant C_ASSERT_SYNC_ERROR                : natural :=  5;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  6;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ADDR_BYTE_BITS           : natural := C_ADDR_BYTE_HI - C_ADDR_BYTE_LO + 1;
  
  constant C_LEN_WIDTH                : natural := C_ADDR_BYTE_BITS;
  constant C_REST_WIDTH               : natural := C_LEN_WIDTH;
  
  subtype C_LEN_POS                   is natural range C_LEN_WIDTH - 1 downto 0;
  subtype C_REST_POS                  is natural range C_REST_WIDTH - 1 downto 0;
  subtype LEN_TYPE                    is std_logic_vector(C_LEN_POS);
  subtype REST_TYPE                   is std_logic_vector(C_REST_POS);
  
  constant C_BYTE_LENGTH              : natural := 8 + Log2(C_S_AXI_DATA_WIDTH/8);
  constant C_ADDR_LENGTH_HI           : natural := C_BYTE_LENGTH - 1;
  constant C_ADDR_LENGTH_LO           : natural := C_ADDR_BYTE_LO;
  
  subtype C_ADDR_LENGTH_POS           is natural range C_ADDR_LENGTH_HI     downto C_ADDR_LENGTH_LO;
  
  subtype C_BYTE_MASK_POS             is natural range C_BYTE_LENGTH - 1 + 7 downto 7;
  subtype C_HALF_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 6 downto 6;
  subtype C_WORD_MASK_POS             is natural range C_BYTE_LENGTH - 1 + 5 downto 5;
  subtype C_DOUBLE_WORD_MASK_POS      is natural range C_BYTE_LENGTH - 1 + 4 downto 4;
  subtype C_QUAD_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 3 downto 3;
  subtype C_OCTA_WORD_MASK_POS        is natural range C_BYTE_LENGTH - 1 + 2 downto 2;
  subtype C_HEXADECA_WORD_MASK_POS    is natural range C_BYTE_LENGTH - 1 + 1 downto 1;
  subtype C_TRIACONTADI_MASK_POS      is natural range C_BYTE_LENGTH - 1 + 0 downto 0;
  
  
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  -- Types for AXI and port related signals (use S0 as reference, all has to be equal).
  constant C_RRESP_WIDTH              : integer             := 2 + 2*C_ENABLE_COHERENCY;
  
  subtype ID_TYPE                     is std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
  subtype RRESP_TYPE                  is std_logic_vector(C_RRESP_WIDTH - 1 downto 0);
  subtype CACHE_DATA_TYPE             is std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
  subtype BE_TYPE                     is std_logic_vector(C_S_AXI_DATA_WIDTH/8 - 1 downto 0);
  subtype DATA_TYPE                   is std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  
  constant C_STAT_ONE                 : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0) := 
                                                              std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
  
  -- Address bit parts
  subtype C_Lx_ADDR_REQ_POS           is natural range C_Lx_ADDR_REQ_HI           downto C_Lx_ADDR_REQ_LO;
  subtype C_Lx_ADDR_DIRECT_POS        is natural range C_Lx_ADDR_DIRECT_HI        downto C_Lx_ADDR_DIRECT_LO;
  subtype C_Lx_ADDR_DATA_POS          is natural range C_Lx_ADDR_DATA_HI          downto C_Lx_ADDR_DATA_LO;
  subtype C_Lx_ADDR_TAG_POS           is natural range C_Lx_ADDR_TAG_HI           downto C_Lx_ADDR_TAG_LO;
  subtype C_Lx_ADDR_LINE_POS          is natural range C_Lx_ADDR_LINE_HI          downto C_Lx_ADDR_LINE_LO;
  subtype C_Lx_ADDR_OFFSET_POS        is natural range C_Lx_ADDR_OFFSET_HI        downto C_Lx_ADDR_OFFSET_LO;
  subtype C_Lx_ADDR_WORD_POS          is natural range C_Lx_ADDR_WORD_HI          downto C_Lx_ADDR_WORD_LO;
  subtype C_Lx_ADDR_BYTE_POS          is natural range C_Lx_ADDR_BYTE_HI          downto C_Lx_ADDR_BYTE_LO;
  
  subtype Lx_ADDR_REQ_TYPE            is std_logic_vector(C_Lx_ADDR_REQ_POS);
  subtype Lx_ADDR_DIRECT_TYPE         is std_logic_vector(C_Lx_ADDR_DIRECT_POS);
  subtype Lx_ADDR_DATA_TYPE           is std_logic_vector(C_Lx_ADDR_DATA_POS);
  subtype Lx_ADDR_TAG_TYPE            is std_logic_vector(C_Lx_ADDR_TAG_POS);
  subtype Lx_ADDR_LINE_TYPE           is std_logic_vector(C_Lx_ADDR_LINE_POS);
  subtype Lx_ADDR_OFFSET_TYPE         is std_logic_vector(C_Lx_ADDR_OFFSET_POS);
  subtype Lx_ADDR_WORD_TYPE           is std_logic_vector(C_Lx_ADDR_WORD_POS);
  subtype Lx_ADDR_BYTE_TYPE           is std_logic_vector(C_Lx_ADDR_BYTE_POS);
  
  
  -- Ranges for TAG information parts.
  constant C_Lx_NUM_STATUS_BITS       : natural := 1 + 1 + C_S_AXI_SUPPORT_UNIQUE + C_S_AXI_SUPPORT_DIRTY;
  constant C_Lx_TAG_SIZE              : natural := C_Lx_NUM_ADDR_TAG_BITS + C_Lx_NUM_STATUS_BITS;
  constant C_Lx_TAG_UNIQUE_POS        : natural := C_Lx_NUM_ADDR_TAG_BITS + 0;
  constant C_Lx_TAG_DIRTY_POS         : natural := C_Lx_TAG_UNIQUE_POS    + C_S_AXI_SUPPORT_UNIQUE;
  constant C_Lx_TAG_LOCKED_POS        : natural := C_Lx_TAG_DIRTY_POS     + C_S_AXI_SUPPORT_DIRTY;
  constant C_Lx_TAG_VALID_POS         : natural := C_Lx_TAG_LOCKED_POS    + 1;
  subtype C_Lx_TAG_ADDR_POS           is natural range C_Lx_NUM_ADDR_TAG_BITS - 1 downto 0;
  subtype C_Lx_TAG_POS                is natural range C_Lx_TAG_SIZE - 1          downto 0;
  subtype Lx_TAG_ADDR_TYPE            is std_logic_vector(C_Lx_TAG_ADDR_POS);
  subtype Lx_TAG_TYPE                 is std_logic_vector(C_Lx_TAG_POS);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------

  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  -- Subtypes of the address from all points of view.
  
  -- Address related.
  subtype C_ADDR_DIRECT_POS           is natural range C_ADDR_DIRECT_HI     downto C_ADDR_DIRECT_LO;
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  
  -- Subtypes for address parts.
  subtype ADDR_DIRECT_TYPE            is std_logic_vector(C_ADDR_DIRECT_POS);
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Interface ratio.
  constant C_RATIO                    : natural := C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH;
  constant C_RATIO_BITS               : natural := Log2(C_RATIO);
  
  subtype C_RATIO_POS                 is natural range Log2(C_CACHE_DATA_WIDTH/8) - 1 downto Log2(C_S_AXI_DATA_WIDTH/8);
  subtype RATIO_TYPE                  is std_logic_vector(C_RATIO_POS);
  
  type WIP_TYPE is record
    Offset            : ADDR_BYTE_TYPE;
    Incr              : std_logic;
    Size              : AXI_SIZE_TYPE;
    Len               : AXI_LENGTH_TYPE;
  end record WIP_TYPE;
  
  type W_TYPE is record
    Last              : std_logic;
    BE                : BE_TYPE;
    Data              : DATA_TYPE;
  end record W_TYPE;
  
  type BP_TYPE is record
    Early             : std_logic;
  end record BP_TYPE;
  
  type BIP_TYPE is record
    ID                : ID_TYPE;
  end record BIP_TYPE;
  
  type ARI_TYPE is record
    Resp              : AXI_CRRESP_TYPE;
  end record ARI_TYPE;
  
  -- Empty data structures.
  constant C_NULL_WIP                 : WIP_TYPE := (Offset=>(others=>'0'), Incr=>'0', 
                                                     Size=>(others=>'0'), Len=>(others=>'0'));
  constant C_NULL_W                   : W_TYPE   := (Last=>'0', BE=>(others=>'0'), Data=>(others=>'0'));
  constant C_NULL_BP                  : BP_TYPE  := (Early=>'0');
  constant C_NULL_BIP                 : BIP_TYPE := (ID=>(others=>'0'));
  constant C_NULL_ARI                 : ARI_TYPE := (Resp=>(others=>'0'));
  
  -- Types for information queue storage.
  type WIP_FIFO_MEM_TYPE              is array(QUEUE_ADDR_POS) of WIP_TYPE;
  type W_FIFO_MEM_TYPE                is array(QUEUE_ADDR_POS) of W_TYPE;
  type BP_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS) of BP_TYPE;
  type BIP_FIFO_MEM_TYPE              is array(QUEUE_ADDR_POS) of BIP_TYPE;
  type ARI_FIFO_MEM_TYPE              is array(QUEUE_ADDR_POS) of ARI_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
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
      C_DSID_WIDTH			    : natural range  0 to   32      := 16;
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
  end component sc_s_axi_r_channel;
  
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
  -- Slave Bus Interface (AW and AR)
  
  signal S_AXI_AWVALID_I            : std_logic;
  signal S_AXI_ARVALID_I            : std_logic;
  signal S_AXI_AWREADY_I            : std_logic;
  signal S_AXI_ARREADY_I            : std_logic;
  signal S_AXI_ARADDR_I             : AXI_ADDR_TYPE;
  signal S_AXI_AWADDR_I             : AXI_ADDR_TYPE;
  
  
  -- ----------------------------------------
  -- Write Transaction Information Queue
  
  signal wr_port_access_i           : WRITE_PORT_TYPE;
  signal wip_push                   : std_logic;
  signal wip_pop                    : std_logic;
  signal wip_refresh_reg            : std_logic;
  signal wip_exist                  : std_logic;
  signal wip_read_fifo_addr         : QUEUE_ADDR_TYPE := (others=>'1');
  signal wip_fifo_mem               : WIP_FIFO_MEM_TYPE := (others=>C_NULL_WIP);
  signal wip_offset                 : ADDR_BYTE_TYPE;
  signal wip_stp_bits               : ADDR_BYTE_TYPE;
  signal wip_use_bits               : ADDR_BYTE_TYPE;
  signal wip_assert                 : std_logic;
  
  
  -- ----------------------------------------
  -- Write Queue Handling
  
  signal w_push                     : std_logic;
  signal w_push_safe                : std_logic;
  signal w_pop_part                 : std_logic;
  signal w_pop                      : std_logic;
  signal w_pop_safe                 : std_logic;
  signal w_fifo_full                : std_logic;
  signal w_fifo_empty               : std_logic;
  signal w_read_fifo_addr           : QUEUE_ADDR_TYPE;
  signal w_fifo_mem                 : W_FIFO_MEM_TYPE; -- := (others=>C_NULL_W);
  signal w_valid                    : std_logic;
  signal w_last                     : std_logic;
  signal w_be                       : BE_TYPE;
  signal w_data                     : DATA_TYPE;
  signal w_ready                    : std_logic;
  signal w_assert                   : std_logic;
  signal S_AXI_WREADY_I             : std_logic;
  
  
  -- ----------------------------------------
  -- Write Complete tracking
  
  signal wc_push        : std_logic;
  signal wc_pop         : std_logic;
  signal wc_fifo_empty  : std_logic;
  
  
  -- ----------------------------------------
  -- Control R-Channel
  
  signal rd_port_access_i           : READ_PORT_TYPE;
  signal read_req_valid             : std_logic;
  signal read_req_ID                : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal read_req_single            : std_logic;
  signal read_req_dvm               : std_logic;
  signal read_req_addr              : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
  signal read_req_DSid              : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  signal read_req_rest              : std_logic_vector(C_REST_WIDTH - 1 downto 0);
  signal read_req_offset            : std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
  signal read_req_stp               : std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
  signal read_req_use               : std_logic_vector(C_ADDR_BYTE_HI   downto C_ADDR_BYTE_LO);
  signal read_req_len               : std_logic_vector(C_LEN_WIDTH - 1  downto 0);
  signal read_req_ready             : std_logic;
  signal r_assert                   : std_logic;
  signal RIF_DEBUG                  : std_logic_vector(255 downto 0);
  signal S_AXI_RVALID_I             : std_logic;
  signal S_AXI_RLAST_I              : std_logic;
  
  
  -- ----------------------------------------
  -- Write Information Queue Handling
  
  signal bip_push                   : std_logic;
  signal bip_pop                    : std_logic;
  signal bip_read_fifo_addr         : QUEUE_ADDR_TYPE:= (others=>'1');
  signal bip_fifo_mem               : BIP_FIFO_MEM_TYPE; -- := (others=>C_NULL_BIP);
  signal bip_fifo_full              : std_logic;
  signal bip_id                     : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal bip_assert                 : std_logic;
  
  
  -- ----------------------------------------
  -- Write Data Handling
  
  signal wr_port_data_valid_i       : std_logic;
  signal wr_port_data_last_i        : std_logic;
  signal wr_port_data_be_i          : std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
  signal wr_port_data_word_i        : std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
  
  
  -- ----------------------------------------
  -- Write Response Handling
  
  signal bp_pop                     : std_logic;
  signal bp_valid                   : std_logic;
  signal bp_ready                   : std_logic;
  signal bp_read_fifo_addr          : QUEUE_ADDR_TYPE:= (others=>'1');
  signal bp_fifo_mem                : BP_FIFO_MEM_TYPE; -- := (others=>C_NULL_BP);
  signal bp_fifo_empty              : std_logic;
  signal bp_early                   : std_logic;
  signal S_AXI_BVALID_I             : std_logic;
  signal update_ext_bresp_ready_i   : std_logic;
  signal bp_fifo_full_i             : std_logic;
  signal bp_assert                  : std_logic;
  
  
  -- ---------------------------------------------------
  -- Internal Interface Signals (Hazard).
  
  signal snoop_act_set_read_hazard : std_logic;
  signal snoop_act_rst_read_hazard : std_logic;
  signal snoop_act_read_hazard     : std_logic;
  signal snoop_act_kill_locked     : std_logic;
  signal snoop_act_just_done       : std_logic;
  signal snoop_act_kill_addr       : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
  
  signal read_data_fetch_addr      : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
  signal read_data_req_addr        : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
  signal read_data_act_addr        : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
    
  signal read_data_fetch_match     : std_logic;
  signal read_data_req_match       : std_logic;
  signal read_data_ongoing         : std_logic;
  signal read_data_block_nested    : std_logic;
  signal read_data_release_block   : std_logic;
  signal read_data_fetch_line_match: std_logic;
  signal read_data_req_line_match  : std_logic;
  signal read_data_act_line_match  : std_logic;
  
  signal read_data_fud_we          : std_logic;
  signal read_data_fud_addr        : std_logic_vector(C_Lx_ADDR_DIRECT_HI   downto C_Lx_ADDR_DIRECT_LO);
  signal read_data_fud_tag_valid   : std_logic;
  signal read_data_fud_tag_unique  : std_logic;
  signal read_data_fud_tag_dirty   : std_logic;
  
  
  -- ---------------------------------------------------
  -- Snoop signals (Read Data & response).
  
  signal snoop_read_data_ready_i    : std_logic;
  
  
  -- ---------------------------------------------------
  -- Lookup signals (Read Data).
  
  signal lookup_read_data_ready_i   : std_logic;
  
  
  -- ---------------------------------------------------
  -- Update signals (Read Data).
  
  signal update_read_data_ready_i   : std_logic;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal sync_assert                : std_logic;
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0) := (others=>'0');
  
  
begin  -- architecture IMP
  
  
  -- Create internal signal with maximum width.
  S_AXI_ARADDR_I <= fit_vec(S_AXI_ARADDR, C_MAX_ADDR_WIDTH);
  S_AXI_AWADDR_I <= fit_vec(S_AXI_AWADDR, C_MAX_ADDR_WIDTH);
  
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
  -- Slave Bus Interface (AW and AR)
  -----------------------------------------------------------------------------
  
  -- Throttle inputs.
  -- No need to throttle write with WIP FIFO because it can never be deeper than BIP.
  S_AXI_AWVALID_I             <= S_AXI_AWVALID and not bip_fifo_full;
  S_AXI_ARVALID_I             <= S_AXI_ARVALID and read_req_ready;
  
  -- AW-Channel.
  Write_ID_extend: process(S_AXI_AWID)
  begin
    wr_port_id                    <= (others=>'0');
    wr_port_id(S_AXI_AWID'range)  <= S_AXI_AWID;
  end process Write_ID_extend;
  wr_port_access_i.Valid      <= S_AXI_AWVALID_I;
  wr_port_access_i.Addr       <= S_AXI_AWADDR_I;
  wr_port_access_i.Len        <= S_AXI_AWLEN;
  wr_port_access_i.Kind       <= C_KIND_WRAP  when S_AXI_AWBURST = C_AW_WRAP else 
                                 C_KIND_INCR;
  wr_port_access_i.Exclusive  <= S_AXI_AWLOCK when C_S_AXI_PROHIBIT_EXCLUSIVE       = 0 else
                                 '0';
  wr_port_access_i.Allocate   <= '1'          when C_S_AXI_FORCE_WRITE_ALLOCATE    /= 0 else
                                 '0'          when C_S_AXI_PROHIBIT_WRITE_ALLOCATE /= 0 else
                                 S_AXI_AWCACHE(3);
  wr_port_access_i.Bufferable <= '1'          when C_S_AXI_FORCE_WRITE_BUFFER      /= 0 else
                                 '0'          when C_S_AXI_PROHIBIT_WRITE_BUFFER   /= 0 else
                                 S_AXI_AWCACHE(0);
  wr_port_access_i.Prot       <= S_AXI_AWPROT;
  wr_port_access_i.Snoop      <= S_AXI_AWSNOOP;
  wr_port_access_i.Barrier    <= S_AXI_AWBAR;
  wr_port_access_i.Domain     <= S_AXI_AWDOMAIN;
  wr_port_access_i.Size       <= S_AXI_AWSIZE;
  wr_port_access_i.DSid       <= fit_vec(S_AXI_AWUSER, C_DSID_WIDTH);
  wr_port_access              <= wr_port_access_i;
  S_AXI_AWREADY_I             <= wr_port_ready and not bip_fifo_full;
  S_AXI_AWREADY               <= S_AXI_AWREADY_I;
  
  -- AR-Channel.
  Read_ID_extend: process(S_AXI_ARID)
  begin
    rd_port_id                    <= (others=>'0');
    rd_port_id(S_AXI_ARID'range)  <= S_AXI_ARID;
  end process Read_ID_extend;
  rd_port_access_i.Valid      <= S_AXI_ARVALID_I;
  rd_port_access_i.Addr       <= S_AXI_ARADDR_I;
  rd_port_access_i.Kind       <= C_KIND_WRAP  when S_AXI_ARBURST = C_AR_WRAP else 
                                 C_KIND_INCR;
  rd_port_access_i.Exclusive  <= S_AXI_ARLOCK when C_S_AXI_PROHIBIT_EXCLUSIVE      = 0 else
                                 '0';
  rd_port_access_i.Allocate   <= '1'          when C_S_AXI_FORCE_READ_ALLOCATE    /= 0 else
                                 '0'          when C_S_AXI_PROHIBIT_READ_ALLOCATE /= 0 else
                                 S_AXI_ARCACHE(2);
  rd_port_access_i.Bufferable <= '1'          when C_S_AXI_FORCE_READ_BUFFER      /= 0 else
                                 '0'          when C_S_AXI_PROHIBIT_READ_BUFFER   /= 0 else
                                 S_AXI_ARCACHE(0);
  rd_port_access_i.Prot       <= S_AXI_ARPROT;
  rd_port_access_i.Snoop      <= S_AXI_ARSNOOP;
  rd_port_access_i.Barrier    <= S_AXI_ARBAR;
  rd_port_access_i.Domain     <= S_AXI_ARDOMAIN;
  rd_port_access_i.DSid       <= fit_vec(S_AXI_ARUSER, C_DSID_WIDTH);
  rd_port_access              <= rd_port_access_i;
  S_AXI_ARREADY_I             <= rd_port_ready and read_req_ready;
  S_AXI_ARREADY               <= S_AXI_ARREADY_I;
  
  -- AR-Channel adjustable.
  External_Narrow: if( C_S_AXI_DATA_WIDTH < C_CACHE_DATA_WIDTH ) generate
  begin
    rd_port_access_i.Len        <= (C_RATIO_BITS - 1 downto 0=>'0') & S_AXI_ARLEN(8 - 1 downto C_RATIO_BITS);

    Adjust_Transaction: process (S_AXI_ARCACHE, S_AXI_ARLOCK, S_AXI_ARSIZE) is
    begin  -- process Gen_Rem_Len
      if( ( S_AXI_ARCACHE(2) = '0' ) and ( S_AXI_ARLOCK = '1' ) ) then
        rd_port_access_i.Size       <= S_AXI_ARSIZE;
      else
        rd_port_access_i.Size       <= std_logic_vector(to_unsigned(Log2(C_CACHE_DATA_WIDTH/8), 3));
      end if;
    end process Adjust_Transaction;
  end generate External_Narrow;
  
  External_Same: if( C_S_AXI_DATA_WIDTH = C_CACHE_DATA_WIDTH ) generate
  begin
    rd_port_access_i.Len        <= S_AXI_ARLEN;
    rd_port_access_i.Size       <= S_AXI_ARSIZE;
  end generate External_Same;
  
  
  -----------------------------------------------------------------------------
  -- Write Transaction Information Queue
  -- 
  -- Only needed when up-sizing.
  -- The address Offset is needed to start WSTRB at the correct position
  -- in the upsized data.
  -----------------------------------------------------------------------------
  
  No_WIP: if( C_CACHE_DATA_WIDTH = C_S_AXI_DATA_WIDTH ) generate
  begin
    wip_exist     <= '1';
    wip_offset    <= C_NULL_WIP.Offset;
    wip_stp_bits  <= C_NULL_WIP.Offset;
    wip_use_bits  <= C_NULL_WIP.Offset;
    
    -- No WIP FIFO.
    wip_assert                  <= '0';
    stat_s_axi_wip              <= C_NULL_STAT_FIFO;
    
  end generate No_WIP;
  
  Use_WIP: if( C_CACHE_DATA_WIDTH /= C_S_AXI_DATA_WIDTH ) generate
  
    signal access_is_incr   : std_logic;
    signal extended_length  : std_logic_vector(21 downto 0);
    signal access_byte_len  : AXI_ADDR_TYPE;
    signal use_bits_cmb     : ADDR_BYTE_TYPE;
    signal wip_fifo_mem_vec : ADDR_BYTE_TYPE;
    signal stp_bits_cmb     : ADDR_BYTE_TYPE;
    
  begin
    -- Control signals for write information queue.
    wip_push        <= S_AXI_AWVALID_I and wr_port_ready;
--    wip_pop         <= w_pop_safe and w_last;
    WC_And_Inst4: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => w_pop_safe,
        A         => w_last,
        Carry_OUT => wip_pop
      );
    
    FIFO_WIP_Pointer: sc_srl_fifo_counter
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
        
        queue_push                => wip_push,
        queue_pop                 => wip_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => wip_refresh_reg,
        
        queue_almost_full         => open,
        queue_full                => open,
        queue_almost_empty        => open,
        queue_empty               => open,
        queue_exist               => wip_exist,
        queue_line_fit            => open,
        queue_index               => wip_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => stat_s_axi_wip,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => wip_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Predecode.
    access_is_incr    <= '1' when S_AXI_AWBURST = C_AW_INCR else '0';
    
    -- Handle memory for WIP Channel FIFO.
    FIFO_WIP_Memory : process (ACLK) is
    begin  -- process FIFO_WIP_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( wip_push = '1') then
          -- Insert new item.
          wip_fifo_mem(0).Offset  <= S_AXI_AWADDR_I(C_ADDR_BYTE_POS);
          wip_fifo_mem(0).Incr    <= access_is_incr;
          wip_fifo_mem(0).Size    <= S_AXI_AWSIZE;
          wip_fifo_mem(0).Len     <= S_AXI_AWLEN;
          
          -- Shift FIFO contents.
          wip_fifo_mem(wip_fifo_mem'left downto 1) <= wip_fifo_mem(wip_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_WIP_Memory;
    
    -- Extend the length vector (help signal).
    Ext_Len: process (wip_fifo_mem, wip_read_fifo_addr) is
    begin  -- process Ext_Len
      extended_length               <= (others=>'0');
      extended_length(14 downto 7)  <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Len;
      extended_length( 6 downto 0)  <= "1111111";
    end process Ext_Len;
    
    -- Create Use/Stp vectors.
    Gen_Real_Len: process (wip_fifo_mem, wip_read_fifo_addr, extended_length) is
    begin  -- process Gen_Real_Len
      access_byte_len <= (others=>'0');
      case wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Size is
        when C_BYTE_SIZE          =>
          access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        when C_HALF_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 16 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_HALF_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_WORD_SIZE          =>
          if( C_S_AXI_DATA_WIDTH >= 32 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_DOUBLE_WORD_SIZE   =>
          if( C_S_AXI_DATA_WIDTH >= 64 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_DOUBLE_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_QUAD_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 128 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_QUAD_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_OCTA_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 256 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_OCTA_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_HEXADECA_WORD_SIZE =>
          if( C_S_AXI_DATA_WIDTH >= 512 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_HEXADECA_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when others               =>
          if( C_S_AXI_DATA_WIDTH >= 1024 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_TRIACONTADI_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
      end case;
    end process Gen_Real_Len;

    wip_fifo_mem_vec <= (others => wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Incr);
    use_bits_cmb <= access_byte_len(C_ADDR_BYTE_POS) or 
                    wip_fifo_mem_vec;
    
    Gen_Stp_Info: process (wip_fifo_mem, wip_read_fifo_addr) is
    begin  -- process Gen_Stp_Info
      case wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Size is
        when C_BYTE_SIZE          =>
          stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
        when C_HALF_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 16 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_WORD_SIZE          =>
          if( C_S_AXI_DATA_WIDTH >= 32 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_DOUBLE_WORD_SIZE   =>
          if( C_S_AXI_DATA_WIDTH >= 64 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE,          C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_QUAD_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 128 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_OCTA_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 256 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_HEXADECA_WORD_SIZE =>
          if( C_S_AXI_DATA_WIDTH >= 512 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE,        C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when others               =>
          if( C_S_AXI_DATA_WIDTH >= 1024 ) then
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE,     C_ADDR_BYTE_BITS));
          else
            stp_bits_cmb  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
      end case;
    end process Gen_Stp_Info;
    
    -- Store WIP in register for good timing.
    WIP_Data_Registers : process (ACLK) is
    begin  -- process WIP_Data_Registers
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          wip_offset    <= C_NULL_WIP.Offset;
          wip_stp_bits  <= C_NULL_WIP.Offset;
          wip_use_bits  <= C_NULL_WIP.Offset;
        elsif( wip_refresh_reg = '1' ) then
          wip_offset    <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Offset;
          wip_stp_bits  <= stp_bits_cmb;
          wip_use_bits  <= use_bits_cmb;
        end if;
      end if;
    end process WIP_Data_Registers;
    
  end generate Use_WIP;
  
  
  -----------------------------------------------------------------------------
  -- Write Queue Handling
  -- 
  -- Queue write data. Assuming the AW and W information is available at the
  -- same time there are at least three clock cycles available for 
  -- pre-processing and timing enhancements.
  -----------------------------------------------------------------------------
  
  -- Control signals for read data queue.
  w_push          <= S_AXI_WVALID;
  w_push_safe     <= w_push and not w_fifo_full;
--  w_pop           <= ( w_ready or not wr_port_data_valid_i ) and wip_exist;
--  w_pop_safe      <= w_pop and not w_fifo_empty;
  WC_Or_Inst2: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => w_ready,
      A_N       => wr_port_data_valid_i,
      Carry_OUT => w_pop_part
    );
  WC_And_Inst2: carry_and 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => w_pop_part,
      A         => wip_exist,
      Carry_OUT => w_pop
    );
  WC_And_Inst3: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => w_pop,
      A_N       => w_fifo_empty,
      Carry_OUT => w_pop_safe
    );
  
  FIFO_W_Pointer: sc_srl_fifo_counter
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
      
      queue_push                => w_push,
      queue_pop                 => w_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => w_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => w_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => w_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_s_axi_w,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => w_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for R Channel FIFO.
  FIFO_W_Memory : process (ACLK) is
  begin  -- process FIFO_W_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( w_push_safe = '1') then
        -- Insert new item.
        w_fifo_mem(0).Last  <= S_AXI_WLAST;
        w_fifo_mem(0).BE    <= S_AXI_WSTRB;
        w_fifo_mem(0).Data  <= S_AXI_WDATA;
        
        -- Shift FIFO contents.
        w_fifo_mem(w_fifo_mem'left downto 1) <= w_fifo_mem(w_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_W_Memory;
  
  -- Forward ready.
  S_AXI_WREADY_I  <= not w_fifo_full;
  S_AXI_WREADY    <= S_AXI_WREADY_I;
  
  -- Rename signals.
  w_valid         <= ( not w_fifo_empty ) and wip_exist;
  w_last          <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Last;
  w_be            <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).BE;
  w_data          <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Data;
  
  
  -----------------------------------------------------------------------------
  -- Write Complete tracking
  -- 
  -- Use quadruple normal queue size to avoid need to check full, impossible
  -- to get quadruple the amount of completed compared to W Queue.
  -----------------------------------------------------------------------------
  
  wc_push <= w_push_safe and S_AXI_WLAST;
  wc_pop  <= bp_pop;
  
  FIFO_WC_Pointer: sc_srl_fifo_counter
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
      C_QUEUE_ADDR_WIDTH        => 2 + C_QUEUE_LENGTH_BITS,
      C_LINE_LENGTH             => 1
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => wc_push,
      queue_pop                 => wc_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => open,
      queue_almost_empty        => open,
      queue_empty               => wc_fifo_empty,
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
      
      assert_error              => open,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  
  -----------------------------------------------------------------------------
  -- Write Data Handling
  -- 
  -- Assign internal interface signals with data from the port. The data is 
  -- mirrored if the internal data is wider than external.
  -- WSTRB is assigned to the currently active word in the upsized data.
  -- 
  -----------------------------------------------------------------------------
  
  -- Simply forward Write data if internal width is same as interface.
  No_Write_Mirror: if( C_CACHE_DATA_WIDTH = C_S_AXI_DATA_WIDTH ) generate
  begin
    wr_port_data_be_i   <= w_be;
    wr_port_data_word_i <= w_data;
  end generate No_Write_Mirror;
  
  -- Mirror Write data if internal width larger than interface.
  Use_Write_Mirror: if( C_CACHE_DATA_WIDTH /= C_S_AXI_DATA_WIDTH ) generate
    subtype C_RATIO_BITS_POS  is natural range C_ADDR_BYTE_HI downto C_ADDR_BYTE_HI - C_RATIO_BITS + 1;
    subtype RATIO_BITS_TYPE   is std_logic_vector(C_RATIO_BITS_POS);
    
    signal first_w_word       : std_logic;
    signal write_offset       : ADDR_BYTE_TYPE;
    signal write_next_offset  : ADDR_BYTE_TYPE;
    signal write_offset_cnt   : ADDR_BYTE_TYPE;
  begin
    -- Select current offset.
    write_offset <= wip_offset when ( first_w_word = '1' ) else write_offset_cnt;
    
    -- Generate next offset including wrap.
    Update_Offset_Select: process (write_offset, wip_stp_bits, wip_use_bits, wip_offset) is
      variable offset_cnt_next_cmb  : ADDR_BYTE_TYPE;
    begin  -- process Update_Offset_Select
      offset_cnt_next_cmb     := std_logic_vector(unsigned(write_offset) + unsigned(wip_stp_bits));
      
      for I in offset_cnt_next_cmb'range loop
        if( wip_use_bits(I) = '0' ) then
          write_next_offset(I)  <= wip_offset(I);
          
        else
          write_next_offset(I)  <= offset_cnt_next_cmb(I);
          
        end if;
      end loop;
    end process Update_Offset_Select;
    
    -- Handle next offset that should be used.
    Write_Miss_Part_Handler : process (ACLK) is
    begin  -- process Write_Miss_Part_Handler
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          first_w_word      <= '1';
          write_offset_cnt  <= (others=>'0');
        else
          if ( w_pop_safe and w_last ) = '1' then
            first_w_word      <= '1';
          elsif ( w_pop_safe ) = '1' then
            first_w_word      <= '0';
            write_offset_cnt  <= write_next_offset;
          end if;
        end if;
      end if;
    end process Write_Miss_Part_Handler;
    
    Gen_Write_Mirror: for I in 0 to C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH - 1 generate
    begin
      -- Generate mirrored data and steer byte enable.
      wr_port_data_be_i((I+1) * C_S_AXI_DATA_WIDTH / 8 - 1 downto I * C_S_AXI_DATA_WIDTH / 8) 
                          <= w_be when ( to_integer(unsigned(write_offset(C_RATIO_BITS_POS))) = I ) 
                             else (others=>'0');
      wr_port_data_word_i((I+1) * C_S_AXI_DATA_WIDTH - 1 downto I * C_S_AXI_DATA_WIDTH)       <= w_data;
      
    end generate Gen_Write_Mirror;
  end generate Use_Write_Mirror;
  
  Write_Data_Output : process (ACLK) is
  begin  -- process Write_Data_Output
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        wr_port_data_valid_i  <= '0';
        wr_port_data_last_i   <= '1';
        wr_port_data_be       <= (others=>'0');
        wr_port_data_word     <= (others=>'0');
      elsif( w_pop = '1' ) then
        wr_port_data_valid_i  <= w_valid;
        wr_port_data_last_i   <= w_last;
        wr_port_data_be       <= wr_port_data_be_i;
        wr_port_data_word     <= wr_port_data_word_i;
      elsif( wr_port_data_ready = '1' ) then
        wr_port_data_valid_i  <= '0';
      end if;
    end if;
  end process Write_Data_Output;
  
  -- Assign output.
  wr_port_data_valid  <= wr_port_data_valid_i;
  wr_port_data_last   <= wr_port_data_last_i;
  
  -- Forward ready.
--  w_ready     <= wr_port_data_ready;
  WC_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => '0',
      A         => wr_port_data_ready,
      Carry_OUT => w_ready
    );
  
  
  -----------------------------------------------------------------------------
  -- Control R-Channel
  -- 
  -- Generate signals for the R-Channel handling. Most signals are directly
  -- from the input of constants for the current configuration.
  -- 
  -----------------------------------------------------------------------------
  
  -- Setup information for R-Channel
  read_req_valid  <= S_AXI_ARVALID_I and rd_port_ready;
  read_req_ID     <= S_AXI_ARID;
  read_req_single <= S_AXI_ARLOCK and not S_AXI_ARCACHE(2) when ( C_S_AXI_DATA_WIDTH < C_CACHE_DATA_WIDTH ) else 
                     '0';
  read_req_dvm    <= '1' when ( S_AXI_ARSNOOP = C_ACSNOOP_DVMComplete ) or 
                              ( S_AXI_ARSNOOP = C_ACSNOOP_DVMMessage  ) else 
                     '0';
  read_req_addr   <= S_AXI_ARADDR_I(C_Lx_ADDR_DIRECT_POS);
  read_req_DSid   <= S_AXI_ARUSER;
  read_req_rest   <= S_AXI_ARLEN(C_REST_WIDTH - 2 - 1 downto 0) & "00";
  read_req_offset <= S_AXI_ARADDR_I(C_ADDR_BYTE_POS);
  read_req_len    <= S_AXI_ARLEN(C_LEN_POS);
  
  Req_Same_Width: if( C_CACHE_DATA_WIDTH = C_S_AXI_DATA_WIDTH ) generate
  begin
    read_req_stp    <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE, C_ADDR_BYTE_BITS));
    read_req_use    <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE * C_Lx_CACHE_LINE_LENGTH - 1, C_ADDR_BYTE_BITS));
    
  end generate Req_Same_Width;
  
  Req_Wider_Width: if( C_CACHE_DATA_WIDTH /= C_S_AXI_DATA_WIDTH ) generate
  
    signal access_is_incr   : std_logic;
    signal extended_length  : std_logic_vector(21 downto 0);
    signal access_byte_len  : AXI_ADDR_TYPE;
    signal use_bits_cmb     : ADDR_BYTE_TYPE;
    signal req_incr_vec     : ADDR_BYTE_TYPE;
    signal stp_bits_cmb     : ADDR_BYTE_TYPE;
    
  begin
      
    -- Predecode.
    access_is_incr    <= '1' when S_AXI_ARBURST = C_AR_INCR else '0';
    
    -- Extend the length vector (help signal).
    Ext_Len: process (wip_fifo_mem, wip_read_fifo_addr) is
    begin  -- process Ext_Len
      extended_length               <= (others=>'0');
      extended_length(14 downto 7)  <= S_AXI_ARLEN;
      extended_length( 6 downto 0)  <= "1111111";
    end process Ext_Len;
    
    -- Create Use/Stp vectors.
    Gen_Real_Len: process (S_AXI_ARSIZE, extended_length) is
    begin  -- process Gen_Real_Len
      access_byte_len <= (others=>'0');
      case S_AXI_ARSIZE is
        when C_BYTE_SIZE          =>
          access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
        when C_HALF_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 16 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_HALF_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_WORD_SIZE          =>
          if( C_S_AXI_DATA_WIDTH >= 32 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_DOUBLE_WORD_SIZE   =>
          if( C_S_AXI_DATA_WIDTH >= 64 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_DOUBLE_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_QUAD_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 128 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_QUAD_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_OCTA_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 256 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_OCTA_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when C_HEXADECA_WORD_SIZE =>
          if( C_S_AXI_DATA_WIDTH >= 512 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_HEXADECA_WORD_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
        when others               =>
          if( C_S_AXI_DATA_WIDTH >= 1024 ) then
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_TRIACONTADI_MASK_POS);
          else
            access_byte_len(C_ADDR_LENGTH_POS)  <= extended_length(C_BYTE_MASK_POS);
          end if;
      end case;
    end process Gen_Real_Len;

    req_incr_vec <= (others => access_is_incr);
    read_req_use <= access_byte_len(C_ADDR_BYTE_POS) or 
                    req_incr_vec;
    
    Gen_Stp_Info: process (S_AXI_ARSIZE) is
    begin  -- process Gen_Stp_Info
      case S_AXI_ARSIZE is
        when C_BYTE_SIZE          =>
          read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
        when C_HALF_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 16 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_WORD_SIZE          =>
          if( C_S_AXI_DATA_WIDTH >= 32 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_DOUBLE_WORD_SIZE   =>
          if( C_S_AXI_DATA_WIDTH >= 64 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE,          C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_QUAD_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 128 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_OCTA_WORD_SIZE     =>
          if( C_S_AXI_DATA_WIDTH >= 256 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE,            C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when C_HEXADECA_WORD_SIZE =>
          if( C_S_AXI_DATA_WIDTH >= 512 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE,        C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
        when others               =>
          if( C_S_AXI_DATA_WIDTH >= 1024 ) then
            read_req_stp  <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE,     C_ADDR_BYTE_BITS));
          else
            read_req_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE,                 C_ADDR_BYTE_BITS));
          end if;
      end case;
    end process Gen_Stp_Info;
    
  end generate Req_Wider_Width;
  
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
      C_DSID_WIDTH		=> C_DSID_WIDTH,
      -- AXI4 Interface Specific.
      C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
      C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH,
      C_S_AXI_RESP_WIDTH        => 2+2*C_ENABLE_COHERENCY,
      
      -- Configuration.
      C_SUPPORT_SUBSIZED        => false,
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
      C_ENABLE_HAZARD_HANDLING  => C_ENABLE_COHERENCY,
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
      S_AXI_RACK                => S_AXI_RACK,
      
      
      -- ---------------------------------------------------
      -- Read Information Interface Signals.
      
      read_req_valid            => read_req_valid,
      read_req_ID               => read_req_ID,
      read_req_last             => '1',
      read_req_failed           => '0',
      read_req_single           => read_req_single,
      read_req_dvm              => read_req_dvm,
      read_req_addr             => read_req_addr,
      read_req_DSid		=> read_req_DSid,
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
      
      snoop_req_piperun         => snoop_req_piperun,
      snoop_act_set_read_hazard => snoop_act_set_read_hazard,
      snoop_act_rst_read_hazard => snoop_act_rst_read_hazard,
      snoop_act_read_hazard     => snoop_act_read_hazard,
      snoop_act_kill_locked     => snoop_act_kill_locked,
      snoop_act_kill_addr       => snoop_act_kill_addr,
      
      read_data_fetch_addr      => read_data_fetch_addr,
      read_data_req_addr        => read_data_req_addr,
      read_data_act_addr        => read_data_act_addr,
      
      read_data_fetch_match     => read_data_fetch_match,
      read_data_req_match       => read_data_req_match,
      read_data_ongoing         => read_data_ongoing,
      read_data_block_nested    => read_data_block_nested,
      read_data_release_block   => read_data_release_block,
      read_data_fetch_line_match=> read_data_fetch_line_match,
      read_data_req_line_match  => read_data_req_line_match,
      read_data_act_line_match  => read_data_act_line_match,
      
      read_data_fud_we          => read_data_fud_we,
      read_data_fud_addr        => read_data_fud_addr,
      read_data_fud_tag_valid   => read_data_fud_tag_valid,
      read_data_fud_tag_unique  => read_data_fud_tag_unique,
      read_data_fud_tag_dirty   => read_data_fud_tag_dirty,
    
      read_data_ex_rack         => read_data_ex_rack,
      
      
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
      snoop_read_data_ready     => snoop_read_data_ready_i,
      
      
      -- ---------------------------------------------------
      -- Lookup signals (Read Data).
      
      lookup_read_data_valid    => lookup_read_data_valid,
      lookup_read_data_last     => lookup_read_data_last,
      lookup_read_data_resp     => lookup_read_data_resp,
      lookup_read_data_set      => lookup_read_data_set,
      lookup_read_data_word     => lookup_read_data_word,
      lookup_read_data_ready    => lookup_read_data_ready_i,
      
      
      -- ---------------------------------------------------
      -- Update signals (Read Data).
      
      update_read_data_valid    => update_read_data_valid,
      update_read_data_last     => update_read_data_last,
      update_read_data_resp     => update_read_data_resp,
      update_read_data_word     => update_read_data_word,
      update_read_data_ready    => update_read_data_ready_i,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_s_axi_rip            => stat_s_axi_rip,
      stat_s_axi_r              => stat_s_axi_r,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => r_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals.
      
      IF_DEBUG                  => RIF_DEBUG 
    );
  
  S_AXI_RVALID            <= S_AXI_RVALID_I;
  S_AXI_RLAST             <= S_AXI_RLAST_I;
  
  snoop_read_data_ready   <= snoop_read_data_ready_i;
  lookup_read_data_ready  <= lookup_read_data_ready_i;
  update_read_data_ready  <= update_read_data_ready_i;
  
  
  -----------------------------------------------------------------------------
  -- Write Information Queue Handling
  -- 
  -- Push all control information needed into the queue to be able to do the 
  -- port specific modifications of the returned response.
  -----------------------------------------------------------------------------
  
  -- Control signals for read data queue.
  bip_push    <= S_AXI_AWVALID_I and wr_port_ready;
  bip_pop     <= bp_pop;
  
  FIFO_BIP_Pointer: sc_srl_fifo_counter
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
      
      queue_push                => bip_push,
      queue_pop                 => bip_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => bip_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => open,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => bip_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_s_axi_bip,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => bip_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for RIP Channel FIFO.
  FIFO_BIP_Memory : process (ACLK) is
  begin  -- process FIFO_BIP_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( bip_push = '1') then
        -- Insert new item.
        bip_fifo_mem(0).ID      <= S_AXI_AWID;
        
        -- Shift FIFO contents.
        bip_fifo_mem(bip_fifo_mem'left downto 1) <= bip_fifo_mem(bip_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_BIP_Memory;
  
  -- Get ID.
  bip_id                <= bip_fifo_mem(to_integer(unsigned(bip_read_fifo_addr))).ID;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Handling
  -- 
  -- Store Write Response Hit/Miss information with ID in a queue.
  -- 
  -- Hit are forwarded directly where as Miss has to wait for a BRESP from the 
  -- external memory.
  -- 
  -- Clock and hold the BRESP until it is acknowledged from AXI.
  -----------------------------------------------------------------------------
  
  -- Generate control signals.
  bp_pop      <= bp_valid and bp_ready;

  FIFO_BP_Pointer: sc_srl_fifo_counter
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
      
      queue_push                => access_bp_push,
      queue_pop                 => bp_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => bp_fifo_full_i,
      queue_almost_empty        => open,
      queue_empty               => bp_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => bp_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_s_axi_bp,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => bp_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for Write Miss FIFO.
  FIFO_BP_Memory : process (ACLK) is
  begin  -- process FIFO_BP_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( access_bp_push = '1' ) then
        -- Insert new item.
        bp_fifo_mem(0).Early  <= access_bp_early;
        
        -- Shift FIFO contents.
        bp_fifo_mem(bp_fifo_mem'left downto 1) <= bp_fifo_mem(bp_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_BP_Memory;
  
  -- Mux response on per port basis.
  bp_early  <= bp_fifo_mem(to_integer(unsigned(bp_read_fifo_addr))).Early;
  
  -- Generate valid for both hit and miss.
  bp_valid  <= ( ( bp_early and not wc_fifo_empty ) or (update_ext_bresp_valid and not bp_early) ) and 
               not bp_fifo_empty;
                                     
  Write_Response_Handler : process (ACLK) is
  begin  -- process Write_Response_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active high)
        S_AXI_BVALID_I  <= '0';
        S_AXI_BRESP     <= (others=>'0');
        S_AXI_BID       <= (others=>'0');
      else
        -- Turn off when the data is acknowledged.
        if( bp_ready = '1' ) then
          S_AXI_BVALID_I  <= '0';
        end if;
        
        -- Start new when information is available.
        if( ( bp_valid and bp_ready ) = '1' ) then
          S_AXI_BVALID_I  <= '1';
          S_AXI_BID       <= bip_id;
          if( bp_early = '1' ) then
            S_AXI_BRESP     <= C_BRESP_OKAY;
          else
            S_AXI_BRESP     <= update_ext_bresp;
          end if;
        end if;
      end if;
    end if;
  end process Write_Response_Handler;
  
  -- Generate internal ready signal.
  bp_ready                  <= S_AXI_BREADY or not S_AXI_BVALID_I;
  
  -- Return ready when able to use miss BRESP.
  update_ext_bresp_ready    <= update_ext_bresp_ready_i;
  update_ext_bresp_ready_i  <= bp_ready and not bp_early and not bp_fifo_empty;
  
  -- Rename the internal valid signal.
  S_AXI_BVALID              <= S_AXI_BVALID_I;
  
  
  -----------------------------------------------------------------------------
  -- Coherency support
  -----------------------------------------------------------------------------
  
  No_Coherency: if( C_ENABLE_COHERENCY = 0 ) generate
  begin
    -- Internal interfaces:
    
    read_data_fetch_addr      <= (others=>'0');
    read_data_req_addr        <= (others=>'0');
    read_data_act_addr        <= (others=>'0');
    
    snoop_fetch_pos_hazard    <= '0';
    
    snoop_act_set_read_hazard <= '0';
    snoop_act_rst_read_hazard <= '0';
    snoop_act_read_hazard     <= '0';
    snoop_act_kill_locked     <= '0';
    snoop_act_kill_addr       <= (others=>'0');
    snoop_act_tag_valid       <= '0';
    snoop_act_tag_unique      <= '0';
    snoop_act_tag_dirty       <= '0';
    snoop_act_done            <= '0';
    snoop_act_use_external    <= '0';
    snoop_act_write_blocking  <= '0';
    
    snoop_info_tag_unique     <= '0';
    snoop_info_tag_dirty      <= '0';
    
    snoop_resp_valid          <= '0';
    snoop_resp_crresp         <= (others=>'0');
    
    
    -- External interfaces:
    
    -- AC-Channel (coherency only)
    S_AXI_ACVALID             <= '0';
    S_AXI_ACADDR              <= (others=>'0');
    S_AXI_ACSNOOP             <= (others=>'0');
    S_AXI_ACPROT              <= (others=>'0');

    -- CR-Channel (coherency only)
    S_AXI_CRREADY             <= '0';

    -- CD-Channel (coherency only)
    S_AXI_CDREADY             <= '0';
    
    No_Debug: if( not C_USE_DEBUG ) generate
    begin
      IF_DEBUG(255                  downto  74) <= (others=>'0');
    end generate No_Debug;
    
  end generate No_Coherency;
  
  Use_Coherency: if( C_ENABLE_COHERENCY /= 0 ) generate
  
    -- ----------------------------------------
    -- Snoop Filter Fetch
    
    signal snoop_fetch_addr_i         : Lx_ADDR_LINE_TYPE;
    signal snoop_fetch_pos_hazard_i   : std_logic;
    
    -- ----------------------------------------
    -- Snoop Request Evaluation
    
    signal snoop_req_tag_valid        : std_logic;
    signal snoop_req_tag_locked       : std_logic;
    signal snoop_req_tag_dirty        : std_logic;
    signal snoop_req_tag_unique       : std_logic;
    signal snoop_req_tag_addr         : Lx_TAG_ADDR_TYPE;
    signal snoop_req_current_tag      : Lx_TAG_TYPE;
    
    signal snoop_req_tag_overwritten  : std_logic;
    signal snoop_req_new_tag_valid    : std_logic;
    signal snoop_req_new_tag_dirty    : std_logic;
    signal snoop_req_new_tag_unique   : std_logic;
    signal snoop_req_new_tag_addr     : Lx_TAG_ADDR_TYPE;
    
    signal snoop_req_tag_hit          : std_logic;
    signal snoop_req_hit              : std_logic;
    signal snoop_req_hazard           : std_logic;
    signal snoop_req_prot_access      : std_logic;
    signal snoop_req_fud_protected    : std_logic;
    
    
    -- ----------------------------------------
    -- Snoop Update
    
    signal snoop_update_we_i          : std_logic;
    signal snoop_update_we            : std_logic_vector(0 downto 0);
    signal snoop_update_addr          : Lx_ADDR_LINE_TYPE;
    signal snoop_update_tag_valid     : std_logic;
    signal snoop_update_tag_lock      : std_logic;
    signal snoop_update_tag_dirty     : std_logic;
    signal snoop_update_tag_unique    : std_logic;
    signal snoop_update_tag_addr      : Lx_TAG_ADDR_TYPE;
    signal snoop_update_new_tag       : Lx_TAG_TYPE;
    
    
    -- ----------------------------------------
    -- Snoop Action
    
    signal snoop_act_tag_valid_i      : std_logic;
    signal snoop_act_tag_locked_i     : std_logic;
    signal snoop_act_tag_dirty_i      : std_logic;
    signal snoop_act_tag_unique_i     : std_logic;
    signal snoop_act_tag_addr_i       : Lx_TAG_ADDR_TYPE;
    signal snoop_act_wait_for_pipe    : std_logic;
    signal snoop_act_completed_ac     : std_logic;
    signal snoop_act_want_ac          : std_logic;
    signal snoop_act_waiting_4_cr     : std_logic;
    signal snoop_act_current_num_ac   : natural range 0 to 15;
    signal snoop_act_allowed_ac       : std_logic;
    signal snoop_act_read_blocked     : std_logic;
    signal snoop_act_ac_hazard        : std_logic;
    signal snoop_act_ac_safe          : std_logic;
    signal snoop_act_ac_done          : std_logic;
    signal S_AXI_ACVALID_I            : std_logic;
    signal snoop_act_done_i           : std_logic;
    signal snoop_act_fud_we           : std_logic;
    signal snoop_act_fud_valid        : std_logic;
    signal snoop_act_fud_hit          : std_logic;
    signal snoop_act_fud_protected    : std_logic;
    signal snoop_act_release_prot     : std_logic;
    signal snoop_act_fud_make_valid   : std_logic;
    signal snoop_act_fud_make_invalid : std_logic;
    signal snoop_act_fud_make_unique  : std_logic;
    signal snoop_act_fud_make_shared  : std_logic;
    signal snoop_act_fud_make_clean   : std_logic;
    signal snoop_act_write_blocking_i : std_logic;
    signal snoop_act_tag_collision    : std_logic;
    
    
    -- ----------------------------------------
    -- Read Data Filter Update
    
    signal snoop_read_data_filter_we  : std_logic;
    
    
    -- ----------------------------------------
    -- Snoop Response
    
    signal ari_push                   : std_logic;
    signal ari_pop                    : std_logic;
    signal ari_fifo_full              : std_logic;
    signal ari_fifo_empty             : std_logic;
    signal ari_read_fifo_addr         : QUEUE_ADDR_TYPE:= (others=>'1');
    signal ari_fifo_mem               : ARI_FIFO_MEM_TYPE; -- := (others=>C_NULL_ARI);
    signal ari_assert                 : std_logic;
    
    
    -- ----------------------------------------
    -- Sync Handling
    
    subtype C_COMPLETE_POS              is natural range C_NUM_PORTS - 2 downto 0;
    
    subtype COMPLETE_TYPE               is std_logic_vector(C_COMPLETE_POS);

    constant complete_one_vec         : COMPLETE_TYPE := (others => '1');

    signal snoop_req_complete_done    : std_logic;
    signal snoop_act_ac_complete      : std_logic;
    signal snoop_req_comp_with_cur    : COMPLETE_TYPE;
    signal complete_request_detected  : COMPLETE_TYPE;
    
  begin
    
    -----------------------------------------------------------------------------
    -- Snoop Filter Fetch
    -----------------------------------------------------------------------------
    
    -- Extract line address bits.
    snoop_fetch_addr_i  <= snoop_fetch_addr(C_Lx_ADDR_LINE_POS);
    
    -- Snoop filter instantiation.
    One_Liner: if( Lx_ADDR_LINE_TYPE'length = 0 ) generate
    begin
      One_Line_Filter_Handler : process (ACLK) is
        variable my_tag   : Lx_TAG_TYPE;
      begin  -- process One_Line_Filter_Handler
        if (ACLK'event and ACLK = '1') then   -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active high)
            my_tag  := (others=>'0');
            
          else
            if( snoop_fetch_piperun = '1' ) then
              -- "Port A" - Read only
              snoop_req_current_tag <= my_tag;
            end if;
            if( ( snoop_update_we_i = '1' ) and ( snoop_update_we = "1" ) ) then
              -- "Port B" - Write only
              my_tag                := snoop_update_new_tag;
            end if;
          end if;
        end if;
      end process One_Line_Filter_Handler;
    
    end generate One_Liner;
    Use_Multi: if( Lx_ADDR_LINE_TYPE'length /= 0 ) generate
    begin
      Filter: sc_ram_module 
        generic map(
          C_TARGET                  => C_TARGET,
          C_WE_A_WIDTH              => 1,
          C_DATA_A_WIDTH            => C_Lx_TAG_SIZE,
          C_ADDR_A_WIDTH            => Lx_ADDR_LINE_TYPE'length,
          C_WE_B_WIDTH              => 1,
          C_DATA_B_WIDTH            => C_Lx_TAG_SIZE,
          C_ADDR_B_WIDTH            => Lx_ADDR_LINE_TYPE'length,
          C_FORCE_BRAM              => false,
          C_FORCE_LUTRAM            => false
        )
        port map(
          -- PORT A
          CLKA                      => ACLK,
          ENA                       => snoop_fetch_piperun,
          WEA                       => "0",
          ADDRA                     => snoop_fetch_addr_i,
          DATA_INA                  => (C_Lx_TAG_POS=>'0'),
          DATA_OUTA                 => snoop_req_current_tag,
          -- PORT B
          CLKB                      => ACLK,
          ENB                       => snoop_update_we_i,
          WEB                       => snoop_update_we,
          ADDRB                     => snoop_update_addr,
          DATA_INB                  => snoop_update_new_tag,
          DATA_OUTB                 => open
        );
      
    end generate Use_Multi;
    
    
    -----------------------------------------------------------------------------
    -- Snoop Request Evaluation
    -----------------------------------------------------------------------------
    
    -- Extract TAG bits
    snoop_req_tag_valid     <= snoop_req_current_tag(C_Lx_TAG_VALID_POS);
    snoop_req_tag_locked    <= snoop_req_current_tag(C_Lx_TAG_LOCKED_POS);
    snoop_req_tag_dirty     <= snoop_req_current_tag(C_Lx_TAG_DIRTY_POS);
    snoop_req_tag_unique    <= snoop_req_current_tag(C_Lx_TAG_UNIQUE_POS);
    snoop_req_tag_addr      <= snoop_req_current_tag(C_Lx_TAG_ADDR_POS);
    
    -- Detect Locked Hazard.
    snoop_req_prot_access   <= '1' when ( ( snoop_req_write = '1' ) or 
                                          ( snoop_req_snoop = C_ARSNOOP_CleanInvalid ) ) else
                               '0';
    snoop_req_fud_protected <= snoop_req_hit and snoop_req_prot_access and snoop_req_tag_locked and 
                               not snoop_req_tag_overwritten;
    
    -- Detect tag and snoop hit.
    snoop_req_tag_hit       <= snoop_req_tag_valid when snoop_req_addr(C_Lx_ADDR_TAG_POS) = snoop_req_tag_addr else '0';
    snoop_req_hit           <= ( ( snoop_req_tag_hit and snoop_req_want ) or 
                                 ( snoop_req_always ) ) and 
                               snoop_req_valid;
    
    
    -- Move Snoop Request to Snoop Update (Information).
    Snoop_Update_Handler : process (ACLK) is
    begin  -- process Snoop_Update_Handler
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_fud_valid         <= '0';
          snoop_act_fud_hit           <= '0';
          snoop_act_fud_make_valid    <= '0';
          snoop_act_fud_make_invalid  <= '0';
          snoop_act_fud_make_unique   <= '0';
          snoop_act_fud_make_shared   <= '0';
          snoop_act_fud_make_clean    <= '0';
          snoop_act_ac_complete       <= '0';
          
        elsif( snoop_req_piperun = '1' ) then
          -- Set Filter Update acording to request.
          snoop_act_fud_valid         <= snoop_req_hit or ( snoop_req_valid and snoop_req_update_filter );
          snoop_act_fud_hit           <= snoop_req_hit;
          
          -- Default assignment
          snoop_act_fud_make_valid    <= '0';
          snoop_act_fud_make_invalid  <= '0';
          snoop_act_fud_make_unique   <= '0';
          snoop_act_fud_make_shared   <= '0';
          snoop_act_fud_make_clean    <= '0';
          
          -- Transfer
          snoop_act_ac_complete       <= snoop_req_valid and ( snoop_req_complete and snoop_req_complete_done );
          
          -- AR an AC snoop has the same encoding (use AR becaus this is a mix and AC dosn't have all).
          case snoop_req_snoop is
            when C_ARSNOOP_ReadOnce           =>
              -- No change (snoop without touching).
              null;
              
            when C_ARSNOOP_ReadShared         =>
              -- Only support for MB subset (allocate myself and make others shared).
              null;
              
            when C_ARSNOOP_ReadClean          =>
              snoop_act_fud_make_valid    <= snoop_req_myself;
              snoop_act_fud_make_shared   <= int_to_std(C_S_AXI_SUPPORT_UNIQUE) and not snoop_req_myself;
              
            when C_ARSNOOP_ReadNotSharedDirty =>
              -- Only support for MB subset (allocate myself and make others shared).
              null;
              
            when C_ARSNOOP_ReadUnique         =>
              -- Only support for MB subset (make invalid except for myself).
              null;
              
            when C_ARSNOOP_CleanUnique        =>
              snoop_act_fud_make_unique   <= int_to_std(C_S_AXI_SUPPORT_UNIQUE);
              
            when C_ARSNOOP_MakeUnique         =>
              -- Only support for MB subset (make myself unique, invalidate others).
              null;
              
            when C_ARSNOOP_CleanShared        =>
              -- Only support for MB subset (force others to write a dirty line).
              null;
              
            when C_ARSNOOP_CleanInvalid       =>
              -- Make all cached copies invalid and write dirty data to memory.
              snoop_act_fud_make_invalid  <= '1';
              
            when C_ARSNOOP_MakeInvalid        =>
              -- Make all caches invalid ignore dirty data.
              snoop_act_fud_make_invalid  <= '1';
              
            when C_ARSNOOP_DVMComplete        =>
              -- No Filter changes.
              null;
              
            when C_ARSNOOP_DVMMessage         =>
              -- No Filter changes.
              null;
              
            when others                       =>
              -- Illegal operation.
              null;
          end case;
          
        elsif( snoop_act_piperun = '1' ) then
          -- When transaction leaves stage restore valid signal.
          snoop_act_fud_valid         <= '0';
          snoop_act_ac_complete       <= '0';
          
        end if;
      end if;
    end process Snoop_Update_Handler;
    
    -- Protect Locked cache line.
    Snoop_Protect_Handler : process (ACLK) is
    begin  -- process Snoop_Protect_Handler
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_fud_protected    <= '0';
          
        elsif( snoop_req_piperun = '1' ) then
          -- Set protection when.
          snoop_act_fud_protected    <= snoop_req_fud_protected;
          
        elsif( snoop_act_release_prot = '1' ) then
          -- Release protection when conflict is solved.
          snoop_act_fud_protected    <= '0';
          
        end if;
      end if;
    end process Snoop_Protect_Handler;
    
    -- Move Snoop Request to Snoop Action (Information).
    Pipeline_Stage_Snoop_Act : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_tag_valid_i   <= '0';
          snoop_act_tag_locked_i  <= '0';
          snoop_act_tag_dirty_i   <= '0';
          snoop_act_tag_unique_i  <= '0';
          snoop_act_tag_addr_i    <= (others=>'0');
          snoop_act_just_done     <= '0';
          
        elsif( snoop_req_piperun = '1' ) then
          if( snoop_req_tag_overwritten = '1' ) then
            -- Tag has been updated while transaction has been stalling in Req, new
            -- values need to be used.
            snoop_act_tag_valid_i   <= snoop_req_new_tag_valid;
            snoop_act_tag_locked_i  <= '0';
            snoop_act_tag_dirty_i   <= snoop_req_new_tag_dirty;
            snoop_act_tag_unique_i  <= snoop_req_new_tag_unique;
            snoop_act_tag_addr_i    <= snoop_req_new_tag_addr;
            
          else
            -- Ordinary pipeline flow.
            snoop_act_tag_valid_i   <= snoop_req_tag_valid;
            snoop_act_tag_locked_i  <= snoop_req_tag_locked;
            snoop_act_tag_dirty_i   <= snoop_req_tag_dirty;
            snoop_act_tag_unique_i  <= snoop_req_tag_unique;
            snoop_act_tag_addr_i    <= snoop_req_tag_addr;
            
          end if;
          
          snoop_act_just_done     <= read_data_req_line_match and read_data_fud_we;
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act;
    
    -- Handle situation where data in req is superseeded by read data FUD.
    Pipeline_Stage_Snoop_Overwrite : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Overwrite
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_req_tag_overwritten <= '0';
          snoop_req_new_tag_valid   <= '0';
          snoop_req_new_tag_dirty   <= '0';
          snoop_req_new_tag_unique  <= '0';
          snoop_req_new_tag_addr    <= (others=>'0');
          
        else
          -- Data handling.
          if( ( ( read_data_req_line_match = '1' ) and ( snoop_read_data_filter_we = '1' ) ) or 
              ( ( read_data_fetch_line_match = '1') and ( snoop_read_data_filter_we = '1' ) and 
                ( snoop_fetch_myself = '1' ) ) ) then
            -- Remember that the Tag has just been updated by read data FUD.
            snoop_req_new_tag_valid   <= read_data_fud_tag_valid;
            snoop_req_new_tag_dirty   <= read_data_fud_tag_dirty;
            snoop_req_new_tag_unique  <= read_data_fud_tag_unique;
            snoop_req_new_tag_addr    <= read_data_fud_addr(C_Lx_ADDR_TAG_POS);
            
          end if;
          
          -- Control handling.
          if( ( read_data_req_line_match = '1' ) and ( snoop_read_data_filter_we = '1' ) ) then
            -- Remember that the Tag has just been updated by read data FUD.
            snoop_req_tag_overwritten <= '1';
            
          elsif( snoop_fetch_piperun = '1' ) then
            -- Refreshing my own snoop filter will not stall.
            snoop_req_tag_overwritten <= read_data_fetch_line_match and snoop_read_data_filter_we and 
                                         snoop_fetch_myself;
            
          elsif( snoop_req_piperun = '1' ) then
            -- Refreshing my own snoop filter will not stall.
            snoop_req_tag_overwritten <= '0';
            
          end if;
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Overwrite;
    
    -- Forward address to be checked for hazards.
    read_data_fetch_addr  <= snoop_fetch_addr(C_Lx_ADDR_DIRECT_POS);
    read_data_req_addr    <= snoop_req_addr(C_Lx_ADDR_DIRECT_POS);
    read_data_act_addr    <= snoop_act_addr(C_Lx_ADDR_DIRECT_POS);
    
    -- Determine if this transaction is a hazard in next pipe stage.
    snoop_req_hazard      <= '1' when ( snoop_req_valid = '1' )                    and 
                                      ( read_data_req_match = '1' )                and
                                      ( snoop_req_snoop /= C_ACSNOOP_DVMComplete ) and 
                                      ( snoop_req_snoop /= C_ACSNOOP_DVMMessage )  else
                             '0';
    
    -- Move Snoop Request to Snoop Action (Hazard).
    Pipeline_Stage_Snoop_Act_Hazard_AC : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Hazard_AC
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_ac_hazard     <= '0';
          snoop_act_read_blocked  <= '0';
          
        elsif( snoop_req_piperun = '1' ) then
          if( ( snoop_req_hazard = '1' ) and 
              ( ( read_data_ongoing = '1' ) or ( read_data_block_nested = '1' ) ) ) or
            ( snoop_req_fud_protected = '1' ) then
            snoop_act_ac_hazard     <= '1';
            snoop_act_read_blocked  <= read_data_block_nested;
          else
            snoop_act_ac_hazard     <= '0';
            snoop_act_read_blocked  <= '0';
          end if;
          
        elsif( snoop_act_piperun = '1' ) then
          snoop_act_ac_hazard     <= '0';
          snoop_act_read_blocked  <= '0';
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Hazard_AC;
    
    -- Set and reset condition for Act Read Hazard.
    snoop_act_set_read_hazard <= snoop_req_hazard and not read_data_ongoing and not read_data_block_nested;
    snoop_act_rst_read_hazard <= ( snoop_act_fud_protected ) or
                                 ( not snoop_act_want_ac ) or
                                 ( snoop_act_want_ac and snoop_act_completed_ac and not snoop_act_waiting_4_cr );
    
    Pipeline_Stage_Snoop_Act_Read_AC : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Read_AC
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_read_hazard <= '0';
          
        elsif( snoop_req_piperun = '1' ) then
          snoop_act_read_hazard <= snoop_act_set_read_hazard;
          
        elsif( snoop_act_rst_read_hazard = '1' ) then
          snoop_act_read_hazard <= '0';
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Read_AC;
    
    -- Track outstanding AR transaction.
    Pipeline_Stage_Snoop_Act_Track_AC : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Read_AC
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_waiting_4_cr    <= '0';
          snoop_act_current_num_ac  <= 0;
          
        else
          if( ( (S_AXI_ACVALID_I and S_AXI_ACREADY) = '1' ) and ( ari_push = '0' ) ) then
            snoop_act_waiting_4_cr    <= '1';
            snoop_act_current_num_ac  <= snoop_act_current_num_ac + 1;
          elsif( ( (S_AXI_ACVALID_I and S_AXI_ACREADY) = '0' ) and ( ari_push = '1' ) ) then
            if( snoop_act_current_num_ac = 1 ) then
              snoop_act_waiting_4_cr    <= '0';
            end if;
            snoop_act_current_num_ac  <= snoop_act_current_num_ac - 1;
          end if;
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Track_AC;
    
    -- Determine when it is safe to snoop.
    snoop_act_ac_safe       <= ( ( not snoop_act_ac_hazard ) or
                                 (     snoop_act_ac_hazard and snoop_act_read_blocked and read_data_release_block ) or
                                 (     snoop_act_ac_hazard and not read_data_ongoing ) ) and
                               ( ( not snoop_act_fud_protected ) or 
                                 ( snoop_act_fud_protected and snoop_act_release_prot ) );
    
    
    snoop_act_release_prot  <= snoop_read_data_filter_we when 
                                      read_data_fud_addr(C_Lx_ADDR_LINE_POS) = snoop_act_addr(C_Lx_ADDR_LINE_POS) else
                               '0';
    
    -- Determine if a cache line has been reused (killed).
    snoop_act_kill_locked   <= snoop_act_valid and snoop_act_myself and not snoop_act_write and 
                               snoop_act_fud_we and snoop_act_tag_locked_i and not snoop_act_just_done and 
                               not ( snoop_act_tag_collision and read_data_act_line_match ) and 
                               not snoop_act_waiting_4_pipe;
    snoop_act_kill_addr     <= snoop_act_addr(C_Lx_ADDR_DIRECT_POS);
    
    
    -----------------------------------------------------------------------------
    -- Snoop Update
    -- 
    -- Update the snoop filter according to current transaction/snoop. The info 
    -- handled are: Valid, Unique/Shared, Dirty/Clean and address.
    -- 
    -----------------------------------------------------------------------------
    
    -- Determine if snoop filter should indeed be updated.
    snoop_update_we         <= (others=>snoop_update_we_i);
    snoop_update_we_i       <= snoop_read_data_filter_we or snoop_act_fud_we;
    snoop_act_fud_we        <= snoop_act_fud_valid and 
                               ( ( snoop_act_fud_make_valid   and 
                                   ( not snoop_act_tag_valid_i or not snoop_act_fud_hit )    ) or 
                                 ( snoop_act_fud_make_invalid and     snoop_act_tag_valid_i  ) or 
                                 ( snoop_act_fud_make_unique  and not snoop_act_tag_unique_i ) or 
                                 ( snoop_act_fud_make_shared  and     snoop_act_tag_unique_i ) );
    
    -- Get address for current Tag.
    snoop_update_addr       <= read_data_fud_addr(C_Lx_ADDR_LINE_POS) when (snoop_read_data_filter_we  = '1' ) else
                               snoop_act_addr(C_Lx_ADDR_LINE_POS);
    
    -- Generate new Tag contents.
    snoop_update_tag_valid  <= ( snoop_act_fud_make_valid or snoop_act_tag_valid_i ) and 
                               not snoop_act_fud_make_invalid;
    snoop_update_tag_lock   <= snoop_act_fud_make_valid and not snoop_act_fud_hit;
    snoop_update_tag_dirty  <= '0';
-- TODO: snoop_info_tag_valid should disregard this port.
    snoop_update_tag_unique <= ( ( snoop_act_fud_make_valid and not reduce_or(snoop_info_tag_valid) ) or 
                                 ( snoop_act_fud_make_unique ) ) and 
                                int_to_std(C_S_AXI_SUPPORT_UNIQUE);
    snoop_update_tag_addr   <= snoop_act_addr(C_Lx_ADDR_TAG_POS) when ( snoop_act_fud_make_valid = '1' ) else 
                               snoop_act_tag_addr_i;
    
    Gen_Filter_Tag: process (snoop_update_tag_valid, snoop_update_tag_dirty, snoop_update_tag_unique, 
                             snoop_update_tag_addr, snoop_update_tag_lock, 
                             snoop_read_data_filter_we, read_data_fud_tag_valid, 
                             read_data_fud_tag_dirty, read_data_fud_tag_unique, read_data_fud_addr) is
    begin  -- process Gen_Filter_Tag
      -- Default value.
      snoop_update_new_tag                      <= (others=>'0');
    
      if( snoop_read_data_filter_we = '1' ) then
        -- Modification by allocating read moving to master.
        snoop_update_new_tag(C_Lx_TAG_VALID_POS)  <= read_data_fud_tag_valid;
        snoop_update_new_tag(C_Lx_TAG_LOCKED_POS) <= '0';
        
        if( C_S_AXI_SUPPORT_DIRTY /= 0 ) then
          snoop_update_new_tag(C_Lx_TAG_DIRTY_POS)  <= read_data_fud_tag_dirty;
        end if;
        
        if( C_S_AXI_SUPPORT_UNIQUE /= 0 ) then
          snoop_update_new_tag(C_Lx_TAG_UNIQUE_POS) <= read_data_fud_tag_unique;
        end if;
        
        snoop_update_new_tag(C_Lx_TAG_ADDR_POS)   <= read_data_fud_addr(C_Lx_ADDR_TAG_POS);
      else
        -- Direct modification by pipeline.
        snoop_update_new_tag(C_Lx_TAG_VALID_POS)  <= snoop_update_tag_valid;
        snoop_update_new_tag(C_Lx_TAG_LOCKED_POS) <= snoop_update_tag_lock;
        
        if( C_S_AXI_SUPPORT_DIRTY /= 0 ) then
          snoop_update_new_tag(C_Lx_TAG_DIRTY_POS)  <= snoop_update_tag_dirty;
        end if;
        
        if( C_S_AXI_SUPPORT_UNIQUE /= 0 ) then
          snoop_update_new_tag(C_Lx_TAG_UNIQUE_POS) <= snoop_update_tag_unique;
        end if;
        
        snoop_update_new_tag(C_Lx_TAG_ADDR_POS)   <= snoop_update_tag_addr;
      end if;
    end process Gen_Filter_Tag;
    
    -- Forward end value.
    snoop_info_tag_unique <= snoop_update_tag_unique;
    snoop_info_tag_dirty  <= snoop_update_tag_dirty;
    
    
    -----------------------------------------------------------------------------
    -- Snoop Action
    -----------------------------------------------------------------------------
    
    -- Make sure Action is only performed once.
    Pipeline_Stage_Snoop_Act_Wait : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Wait
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_wait_for_pipe <= '0';
          snoop_act_completed_ac  <= '0';
        else
          if( snoop_act_piperun = '1' ) then
            snoop_act_wait_for_pipe <= '0';
            snoop_act_completed_ac  <= '0';
          elsif( snoop_act_done_i = '1' ) then
            snoop_act_wait_for_pipe <= '1';
            snoop_act_completed_ac  <= snoop_act_allowed_ac;
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Wait;
    
    -- .
    Pipeline_Stage_Snoop_AC_Done : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_AC_Done
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_ac_done <= '0';
        else
          if( snoop_act_piperun = '1' ) then
            snoop_act_ac_done <= '0';
          elsif( ( S_AXI_ACVALID_I and S_AXI_ACREADY ) = '1' ) then
            snoop_act_ac_done <= '1';
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_AC_Done;
    
    -- Is there or has a transaction been completed.
    snoop_act_use_external  <= snoop_act_completed_ac or snoop_act_want_ac;
    
    -- Determine when Snoop should go external:
    --  * A valid update situation that is acted on, or
    --  * A DVM Complete needs has been collected.
    snoop_act_want_ac       <= ( snoop_act_fud_valid and 
                                 ( ( snoop_act_fud_we and not snoop_act_myself ) or snoop_act_always ) ) or
                               ( snoop_act_ac_complete );
    snoop_act_allowed_ac    <= snoop_act_want_ac and snoop_act_ac_safe;
    S_AXI_ACVALID_I         <= snoop_act_allowed_ac and not snoop_act_ac_done;
    
    -- Forward AC snoop information.
    S_AXI_ACVALID           <= S_AXI_ACVALID_I;
    S_AXI_ACADDR            <= fit_vec(snoop_act_addr, C_S_AXI_ADDR_WIDTH);
    S_AXI_ACSNOOP           <= snoop_act_snoop;
    S_AXI_ACPROT            <= snoop_act_prot;
    
    -- CR-Channel (coherency only)
    -- Only write-through MicroBlaze is supported as master at this point, 
    -- ignore response except error information (since nothing can be dirty).
    S_AXI_CRREADY           <= not ari_fifo_full;

    -- CD-Channel (coherency only)
    -- Only write-through MicroBlaze is supported as master at this point, 
    -- ignore response since nothing can be dirty.
    S_AXI_CDREADY           <= '1';
    
    -- Determine when stage is done:
    --  * Acknowledged AC message, or
    --  * No external message at all.
    snoop_act_done          <= snoop_act_done_i;
    snoop_act_done_i        <= snoop_act_valid and
                               ( not snoop_act_tag_collision ) and 
                               ( ( S_AXI_ACVALID_I and S_AXI_ACREADY ) or 
                                 snoop_act_ac_done or
                                 not snoop_act_want_ac );
    
    -- Assign output.
    snoop_act_tag_valid     <= snoop_act_tag_valid_i;
    snoop_act_tag_dirty     <= snoop_act_tag_dirty_i;
    snoop_act_tag_unique    <= snoop_act_tag_unique_i;
    
    -- Control signals for ACE Response Information queue.
    ari_push                <= S_AXI_CRVALID and not ari_fifo_full;
    ari_pop                 <= snoop_resp_ready and not ari_fifo_empty;
    
    FIFO_ARI_Pointer: sc_srl_fifo_counter
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
        
        queue_push                => ari_push,
        queue_pop                 => ari_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => open,
        queue_full                => ari_fifo_full,
        queue_almost_empty        => open,
        queue_empty               => ari_fifo_empty,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => ari_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => open, -- stat_acs_ari(I),
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => ari_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Handle memory for ARI Channel FIFO.
    FIFO_ARI_Memory : process (ACLK) is
    begin  -- process FIFO_ARI_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( ari_push = '1' ) then
          -- Insert new item.
          ari_fifo_mem(0).Resp  <= S_AXI_CRRESP;
          
          -- Shift FIFO contents.
          ari_fifo_mem(ari_fifo_mem'left downto 1) <= ari_fifo_mem(ari_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_ARI_Memory;
    
    -- Extract data.
    snoop_resp_valid  <= not ari_fifo_empty;
    snoop_resp_crresp <= ari_fifo_mem(to_integer(unsigned(ari_read_fifo_addr))).Resp;
    
    
    -----------------------------------------------------------------------------
    -- Sync Handling
    -----------------------------------------------------------------------------
    
    
    -- Generate current complete collection.
    Complete_Handler : process (complete_request_detected, snoop_req_complete_target) is
    begin  -- process Complete_Handler
      for I in 0 to C_NUM_PORTS - 2 loop
        if( I >= C_NUM_OPTIMIZED_PORTS - 1 ) then
          snoop_req_comp_with_cur(I)  <= '1';
          
        elsif( I < C_PORT_NUM ) then
          snoop_req_comp_with_cur(I)  <= complete_request_detected(I) or snoop_req_complete_target(I);
          
        elsif( I >= C_PORT_NUM ) then
          snoop_req_comp_with_cur(I)  <= complete_request_detected(I) or snoop_req_complete_target(I+1);
          
        end if;
      end loop;
    end process Complete_Handler;
    
    -- Handle the tracking of Sync to all Complete received.
    Sync_Handler : process (ACLK) is
    begin  -- process Sync_Handler
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          complete_request_detected <= (others=>'1');
          for I in 0 to C_NUM_PORTS - 2 loop
            if( I >= C_NUM_OPTIMIZED_PORTS - 1 ) then
              complete_request_detected(I)  <= '1';
            end if;
          end loop;
          
        else
          if( ( snoop_fetch_piperun = '1' ) and ( snoop_fetch_valid = '1' ) and ( snoop_fetch_sync = '1' ) )then
            complete_request_detected <= (others=>'0');
            
          elsif( ( snoop_req_piperun = '1' ) and ( snoop_req_complete = '1' ) ) then
            complete_request_detected <= snoop_req_comp_with_cur;
          end if;
        end if;
      end if;
    end process Sync_Handler;
    
    -- Determine if complete phase is done.
    snoop_req_complete_done <= snoop_req_complete when ( snoop_req_comp_with_cur = complete_one_vec ) else 
                               '0';
    
    -- Detect condition where an illgal second Sync is issued before the first has completed.
    sync_assert             <= snoop_fetch_piperun and snoop_fetch_valid and snoop_fetch_sync when 
                                      ( snoop_req_comp_with_cur /= complete_one_vec ) else 
                               '0';
    
    
    -----------------------------------------------------------------------------
    -- Read Data Filter Update
    -----------------------------------------------------------------------------
    
    -- Generate write signal.
    snoop_read_data_filter_we   <= read_data_fud_we;
    
    -- Stall pipe to make sure current is data is seen for next transaction.
    snoop_fetch_pos_hazard_i    <= read_data_fetch_line_match and read_data_ongoing and not snoop_fetch_myself;
    snoop_fetch_pos_hazard      <= snoop_fetch_pos_hazard_i;
    
    -- Stall pipe
    snoop_act_write_blocking_i  <= read_data_req_line_match and snoop_read_data_filter_we;
    snoop_act_write_blocking    <= snoop_act_write_blocking_i;
    
    -- Detect Collision in write to tag.
    snoop_act_tag_collision     <= ( snoop_act_fud_we and snoop_read_data_filter_we );
    
    
    -----------------------------------------------------------------------------
    -- Debug 
    -----------------------------------------------------------------------------
    
    No_Debug: if( not C_USE_DEBUG ) generate
    begin
      IF_DEBUG(255                  downto  74) <= (others=>'0');
    end generate No_Debug;
    
    Use_Debug: if( C_USE_DEBUG ) generate
      constant C_MY_QCNT    : natural := min_of( 4, C_QUEUE_LENGTH_BITS);
      constant C_MY_TAG     : natural := min_of(16, C_Lx_NUM_ADDR_TAG_BITS);
      constant C_MY_ADDR    : natural := min_of(16, C_Lx_ADDR_LINE_HI - C_Lx_ADDR_LINE_LO + 1);
      constant C_MY_DADDR   : natural := min_of(28, C_Lx_ADDR_DIRECT_HI - C_Lx_ADDR_DIRECT_LO + 1);
      constant C_MY_PORT    : natural := min_of( 4, C_NUM_PORTS);
      constant C_MY_COMP    : natural := min_of( 3, C_NUM_PORTS - 1);
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active true)
            IF_DEBUG(255                  downto  74) <= (others=>'0');
          else
            -- Default assignment.
            IF_DEBUG(255                  downto  74) <= (others=>'0');
            
            IF_DEBUG(                             74) <= snoop_req_valid;
            IF_DEBUG(                             75) <= snoop_req_write;
            IF_DEBUG(                             76) <= snoop_req_myself;
            IF_DEBUG(                             77) <= snoop_req_always;
            IF_DEBUG(                             78) <= snoop_req_update_filter;
            IF_DEBUG(                             79) <= snoop_req_want;
            IF_DEBUG(                             80) <= snoop_act_valid;
            IF_DEBUG(                             81) <= snoop_act_myself;
            IF_DEBUG(                             82) <= snoop_act_always;
            IF_DEBUG(                             83) <= snoop_act_tag_valid_i;
            IF_DEBUG(                             84) <= snoop_act_tag_dirty_i;
            IF_DEBUG(                             85) <= snoop_act_tag_unique_i;
            IF_DEBUG(                             86) <= snoop_act_done_i;
            IF_DEBUG(                             87) <= snoop_act_completed_ac or snoop_act_want_ac; -- snoop_act_use_external
            IF_DEBUG(                             88) <= not ari_fifo_empty;                          -- snoop_resp_valid
            IF_DEBUG(                             89) <= snoop_resp_ready;
            IF_DEBUG(                             90) <= snoop_read_data_valid;
            IF_DEBUG(                             91) <= snoop_read_data_last;
            IF_DEBUG(                             92) <= snoop_read_data_ready_i;
            IF_DEBUG(                             93) <= ari_push;
            IF_DEBUG(                             94) <= ari_pop;
            IF_DEBUG(                             95) <= ari_fifo_full;
            IF_DEBUG(                             96) <= ari_fifo_empty;
            IF_DEBUG(                             97) <= ari_assert;
            IF_DEBUG(                             98) <= S_AXI_ACVALID_I;
            IF_DEBUG(                             99) <= snoop_act_want_ac;
            IF_DEBUG(                            100) <= snoop_act_completed_ac;
            IF_DEBUG(                            101) <= snoop_act_wait_for_pipe;
            IF_DEBUG(                            102) <= snoop_act_fud_valid;
            IF_DEBUG(                            103) <= snoop_act_fud_make_valid;
            IF_DEBUG(                            104) <= snoop_act_fud_make_invalid;
            IF_DEBUG(                            105) <= snoop_act_fud_make_unique;
            IF_DEBUG(                            106) <= snoop_act_fud_make_shared;
            IF_DEBUG(                            107) <= snoop_act_fud_make_clean;
            IF_DEBUG(                            108) <= snoop_act_fud_we;
            IF_DEBUG(                            109) <= snoop_update_tag_valid;
            IF_DEBUG(                            110) <= snoop_update_tag_dirty;
            IF_DEBUG(                            111) <= snoop_update_tag_unique;
            IF_DEBUG(                            112) <= snoop_req_tag_hit;
            IF_DEBUG(                            113) <= snoop_req_hit;
            IF_DEBUG(                            114) <= snoop_req_tag_valid;
            IF_DEBUG(                            115) <= snoop_req_tag_dirty;
            IF_DEBUG(                            116) <= snoop_req_tag_unique;
            IF_DEBUG(                            117) <= snoop_read_data_filter_we;
            IF_DEBUG(                            118) <= snoop_act_read_blocked;
            IF_DEBUG(                            119) <= snoop_act_ac_hazard;
            IF_DEBUG(                            120) <= snoop_act_ac_safe;
            
            IF_DEBUG(                            121) <= snoop_fetch_myself;
            IF_DEBUG(                            122) <= snoop_fetch_pos_hazard_i;
            IF_DEBUG(                            123) <= snoop_req_hazard;
            IF_DEBUG(                            124) <= snoop_req_tag_overwritten;
            IF_DEBUG(                            125) <= snoop_req_new_tag_valid;
            IF_DEBUG(                            126) <= snoop_req_new_tag_dirty;
            IF_DEBUG(                            127) <= snoop_req_new_tag_unique;
            IF_DEBUG(                            128) <= snoop_act_write_blocking_i;
            IF_DEBUG(                            129) <= snoop_act_read_hazard;
            IF_DEBUG(                            130) <= read_data_fetch_line_match;
            IF_DEBUG(                            131) <= read_data_req_match;
            IF_DEBUG(                            132) <= read_data_ongoing;
            IF_DEBUG(                            133) <= read_data_block_nested;
            IF_DEBUG(                            134) <= read_data_release_block;
            IF_DEBUG(                            135) <= read_data_fud_we;
            IF_DEBUG(                            136) <= read_data_fud_tag_valid;
            IF_DEBUG(                            137) <= read_data_fud_tag_unique;
            IF_DEBUG(                            138) <= read_data_fud_tag_dirty;
            IF_DEBUG(                            139) <= snoop_act_allowed_ac;
            IF_DEBUG(                            140) <= snoop_act_waiting_4_cr;
            IF_DEBUG(                            141) <= snoop_fetch_sync;
            IF_DEBUG(                            142) <= snoop_req_complete_done;
            IF_DEBUG(                            143) <= snoop_req_complete;
            IF_DEBUG(                            144) <= snoop_act_ac_complete;
            IF_DEBUG(                            145) <= snoop_act_fud_hit;
            IF_DEBUG(                            146) <= snoop_act_fud_protected;
            IF_DEBUG(                            147) <= snoop_req_tag_locked;
            IF_DEBUG(                            148) <= snoop_update_tag_lock;
            IF_DEBUG(                            149) <= snoop_act_release_prot;
            IF_DEBUG(                            150) <= snoop_req_fud_protected;
            IF_DEBUG(                            151) <= lookup_read_data_allocate;
            IF_DEBUG(                            152) <= snoop_fetch_valid;
            IF_DEBUG(                            153) <= snoop_act_kill_locked;
            IF_DEBUG(                            154) <= snoop_act_waiting_4_pipe;
            IF_DEBUG(                            155) <= snoop_act_tag_locked_i;
            IF_DEBUG(                            156) <= snoop_act_write;
            IF_DEBUG(                            155) <= RIF_DEBUG(150); -- rk_empty;
            IF_DEBUG(                            156) <= RIF_DEBUG(151); -- read_data_fud_is_dead;
            IF_DEBUG(                            157) <= read_data_req_line_match;
            IF_DEBUG(                            158) <= read_data_act_line_match;
            IF_DEBUG(                            159) <= snoop_act_just_done;
            
            
            IF_DEBUG(160 + C_MY_ADDR  - 1 downto 160) <= snoop_fetch_addr_i(C_Lx_ADDR_LINE_LO + C_MY_ADDR - 1 downto C_Lx_ADDR_LINE_LO);
            IF_DEBUG(176 + C_MY_TAG   - 1 downto 176) <= snoop_req_new_tag_addr(C_MY_TAG - 1 downto 0);
            IF_DEBUG(192 + C_MY_DADDR - 1 downto 192) <= read_data_fud_addr(C_Lx_ADDR_DIRECT_LO + C_MY_DADDR - 1 downto C_Lx_ADDR_DIRECT_LO);
            IF_DEBUG(220 + C_MY_QCNT  - 1 downto 220) <= ari_read_fifo_addr(C_MY_QCNT - 1 downto 0);
            IF_DEBUG(224 + C_MY_PORT  - 1 downto 224) <= snoop_req_complete_target(C_MY_PORT - 1 downto 0);
            IF_DEBUG(228 + C_MY_COMP  - 1 downto 228) <= complete_request_detected(C_MY_COMP - 1 downto 0);
            
            IF_DEBUG(                            160) <= RIF_DEBUG( 42); -- S_AXI_RREADY;
            IF_DEBUG(                            161) <= RIF_DEBUG(157); -- ri_push;
            IF_DEBUG(                            162) <= RIF_DEBUG(158); -- ri_pop;
            IF_DEBUG(                            163) <= RIF_DEBUG(159); -- ri_exist;
            IF_DEBUG(                            164) <= RIF_DEBUG(160); -- ri_hit;
            IF_DEBUG(                            165) <= RIF_DEBUG(165); -- r_hit_pop;
            IF_DEBUG(                            166) <= RIF_DEBUG(166); -- r_miss_pop;
            IF_DEBUG(                            167) <= RIF_DEBUG(167); -- r_pop_safe;
            IF_DEBUG(                            168) <= RIF_DEBUG(236); -- r_last;
            IF_DEBUG(                            169) <= RIF_DEBUG(237); -- ri_allocate;
            
            IF_DEBUG(                            170) <= snoop_req_prot_access;
            IF_DEBUG(                            171) <= snoop_act_ac_done;
            
          end if;
        end if;
      end process Debug_Handle;
    
--      IF_DEBUG(255                  downto  74)  <= RIF_DEBUG(255 downto 74);
      
    end generate Use_Debug;
    
  end generate Use_Coherency;

  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_s_axi_rd_segments      <= C_NULL_STAT_POINT;
    stat_s_axi_wr_segments      <= C_NULL_STAT_POINT;
    stat_s_axi_rd_latency       <= C_NULL_STAT_POINT;
    stat_s_axi_wr_latency       <= C_NULL_STAT_POINT;
    
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
    
    Wr_Segments_Inst: sc_stat_counter
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
        
        update                    => aw_start,
        counter                   => C_STAT_ONE,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
      
        stat_data                 => stat_s_axi_wr_segments
      );
      
    Rd_Segments_Inst: sc_stat_counter
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_SIMPLE_COUNTER     => 0,
        C_STAT_BITS               => C_STAT_BITS,
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
        
        update                    => ar_start,
        counter                   => C_STAT_ONE,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_s_axi_rd_segments
      );
      
    Latency_Inst: sc_stat_latency
      generic map(
        -- General.
        C_TARGET                  => C_TARGET,
        
        -- Configuration.
        C_STAT_LATENCY_RD_DEPTH   => C_STAT_OPT_LAT_RD_DEPTH,
        C_STAT_LATENCY_WR_DEPTH   => C_STAT_OPT_LAT_WR_DEPTH,
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
        
        stat_rd_latency           => stat_s_axi_rd_latency,
        stat_wr_latency           => stat_s_axi_wr_latency,
        stat_rd_latency_conf      => stat_s_axi_rd_latency_conf,
        stat_wr_latency_conf      => stat_s_axi_wr_latency_conf
      );
    
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG( 73                  downto   0)  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_QCNT    : natural := min_of( 4, C_QUEUE_LENGTH_BITS);
    constant C_MY_ADDR    : natural := min_of(16, C_Lx_ADDR_LINE_HI - C_Lx_ADDR_LINE_LO + 1);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          IF_DEBUG( 73                  downto   0)  <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG( 73                  downto   0)  <= (others=>'0');
          
          IF_DEBUG(  0 + C_MY_QCNT  - 1 downto   0) <= wip_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          IF_DEBUG(  4 + C_MY_QCNT  - 1 downto   4) <= w_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          IF_DEBUG(  8 + C_MY_QCNT  - 1 downto   8) <= bip_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          IF_DEBUG( 12 + C_MY_QCNT  - 1 downto  12) <= bp_read_fifo_addr(C_MY_QCNT - 1 downto 0);
          IF_DEBUG(                             16) <= access_bp_early;
          IF_DEBUG(                             17) <= bp_fifo_full_i;
          IF_DEBUG(                             18) <= update_ext_bresp_valid;
          IF_DEBUG(                             19) <= update_ext_bresp_ready_i;
          IF_DEBUG(                             20) <= wr_port_data_valid_i;
          IF_DEBUG(                             21) <= wr_port_data_last_i;
          IF_DEBUG(                             22) <= wr_port_data_ready;
          IF_DEBUG(                             23) <= wip_push;
          IF_DEBUG(                             24) <= wip_pop;
          IF_DEBUG(                             25) <= wip_refresh_reg;
          IF_DEBUG(                             26) <= wip_exist;
          IF_DEBUG(                             27) <= wip_assert;
          IF_DEBUG(                             28) <= w_push;
          IF_DEBUG(                             29) <= w_push_safe;
          IF_DEBUG(                             30) <= w_pop;
          IF_DEBUG(                             31) <= w_pop_safe;
          IF_DEBUG(                             32) <= w_fifo_full;
          IF_DEBUG(                             33) <= w_fifo_empty;
          IF_DEBUG(                             34) <= w_valid;
          IF_DEBUG(                             35) <= w_last;
          IF_DEBUG(                             36) <= w_ready;
          IF_DEBUG(                             37) <= w_assert;
          IF_DEBUG(                             38) <= S_AXI_WREADY_I;
          IF_DEBUG(                             39) <= read_req_valid;
          IF_DEBUG(                             40) <= read_req_single;
          IF_DEBUG(                             41) <= read_req_ready;
          IF_DEBUG(                             42) <= S_AXI_RVALID_I;
          IF_DEBUG(                             43) <= S_AXI_RLAST_I;
          IF_DEBUG(                             44) <= bip_push;
          IF_DEBUG(                             45) <= bip_pop;
          IF_DEBUG(                             46) <= bip_fifo_full;
          IF_DEBUG(                             47) <= bip_assert;
          IF_DEBUG(                             48) <= bp_pop;
          IF_DEBUG(                             49) <= bp_valid;
          IF_DEBUG(                             50) <= bp_ready;
          IF_DEBUG(                             51) <= bp_fifo_empty;
          IF_DEBUG(                             52) <= bp_early;
          IF_DEBUG(                             53) <= S_AXI_BVALID_I;
          IF_DEBUG(                             54) <= bp_assert;
          IF_DEBUG(                             55) <= S_AXI_BREADY;
          IF_DEBUG(                             56) <= access_bp_push;
          IF_DEBUG(                             57) <= lookup_read_data_new;
          IF_DEBUG(                             58) <= lookup_read_data_hit;
          IF_DEBUG(                             59) <= lookup_read_data_snoop;
          IF_DEBUG(                             60) <= wr_port_access_i.Valid;
          IF_DEBUG(                             61) <= wr_port_ready;
          IF_DEBUG(                             62) <= rd_port_access_i.Valid;
          IF_DEBUG(                             63) <= rd_port_ready;
          IF_DEBUG(                             64) <= arbiter_piperun;
          IF_DEBUG(                             65) <= snoop_fetch_piperun;
          IF_DEBUG(                             66) <= snoop_req_piperun;
          IF_DEBUG(                             67) <= snoop_act_piperun;
          IF_DEBUG(                             68) <= lookup_read_data_valid;
          IF_DEBUG(                             69) <= lookup_read_data_last;
          IF_DEBUG(                             70) <= lookup_read_data_ready_i;
          IF_DEBUG(                             71) <= update_read_data_valid;
          IF_DEBUG(                             72) <= update_read_data_last;
          IF_DEBUG(                             73) <= update_read_data_ready_i;
          
        end if;
      end if;
    end process Debug_Handle;
  
--    IF_DEBUG( 73                  downto   0)  <= RIF_DEBUG(73 downto 0);
    
  end generate Use_Debug;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- ----------------------------------------
  -- Detect incorrect behaviour
  
  Assertions: block
  begin
    -- Detect condition
    assert_err(C_ASSERT_WIP_QUEUE_ERROR)  <= wip_assert   when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_W_QUEUE_ERROR)    <= w_assert     when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_BIP_QUEUE_ERROR)  <= bip_assert   when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_BP_QUEUE_ERROR)   <= bp_assert    when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_R_CHANNEL_ERROR)  <= r_assert     when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_SYNC_ERROR)       <= sync_assert  when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_WIP_QUEUE_ERROR) /= '1' 
      report "Optimized AXI: Erroneous handling of WIP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_W_QUEUE_ERROR) /= '1' 
      report "Optimized AXI: Erroneous handling of W Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BIP_QUEUE_ERROR) /= '1' 
      report "Optimized AXI: Erroneous handling of BIP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BP_QUEUE_ERROR) /= '1' 
      report "Optimized AXI: Erroneous handling of BP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_R_CHANNEL_ERROR) /= '1' 
      report "Optimized AXI: R Channel error."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_SYNC_ERROR) /= '1' 
      report "Optimized AXI: Sync before all Complete has been received."
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


