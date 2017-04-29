-------------------------------------------------------------------------------
-- sc_s_axi_w_channel.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_w_channel.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_w_channel.vhd
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


entity sc_s_axi_w_channel is
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
end entity sc_s_axi_w_channel;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_w_channel is

  
  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_WIP_QUEUE_ERROR           : natural :=  0;
  constant C_ASSERT_W_QUEUE_ERROR             : natural :=  1;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  2;
  
  
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  subtype BE_TYPE                     is std_logic_vector(C_S_AXI_DATA_WIDTH/8 - 1 downto 0);
  subtype DATA_TYPE                   is std_logic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);
  
  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  -- Subtypes of the address from all points of view.
  
  -- Address related.
  subtype C_ADDR_BYTE_POS             is natural range C_ADDR_BYTE_HI       downto C_ADDR_BYTE_LO;
  
  -- Subtypes for address parts.
  subtype ADDR_BYTE_TYPE              is std_logic_vector(C_ADDR_BYTE_POS);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  type W_TYPE is record
    BE                : BE_TYPE;
    Data              : DATA_TYPE;
  end record W_TYPE;
  
  type WIP_TYPE is record
    Last              : std_logic;
    Failed            : std_logic;
    Offset            : ADDR_BYTE_TYPE;
    Stp_Bits          : ADDR_BYTE_TYPE;
    Use_Bits          : ADDR_BYTE_TYPE;
    Len               : AXI_LENGTH_TYPE;
  end record WIP_TYPE;
  
  -- Empty data structures.
  constant C_NULL_W                   : W_TYPE   := (BE=>(others=>'0'), Data=>(others=>'0'));
  constant C_NULL_WIP                 : WIP_TYPE := (Last=>'1', Failed=>'0', Offset=>(others=>'0'), 
                                                     Stp_Bits=>(others=>'0'), Use_Bits=>(others=>'0'), 
                                                     Len=>(others=>'0'));
  
  -- Types for information queue storage.
  type W_FIFO_MEM_TYPE            is array(QUEUE_ADDR_POS)      of W_TYPE;
  type WIP_FIFO_MEM_TYPE          is array(QUEUE_ADDR_POS)      of WIP_TYPE;
  
  
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
  -- Handle Transaction Information Queue
  
  signal wip_push                 : std_logic;
  signal wip_pop                  : std_logic;
  signal wip_refresh_reg          : std_logic;
  signal wip_exist                : std_logic;
  signal wip_read_fifo_addr       : QUEUE_ADDR_TYPE := (others=>'1');
  signal wip_fifo_mem             : WIP_FIFO_MEM_TYPE := (others=>C_NULL_WIP);
  signal wip_fifo_almost_full     : std_logic;
  signal wip_fifo_full            : std_logic;
  signal wip_last                 : std_logic;
  signal wip_failed               : std_logic;
  signal wip_offset               : ADDR_BYTE_TYPE;
  signal wip_stp_bits             : ADDR_BYTE_TYPE;
  signal wip_use_bits             : ADDR_BYTE_TYPE;
  signal wip_len                  : AXI_LENGTH_TYPE;
  signal wip_assert               : std_logic;
  signal wr_ready_i               : std_logic;
  
  
  -- ----------------------------------------
  -- Handle Length and Sequence Control
  
  signal first_wr_beat            : std_logic;
  signal first_wr_word            : std_logic;
  signal write_offset_cnt         : ADDR_BYTE_TYPE;
  signal len                      : AXI_LENGTH_TYPE;
  signal len_cnt                  : AXI_LENGTH_TYPE;
  signal last                     : std_logic;
  
  
  -- ----------------------------------------
  -- Write Queue Handling
  
  signal w_push                   : std_logic;
  signal w_push_safe              : std_logic;
  signal w_pop_part               : std_logic;
  signal w_pop                    : std_logic;
  signal w_pop_safe               : std_logic;
  signal w_fifo_full              : std_logic;
  signal w_fifo_empty             : std_logic;
  signal w_read_fifo_addr         : QUEUE_ADDR_TYPE;
  signal w_fifo_mem               : W_FIFO_MEM_TYPE; -- := (others=>C_NULL_W);
  signal w_valid                  : std_logic;
  signal w_be                     : BE_TYPE;
  signal w_data                   : DATA_TYPE;
  signal w_ready                  : std_logic;
  signal w_fail_ready             : std_logic;
  signal w_assert                 : std_logic;
  
  
  -- ----------------------------------------
  -- Write Complete tracking
  
  signal wc_push        : std_logic;
  signal wc_pop         : std_logic;
  signal wc_fifo_empty  : std_logic;
  
  
  -- ----------------------------------------
  -- Control W-Channel
  
  signal wr_port_data_valid_cmb   : std_logic;
  signal wr_port_data_valid_i     : std_logic;
  signal wr_port_data_be_i        : std_logic_vector(C_CACHE_DATA_WIDTH/8 - 1 downto 0);
  signal wr_port_data_word_i      : std_logic_vector(C_CACHE_DATA_WIDTH - 1 downto 0);
  signal write_next_offset        : ADDR_BYTE_TYPE;
  signal write_offset             : ADDR_BYTE_TYPE;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1             : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
begin  -- architecture IMP

  
  -----------------------------------------------------------------------------
  -- Handle Transaction Information Queue
  --
  -- Write Information Port queue keeps track of all information that relates 
  -- to the transaction:
  --  * Last    - If this is the last segment of the original transaction.
  --  * Len     - Number of beats for this segment.
  --  * Failed  - If this is a failed transaction that has to be terminated
  --              instead of forwarded.
  --  * Size    - (optional) Size of transaction used for WSTRB generation
  --              when expanding data bus.
  --  * Offset  - (optional) Offset for first beat in a transaction that is 
  --              scaled up.
  -----------------------------------------------------------------------------
  
  -- Control signals for write information queue.
  wip_push        <= wr_valid and not wip_fifo_full;
--  wip_pop         <= w_pop_safe and last;
  WC_And_Inst4: carry_compare_const
    generic map(
      C_TARGET  => C_TARGET,
      C_SIGNALS => 3,
      C_SIZE    => 8,
      B_Vec     => (C_AXI_LENGTH_POS=>'0')
    )
    port map(
      Carry_In  => w_pop_safe,                -- [in  std_logic]
      A_Vec     => len,                       -- [in  std_logic_vector]
      Carry_Out => wip_pop                    -- [out std_logic]
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
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => wip_push,
      queue_pop                 => wip_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => wip_refresh_reg,
      
      queue_almost_full         => wip_fifo_almost_full,
      queue_full                => wip_fifo_full,
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
    
  -- Handle memory for WIP Channel FIFO.
  FIFO_WIP_Memory : process (ACLK) is
  begin  -- process FIFO_WIP_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( wip_push = '1') then
        -- Insert new item.
        wip_fifo_mem(0).Last      <= wr_last;
        wip_fifo_mem(0).Failed    <= wr_failed;
        wip_fifo_mem(0).Len       <= wr_len;
        
        if( C_CACHE_DATA_WIDTH /= C_S_AXI_DATA_WIDTH ) then
          wip_fifo_mem(0).Offset    <= wr_offset;
          wip_fifo_mem(0).Stp_Bits  <= wr_stp;
          wip_fifo_mem(0).Use_Bits  <= wr_use;
        else
          wip_fifo_mem(0).Offset    <= (others=>'0');
          wip_fifo_mem(0).Stp_Bits  <= (others=>'0');
          wip_fifo_mem(0).Use_Bits  <= (others=>'0');
        end if;
        
        -- Shift FIFO contents.
        wip_fifo_mem(wip_fifo_mem'left downto 1) <= wip_fifo_mem(wip_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_WIP_Memory;
  
  -- Store WIP in register for good timing.
  WIP_Data_Registers : process (ACLK) is
  begin  -- process WIP_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        wip_last      <= C_NULL_WIP.Last;
        wip_failed    <= C_NULL_WIP.Failed;
        wip_offset    <= C_NULL_WIP.Offset;
        wip_stp_bits  <= C_NULL_WIP.Stp_Bits;
        wip_use_bits  <= C_NULL_WIP.Use_Bits;
        wip_len       <= C_NULL_WIP.Len;
      elsif( wip_refresh_reg = '1' ) then
        wip_last      <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Last;
        wip_failed    <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Failed;
        wip_offset    <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Offset;
        wip_stp_bits  <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Stp_Bits;
        wip_use_bits  <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Use_Bits;
        wip_len       <= wip_fifo_mem(to_integer(unsigned(wip_read_fifo_addr))).Len;
      end if;
    end if;
  end process WIP_Data_Registers;
  
  -- Acknowledge new transaction information.
  wr_ready_i            <= ( not wip_fifo_full ) and ( not wip_fifo_almost_full );
  wr_ready              <= wr_ready_i;
  
  
  -----------------------------------------------------------------------------
  -- Handle Length and Sequence Control
  -- 
  -- Keep track of a segments of an burst of data. For a split burst new 
  -- WLAST has to be generated. Instead of merging original last with inserted
  -- ones, all WLAST are generated from the same mechanism.
  -----------------------------------------------------------------------------
  
  -- Select current length.
  len                   <= wip_len    when ( first_wr_word = '1' )          else len_cnt;
  
  -- Detect last word for this part.
  last                  <= '1'        when ( to_integer(unsigned(len))) = 0 else '0';
  
  -- Handle next offset that should be used.
  Write_Segment_Part_Handler : process (ACLK) is
  begin  -- process Write_Segment_Part_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        first_wr_beat     <= '1';
        first_wr_word     <= '1';
      else
        if ( wip_pop = '1' ) then
          first_wr_beat     <= wip_last;
          first_wr_word     <= '1';
        elsif ( w_pop_safe ) = '1' then
          first_wr_beat     <= '0';
          first_wr_word     <= '0';
        end if;
      end if;
    end if;
  end process Write_Segment_Part_Handler;
  
  Write_Segment_Cnt_Handler : process (ACLK) is
  begin  -- process Write_Segment_Cnt_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        write_offset_cnt  <= (others=>'0');
        len_cnt           <= (others=>'0');
      elsif ( w_pop_safe ) = '1' then
        write_offset_cnt  <= write_next_offset;
        len_cnt           <= std_logic_vector(unsigned(len) - 1);
      end if;
    end if;
  end process Write_Segment_Cnt_Handler;
  
  
  -----------------------------------------------------------------------------
  -- Write Queue Handling
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
      ARESET                    => ARESET,
  
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
        w_fifo_mem(0).BE    <= S_AXI_WSTRB;
        w_fifo_mem(0).Data  <= S_AXI_WDATA;
        
        -- Shift FIFO contents.
        w_fifo_mem(w_fifo_mem'left downto 1) <= w_fifo_mem(w_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_W_Memory;
  
  -- Forward ready.
  S_AXI_WREADY  <= not w_fifo_full;
  
  -- Rename signals.
  w_valid       <= not w_fifo_empty;
  w_be          <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).BE;
  w_data        <= w_fifo_mem(to_integer(unsigned(w_read_fifo_addr))).Data;
  
  
  -----------------------------------------------------------------------------
  -- Write Complete tracking
  -- 
  -- Queue level is always same or lower than BIP and that will prevent 
  -- this  queue from overrunning.
  -----------------------------------------------------------------------------
  
  wc_push <= wip_pop;
  wc_pop  <= wc_ready;
  
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
    
  wc_valid  <= not wc_fifo_empty;
  
  
  -----------------------------------------------------------------------------
  -- Control W-Channel
  -- 
  -- Assign internal interface signals with data from the port. The data is 
  -- mirrored if the internal data is wider than external.
  -- New wider WSTRB is generated, if neccesary, for the new wider internal 
  -- data stream.
  -- 
  -- Failed (exclusive) data is terminated and never forwarded to the rest
  -- of the cache. The transaction information has already been stoped in AW.
  -----------------------------------------------------------------------------
  
  -- Simply forward Write data if internal width is same as interface.
  No_Write_Mirror: if( C_CACHE_DATA_WIDTH = C_S_AXI_DATA_WIDTH ) generate
  begin
    -- Just let data pass through untouched.
    wr_port_data_be_i   <= w_be;
    wr_port_data_word_i <= w_data;
    
    -- Not used for same width.
    write_next_offset <= (others=>'0');
    
  end generate No_Write_Mirror;
  
  -- Mirror Write data if internal width larger than interface.
  Use_Write_Mirror: if( C_CACHE_DATA_WIDTH /= C_S_AXI_DATA_WIDTH ) generate
    constant C_RATIO                : natural := C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH;
    subtype C_RATIO_POS             is natural range 0 to C_RATIO - 1;
    subtype RATIO_TYPE              is std_logic_vector(C_RATIO_POS);
    constant C_RATIO_BITS           : natural := Log2(C_RATIO);
    subtype C_RATIO_BITS_POS        is natural range C_ADDR_BYTE_HI downto C_ADDR_BYTE_HI - C_RATIO_BITS + 1;
    subtype RATIO_BITS_TYPE         is std_logic_vector(C_RATIO_BITS_POS);
    
  begin
    
    -- Select current offset.
    write_offset          <= wip_offset when ( first_wr_beat = '1' )          else write_offset_cnt;
    
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
    
    Gen_Write_Mirror: for I in 0 to C_CACHE_DATA_WIDTH / C_S_AXI_DATA_WIDTH - 1 generate
    begin
      -- Generate mirrored data and steer byte enable.
      wr_port_data_be_i((I+1) * C_S_AXI_DATA_WIDTH / 8 - 1 downto I * C_S_AXI_DATA_WIDTH / 8) 
                          <= w_be when ( to_integer(unsigned(write_offset(C_RATIO_BITS_POS))) = I ) 
                             else (others=>'0');
      wr_port_data_word_i((I+1) * C_S_AXI_DATA_WIDTH - 1 downto I * C_S_AXI_DATA_WIDTH)       <= w_data;
      
    end generate Gen_Write_Mirror;
  end generate Use_Write_Mirror;
  
  Write_Data_Output_Valid : process (w_pop, w_valid, wip_exist, wip_failed, wr_port_data_ready, wr_port_data_valid_i) is
  begin  -- process Write_Data_Output_Valid
    if( w_pop = '1' ) then
      wr_port_data_valid_cmb  <= w_valid and wip_exist and not wip_failed;
    elsif( wr_port_data_ready = '1' ) then
      wr_port_data_valid_cmb  <= '0';
    else
      wr_port_data_valid_cmb  <= wr_port_data_valid_i;
    end if;
  end process Write_Data_Output_Valid;
  
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
      D         => wr_port_data_valid_cmb,
      Q         => wr_port_data_valid_i
    );
    
  Write_Data_Output : process (ACLK) is
  begin  -- process Write_Data_Output
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        wr_port_data_last     <= '1';
        wr_port_data_be       <= (others=>'0');
        wr_port_data_word     <= (others=>'0');
      elsif( w_pop = '1' ) then
        wr_port_data_last     <= last;
        wr_port_data_be       <= wr_port_data_be_i;
        wr_port_data_word     <= wr_port_data_word_i;
      end if;
    end if;
  end process Write_Data_Output;
  
  -- Assign output.
  wr_port_data_valid  <= wr_port_data_valid_i;
  
  -- Forward ready.
--  w_ready           <= wr_port_data_ready or 
--                       ( wip_failed and wip_exist );
  WC_And_Inst1: carry_and 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => wip_failed,
      A         => wip_exist,
      Carry_OUT => w_fail_ready
    );
  WC_Or_Inst1: carry_or 
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => w_fail_ready,
      A         => wr_port_data_ready,
      Carry_OUT => w_ready
    );
  
  
  -----------------------------------------------------------------------------
  -- Synchronization
  --
  -- Syncronize with B-Channel that is waiting for the Write Data stream to be 
  -- terminated. Protocol requires all W data to be acknowledged before 
  -- B Response.
  -----------------------------------------------------------------------------
  
  Pipeline_Failed : process (ACLK) is 
  begin  
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active true)
        write_fail_completed  <= '0';
      else
        write_fail_completed  <= wip_pop and wip_failed;
        
      end if;
    end if;
  end process Pipeline_Failed;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    IF_DEBUG  <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET = '1') then              -- synchronous reset (active true)
          IF_DEBUG  <= (others=>'0');
        else
          -- Default assignment.
          IF_DEBUG      <= (others=>'0');
          
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
    assert_err(C_ASSERT_WIP_QUEUE_ERROR)  <= wip_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_W_QUEUE_ERROR)    <= w_assert   when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_WIP_QUEUE_ERROR) /= '1' 
      report "AXI W Channel: Erroneous handling of WIP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_W_QUEUE_ERROR) /= '1' 
      report "AXI W Channel: Erroneous handling of W Queue, read from empty or push to full."
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






    
    
    
    
