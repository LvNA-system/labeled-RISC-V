-------------------------------------------------------------------------------
-- sc_arbiter.vhd - Entity and architecture
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
-- Filename:        sc_arbiter.vhd
--
-- Description:     
--
-- VHDL-Standard:   VHDL'93/02
-------------------------------------------------------------------------------
-- Structure:   
--              sc_arbiter.vhd
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


entity sc_arbiter is
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
    C_ID_WIDTH                : natural range  1 to   32      :=  1;
    C_ENABLE_CTRL             : natural range  0 to    1      :=  0;
    C_ENABLE_EX_MON           : natural range  0 to    1      :=  0;
    C_NUM_OPTIMIZED_PORTS     : natural range  0 to   32      :=  1;
    C_NUM_GENERIC_PORTS       : natural range  0 to   32      :=  0;
    C_NUM_FAST_PORTS          : natural range  0 to   32      :=  0;
    C_NUM_PORTS               : natural range  1 to   32      :=  1
  );
  port (
    -- ---------------------------------------------------
    -- Common signals.
    
    ACLK                      : in  std_logic;
    ARESET                    : in  std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (All request).
    
    opt_port_piperun          : in  std_logic;
    arbiter_piperun           : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Write request).
    
    wr_port_access            : in  WRITE_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
    wr_port_id                : in  std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
    wr_port_ready             : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Internal Interface Signals (Read request).
    
    rd_port_access            : in  READ_PORTS_TYPE(C_NUM_PORTS - 1 downto 0);
    rd_port_id                : in  std_logic_vector(C_NUM_PORTS * C_ID_WIDTH - 1 downto 0);
    rd_port_ready             : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Arbiter signals (to Access).
    
    arb_access                : out ARBITRATION_TYPE;
    arb_access_id             : out std_logic_vector(C_ID_WIDTH - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Control If Transactions.
    
    ctrl_init_done            : in  std_logic;
    ctrl_access               : in  ARBITRATION_TYPE;
    ctrl_ready                : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Port signals.
    
    arbiter_bp_push           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    arbiter_bp_early          : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    wr_port_inbound           : out std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Access signals.
    
    access_piperun            : in  std_logic;
    access_write_priority     : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    access_other_write_prio   : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Port signals (to Arbiter).
    
    read_data_hit_fit         : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Lookup signals (to Arbiter).
    
    lookup_read_done          : in  std_logic_vector(C_NUM_PORTS - 1 downto 0);
    
    
    -- ---------------------------------------------------
    -- Statistics Signals
    
    stat_reset                      : in  std_logic;
    stat_enable                     : in  std_logic;
    
    stat_arb_valid                  : out STAT_POINT_TYPE;    -- Time valid transactions exist
    stat_arb_concurrent_accesses    : out STAT_POINT_TYPE;    -- Transactions available each time command is arbitrated
    stat_arb_opt_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_OPTIMIZED_PORTS - 1 downto 0);    
    stat_arb_gen_read_blocked       : out STAT_POINT_VECTOR_TYPE(C_NUM_GENERIC_PORTS - 1 downto 0);    
                                                              -- Time valid read is blocked by prohibit
    
    
    -- ---------------------------------------------------
    -- Assert Signals
    
    assert_error              : out std_logic;
    
    
    -- ---------------------------------------------------
    -- Debug signals.
    
    ARBITER_DEBUG             : out std_logic_vector(255 downto 0)
  );
end entity sc_arbiter;

library IEEE;
use IEEE.numeric_std.all;

architecture IMP of sc_arbiter is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  -- 
  -- Arbitrate between available input transactions, with a Round-Robin 
  -- scheme.
  -- Write can be prioritized when needed. 
  -- Read a prohibited on the same port until data is returned, because of the
  -- Hit/Miss delay difference issue.
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
  
  subtype C_PORT_POS                  is natural range C_NUM_PORTS - 1 downto 0;
  subtype PORT_TYPE                   is std_logic_vector(C_PORT_POS);
  
  
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  function arbitrate(token : PORT_TYPE; rp : READ_PORTS_TYPE; wp : WRITE_PORTS_TYPE; rack, wack, rprohib, wprio : PORT_TYPE) return ARBITRATION_TYPE is
    variable arb    : ARBITRATION_TYPE := C_NULL_ARBITRATION;
    variable found  : boolean          := false;
  begin
    for i in 0 to C_NUM_PORTS - 1 loop
      if ( wprio(i) = '1' and wp(i).Valid = '1' and wack(i) = '0' ) then
        found       := true;
        arb.Valid   := '1';
        arb.Wr      := '1';
        arb.Port_Num:= std_logic_vector(to_unsigned(i, C_MAX_NUM_PORT_WIDTH));
        
      elsif( rp(i).Valid = '1' and rprohib(i) = '0' and ( arb.Valid = '0' or ( token(I) = '1' and not found ) ) ) then
        arb.Valid   := '1';
        arb.Wr      := '0';
        arb.Port_Num:= std_logic_vector(to_unsigned(i, C_MAX_NUM_PORT_WIDTH));
        
      elsif( wp(i).Valid = '1' and wack(i) = '0' and ( arb.Valid = '0' or ( token(I) = '1' and not found ) ) ) then
        arb.Valid   := '1';
        arb.Wr      := '1';
        arb.Port_Num:= std_logic_vector(to_unsigned(i, C_MAX_NUM_PORT_WIDTH));
        
      end if;
    end loop;
    
    return arb;
  end function arbitrate;
  
  function set_fast_port return PORT_TYPE is
    variable tmp    : PORT_TYPE := (others=>'0');
  begin
    if( C_NUM_FAST_PORTS > 0 ) then
      tmp(C_NUM_PORTS - 1 downto C_NUM_PORTS - C_NUM_FAST_PORTS)  := (others=>'1');
    end if;
    
    return tmp;
  end function set_fast_port;
  
  
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
  constant C_WRITE_ENABLED            : PORT_TYPE := (others=>'1');  
  constant C_READ_ENABLED             : PORT_TYPE := (others=>'1');  
  constant C_FAST_PORT                : PORT_TYPE := set_fast_port;  
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
  component carry_and is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE
      );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
  end component carry_and;
  
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
  
  component carry_or is
    generic (
      C_KEEP    : boolean:= false;
      C_TARGET : TARGET_FAMILY_TYPE
      );
    port (
      Carry_IN  : in  std_logic;
      A         : in  std_logic;
      Carry_OUT : out std_logic);
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
  signal prohibit_rst               : boolean;
--  attribute dont_touch              : string;
--  attribute dont_touch              of Reset_Inst     : label is "true";
  
  -- Guide Vivado Synthesis to handle control set as intended.
--  attribute direct_reset            : string;
--  attribute direct_reset            of prohibit_rst   : signal is "true";
  
  -- ----------------------------------------
  -- Piperun 
  
  signal arbiter_piperun_i          : std_logic;
  
  
  -- ----------------------------------------
  -- Detect Transactions
  
  signal wr_port_blocked            : PORT_TYPE;
  signal wr_port_exist              : PORT_TYPE;
  signal rd_port_exist              : PORT_TYPE;
  signal trans_port_exist           : PORT_TYPE;
  signal port_idle                  : PORT_TYPE;
  signal port_prio_taken            : PORT_TYPE;
  signal port_token_taken           : PORT_TYPE;
  signal port_arbiter_taken         : PORT_TYPE;
  signal port_other_idle            : PORT_TYPE;
  signal port_allow_ready_pre       : PORT_TYPE;
  signal port_allow_ready           : PORT_TYPE;
  signal port_ready_blocked_by_init : PORT_TYPE;
  signal port_ready_no_init         : PORT_TYPE;
  signal port_ready                 : PORT_TYPE;
  signal port_ready_i               : PORT_TYPE;
  signal wr_port_ready_cmb          : PORT_TYPE;
  signal wr_port_ready_cmb2         : PORT_TYPE;
  signal wr_port_ready_q            : PORT_TYPE;
  signal wr_port_ready_block        : PORT_TYPE;
  signal rd_port_ready_cmb          : PORT_TYPE;
  signal rd_port_ready_cmb2         : PORT_TYPE;
  signal rd_port_ready_q            : PORT_TYPE;
  signal rd_port_ready_block        : PORT_TYPE;
  signal wr_port_bufferable         : PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Arbitration
  
  signal arb_token_new              : PORT_TYPE;
  signal arb_token                  : PORT_TYPE;
  signal arb_token_cnt              : C_PORT_POS;
  signal port_ready_num             : C_PORT_POS;
  signal all_ready                  : std_logic;
  signal arbiter_piperun_and_valid  : std_logic;
  signal arb_access_cmb             : ARBITRATION_TYPE;
  signal arb_access_i               : ARBITRATION_TYPE;
  signal wr_port_ready_i            : PORT_TYPE;
  signal rd_port_ready_i            : PORT_TYPE;
  signal arb_want_multi_part        : PORT_TYPE;
  signal rd_port_multi_part         : PORT_TYPE;
  signal any_port_forbid            : PORT_TYPE;
  signal dvm_2nd_part               : std_logic;
  signal ctrl_ready_i               : std_logic;
  
  
  -- ----------------------------------------
  -- Prohibit Handle
  
  signal arb_prohibit_read          : PORT_TYPE;
  signal arb_prohibit_quick         : PORT_TYPE;
  
  
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
  -- Piperun 
  -----------------------------------------------------------------------------
  
  -- The Piperun signal takes a detour through the Front End in order to branch out
  -- the Generic Piperun signals, but the status of the piperun is not altered.
  -- It returns as "opt_port_piperun" and the carry chain can continue with the
  -- ready termination to generate "arbiter_piperun_and_valid".
-- TODO: Could it be safe to propagate "arbiter_piperun_and_valid" to the Front End?
  arbiter_piperun   <= arbiter_piperun_i;
  arbiter_piperun_i <= access_piperun;
  
  -- Any ready.
  all_ready         <= reduce_or(port_ready);
  
  -- Generate valid for token.
  FE_Arb_PR_Valid_Inst1: carry_and
    generic map(
      C_TARGET => C_TARGET
    )
    port map(
      Carry_IN  => opt_port_piperun,
      A         => all_ready,
      Carry_OUT => arbiter_piperun_and_valid
    );
  
  
  -----------------------------------------------------------------------------
  -- Detect Transactions
  -----------------------------------------------------------------------------
  
  Gen_Port_Ready: for I in 0 to C_NUM_PORTS - 1 generate
    signal idle_carry : std_logic_vector(C_NUM_PORTS*2 downto 0);
  begin
    wr_port_bufferable(I) <= wr_port_access(I).Bufferable and 
                             ( not ( wr_port_access(I).Exclusive and int_to_std(C_ENABLE_EX_MON) ) or 
                               not   wr_port_access(I).Exclusive );
    
    -- Forward that write is comming.
    wr_port_inbound(I)    <= wr_port_access(I).Valid;
    
    -- Detect if read is blocking write.
    wr_port_blocked(I)    <= ( rd_port_access(I).Valid and not access_write_priority(I) ) or
                             rd_port_multi_part(I) or any_port_forbid(I);
    
    -- Detect active write transaction.
    wr_port_exist(I)      <= wr_port_access(I).Valid and not wr_port_blocked(I) and not wr_port_ready_block(I) 
                                when C_WRITE_ENABLED(I) = '1' else
                             '0';
    
    -- Detect active read transaction.
    rd_port_exist(I)      <= rd_port_access(I).Valid and ( rd_port_multi_part(I) or not access_write_priority(I) ) and 
                             not rd_port_ready_block(I) and not any_port_forbid(I)
                                when C_READ_ENABLED(I) = '1' else
                             '0';
    
    -- Detect any active transaction.
    trans_port_exist(I)   <= wr_port_exist(I) or rd_port_exist(I);
    
    -- Detect if port is idle.
    port_idle(I)          <= ( not wr_port_exist(I) ) and ( not rd_port_exist(I) );
    
    -- Detect priority taken.
    port_prio_taken(I)    <= ( wr_port_access(I).Valid and access_write_priority(I) ) or
                             ( rd_port_access(I).Valid and rd_port_multi_part(I) );
    
    -- Detect token taken.
    port_token_taken(I)   <= ( wr_port_access(I).Valid or rd_port_access(I).Valid ) and arb_token(I) and 
                             not any_port_forbid(I);
    
    -- Detect arbiter taken.
    port_arbiter_taken(I) <= port_prio_taken(I) or port_token_taken(I);
    
    
    -- Search if lower priority transactions are idle
    idle_carry(idle_carry'right) <= '1';
    Detect_Idle: for J in 0 to C_NUM_PORTS - 1 generate
    begin
      Lower_Prio: if J < I generate
      begin
        LP_Rd_Inst: carry_and_n
          generic map(
            C_TARGET => C_TARGET
          )
          port map(
            Carry_IN  => idle_carry(J*2),
            A_N       => rd_port_exist(J),
            Carry_OUT => idle_carry(J*2+1)
          );
        LP_Wr_Inst: carry_and_n
          generic map(
            C_TARGET => C_TARGET
          )
          port map(
            Carry_IN  => idle_carry(J*2+1),
            A_N       => wr_port_exist(J),
            Carry_OUT => idle_carry(J*2+2)
          );
      end generate Lower_Prio;
      
      Current_Port: if J = I generate
      begin
        idle_carry(J*2+1) <= idle_carry(J*2);
        idle_carry(J*2+2) <= idle_carry(J*2+1);
      end generate Current_Port;
      
      Taken_Block: if J > I generate
      begin
        TB_Inst: carry_and_n
          generic map(
            C_TARGET => C_TARGET
          )
          port map(
            Carry_IN  => idle_carry(J*2),
            A_N       => port_arbiter_taken(J),
            Carry_OUT => idle_carry(J*2+1)
          );
        idle_carry(J*2+2) <= idle_carry(J*2+1);
      end generate Taken_Block;
    end generate Detect_Idle;
    
    -- No one else want or are being arbitrated.
    port_other_idle(I)  <= idle_carry(idle_carry'left);
    
    -- Add if current has the token.
    Token_Inst: carry_or
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_other_idle(I),
        A         => arb_token(I),
        Carry_OUT => port_allow_ready_pre(I)
      );
    Prio_Inst: carry_or
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_allow_ready_pre(I),
        A         => access_write_priority(I),
        Carry_OUT => port_allow_ready(I)
      );
    
    -- Detect if port is used.
    Use_Inst: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_allow_ready(I),
        A         => trans_port_exist(I),
        Carry_OUT => port_ready_no_init(I)
      );
    
    -- Detect if initialization has completed.
    port_ready_blocked_by_init(I) <= ctrl_init_done and not ARESET and not ARESET_I;
    Init_Inst: carry_and
      generic map(
        C_TARGET => C_TARGET
      )
      port map(
        Carry_IN  => port_ready_no_init(I),
        A         => port_ready_blocked_by_init(I),
        Carry_OUT => port_ready(I)
      );
    
    -- Set port type dependent ready forwading and blocking.
    Use_Fast_Port: if( C_FAST_PORT(I) = '1' ) generate
    begin
      -- Transaction type dependent ready.
      Wr_Inst: carry_latch_and
        generic map(
          C_TARGET  => C_TARGET,
          C_NUM_PAD => 0,
          C_INV_C   => false
        )
        port map(
          Carry_IN  => port_ready(I),
          A         => wr_port_exist(I),
          O         => wr_port_ready_cmb(I),
          Carry_OUT => port_ready_i(I)
        );
        
      Rd_Inst: carry_and
        generic map(
          C_TARGET => C_TARGET
        )
        port map(
          Carry_IN  => port_ready_i(I),
          A         => rd_port_exist(I),
          Carry_OUT => rd_port_ready_cmb(I)
        );
        
      
      -- Assign output.
      rd_port_ready_i(I)      <= rd_port_ready_cmb(I);
      wr_port_ready_i(I)      <= wr_port_ready_cmb(I);
      
      -- Unused signals.
      rd_port_ready_q(I)      <= '0';
      wr_port_ready_q(I)      <= '0';
      
      -- Generate blocking.
      rd_port_ready_block(I)  <= arb_prohibit_read(I);
      wr_port_ready_block(I)  <= '0';
      
      -- Unused bit for Fast.
      wr_port_ready_cmb2(I) <= '0';
      rd_port_ready_cmb2(I) <= '0';
    end generate Use_Fast_Port;
    
    Use_Slow_Port: if( C_FAST_PORT(I) /= '1' ) generate
    begin
      -- Transaction type dependent ready.
      Rd_Inst: carry_latch_and
        generic map(
          C_TARGET  => C_TARGET,
          C_NUM_PAD => 0,
          C_INV_C   => false
        )
        port map(
          Carry_IN  => port_ready(I),
          A         => rd_port_exist(I),
          O         => rd_port_ready_cmb(I),
          Carry_OUT => port_ready_i(I)
        );
        
      Wr_Inst: carry_and
        generic map(
          C_TARGET => C_TARGET
        )
        port map(
          Carry_IN  => port_ready_i(I),
          A         => wr_port_exist(I),
          Carry_OUT => wr_port_ready_cmb(I)
        );
      
      -- Generate the combinatorial input for the FFs.
      Ready_Gen: process (rd_port_ready_cmb, wr_port_ready_cmb, arbiter_piperun_i) is
      begin  -- process Ready_Gen
        wr_port_ready_cmb2(I) <= '0';
        rd_port_ready_cmb2(I) <= '0';
        if( ( wr_port_ready_cmb(I) = '1' ) and ( arbiter_piperun_i = '1' ) ) then
          wr_port_ready_cmb2(I) <= '1';
        end if;
        if( ( rd_port_ready_cmb(I) = '1' ) and ( arbiter_piperun_i = '1' ) ) then
          rd_port_ready_cmb2(I) <= '1';
        end if;
      end process Ready_Gen;
      
      
      -- Clock port ready.
      Rd_FF_Inst : FDR
        port map (
          Q  => rd_port_ready_q(I),           -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => rd_port_ready_cmb2(I),        -- [in  std_logic]
          R  => ARESET_I                      -- [in  std_logic]
        );
      Wr_FF_Inst : FDR
        port map (
          Q  => wr_port_ready_q(I),           -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => wr_port_ready_cmb2(I),        -- [in  std_logic]
          R  => ARESET_I                      -- [in  std_logic]
        );
      
      -- Assign output.
      rd_port_ready_i(I)  <= rd_port_ready_q(I);
      wr_port_ready_i(I)  <= wr_port_ready_q(I);
      
      -- Generate blocking.
      rd_port_ready_block(I)  <= arb_prohibit_read(I);
      wr_port_ready_block(I)  <= wr_port_ready_q(I);
    end generate Use_Slow_Port;
  end generate Gen_Port_Ready;
  
  
  -----------------------------------------------------------------------------
  -- Predecode
  -----------------------------------------------------------------------------
  
  Pre_Decode: process (rd_port_access, rd_port_ready_cmb, rd_port_multi_part, dvm_2nd_part) is
  begin  -- process Pre_Decode
    arb_want_multi_part <= (others=>'0');
    
    for i in 0 to C_NUM_PORTS - 1 loop
      if( ( i < C_NUM_OPTIMIZED_PORTS ) and 
          ( rd_port_access(i).Snoop = C_ARSNOOP_DVMMessage ) ) then
        arb_want_multi_part(i)  <= rd_port_access(i).Addr(C_DVM_MORE_POS) and not dvm_2nd_part;
      end if;
    end loop;
  end process Pre_Decode;
  
  
  -----------------------------------------------------------------------------
  -- Arbitration
  -----------------------------------------------------------------------------
  
  Port_Gen: process (port_ready) is
  begin  -- process Port_Gen
    port_ready_num  <= 0;
    for i in 0 to C_NUM_PORTS - 1 loop
      if( port_ready(i) = '1' ) then
        port_ready_num <= i;
      end if;
    end loop; 
  end process Port_Gen;
  
  Arbitration_Handle : process (ACLK) is
  begin  -- process Arbitration_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        arb_access_i            <= C_NULL_ARBITRATION;
        arb_access_id           <= (others=>'0');
        
      else
        if( arbiter_piperun_i = '1' ) then
          -- Common arbitration part.
          arb_access_i.Valid      <= reduce_or(port_ready);
          arb_access_i.Wr         <= reduce_or(wr_port_ready_cmb);
          arb_access_i.Port_Num   <= std_logic_vector(to_unsigned(port_ready_num, C_MAX_NUM_PORT_WIDTH));
          
          -- Type dependent.
          if( reduce_or(wr_port_ready_cmb) = '1' ) then
            -- Write transaction.
            arb_access_id             <= wr_port_id((port_ready_num + 1) * C_ID_WIDTH - 1 downto 
                                                    (port_ready_num + 0) * C_ID_WIDTH);
            arb_access_i.Addr         <= wr_port_access(port_ready_num).Addr;
            arb_access_i.Len          <= wr_port_access(port_ready_num).Len;
            arb_access_i.Kind         <= wr_port_access(port_ready_num).Kind;
            arb_access_i.Exclusive    <= wr_port_access(port_ready_num).Exclusive;
            arb_access_i.Allocate     <= wr_port_access(port_ready_num).Allocate;
            arb_access_i.Bufferable   <= wr_port_bufferable(port_ready_num);
            arb_access_i.Evict        <= '0';
            arb_access_i.Ignore_Data  <= '0';
            arb_access_i.Force_Hit    <= '0';
            arb_access_i.Internal_Cmd <= '0';
            arb_access_i.Prot         <= wr_port_access(port_ready_num).Prot;
            arb_access_i.Snoop        <= (others=>'0');
            arb_access_i.Snoop(C_AXI_AWSNOOP_POS)
                                      <= wr_port_access(port_ready_num).Snoop;
            arb_access_i.Barrier      <= wr_port_access(port_ready_num).Barrier;
            arb_access_i.Domain       <= wr_port_access(port_ready_num).Domain;
            arb_access_i.Size         <= wr_port_access(port_ready_num).Size;
            arb_access_i.DSid         <= wr_port_access(port_ready_num).DSid;
            
          elsif( reduce_or(rd_port_ready_cmb) = '1' ) then
            -- Read transaction.
            arb_access_id             <= rd_port_id((port_ready_num + 1) * C_ID_WIDTH - 1 downto 
                                                    (port_ready_num + 0) * C_ID_WIDTH);
            arb_access_i.Addr         <= rd_port_access(port_ready_num).Addr;
            arb_access_i.Len          <= rd_port_access(port_ready_num).Len;
            arb_access_i.Kind         <= rd_port_access(port_ready_num).Kind;
            arb_access_i.Exclusive    <= rd_port_access(port_ready_num).Exclusive;
            arb_access_i.Allocate     <= rd_port_access(port_ready_num).Allocate;
            arb_access_i.Bufferable   <= rd_port_access(port_ready_num).Bufferable;
            arb_access_i.Evict        <= '0';
            arb_access_i.Ignore_Data  <= '0';
            arb_access_i.Force_Hit    <= '0';
            arb_access_i.Internal_Cmd <= '0';
            arb_access_i.Prot         <= rd_port_access(port_ready_num).Prot;
            arb_access_i.Snoop        <= rd_port_access(port_ready_num).Snoop;
            arb_access_i.Barrier      <= rd_port_access(port_ready_num).Barrier;
            arb_access_i.Domain       <= rd_port_access(port_ready_num).Domain;
            arb_access_i.Size         <= rd_port_access(port_ready_num).Size;
            arb_access_i.DSid         <= rd_port_access(port_ready_num).DSid;
            
          else
            -- Ctrl port transaction.
            arb_access_i              <= ctrl_access;
            arb_access_i.Valid        <= ctrl_access.Valid and not ctrl_ready_i;
            
            ctrl_ready_i              <= ctrl_access.Valid and not ctrl_ready_i;
            
          end if;
          
        else
          ctrl_ready_i              <= '0';
          
        end if;
      end if;
    end if;
  end process Arbitration_Handle;
  
  Token_Handle : process (ACLK) is
  begin  -- process Arbitration_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        dvm_2nd_part    <= '0';
        arb_token_cnt   <= 0;
        
      elsif( arbiter_piperun_and_valid = '1' ) then
        -- Track message that needs to be kept together.
        dvm_2nd_part    <= rd_port_ready_cmb(port_ready_num) and arb_want_multi_part(port_ready_num);
        
        -- Only move token once per message.
        if( dvm_2nd_part = '0' ) then
          if( arb_token_cnt = C_NUM_PORTS - 1 ) then
            arb_token_cnt   <= 0;
          else
            arb_token_cnt   <= arb_token_cnt + 1;
          end if;
        end if;
        
      end if;
    end if;
  end process Token_Handle;
  
  Single_Port: if( C_NUM_PORTS = 1 ) generate
  begin
    arb_token           <= (others=>'1');
    rd_port_multi_part  <= (others=>'0');
    any_port_forbid     <= (others=>'0');
    
  end generate Single_Port;
  
  Multi_Port: if( C_NUM_PORTS > 1 ) generate
    signal rd_port_multi_part_cmb     : PORT_TYPE;
    signal any_port_forbid_cmb        : PORT_TYPE;
  begin
    Multi_Part_Handle : process (rd_port_ready_cmb, arb_want_multi_part, port_ready_num) is
    begin  -- process Multi_Part_Handle
      if( reduce_or(rd_port_ready_cmb) = '1' ) then
        any_port_forbid_cmb                     <= (others=>arb_want_multi_part(port_ready_num));
        any_port_forbid_cmb(port_ready_num)     <= '0';
        rd_port_multi_part_cmb                  <= (others=>'0');
        rd_port_multi_part_cmb(port_ready_num)  <= arb_want_multi_part(port_ready_num);
        
      else
        rd_port_multi_part_cmb                  <= (others=>'0');
        any_port_forbid_cmb                     <= (others=>'0');
        
      end if;
    end process Multi_Part_Handle;
    
    Token_Handle : process (dvm_2nd_part, arb_token) is
    begin  -- process Token_Handle
      if( dvm_2nd_part = '0' ) then
        arb_token_new <= arb_token(arb_token'left - 1 downto arb_token'right) & arb_token(arb_token'left);
      else
        arb_token_new <= arb_token;
      end if;
      
    end process Token_Handle;
    
    Gen_Token: for I in 0 to C_NUM_PORTS - 1 generate
    begin
      First_Inst: if( I = 0 ) generate
      begin
        FF_Inst : FDSE
          port map (
            Q  => arb_token(I),                 -- [out std_logic]
            C  => ACLK,                         -- [in  std_logic]
            D  => arb_token_new(I),             -- [in  std_logic]
            CE => arbiter_piperun_and_valid,    -- [in  std_logic]
            S  => ARESET_I                      -- [in  std_logic]
          );
      end generate First_Inst;
      Other_Inst: if( I /= 0 ) generate
      begin
        FF_Inst : FDRE
          port map (
            Q  => arb_token(I),                 -- [out std_logic]
            C  => ACLK,                         -- [in  std_logic]
            D  => arb_token_new(I),             -- [in  std_logic]
            CE => arbiter_piperun_and_valid,    -- [in  std_logic]
            R  => ARESET_I                      -- [in  std_logic]
          );
      end generate Other_Inst;
      
      Multi_FF_Inst : FDRE
        port map (
          Q  => rd_port_multi_part(I),        -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => rd_port_multi_part_cmb(I),    -- [in  std_logic]
          CE => arbiter_piperun_and_valid,    -- [in  std_logic]
          R  => ARESET_I                      -- [in  std_logic]
        );
      Forbid_FF_Inst : FDRE
        port map (
          Q  => any_port_forbid(I),           -- [out std_logic]
          C  => ACLK,                         -- [in  std_logic]
          D  => any_port_forbid_cmb(I),       -- [in  std_logic]
          CE => arbiter_piperun_and_valid,    -- [in  std_logic]
          R  => ARESET_I                      -- [in  std_logic]
        );
    end generate Gen_Token;
  end generate Multi_Port;
  
  -- Assign external.
  arb_access    <= arb_access_i;
  wr_port_ready <= wr_port_ready_i;
  rd_port_ready <= rd_port_ready_i;
  ctrl_ready    <= ctrl_ready_i;
  
  Arbitration_Early_Handle : process (ACLK) is
  begin  -- process Arbitration_Early_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      if ARESET_I = '1' then                      -- synchronous reset (active high)
        arbiter_bp_push   <= (others=>'0');
        arbiter_bp_early  <= (others=>'0');
        
      else
        -- Default assignment.
        arbiter_bp_push   <= (others=>'0');
        
        if( arbiter_piperun_i = '1' ) then
          arbiter_bp_push   <= wr_port_ready_cmb;
        end if;
        
        for i in 0 to C_NUM_PORTS - 1 loop
          arbiter_bp_early(I)  <= wr_port_bufferable(I) or 
                                  wr_port_access(I).Allocate;
        end loop; 
        
      end if;
    end if;
  end process Arbitration_Early_Handle;
  
  
  -----------------------------------------------------------------------------
  -- Prohibit Handle
  -----------------------------------------------------------------------------
  
  prohibit_rst  <= ARESET_I = '1';
  
  Prohibit_Handle : process (ACLK) is
  begin  -- process Prohibit_Handle
    if ACLK'event and ACLK = '1' then           -- rising clock edge
      for I in 0 to C_NUM_PORTS - 1 loop
        if prohibit_rst then                      -- synchronous reset (active high)
          arb_prohibit_read     <= (others=>'0');
          arb_prohibit_quick    <= (others=>'0');
        
        else
          if( ( rd_port_ready_cmb(I) = '1' ) and ( arbiter_piperun_i = '1' ) and 
              ( read_data_hit_fit(I) = '0' or C_FAST_PORT(I) = '0' ) ) then
            arb_prohibit_read(I)  <= '1';
            arb_prohibit_quick(I) <= read_data_hit_fit(I) and not C_FAST_PORT(I);
            
          elsif( ( lookup_read_done(I) = '1' ) or ( arb_prohibit_quick(I) = '1' ) )then
            arb_prohibit_read(I)  <= '0';
            arb_prohibit_quick(I) <= '0';
            
          end if;
        end if;
      end loop;
    end if;
  end process Prohibit_Handle;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_arb_valid                <= C_NULL_STAT_POINT;
    stat_arb_concurrent_accesses  <= C_NULL_STAT_POINT;
    stat_arb_opt_read_blocked     <= (others=>C_NULL_STAT_POINT);
    stat_arb_gen_read_blocked     <= (others=>C_NULL_STAT_POINT);
  end generate No_Stat;
  
  Use_Stat: if( C_USE_STATISTICS ) generate
  
    signal valid_count                : natural range 0 to 2 * C_NUM_PORTS;
    signal new_arbitation             : std_logic;
    signal concurrent_valid           : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal count_time                 : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    signal time_valid                 : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
    
  begin
    Count_Active_Ports: process (wr_port_access, rd_port_access) is
      variable tmp  : natural range 0 to 2 * C_NUM_PORTS;
    begin  -- process Count_Active_Ports
      tmp := 0;
      for i in 0 to C_NUM_PORTS - 1 loop
        if( wr_port_access(i).Valid = '1' ) then
          tmp := tmp + 1;
        end if;
        if( rd_port_access(i).Valid = '1' ) then
          tmp := tmp + 1;
        end if;
      end loop; 
      valid_count <= tmp;
    end process Count_Active_Ports;
    
    Stat_Handle : process (ACLK) is
    begin  -- process Stat_Handle
      if ACLK'event and ACLK = '1' then           -- rising clock edge
        if stat_reset = '1' then                  -- synchronous reset (active high)
          new_arbitation    <= '0';
          concurrent_valid  <= (others=>'0');
          count_time        <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
          time_valid        <= (others=>'0');
          
        else
          new_arbitation    <= '0';
          
          if( arb_access_i.Valid = '1' ) then
            count_time        <= std_logic_vector(unsigned(count_time) + 1);
          end if;
          if( arbiter_piperun_i = '1' ) then
            new_arbitation    <= reduce_or(port_ready);
            concurrent_valid  <= std_logic_vector(to_unsigned(valid_count, C_STAT_COUNTER_BITS));
            count_time        <= std_logic_vector(to_unsigned(1, C_STAT_COUNTER_BITS));
            time_valid        <= count_time;
            
          end if;
        end if;
      end if;
    end process Stat_Handle;
    
    Trans_Inst: sc_stat_counter
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
        
        update                    => new_arbitation,
        counter                   => time_valid,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_arb_valid
      );
      
    Segment_Inst: sc_stat_counter
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
        
        update                    => new_arbitation,
        counter                   => concurrent_valid,
        
        
        -- ---------------------------------------------------
        -- Statistics Signals
        
        stat_enable               => stat_enable,
        
        stat_data                 => stat_arb_concurrent_accesses
      );
      
    Gen_Prohibit: for I in 0 to C_NUM_PORTS - 1 generate
      signal port_tick            : std_logic;
      signal port_done            : std_logic;
      signal port_arbitation      : std_logic;
      signal read_block_valid     : std_logic;
      signal prohibit_cnt         : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
      signal prohibit_stat        : std_logic_vector(C_STAT_COUNTER_BITS - 1 downto 0);
      signal stat_read_block      : STAT_POINT_TYPE;
    begin
      -- Detector.
      Stat_Handle : process (ACLK) is
      begin  -- process Stat_Handle
        if ACLK'event and ACLK = '1' then           -- rising clock edge
          if stat_reset = '1' then                  -- synchronous reset (active high)
            port_tick         <= '0';
            port_done         <= '0';
            port_arbitation   <= '0';
            read_block_valid  <= '0';
            prohibit_cnt      <= (others=>'0');
            prohibit_stat     <= (others=>'0');
            
          else
            port_tick         <= arbiter_piperun_i and rd_port_access(I).Valid and arb_prohibit_read(I);
            port_done         <= arbiter_piperun_i and rd_port_access(I).Valid and rd_port_ready_cmb(I);
            port_arbitation   <= port_done and read_block_valid;
            
            if( port_tick = '1' ) then
              read_block_valid  <= '1';
              prohibit_cnt      <= std_logic_vector(unsigned(prohibit_cnt) + 1);
            end if;
            if( port_done = '1' ) then
              read_block_valid  <= '0';
              prohibit_cnt      <= (others=>'0');
              prohibit_stat     <= prohibit_cnt;
            end if;
          end if;
        end if;
      end process Stat_Handle;
      
      -- Stat counter.
      Segment_Inst: sc_stat_counter
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
          
          update                    => port_arbitation,
          counter                   => prohibit_stat,
          
          
          -- ---------------------------------------------------
          -- Statistics Signals
          
          stat_enable               => stat_enable,
          
          stat_data                 => stat_read_block
        );
      
      -- Assign depending on category.
      Use_Opt: if( I < C_NUM_OPTIMIZED_PORTS ) generate
      begin
        stat_arb_opt_read_blocked(I)                          <= stat_read_block;
      end generate Use_Opt;
      Use_Gen: if( I >= C_NUM_OPTIMIZED_PORTS ) generate
      begin
        stat_arb_gen_read_blocked(I - C_NUM_OPTIMIZED_PORTS)  <= stat_read_block;
      end generate Use_Gen;
    end generate Gen_Prohibit;
    
  end generate Use_Stat;
  
  -----------------------------------------------------------------------------
  -- Debug 
  -----------------------------------------------------------------------------
  No_Debug: if( not C_USE_DEBUG ) generate
  begin
    ARBITER_DEBUG <= (others=>'0');
  end generate No_Debug;
  
  Use_Debug: if( C_USE_DEBUG ) generate
    constant C_MY_PORTS       : natural := 9;
    constant C_MY_PORTS_WIDTH : natural := 4;
    constant C_PART1_LEN      : natural:= 4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 7;
  begin
    Debug_Handle : process (ACLK) is 
    begin  
      if ACLK'event and ACLK = '1' then     -- rising clock edge
        if (ARESET_I = '1') then              -- synchronous reset (active true)
          ARBITER_DEBUG <= (others=>'0');
        else
          -- Default assignment.
          ARBITER_DEBUG <= (others=>'0');
          
          -- Add probes for one-hot encoded information: 7 * 9 = 63
          ARBITER_DEBUG( 0 * C_MY_PORTS + C_NUM_PORTS - 1 downto  0 * C_MY_PORTS) <= wr_port_ready_i;
          ARBITER_DEBUG( 1 * C_MY_PORTS + C_NUM_PORTS - 1 downto  1 * C_MY_PORTS) <= rd_port_ready_i;
          ARBITER_DEBUG( 2 * C_MY_PORTS + C_NUM_PORTS - 1 downto  2 * C_MY_PORTS) <= arb_prohibit_read;
          ARBITER_DEBUG( 3 * C_MY_PORTS + C_NUM_PORTS - 1 downto  3 * C_MY_PORTS) <= access_write_priority;
          for I in 0 to C_NUM_PORTS - 1 loop
            ARBITER_DEBUG( 4 * C_MY_PORTS + I)                                     <= wr_port_access(I).Valid;
            ARBITER_DEBUG( 5 * C_MY_PORTS + I)                                     <= rd_port_access(I).Valid;
          end loop;
          ARBITER_DEBUG( 6 * C_MY_PORTS + C_NUM_PORTS - 1 downto  6 * C_MY_PORTS) <= arb_token;
          
          -- Add probes for binary encoded information: 4 * 4 = 16
          ARBITER_DEBUG(1 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS - 1 downto 
                        0 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS)                 
                                          <= std_logic_vector(to_unsigned(arb_token_cnt, C_MY_PORTS_WIDTH));
          ARBITER_DEBUG(1 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + C_NUM_PORTS - 1 downto 
                        1 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS)                 
                                          <= lookup_read_done(C_NUM_PORTS - 1 downto 0);
          ARBITER_DEBUG(3 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS - 1 downto 
                        2 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS)                 
                                          <= (others=>'0');
          ARBITER_DEBUG(3 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + C_NUM_PORTS - 1 downto 
                        3 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS)                 
                                          <= read_data_hit_fit(C_NUM_PORTS - 1 downto 0);
          
          -- Add probes for one bit signals: 1+1+1+1+1+1+1 = 7
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 0)             <= access_piperun;
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 1)             <= arbiter_piperun_and_valid;
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 2)             <= dvm_2nd_part;
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 3)             <= '0';
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 4)             <= '0';
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 5)             <= '0';
          ARBITER_DEBUG(4 * C_MY_PORTS_WIDTH + 7 * C_MY_PORTS + 6)             <= '0';
          
          ARBITER_DEBUG(C_PART1_LEN + C_NUM_PORTS - 1 downto C_PART1_LEN)           <= port_ready;
          -- Add probes for records.
--          ARBITER_DEBUG(1 * C_ARB_TYPE_LEN + C_PART1_LEN - 1 downto 
--                        0 * C_ARB_TYPE_LEN + C_PART1_LEN)                           <= To_StdVec(arb_access_cmb);
--          ARBITER_DEBUG(1 * C_ARB_TYPE_LEN + 160 - 1 downto 
--                        0 * C_ARB_TYPE_LEN + 160)                                   <= To_StdVec(arb_access_i) and 
--                                                                                       (C_ARB_TYPE_LEN - 1 downto 0=>arb_access_i.Valid);
                        
--          ARBITER_DEBUG(221 + 0 * C_MAX_PORTS + C_NUM_PORTS - 1 downto 221 + 0 * C_MAX_PORTS) <= arb_want_multi_part;
--          ARBITER_DEBUG(221 + 1 * C_MAX_PORTS + C_NUM_PORTS - 1 downto 221 + 1 * C_MAX_PORTS) <= rd_port_multi_part;
--          ARBITER_DEBUG(221 + 2 * C_MAX_PORTS + C_NUM_PORTS - 1 downto 221 + 2 * C_MAX_PORTS) <= any_port_forbid;
          
        end if;
      end if;
    end process Debug_Handle;
  end generate Use_Debug;
  
  
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
