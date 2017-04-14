-------------------------------------------------------------------------------
-- sc_access.vhd - Entity and architecture
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
-- Filename:        sc_access.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_access.vhd
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


entity sc_access is
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
    
    -- Data type and settings specific.
    C_Lx_ADDR_LINE_HI         : natural range  4 to   63      := 13;
    C_Lx_ADDR_LINE_LO         : natural range  4 to   63      :=  7;
    
    -- IP Specific.
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_PORTS               : natural range  1 to   32      :=  1;
    C_ENABLE_COHERENCY        : natural range  0 to    1      :=  0;
    C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
    C_ID_WIDTH                : natural range  1 to   32      :=  1;
    
    -- Data type and settings specific.
    C_CACHE_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_ADDR_OFFSET_HI          : natural range  2 to   63      :=  6;
    C_ADDR_OFFSET_LO          : natural range  0 to   63      :=  0
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write Data).
    
    wr_port_data_valid        : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    wr_port_data_last         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    wr_port_data_be           : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
    wr_port_data_word         : in  std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
    wr_port_data_ready        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Snoop communication).
    
    snoop_fetch_piperun       : out std_logic;
    snoop_fetch_valid         : out std_logic;
    snoop_fetch_addr          : out AXI_ADDR_TYPE;
    snoop_fetch_myself        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_fetch_sync          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_fetch_pos_hazard    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    snoop_req_piperun         : out std_logic;
    snoop_req_valid           : out std_logic;
    snoop_req_write           : out std_logic;
    snoop_req_size            : out AXI_SIZE_TYPE;
    snoop_req_addr            : out AXI_ADDR_TYPE;
    snoop_req_snoop           : out AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
    snoop_req_myself          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_req_always          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_req_update_filter   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_req_want            : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_req_complete        : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_req_complete_target : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    snoop_act_piperun         : out std_logic;
    snoop_act_valid           : out std_logic;
    snoop_act_waiting_4_pipe  : out std_logic;
    snoop_act_write           : out std_logic;
    snoop_act_addr            : out AXI_ADDR_TYPE;
    snoop_act_prot            : out AXI_PROT_TYPE;
    snoop_act_snoop           : out AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
    snoop_act_myself          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_always          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_tag_valid       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_tag_unique      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_tag_dirty       : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_done            : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_use_external    : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_act_write_blocking  : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    snoop_info_tag_valid      : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_info_tag_unique     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_info_tag_dirty      : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    snoop_resp_valid          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_resp_crresp         : in  AXI_CRRESP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
    snoop_resp_ready          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    read_data_ex_rack         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Arbiter signals.
    
    arb_access                : in  ARBITRATION_TYPE;
    arb_access_id             : in  std_logic_vector(C_ID_WIDTH - 1 downto 0);
    
    arbiter_bp_push           : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    arbiter_bp_early          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    wr_port_inbound           : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
     
    -- ---------------------------------------------------
    -- Lookup signals.
    
    lookup_piperun            : in  std_logic;
    
    lookup_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Update signals.
    
    update_write_data_ready   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Access signals (for Arbiter).
    
    access_piperun            : out std_logic;
    access_write_priority     : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_other_write_prio   : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    access_bp_push            : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_bp_early           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Access signals (to Lookup/Update).
    
    access_valid              : out std_logic;
    access_info               : out ACCESS_TYPE;
    access_use                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    access_stp                : out std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    access_id                 : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
    
    access_data_valid         : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_data_last          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_data_be            : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH/8 - 1 downto 0);
    access_data_word          : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Snoop signals (Read Data & response).
    
    snoop_read_data_valid     : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    snoop_read_data_last      : out std_logic;
    snoop_read_data_resp      : out AXI_RRESP_TYPE;
    snoop_read_data_word      : out std_logic_vector(C_NUM_PORTS * C_CACHE_DATA_WIDTH - 1 downto 0);
    snoop_read_data_ready     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    stat_access_valid         : out STAT_POINT_TYPE;    -- Time valid per transaction
    stat_access_stall         : out STAT_POINT_TYPE;    -- Time stalled per transaction
    stat_access_fetch_stall   : out STAT_POINT_TYPE;    -- Time stalled per transaction (fetch)
    stat_access_req_stall     : out STAT_POINT_TYPE;    -- Time stalled per transaction (req)
    stat_access_act_stall     : out STAT_POINT_TYPE;    -- Time stalled per transaction (act)
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug signals.
    
    ACCESS_DEBUG              : out std_logic_vector(255 downto 0)
  );
end entity sc_access;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_access is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Access transaction control.
  -- 
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  1;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_ADDR_OFFSET_BITS             : natural := C_ADDR_OFFSET_HI - C_ADDR_OFFSET_LO + 1;
  
  subtype C_Lx_ADDR_LINE_POS          is natural range C_Lx_ADDR_LINE_HI          downto C_Lx_ADDR_LINE_LO;
  subtype Lx_ADDR_LINE_TYPE           is std_logic_vector(C_Lx_ADDR_LINE_POS);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Port related.
  subtype C_PORT_POS                  is natural range C_NUM_PORTS - 1 downto 0;
  subtype PORT_TYPE                   is std_logic_vector(C_PORT_POS);
  
  type PORT_POS_ARRAY_TYPE            is array(C_PORT_POS) of C_PORT_POS;
  
  -- Address related.
  subtype C_ADDR_OFFSET_POS           is natural range C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO;
  subtype ADDR_OFFSET_TYPE            is std_logic_vector(C_ADDR_OFFSET_POS);
  
  subtype C_BYTE_MASK_POS             is natural range C_ADDR_OFFSET_HI + 7 downto 7;
  subtype C_HALF_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 6 downto 6;
  subtype C_WORD_MASK_POS             is natural range C_ADDR_OFFSET_HI + 5 downto 5;
  subtype C_DOUBLE_WORD_MASK_POS      is natural range C_ADDR_OFFSET_HI + 4 downto 4;
  subtype C_QUAD_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 3 downto 3;
  subtype C_OCTA_WORD_MASK_POS        is natural range C_ADDR_OFFSET_HI + 2 downto 2;
  subtype C_HEXADECA_WORD_MASK_POS    is natural range C_ADDR_OFFSET_HI + 1 downto 1;
  subtype C_TRIACONTADI_MASK_POS      is natural range C_ADDR_OFFSET_HI + 0 downto 0;
  
  
  -- Custom data structures.
  type SS_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
  end record SS_TYPE;
  
  type RS_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Resp_Mask         : PORT_TYPE;
    No_Forward        : std_logic;
    Exclusive_Ok      : std_logic;
  end record RS_TYPE;
  
  -- Empty data structures.
  constant C_NULL_SS                  : SS_TYPE   := (Port_Num=>0);
  constant C_NULL_RS                  : RS_TYPE   := (Port_Num=>0, Resp_Mask=>(others=>'0'), No_Forward=>'0',
                                                      Exclusive_Ok=>'0');
  
  -- Types for information queue storage.
  type SS_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS) of SS_TYPE;
  type RS_FIFO_MEM_TYPE               is array(QUEUE_ADDR_POS) of RS_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component carry_vec_and_n is
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
  end component carry_vec_and_n;
  
  component carry_and_n is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE
      );
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and_n;
  
  component carry_or_n is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE
      );
    port (
      Carry_IN  : in  std_logic;
      A_N       : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_or_n;
  
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
--  attribute keep                    : string;
--  attribute keep                    of Reset_Inst     : label is "true";
  
  -- Guide Vivado Synthesis to handle control set as intended.
--  attribute direct_reset            : string;
--  attribute direct_reset            of ARESET_I       : signal is "true";
  
  
  -- ----------------------------------------
  -- Pipeline Stage: Access
  
  signal lookup_piperun_post1       : std_logic;
  signal lookup_piperun_i           : std_logic;
  signal access_piperun_i           : std_logic;
  signal extended_length            : std_logic_vector(C_ADDR_OFFSET_BITS + 15 - 1 downto 0);
  
  signal access_valid_i             : std_logic;
  signal access_info_i              : ACCESS_TYPE;
  
  signal access_evict_line          : std_logic;
  signal access_evict_1st_cycle     : std_logic;
  signal access_evict_2nd_cycle     : std_logic;
  signal access_evict_inserted      : std_logic;
  signal access_stall               : std_logic;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
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
  -- Pipeline Stage: Access
  -- 
  -----------------------------------------------------------------------------
  
  -- Move this stage when there is no stall or there is a bubble to fill.
--  access_piperun  <= ( lookup_piperun or not access_valid_i ) and not access_stall;
  FE_Acs_PR_Or_Inst1: carry_or_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_piperun,
      A_N       => access_valid_i,
      Carry_OUT => lookup_piperun_post1
    );
  FE_Acs_PR_And_Inst1: carry_and_n 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => lookup_piperun_post1,
      A_N       => access_stall,
      Carry_OUT => lookup_piperun_i
    );
  access_piperun  <= access_piperun_i;
  
  
  -----------------------------------------------------------------------------
  -- Non Coherent
  -----------------------------------------------------------------------------
  No_Coherency: if( C_ENABLE_COHERENCY = 0 ) generate
  begin
    -- No maipulation of piperun
    access_piperun_i            <= lookup_piperun_i;
    
    -- Transaction (manipulation for Exclusive).
    access_valid_i              <= arb_access.Valid;
    access_info_i.Port_Num      <= arb_access.Port_Num;
    access_info_i.Allocate      <= arb_access.Allocate and 
                                   not arb_access.Evict;
    access_info_i.Bufferable    <= arb_access.Bufferable;
    access_info_i.Exclusive     <= arb_access.Exclusive;
    access_info_i.Evict         <= arb_access.Evict;
    access_info_i.SnoopResponse <= '0';
    access_info_i.KillHit       <= arb_access.Evict;
    access_info_i.Kind          <= arb_access.Kind;
    access_info_i.Wr            <= arb_access.Wr;
    access_info_i.Addr          <= arb_access.Addr;
    access_info_i.Len           <= arb_access.Len;
    access_info_i.Size          <= arb_access.Size;
    access_info_i.DSid          <= arb_access.DSid;
    access_info_i.IsShared      <= '0';
    access_info_i.PassDirty     <= '0';
    access_info_i.Lx_Allocate   <= '0';
    access_info_i.Ignore_Data   <= arb_access.Ignore_Data;
    access_info_i.Force_Hit     <= '0';
    access_info_i.Internal_Cmd  <= arb_access.Internal_Cmd;
    
    -- Must evict line if there is no internal Exclusive monitor.
    access_evict_line           <= access_valid_i and arb_access.Exclusive when ( C_ENABLE_EX_MON = 0 ) else '0';
    
    -- Extend the length vector.
    Ext_Len: process (arb_access) is
    begin  -- process Ext_Len
      extended_length               <= (others=>'0');
      extended_length(14 downto 7)  <= arb_access.Len;
      extended_length( 6 downto 0)  <= "1111111";
    end process Ext_Len;
    
    -- Generate step and use.
    Gen_Mask: process (arb_access, extended_length) is
    begin  -- process Gen_Mask
      case arb_access.Size is
        when C_BYTE_SIZE          =>
          access_use  <= extended_length(C_BYTE_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_HALF_WORD_SIZE     =>
          access_use  <= extended_length(C_HALF_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_WORD_SIZE          =>
          access_use  <= extended_length(C_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_DOUBLE_WORD_SIZE   =>
          access_use  <= extended_length(C_DOUBLE_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_QUAD_WORD_SIZE     =>
          access_use  <= extended_length(C_QUAD_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_OCTA_WORD_SIZE     =>
          access_use  <= extended_length(C_OCTA_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_HEXADECA_WORD_SIZE =>
          access_use  <= extended_length(C_HEXADECA_WORD_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when others               =>
          access_use  <= extended_length(C_TRIACONTADI_MASK_POS);
          access_stp  <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
      end case;
    end process Gen_Mask;
    
    -- ID.
    access_id                 <= arb_access_id;
    
    -- Simply pass through.
    access_bp_push            <= arbiter_bp_push;
    access_bp_early           <= arbiter_bp_early;
    
    
    -----------------------------------------------------------------------------
    -- No snooping
    -----------------------------------------------------------------------------
    
    -- Internal Interface Signals (Snoop communication).
    snoop_fetch_piperun       <= '0';
    snoop_fetch_valid         <= '0';
    snoop_fetch_addr          <= (others=>'0');
    snoop_fetch_myself        <= (others=>'0');
    snoop_fetch_sync          <= (others=>'0');
    
    snoop_req_piperun         <= '0';
    snoop_req_valid           <= '0';
    snoop_req_write           <= '0';
    snoop_req_size            <= (others=>'0');
    snoop_req_addr            <= (others=>'0');
    snoop_req_snoop           <= (others=>(others=>'0'));
    snoop_req_myself          <= (others=>'0');
    snoop_req_always          <= (others=>'0');
    snoop_req_update_filter   <= (others=>'0');
    snoop_req_want            <= (others=>'0');
    snoop_req_complete        <= (others=>'0');
    snoop_req_complete_target <= (others=>'0');
    
    snoop_act_piperun         <= '0';
    snoop_act_valid           <= '0';
    snoop_act_waiting_4_pipe  <= '0';
    snoop_act_write           <= '0';
    snoop_act_addr            <= (others=>'0');
    snoop_act_prot            <= (others=>'0');
    snoop_act_snoop           <= (others=>(others=>'0'));
    snoop_act_myself          <= (others=>'0');
    snoop_act_always          <= (others=>'0');
    
    snoop_info_tag_valid      <= (others=>'0');
    
    snoop_resp_ready          <= (others=>'0');
    
    -- Snoop signals (Read Data & response).
    snoop_read_data_valid     <= (others=>'0');
    snoop_read_data_last      <= '0';
    snoop_read_data_resp      <= (others=>'0');
    snoop_read_data_word      <= (others=>'0');
    
    
    -----------------------------------------------------------------------------
    -- Statistics
    -----------------------------------------------------------------------------
    
    stat_access_fetch_stall   <= C_NULL_STAT_POINT;
    stat_access_req_stall     <= C_NULL_STAT_POINT;
    stat_access_act_stall     <= C_NULL_STAT_POINT;
    
    
    -----------------------------------------------------------------------------
    -- Debug 
    -----------------------------------------------------------------------------
    
    No_Debug: if( not C_USE_DEBUG ) generate
    begin
      ACCESS_DEBUG  <= (others=>'0');
    end generate No_Debug;
    
    Use_Debug: if( C_USE_DEBUG ) generate
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active true)
            ACCESS_DEBUG                                  <= (others=>'0');
            
          else
            -- Default assignment.
            ACCESS_DEBUG                                  <= (others=>'0');
            
            ACCESS_DEBUG(                            206) <= lookup_piperun_i;
            ACCESS_DEBUG(                            207) <= access_evict_line;
            ACCESS_DEBUG(                            208) <= access_evict_1st_cycle;
            ACCESS_DEBUG(                            209) <= access_evict_2nd_cycle;
            ACCESS_DEBUG(                            210) <= access_evict_inserted;
            ACCESS_DEBUG(                            211) <= access_stall;
    
          end if;
        end if;
      end process Debug_Handle;
    end generate Use_Debug;
    
  end generate No_Coherency;
  
  
  -----------------------------------------------------------------------------
  -- Coherent
  -----------------------------------------------------------------------------
  Use_Coherency: if( C_ENABLE_COHERENCY /= 0 ) generate
    
    -- Types for information queue storage.
    type SS_FIFO_MEM_VEC_TYPE         is array(C_NUM_OPTIMIZED_PORTS-1 downto 0) of SS_FIFO_MEM_TYPE;
    type QUEUE_ADDR_VEC_TYPE          is array(C_NUM_OPTIMIZED_PORTS-1 downto 0) of QUEUE_ADDR_TYPE;

    -- ----------------------------------------
    -- Pipeline Stage: Snoop Fetch
    
    signal snoop_fetch_piperun_pre1   : std_logic;
    signal snoop_fetch_piperun_i      : std_logic;
    signal snoop_fetch_stall          : std_logic;
    signal snoop_fetch_waiting_4_pipe : std_logic;
    signal snoop_fetch_valid_i        : std_logic;
    signal snoop_fetch_info           : ACCESS_TYPE;
    signal snoop_fetch_addr_i         : AXI_ADDR_TYPE;
    signal snoop_fetch_myself_i       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_always         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_any_always     : std_logic;
    signal snoop_fetch_update_filter  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_ud_filter_me   : std_logic;
    signal snoop_fetch_no_data        : std_logic;
    signal snoop_fetch_no_rs          : std_logic;
    signal snoop_fetch_dvm_complete   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_dvm_is_complete: std_logic;
    signal snoop_fetch_comp_port      : C_PORT_POS;
    signal snoop_fetch_comp_target    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_dvm_sync       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_dvm_is_sync    : std_logic;
    signal snoop_fetch_any_want       : std_logic;
    signal snoop_fetch_want           : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_snoop          : AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_prot           : AXI_PROT_TYPE;
    signal snoop_fetch_use            : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_fetch_stp            : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_fetch_port_num       : C_PORT_POS;
    signal snoop_fetch_ex_with_mon    : std_logic;
    signal snoop_fetch_valid_cu       : std_logic;
    signal snoop_fetch_exclusive_ok   : std_logic;
    signal snoop_fetch_start_monitor  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_stop_monitor   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_fetch_is_part2       : std_logic;
    signal snoop_fetch_lx_allocate    : std_logic;
    signal snoop_fetch_peer_caches    : std_logic;
    signal snoop_fetch_ds_caches      : std_logic;
    signal snoop_fetch_valid_ds_ci    : std_logic;
    signal snoop_fetch_ignore_data    : std_logic;
    signal snoop_fetch_comp_hold      : PORT_TYPE;
    signal snoop_fetch_dvm_comp_hold  : std_logic;
    
    
    -- ----------------------------------------
    -- Pipeline Stage: Snoop Request
    
    signal snoop_req_piperun_pre1     : std_logic;
    signal snoop_req_piperun_i        : std_logic;
    signal snoop_req_stall            : std_logic;
    signal snoop_req_conflict         : std_logic; 
    signal snoop_req_exclusive_stall  : std_logic; 
    signal snoop_req_valid_i          : std_logic;
    signal snoop_req_info             : ACCESS_TYPE;
    signal snoop_req_addr_i           : AXI_ADDR_TYPE;
    signal snoop_req_myself_i         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_always_i         : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_any_always       : std_logic;
    signal snoop_req_update_filter_i  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_update_filter_me : std_logic;
    signal snoop_req_no_data          : std_logic;
    signal snoop_req_no_rs            : std_logic;
    signal snoop_req_any_want         : std_logic;
    signal snoop_req_want_i           : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_snoop_i          : AXI_SNOOP_VECTOR_TYPE(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_prot             : AXI_PROT_TYPE;
    signal snoop_req_use              : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_req_stp              : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_req_exclusive_ok     : std_logic;
    signal snoop_req_start_monitor    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_stop_monitor     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_req_allow_exclusive  : std_logic;
    signal snoop_req_evict_line       : std_logic;
    signal snoop_req_early_resp       : std_logic;
    signal snoop_req_port_num         : C_PORT_POS;
    
    
    -- ----------------------------------------
    -- Pipeline Stage: Snoop Action
    
    signal snoop_act_piperun_pre2     : std_logic;
    signal snoop_act_piperun_pre1     : std_logic;
    signal snoop_act_piperun_i        : std_logic; 
    signal snoop_act_valid_vec        : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_act_stall_part1      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_act_stall_part2      : std_logic; 
    signal snoop_act_stall            : std_logic; 
    signal snoop_act_valid_i          : std_logic; 
    signal snoop_act_waiting_4_pipe_i : std_logic;
    signal snoop_act_conflict         : std_logic; 
    signal snoop_act_info             : ACCESS_TYPE;
    signal snoop_act_addr_i           : AXI_ADDR_TYPE;
    signal snoop_act_any_always       : std_logic;
    signal snoop_act_no_data          : std_logic;
    signal snoop_act_no_rs            : std_logic;
    signal snoop_act_use              : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_act_stp              : std_logic_vector(C_ADDR_OFFSET_HI downto C_ADDR_OFFSET_LO);
    signal snoop_act_dvm_complete_me  : std_logic;
    signal snoop_act_complete_done    : std_logic;
    signal snoop_act_exclusive_ok     : std_logic;
    signal snoop_act_evict_line       : std_logic;
    signal snoop_act_early_resp       : std_logic;
    signal snoop_act_port_num         : C_PORT_POS;
    
    
    -- ----------------------------------------
    -- Pipeline Stage: Access
    
    signal access_waiting_for_pipe    : std_logic;
    signal access_snooped_ports       : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal access_no_data             : std_logic;
    signal access_no_rs               : std_logic;
    signal access_exclusive_ok        : std_logic;
    
    
    -- ----------------------------------------
    -- Queue handling
    
    signal c_push                     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal c_pop                      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal c_fifo_full                : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal c_fifo_empty               : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal c_assert                   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    signal ss_push                    : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal ss_pop                     : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal ss_fifo_full               : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal ss_fifo_empty              : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal ss_port_num                : PORT_POS_ARRAY_TYPE;
    signal ss_assert                  : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    signal rs_push                    : std_logic;
    signal rs_pop                     : std_logic;
    signal rs_fifo_almost_full        : std_logic;
    signal rs_fifo_full               : std_logic;
    signal rs_fifo_empty              : std_logic;
    signal rs_read_fifo_addr          : QUEUE_ADDR_TYPE:= (others=>'1');
    signal rs_fifo_mem                : RS_FIFO_MEM_TYPE; -- := (others=>C_NULL_RS);
    signal rs_no_forward              : std_logic;
    signal rs_port_num                : natural range 0 to C_NUM_PORTS - 1;
    signal rs_resp_mask               : PORT_TYPE;
    signal rs_exclusive_ok            : std_logic;
    signal rs_assert                  : std_logic;
    
    signal ss_read_fifo_addr_vec      : QUEUE_ADDR_VEC_TYPE:= (others=>(others=>'1'));
    signal ss_fifo_mem_vec            : SS_FIFO_MEM_VEC_TYPE; -- := (others=>(others=>C_NULL_SS));
    
    -- ----------------------------------------
    -- Handle Response Merging
    
    signal access_merged_error        : std_logic;
    signal access_all_resp_available  : std_logic;
    signal access_resp_valid          : std_logic;
    signal access_resp_valid_vec      : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_read_data_port_num   : natural range 0 to C_NUM_PORTS - 1;
    signal snoop_read_data_any_valid  : std_logic;
    
    
    -- ----------------------------------------
    -- Exclusive Monitor
    
    signal snoop_ex_monitor_allow_new : std_logic;
    signal snoop_ex_monitor_started   : std_logic_vector(C_NUM_PORTS - 1 downto 0);
    signal snoop_ex_monitor_port      : natural range 0 to C_NUM_PORTS - 1;
    signal snoop_ex_enable_timer      : std_logic;
    signal snoop_ex_timer             : natural range 0 to C_NUM_PORTS;
    
  begin
    
    access_piperun_i              <= snoop_fetch_piperun_i;
    
    
    -----------------------------------------------------------------------------
    -- Traslate
    -- 
    -----------------------------------------------------------------------------
    
    -- Decode cache effect.
    snoop_fetch_peer_caches         <= '1' when ( arb_access.Domain = C_DOMAIN_INNER_SHAREABLE ) or
                                                ( arb_access.Domain = C_DOMAIN_OUTER_SHAREABLE ) else
                                       '0';
    snoop_fetch_ds_caches           <= '1' when ( arb_access.Domain = C_DOMAIN_NON_SHAREABLE   ) or
                                                ( arb_access.Domain = C_DOMAIN_INNER_SHAREABLE ) or
                                                ( arb_access.Domain = C_DOMAIN_OUTER_SHAREABLE ) else
                                       '0';
    
    -- Transaction (manipulation for Exclusive).
    snoop_fetch_valid_i             <= arb_access.Valid;
    snoop_fetch_info.Port_Num       <= arb_access.Port_Num;
    snoop_fetch_info.Allocate       <= arb_access.Allocate and 
                                       not arb_access.Evict;
    snoop_fetch_info.Bufferable     <= arb_access.Bufferable;
    snoop_fetch_info.Exclusive      <= arb_access.Exclusive;
    snoop_fetch_info.Evict          <= arb_access.Evict;
    snoop_fetch_info.SnoopResponse  <= '0';
    snoop_fetch_info.KillHit        <= arb_access.Evict;
    snoop_fetch_info.Kind           <= arb_access.Kind;
    snoop_fetch_info.Wr             <= arb_access.Wr;
    snoop_fetch_info.Addr           <= arb_access.Addr;
    snoop_fetch_info.Len            <= arb_access.Len;
    snoop_fetch_info.Size           <= arb_access.Size;
    snoop_fetch_info.IsShared       <= '0';
    snoop_fetch_info.PassDirty      <= '0';
    snoop_fetch_info.Lx_Allocate    <= snoop_fetch_lx_allocate;
    snoop_fetch_info.Ignore_Data    <= arb_access.Ignore_Data or 
                                       snoop_fetch_ignore_data;
    snoop_fetch_info.Force_Hit      <= arb_access.Force_Hit;
    snoop_fetch_info.Internal_Cmd   <= arb_access.Internal_Cmd;

    
    -- Extend the length vector.
    Ext_Len: process (arb_access) is
    begin  -- process Ext_Len
      extended_length               <= (others=>'0');
      extended_length(14 downto 7)  <= arb_access.Len;
      extended_length( 6 downto 0)  <= "1111111";
    end process Ext_Len;
    
    -- Generate step and use.
    Gen_Mask: process (arb_access, extended_length) is
    begin  -- process Gen_Mask
      case arb_access.Size is
        when C_BYTE_SIZE          =>
          snoop_fetch_use  <= extended_length(C_BYTE_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_BYTE_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_HALF_WORD_SIZE     =>
          snoop_fetch_use  <= extended_length(C_HALF_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_HALF_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_WORD_SIZE          =>
          snoop_fetch_use  <= extended_length(C_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_DOUBLE_WORD_SIZE   =>
          snoop_fetch_use  <= extended_length(C_DOUBLE_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_DOUBLE_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_QUAD_WORD_SIZE     =>
          snoop_fetch_use  <= extended_length(C_QUAD_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_QUAD_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_OCTA_WORD_SIZE     =>
          snoop_fetch_use  <= extended_length(C_OCTA_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_OCTA_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when C_HEXADECA_WORD_SIZE =>
          snoop_fetch_use  <= extended_length(C_HEXADECA_WORD_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_HEXADECA_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
        when others               =>
          snoop_fetch_use  <= extended_length(C_TRIACONTADI_MASK_POS);
          snoop_fetch_stp  <= std_logic_vector(to_unsigned(C_TRIACONTADI_WORD_STEP_SIZE, C_ADDR_OFFSET_BITS));
          
      end case;
    end process Gen_Mask;
    
    -- Assign external signal.
    snoop_fetch_addr      <= snoop_fetch_addr_i;
    snoop_fetch_addr_i    <= arb_access.Addr;
    
    
    -----------------------------------------------------------------------------
    -- Pipeline Stage: Snoop Fetch
    -- 
    -----------------------------------------------------------------------------
    
    -- Pipeline control
--    snoop_fetch_piperun_i   <= ( snoop_req_piperun_i or not snoop_req_valid_i ) and not snoop_fetch_stall;
    FE_Acs_PR_Or_Inst4: carry_or_n 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => snoop_req_piperun_i,
        A_N       => snoop_req_valid_i,
        Carry_OUT => snoop_fetch_piperun_pre1
      );
    FE_Acs_PR_And_Inst4: carry_and_n 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => snoop_fetch_piperun_pre1,
        A_N       => snoop_fetch_stall,
        Carry_OUT => snoop_fetch_piperun_i
      );
    
    -- Stall conditions: Tag Line hazards.
    snoop_fetch_stall       <= snoop_req_conflict or snoop_act_conflict or snoop_req_exclusive_stall or
                               reduce_or(snoop_fetch_pos_hazard);
    
    -- Help signal for current Port number.
    snoop_fetch_port_num    <= get_port_num(snoop_fetch_info.Port_Num, C_NUM_PORTS);
    
    -- Help signal to determine if a CleanUnique shall proceed.
    snoop_fetch_ex_with_mon <= snoop_fetch_valid_i and snoop_fetch_info.Exclusive and 
                               snoop_ex_monitor_started(snoop_fetch_port_num);
    snoop_fetch_valid_cu    <= snoop_fetch_ex_with_mon or 
                               ( snoop_fetch_valid_i and not snoop_fetch_info.Exclusive );
    
    -- Generate the target for a complete transaction.
    snoop_fetch_comp_port   <= ss_port_num(snoop_fetch_port_num);
    
    -- Decode transaction
    Transaction_Decode: process (arb_access, snoop_fetch_comp_port, snoop_fetch_dvm_comp_hold, snoop_fetch_comp_hold, 
                                 snoop_fetch_ex_with_mon, snoop_fetch_valid_cu, snoop_fetch_is_part2,
                                 snoop_fetch_peer_caches, snoop_fetch_ds_caches, snoop_fetch_info,
                                 snoop_ex_monitor_allow_new) is
    begin  -- process Transaction_Decode
      -- Default assignment
      snoop_fetch_myself_i          <= (others=>'0');
      snoop_fetch_always            <= (others=>'0');
      snoop_fetch_any_always        <= '0';
      snoop_fetch_update_filter     <= (others=>'0');
      snoop_fetch_ud_filter_me      <= '0';
      snoop_fetch_no_data           <= '0';
      snoop_fetch_no_rs             <= '0';
      snoop_fetch_exclusive_ok      <= '0';
      snoop_fetch_start_monitor     <= (others=>'0');
      snoop_fetch_stop_monitor      <= (others=>'0');
      snoop_fetch_any_want          <= '0';
      snoop_fetch_want              <= (others=>'0');
      snoop_fetch_dvm_complete      <= (others=>'0');
      snoop_fetch_comp_target       <= (others=>'0');
      snoop_fetch_dvm_is_complete   <= '0';
      snoop_fetch_dvm_sync          <= (others=>'0');
      snoop_fetch_dvm_is_sync       <= '0';
      snoop_fetch_lx_allocate       <= '0';
      snoop_fetch_valid_ds_ci       <= '0';
      snoop_fetch_ignore_data       <= '0';
      
      for I in 0 to C_NUM_PORTS - 1 loop
        if( get_port_num(arb_access.Port_Num, C_NUM_PORTS) = I ) then
          -- Current port only update filter.
          snoop_fetch_myself_i(I)         <= '1';
          snoop_fetch_snoop(I)          <= arb_access.Snoop;
          
          if( arb_access.Wr = '1' ) then
            -- Write transaction.
          
            case arb_access.Snoop(C_AXI_AWSNOOP_POS) is
              when C_AWSNOOP_WriteUnique  =>
                -- MicroBlaze will allocate on Word WriteUnique.
                snoop_fetch_no_rs             <= '1';
                
              when C_AWSNOOP_WriteLineUnique    =>
                null;
                
              when C_AWSNOOP_WriteClean         =>
                null;
                
              when C_AWSNOOP_WriteBack          =>
                null;
                
              when C_AWSNOOP_Evict              =>
                null;
                
              when others                       =>
                null;
            end case;
            
          else
            -- Read transaction.
            
            
            snoop_fetch_no_rs             <= snoop_fetch_info.Internal_Cmd;
            
            case arb_access.Snoop is
              when C_ARSNOOP_ReadOnce  =>
                -- Nothing needs to be done.
                null;
                
              when C_ARSNOOP_ReadShared         =>
                null;
                
              when C_ARSNOOP_ReadClean          =>
                -- Might need to update filter.
                snoop_fetch_lx_allocate       <= '1';
                snoop_fetch_update_filter(I)  <= '1';
                snoop_fetch_ud_filter_me      <= '1';
                snoop_fetch_start_monitor(I)  <= arb_access.Exclusive and snoop_ex_monitor_allow_new;
                
              when C_ARSNOOP_ReadNotSharedDirty =>
                null;
                
              when C_ARSNOOP_ReadUnique         =>
                null;
                
              when C_ARSNOOP_CleanUnique        =>
                -- Make sure entry is removed from filter.
                snoop_fetch_update_filter(I)  <= '1';
                snoop_fetch_ud_filter_me      <= '1';
                snoop_fetch_no_data           <= '1';
                snoop_fetch_exclusive_ok      <= snoop_fetch_ex_with_mon;
                snoop_fetch_start_monitor(I)  <= arb_access.Exclusive and snoop_ex_monitor_allow_new;
                
              when C_ARSNOOP_MakeUnique         =>
                null;
                
              when C_ARSNOOP_CleanShared        =>
                null;
                
              when C_ARSNOOP_CleanInvalid       =>
                -- Make sure entry is removed from filter.
                snoop_fetch_update_filter(I)  <= '1';
                snoop_fetch_ud_filter_me      <= '1';
                snoop_fetch_no_data           <= '1';
                snoop_fetch_valid_ds_ci       <= snoop_fetch_ds_caches;
                
                
              when C_ARSNOOP_MakeInvalid        =>
                snoop_fetch_update_filter(I)  <= '1';
                snoop_fetch_ud_filter_me      <= '1';
                snoop_fetch_no_data           <= '1';
                snoop_fetch_valid_ds_ci       <= snoop_fetch_ds_caches;
                snoop_fetch_ignore_data       <= '1';
                
              when C_ARSNOOP_DVMComplete        =>
                -- Collect transactions.
                if( snoop_fetch_dvm_comp_hold = '0' ) then
                  snoop_fetch_dvm_complete      <= std_logic_vector(to_unsigned(2 ** snoop_fetch_comp_port, 
                                                                                C_NUM_PORTS));
                else
                  snoop_fetch_dvm_complete      <= snoop_fetch_comp_hold;
                end if;
                snoop_fetch_comp_target(I)    <= '1';
                snoop_fetch_dvm_is_complete   <= '1';
                snoop_fetch_no_data           <= '1';
                
              when C_ARSNOOP_DVMMessage         =>
                -- Register if it is a Sync message.
                snoop_fetch_dvm_is_sync       <= arb_access.Addr(C_DVM_NEED_COMPLETE_POS) and not snoop_fetch_is_part2;
                snoop_fetch_dvm_sync(I)       <= arb_access.Addr(C_DVM_NEED_COMPLETE_POS) and not snoop_fetch_is_part2;
                snoop_fetch_no_data           <= '1';
                
              when others                       =>
                null;
            end case;
          end if;
        else
          -- All other ports.
          
          -- Default assignment
          snoop_fetch_snoop(I)          <= C_ACSNOOP_CleanInvalid;
          
          if( arb_access.Wr = '1' ) then
            -- Write transaction.
          
            case arb_access.Snoop(C_AXI_AWSNOOP_POS) is
              when C_AWSNOOP_WriteUnique  => --  | C_AWSNOOP_WriteNoSnoop
                snoop_fetch_want(I)           <= snoop_fetch_peer_caches;
                snoop_fetch_any_want          <= snoop_fetch_peer_caches;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_CleanInvalid;
                
              when C_AWSNOOP_WriteLineUnique    =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: snoop_fetch_peer_caches;
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: snoop_fetch_peer_caches;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_MakeInvalid;
                
              when C_AWSNOOP_WriteClean         =>
                snoop_fetch_want(I)           <= '0';
                snoop_fetch_any_want          <= '0';
                
              when C_AWSNOOP_WriteBack          =>
                snoop_fetch_want(I)           <= '0';
                snoop_fetch_any_want          <= '0';
                
              when C_AWSNOOP_Evict              =>
                snoop_fetch_want(I)           <= '0';
                snoop_fetch_any_want          <= '0';
                
              when others                       =>
                null;
            end case;
          else
            -- Read transaction.
            
            case arb_access.Snoop is
              when C_ARSNOOP_ReadOnce  => --  | C_ARSNOOP_ReadNoSnoop
                snoop_fetch_want(I)           <= snoop_fetch_peer_caches;
                snoop_fetch_any_want          <= snoop_fetch_peer_caches;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_ReadOnce;
                
              when C_ARSNOOP_ReadShared         =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_ReadShared;
                
              when C_ARSNOOP_ReadClean          =>
                snoop_fetch_snoop(I)          <= C_ACSNOOP_ReadClean;
                
              when C_ARSNOOP_ReadNotSharedDirty =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_ReadNotSharedDirty;
                
              when C_ARSNOOP_ReadUnique         =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_ReadUnique;
                
              when C_ARSNOOP_CleanUnique        =>
                snoop_fetch_want(I)           <= snoop_fetch_valid_cu;
                snoop_fetch_any_want          <= snoop_fetch_valid_cu;
                snoop_fetch_stop_monitor(I)   <= snoop_fetch_ex_with_mon;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_CleanInvalid;
                
              when C_ARSNOOP_MakeUnique         =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_MakeInvalid;
                
              when C_ARSNOOP_CleanShared        =>
                snoop_fetch_want(I)           <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_any_want          <= '0'; -- Only support for MB subset: '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_CleanShared;
                
              when C_ARSNOOP_CleanInvalid       =>
                snoop_fetch_want(I)           <= snoop_fetch_peer_caches;
                snoop_fetch_any_want          <= snoop_fetch_peer_caches;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_CleanInvalid;
                
              when C_ARSNOOP_MakeInvalid        =>
                snoop_fetch_want(I)           <= snoop_fetch_peer_caches;
                snoop_fetch_any_want          <= snoop_fetch_peer_caches;
                snoop_fetch_snoop(I)          <= C_ACSNOOP_MakeInvalid;
                
              when C_ARSNOOP_DVMComplete        =>
                snoop_fetch_snoop(I)          <= C_ACSNOOP_DVMComplete;
                
              when C_ARSNOOP_DVMMessage         =>
                snoop_fetch_always(I)         <= '1';
                snoop_fetch_any_always        <= '1';
                snoop_fetch_snoop(I)          <= C_ACSNOOP_DVMMessage;
                
              when others                       =>
                null;
            end case;
          end if;
        end if;
      end loop;
    end process Transaction_Decode;
    
    snoop_fetch_prot  <= arb_access.Prot;
    
    Pipeline_Stage_Snoop_Fetch_Done : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Fetch_Done
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          snoop_fetch_waiting_4_pipe  <= '0';
          snoop_fetch_comp_hold       <= (others=>'0');
          snoop_fetch_dvm_comp_hold   <= '0';
          
        else
          if( snoop_fetch_piperun_i = '1' ) then
            snoop_fetch_waiting_4_pipe  <= '0';
            snoop_fetch_comp_hold       <= (others=>'0');
            snoop_fetch_dvm_comp_hold   <= '0';
          elsif( snoop_fetch_valid_i = '1' ) then
            snoop_fetch_waiting_4_pipe  <= '1';
            if( snoop_fetch_waiting_4_pipe = '0' ) then
              snoop_fetch_comp_hold       <= snoop_fetch_dvm_complete;
              snoop_fetch_dvm_comp_hold   <= snoop_fetch_dvm_is_complete;
            end if;
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Fetch_Done;
    
    -- Move Snoop Request to Snoop Request (Valid).
    Pipeline_Stage_Snoop_Req_Valid : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Req_Valid
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_req_valid_i <= '0';
        else
          if( snoop_fetch_piperun_i = '1' ) then
            snoop_req_valid_i <= snoop_fetch_valid_i;
          elsif( snoop_req_piperun_i = '1' ) then
            snoop_req_valid_i <= '0';
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Req_Valid;
    
    -- Need to stall for Exclusive Store Transaction.
    Pipeline_Stage_Snoop_Req_Ex : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Req_Ex
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_req_exclusive_stall <= '0';
        else
          if( snoop_fetch_piperun_i = '1' ) then
            snoop_req_exclusive_stall <= snoop_fetch_ex_with_mon;
          else
            snoop_req_exclusive_stall <= '0';
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Req_Ex;
    
    -- Move Snoop Request to Snoop Request (Information).
    Pipeline_Stage_Snoop_Req : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Req
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_req_info              <= C_NULL_ACCESS;
          snoop_req_myself_i          <= (others=>'0');
          snoop_req_always_i          <= (others=>'0');
          snoop_req_any_always        <= '0';
          snoop_req_update_filter_i   <= (others=>'0');
          snoop_req_update_filter_me  <= '0';
          snoop_req_no_data           <= '0';
          snoop_req_no_rs             <= '0';
          snoop_req_any_want          <= '0';
          snoop_req_want_i            <= (others=>'0');
          snoop_req_snoop_i           <= (others=>(others=>'0'));
          snoop_req_prot              <= (others=>'0');
          snoop_req_use               <= (others=>'0');
          snoop_req_stp               <= (others=>'0');
          snoop_req_exclusive_ok      <= '0';
          snoop_req_start_monitor     <= (others=>'0');
          snoop_req_stop_monitor      <= (others=>'0');
          snoop_req_complete_target   <= (others=>'0');
          snoop_req_complete          <= (others=>'0');
          snoop_fetch_is_part2        <= '0';
          snoop_req_allow_exclusive   <= '0';
          snoop_req_evict_line        <= '0';
          snoop_req_early_resp        <= '0';
          snoop_req_port_num          <= 0;
          
        elsif( snoop_fetch_piperun_i = '1' ) then
          snoop_req_info              <= snoop_fetch_info;
          snoop_req_myself_i          <= snoop_fetch_myself_i;
          snoop_req_always_i          <= snoop_fetch_always;
          snoop_req_any_always        <= snoop_fetch_any_always;
          snoop_req_update_filter_i   <= snoop_fetch_update_filter;
          snoop_req_update_filter_me  <= snoop_fetch_ud_filter_me;
          snoop_req_no_data           <= snoop_fetch_no_data;
          snoop_req_no_rs             <= snoop_fetch_no_rs;
          snoop_req_any_want          <= snoop_fetch_any_want;
          snoop_req_want_i            <= snoop_fetch_want;
          snoop_req_snoop_i           <= snoop_fetch_snoop;
          snoop_req_prot              <= snoop_fetch_prot;
          snoop_req_use               <= snoop_fetch_use;
          snoop_req_stp               <= snoop_fetch_stp;
--          snoop_req_dvm_complete_me   <= snoop_fetch_dvm_is_complete;
          snoop_req_exclusive_ok      <= snoop_fetch_exclusive_ok;
          snoop_req_start_monitor     <= snoop_fetch_start_monitor;
          snoop_req_stop_monitor      <= snoop_fetch_stop_monitor;
          snoop_req_complete_target   <= snoop_fetch_comp_target;
          snoop_req_complete          <= snoop_fetch_dvm_complete;
          if( snoop_fetch_valid_i = '1' ) then
            snoop_fetch_is_part2        <= snoop_fetch_any_always and 
                                           snoop_fetch_addr_i(C_DVM_MORE_POS);
          end if;
          if( snoop_fetch_port_num = snoop_ex_monitor_port ) then
            snoop_req_allow_exclusive   <= snoop_fetch_valid_i and snoop_fetch_info.Wr;
          else
            snoop_req_allow_exclusive   <= '0';
          end if;
          
          -- Remove exclusive propagation for "Exclusive Store transaction".
          if( ( arb_access.Wr = '0' ) and ( arb_access.Snoop = C_ARSNOOP_CleanUnique ) ) then
            snoop_req_info.Exclusive    <= '0';
          end if;
          
          -- Propagate induced evict of line.
          snoop_req_evict_line        <= snoop_fetch_valid_ds_ci;
          
          -- Determine if an early response is allowed.
          snoop_req_early_resp        <= arb_access.Bufferable or 
                                         arb_access.Allocate;
          snoop_req_port_num          <= snoop_fetch_port_num;
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Req;
    
    -- Assign output.
    snoop_fetch_piperun <= snoop_fetch_piperun_i;
    snoop_fetch_valid   <= snoop_fetch_valid_i;
    snoop_fetch_myself  <= snoop_fetch_myself_i;
    snoop_fetch_sync    <= snoop_fetch_dvm_sync;
    
    
    -----------------------------------------------------------------------------
    -- Pipeline Stage: Snoop Request
    -- 
    -----------------------------------------------------------------------------
    
    -- Pipeline control
--    snoop_req_piperun_i       <= ( snoop_act_piperun_i or not snoop_act_valid_i ) and not snoop_req_stall;
    FE_Acs_PR_Or_Inst3: carry_or_n 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => snoop_act_piperun_i,
        A_N       => snoop_act_valid_i,
        Carry_OUT => snoop_req_piperun_pre1
      );
    FE_Acs_PR_And_Inst3: carry_vec_and_n 
      generic map(
        C_TARGET => C_TARGET,
        C_INPUTS => Family_To_LUT_Size(C_TARGET),
        C_SIZE   => C_NUM_PORTS
      )
      port map(
        Carry_IN  => snoop_req_piperun_pre1,
        A_Vec     => snoop_act_write_blocking,
        Carry_OUT => snoop_req_piperun_i
      );
    
    -- Stall conditions: Still waiting for AC acknowledge.
    snoop_req_stall           <= reduce_or(snoop_act_write_blocking);
    
    -- Move Snoop Request to Snoop Action (Valid).
    Pipeline_Stage_Snoop_Act_Valid : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Valid
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_valid_i <= '0';
        else
          if( snoop_req_piperun_i = '1' ) then
            snoop_act_valid_i <= snoop_req_valid_i;
          elsif( snoop_act_piperun_i = '1' ) then
            snoop_act_valid_i <= '0';
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Valid;
    
    Pipeline_Stage_Snoop_Act_Done : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act_Done
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          snoop_act_waiting_4_pipe_i  <= '0';
          
        else
          if( snoop_act_piperun_i = '1' ) then
            snoop_act_waiting_4_pipe_i  <= '0';
          elsif( snoop_act_valid_i = '1' ) then
            snoop_act_waiting_4_pipe_i  <= '1';
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act_Done;
    
    -- Move Snoop Request to Snoop Action (Information).
    Pipeline_Stage_Snoop_Act : process (ACLK) is
    begin  -- process Pipeline_Stage_Snoop_Act
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_act_info              <= C_NULL_ACCESS;
          snoop_act_snoop             <= (others=>(others=>'0'));
          snoop_act_myself            <= (others=>'0');
          snoop_act_always            <= (others=>'0');
          snoop_act_any_always        <= '0';
          snoop_act_no_data           <= '0';
          snoop_act_no_rs             <= '0';
          snoop_act_exclusive_ok      <= '0';
          snoop_act_prot              <= (others=>'0');
          snoop_act_use               <= (others=>'0');
          snoop_act_stp               <= (others=>'0');
          snoop_act_evict_line        <= '0';
          snoop_act_early_resp        <= '0';
          snoop_act_port_num          <= 0;
          
        elsif( snoop_req_piperun_i = '1' ) then
          snoop_act_info              <= snoop_req_info;
          snoop_act_snoop             <= snoop_req_snoop_i;
          snoop_act_myself            <= snoop_req_myself_i;
          snoop_act_any_always        <= snoop_req_any_always;
          snoop_act_always            <= snoop_req_always_i;
          snoop_act_no_data           <= snoop_req_no_data;
          snoop_act_no_rs             <= snoop_req_no_rs;
          snoop_act_exclusive_ok      <= snoop_req_exclusive_ok;
          snoop_act_prot              <= snoop_req_prot;
          snoop_act_use               <= snoop_req_use;
          snoop_act_stp               <= snoop_req_stp;
          snoop_act_evict_line        <= snoop_req_evict_line;
          snoop_act_early_resp        <= snoop_req_early_resp;
          snoop_act_port_num          <= snoop_req_port_num;
          
        end if;
      end if;
    end process Pipeline_Stage_Snoop_Act;
    
    -- Rename output.
    snoop_req_addr_i        <= snoop_req_info.Addr;
    
    -- Assign external.
    snoop_req_piperun       <= snoop_req_piperun_i;
    snoop_req_valid         <= snoop_req_valid_i;
    snoop_req_write         <= snoop_req_info.Wr;
    snoop_req_myself        <= snoop_req_myself_i;
    snoop_req_always        <= snoop_req_always_i;
    snoop_req_update_filter <= snoop_req_update_filter_i;
    snoop_req_want          <= snoop_req_want_i;
    snoop_req_size          <= snoop_req_info.Size;
    snoop_req_addr          <= snoop_req_addr_i;
    snoop_req_snoop         <= snoop_req_snoop_i;
    
    
    -----------------------------------------------------------------------------
    -- Pipeline Stage: Snoop Action
    -- 
    -----------------------------------------------------------------------------
    
    -- Pipeline control
--    snoop_act_piperun_i       <= ( lookup_piperun_i or not access_valid_i ) and not snoop_act_stall;
    FE_Acs_PR_Or_Inst2: carry_or_n 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => lookup_piperun_i,
        A_N       => access_valid_i,
        Carry_OUT => snoop_act_piperun_pre2
      );
    FE_Acs_PR_And_Inst2a: carry_vec_and_n 
      generic map(
        C_TARGET => C_TARGET,
        C_INPUTS => Family_To_LUT_Size(C_TARGET),
        C_SIZE   => C_NUM_PORTS
      )
      port map(
        Carry_IN  => snoop_act_piperun_pre2,
        A_Vec     => snoop_act_stall_part1,
        Carry_OUT => snoop_act_piperun_pre1
      );
    FE_Acs_PR_And_Inst2b: carry_and_n 
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => snoop_act_piperun_pre1,
        A_N       => snoop_act_stall_part2,
        Carry_OUT => snoop_act_piperun_i
      );
    
    -- Stall conditions: Still waiting for AC acknowledge.
--    snoop_act_stall           <= ( snoop_act_valid_i and reduce_or(not snoop_act_done) ) or 
--                                 rs_fifo_almost_full or rs_fifo_full;
    snoop_act_valid_vec       <= (others => snoop_act_valid_i);
    snoop_act_stall_part1     <= snoop_act_valid_vec and not snoop_act_done;
    snoop_act_stall_part2     <= rs_fifo_almost_full or rs_fifo_full;
    snoop_act_stall           <= reduce_or(snoop_act_stall_part1) or snoop_act_stall_part2;
    
    -- Move Snoop Action to Access (Valid).
    Pipeline_Stage_Access_Valid : process (ACLK) is
    begin  -- process Pipeline_Stage_Access_Valid
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          access_valid_i  <= '0';
        else
          if( snoop_act_piperun_i = '1' ) then
            access_valid_i  <= snoop_act_valid_i;
            
          elsif( lookup_piperun_i = '1' ) then
            access_valid_i  <= '0';
            
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Access_Valid;
    
    -- Move Snoop Action to Access (Information).
    Pipeline_Stage_Access : process (ACLK) is
    begin  -- process Pipeline_Stage_Access
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          access_info_i               <= C_NULL_ACCESS;
          access_use                  <= (others=>'0');
          access_stp                  <= (others=>'0');
          access_snooped_ports        <= (others=>'0');
          access_no_data              <= '0';
          access_no_rs                <= '0';
          access_exclusive_ok         <= '0';
          access_evict_line           <= '0';
          access_bp_push              <= (others=>'0');
          access_bp_early             <= (others=>'0');
          
        elsif( snoop_act_piperun_i = '1' ) then
          -- Default assignement.
          access_info_i               <= snoop_act_info;
          access_use                  <= snoop_act_use;
          access_stp                  <= snoop_act_stp;
          access_snooped_ports        <= snoop_act_use_external;
          access_no_data              <= snoop_act_no_data;
          access_no_rs                <= snoop_act_no_rs;
          access_exclusive_ok         <= snoop_act_exclusive_ok;
          access_bp_push              <= (others=>'0');
          
          -- Make sure that transactions that doesn't carry data is seen by the core as length 1.
          if( snoop_act_no_data = '1' ) then
            access_info_i.Len           <= (others=>'0');
          end if;
          
          -- Update respsonse bits.
          access_info_i.SnoopResponse <= ( snoop_act_any_always or snoop_act_no_data ) and 
                                         not snoop_act_info.Evict;
          access_info_i.KillHit       <= snoop_act_any_always or snoop_act_no_data or 
                                         snoop_act_info.Evict;
    
          -- Update extra coherency bits after all snooping is completed.
          access_info_i.IsShared      <= not snoop_info_tag_unique(snoop_act_port_num);
          access_info_i.PassDirty     <= snoop_info_tag_dirty(snoop_act_port_num);
          
          -- Stalls if preparing for Exclusive.
          access_evict_line           <= snoop_act_evict_line;
          
          -- Generate early information for write.
          access_bp_push(snoop_act_port_num)  <= snoop_act_valid_i and snoop_act_info.Wr;
          access_bp_early                     <= (others=>snoop_act_early_resp);
          
        else
          access_bp_push              <= (others=>'0');
          
        end if;
      end if;
    end process Pipeline_Stage_Access;
    
    -- Rename output.
    snoop_act_addr_i          <= snoop_act_info.Addr;
    
    -- Assign external.
    snoop_act_piperun         <= snoop_act_piperun_i;
    snoop_act_valid           <= snoop_act_valid_i;
    snoop_act_waiting_4_pipe  <= snoop_act_waiting_4_pipe_i;
    snoop_act_write           <= snoop_act_info.Wr;
    snoop_act_addr            <= snoop_act_addr_i;
    
    -- No need to modify
    snoop_info_tag_valid      <= snoop_act_tag_valid;
    
    
    -----------------------------------------------------------------------------
    -- Pipeline Stage: Access
    -- 
    -----------------------------------------------------------------------------
    
    Pipeline_Stage_Access_Done : process (ACLK) is
    begin  -- process Pipeline_Stage_Access_Done
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ARESET_I = '1' ) then             -- synchronous reset (active high)
          access_waiting_for_pipe <= '0';
          
        else
          if( snoop_act_piperun_i = '1' ) then
            access_waiting_for_pipe <= '0';
          elsif( access_valid_i = '1' ) then
            access_waiting_for_pipe <= '1';
          else
          end if;
        end if;
      end if;
    end process Pipeline_Stage_Access_Done;
    
    
    -----------------------------------------------------------------------------
    -- Conflict detection
    -- 
    -----------------------------------------------------------------------------
    
    -- Detect conflicts because of updating tag (potential or actual).
    snoop_req_conflict  <= '1' when ( snoop_fetch_addr_i(C_Lx_ADDR_LINE_POS) = snoop_req_addr_i(C_Lx_ADDR_LINE_POS) and
                                      ( snoop_req_any_want = '1' or snoop_req_update_filter_me = '1' ) and
                                      ( snoop_req_valid_i = '1' ) and
                                      ( snoop_fetch_valid_i = '1' ) ) else
                           '0';
                           
    snoop_act_conflict  <= '1' when ( snoop_fetch_addr_i(C_Lx_ADDR_LINE_POS) = snoop_act_addr_i(C_Lx_ADDR_LINE_POS) and 
                                      ( snoop_act_valid_i = '1' ) and
                                      ( snoop_fetch_valid_i = '1' ) ) else
                           '0';
    
    
    -----------------------------------------------------------------------------
    -- Queue handling:
    -- 
    -- There need to be a number of queues to handle the latency/flexibility on
    -- DVM messages
    -- 
    -- * DVM Sync Souce:
    --   One queue per port that stores which port a DVM complete should be 
    --   transmitted to.
    --   (From AR)
    -- 
    -- * ACE Response Info:
    --   A queue for each port containing response information that shall be 
    --   coalecsced into one reponse to a specific master.
    --   (Queue physically located in port)
    -- 
    -- * ACE Response Source:
    --   A single queue that determines which port the coalesced snoop resonses
    --   shall be forwared to. 
    --   DVM Complete will insert empty entries in this queue to make sure 
    --   a response is genereated. Last complete will actually wait for CR from
    --   Sync Source in order to have something that terminates that response.
    --   (From CR)
    -- 
    -----------------------------------------------------------------------------
    
    Gen_Port_Queues: for I in 0 to C_NUM_PORTS - 1 generate
    begin
      
      Not_Optimized: if( I >= C_NUM_OPTIMIZED_PORTS ) generate
      begin
        ss_push(I)        <= '0';
        ss_pop(I)         <= '0'; 
        ss_fifo_full(I)   <= '0';
        ss_fifo_empty(I)  <= '0';
        
      end generate Not_Optimized;
      
      Is_Optimized: if( I < C_NUM_OPTIMIZED_PORTS ) generate      
      begin
      
        -- Control signals for DVM Sync Source queue.
        -- Push: when Sync transaction is detected propagate to all others.
        -- Pop:  when Complete transaction is detected.
        ss_push(I)  <= snoop_fetch_valid_i and snoop_fetch_dvm_is_sync and not snoop_fetch_dvm_sync(I) and 
                       not snoop_fetch_waiting_4_pipe;
        ss_pop(I)   <= snoop_fetch_valid_i and snoop_fetch_comp_target(I) and 
                       not snoop_fetch_waiting_4_pipe;
        
        FIFO_SS_Pointer: sc_srl_fifo_counter
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
            
            queue_push                => ss_push(I),
            queue_pop                 => ss_pop(I),
            queue_push_qualifier      => '0',
            queue_pop_qualifier       => '0',
            queue_refresh_reg         => open,
            
            queue_almost_full         => open,
            queue_full                => ss_fifo_full(I),
            queue_almost_empty        => open,
            queue_empty               => ss_fifo_empty(I),
            queue_exist               => open,
            queue_line_fit            => open,
            queue_index               => ss_read_fifo_addr_vec(I),
            
            
            -- ---------------------------------------------------
            -- Statistics Signals
            
            stat_reset                => stat_reset,
            stat_enable               => stat_enable,
            
            stat_data                 => open, -- stat_acs_ss,
            
            
            -- ---------------------------------------------------
            -- Assert Signals
            
            assert_error              => ss_assert(I),
            
            
            -- ---------------------------------------------------
            -- Debug Signals
            
            DEBUG                     => open
          );
          
        -- Handle memory for SS Channel FIFO.
        FIFO_SS_Memory : process (ACLK) is
        begin  -- process FIFO_SS_Memory
          if (ACLK'event and ACLK = '1') then    -- rising clock edge
            if ( ss_push(I) = '1' ) then
              -- Insert new item.
              ss_fifo_mem_vec(I)(0).Port_Num     <= get_port_num(snoop_fetch_info.Port_Num, C_NUM_PORTS);
              
              -- Shift FIFO contents.
              ss_fifo_mem_vec(I)(C_QUEUE_LENGTH-1 downto 1) <= ss_fifo_mem_vec(I)(C_QUEUE_LENGTH-2 downto 0);
            end if;
          end if;
        end process FIFO_SS_Memory;
        
      end generate Is_Optimized;
      
    end generate Gen_Port_Queues;
    
    -- Extract information.
    SS_Port_Num_Assign : process(ss_read_fifo_addr_vec, ss_fifo_mem_vec) is
    begin
      ss_port_num <= (others => 0);
      for I in 0 to C_NUM_OPTIMIZED_PORTS - 1 loop
        ss_port_num(I) <= ss_fifo_mem_vec(I)( to_integer(unsigned(ss_read_fifo_addr_vec(I))) ).Port_Num;
      end loop;
    end process SS_Port_Num_Assign;
      
    
    -- Control signals for ACE Response Source queue.
    rs_push           <= access_valid_i and ( reduce_or(access_snooped_ports) or access_no_data ) and 
                         not access_waiting_for_pipe;
    rs_pop            <= access_resp_valid;
    
    FIFO_RS_Pointer: sc_srl_fifo_counter
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
        
        queue_push                => rs_push,
        queue_pop                 => rs_pop,
        queue_push_qualifier      => '0',
        queue_pop_qualifier       => '0',
        queue_refresh_reg         => open,
        
        queue_almost_full         => rs_fifo_almost_full,
        queue_full                => rs_fifo_full,
        queue_almost_empty        => open,
        queue_empty               => rs_fifo_empty,
        queue_exist               => open,
        queue_line_fit            => open,
        queue_index               => rs_read_fifo_addr,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_reset                => stat_reset,
        stat_enable               => stat_enable,
        
        stat_data                 => open, -- stat_acs_rs,
        
        
        -- ---------------------------------------------------
        -- Assert Signals
        
        assert_error              => rs_assert,
        
        
        -- ---------------------------------------------------
        -- Debug Signals
        
        DEBUG                     => open
      );
      
    -- Handle memory for RS Channel FIFO.
    FIFO_RS_Memory : process (ACLK) is
    begin  -- process FIFO_RS_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( rs_push = '1' ) then
          -- Insert new item.
          rs_fifo_mem(0).Port_Num     <= get_port_num(access_info_i.Port_Num, C_NUM_PORTS);
          rs_fifo_mem(0).Resp_Mask    <= access_snooped_ports;
          rs_fifo_mem(0).No_Forward   <= access_no_rs;
          rs_fifo_mem(0).Exclusive_Ok <= access_exclusive_ok;
          
          -- Shift FIFO contents.
          rs_fifo_mem(rs_fifo_mem'left downto 1) <= rs_fifo_mem(rs_fifo_mem'left-1 downto 0);
        end if;
      end if;
    end process FIFO_RS_Memory;
    
    -- Extract information.
    rs_no_forward   <= rs_fifo_mem(to_integer(unsigned(rs_read_fifo_addr))).No_Forward;
    rs_port_num     <= rs_fifo_mem(to_integer(unsigned(rs_read_fifo_addr))).Port_Num;
    rs_resp_mask    <= rs_fifo_mem(to_integer(unsigned(rs_read_fifo_addr))).Resp_Mask;
    rs_exclusive_ok <= rs_fifo_mem(to_integer(unsigned(rs_read_fifo_addr))).Exclusive_Ok;
    
    
    -----------------------------------------------------------------------------
    -- Handle Response Merging
    -- 
    -----------------------------------------------------------------------------
    
    -- Merge all responses.
    Merge_Resp: process (rs_resp_mask, snoop_resp_crresp) is
    begin  -- process Merge_Resp
      access_merged_error <= '0';
      
      for I in C_PORT_POS loop
        if( rs_resp_mask(I) = '1' and snoop_resp_crresp(I)(C_CRRESP_ERROR_POS) = '1' ) then
          access_merged_error <= '1';
        end if;
      end loop;
    end process Merge_Resp;
    
    -- Check if all Resps that has to be merged is available
    access_all_resp_available <= ( not rs_fifo_empty ) when 
                                            ( ( snoop_resp_valid and rs_resp_mask ) = rs_resp_mask ) else 
                                 '0';
    
    -- Check that target queue can fit data.
    access_resp_valid         <= access_all_resp_available and 
                                 ( rs_no_forward or not snoop_read_data_any_valid or
                                   ( snoop_read_data_any_valid and snoop_read_data_ready(snoop_read_data_port_num) ) ); 
    
    -- Acknowledge all sources.
    access_resp_valid_vec     <= (others => access_resp_valid);
    snoop_resp_ready          <= access_resp_valid_vec and
                                 rs_resp_mask;
    
    
    Snoop_Response_Handle : process (ACLK) is
    begin  -- process Snoop_Response_Handle
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_read_data_port_num  <= 0;
          snoop_read_data_any_valid <= '0';
          snoop_read_data_valid     <= (others=>'0');
          snoop_read_data_last      <= '1';
          snoop_read_data_resp      <= C_RRESP_OKAY;
          snoop_read_data_word      <= (others=>'0');
          
        else
          -- Remove message from register when acknowledged.
          if( snoop_read_data_ready(snoop_read_data_port_num) = '1' ) then
            snoop_read_data_any_valid <= '0';
            snoop_read_data_valid     <= (others=>'0');
          end if;
          
          -- Push new message to register (for queue) when there is room.
          if( ( access_resp_valid = '1' ) and ( rs_no_forward = '0' ) ) then
            snoop_read_data_port_num  <= rs_port_num;
            
            snoop_read_data_any_valid <= '1';
            snoop_read_data_valid     <= std_logic_vector(to_unsigned(2 ** rs_port_num, C_NUM_PORTS));
            snoop_read_data_last      <= '1';
            if( access_merged_error = '1' ) then
              snoop_read_data_resp      <= C_RRESP_SLVERR;
            elsif( rs_exclusive_ok = '1' ) then
              snoop_read_data_resp      <= C_RRESP_EXOKAY;
            else
              snoop_read_data_resp      <= C_RRESP_OKAY;
            end if;
            snoop_read_data_word      <= (others=>'0');
          
          end if;
        end if;
      end if;
    end process Snoop_Response_Handle;
    
    
    -----------------------------------------------------------------------------
    -- Exclusive Monitor
    -- 
    -----------------------------------------------------------------------------
    
    Exclusive_Monitor_Handle : process (ACLK) is
    begin  -- process Exclusive_Monitor_Handle
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_ex_monitor_allow_new  <= '1';
          snoop_ex_monitor_port       <= 0;
          
        else
          if( ( snoop_req_valid_i = '1' ) and ( snoop_req_exclusive_ok = '1' ) ) then
            snoop_ex_monitor_allow_new  <= '0';
            snoop_ex_monitor_port       <= get_port_num(snoop_req_info.Port_Num, C_NUM_PORTS);
            
          elsif( ( snoop_req_valid_i = '1' ) and 
                 ( ( snoop_req_allow_exclusive = '1' ) or ( snoop_ex_timer = 0 ) ) ) then
            -- For WT the window for New Exclusive Sequence is increased from until RACK
            -- to until write that conclude the sequence.
            snoop_ex_monitor_allow_new  <= '1';
            
          end if;
          
        end if;
      end if;
    end process Exclusive_Monitor_Handle;
    
    Exclusive_Monitor_Handle_Timer : process (ACLK) is
    begin  -- process Exclusive_Monitor_Handle_Timer
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_ex_enable_timer <= '0';
          
        else
          if( ( snoop_req_valid_i = '1' ) and 
              ( ( snoop_req_allow_exclusive = '1' ) or ( snoop_ex_timer = 0 ) ) ) then
            -- Disable timer when Ex monitor is restarted.
            snoop_ex_enable_timer <= '0';
            
          elsif( ( read_data_ex_rack(snoop_ex_monitor_port) = '1' ) )then
            -- RACK for transaction has been received, enable timer for ex release delay.
            snoop_ex_enable_timer <= '1';
            
          end if;
          
        end if;
      end if;
    end process Exclusive_Monitor_Handle_Timer;
    
    Exclusive_Monitor_Timer : process (ACLK) is
    begin  -- process Exclusive_Monitor_Timer
      if (ACLK'event and ACLK = '1') then   -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active high)
          snoop_ex_timer  <= 0;
          
        elsif( snoop_req_piperun_i = '1' ) then
          if( ( snoop_req_valid_i = '1' ) and ( snoop_req_exclusive_ok = '1' ) ) then
            snoop_ex_timer  <= C_NUM_PORTS;
            
          elsif( ( snoop_ex_timer /= 0 ) and ( snoop_ex_enable_timer = '1' ) and 
                 ( wr_port_inbound(snoop_ex_monitor_port) = '0' ) )then
            snoop_ex_timer  <= snoop_ex_timer - 1;
            
          end if;
          
        end if;
      end if;
    end process Exclusive_Monitor_Timer;
    
    Ex_Monitor: for I in 0 to C_NUM_PORTS - 1 generate
    begin
      
      Exclusive_Monitor_Bit : process (ACLK) is
      begin  -- process Exclusive_Monitor_Bit
        if (ACLK'event and ACLK = '1') then   -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active high)
            snoop_ex_monitor_started(I) <= '0';
            
          elsif( snoop_req_valid_i = '1' ) then
            if( snoop_req_stop_monitor(I) = '1' ) then
              snoop_ex_monitor_started(I) <= '0';
              
            elsif( snoop_req_start_monitor(I) = '1' ) then
              snoop_ex_monitor_started(I) <= '1';
              
            end if;
            
          end if;
        end if;
      end process Exclusive_Monitor_Bit;
      
    end generate Ex_Monitor;
    
    
    -----------------------------------------------------------------------------
    --  
    -- 
    -----------------------------------------------------------------------------
    
    -- Unused.
    access_id               <= (others=>'0');
    
    
    -----------------------------------------------------------------------------
    -- Statistics
    -----------------------------------------------------------------------------
    
    No_Stat: if( not C_USE_STATISTICS ) generate
    begin
      stat_access_fetch_stall <= C_NULL_STAT_POINT;
      stat_access_req_stall   <= C_NULL_STAT_POINT;
      stat_access_act_stall   <= C_NULL_STAT_POINT;
      
    end generate No_Stat;
    
    Use_Stat: if( C_USE_STATISTICS ) generate
      
      signal det_acs_fetch_stall    : std_logic;
      signal det_acs_req_stall      : std_logic;
      signal det_acs_act_stall      : std_logic;
      
    begin
      Stat_Handle : process (ACLK) is
      begin  -- process Stat_Handle
        if ACLK'event and ACLK = '1' then           -- rising clock edge
          if stat_reset = '1' then                  -- synchronous reset (active high)
            det_acs_fetch_stall <= '0';
            det_acs_req_stall   <= '0';
            det_acs_act_stall   <= '0';
            
          else
            det_acs_fetch_stall <= snoop_fetch_valid_i and snoop_fetch_stall;
            det_acs_req_stall   <= snoop_req_valid_i   and snoop_req_stall;
            det_acs_act_stall   <= snoop_act_valid_i   and snoop_act_stall;
            
          end if;
        end if;
      end process Stat_Handle;
      
      Stall_Fetch_Inst: sc_stat_event
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
          
          probe                     => det_acs_fetch_stall,
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_access_fetch_stall
        );
        
      Stall_Req_Inst: sc_stat_event
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
          
          probe                     => det_acs_req_stall,
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_access_req_stall
        );
        
      Stall_Act_Inst: sc_stat_event
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
          
          probe                     => det_acs_act_stall,
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_access_act_stall
        );
        
    end generate Use_Stat;
    
    
    -----------------------------------------------------------------------------
    -- Debug 
    -----------------------------------------------------------------------------
    
    No_Debug: if( not C_USE_DEBUG ) generate
    begin
      ACCESS_DEBUG  <= (others=>'0');
    end generate No_Debug;
    
    Use_Debug: if( C_USE_DEBUG ) generate
      constant C_MY_PORT    : natural := min_of( 4, C_NUM_PORTS);
      constant C_MY_QCNT    : natural := min_of( 4, C_QUEUE_LENGTH_BITS);
      constant C_MY_NUM     : natural := min_of( 2, Log2(C_NUM_PORTS));
      constant C_MY_TIMER   : natural := min_of( 4, Log2(C_NUM_PORTS));
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active true)
            ACCESS_DEBUG                                  <= (others=>'0');
            
          else
            -- Default assignment.
            ACCESS_DEBUG                                  <= (others=>'0');
            
            ACCESS_DEBUG(  0 + C_MY_PORT  - 1 downto   0) <= snoop_fetch_myself_i(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(  4 + C_MY_PORT  - 1 downto   4) <= snoop_fetch_always(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(  8 + C_MY_PORT  - 1 downto   8) <= snoop_fetch_update_filter(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 12 + C_MY_PORT  - 1 downto  12) <= snoop_fetch_comp_target(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 16 + C_MY_PORT  - 1 downto  16) <= snoop_fetch_dvm_sync(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 20 + C_MY_PORT  - 1 downto  20) <= snoop_fetch_want(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 24 + C_MY_PORT  - 1 downto  24) <= snoop_fetch_start_monitor(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 28 + C_MY_PORT  - 1 downto  28) <= snoop_fetch_stop_monitor(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 32 + C_MY_PORT  - 1 downto  32) <= snoop_req_myself_i(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 36 + C_MY_PORT  - 1 downto  36) <= snoop_req_always_i(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 40 + C_MY_PORT  - 1 downto  40) <= snoop_req_update_filter_i(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 44 + C_MY_PORT  - 1 downto  44) <= snoop_req_want_i(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 48 + C_MY_PORT  - 1 downto  48) <= snoop_req_start_monitor(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 52 + C_MY_PORT  - 1 downto  52) <= snoop_req_stop_monitor(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 56 + C_MY_PORT  - 1 downto  56) <= access_snooped_ports(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 60 + C_MY_PORT  - 1 downto  60) <= ss_push(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 64 + C_MY_PORT  - 1 downto  64) <= ss_pop(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 68 + C_MY_PORT  - 1 downto  68) <= ss_fifo_empty(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 72 + C_MY_PORT  - 1 downto  72) <= snoop_fetch_dvm_complete(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 76 + C_MY_PORT  - 1 downto  76) <= snoop_fetch_comp_hold(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 80 + C_MY_PORT  - 1 downto  80) <= snoop_ex_monitor_started(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 84 + C_MY_PORT  - 1 downto  84) <= rs_resp_mask(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 88 + C_MY_PORT  - 1 downto  88) <= snoop_act_tag_valid(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 92 + C_MY_PORT  - 1 downto  92) <= snoop_act_tag_unique(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG( 96 + C_MY_PORT  - 1 downto  96) <= snoop_act_tag_dirty(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(100 + C_MY_PORT  - 1 downto 100) <= snoop_act_done(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(104 + C_MY_PORT  - 1 downto 104) <= snoop_act_use_external(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(108 + C_MY_PORT  - 1 downto 108) <= snoop_info_tag_unique(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(112 + C_MY_PORT  - 1 downto 112) <= snoop_info_tag_dirty(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(116 + C_MY_PORT  - 1 downto 116) <= snoop_resp_valid(C_MY_PORT - 1 downto 0);
            
            ACCESS_DEBUG(120 + C_MY_NUM   - 1 downto 120) <= std_logic_vector(to_unsigned(snoop_fetch_port_num, C_MY_NUM));
            ACCESS_DEBUG(122 + C_MY_NUM   - 1 downto 122) <= std_logic_vector(to_unsigned(snoop_fetch_comp_port, C_MY_NUM));
            ACCESS_DEBUG(124 + C_MY_NUM   - 1 downto 124) <= std_logic_vector(to_unsigned(rs_port_num, C_MY_NUM));
            
            ACCESS_DEBUG(126 + C_MY_PORT  - 1 downto 126) <= ss_assert(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(130 + C_MY_QCNT  - 1 downto 130) <= rs_read_fifo_addr;
            
            ACCESS_DEBUG(                            134) <= snoop_fetch_piperun_i;
            ACCESS_DEBUG(                            135) <= snoop_fetch_stall;
            ACCESS_DEBUG(                            136) <= snoop_fetch_waiting_4_pipe;
            ACCESS_DEBUG(                            137) <= snoop_fetch_valid_i;
            ACCESS_DEBUG(                            138) <= snoop_fetch_any_always;
            ACCESS_DEBUG(                            139) <= snoop_fetch_ud_filter_me;
            ACCESS_DEBUG(                            140) <= snoop_fetch_no_data;
            ACCESS_DEBUG(                            141) <= snoop_fetch_no_rs;
            ACCESS_DEBUG(                            142) <= snoop_fetch_dvm_is_complete;
            ACCESS_DEBUG(                            143) <= snoop_fetch_dvm_is_sync;
            ACCESS_DEBUG(                            144) <= snoop_fetch_any_want;
            ACCESS_DEBUG(                            145) <= snoop_fetch_ex_with_mon;
            ACCESS_DEBUG(                            146) <= snoop_fetch_valid_cu;
            ACCESS_DEBUG(                            147) <= snoop_fetch_exclusive_ok;
            
            ACCESS_DEBUG(                            148) <= snoop_req_piperun_i;
            ACCESS_DEBUG(                            149) <= snoop_req_stall;
            ACCESS_DEBUG(                            150) <= snoop_req_conflict; 
            ACCESS_DEBUG(                            151) <= snoop_req_exclusive_stall;
            ACCESS_DEBUG(                            152) <= snoop_req_valid_i;
            ACCESS_DEBUG(                            153) <= snoop_req_any_always;
            ACCESS_DEBUG(                            154) <= snoop_req_update_filter_me;
            ACCESS_DEBUG(                            155) <= snoop_req_no_data;
            ACCESS_DEBUG(                            156) <= snoop_req_no_rs;
            ACCESS_DEBUG(                            157) <= snoop_req_any_want;
            ACCESS_DEBUG(                            158) <= '0';
            ACCESS_DEBUG(                            159) <= '0';
            ACCESS_DEBUG(                            160) <= snoop_req_exclusive_ok;
            ACCESS_DEBUG(                            161) <= snoop_req_info.Wr;           -- snoop_req_write
            
            ACCESS_DEBUG(                            162) <= snoop_act_piperun_i; 
            ACCESS_DEBUG(                            163) <= snoop_act_stall; 
            ACCESS_DEBUG(                            164) <= snoop_act_valid_i; 
            ACCESS_DEBUG(                            165) <= snoop_act_conflict;
            ACCESS_DEBUG(                            166) <= snoop_act_any_always;
            ACCESS_DEBUG(                            167) <= snoop_act_no_data;
            ACCESS_DEBUG(                            168) <= snoop_act_no_rs;
            ACCESS_DEBUG(                            169) <= snoop_act_waiting_4_pipe_i;
            ACCESS_DEBUG(                            170) <= snoop_act_info.Wr;           -- snoop_act_write
            ACCESS_DEBUG(                            171) <= snoop_act_exclusive_ok;
            
            ACCESS_DEBUG(                            172) <= access_waiting_for_pipe;
            ACCESS_DEBUG(                            173) <= '0';
            ACCESS_DEBUG(                            174) <= '0';
            ACCESS_DEBUG(                            175) <= access_no_data;
            ACCESS_DEBUG(                            176) <= access_no_rs;
            ACCESS_DEBUG(                            177) <= access_exclusive_ok;
            
            ACCESS_DEBUG(                            178) <= snoop_read_data_any_valid;
            ACCESS_DEBUG(                            179) <= reduce_or(ss_assert);
            ACCESS_DEBUG(                            180) <= arb_access.Exclusive;        -- snoop_fetch_exclusive
            ACCESS_DEBUG(                            181) <= snoop_ex_monitor_allow_new;  
            ACCESS_DEBUG(                            182) <= rs_fifo_almost_full;
            
            ACCESS_DEBUG(                            183) <= rs_push;
            ACCESS_DEBUG(                            184) <= rs_pop;
            ACCESS_DEBUG(                            185) <= rs_fifo_full;
            ACCESS_DEBUG(                            186) <= rs_fifo_empty;
            ACCESS_DEBUG(                            187) <= rs_no_forward;
            ACCESS_DEBUG(                            188) <= rs_exclusive_ok;
            ACCESS_DEBUG(                            189) <= rs_assert;
            
            ACCESS_DEBUG(                            190) <= snoop_fetch_dvm_comp_hold;
            
            ACCESS_DEBUG(                            191) <= access_merged_error;
            ACCESS_DEBUG(                            192) <= access_all_resp_available;
            ACCESS_DEBUG(                            193) <= access_resp_valid;
            
            ACCESS_DEBUG(                            194) <= snoop_fetch_is_part2;
            
            ACCESS_DEBUG(195 + C_MY_PORT  - 1 downto 195) <= snoop_fetch_pos_hazard(C_MY_PORT - 1 downto 0);
            ACCESS_DEBUG(                            199) <= snoop_fetch_lx_allocate;
            
            ACCESS_DEBUG(200 + C_MY_NUM   - 1 downto 200) <= std_logic_vector(to_unsigned(snoop_ex_monitor_port, 
                                                                                          C_MY_NUM));
            
            ACCESS_DEBUG(202 + C_MY_TIMER - 1 downto 202) <= std_logic_vector(to_unsigned(snoop_ex_timer, 
                                                                                          C_MY_TIMER));
            
            
            ACCESS_DEBUG(                            206) <= lookup_piperun_i;
            ACCESS_DEBUG(                            207) <= access_evict_line;
            ACCESS_DEBUG(                            208) <= access_evict_1st_cycle;
            ACCESS_DEBUG(                            209) <= access_evict_2nd_cycle;
            ACCESS_DEBUG(                            210) <= access_evict_inserted;
            ACCESS_DEBUG(                            211) <= access_stall;
            ACCESS_DEBUG(                            212) <= snoop_act_evict_line;
            ACCESS_DEBUG(                            213) <= snoop_req_evict_line;
            ACCESS_DEBUG(                            214) <= snoop_fetch_peer_caches;
            ACCESS_DEBUG(                            215) <= snoop_fetch_ds_caches;
            ACCESS_DEBUG(                            216) <= snoop_fetch_valid_ds_ci;
            ACCESS_DEBUG(                            217) <= snoop_fetch_ignore_data;
            ACCESS_DEBUG(                            218) <= snoop_ex_enable_timer;
    
          end if;
        end if;
      end process Debug_Handle;
    end generate Use_Debug;
    
  end generate Use_Coherency;
  
  
  -----------------------------------------------------------------------------
  -- Common code
  -----------------------------------------------------------------------------
  
  -- Exclusive signals.
  access_evict_1st_cycle      <= access_evict_line and not access_evict_inserted;
  access_evict_2nd_cycle      <= access_evict_line and     access_evict_inserted;
  
  -- Handle sequence for Exclusive.
  Pipeline_Exclusive_Handle : process (ACLK) is
  begin  -- process Pipeline_Exclusive_Handle
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET_I = '1' ) then             -- synchronous reset (active high)
        access_evict_inserted <= '0';
      else
        if( lookup_piperun_i = '1' ) then
          access_evict_inserted <= '0';
        elsif( lookup_piperun = '1' ) then
          access_evict_inserted <= access_valid_i and access_evict_line;
        end if;
      end if;
    end if;
  end process Pipeline_Exclusive_Handle;
  
  -- Stalls if preparing for Exclusive.
  access_stall                <= access_valid_i and access_evict_1st_cycle;
  
  -- Assign output directly.
  access_valid                <= access_valid_i;
  
  -- Assign and manipulate Access transaction when evict must be inserted.
  Post_Process_Access: process (access_info_i, access_evict_1st_cycle, access_evict_2nd_cycle) is
  begin  -- process Post_Process_Access
    -- Default assignement.
    access_info               <= access_info_i;
    
    -- Update as necessary.
    access_info.Allocate      <= ( access_info_i.Allocate  and not access_evict_1st_cycle );
    
    access_info.Exclusive     <= ( access_info_i.Exclusive and not access_evict_1st_cycle );
    
    access_info.Evict         <= access_info_i.Evict or
                                 access_evict_1st_cycle;
    
    access_info.SnoopResponse <= ( access_info_i.SnoopResponse and not access_evict_1st_cycle );
    
    access_info.KillHit       <= access_info_i.KillHit or
                                 access_evict_1st_cycle;
    
    access_info.Wr            <= ( access_info_i.Wr        and not access_evict_1st_cycle );
    
  end process Post_Process_Access;
  
  -- Write Data propagation.
  access_data_valid   <= wr_port_data_valid;
  access_data_last    <= wr_port_data_last;
  access_data_be      <= wr_port_data_be;
  access_data_word    <= wr_port_data_word;
  wr_port_data_ready  <= lookup_write_data_ready or update_write_data_ready;
  
  -- Unused.
  access_write_priority   <= (others=>'0');
  access_other_write_prio <= (others=>'0');
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_access_valid       <= C_NULL_STAT_POINT;
    stat_access_stall       <= C_NULL_STAT_POINT;
    
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    
    signal new_access             : std_logic;
    signal count_time             : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal time_valid             : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    
    signal det_acs_stall          : std_logic;
    
  begin
    Stat_Handle : process (ACLK) is
    begin  -- process Stat_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if stat_reset = '1' then                  -- synchronous reset (active high)
          new_access          <= '0';
          count_time          <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
          time_valid          <= (others=>'0');
          det_acs_stall       <= '0';
          
        else
          new_access          <= '0';
          det_acs_stall       <= access_valid_i      and access_stall;
          
          if( access_valid_i = '1' ) then
            count_time  <= std_logic_vector(unsigned(count_time) + 1);
          end if;
          if( lookup_piperun = '1' ) then
            new_access  <= access_valid_i;
            count_time  <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
            time_valid  <= count_time;
            
          end if;
        end if;
      end if;
    end process Stat_Handle;
    
    Valid_Inst: sc_stat_counter
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
        
        update                    => new_access,
        counter                   => time_valid,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_access_valid
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
        
        probe                     => det_acs_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_access_stall
      );
    
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  
  -- Detect condition
  assert_err  <= (others=>'0');
  
  
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
