-------------------------------------------------------------------------------
-- sc_back_end.vhd - Entity and architecture
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
-- Filename:        sc_back_end.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_back_end.vhd
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


entity sc_back_end is
  generic (
    -- General.
    C_TARGET                  : TARGET_FAMILY_TYPE;
    C_USE_DEBUG               : boolean                       := false;
    C_USE_ASSERTIONS          : boolean                       := false;
    C_USE_STATISTICS          : boolean                       := false;
    C_STAT_MEM_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
    C_STAT_MEM_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
    C_STAT_BITS               : natural range  1 to   64      := 32;
    C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
    C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
    C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
    C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
    
    -- PARD Specific.
    C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
    
    -- IP Specific.
    C_BASEADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
    C_HIGHADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
    C_NUM_PORTS               : natural range  1 to   32      :=  1;
    C_CACHE_LINE_LENGTH       : natural range  8 to  128      := 32;
    C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
    C_EXTERNAL_DATA_ADDR_WIDTH: natural range  2 to    7      :=  2;
    C_OPTIMIZE_ORDER          : natural range  0 to    5      :=  0;
    C_ORDER_PER_PORT          : natural range  0 to    1      :=  0;
    C_NUM_ORDER_BINS          : natural range 16 to   64      := 16;
    C_ORDER_BINS_ADDR_MASK    : std_logic_vector(63 downto 0) := X"0000_0000_0000_0000";
    
    -- Data type and settings specific.
    C_ADDR_VALID_HI           : natural range  0 to   63      := 31;
    C_ADDR_VALID_LO           : natural range  0 to   63      := 28;
    C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
    C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
    C_ADDR_TAG_CONTENTS_HI    : natural range  0 to   63      := 27;
    C_ADDR_TAG_CONTENTS_LO    : natural range  0 to   63      :=  7;
    C_ADDR_LINE_HI            : natural range  4 to   63      := 13;
    C_ADDR_LINE_LO            : natural range  4 to   63      :=  7;
    
    -- AXI4 Master Interface specific.
    C_M_AXI_THREAD_ID_WIDTH   : natural range  1 to   32      :=  1;
    C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
    C_M_AXI_ADDR_WIDTH        : natural                       := 32
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Update signals.
    
    read_req_valid            : in  std_logic;
    read_req_port             : in  natural range 0 to C_NUM_PORTS - 1;
    read_req_addr             : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    read_req_len              : in  std_logic_vector(8 - 1 downto 0);
    read_req_size             : in  std_logic_vector(3 - 1 downto 0);
    read_req_exclusive        : in  std_logic;
    read_req_kind             : in  std_logic;
    read_req_ready            : out std_logic;
    read_req_DSid             : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    write_req_valid           : in  std_logic;
    write_req_port            : in  natural range 0 to C_NUM_PORTS - 1;
    write_req_internal        : in  std_logic;
    write_req_addr            : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    write_req_len             : in  std_logic_vector(8 - 1 downto 0);
    write_req_size            : in  std_logic_vector(3 - 1 downto 0);
    write_req_exclusive       : in  std_logic;
    write_req_kind            : in  std_logic;
    write_req_line_only       : in  std_logic;
    write_req_ready           : out std_logic;
    write_req_DSid            : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    
    write_data_valid          : in  std_logic;
    write_data_last           : in  std_logic;
    write_data_be             : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
    write_data_word           : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
    write_data_ready          : out std_logic;
    write_data_almost_full    : out std_logic;
    write_data_full           : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Backend signals (to Update).
    
    backend_wr_resp_valid     : out std_logic;
    backend_wr_resp_port      : in  natural range 0 to C_NUM_PORTS - 1;
    backend_wr_resp_internal  : in  std_logic;
    backend_wr_resp_addr      : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
    backend_wr_resp_bresp     : out AXI_BRESP_TYPE;
    backend_wr_resp_ready     : in  std_logic;
    
    backend_rd_data_valid     : out std_logic;
    backend_rd_data_last      : out std_logic;
    backend_rd_data_word      : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
    backend_rd_data_rresp     : out std_logic_vector(2 - 1 downto 0);
    backend_rd_data_ready     : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- AXI4 Master Interface Signals.
    
    M_AXI_AWID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_AWADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_AWLEN               : out std_logic_vector(7 downto 0);
    M_AXI_AWSIZE              : out std_logic_vector(2 downto 0);
    M_AXI_AWBURST             : out std_logic_vector(1 downto 0);
    M_AXI_AWLOCK              : out std_logic;
    M_AXI_AWCACHE             : out std_logic_vector(3 downto 0);
    M_AXI_AWPROT              : out std_logic_vector(2 downto 0);
    M_AXI_AWQOS               : out std_logic_vector(3 downto 0);
    M_AXI_AWVALID             : out std_logic;
    M_AXI_AWREADY             : in  std_logic;
    M_AXI_AWUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
    
    M_AXI_WDATA               : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_WSTRB               : out std_logic_vector((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
    M_AXI_WLAST               : out std_logic;
    M_AXI_WVALID              : out std_logic;
    M_AXI_WREADY              : in  std_logic;
    
    M_AXI_BRESP               : in  std_logic_vector(1 downto 0);
    M_AXI_BID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_BVALID              : in  std_logic;
    M_AXI_BREADY              : out std_logic;
    
    M_AXI_ARID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_ARADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
    M_AXI_ARLEN               : out std_logic_vector(7 downto 0);
    M_AXI_ARSIZE              : out std_logic_vector(2 downto 0);
    M_AXI_ARBURST             : out std_logic_vector(1 downto 0);
    M_AXI_ARLOCK              : out std_logic;
    M_AXI_ARCACHE             : out std_logic_vector(3 downto 0);
    M_AXI_ARPROT              : out std_logic_vector(2 downto 0);
    M_AXI_ARQOS               : out std_logic_vector(3 downto 0);
    M_AXI_ARVALID             : out std_logic;
    M_AXI_ARREADY             : in  std_logic;
    M_AXI_ARUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
    
    M_AXI_RID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
    M_AXI_RDATA               : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
    M_AXI_RRESP               : in  std_logic_vector(1 downto 0);
    M_AXI_RLAST               : in  std_logic;
    M_AXI_RVALID              : in  std_logic;
    M_AXI_RREADY              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                : in  std_logic;
    stat_enable               : in  std_logic;
    
    stat_be_aw                : out STAT_FIFO_TYPE;     -- Write Address
    stat_be_w                 : out STAT_FIFO_TYPE;     -- Write Data
    stat_be_ar                : out STAT_FIFO_TYPE;     -- Read Address
    stat_be_ar_search_depth   : out STAT_POINT_TYPE;    -- Average search depth
    stat_be_ar_stall          : out STAT_POINT_TYPE;    -- Average total stall
    stat_be_ar_protect_stall  : out STAT_POINT_TYPE;    -- Average protected stall
    stat_be_rd_latency        : out STAT_POINT_TYPE;    -- External Read Latency
    stat_be_wr_latency        : out STAT_POINT_TYPE;    -- External Write Latency
    stat_be_rd_latency_conf   : in  STAT_CONF_TYPE;     -- External Read Latency Configuration
    stat_be_wr_latency_conf   : in  STAT_CONF_TYPE;     -- External Write Latency Configuration
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug Signals.
    
    BACKEND_DEBUG             : out std_logic_vector(255 downto 0)
  );
end entity sc_back_end;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_back_end is

  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_AW_QUEUE_ERROR            : natural :=  0;
  constant C_ASSERT_W_QUEUE_ERROR             : natural :=  1;
  constant C_ASSERT_AR_QUEUE_ERROR            : natural :=  2;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  3;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Ranges for address parts.
  subtype C_ADDR_VALID_POS            is natural range C_ADDR_VALID_HI downto C_ADDR_VALID_LO;
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO;
  subtype C_ADDR_TAG_CONTENTS_POS     is natural range C_ADDR_TAG_CONTENTS_HI downto C_ADDR_TAG_CONTENTS_LO;
  
  -- Subtypes for address parts.
  subtype ADDR_INTERNAL_TYPE          is std_logic_vector(C_ADDR_INTERNAL_POS);
  subtype ADDR_TAG_CONTENTS_TYPE      is std_logic_vector(C_ADDR_TAG_CONTENTS_POS);
  
  -- Read-Write reordering handling.
  constant C_MAX_OUTSTANDING_WRITE    : integer:= 31;
  subtype OUTSTANDING_WRITE_TYPE      is rinteger range 0 to C_MAX_OUTSTANDING_WRITE;
  
  -- Per Port Write Counter
  subtype C_PER_PORT_POS              is rinteger range 0 to C_ORDER_PER_PORT * ( C_NUM_PORTS-1);
  type R_PROTECT_TYPE                 is array(C_PER_PORT_POS)         of ADDR_TAG_CONTENTS_TYPE;
  type PORT_WRITE_CNT_TYPE            is array(C_PER_PORT_POS)         of OUTSTANDING_WRITE_TYPE;
  
  type HISTORY_TYPE is record
    Line_Only         : std_logic;
    Addr              : ADDR_TAG_CONTENTS_TYPE;
    DSid			  : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  end record HISTORY_TYPE;
  
  constant C_NULL_HISTORY             : HISTORY_TYPE  := (Line_Only=>'0', Addr=>(others=>'0'), DSid=>(others=>'0'));
  
  type HISTORY_BUFFER_TYPE            is array(OUTSTANDING_WRITE_TYPE) of HISTORY_TYPE;
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  subtype BE_TYPE                     is std_logic_vector(C_EXTERNAL_DATA_WIDTH / 8 - 1 downto 0);
  subtype DATA_TYPE                   is std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
  subtype LENGTH_TYPE                 is std_logic_vector(8 - 1 downto 0);
  subtype SIZE_TYPE                   is std_logic_vector(3 - 1 downto 0);
  subtype PORT_TYPE                   is std_logic_vector(C_NUM_PORTS - 1 downto 0);
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Types for Queue Length.
  constant C_DATA_QUEUE_LINE_LENGTH   : integer:= 32 * C_CACHE_LINE_LENGTH / C_EXTERNAL_DATA_WIDTH;
  constant C_DATA_QUEUE_LENGTH        : integer:= max_of(16, 2 * C_DATA_QUEUE_LINE_LENGTH);
  constant C_DATA_QUEUE_LENGTH_BITS   : integer:= log2(C_DATA_QUEUE_LENGTH);
  subtype DATA_QUEUE_ADDR_POS         is natural range C_DATA_QUEUE_LENGTH - 1 downto 0;
  subtype DATA_QUEUE_ADDR_TYPE        is std_logic_vector(C_DATA_QUEUE_LENGTH_BITS - 1 downto 0);
  
  
  -- Channel Information.
  type AW_TYPE is record
    Addr              : ADDR_INTERNAL_TYPE;
    Len               : LENGTH_TYPE;
    Size              : SIZE_TYPE;
    Exclusive         : std_logic;
    Kind              : std_logic;
    DSid              : PARD_DSID_TYPE;
  end record AW_TYPE;
  
  type W_TYPE is record
    Last              : std_logic;
    Strb              : BE_TYPE;
    Data              : DATA_TYPE;
  end record W_TYPE;
  
  type AR_TYPE is record
    Port_Num          : natural range 0 to C_NUM_PORTS - 1;
    Addr              : ADDR_INTERNAL_TYPE;
    Len               : LENGTH_TYPE;
    Size              : SIZE_TYPE;
    Exclusive         : std_logic;
    Kind              : std_logic;
    DSid              : PARD_DSID_TYPE;
  end record AR_TYPE;
  
  -- Empty response data.
  constant C_NULL_AW              : AW_TYPE:= (Addr=>(others=>'0'), Len=>(others=>'0'), Size=>(others=>'0'), 
                                               Exclusive=>'0', Kind=>'0', DSid=>(others=>'0'));
  constant C_NULL_W               : W_TYPE:= (Last=>'0', Strb=>(others=>'0'), Data=>(others=>'0'));
  constant C_NULL_AR              : AR_TYPE:= (Port_Num=>0, Addr=>(others=>'0'), Len=>(others=>'0'), 
                                               Size=>(others=>'0'), Exclusive=>'0', Kind=>'0',
                                               DSid=>(others=>'0'));
  
  -- Types for information queue storage.
  type AW_FIFO_MEM_TYPE           is array(QUEUE_ADDR_POS)      of AW_TYPE;
  type W_FIFO_MEM_TYPE            is array(DATA_QUEUE_ADDR_POS) of W_TYPE;
  type AR_FIFO_MEM_TYPE           is array(QUEUE_ADDR_POS)      of AR_TYPE;
  
  
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
  
  component sc_m_axi_interface is
    generic (
      -- General.
      C_TARGET                  : TARGET_FAMILY_TYPE;
      C_USE_STATISTICS          : boolean                       := false;
      C_STAT_MEM_LAT_RD_DEPTH   : natural range  1 to   32      :=  4;
      C_STAT_MEM_LAT_WR_DEPTH   : natural range  1 to   32      := 16;
      C_STAT_BITS               : natural range  1 to   64      := 32;
      C_STAT_BIG_BITS           : natural range  1 to   64      := 48;
      C_STAT_COUNTER_BITS       : natural range  1 to   31      := 16;
      C_STAT_MAX_CYCLE_WIDTH    : natural range  2 to   16      := 16;
      C_STAT_USE_STDDEV         : natural range  0 to    1      :=  0;
      
      -- IP Specific.
      C_BASEADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8000_0000";
      C_HIGHADDR                : std_logic_vector(63 downto 0) := X"0000_0000_8FFF_FFFF";
      C_EXTERNAL_DATA_WIDTH     : natural range 32 to 1024      := 32;
      
      -- Data type and settings specific.
      C_ADDR_VALID_HI           : natural range  0 to   63      := 31;
      C_ADDR_VALID_LO           : natural range  0 to   63      := 28;
      C_ADDR_INTERNAL_HI        : natural range  0 to   63      := 27;
      C_ADDR_INTERNAL_LO        : natural range  0 to   63      :=  0;
      
      -- PARD Specific.
      C_DSID_WIDTH              : natural range  0 to   32      := 16;  -- Tag width / AxUSER width
      
      -- AXI4 Master Interface specific.
      C_M_AXI_THREAD_ID_WIDTH   : natural range  1 to   32      := 1;
      C_M_AXI_DATA_WIDTH        : natural range 32 to 1024      := 32;
      C_M_AXI_ADDR_WIDTH        : natural range 15 to   64      := 32
    );
    port (
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      : in  std_logic;
      ARESET                    : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Out).
      
      aw_valid                  : in  std_logic;
      aw_addr                   : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      aw_len                    : in  std_logic_vector(7 downto 0);
      aw_size                   : in  std_logic_vector(2 downto 0);
      aw_exclusive              : in  std_logic;
      aw_kind                   : in  std_logic;
      aw_ready                  : out std_logic;
      aw_DSid                   : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      w_valid                   : in  std_logic;
      w_last                    : in  std_logic;
      w_strb                    : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
      w_data                    : in  std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      w_ready                   : out std_logic;
      
      ar_valid                  : in  std_logic;
      ar_addr                   : in  std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
      ar_len                    : in  std_logic_vector(7 downto 0);
      ar_size                   : in  std_logic_vector(2 downto 0);
      ar_exclusive              : in  std_logic;
      ar_kind                   : in  std_logic;
      ar_ready                  : out std_logic;
      ar_DSid                   : in  std_logic_vector(C_DSID_WIDTH - 1 downto 0);
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (In).
      
      backend_wr_resp_valid     : out std_logic;
      backend_wr_resp_bresp     : out std_logic_vector(2 - 1 downto 0);
      backend_wr_resp_ready     : in  std_logic;
      
      backend_rd_data_valid     : out std_logic;
      backend_rd_data_last      : out std_logic;
      backend_rd_data_word      : out std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
      backend_rd_data_rresp     : out std_logic_vector(2 - 1 downto 0);
      backend_rd_data_ready     : in  std_logic;
      
      
      -- ---------------------------------------------------
      -- AXI4 Master Interface Signals.
      
      M_AXI_AWID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_AWADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_AWLEN               : out std_logic_vector(7 downto 0);
      M_AXI_AWSIZE              : out std_logic_vector(2 downto 0);
      M_AXI_AWBURST             : out std_logic_vector(1 downto 0);
      M_AXI_AWLOCK              : out std_logic;
      M_AXI_AWCACHE             : out std_logic_vector(3 downto 0);
      M_AXI_AWPROT              : out std_logic_vector(2 downto 0);
      M_AXI_AWQOS               : out std_logic_vector(3 downto 0);
      M_AXI_AWVALID             : out std_logic;
      M_AXI_AWREADY             : in  std_logic;
      M_AXI_AWUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
      
      M_AXI_WDATA               : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      M_AXI_WSTRB               : out std_logic_vector((C_M_AXI_DATA_WIDTH/8)-1 downto 0);
      M_AXI_WLAST               : out std_logic;
      M_AXI_WVALID              : out std_logic;
      M_AXI_WREADY              : in  std_logic;
      
      M_AXI_BRESP               : in  std_logic_vector(1 downto 0);
      M_AXI_BID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_BVALID              : in  std_logic;
      M_AXI_BREADY              : out std_logic;
      
      M_AXI_ARID                : out std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_ARADDR              : out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
      M_AXI_ARLEN               : out std_logic_vector(7 downto 0);
      M_AXI_ARSIZE              : out std_logic_vector(2 downto 0);
      M_AXI_ARBURST             : out std_logic_vector(1 downto 0);
      M_AXI_ARLOCK              : out std_logic;
      M_AXI_ARCACHE             : out std_logic_vector(3 downto 0);
      M_AXI_ARPROT              : out std_logic_vector(2 downto 0);
      M_AXI_ARQOS               : out std_logic_vector(3 downto 0);
      M_AXI_ARVALID             : out std_logic;
      M_AXI_ARREADY             : in  std_logic;
      M_AXI_ARUSER              : out std_logic_vector(C_DSID_WIDTH-1 downto 0);
      
      M_AXI_RID                 : in  std_logic_vector(C_M_AXI_THREAD_ID_WIDTH-1 downto 0);
      M_AXI_RDATA               : in  std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
      M_AXI_RRESP               : in  std_logic_vector(1 downto 0);
      M_AXI_RLAST               : in  std_logic;
      M_AXI_RVALID              : in  std_logic;
      M_AXI_RREADY              : out std_logic;
    
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                : in  std_logic;
      stat_enable               : in  std_logic;
      
      stat_be_rd_latency        : out STAT_POINT_TYPE;    -- External Read Latency
      stat_be_wr_latency        : out STAT_POINT_TYPE;    -- External Write Latency
      stat_be_rd_latency_conf   : in  STAT_CONF_TYPE;     -- External Read Latency Configuration
      stat_be_wr_latency_conf   : in  STAT_CONF_TYPE      -- External Write Latency Configuration
    );
  end component sc_m_axi_interface;
  
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
  
  component comparator is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET          : TARGET_FAMILY_TYPE;
      C_SIZE            : natural);
    port (
      Carry_IN  : in  std_logic;
      DI        : in  std_logic;
      A_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      B_Vec     : in  std_logic_vector(C_SIZE-1 downto 0);
      Carry_OUT : out std_logic
    );
  end component comparator;
  
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
  -- Write Buffers
  
  signal write_req_ready_i          : std_logic;
  signal aw_push                    : std_logic;
  signal aw_pop                     : std_logic;
  signal aw_read_fifo_addr          : QUEUE_ADDR_TYPE:= (others=>'1');
  signal aw_fifo_mem                : AW_FIFO_MEM_TYPE; -- := (others=>C_NULL_AW);
  signal aw_fifo_full               : std_logic;
  signal aw_fifo_empty              : std_logic;
  signal aw_valid                   : std_logic;
  signal aw_addr                    : std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
  signal aw_len                     : std_logic_vector(7 downto 0);
  signal aw_size                    : std_logic_vector(2 downto 0);
  signal aw_exclusive               : std_logic;
  signal aw_kind                    : std_logic;
  signal aw_ready                   : std_logic;
  signal aw_DSid                    : std_logic_vector(C_DSID_WIDTH-1 downto 0);
  signal aw_assert                  : std_logic;
  signal write_data_ready_i         : std_logic;
  signal w_push                     : std_logic;
  signal w_pop                      : std_logic;
  signal w_fifo_mem                 : W_FIFO_MEM_TYPE; -- := (others=>C_NULL_W);
  signal w_read_fifo_addr           : DATA_QUEUE_ADDR_TYPE:= (others=>'1');
  signal w_fifo_almost_full         : std_logic;
  signal w_fifo_full                : std_logic;
  signal w_fifo_empty               : std_logic;
  signal w_valid                    : std_logic;
  signal w_last                     : std_logic;
  signal w_strb                     : std_logic_vector(C_EXTERNAL_DATA_WIDTH/8 - 1 downto 0);
  signal w_data                     : std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
  signal w_ready                    : std_logic;
  signal w_assert                   : std_logic;
  
  
  -- ----------------------------------------
  -- Read Buffer
  
  signal read_req_ready_i           : std_logic;
  signal ar_push                    : std_logic;
  signal ar_pop_i                   : std_logic;
  signal ar_pop                     : std_logic;
  signal ar_pop_or_reset            : std_logic;
  signal ar_read_fifo_addr          : QUEUE_ADDR_TYPE:= (others=>'1');
  signal ar_fifo_mem                : AR_FIFO_MEM_TYPE; -- := (others=>C_NULL_AR);
  signal ar_fifo_full               : std_logic;
  signal ar_fifo_empty              : std_logic;
  
  signal ar_exist                   : std_logic;
  signal ar_valid                   : std_logic;
  signal ar_port                    : natural range 0 to C_NUM_PORTS - 1;
  signal ar_addr                    : std_logic_vector(C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO);
  signal ar_len                     : std_logic_vector(7 downto 0);
  signal ar_size                    : std_logic_vector(2 downto 0);
  signal ar_exclusive               : std_logic;
  signal ar_kind                    : std_logic;
  signal ar_ready                   : std_logic;
  signal ar_DSid                    : std_logic_vector(C_DSID_WIDTH-1 downto 0);
  signal ar_assert                  : std_logic;
  
  
  -- ----------------------------------------
  -- Placement of Reorder Check
  
  signal allow_read_req_ready       : std_logic;
  signal allow_ar_valid             : std_logic;
  signal check_port                 : rinteger range 0 to C_NUM_PORTS - 1;
  signal check_addr                 : ADDR_INTERNAL_TYPE;
  signal check_DSid                 : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
  
  signal read_possible_for_pending  : std_logic;
  signal search_count               : OUTSTANDING_WRITE_TYPE;
  signal protected_read_hit_n       : std_logic;
  
  signal protected_read_hit_n_without_DSid	: std_logic;
  signal protected_read_hit_n_DSid		: std_logic;
  
  -- ----------------------------------------
  -- Write-Read Reordering Control
  
  signal pending_write              : OUTSTANDING_WRITE_TYPE;
  signal push_pending_write         : std_logic;
  signal pop_pending_write          : std_logic;
  signal refresh_pending_write      : std_logic;
  signal need_to_stall_write        : std_logic;
  signal need_to_stall_write_cmb    : std_logic;
  signal no_write_blocking_read     : std_logic;
  signal pending_write_is_1         : std_logic;
  
  
  -- ----------------------------------------
  -- Write Response Handling
  
  signal backend_wr_resp_valid_i    : std_logic;
  signal backend_wr_resp_bresp_i    : std_logic_vector(2 - 1 downto 0);
  signal backend_wr_resp_ready_i    : std_logic;
  
  
  -- ----------------------------------------
  -- Read Handling

  signal backend_rd_data_valid_i    : std_logic;
  signal backend_rd_data_last_i     : std_logic;
  signal backend_rd_data_word_i     : std_logic_vector(C_EXTERNAL_DATA_WIDTH - 1 downto 0);
  signal backend_rd_data_rresp_i    : std_logic_vector(2 - 1 downto 0);
  signal backend_rd_data_ready_i    : std_logic;
  

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
  -- Write Buffers
  -----------------------------------------------------------------------------
  
  -- Control signals for write address buffer.
  write_req_ready_i   <= not aw_fifo_full and not need_to_stall_write;
  write_req_ready     <= write_req_ready_i;
  aw_push             <= push_pending_write;
  aw_pop              <= aw_valid and aw_ready;
  
  -- Control signals for write data buffer.
  write_data_ready_i  <= not w_fifo_full;
  write_data_ready    <= write_data_ready_i;
  w_push              <= write_data_valid and write_data_ready_i;
  w_pop               <= w_valid and w_ready;
    
  FIFO_AW_Pointer: sc_srl_fifo_counter
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
      
      queue_push                => aw_push,
      queue_pop                 => aw_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => aw_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => aw_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => aw_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_be_aw,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => aw_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
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
      
      queue_push                => w_push,
      queue_pop                 => w_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => w_fifo_almost_full,
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
      
      stat_data                 => stat_be_w,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => w_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for AW Channel FIFO.
  FIFO_AW_Memory : process (ACLK) is
  begin  -- process FIFO_AW_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( aw_push = '1' ) then
        -- Insert new item.
        aw_fifo_mem(0).Addr       <= write_req_addr;
        aw_fifo_mem(0).Len        <= write_req_len;
        aw_fifo_mem(0).Size       <= write_req_size;
        aw_fifo_mem(0).Kind       <= write_req_kind;
        aw_fifo_mem(0).Exclusive  <= write_req_exclusive;
        aw_fifo_mem(0).DSid       <= write_req_DSid;
        
        -- Shift FIFO contents.
        aw_fifo_mem(aw_fifo_mem'left downto 1) <= aw_fifo_mem(aw_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_AW_Memory;

  -- Handle memory for W Channel FIFO.
  FIFO_W_Memory : process (ACLK) is
  begin  -- process FIFO_W_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( w_push = '1') then
        -- Insert new item.
        w_fifo_mem(0).Last  <= write_data_last;
        w_fifo_mem(0).Strb  <= write_data_be;
        w_fifo_mem(0).Data  <= write_data_word;
        
        -- Shift FIFO contents.
        w_fifo_mem(w_fifo_mem'left downto 1) <= w_fifo_mem(w_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_W_Memory;
  
  -- Extract data for AW-Channel.
  aw_valid      <= not aw_fifo_empty;
  aw_addr       <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).Addr;
  aw_len        <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).Len;
  aw_size       <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).Size;
  aw_exclusive  <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).Exclusive;
  aw_kind       <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).Kind;
  aw_DSid       <= aw_fifo_mem(to_integer(unsigned(aw_read_fifo_addr))).DSid;
  
  -- Extract data for W-Channel.
  w_valid       <= not w_fifo_empty;
  w_last        <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Last;
  w_strb        <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Strb;
  w_data        <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Data;
  
  -- Assign external signals.
  write_data_almost_full  <= w_fifo_almost_full;
  write_data_full         <= w_fifo_full;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Handling
  -----------------------------------------------------------------------------
  
  -- Rename signal.  
  backend_wr_resp_valid   <= backend_wr_resp_valid_i;
  backend_wr_resp_ready_i <= backend_wr_resp_ready;
  
  
  -----------------------------------------------------------------------------
  -- Read Buffer
  -----------------------------------------------------------------------------
  
  -- Control signals for read address buffer.
  read_req_ready_i  <= allow_read_req_ready and not ar_fifo_full;
  read_req_ready    <= read_req_ready_i;
  ar_push           <= read_req_valid and read_req_ready_i;
--  ar_pop            <= ar_valid and ar_ready;
  BE_Valid_And_Inst2: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => ar_valid,
      A         => ar_ready,
      Carry_OUT => ar_pop_i
    );
  LU_Mem_PR_Latch_Inst1: carry_latch_or
    generic map(
      C_TARGET  => C_TARGET,
      C_NUM_PAD => 0,
      C_INV_C   => false
    )
    port map(
      Carry_IN  => ar_pop_i,
      A         => ARESET_I,
      O         => ar_pop_or_reset,
      Carry_OUT => ar_pop
    );
  
  FIFO_AR_Pointer: sc_srl_fifo_counter
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
      
      queue_push                => ar_push,
      queue_pop                 => ar_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => open,
      queue_full                => ar_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => ar_fifo_empty,
      queue_exist               => open,
      queue_line_fit            => open,
      queue_index               => ar_read_fifo_addr,
      
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_data                 => stat_be_ar,
      
      
      -- ---------------------------------------------------
      -- Assert Signals
      
      assert_error              => ar_assert,
      
      
      -- ---------------------------------------------------
      -- Debug Signals
      
      DEBUG                     => open
    );
    
  -- Handle memory for AR Channel FIFO.
  FIFO_AR_Memory : process (ACLK) is
  begin  -- process FIFO_AR_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( ar_push = '1' ) then
        -- Insert new item.
        ar_fifo_mem(0).Port_Num   <= read_req_port;
        ar_fifo_mem(0).Addr       <= read_req_addr;
        ar_fifo_mem(0).Len        <= read_req_len;
        ar_fifo_mem(0).Size       <= read_req_size;
        ar_fifo_mem(0).Kind       <= read_req_kind;
        ar_fifo_mem(0).Exclusive  <= read_req_exclusive;
        ar_fifo_mem(0).DSid       <= read_req_DSid;
        
        -- Shift FIFO contents.
        ar_fifo_mem(ar_fifo_mem'left downto 1) <= ar_fifo_mem(ar_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_AR_Memory;
  
  -- Extract data for AR-Channel.
  ar_exist      <= not ar_fifo_empty;
--  ar_valid      <= allow_ar_valid and ar_exist;
  BE_Valid_And_Inst1: carry_and
    generic map(
      C_TARGET  => C_TARGET
    )
    port map(
      Carry_IN  => allow_ar_valid,
      A         => ar_exist,
      Carry_OUT => ar_valid
    );
  
  ar_port       <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Port_Num;
  ar_addr       <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Addr;
  ar_len        <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Len;
  ar_size       <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Size;
  ar_exclusive  <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Exclusive;
  ar_kind       <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).Kind;
  ar_DSid       <= ar_fifo_mem(to_integer(unsigned(ar_read_fifo_addr))).DSid;
  
  
  -----------------------------------------------------------------------------
  -- Read Handling
  -----------------------------------------------------------------------------
  
  -- Rename signal.  
  backend_rd_data_valid   <= backend_rd_data_valid_i;
  backend_rd_data_last    <= backend_rd_data_last_i;
  backend_rd_data_ready_i <= backend_rd_data_ready;
  
  
  -----------------------------------------------------------------------------
  -- Placement of Reorder Check
  -----------------------------------------------------------------------------
  
  allow_read_req_ready  <= '1';
  allow_ar_valid        <= no_write_blocking_read;
  check_port            <= ar_port;
  check_addr            <= ar_addr;
  check_DSid            <= ar_DSid;
  
  
  -----------------------------------------------------------------------------
  -- Write-Read Reordering Control
  -----------------------------------------------------------------------------
  
  -- Create control signals.
  push_pending_write    <= write_req_valid and write_req_ready_i;
  pop_pending_write     <= backend_wr_resp_valid_i and backend_wr_resp_ready_i;
  refresh_pending_write <= push_pending_write xor pop_pending_write;
  
  -- Up/Down counter for outstanding transactions.
  Outstanding_Write_Cnt : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active true)
        pending_write           <= 0;
        pending_write_is_1      <= '0';
      elsif( refresh_pending_write = '1' ) then
        -- Handle Read Write ordering.
        if( push_pending_write = '1' ) then
          -- New write request.
          pending_write           <= pending_write + 1;
          pending_write_is_1      <= '0';
          if( pending_write = 0 ) then
            pending_write_is_1      <= '1';
          end if;
        else
          -- Write completed.
          -- pragma translate_off
          if (pending_write > 0) then
          -- pragma translate_on
          pending_write           <= pending_write - 1;
          -- pragma translate_off
          end if;
          -- pragma translate_on
          pending_write_is_1      <= '0';
          if( pending_write = 2 ) then
            pending_write_is_1      <= '1';
          end if;
        end if;
        
      end if;
    end if;
  end process Outstanding_Write_Cnt;
  
  -- Flags for outstanding transactions.
  Outstanding_Write_Flags : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if (ARESET_I = '1') then              -- synchronous reset (active true)
        need_to_stall_write     <= '0';
      elsif( refresh_pending_write = '1' ) then
        -- Handle Buffer level throttling.
        need_to_stall_write     <= need_to_stall_write_cmb;
      end if;
    end if;
  end process Outstanding_Write_Flags;
  
  -- Check threshold for outstanding write.
  -- => Stop further accesses if limit has been reached.
  need_to_stall_write_cmb     <= '0' when (pending_write < C_MAX_OUTSTANDING_WRITE - 1) else push_pending_write;
  
  
  -----------------------------------------------------------------------------
  -- Write-Read Reordering Algorithm #4
  -- 
  -- Serial search a history buffer to see if there are any conflicting writes
  -- for the read.
  -- Wait until the blocking write has been removed from the history queue 
  -- with a BRESP.
  -----------------------------------------------------------------------------
  
  Order_Optimization_4: if( C_OPTIMIZE_ORDER = 4 ) generate
    signal buffer_addr                : std_logic_vector(Log2(C_MAX_OUTSTANDING_WRITE) - 1 downto 0);
    signal protected_read_addr        : ADDR_TAG_CONTENTS_TYPE;
    signal protected_read_DSid        : std_logic_vector(C_DSID_WIDTH - 1 downto 0);
    signal hist_fifo_mem              : HISTORY_BUFFER_TYPE;
    
    signal check_addr_i               : std_logic_vector(C_ADDR_TAG_CONTENTS_HI downto C_ADDR_TAG_CONTENTS_LO - 1);
    signal prot_addr_i                : std_logic_vector(C_ADDR_TAG_CONTENTS_HI downto C_ADDR_TAG_CONTENTS_LO - 1);
    signal protected_read_hit_high_n  : std_logic;
    signal protected_line_only        : std_logic;
    signal protected_read_hit_other_n : std_logic;
    signal be_no_block_1              : std_logic;
    signal be_pop_last_check          : std_logic;
    signal be_no_block_1to2_part      : std_logic;
    signal search_count_i             : std_logic_vector(Log2(C_MAX_OUTSTANDING_WRITE) - 1 downto 0);
    signal pending_write_i            : std_logic_vector(Log2(C_MAX_OUTSTANDING_WRITE) - 1 downto 0);
    signal be_no_block_1to2           : std_logic;
    signal be_all_checked             : std_logic;
    signal be_no_block_1to3           : std_logic;
    signal be_pop_last                : std_logic;
    signal be_no_block_1to4           : std_logic;
    signal be_no_write                : std_logic;
  begin
    -- Handle serch for address.
    Track_Read_Search: process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if( ar_pop_or_reset = '1' ) then    -- synchronous reset (active true)
            -- Buffer pointer is reset when a read is completed (on AR).
            buffer_addr   <= (others=>'0');
            search_count  <= 1;
        elsif( ( ( ar_exist = '1' ) and ( protected_read_hit_n = '1' ) and ( search_count <= pending_write ) ) or
               ( ( ar_exist = '1' ) and ( push_pending_write = '1' ) and ( search_count <= C_MAX_OUTSTANDING_WRITE ) ) ) then
          -- Buffer pointer is increased while there is no match in the buffer. When
          -- the last entry has been reach with no collision the read can commence 
          -- externally.
          buffer_addr   <= std_logic_vector(unsigned(buffer_addr) + 1);
          search_count  <= search_count + 1;
        end if;
        
      end if;
    end process Track_Read_Search;
    
    -- Write History buffer.
    Write_History : process (ACLK) is
    begin  -- process Req_FIFO_Memory
      if (ACLK'event and ACLK = '1') then    -- rising clock edge
        if ( push_pending_write = '1') then
          -- Insert new item.
          hist_fifo_mem(0).Line_Only  <= write_req_line_only;
          hist_fifo_mem(0).Addr       <= write_req_addr(C_ADDR_TAG_CONTENTS_POS);
          hist_fifo_mem(0).DSid       <= write_req_DSid;
          
          -- Shift FIFO contents.
          hist_fifo_mem(1 to hist_fifo_mem'right) <= hist_fifo_mem(0 to hist_fifo_mem'right-1);
        end if;
      end if;
    end process Write_History;
    
    -- Get currently searched entry.
    protected_read_addr <= hist_fifo_mem(to_integer(unsigned(buffer_addr))).Addr; 
    protected_line_only <= hist_fifo_mem(to_integer(unsigned(buffer_addr))).Line_Only; 
    protected_read_DSid <= hist_fifo_mem(to_integer(unsigned(buffer_addr))).DSid;
    -- Detect hit in forbidden area.

--  protected_read_hit_n  <= '0' when check_addr(C_ADDR_TAG_CONTENTS_POS) = protected_read_addr(C_ADDR_TAG_CONTENTS_POS) and check_DSid = protected_read_DSid
--                             else '1';


    check_addr_i  <= check_addr(C_ADDR_TAG_CONTENTS_POS) & '1';
    prot_addr_i   <= protected_read_addr(C_ADDR_TAG_CONTENTS_POS) & '1';
    Prot_Inst_High: comparator
      generic map(
        C_TARGET          => C_TARGET,
        C_SIZE            => C_ADDR_TAG_CONTENTS_HI - C_ADDR_LINE_HI 
      )
      port map(
        Carry_IN          => '0',
        DI                => '1',
        A_Vec             => check_addr_i(C_ADDR_TAG_CONTENTS_HI downto C_ADDR_LINE_HI + 1),
        B_Vec             => prot_addr_i(C_ADDR_TAG_CONTENTS_HI downto C_ADDR_LINE_HI + 1),
        Carry_OUT         => protected_read_hit_high_n
      );
    
    Prot_Inst_Select: carry_and_n
      generic map(
        C_TARGET          => C_TARGET
      )
      port map(
        Carry_IN          => protected_read_hit_high_n,
        A_N               => protected_line_only,
        Carry_OUT         => protected_read_hit_other_n
      );
    
    Prot_Inst_Low: comparator
      generic map(
        C_TARGET          => C_TARGET,
        C_SIZE            => C_ADDR_LINE_HI - C_ADDR_TAG_CONTENTS_LO + 2
      )
      port map(
        Carry_IN          => protected_read_hit_other_n,
        DI                => '1',
        A_Vec             => check_addr_i(C_ADDR_LINE_HI downto C_ADDR_TAG_CONTENTS_LO - 1),
        B_Vec             => prot_addr_i(C_ADDR_LINE_HI downto C_ADDR_TAG_CONTENTS_LO - 1),
        Carry_OUT         => protected_read_hit_n_without_DSid
      );

    Prot_Inst_DSid: comparator
      generic map(
        C_TARGET          => RTL,
        C_SIZE            => C_DSID_WIDTH
      )
      port map(
        Carry_IN          => '0',
        DI                => '1',
        A_Vec             => check_DSid,
        B_Vec             => protected_read_DSid,
        Carry_OUT         => protected_read_hit_n_DSid
      );
    -- Hit = 0 , Miss = 1
    protected_read_hit_n <= protected_read_hit_n_without_DSid or protected_read_hit_n_DSid;
    
    -- End of the write queue has been reached. If there is no collision the
    -- read can begin (externally).
    read_possible_for_pending <= '1' when ( search_count = pending_write ) else '0';
    
    -- Check when it is safe to initiate read.
    -- 1) All active write is safe.
    -- 2) Oldest and current element removed from queue (doesn't matter if it is collision).
    -- 3) Entire queue has been checked (includes no queue at all).
    -- 4) Last write acknowledged (for this port) regardless if it is conflict.
    -- 5) No pending write.
--    no_write_blocking_read  <= '1' when
--                               ( (protected_read_hit_n = '1') and read_possible_for_pending = '1' ) or 
--                               ( (pop_pending_write = '1') and read_possible_for_pending = '1' ) or
--                               ( search_count > pending_write ) or 
--                               ( (pending_write  = 1) and (pop_pending_write = '1') ) or 
--                               ( pending_write = 0 )
--                               else '0';

--    BE_Block_And_Inst1: carry_and
--      generic map(
--        C_TARGET  => C_TARGET
--      )
--      port map(
--        Carry_IN  => protected_read_hit_n,
--        A         => read_possible_for_pending,
--        Carry_OUT => be_no_block_1
--      );
--    
--    be_pop_last_check <= pop_pending_write and read_possible_for_pending;
--    
--    BE_Block_Or_Inst1: carry_or
--      generic map(
--        C_TARGET  => C_TARGET
--      )
--      port map(
--        Carry_IN  => be_no_block_1,
--        A         => be_pop_last_check,
--        Carry_OUT => be_no_block_1to2
--      );

    BE_Block_Or_Inst1: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => protected_read_hit_n,
        A         => pop_pending_write,
        Carry_OUT => be_no_block_1to2_part
      );
      
    search_count_i  <= std_logic_vector(to_unsigned(search_count,  Log2(C_MAX_OUTSTANDING_WRITE)));
    pending_write_i <= std_logic_vector(to_unsigned(pending_write, Log2(C_MAX_OUTSTANDING_WRITE)));
    
    Pos_Inst: comparator
      generic map(
        C_TARGET          => C_TARGET,
        C_SIZE            => Log2(C_MAX_OUTSTANDING_WRITE)
      )
      port map(
        Carry_IN          => be_no_block_1to2_part,
        DI                => '0',
        A_Vec             => search_count_i,
        B_Vec             => pending_write_i,
        Carry_OUT         => be_no_block_1to2
      );
    
    be_all_checked    <= '1' when ( search_count > pending_write ) else '0';
    
    BE_Block_Or_Inst2: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => be_no_block_1to2,
        A         => be_all_checked,
        Carry_OUT => be_no_block_1to3
      );
    
    be_pop_last       <= '1' when ( (pending_write_is_1 = '1') and (pop_pending_write = '1') ) else '0';
    
    BE_Block_Or_Inst3: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => be_no_block_1to3,
        A         => be_pop_last,
        Carry_OUT => be_no_block_1to4
      );
    
    be_no_write       <= '1' when ( pending_write = 0 ) else '0';
    
    BE_Block_Or_Inst4: carry_or
      generic map(
        C_TARGET  => C_TARGET
      )
      port map(
        Carry_IN  => be_no_block_1to4,
        A         => be_no_write,
        Carry_OUT => no_write_blocking_read
      );
    
    No_Debug: if( not C_USE_DEBUG ) generate
    begin
      BACKEND_DEBUG(255 downto 230) <= (others=>'0');
    end generate No_Debug;
    
    Use_Debug: if( C_USE_DEBUG ) generate
      constant C_MY_ADDR    : natural := min_of(256-230, C_ADDR_TAG_CONTENTS_HI - C_ADDR_TAG_CONTENTS_LO + 1);
      constant C_MY_BADDR   : natural := min_of(6, Log2(C_MAX_OUTSTANDING_WRITE));
      
    begin
      Debug_Handle : process (ACLK) is 
      begin  
        if ACLK'event and ACLK = '1' then     -- rising clock edge
          if (ARESET_I = '1') then              -- synchronous reset (active true)
            BACKEND_DEBUG(255 downto 230) <= (others=>'0');
          else
            -- Default assignment.
            BACKEND_DEBUG(255                   downto 230) <= (others=>'0');
            
            BACKEND_DEBUG(230 + C_MY_BADDR  - 1 downto 230) <= buffer_addr(C_MY_BADDR- 1 downto 0);
            BACKEND_DEBUG(236 + C_MY_BADDR  - 1 downto 236) <= std_logic_vector(to_unsigned(search_count, C_MY_BADDR));
            BACKEND_DEBUG(                             242) <= protected_read_hit_n;
            BACKEND_DEBUG(                             243) <= read_possible_for_pending;
            BACKEND_DEBUG(                             244) <= ar_valid;
            
          end if;
        end if;
      end process Debug_Handle;
    end generate Use_Debug;
    
  end generate Order_Optimization_4;
  
  
  -----------------------------------------------------------------------------
  -- Master AXI Interface
  -----------------------------------------------------------------------------
  
  M_AXI_INST: sc_m_axi_interface
    generic map(
      -- General.
      C_TARGET                  => C_TARGET,
      C_USE_STATISTICS          => C_USE_STATISTICS,
      C_STAT_MEM_LAT_RD_DEPTH   => C_STAT_MEM_LAT_RD_DEPTH,
      C_STAT_MEM_LAT_WR_DEPTH   => C_STAT_MEM_LAT_WR_DEPTH,
      C_STAT_BITS               => C_STAT_BITS,
      C_STAT_BIG_BITS           => C_STAT_BIG_BITS,
      C_STAT_COUNTER_BITS       => C_STAT_COUNTER_BITS,
      C_STAT_MAX_CYCLE_WIDTH    => C_STAT_MAX_CYCLE_WIDTH,
      C_STAT_USE_STDDEV         => C_STAT_USE_STDDEV,
      
      -- IP Specific.
      C_BASEADDR                => C_BASEADDR,
      C_HIGHADDR                => C_HIGHADDR,
      C_EXTERNAL_DATA_WIDTH     => C_EXTERNAL_DATA_WIDTH,
      
      -- Data type and settings specific.
      C_ADDR_VALID_HI           => C_ADDR_VALID_HI,
      C_ADDR_VALID_LO           => C_ADDR_VALID_LO,
      C_ADDR_INTERNAL_HI        => C_ADDR_INTERNAL_HI,
      C_ADDR_INTERNAL_LO        => C_ADDR_INTERNAL_LO,
      
      -- PARD Specific.
      C_DSID_WIDTH              => C_DSID_WIDTH,

      -- AXI4 Master Interface specific.
      C_M_AXI_THREAD_ID_WIDTH   => C_M_AXI_THREAD_ID_WIDTH,
      C_M_AXI_DATA_WIDTH        => C_M_AXI_DATA_WIDTH,
      C_M_AXI_ADDR_WIDTH        => C_M_AXI_ADDR_WIDTH
    )
    port map(
      -- ---------------------------------------------------
      -- Common signals.
      ACLK                      => ACLK,
      ARESET                    => ARESET_I,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (Out).
      
      aw_valid                  => aw_valid,
      aw_addr                   => aw_addr,
      aw_len                    => aw_len,
      aw_size                   => aw_size,
      aw_exclusive              => aw_exclusive,
      aw_kind                   => aw_kind,
      aw_ready                  => aw_ready,
      aw_DSid                   => aw_DSid,
      
      w_valid                   => w_valid,
      w_last                    => w_last,
      w_strb                    => w_strb,
      w_data                    => w_data,
      w_ready                   => w_ready,
      
      ar_valid                  => ar_valid,
      ar_addr                   => ar_addr,
      ar_len                    => ar_len,
      ar_size                   => ar_size,
      ar_exclusive              => ar_exclusive,
      ar_kind                   => ar_kind,
      ar_ready                  => ar_ready,
      ar_DSid                   => ar_DSid,
      
      
      -- ---------------------------------------------------
      -- Internal Interface Signals (In).
      
      backend_wr_resp_valid     => backend_wr_resp_valid_i,
      backend_wr_resp_bresp     => backend_wr_resp_bresp_i,
      backend_wr_resp_ready     => backend_wr_resp_ready_i,
      
      backend_rd_data_valid     => backend_rd_data_valid_i,
      backend_rd_data_last      => backend_rd_data_last_i,
      backend_rd_data_word      => backend_rd_data_word_i,
      backend_rd_data_rresp     => backend_rd_data_rresp_i,
      backend_rd_data_ready     => backend_rd_data_ready_i,
      
      
      -- ---------------------------------------------------
      -- AXI4 Master Interface Signals.
      
      M_AXI_AWID                => M_AXI_AWID,
      M_AXI_AWADDR              => M_AXI_AWADDR,
      M_AXI_AWLEN               => M_AXI_AWLEN,
      M_AXI_AWSIZE              => M_AXI_AWSIZE,
      M_AXI_AWBURST             => M_AXI_AWBURST,
      M_AXI_AWLOCK              => M_AXI_AWLOCK,
      M_AXI_AWCACHE             => M_AXI_AWCACHE,
      M_AXI_AWPROT              => M_AXI_AWPROT,
      M_AXI_AWQOS               => M_AXI_AWQOS,
      M_AXI_AWVALID             => M_AXI_AWVALID,
      M_AXI_AWREADY             => M_AXI_AWREADY,
      M_AXI_AWUSER              => M_AXI_AWUSER,
      
      M_AXI_WDATA               => M_AXI_WDATA,
      M_AXI_WSTRB               => M_AXI_WSTRB,
      M_AXI_WLAST               => M_AXI_WLAST,
      M_AXI_WVALID              => M_AXI_WVALID,
      M_AXI_WREADY              => M_AXI_WREADY,
      
      M_AXI_BRESP               => M_AXI_BRESP,
      M_AXI_BID                 => M_AXI_BID,
      M_AXI_BVALID              => M_AXI_BVALID,
      M_AXI_BREADY              => M_AXI_BREADY,
      
      M_AXI_ARID                => M_AXI_ARID,
      M_AXI_ARADDR              => M_AXI_ARADDR,
      M_AXI_ARLEN               => M_AXI_ARLEN,
      M_AXI_ARSIZE              => M_AXI_ARSIZE,
      M_AXI_ARBURST             => M_AXI_ARBURST,
      M_AXI_ARLOCK              => M_AXI_ARLOCK,
      M_AXI_ARCACHE             => M_AXI_ARCACHE,
      M_AXI_ARPROT              => M_AXI_ARPROT,
      M_AXI_ARQOS               => M_AXI_ARQOS,
      M_AXI_ARVALID             => M_AXI_ARVALID,
      M_AXI_ARREADY             => M_AXI_ARREADY,
      M_AXI_ARUSER              => M_AXI_ARUSER,
      
      M_AXI_RID                 => M_AXI_RID,
      M_AXI_RDATA               => M_AXI_RDATA,
      M_AXI_RRESP               => M_AXI_RRESP,
      M_AXI_RLAST               => M_AXI_RLAST,
      M_AXI_RVALID              => M_AXI_RVALID,
      M_AXI_RREADY              => M_AXI_RREADY,
    
      
      -- ---------------------------------------------------
      -- Statistics Signals
      
      stat_reset                => stat_reset,
      stat_enable               => stat_enable,
      
      stat_be_rd_latency        => stat_be_rd_latency,
      stat_be_wr_latency        => stat_be_wr_latency,
      stat_be_rd_latency_conf   => stat_be_rd_latency_conf,
      stat_be_wr_latency_conf   => stat_be_wr_latency_conf
    );
  
  backend_wr_resp_bresp <= backend_wr_resp_bresp_i;
  backend_rd_data_word  <= backend_rd_data_word_i;
  backend_rd_data_rresp <= backend_rd_data_rresp_i;
    
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_be_ar_search_depth   <= C_NULL_STAT_POINT;
    stat_be_ar_stall          <= C_NULL_STAT_POINT;
    stat_be_ar_protect_stall  <= C_NULL_STAT_POINT;
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
    
    signal new_access                 : std_logic;
    signal stat_search_depth          : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal stat_stall_cnt             : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal stat_stall                 : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal stat_prot_cnt              : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal stat_prot                  : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    
  begin
  
    Stat_Handle : process (ACLK) is
    begin  -- process Stat_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if stat_reset = '1' then                  -- synchronous reset (active high)
          new_access        <= '0';
          stat_search_depth <= (others=>'0');
          stat_stall_cnt    <= (others=>'0');
          stat_stall        <= (others=>'0');
          stat_prot_cnt     <= (others=>'0');
          stat_prot         <= (others=>'0');
          
        else
          new_access    <= '0';
          
          if( ar_exist = '1' ) then
            stat_stall_cnt  <= std_logic_vector(unsigned(stat_stall_cnt) + 1);
          end if;
          if( ( ar_exist and not protected_read_hit_n ) = '1' ) then
            stat_prot_cnt   <= std_logic_vector(unsigned(stat_prot_cnt) + 1);
          end if;
          if( ar_pop = '1' ) then
            new_access        <= '1';
            stat_search_depth <= std_logic_vector(to_unsigned(search_count, C_STAT_COUNTER_BITS));
            stat_stall        <= stat_stall_cnt;
            stat_prot         <= stat_prot_cnt;
            stat_stall_cnt    <= (others=>'0');
            stat_prot_cnt     <= (others=>'0');
            
          end if;
        end if;
      end if;
    end process Stat_Handle;
    
    Depth_Inst: sc_stat_counter
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
        counter                   => stat_search_depth,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_be_ar_search_depth
      );
      
    Stall_Inst: sc_stat_counter
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
        counter                   => stat_stall,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_be_ar_stall
      );
      
    Protect_Inst: sc_stat_counter
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
        counter                   => stat_prot,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_be_ar_protect_stall
      );
      
  end generate Use_Stat;
  
  
  -----------------------------------------------------------------------------
  -- Debug
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    BACKEND_DEBUG(229 downto   0) <= (others=>'0');
  end generate No_Debug;
  
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_WLEN    : natural := min_of( 8, C_DATA_QUEUE_LENGTH_BITS);
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          BACKEND_DEBUG(229 downto   0) <= (others=>'0');
        else
          -- Default assignment.
          BACKEND_DEBUG(229 downto   0) <= (others=>'0');
          
          -- Read Address: 1+4+8+3+1+1+1 = 19 + 32
          BACKEND_DEBUG(             0) <= read_req_valid;
          BACKEND_DEBUG(  4 downto   1) <= std_logic_vector(to_unsigned(read_req_port, 4));
          BACKEND_DEBUG(C_ADDR_INTERNAL_HI - C_ADDR_INTERNAL_LO + 5 downto   5) 
                                        <= read_req_addr;
          BACKEND_DEBUG( 44 downto  37) <= read_req_len;
          BACKEND_DEBUG( 47 downto  45) <= read_req_size;
          BACKEND_DEBUG(            48) <= read_req_exclusive;
          BACKEND_DEBUG(            49) <= read_req_kind;
          BACKEND_DEBUG(            50) <= read_req_ready_i;
          
          -- Write Address: 1+4+1+8+3+1+1+1 = 20 + 32
          BACKEND_DEBUG(            51) <= write_req_valid;
          BACKEND_DEBUG( 55 downto  52) <= std_logic_vector(to_unsigned(write_req_port, 4));
          BACKEND_DEBUG(            56) <= write_req_internal;
          BACKEND_DEBUG(C_ADDR_INTERNAL_HI - C_ADDR_INTERNAL_LO + 57 downto  57) 
                                        <= write_req_addr;
          BACKEND_DEBUG( 96 downto  89) <= write_req_len;
          BACKEND_DEBUG( 99 downto  97) <= write_req_size;
          BACKEND_DEBUG(           100) <= write_req_exclusive;
          BACKEND_DEBUG(           101) <= write_req_kind;
          BACKEND_DEBUG(           102) <= write_req_ready_i;
          
          -- Write Data: 1+1+1+1+1 = 5 + 4 + 32
          BACKEND_DEBUG(           103) <= write_data_valid;
          BACKEND_DEBUG(           104) <= write_data_last;
          BACKEND_DEBUG(108 downto 105) <= write_data_be(min_of(32, C_EXTERNAL_DATA_WIDTH)/8 - 1 downto 0);
          BACKEND_DEBUG(140 downto 109) <= write_data_word(min_of(32, C_EXTERNAL_DATA_WIDTH) - 1 downto 0);
          BACKEND_DEBUG(           141) <= write_data_ready_i;
          BACKEND_DEBUG(           142) <= w_fifo_almost_full;
          BACKEND_DEBUG(           143) <= w_fifo_full;
          
          -- Write response: 1+4+1+2+1 = 9
          BACKEND_DEBUG(           144) <= backend_wr_resp_valid_i;
          BACKEND_DEBUG(148 downto 145) <= std_logic_vector(to_unsigned(backend_wr_resp_port, 4));
          BACKEND_DEBUG(           149) <= backend_wr_resp_internal;
          BACKEND_DEBUG(151 downto 150) <= backend_wr_resp_bresp_i;
          BACKEND_DEBUG(           152) <= backend_wr_resp_ready_i;
        
          -- Read Response: 1+1+2+1 = 5 + 32
          BACKEND_DEBUG(           153) <= backend_rd_data_valid_i;
          BACKEND_DEBUG(           154) <= backend_rd_data_last_i;
          BACKEND_DEBUG(186 downto 155) <= backend_rd_data_word_i(min_of(32, C_EXTERNAL_DATA_WIDTH) - 1 downto 0);
          BACKEND_DEBUG(188 downto 187) <= backend_rd_data_rresp_i;
          BACKEND_DEBUG(           189) <= backend_rd_data_ready_i;
        
          -- Pending write and reorder: 5+1+1+1+1+1 = 10
          BACKEND_DEBUG(194 downto 190) <= std_logic_vector(to_unsigned(pending_write, Log2(C_MAX_OUTSTANDING_WRITE)));
          BACKEND_DEBUG(           195) <= push_pending_write;
          BACKEND_DEBUG(           196) <= pop_pending_write;
          BACKEND_DEBUG(           197) <= refresh_pending_write;
          BACKEND_DEBUG(           198) <= need_to_stall_write;
          BACKEND_DEBUG(           199) <= no_write_blocking_read;
          
          -- AW FIFO: 1+5+1 = 7
          BACKEND_DEBUG(           200) <= aw_pop;
          BACKEND_DEBUG(204 downto 201) <= aw_read_fifo_addr;
          BACKEND_DEBUG(           205) <= aw_fifo_empty;
        
          -- W FIFO: 1+1+8+1 = 11
          BACKEND_DEBUG(           206) <= w_push;
          BACKEND_DEBUG(           207) <= w_pop;
          BACKEND_DEBUG(208 + C_MY_WLEN - 1 downto 208) <= w_read_fifo_addr(C_MY_WLEN - 1 downto 0);
          BACKEND_DEBUG(           216) <= w_fifo_empty;
          
          -- AR FIFO: 1+1+5+1 = 8
          BACKEND_DEBUG(           217) <= ar_push;
          BACKEND_DEBUG(           218) <= ar_pop;
          BACKEND_DEBUG(222 downto 219) <= ar_read_fifo_addr;
          BACKEND_DEBUG(           223) <= ar_fifo_empty;
          
          -- Placement of Reorder Check: 1+1+4 = 6
          BACKEND_DEBUG(           224) <= allow_read_req_ready;
          BACKEND_DEBUG(           225) <= allow_ar_valid;
          BACKEND_DEBUG(229 downto 226) <= std_logic_vector(to_unsigned(check_port, 4));
          
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
    assert_err(C_ASSERT_AW_QUEUE_ERROR)   <= aw_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_W_QUEUE_ERROR)    <= w_assert  when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_AR_QUEUE_ERROR)   <= ar_assert when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_AW_QUEUE_ERROR) /= '1' 
      report "Backend: Erroneous handling of AW Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_W_QUEUE_ERROR) /= '1' 
      report "Backend: Erroneous handling of W Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_AR_QUEUE_ERROR) /= '1' 
      report "Backend: Erroneous handling of AR Queue , read from empty or push to full."
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
