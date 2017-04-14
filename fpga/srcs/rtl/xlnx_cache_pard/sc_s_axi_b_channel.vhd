-------------------------------------------------------------------------------
-- sc_s_axi_b_channel.vhd - Entity and architecture
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
-- Filename:        sc_s_axi_b_channel.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_s_axi_b_channel.vhd
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

entity sc_s_axi_b_channel is
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
    C_S_AXI_ID_WIDTH          : natural                       :=  1
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
    
    write_fail_completed      : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write response).
    
    access_bp_push            : in  std_logic;
    access_bp_early           : in  std_logic;
    
    wc_valid                  : in  std_logic;
    wc_ready                  : out std_logic;
    
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
end entity sc_s_axi_b_channel;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;
use work.system_cache_queue_pkg.all;


architecture IMP of sc_s_axi_b_channel is
  

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration (Assertions)
  -----------------------------------------------------------------------------
  
  -- Define offset to each assertion.
  constant C_ASSERT_BIP_QUEUE_ERROR           : natural :=  0;
  constant C_ASSERT_BP_QUEUE_ERROR            : natural :=  1;
  
  -- Total number of assertions.
  constant C_ASSERT_BITS                      : natural :=  2;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  

    
    
  -----------------------------------------------------------------------------
  -- Custom types (AXI)
  -----------------------------------------------------------------------------
  
  -- Types for AXI and port related signals (use S0 as reference, all has to be equal).
  subtype ID_TYPE                     is std_logic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------

  
  -----------------------------------------------------------------------------
  -- Custom types (Address)
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration (Calculated or depending)
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  type BP_TYPE is record
    Early             : std_logic;
  end record BP_TYPE;
  
  type BIP_TYPE is record
    Failed            : std_logic;
    Last              : std_logic;
    ID                : ID_TYPE;
  end record BIP_TYPE;
  
  -- Empty data structures.
  constant C_NULL_BP                  : BP_TYPE  := (Early=>'0');
  constant C_NULL_BIP                 : BIP_TYPE := (Failed=>'0', Last=>'0', ID=>(others=>'0'));
  
  -- Types for information queue storage.
  type BP_FIFO_MEM_TYPE           is array(QUEUE_ADDR_POS)      of BP_TYPE;
  type BIP_FIFO_MEM_TYPE          is array(QUEUE_ADDR_POS)      of BIP_TYPE;
  
  
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
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Write Information Queue Handling
  
  signal bip_push                 : std_logic;
  signal bip_pop                  : std_logic;
  signal bip_read_fifo_addr       : QUEUE_ADDR_TYPE:= (others=>'1');
  signal bip_fifo_mem             : BIP_FIFO_MEM_TYPE; -- := (others=>C_NULL_BIP);
  signal bip_fifo_almost_full     : std_logic;
  signal bip_fifo_full            : std_logic;
  signal bip_fifo_empty           : std_logic;
  signal bip_last                 : std_logic;
  signal bip_failed               : std_logic;
  signal bip_id                   : std_logic_vector(C_S_AXI_ID_WIDTH - 1   downto 0);
  signal bip_assert               : std_logic;
  
  
  -- ----------------------------------------
  -- Write Response Handling
  
  signal bp_pop                   : std_logic;
  signal bp_refresh_reg           : std_logic;
  signal bp_exist                 : std_logic;
  signal bp_valid_normal          : std_logic;
  signal bp_valid_failed          : std_logic;
  signal bp_valid                 : std_logic;
  signal bp_ready                 : std_logic;
  signal bp_read_fifo_addr        : QUEUE_ADDR_TYPE:= (others=>'1');
  signal bp_fifo_mem              : BP_FIFO_MEM_TYPE; -- := (others=>C_NULL_BP);
  signal bp_fifo_empty            : std_logic;
  signal bp_early                 : std_logic;
  signal bp_assert                : std_logic;
  
  
  -- ----------------------------------------
  -- Write Response Handling
  
  signal S_AXI_BVALID_I           : std_logic;
  signal S_AXI_BRESP_I            : std_logic_vector(1 downto 0);
  signal first_bresp              : std_logic;
  
  
  -- ----------------------------------------
  -- Assertion signals.
  
  signal assert_err                 : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  signal assert_err_1               : std_logic_vector(C_ASSERT_BITS-1 downto 0);
  
  
begin  -- architecture IMP
  
  
  -----------------------------------------------------------------------------
  -- Write Information Queue Handling
  -- 
  -- Push all control information needed into the queue to be able to do the 
  -- port specific modifications of the returned response.
  -----------------------------------------------------------------------------
  
  -- Control signals for read data queue.
  bip_push    <= write_req_valid and not bip_fifo_full;
  bip_pop     <= bp_ready and bp_valid;
  
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
      ARESET                    => ARESET,
  
      -- ---------------------------------------------------
      -- Queue Counter Interface
      
      queue_push                => bip_push,
      queue_pop                 => bip_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => open,
      
      queue_almost_full         => bip_fifo_almost_full,
      queue_full                => bip_fifo_full,
      queue_almost_empty        => open,
      queue_empty               => bip_fifo_empty,
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
    
  -- Handle memory for BIP Channel FIFO.
  FIFO_BIP_Memory : process (ACLK) is
  begin  -- process FIFO_BIP_Memory
    if (ACLK'event and ACLK = '1') then    -- rising clock edge
      if ( bip_push = '1') then
        -- Insert new item.
        bip_fifo_mem(0).ID      <= write_req_ID;
        bip_fifo_mem(0).Last    <= write_req_last;
        bip_fifo_mem(0).Failed  <= write_req_failed;
        
        -- Shift FIFO contents.
        bip_fifo_mem(bip_fifo_mem'left downto 1) <= bip_fifo_mem(bip_fifo_mem'left-1 downto 0);
      end if;
    end if;
  end process FIFO_BIP_Memory;
  
  -- Acknowledge new transaction information.
  write_req_ready       <= ( not bip_fifo_full ) and ( not bip_fifo_almost_full );
  
  -- Extract data.
  bip_last              <= bip_fifo_mem(to_integer(unsigned(bip_read_fifo_addr))).Last;
  bip_failed            <= bip_fifo_mem(to_integer(unsigned(bip_read_fifo_addr))).Failed;
  bip_id                <= bip_fifo_mem(to_integer(unsigned(bip_read_fifo_addr))).ID;
  
  -- Pull write complete when poping BIP.
  wc_ready              <= bip_pop;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Port Handling
  -- 
  -- Store Write Response Hit/Miss information with ID in a queue.
  -- 
  -- Hit are forwarded directly where as Miss has to wait for a BRESP from the 
  -- external memory.
  -----------------------------------------------------------------------------
  
  -- Generate control signals.
  bp_pop            <= bip_pop and not bip_failed;
  
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
      
      queue_push                => access_bp_push,
      queue_pop                 => bp_pop,
      queue_push_qualifier      => '0',
      queue_pop_qualifier       => '0',
      queue_refresh_reg         => bp_refresh_reg,
      
      queue_almost_full         => open,
      queue_full                => open,
      queue_almost_empty        => open,
      queue_empty               => bp_fifo_empty,
      queue_exist               => bp_exist,
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

  -- Store BP in register for good timing.
  BP_Data_Registers : process (ACLK) is
  begin  -- process BP_Data_Registers
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        bp_early  <= C_NULL_BP.Early;
      elsif( bp_refresh_reg = '1' ) then
        -- Mux response on per port basis.
        bp_early  <= bp_fifo_mem(to_integer(unsigned(bp_read_fifo_addr))).Early;
      end if;
    end if;
  end process BP_Data_Registers;
  
  -- Generate valid for both hit and miss.
  bp_valid_normal       <= ( ( ( bp_early and wc_valid ) or (update_ext_bresp_valid and not bp_early) ) and bp_exist );
  bp_valid_failed       <= ( bip_failed and write_fail_completed and not bip_fifo_empty );
  bp_valid              <= bp_valid_normal or bp_valid_failed;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Handling
  -- 
  -- Clock and hold the BRESP until it is acknowledged from AXI.
  -----------------------------------------------------------------------------
  
  Write_Response_Handler : process (ACLK) is
  begin  -- process Write_Response_Handler
    if (ACLK'event and ACLK = '1') then   -- rising clock edge
      if (ARESET = '1') then              -- synchronous reset (active high)
        first_bresp     <= '1';
        S_AXI_BVALID_I  <= '0';
        S_AXI_BRESP_I   <= (others=>'0');
        S_AXI_BID       <= (others=>'0');
      else
        -- Turn off when the data is acknowledged.
        if( bp_ready = '1' ) then
          S_AXI_BVALID_I  <= '0';
        end if;
        
        -- Start new when information is available.
        if( ( bp_valid and bp_ready ) = '1' ) then
          first_bresp     <= bip_last;
          S_AXI_BVALID_I  <= bip_last;
          S_AXI_BID       <= bip_id;
          if( first_bresp = '1' ) then
            if( bip_failed = '1' ) then
              S_AXI_BRESP_I   <= C_BRESP_OKAY;
            elsif( bp_early = '1' ) then
              S_AXI_BRESP_I   <= C_BRESP_OKAY;
            else
              S_AXI_BRESP_I   <= update_ext_bresp;
            end if;
          elsif( bp_early = '0' ) then
            if( unsigned(update_ext_bresp) > unsigned(S_AXI_BRESP_I) ) then
              S_AXI_BRESP_I   <= update_ext_bresp;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process Write_Response_Handler;
  
  -- Generate internal ready signal.
  bp_ready                <= S_AXI_BREADY or not S_AXI_BVALID_I;
  
  -- Return ready when able to use miss BRESP.
  update_ext_bresp_ready  <= bp_ready and not bp_early and bp_exist;
  
  -- Rename the internal valid signal.
  S_AXI_BVALID            <= S_AXI_BVALID_I;
  S_AXI_BRESP             <= S_AXI_BRESP_I;
  
  
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
    assert_err(C_ASSERT_BIP_QUEUE_ERROR)  <= bip_assert when C_USE_ASSERTIONS else '0';
    
    -- Detect condition
    assert_err(C_ASSERT_BP_QUEUE_ERROR)   <= bp_assert  when C_USE_ASSERTIONS else '0';
    
    -- pragma translate_off
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BIP_QUEUE_ERROR) /= '1' 
      report "AXI B Channel: Erroneous handling of BIP Queue, read from empty or push to full."
        severity error;
    
    -- Report issues.
    assert assert_err_1(C_ASSERT_BP_QUEUE_ERROR) /= '1' 
      report "AXI B Channel: Erroneous handling of BP Queue, read from empty or push to full."
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


