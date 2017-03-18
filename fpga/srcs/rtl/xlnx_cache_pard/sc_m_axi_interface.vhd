-------------------------------------------------------------------------------
-- sc_m_axi_interface.vhd - Entity and architecture
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
-- Filename:        sc_m_axi_interface.vhd
--
-- Description:     
--                  
-- VHDL-Standard:   VHDL'93
-------------------------------------------------------------------------------
-- Structure:   
--              sc_m_axi_interface.vhd
--
-------------------------------------------------------------------------------
-- Author:          rikardw
--
-- History:
--   rikardw  2011-06-21    First Version
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

entity sc_m_axi_interface is
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
end entity sc_m_axi_interface;


library Unisim;
use Unisim.vcomponents.all;

library work;
use work.system_cache_pkg.all;


architecture IMP of sc_m_axi_interface is

  -----------------------------------------------------------------------------
  -- Description
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Constant declaration
  -----------------------------------------------------------------------------
  
    
  -----------------------------------------------------------------------------
  -- Function declaration
  -----------------------------------------------------------------------------
  
  
  -----------------------------------------------------------------------------
  -- Custom types
  -----------------------------------------------------------------------------
  
  -- Ranges for address parts.
  subtype C_ADDR_VALID_POS            is natural range C_ADDR_VALID_HI downto C_ADDR_VALID_LO;
  subtype C_ADDR_INTERNAL_POS         is natural range C_ADDR_INTERNAL_HI downto C_ADDR_INTERNAL_LO;
  
  
  -----------------------------------------------------------------------------
  -- Component declaration
  -----------------------------------------------------------------------------
  
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
  
  
  -----------------------------------------------------------------------------
  -- Signal declaration
  -----------------------------------------------------------------------------
  
  signal M_AXI_AWVALID_I          : std_logic;
  signal M_AXI_WVALID_I           : std_logic;
  signal M_AXI_WLAST_I            : std_logic;
  signal M_AXI_ARVALID_I          : std_logic;
  signal aw_ready_i               : std_logic;
  signal w_ready_i                : std_logic;
  signal ar_ready_i               : std_logic;
  
    
begin  -- architecture IMP


  -----------------------------------------------------------------------------
  -- Write Address Channel
  -----------------------------------------------------------------------------
  
  aw_ready_i  <= ( M_AXI_AWREADY or not M_AXI_AWVALID_I );
  aw_ready    <= aw_ready_i;
  
  -- Control output register for AW.
  Write_Addr_Request : process (ACLK) is
    variable M_AXI_AWADDR_I           : std_logic_vector(C_MAX_ADDR_WIDTH - 1 downto 0);
  begin  -- process Write_Addr_Request
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET = '1' ) then             -- synchronous reset (active high)
        M_AXI_AWVALID_I                     <= '0';
        M_AXI_AWADDR_I(C_ADDR_VALID_POS)    := C_BASEADDR(C_ADDR_VALID_POS);
        M_AXI_AWADDR_I(C_ADDR_INTERNAL_POS) := (others=>'0');
        M_AXI_AWADDR                        <= fit_vec(M_AXI_AWADDR_I, C_M_AXI_ADDR_WIDTH);
        M_AXI_AWLEN                         <= (others=>'0');
        M_AXI_AWBURST                       <= (others=>'0');
        M_AXI_AWSIZE                        <= std_logic_vector(to_unsigned(log2(C_M_AXI_DATA_WIDTH / 8), 3));
        M_AXI_AWLOCK                        <= '0';
        M_AXI_AWUSER                        <= (others=>'0');
        
      else
        if( M_AXI_AWREADY = '1' ) then
          M_AXI_AWVALID_I                     <= '0';
        end if;
          
        if( aw_ready_i = '1' ) then
          M_AXI_AWVALID_I                     <= aw_valid;
          M_AXI_AWADDR_I(C_ADDR_VALID_POS)    := C_BASEADDR(C_ADDR_VALID_POS);
          M_AXI_AWADDR_I(C_ADDR_INTERNAL_POS) := aw_addr;
          M_AXI_AWADDR                        <= fit_vec(M_AXI_AWADDR_I, C_M_AXI_ADDR_WIDTH);
          M_AXI_AWLEN                         <= aw_len;
          M_AXI_AWSIZE                        <= aw_size;
          M_AXI_AWLOCK                        <= aw_exclusive;
          M_AXI_AWUSER                        <= aw_DSid(C_DSID_WIDTH-1 downto 0);
          if( aw_kind = C_KIND_WRAP ) then
            M_AXI_AWBURST                       <= C_AW_WRAP;
          else
            M_AXI_AWBURST                       <= C_AW_INCR;
          end if;
        end if;
      end if;
    end if;
  end process Write_Addr_Request;
  
  -- Set constant values and assign external signals for AW-Channel.
  M_AXI_AWVALID <= M_AXI_AWVALID_I;
  M_AXI_AWID    <= (others=>'0');
  M_AXI_AWCACHE <= "0011";
  M_AXI_AWPROT  <= (others=>'0');
  M_AXI_AWQOS   <= (others=>'1');
  
  
  -----------------------------------------------------------------------------
  -- Write Channel
  -----------------------------------------------------------------------------
  
  w_ready_i <= ( M_AXI_WREADY or not M_AXI_WVALID_I );
  w_ready   <= w_ready_i;
  
  -- Control output register for W.
  Write_Data_Request : process (ACLK) is
  begin  -- process Write_Data_Request
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET = '1' ) then             -- synchronous reset (active high)
        M_AXI_WVALID_I  <= '0';
        M_AXI_WLAST_I   <= '0';
        M_AXI_WSTRB     <= (others=>'0');
        M_AXI_WDATA     <= (others=>'0');
        
      else
        if( M_AXI_WREADY = '1' ) then
          M_AXI_WVALID_I <= '0';
        end if;
          
        if( w_ready_i = '1' ) then
          M_AXI_WVALID_I  <= w_valid;
          M_AXI_WLAST_I   <= w_last;
          M_AXI_WSTRB     <= w_strb;
          M_AXI_WDATA     <= w_data;
        end if;
      end if;
    end if;
  end process Write_Data_Request;
  
  -- Assign external signal for W-Channel.
  M_AXI_WVALID                    <= M_AXI_WVALID_I;
  M_AXI_WLAST                     <= M_AXI_WLAST_I;
  
  
  -----------------------------------------------------------------------------
  -- Write Response Channel
  -----------------------------------------------------------------------------
  
  -- No custom logic in this level.
  backend_wr_resp_valid <= M_AXI_BVALID;
  backend_wr_resp_bresp <= M_AXI_BRESP;
  M_AXI_BREADY          <= backend_wr_resp_ready;
  
  
  -----------------------------------------------------------------------------
  -- Read Address Channel
  -----------------------------------------------------------------------------
  
  ar_ready_i  <= ( M_AXI_ARREADY or not M_AXI_ARVALID_I );
  ar_ready    <= ar_ready_i;
  
  -- Control output register for AW.
  Read_Addr_Request : process (ACLK) is
    variable M_AXI_ARADDR_I           : std_logic_vector(C_MAX_ADDR_WIDTH - 1 downto 0);
  begin  -- process Read_Addr_Request
    if ACLK'event and ACLK = '1' then     -- rising clock edge
      if( ARESET = '1' ) then             -- synchronous reset (active high)
        M_AXI_ARVALID_I                     <= '0';
        M_AXI_ARADDR_I(C_ADDR_VALID_POS)    := C_BASEADDR(C_ADDR_VALID_POS);
        M_AXI_ARADDR_I(C_ADDR_INTERNAL_POS) := (others=>'0');
        M_AXI_ARADDR                        <= fit_vec(M_AXI_ARADDR_I, C_M_AXI_ADDR_WIDTH);
        M_AXI_ARLEN                         <= (others=>'0');
        M_AXI_ARBURST                       <= (others=>'0');
        M_AXI_ARSIZE                        <= std_logic_vector(to_unsigned(log2(C_M_AXI_DATA_WIDTH / 8), 3));
        M_AXI_ARLOCK                        <= '0';
        M_AXI_ARUSER                        <= (others=>'0');
        
      else
        if( M_AXI_ARREADY = '1' ) then
          M_AXI_ARVALID_I                     <= '0';
        end if;
          
        if( ar_ready_i = '1' ) then
          M_AXI_ARVALID_I                     <= ar_valid;
          M_AXI_ARADDR_I(C_ADDR_VALID_POS)    := C_BASEADDR(C_ADDR_VALID_POS);
          M_AXI_ARADDR_I(C_ADDR_INTERNAL_POS) := ar_addr;
          M_AXI_ARADDR                        <= fit_vec(M_AXI_ARADDR_I, C_M_AXI_ADDR_WIDTH);
          M_AXI_ARLEN                         <= ar_len;
          M_AXI_ARSIZE                        <= ar_size;
          M_AXI_ARLOCK                        <= ar_exclusive;
          M_AXI_ARUSER                        <= ar_DSid(C_DSID_WIDTH-1 downto 0);
          if( ar_kind = C_KIND_WRAP ) then
            M_AXI_ARBURST                       <= C_AR_WRAP;
          else
            M_AXI_ARBURST                       <= C_AR_INCR;
          end if;
        end if;
      end if;
    end if;
  end process Read_Addr_Request;
  
  -- Set constant values and assign external signals for AW-Channel.
  M_AXI_ARVALID <= M_AXI_ARVALID_I;
  M_AXI_ARID    <= (others=>'0');
  M_AXI_ARCACHE <= "0011";
  M_AXI_ARPROT  <= (others=>'0');
  M_AXI_ARQOS   <= (others=>'1');
  
  
  -----------------------------------------------------------------------------
  -- Read Channel
  -----------------------------------------------------------------------------
    
  -- No custom logic in this level.
  backend_rd_data_valid <= M_AXI_RVALID;
  backend_rd_data_last  <= M_AXI_RLAST;
  backend_rd_data_word  <= M_AXI_RDATA;
  backend_rd_data_rresp <= M_AXI_RRESP;
  M_AXI_RREADY          <= backend_rd_data_ready;
  
  
  -----------------------------------------------------------------------------
  -- Statistics
  -----------------------------------------------------------------------------
  
  No_Stat: if( not C_USE_STATISTICS ) generate
  begin
    stat_be_rd_latency  <= C_NULL_STAT_POINT;
    stat_be_wr_latency  <= C_NULL_STAT_POINT;
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
          ar_start  <= M_AXI_ARVALID_I  and not ar_done;
          ar_ack    <= M_AXI_ARVALID_I  and M_AXI_ARREADY;
          rd_valid  <= M_AXI_RVALID     and backend_rd_data_ready;
          rd_last   <= M_AXI_RVALID     and backend_rd_data_ready and M_AXI_RLAST;
          
          aw_start  <= M_AXI_AWVALID_I  and not aw_done;
          aw_ack    <= M_AXI_AWVALID_I  and M_AXI_AWREADY;
          wr_valid  <= M_AXI_WVALID_I   and M_AXI_WREADY;
          wr_last   <= M_AXI_WVALID_I   and M_AXI_WREADY and M_AXI_WLAST_I;
          wr_resp   <= M_AXI_BVALID     and backend_wr_resp_ready;
          
          if( M_AXI_ARREADY = '1' ) then
            ar_done   <= '0';
          elsif( M_AXI_ARVALID_I = '1' ) then
            ar_done   <= '1';
          end if;
          
          if( M_AXI_AWREADY = '1' ) then
            aw_done   <= '0';
          elsif( M_AXI_AWVALID_I = '1' ) then
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
        C_STAT_LATENCY_RD_DEPTH   => C_STAT_MEM_LAT_RD_DEPTH,
        C_STAT_LATENCY_WR_DEPTH   => C_STAT_MEM_LAT_WR_DEPTH,
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
    
        stat_rd_latency           => stat_be_rd_latency,
        stat_wr_latency           => stat_be_wr_latency,
        stat_rd_latency_conf      => stat_be_rd_latency_conf,
        stat_wr_latency_conf      => stat_be_wr_latency_conf
      );
    
  end generate Use_Stat;
  
  
end architecture IMP;






    
    
    
    
