-------------------------------------------------------------------------------
-- system_cache_pkg -  package
-------------------------------------------------------------------------------
--
-- (c) Copyright 2001-2014 Xilinx, Inc. All rights reserved.
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
-- Filename:        system_cache_pkg.vhd
-- Version:         v1.00a
-- Description:     A package with type definition and help functions for
--                  different implementations of the MicroBlaze family
--
-------------------------------------------------------------------------------
-- Structure:   
--              system_cache_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          rikardw
-- History:
--  rikardw         2011-05-30      -- First version
--  stefana         2012-12-14      -- Removed legacy families
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "*_clk"
--      reset signals:                          "rst", "*_rst", "reset"
--      generics:                               All uppercase, starting with: "C_"
--      constants:                              All uppercase, not starting with: "C_"
--      state machine next state:               "*_next_state"
--      state machine current state:            "*_curr_state"
--      pipelined signals:                      "*_d#"
--      counter signals:                        "*_cnt_*" , "*_counter_*", "*_count_*"
--      internal version of output port:        "*_i"
--      ports:                                  Names begin with uppercase
--      component instantiations:               "<ENTITY>_I#|<FUNC>" , "<ENTITY>_I"
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


package system_cache_pkg is

  -----------------------------------------------------------------------------
  -- Common Constants & Types
  -----------------------------------------------------------------------------
  
  -- FPGA architectures
  type TARGET_FAMILY_TYPE is (ARTIX7,
                              KINTEX7,
                              VIRTEX7,
                              ZYNQ,
                              VIRTEXU,
                              KINTEXU,
                              ZYNQUE,
                              VIRTEXUM,
                              KINTEXUM,
                              RTL
                             );
  
  -- FPGA resources.
  type TARGET_PROPERTY_TYPE is (LATCH_AS_LOGIC, DUAL_DFF, BRAM_WITH_BYTE_ENABLE,
                                BRAM_36K, BRAM_16K_WE, DSP, DSP48_V4, DSP48_A, DSP48_E);
  
  -- Create a Boolean array type
  type boolean_array is array (natural range <>) of boolean;

  -- Create an integer array type
  type integer_array is array (natural range <>) of integer;

  
  -----------------------------------------------------------------------------
  -- Common Functions
  -----------------------------------------------------------------------------
  
  -- Log2 function returns the number of bits required to encode x choices
  function log2(x : natural) return integer;
  
  -- Convert to std_logic.
  function int_to_std(v : integer) return std_logic;
  function int_to_std(v, n : integer) return std_logic_vector;
  
  -- Handle vector.
  function fit_vec(v : std_logic_vector; w : integer) return std_logic_vector;
  
  -- Select integer/std_logic/std_logic_vector.
  function sel(s : boolean; x,y : integer) return integer;
  function sel(s : boolean; x,y : std_logic) return std_logic;
  function sel(s : boolean; x,y : std_logic_vector) return std_logic_vector;
  function max_of(x,y : integer) return integer;
  function min_of(x,y : integer) return integer;
  function is_on(x: integer) return integer;
  function is_off(x: integer) return integer;
  
  -- Logic functions.
  function reduce_or(x : std_logic_vector) return std_logic;
  function reduce_and(x : std_logic_vector) return std_logic;
  function reduce_xor(x : std_logic_vector) return std_logic;
  
  -- Create a resolved boolean
  function resolve_boolean(values : in boolean_array ) return boolean;

  -- Resolved boolean type
  subtype rboolean is resolve_boolean boolean;

  -- Or two integer booleans
  function intbool_or(constant a : integer; constant b : integer ) return integer;

  -- Create a resolved integer
  function resolve_integer(values : in integer_array ) return integer;

  -- Resolved integer type
  subtype rinteger is resolve_integer integer;

  -- moved from microblaze.vhd for GTi
  function LowerCase_Char(char : character) return character;
  function LowerCase_String (s : string) return string;
  function Equal_String( str1, str2 : STRING ) RETURN BOOLEAN;
  function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE;

  -- Get the maximum number of inputs to a LUT.
  function Family_To_LUT_Size(Family : TARGET_FAMILY_TYPE) return integer;

  function Has_Target(Family : TARGET_FAMILY_TYPE; TARGET_PROP : TARGET_PROPERTY_TYPE) return boolean;
  
  
  -----------------------------------------------------------------------------
  -- System Cache Specific Constants
  -----------------------------------------------------------------------------
  
  -- 0   - v2.00a
  -- 1   - v3.0
  -- 2   - v2.00b
  -- 3   - v3.1
  constant C_SYSTEM_CACHE_VERSION       : natural :=  3;
  
  -- ----------------------------------------
  -- Static System Cache Constants
  
  constant C_MAX_NUM_PORT_WIDTH         : natural :=  5;
  constant C_MAX_NUM_PORTS              : natural :=  2 ** C_MAX_NUM_PORT_WIDTH;
  constant C_MAX_OPTIMIZED_PORTS        : natural := 16;
  constant C_MAX_GENERIC_PORTS          : natural := 16;
  constant C_MAX_PORTS                  : natural :=  C_MAX_OPTIMIZED_PORTS + C_MAX_GENERIC_PORTS;
  
  
  -- ----------------------------------------
  -- System Cache Range Constants
  
  subtype C_PORT_NUM_POS                is natural range C_MAX_NUM_PORT_WIDTH - 1 downto 0;
  subtype C_MAX_PORTS_POS               is natural range C_MAX_NUM_PORTS - 1 downto 0;
  
  
  -- ----------------------------------------
  -- System Cache Derived Types
  
  subtype PORT_NUM_TYPE                 is std_logic_vector(C_PORT_NUM_POS);
  subtype MAX_PORTS_TYPE                is std_logic_vector(C_MAX_PORTS_POS);
  
  
  -- ----------------------------------------
  -- Static AXI Constants
  
  constant C_MAX_ADDR_WIDTH             : natural := 64;
  constant C_MAX_RRESP_WIDTH            : natural :=  4;
  constant C_ACE_RRESP_WIDTH            : natural :=  4;
  constant C_AXI_RRESP_WIDTH            : natural :=  2;
  constant C_BRESP_WIDTH                : natural :=  2;
  constant C_AXI_LENGTH_WIDTH           : natural :=  8;
  
  
  -- ----------------------------------------
  -- AXI Range Constants
  
  subtype C_AXI_ADDR_POS                is natural range C_MAX_ADDR_WIDTH - 1 downto 0;
  subtype C_AXI_LENGTH_POS              is natural range 8 - 1 downto 0;
  subtype C_AXI_SIZE_POS                is natural range 3 - 1 downto 0;
  subtype C_AXI_BURST_POS               is natural range 2 - 1 downto 0;
  subtype C_AXI_CACHE_POS               is natural range 4 - 1 downto 0;
  subtype C_AXI_PROT_POS                is natural range 3 - 1 downto 0;
  subtype C_AXI_QOS_POS                 is natural range 4 - 1 downto 0;
  subtype C_AXI_BRESP_POS               is natural range C_BRESP_WIDTH - 1 downto 0;
  subtype C_AXI_RRESP_POS               is natural range C_MAX_RRESP_WIDTH - 1 downto 0;
  subtype C_AXI_ACSNOOP_POS             is natural range 4 - 1 downto 0;
  subtype C_AXI_AWSNOOP_POS             is natural range 3 - 1 downto 0;
  subtype C_AXI_ARSNOOP_POS             is natural range 4 - 1 downto 0;
  subtype C_AXI_SNOOP_POS               is natural range 4 - 1 downto 0;
  subtype C_AXI_BARRIER_POS             is natural range 2 - 1 downto 0;
  subtype C_AXI_DOMAIN_POS              is natural range 2 - 1 downto 0;
  subtype C_AXI_CRRESP_POS              is natural range 5 - 1 downto 0;
  
  subtype C_AXI_LENGTH_CARRY_POS        is natural range 8 downto 0;
  
  
  -- ----------------------------------------
  -- Bit fields
  
  subtype  C_DVM_VMID_POS               is natural range 31 downto 24;
  subtype  C_DVM_ASID_POS               is natural range 23 downto 16;
  constant C_DVM_NEED_COMPLETE_POS      :  natural              := 15;
  subtype  C_DVM_MESSAGE_POS            is natural range 14 downto 12;
  subtype  C_DVM_OS_POS                 is natural range 11 downto 10;
  subtype  C_DVM_SECURE_POS             is natural range  9 downto  8;
  constant C_DVM_RESERVED1_POS          :  natural              :=  7;
  constant C_DVM_USE_VMID_POS           :  natural              :=  6;
  constant C_DVM_USE_ASID_POS           :  natural              :=  5;
  subtype  C_DVM_RESERVED0_POS          is natural range  4 downto  1;
  constant C_DVM_MORE_POS               :  natural              :=  0;
  
  constant C_RRESP_ISSHARED_POS         :  natural              :=  3;
  constant C_RRESP_PASSDIRTY_POS        :  natural              :=  2;
  constant C_RRESP_ERROR_POS            :  natural              :=  1;
  constant C_RRESP_EXOKAY_POS           :  natural              :=  0;
  
  constant C_CRRESP_WASUNIQUE_POS       :  natural              :=  4;
  constant C_CRRESP_ISSHARED_POS        :  natural              :=  3;
  constant C_CRRESP_PASSDIRTY_POS       :  natural              :=  2;
  constant C_CRRESP_ERROR_POS           :  natural              :=  1;
  constant C_CRRESP_DATATRANSFER_POS    :  natural              :=  0;
  
  
  -- ----------------------------------------
  -- AXI Derived Types
  
  subtype AXI_ADDR_TYPE                 is std_logic_vector(C_AXI_ADDR_POS);
  subtype AXI_LENGTH_TYPE               is std_logic_vector(C_AXI_LENGTH_POS);
  subtype AXI_SIZE_TYPE                 is std_logic_vector(C_AXI_SIZE_POS);
  subtype AXI_BURST_TYPE                is std_logic_vector(C_AXI_BURST_POS);
  subtype AXI_CACHE_TYPE                is std_logic_vector(C_AXI_CACHE_POS);
  subtype AXI_PROT_TYPE                 is std_logic_vector(C_AXI_PROT_POS);
  subtype AXI_QOS_TYPE                  is std_logic_vector(C_AXI_QOS_POS);
  subtype AXI_BRESP_TYPE                is std_logic_vector(C_AXI_BRESP_POS);
  subtype AXI_RRESP_TYPE                is std_logic_vector(C_AXI_RRESP_POS);
  subtype AXI_ACSNOOP_TYPE              is std_logic_vector(C_AXI_ACSNOOP_POS);
  subtype AXI_AWSNOOP_TYPE              is std_logic_vector(C_AXI_AWSNOOP_POS);
  subtype AXI_ARSNOOP_TYPE              is std_logic_vector(C_AXI_ARSNOOP_POS);
  subtype AXI_SNOOP_TYPE                is std_logic_vector(C_AXI_SNOOP_POS);
  subtype AXI_BARRIER_TYPE              is std_logic_vector(C_AXI_BARRIER_POS);
  subtype AXI_DOMAIN_TYPE               is std_logic_vector(C_AXI_DOMAIN_POS);
  subtype AXI_CRRESP_TYPE               is std_logic_vector(C_AXI_CRRESP_POS);
  
  subtype DVM_VMID_TYPE                 is std_logic_vector(C_DVM_VMID_POS);
  subtype DVM_ASID_TYPE                 is std_logic_vector(C_DVM_ASID_POS);
  subtype DVM_MESSAGE_TYPE              is std_logic_vector(C_DVM_MESSAGE_POS);
  subtype DVM_OS_TYPE                   is std_logic_vector(C_DVM_OS_POS);
  subtype DVM_SECURE_TYPE               is std_logic_vector(C_DVM_SECURE_POS);
  
  subtype AXI_LENGTH_CARRY_TYPE         is std_logic_vector(C_AXI_LENGTH_CARRY_POS);
  
  type AXI_SNOOP_VECTOR_TYPE            is array(natural range <>) of AXI_SNOOP_TYPE;
  type AXI_CRRESP_VECTOR_TYPE           is array(natural range <>) of AXI_CRRESP_TYPE;
  
  -- ----------------------------------------
  -- PARD DSid Types
  constant C_CURRENT_DSID_WIDTH 	: natural := 16;
  constant C_MAX_DSID_WIDTH 		: natural := 32;
  subtype  C_PARD_DSID_POS  is natural range C_CURRENT_DSID_WIDTH-1 downto 0;
  subtype  PARD_DSID_TYPE   is std_logic_vector(C_PARD_DSID_POS);
  
  -- Statistic Constant & Types 
  
  constant C_RD_LATENCY_WIDTH           : natural := 2;
  constant C_WR_LATENCY_WIDTH           : natural := 3;
  
  subtype C_RD_LATENCY_POS              is natural range C_RD_LATENCY_WIDTH - 1 downto 0;
  subtype C_WR_LATENCY_POS              is natural range C_WR_LATENCY_WIDTH - 1 downto 0;
  
  subtype RD_LATENCY_TYPE               is std_logic_vector(C_RD_LATENCY_POS);
  subtype WR_LATENCY_TYPE               is std_logic_vector(C_WR_LATENCY_POS);
  
  constant C_CTRL_CONF_WIDTH            : natural := 1;
  subtype C_CTRL_CONF_POS               is natural range C_CTRL_CONF_WIDTH - 1 downto 0;
  subtype CTRL_CONF_TYPE                is std_logic_vector(C_CTRL_CONF_POS);
  
  
  -- ----------------------------------------
  -- AXI Port Information
  
  type COMMON_PORT_TYPE is record
    Valid             : std_logic;
    Addr              : AXI_ADDR_TYPE;
    Len               : AXI_LENGTH_TYPE;
    Kind              : std_logic;
    Exclusive         : std_logic;
    Allocate          : std_logic;
    Bufferable        : std_logic;
    Prot              : AXI_PROT_TYPE;
    Barrier           : AXI_BARRIER_TYPE;
    Domain            : AXI_DOMAIN_TYPE;
    Size              : AXI_SIZE_TYPE;
    DSid              : PARD_DSID_TYPE;
  end record COMMON_PORT_TYPE;
  
  type WRITE_PORT_TYPE is record
    Valid             : std_logic;
    Addr              : AXI_ADDR_TYPE;
    Len               : AXI_LENGTH_TYPE;
    Kind              : std_logic;
    Exclusive         : std_logic;
    Allocate          : std_logic;
    Bufferable        : std_logic;
    Prot              : AXI_PROT_TYPE;
    Snoop             : AXI_AWSNOOP_TYPE;
    Barrier           : AXI_BARRIER_TYPE;
    Domain            : AXI_DOMAIN_TYPE;
    Size              : AXI_SIZE_TYPE;
    DSid              : PARD_DSID_TYPE;
  end record WRITE_PORT_TYPE;
  
  type READ_PORT_TYPE is record
    Valid             : std_logic;
    Addr              : AXI_ADDR_TYPE;
    Len               : AXI_LENGTH_TYPE;
    Kind              : std_logic;
    Exclusive         : std_logic;
    Allocate          : std_logic;
    Bufferable        : std_logic;
    Prot              : AXI_PROT_TYPE;
    Snoop             : AXI_ARSNOOP_TYPE;
    Barrier           : AXI_BARRIER_TYPE;
    Domain            : AXI_DOMAIN_TYPE;
    Size              : AXI_SIZE_TYPE;
    DSid              : PARD_DSID_TYPE;
  end record READ_PORT_TYPE;
  
  type WRITE_PORTS_TYPE               is array(natural range <>) of WRITE_PORT_TYPE;
  type READ_PORTS_TYPE                is array(natural range <>) of READ_PORT_TYPE;
  
  
  -- ----------------------------------------
  -- Port Arbitration
  
  type ARBITRATION_TYPE is record
    Valid             : std_logic;
    Wr                : std_logic;
    Port_Num          : PORT_NUM_TYPE;
    Addr              : AXI_ADDR_TYPE;
    Len               : AXI_LENGTH_TYPE;
    Kind              : std_logic;
    Exclusive         : std_logic;
    Allocate          : std_logic;
    Bufferable        : std_logic;
    Evict             : std_logic;
    Ignore_Data       : std_logic;
    Force_Hit         : std_logic;
    Internal_Cmd      : std_logic;
    Prot              : AXI_PROT_TYPE;
    Snoop             : AXI_SNOOP_TYPE;
    Barrier           : AXI_BARRIER_TYPE;
    Domain            : AXI_DOMAIN_TYPE;
    Size              : AXI_SIZE_TYPE;
    DSid              : PARD_DSID_TYPE;
  end record ARBITRATION_TYPE;
  
  
  constant C_ARB_TYPE_LEN  : natural:= 1 + 1 + PORT_NUM_TYPE'length + AXI_ADDR_TYPE'length + AXI_LENGTH_TYPE'length + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + AXI_PROT_TYPE'length + AXI_SNOOP_TYPE'length + AXI_BARRIER_TYPE'length + AXI_DOMAIN_TYPE'length + AXI_SIZE_TYPE'length;
  
  
  function To_StdVec(from : ARBITRATION_TYPE) return std_logic_vector;
  
  
  -- ----------------------------------------
  -- Access Information
  
  type ACCESS_TYPE is record
    Port_Num          : PORT_NUM_TYPE;
    Allocate          : std_logic;
    Bufferable        : std_logic;
    Exclusive         : std_logic;
    Evict             : std_logic;
    SnoopResponse     : std_logic;
    KillHit           : std_logic;
    Kind              : std_logic;
    Wr                : std_logic;
    PassDirty         : std_logic;
    IsShared          : std_logic;
    Lx_Allocate       : std_logic;
    Ignore_Data       : std_logic;
    Force_Hit         : std_logic;
    Internal_Cmd      : std_logic;
    Addr              : AXI_ADDR_TYPE;
    Len               : AXI_LENGTH_TYPE;
    Size              : AXI_SIZE_TYPE;
    DSid              : PARD_DSID_TYPE;
  end record ACCESS_TYPE;
  
  
  constant C_ACC_TYPE_LEN   : natural:= PORT_NUM_TYPE'length + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 + 1 +AXI_ADDR_TYPE'length + AXI_LENGTH_TYPE'length + AXI_SIZE_TYPE'length;
  
  
  function To_StdVec(from : ACCESS_TYPE) return std_logic_vector;
  
  
  -- ----------------------------------------
  -- Statistics Information
  
  constant C_MAX_STAT_WIDTH             : natural := 64;
  subtype C_STAT_POS                    is natural range C_MAX_STAT_WIDTH - 1 downto 0;
  subtype STAT_TYPE                     is std_logic_vector(C_STAT_POS);
  
  constant C_MAX_STAT_CONF_WIDTH        : natural := 64;
  subtype C_STAT_CONF_POS               is natural range C_MAX_STAT_CONF_WIDTH - 1 downto 0;
  subtype STAT_CONF_TYPE                is std_logic_vector(C_STAT_CONF_POS);
  
  constant C_STAT_MIN_HI                : natural := C_MAX_STAT_WIDTH - 1;
  constant C_STAT_MIN_LO                : natural := C_MAX_STAT_WIDTH - 16;
  subtype C_STAT_MIN_POS                is natural range C_STAT_MIN_HI downto C_STAT_MIN_LO;
  subtype STAT_MIN_TYPE                 is std_logic_vector(C_STAT_MIN_POS);
  constant C_STAT_MAX_HI                : natural := C_MAX_STAT_WIDTH -16 - 1;
  constant C_STAT_MAX_LO                : natural := C_MAX_STAT_WIDTH - 32;
  subtype C_STAT_MAX_POS                is natural range C_STAT_MAX_HI downto C_STAT_MAX_LO;
  subtype STAT_MAX_TYPE                 is std_logic_vector(C_STAT_MAX_POS);
  constant C_STAT_FULL_POS              : natural := 1;
  constant C_STAT_OVERFLOW_POS          : natural := 0;
  
  type STAT_POINT_TYPE is record
    Events            : STAT_TYPE;
    Min_Max_Status    : STAT_TYPE;
    Sum               : STAT_TYPE;
    Sum_2             : STAT_TYPE;
  end record STAT_POINT_TYPE;
  
  type STAT_FIFO_TYPE is record
    Empty_Cycles      : STAT_TYPE;
    Index_Updates     : STAT_TYPE;
    Index_Max         : STAT_TYPE;
    Index_Sum         : STAT_TYPE;
  end record STAT_FIFO_TYPE;
  
  type STAT_VECTOR_TYPE                 is array(natural range <>) of STAT_TYPE;
  type STAT_POINT_VECTOR_TYPE           is array(natural range <>) of STAT_POINT_TYPE;
  type STAT_FIFO_VECTOR_TYPE            is array(natural range <>) of STAT_FIFO_TYPE;
  type STAT_CONF_VECTOR_TYPE            is array(natural range <>) of STAT_CONF_TYPE;
  
  
  constant C_STAT_POINT_TYPE_LEN        : natural:= 4 * C_MAX_STAT_WIDTH;
  constant C_STAT_FIFO_TYPE_LEN         : natural:= 4 * C_MAX_STAT_WIDTH;
  
  
  function To_StdVec(from : STAT_POINT_TYPE) return std_logic_vector;
  function To_StdVec(from : STAT_FIFO_TYPE) return std_logic_vector;
  
  function Stat_Get_Register(from : STAT_VECTOR_TYPE; 
                             idx  : natural) return STAT_TYPE;
  function Stat_Point_Get_Register(from : STAT_POINT_TYPE; 
                                   idx  : natural range 0 to 7) return STAT_TYPE;
  function Stat_FIFO_Get_Register(from : STAT_FIFO_TYPE; 
                                  idx  : natural range 0 to 7) return STAT_TYPE;
  function Stat_Conf_Get_Register(from : STAT_CONF_VECTOR_TYPE; 
                                  idx  : natural) return STAT_TYPE;
  function Stat_Conf_Get_Register(from : STAT_CONF_TYPE) return STAT_TYPE;
                                  
  function Stat_Conf_Set_Register(from : std_logic_vector; 
                                  w    : natural) return STAT_CONF_TYPE;
  
  function Stat_Get_Register_32bit(from : STAT_VECTOR_TYPE; 
                                   idx  : natural;
                                   word : natural range 0 to 1) return std_logic_vector;
  function Stat_Get_Register_64bit(from : STAT_VECTOR_TYPE; 
                                   idx  : natural) return std_logic_vector;
  function Stat_Point_Get_Register_32bit(from : STAT_POINT_TYPE; 
                                         idx  : natural range 0 to 7;
                                         word : natural range 0 to 1) return std_logic_vector;
  function Stat_Point_Get_Register_64bit(from : STAT_POINT_TYPE; 
                                         idx  : natural range 0 to 7) return std_logic_vector;
  function Stat_FIFO_Get_Register_32bit(from  : STAT_FIFO_TYPE; 
                                        idx   : natural range 0 to 7;
                                        word  : natural range 0 to 1) return std_logic_vector;
  function Stat_FIFO_Get_Register_64bit(from  : STAT_FIFO_TYPE; 
                                        idx   : natural range 0 to 7) return std_logic_vector;
  
  
  -- ----------------------------------------
  -- Null Records
  
  constant C_NULL_COMMON_PORT         : COMMON_PORT_TYPE  := (Valid=>'0', Addr=>(others=>'0'),  Len=>(others=>'0'), 
                                                              Kind=>'0', Exclusive=>'0', Allocate=>'0', 
                                                              Bufferable=>'0', Prot=>(others=>'0'), 
                                                              Barrier=>(others=>'0'), Domain=>(others=>'0'), 
                                                              Size=>(others=>'0'), DSid=>(others=>'0'));
  
  constant C_NULL_WRITE_PORT          : WRITE_PORT_TYPE   := (Valid=>'0', Addr=>(others=>'0'),  Len=>(others=>'0'), 
                                                              Kind=>'0', Exclusive=>'0', Allocate=>'0', 
                                                              Bufferable=>'0', Prot=>(others=>'0'), 
                                                              Snoop=>(others=>'0'), Barrier=>(others=>'0'), 
                                                              Domain=>(others=>'0'), Size=>(others=>'0'),
                                                              DSid=>(others=>'0'));
  
  constant C_NULL_READ_PORT           : READ_PORT_TYPE    := (Valid=>'0', Addr=>(others=>'0'),  Len=>(others=>'0'), 
                                                              Kind=>'0', Exclusive=>'0', Allocate=>'0', 
                                                              Bufferable=>'0', Prot=>(others=>'0'), 
                                                              Snoop=>(others=>'0'), Barrier=>(others=>'0'), 
                                                              Domain=>(others=>'0'), Size=>(others=>'0'),
                                                              DSid=>(others=>'0'));
  
  constant C_NULL_ARBITRATION         : ARBITRATION_TYPE  := (Valid=>'0', Wr=>'0', Port_Num=>(others=>'0'), 
                                                              Addr=>(others=>'0'),  Len=>(others=>'0'), 
                                                              Kind=>'0', Exclusive=>'0', Allocate=>'0', 
                                                              Bufferable=>'0', Evict=>'0', Ignore_Data=>'0', 
                                                              Force_Hit=>'0', Internal_Cmd=>'0', Prot=>(others=>'0'), 
                                                              Snoop=>(others=>'0'), Barrier=>(others=>'0'), 
                                                              Domain=>(others=>'0'), Size=>(others=>'0'),
                                                              DSid=>(others=>'0'));
  
  constant C_NULL_ACCESS              : ACCESS_TYPE       := (Port_Num=>(others=>'0'), Allocate=>'0', Bufferable=>'0', 
                                                              Exclusive=>'0', Evict=>'0', SnoopResponse=>'0', 
                                                              KillHit=>'0', Kind=>'0', Wr=>'0', 
                                                              PassDirty=>'0', IsShared=>'0', Lx_Allocate=>'0', 
                                                              Ignore_Data=>'0', Force_Hit=>'0', Internal_Cmd=>'0', 
                                                              Addr=>(others=>'0'), Len=>(others=>'0'), 
                                                              Size=>(others=>'0'), DSid=>(others=>'0'));
  
  constant C_NULL_STAT_POINT          : STAT_POINT_TYPE   := (Events=>(others=>'0'), Min_Max_Status=>(others=>'0'), 
                                                              Sum=>(others=>'0'), Sum_2=>(others=>'0'));
  
  constant C_NULL_STAT_FIFO           : STAT_FIFO_TYPE    := (Empty_Cycles=>(others=>'0'), Index_Updates=>(others=>'0'), 
                                                              Index_Max=>(others=>'0'), Index_Sum=>(others=>'0'));
  
  
  -- ----------------------------------------
  -- AXI NULL
  
  constant NULL_AXI_ADDR                : AXI_ADDR_TYPE   := (others=>'0');
  constant NULL_AXI_LENGTH              : AXI_LENGTH_TYPE := (others=>'0');
  constant NULL_AXI_SIZE                : AXI_SIZE_TYPE   := (others=>'0');
  constant NULL_AXI_BURST               : AXI_BURST_TYPE  := (others=>'0');
  constant NULL_AXI_CACHE               : AXI_CACHE_TYPE  := (others=>'0');
  constant NULL_AXI_PROT                : AXI_PROT_TYPE   := (others=>'0');
  constant NULL_AXI_QOS                 : AXI_QOS_TYPE    := (others=>'0');
  constant NULL_AXI_BRESP               : AXI_BRESP_TYPE  := (others=>'0');
  constant NULL_AXI_RRESP               : AXI_RRESP_TYPE  := (others=>'0');
  constant NULL_AXI_ACSNOOP             : AXI_ACSNOOP_TYPE:= (others=>'0');
  constant NULL_AXI_AWSNOOP             : AXI_AWSNOOP_TYPE:= (others=>'0');
  constant NULL_AXI_ARSNOOP             : AXI_ARSNOOP_TYPE:= (others=>'0');
  constant NULL_AXI_SNOOP               : AXI_SNOOP_TYPE  := (others=>'0');
  constant NULL_AXI_BARRIER             : AXI_BARRIER_TYPE:= (others=>'0');
  constant NULL_AXI_DOMAIN              : AXI_DOMAIN_TYPE := (others=>'0');
  constant NULL_AXI_CRRESP              : AXI_CRRESP_TYPE := (others=>'0');
  
  
  -- ----------------------------------------
  -- AXI Constants
  
  -- http://en.wikipedia.org/wiki/Number_prefix
  constant C_BYTE_SIZE                  : AXI_SIZE_TYPE := "000";
  constant C_HALF_WORD_SIZE             : AXI_SIZE_TYPE := "001";
  constant C_WORD_SIZE                  : AXI_SIZE_TYPE := "010";
  constant C_DOUBLE_WORD_SIZE           : AXI_SIZE_TYPE := "011";
  constant C_QUAD_WORD_SIZE             : AXI_SIZE_TYPE := "100";
  constant C_OCTA_WORD_SIZE             : AXI_SIZE_TYPE := "101";
  constant C_HEXADECA_WORD_SIZE         : AXI_SIZE_TYPE := "110";
  constant C_TRIACONTADI_WORD_SIZE      : AXI_SIZE_TYPE := "111";
  
  constant C_BYTE_STEP_SIZE             : natural :=   1;
  constant C_HALF_WORD_STEP_SIZE        : natural :=   2;
  constant C_WORD_STEP_SIZE             : natural :=   4;
  constant C_DOUBLE_WORD_STEP_SIZE      : natural :=   8;
  constant C_QUAD_WORD_STEP_SIZE        : natural :=  16;
  constant C_OCTA_WORD_STEP_SIZE        : natural :=  32;
  constant C_HEXADECA_WORD_STEP_SIZE    : natural :=  64;
  constant C_TRIACONTADI_WORD_STEP_SIZE : natural := 128;
  
  constant C_BYTE_WIDTH                 : natural := 8 * C_BYTE_STEP_SIZE;
  constant C_HALF_WORD_WIDTH            : natural := 8 * C_HALF_WORD_STEP_SIZE;
  constant C_WORD_WIDTH                 : natural := 8 * C_WORD_STEP_SIZE;
  constant C_DOUBLE_WORD_WIDTH          : natural := 8 * C_DOUBLE_WORD_STEP_SIZE;
  constant C_QUAD_WORD_WIDTH            : natural := 8 * C_QUAD_WORD_STEP_SIZE;
  constant C_OCTA_WORD_WIDTH            : natural := 8 * C_OCTA_WORD_STEP_SIZE;
  constant C_HEXADECA_WORD_WIDTH        : natural := 8 * C_HEXADECA_WORD_STEP_SIZE;
  constant C_TRIACONTADI_WORD_WIDTH     : natural := 8 * C_TRIACONTADI_WORD_STEP_SIZE;
  
  constant C_BRESP_OKAY                 : AXI_BRESP_TYPE  := std_logic_vector(to_unsigned(0, C_BRESP_WIDTH));
  constant C_BRESP_EXOKAY               : AXI_BRESP_TYPE  := std_logic_vector(to_unsigned(1, C_BRESP_WIDTH));
  constant C_BRESP_SLVERR               : AXI_BRESP_TYPE  := std_logic_vector(to_unsigned(2, C_BRESP_WIDTH));
  constant C_BRESP_DECERR               : AXI_BRESP_TYPE  := std_logic_vector(to_unsigned(3, C_BRESP_WIDTH));
  constant C_RRESP_OKAY                 : AXI_RRESP_TYPE  := std_logic_vector(to_unsigned(0, C_MAX_RRESP_WIDTH));
  constant C_RRESP_EXOKAY               : AXI_RRESP_TYPE  := std_logic_vector(to_unsigned(1, C_MAX_RRESP_WIDTH));
  constant C_RRESP_SLVERR               : AXI_RRESP_TYPE  := std_logic_vector(to_unsigned(2, C_MAX_RRESP_WIDTH));
  constant C_RRESP_DECERR               : AXI_RRESP_TYPE  := std_logic_vector(to_unsigned(3, C_MAX_RRESP_WIDTH));
  
  constant C_LOCK_NORMAL                : std_logic := '0';
  constant C_LOCK_EXCLUSIVE             : std_logic := '1';

  constant C_AR_FIX                     : std_logic_vector(1 downto 0) := "00";
  constant C_AR_INCR                    : std_logic_vector(1 downto 0) := "01";
  constant C_AR_WRAP                    : std_logic_vector(1 downto 0) := "10";
  constant C_AR_RESERVED                : std_logic_vector(1 downto 0) := "11";
  constant C_AW_FIX                     : std_logic_vector(1 downto 0) := "00";
  constant C_AW_INCR                    : std_logic_vector(1 downto 0) := "01";
  constant C_AW_WRAP                    : std_logic_vector(1 downto 0) := "10";
  constant C_AW_RESERVED                : std_logic_vector(1 downto 0) := "11";
  constant C_KIND_WRAP                  : std_logic                    := '1';
  constant C_KIND_INCR                  : std_logic                    := '0';
  
  constant C_ARCACHE_BUFFERABLE_POS     : natural := 0;
  constant C_ARCACHE_MODIFIABLE_POS     : natural := 1;
  constant C_ARCACHE_READ_ALLOCATE_POS  : natural := 2;
  constant C_ARCACHE_OTHER_ALLOCATE_POS : natural := 3;
  constant C_AWCACHE_BUFFERABLE_POS     : natural := 0;
  constant C_AWCACHE_MODIFIABLE_POS     : natural := 1;
  constant C_AWCACHE_OTHER_ALLOCATE_POS : natural := 2;
  constant C_AWCACHE_WRITE_ALLOCATE_POS : natural := 3;
  
  
  
  -- ----------------------------------------
  -- ACE Constants
  
  constant C_DOMAIN_NON_SHAREABLE       : AXI_DOMAIN_TYPE:= "00";
  constant C_DOMAIN_INNER_SHAREABLE     : AXI_DOMAIN_TYPE:= "01";
  constant C_DOMAIN_OUTER_SHAREABLE     : AXI_DOMAIN_TYPE:= "10";
  constant C_DOMAIN_SYSTEM_SHAREABLE    : AXI_DOMAIN_TYPE:= "11";
  
  constant C_BAR_NORMAL_RESPECTING      : AXI_BARRIER_TYPE:= "00";
  constant C_BAR_MEMORY_BARRIER         : AXI_BARRIER_TYPE:= "01";
  constant C_BAR_NORMAL_IGNORING        : AXI_BARRIER_TYPE:= "10";
  constant C_BAR_SYNCHRONIZATION        : AXI_BARRIER_TYPE:= "11";
  
  constant C_ARSNOOP_ReadNoSnoop        : AXI_ARSNOOP_TYPE:= "0000";
  constant C_ARSNOOP_ReadOnce           : AXI_ARSNOOP_TYPE:= "0000";
  constant C_ARSNOOP_ReadShared         : AXI_ARSNOOP_TYPE:= "0001";
  constant C_ARSNOOP_ReadClean          : AXI_ARSNOOP_TYPE:= "0010";
  constant C_ARSNOOP_ReadNotSharedDirty : AXI_ARSNOOP_TYPE:= "0011";
  constant C_ARSNOOP_ReadUnique         : AXI_ARSNOOP_TYPE:= "0111";
  constant C_ARSNOOP_CleanUnique        : AXI_ARSNOOP_TYPE:= "1011";
  constant C_ARSNOOP_MakeUnique         : AXI_ARSNOOP_TYPE:= "1100";
  constant C_ARSNOOP_CleanShared        : AXI_ARSNOOP_TYPE:= "1000";
  constant C_ARSNOOP_CleanInvalid       : AXI_ARSNOOP_TYPE:= "1001";
  constant C_ARSNOOP_MakeInvalid        : AXI_ARSNOOP_TYPE:= "1101";
  constant C_ARSNOOP_DVMComplete        : AXI_ARSNOOP_TYPE:= "1110";
  constant C_ARSNOOP_DVMMessage         : AXI_ARSNOOP_TYPE:= "1111";
  constant C_ARSNOOP_Barrier            : AXI_ARSNOOP_TYPE:= "0000";
  
  constant C_AWSNOOP_WriteNoSnoop       : AXI_AWSNOOP_TYPE:= "000";
  constant C_AWSNOOP_WriteUnique        : AXI_AWSNOOP_TYPE:= "000";
  constant C_AWSNOOP_WriteLineUnique    : AXI_AWSNOOP_TYPE:= "001";
  constant C_AWSNOOP_WriteClean         : AXI_AWSNOOP_TYPE:= "010";
  constant C_AWSNOOP_WriteBack          : AXI_AWSNOOP_TYPE:= "011";
  constant C_AWSNOOP_Evict              : AXI_AWSNOOP_TYPE:= "100";
  constant C_AWSNOOP_Barrier            : AXI_AWSNOOP_TYPE:= "000";
    
  constant C_ACSNOOP_ReadOnce           : AXI_ACSNOOP_TYPE:= "0000";
  constant C_ACSNOOP_ReadShared         : AXI_ACSNOOP_TYPE:= "0001";
  constant C_ACSNOOP_ReadClean          : AXI_ACSNOOP_TYPE:= "0010";
  constant C_ACSNOOP_ReadNotSharedDirty : AXI_ACSNOOP_TYPE:= "0011";
  constant C_ACSNOOP_ReadUnique         : AXI_ACSNOOP_TYPE:= "0111";
  constant C_ACSNOOP_CleanShared        : AXI_ACSNOOP_TYPE:= "1000";
  constant C_ACSNOOP_CleanInvalid       : AXI_ACSNOOP_TYPE:= "1001";
  constant C_ACSNOOP_MakeInvalid        : AXI_ACSNOOP_TYPE:= "1101";
  constant C_ACSNOOP_DVMComplete        : AXI_ACSNOOP_TYPE:= "1110";
  constant C_ACSNOOP_DVMMessage         : AXI_ACSNOOP_TYPE:= "1111";
  
  constant C_DVM_MSG_TLB_INVALIDATE     : DVM_MESSAGE_TYPE := "000";
  constant C_DVM_MSG_BP_INVALIDATE      : DVM_MESSAGE_TYPE := "001";
  constant C_DVM_MSG_PH_INSTR_INVAL     : DVM_MESSAGE_TYPE := "010";
  constant C_DVM_MSG_VIR_INSTR_INVAL    : DVM_MESSAGE_TYPE := "011";
  constant C_DVM_MSG_SYNC               : DVM_MESSAGE_TYPE := "100";
  constant C_DVM_MSG_HINT               : DVM_MESSAGE_TYPE := "110";
  
  constant C_DVM_OS_BOTH                : DVM_OS_TYPE      := "00";
  constant C_DVM_OS_RESERVED            : DVM_OS_TYPE      := "01";
  constant C_DVM_OS_GUEST               : DVM_OS_TYPE      := "10";
  constant C_DVM_OS_HYPERVISOR          : DVM_OS_TYPE      := "11";
  
  constant C_DVM_SECURE_BOTH            : DVM_SECURE_TYPE  := "00";
  constant C_DVM_SECURE_RESERVED        : DVM_SECURE_TYPE  := "01";
  constant C_DVM_SECURE_SECURE_ONLY     : DVM_SECURE_TYPE  := "10";
  constant C_DVM_SECURE_NONSECURE_ONLY  : DVM_SECURE_TYPE  := "11";
  
  
  -- ----------------------------------------
  -- Statistics Constants
  
  constant C_STAT_ADDR_OPT_CATEGORY         : natural :=  0;  -- 000
  constant C_STAT_ADDR_GEN_CATEGORY         : natural :=  1;  -- 020
  constant C_STAT_ADDR_ARB_CATEGORY         : natural :=  2;  -- 040
  constant C_STAT_ADDR_ACS_CATEGORY         : natural :=  3;  -- 060
  constant C_STAT_ADDR_LU_CATEGORY          : natural :=  4;  -- 080
  constant C_STAT_ADDR_UD_CATEGORY          : natural :=  5;  -- 0A0
  constant C_STAT_ADDR_BE_CATEGORY          : natural :=  6;  -- 0C0
  constant C_STAT_ADDR_CTRL_CATEGORY        : natural :=  7;  -- 0E0
  
  
  constant C_STAT_ADDR_OPT_RD_SEGMENTS      : natural :=  0;  -- 000
  constant C_STAT_ADDR_OPT_WR_SEGMENTS      : natural :=  1;  -- 020
  constant C_STAT_ADDR_OPT_RIP              : natural :=  2;  -- 040
  constant C_STAT_ADDR_OPT_R                : natural :=  3;  -- 060
  constant C_STAT_ADDR_OPT_BIP              : natural :=  4;  -- 080
  constant C_STAT_ADDR_OPT_BP               : natural :=  5;  -- 0A0
  constant C_STAT_ADDR_OPT_WIP              : natural :=  6;  -- 0C0
  constant C_STAT_ADDR_OPT_W                : natural :=  7;  -- 0E0
  constant C_STAT_ADDR_OPT_READ_BLOCK       : natural :=  8;  -- 100
  constant C_STAT_ADDR_OPT_WRITE_HIT        : natural :=  9;  -- 120
  constant C_STAT_ADDR_OPT_WRITE_MISS       : natural := 10;  -- 140
  constant C_STAT_ADDR_OPT_WRITE_MISS_DIRTY : natural := 11;  -- 160
  constant C_STAT_ADDR_OPT_READ_HIT         : natural := 12;  -- 180
  constant C_STAT_ADDR_OPT_READ_MISS        : natural := 13;  -- 1A0
  constant C_STAT_ADDR_OPT_READ_MISS_DIRTY  : natural := 14;  -- 1C0
  constant C_STAT_ADDR_OPT_LOCKED_WRITE_HIT : natural := 15;  -- 1E0
  constant C_STAT_ADDR_OPT_LOCKED_READ_HIT  : natural := 16;  -- 200
  constant C_STAT_ADDR_OPT_FIRST_WRITE_HIT  : natural := 17;  -- 220
  constant C_STAT_ADDR_OPT_RD_LATENCY       : natural := 18;  -- 240
  constant C_STAT_ADDR_OPT_WR_LATENCY       : natural := 19;  -- 260
  constant C_STAT_ADDR_OPT_RD_LAT_CONF      : natural := 20;  -- 280
  constant C_STAT_ADDR_OPT_WR_LAT_CONF      : natural := 21;  -- 2A0
  
  
  constant C_STAT_ADDR_GEN_RD_SEGMENTS      : natural :=  0;  -- 000
  constant C_STAT_ADDR_GEN_WR_SEGMENTS      : natural :=  1;  -- 020
  constant C_STAT_ADDR_GEN_RIP              : natural :=  2;  -- 040
  constant C_STAT_ADDR_GEN_R                : natural :=  3;  -- 060
  constant C_STAT_ADDR_GEN_BIP              : natural :=  4;  -- 080
  constant C_STAT_ADDR_GEN_BP               : natural :=  5;  -- 0A0
  constant C_STAT_ADDR_GEN_WIP              : natural :=  6;  -- 0C0
  constant C_STAT_ADDR_GEN_W                : natural :=  7;  -- 0E0
  constant C_STAT_ADDR_GEN_READ_BLOCK       : natural :=  8;  -- 100
  constant C_STAT_ADDR_GEN_WRITE_HIT        : natural :=  9;  -- 120
  constant C_STAT_ADDR_GEN_WRITE_MISS       : natural := 10;  -- 140
  constant C_STAT_ADDR_GEN_WRITE_MISS_DIRTY : natural := 11;  -- 160
  constant C_STAT_ADDR_GEN_READ_HIT         : natural := 12;  -- 180
  constant C_STAT_ADDR_GEN_READ_MISS        : natural := 13;  -- 1A0
  constant C_STAT_ADDR_GEN_READ_MISS_DIRTY  : natural := 14;  -- 1C0
  constant C_STAT_ADDR_GEN_LOCKED_WRITE_HIT : natural := 15;  -- 1E0
  constant C_STAT_ADDR_GEN_LOCKED_READ_HIT  : natural := 16;  -- 200
  constant C_STAT_ADDR_GEN_FIRST_WRITE_HIT  : natural := 17;  -- 220
  constant C_STAT_ADDR_GEN_RD_LATENCY       : natural := 18;  -- 240
  constant C_STAT_ADDR_GEN_WR_LATENCY       : natural := 19;  -- 260
  constant C_STAT_ADDR_GEN_RD_LAT_CONF      : natural := 20;  -- 280
  constant C_STAT_ADDR_GEN_WR_LAT_CONF      : natural := 21;  -- 2A0
  
  
  constant C_STAT_ADDR_ARB_VALID            : natural :=  0;  -- 000
  constant C_STAT_ADDR_ARB_CON_ACCESS       : natural :=  1;  -- 020
  
  
  constant C_STAT_ADDR_ACS_VALID            : natural :=  0;  -- 000
  constant C_STAT_ADDR_ACS_STALL            : natural :=  1;  -- 020
  constant C_STAT_ADDR_ACS_FETCH_STALL      : natural :=  2;  -- 040
  constant C_STAT_ADDR_ACS_REQ_STALL        : natural :=  3;  -- 060
  constant C_STAT_ADDR_ACS_ACT_STALL        : natural :=  4;  -- 080
  
  
  constant C_STAT_ADDR_LU_STALL             : natural :=  0;  -- 000
  constant C_STAT_ADDR_LU_FETCH_STALL       : natural :=  1;  -- 020
  constant C_STAT_ADDR_LU_MEM_STALL         : natural :=  2;  -- 040
  constant C_STAT_ADDR_LU_DATA_STALL        : natural :=  3;  -- 060
  constant C_STAT_ADDR_LU_DATA_HIT_STALL    : natural :=  4;  -- 080
  constant C_STAT_ADDR_LU_DATA_MISS_STALL   : natural :=  5;  -- 0A0
  
  
  constant C_STAT_ADDR_UD_STALL             : natural :=  0;  -- 000
  constant C_STAT_ADDR_UD_TAG_FREE          : natural :=  1;  -- 020
  constant C_STAT_ADDR_UD_DATA_FREE         : natural :=  2;  -- 040
  constant C_STAT_ADDR_UD_RI                : natural :=  3;  -- 060
  constant C_STAT_ADDR_UD_R                 : natural :=  4;  -- 080
  constant C_STAT_ADDR_UD_E                 : natural :=  5;  -- 0A0
  constant C_STAT_ADDR_UD_BS                : natural :=  6;  -- 0C0
  constant C_STAT_ADDR_UD_WM                : natural :=  7;  -- 0E0
  constant C_STAT_ADDR_UD_WMA               : natural :=  8;  -- 100
  
  
  constant C_STAT_ADDR_BE_AW                : natural :=  0;  -- 000
  constant C_STAT_ADDR_BE_W                 : natural :=  1;  -- 020
  constant C_STAT_ADDR_BE_AR                : natural :=  2;  -- 040
  constant C_STAT_ADDR_BE_AR_SEARCH_DEPTH   : natural :=  3;  -- 060
  constant C_STAT_ADDR_BE_AR_STALL          : natural :=  4;  -- 080
  constant C_STAT_ADDR_BE_AR_PROTECT_STALL  : natural :=  5;  -- 0A0
  constant C_STAT_ADDR_BE_RD_LATENCY        : natural :=  6;  -- 0C0
  constant C_STAT_ADDR_BE_WR_LATENCY        : natural :=  7;  -- 0E0
  constant C_STAT_ADDR_BE_RD_LAT_CONF       : natural :=  8;  -- 100
  constant C_STAT_ADDR_BE_WR_LAT_CONF       : natural :=  9;  -- 120
  
  
  constant C_STAT_ADDR_CTRL_RESET           : natural :=  0;  -- 000
  constant C_STAT_ADDR_CTRL_ENABLE          : natural :=  1;  -- 008
  constant C_STAT_ADDR_CTRL_CLEAN           : natural :=  2;  -- 010
  constant C_STAT_ADDR_CTRL_FLUSH           : natural :=  3;  -- 018
  constant C_STAT_ADDR_CTRL0_VERSION        : natural :=  4;  -- 020
  constant C_STAT_ADDR_CTRL1_VERSION        : natural :=  5;  -- 028
  
  
  -- Settings for read latency measurements
  -- 0: read latency  AR     -> RVALID ack
  -- 1: read latency  AR ack -> RVALID ack
  -- 2: read latency  AR     -> RLAST ack
  -- 3: read latency  AR ack -> RLAST ack
  
  -- Settings for write latency measurements
  -- 0: write latency AW     -> WVALID ack
  -- 1: write latency AW ack -> WVALID ack
  -- 2: write latency AW     -> WLAST ack
  -- 3: write latency AW ack -> WLAST ack
  -- 4: write latency AW     -> B ack
  -- 5: write latency AW ack -> B ack
  
  constant C_STAT_RD_LATENCY_VALID          : RD_LATENCY_TYPE := std_logic_vector(to_unsigned(0, C_RD_LATENCY_WIDTH));
  constant C_STAT_RD_LATENCY_ACK_VALID      : RD_LATENCY_TYPE := std_logic_vector(to_unsigned(1, C_RD_LATENCY_WIDTH));
  constant C_STAT_RD_LATENCY_LAST           : RD_LATENCY_TYPE := std_logic_vector(to_unsigned(2, C_RD_LATENCY_WIDTH));
  constant C_STAT_RD_LATENCY_ACK_LAST       : RD_LATENCY_TYPE := std_logic_vector(to_unsigned(3, C_RD_LATENCY_WIDTH));
  
  constant C_STAT_WR_LATENCY_VALID          : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(0, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_ACK_VALID      : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(1, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_LAST           : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(2, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_ACK_LAST       : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(3, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_BRESP          : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(4, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_ACK_BRESP      : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(5, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_RESEVED1       : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(6, C_WR_LATENCY_WIDTH));
  constant C_STAT_WR_LATENCY_RESEVED2       : WR_LATENCY_TYPE := std_logic_vector(to_unsigned(7, C_WR_LATENCY_WIDTH));
  
  constant C_STAT_DEFAULT_RD_LAT_CONF       : RD_LATENCY_TYPE :=  std_logic_vector(to_unsigned(0, C_RD_LATENCY_WIDTH));
  constant C_STAT_DEFAULT_WR_LAT_CONF       : WR_LATENCY_TYPE :=  std_logic_vector(to_unsigned(4, C_WR_LATENCY_WIDTH));
  
  constant C_STAT_POINT_EVENTS              : natural := 0;
  constant C_STAT_POINT_MIN_MAX_STATUS      : natural := 1;
  constant C_STAT_POINT_SUM                 : natural := 2;
  constant C_STAT_POINT_SUM_2               : natural := 3;
                                      
  constant C_STAT_FIFO_EMPTY_CYCLES         : natural := 0;
  constant C_STAT_FIFO_INDEX_UPDATES        : natural := 1;
  constant C_STAT_FIFO_INDEX_MAX            : natural := 2;
  constant C_STAT_FIFO_INDEX_SUM            : natural := 3;
  
  constant C_CTRL_CONF_ENABLE               : natural := 0;
  constant C_STAT_DEFAULT_CTRL_CONF         : CTRL_CONF_TYPE :=  std_logic_vector(to_unsigned(1, C_CTRL_CONF_WIDTH));
  
  
  -----------------------------------------------------------------------------
  -- System Cache Specific Functions
  -----------------------------------------------------------------------------
  
  -- Translate port vector to natural.
  function get_port_num(signal x : std_logic_vector(4 downto 0); constant y : natural) return natural;
  
  -- Getnumber of common address bits.
  function Addr_Bits (x, y : std_logic_vector(0 to 63);
                      z    : natural) return natural;

  
end package system_cache_pkg;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package body system_cache_pkg is

  -----------------------------------------------------------------------------
  -- Common Functions
  -----------------------------------------------------------------------------
  
  function conv_index (I : integer) return integer is
  begin
    case I is
      when 0 => return 0;
      when 1 => return 2;
      when 2 => return 8;
      when 3 => return 10;
      when 4 => return 16;
      when 5 => return 18;
      when 6 => return 24;
      when 7 => return 26;
      when 8 => return 1;
      when 9 => return 3;
      when 10 => return 9;
      when 11 => return 11;
      when 12 => return 17;
      when 13 => return 19;
      when 14 => return 25;
      when 15 => return 27;
      when 16 => return 4;
      when 17 => return 6;
      when 18 => return 12;
      when 19 => return 14;
      when 20 => return 20;
      when 21 => return 22;
      when 22 => return 28;
      when 23 => return 30;
      when 24 => return 5;
      when 25 => return 7;
      when 26 => return 13;
      when 27 => return 15;
      when 28 => return 21;
      when 29 => return 23;
      when 30 => return 29;
      when 31 => return 31;
      when others => return -1;
    end case;
  end function conv_index;


  -- log2 function returns the number of bits required to encode x choices
  function log2(x : natural) return integer is
    variable i  : integer := 0;   
  begin 
    if x = 0 then return 0;
    else
      while 2**i < x loop
        i := i+1;
      end loop;
      return i;
    end if;
  end function log2;

  function int_to_std(v : integer) return std_logic is
  begin
    if v /= 0 then 
      return '1';
    end if;
    
    return '0';
  end function int_to_std;
  
  function int_to_std(v, n : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(v, n));
  end function int_to_std;
  
  function fit_vec(v : std_logic_vector; w : integer) return std_logic_vector is
    variable tmp    : std_logic_vector(w-1 downto 0) := (others=>'0');
  begin
    if( v'length > w ) then
      -- Too large => crop.
      tmp                         := v(v'right + w - 1 downto v'right);
    elsif( v'length < w ) then
      -- Too small => expand.
      tmp(v'length - 1 downto 0)  := v;
    else
      -- Just right.
      tmp                         := v;
    end if;
    
    return tmp;
  end function fit_vec;
  
  function sel(s : boolean; x,y : integer) return integer is
  begin
    if s then 
      return x;
    end if;
    
    return y;
  end function sel;
  
  function sel(s : boolean; x,y : std_logic) return std_logic is
  begin
    if s then 
      return x;
    end if;
    
    return y;
  end function sel;
  
  function sel(s : boolean; x,y : std_logic_vector) return std_logic_vector is
  begin
    if s then 
      return x;
    end if;
    
    return y;
  end function sel;
  
  function max_of(x,y : integer) return integer is
  begin
    if x > y then 
      return x;
    end if;
    
    return y;
  end function max_of;
  
  function min_of(x,y : integer) return integer is
  begin
    if x < y then 
      return x;
    end if;
    
    return y;
  end function min_of;
  
  function is_on(x : integer) return integer is
  begin
    if x > 0 then 
      return 1;
    end if;
    
    return 0;
  end function is_on;

  function is_off(x : integer) return integer is
  begin
    if x > 0 then 
      return 0;
    end if;
    
    return 1;
  end function is_off;

  
  
  function reduce_or(x : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in x'range loop
      r := r or x(i);
    end loop;
    
    return r;
  end function reduce_or;
  
  
  function reduce_and(x : std_logic_vector) return std_logic is
    variable r : std_logic := '1';
  begin
    for i in x'range loop
      r := r and x(i);
    end loop;
    
    return r;
  end function reduce_and;
  
  
  function reduce_xor(x : std_logic_vector) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in x'range loop
      r := r xor x(i);
    end loop;
    
    return r;
  end function reduce_xor;
  
  
  -- Function for resolved boolean
  -- If any boolean in the array is false, then the result is false
  function resolve_boolean( values : in boolean_array ) return boolean is
    variable result: boolean := TRUE;
  begin
    if (values'length = 1) then
       result := values(values'low);
    else
       for I in values'range loop
          if values(I) = FALSE then
             result := FALSE;
          end if;
       end loop;
    end if;
    return result;
  end function resolve_boolean; 

  -- Function to or two integer booleans
  function intbool_or( constant a : integer; constant b : integer) return integer is
    variable result : integer := 0;
  begin
    if a /= 0 then
       result := 1;
    end if;
    if b /= 0 then
       result := 1;
    end if;
    return result;
  end function intbool_or;

  -- Function for resolved integer
  -- The result is the bitwise "or" of the integers
  function resolve_integer( values : in integer_array ) return integer is
    variable result   : integer := 0;
    variable result_s : signed(31 downto 0) := (others => '0');
    variable value_s  : signed(31 downto 0);
  begin
    if (values'length = 1) then
      result := values(values'low);
    else
      for I in values'range loop
        if values(I) < -2147483647 then
          value_s := X"80000000";
        elsif values(I) < 0 then
          value_s := '1' & to_signed((2147483647 + values(I)) + 1, 31);
        else
          value_s := '0' & to_signed(values(I), 31);
        end if;
        result_s := result_s or value_s;
      end loop;
      result := to_integer(result_s);
    end if;
    return result;
  end function resolve_integer;

  function LowerCase_Char(char : character) return character is
  begin
    -- If char is not an upper case letter then return char
    if char < 'A' or char > 'Z' then
      return char;
    end if;
    -- Otherwise map char to its corresponding lower case character and
    -- return that
    case char is
      when 'A'    => return 'a'; when 'B' => return 'b'; when 'C' => return 'c'; when 'D' => return 'd';
      when 'E'    => return 'e'; when 'F' => return 'f'; when 'G' => return 'g'; when 'H' => return 'h';
      when 'I'    => return 'i'; when 'J' => return 'j'; when 'K' => return 'k'; when 'L' => return 'l';
      when 'M'    => return 'm'; when 'N' => return 'n'; when 'O' => return 'o'; when 'P' => return 'p';
      when 'Q'    => return 'q'; when 'R' => return 'r'; when 'S' => return 's'; when 'T' => return 't';
      when 'U'    => return 'u'; when 'V' => return 'v'; when 'W' => return 'w'; when 'X' => return 'x';
      when 'Y'    => return 'y'; when 'Z' => return 'z';
      when others => return char;
    end case;
  end LowerCase_Char;

  function LowerCase_String (s : string) return string is
    variable res : string(s'range);
  begin  -- function LowerCase_String
    for I in s'range loop
      res(I) := LowerCase_Char(s(I));
    end loop;  -- I
    return res;
  end function LowerCase_String;

  -- Returns true if case insensitive string comparison determines that
  -- str1 and str2 are equal
  function Equal_String( str1, str2 : STRING ) RETURN BOOLEAN IS
    CONSTANT len1 : INTEGER := str1'length;
    CONSTANT len2 : INTEGER := str2'length;
    VARIABLE equal : BOOLEAN := TRUE;
  BEGIN
    IF NOT (len1=len2) THEN
      equal := FALSE;
    ELSE
      FOR i IN str1'range LOOP
        IF NOT (LowerCase_Char(str1(i)) = LowerCase_Char(str2(i))) THEN
          equal := FALSE;
        END IF;
      END LOOP;
    END IF;

    RETURN equal;
  END Equal_String;

  function String_To_Family (S : string; Select_RTL : boolean) return TARGET_FAMILY_TYPE is
  begin  -- function String_To_Family
    if ((Select_RTL) or Equal_String(S, "rtl")) then
      return RTL;
    elsif Equal_String(S, "virtex7") or Equal_String(S, "qvirtex7") then
      return VIRTEX7;
    elsif Equal_String(S, "kintex7")  or Equal_String(S, "kintex7l")  or
          Equal_String(S, "qkintex7") or Equal_String(S, "qkintex7l") then
      return KINTEX7;
    elsif Equal_String(S, "artix7")  or Equal_String(S, "artix7l")  or Equal_String(S, "aartix7") or
          Equal_String(S, "qartix7") or Equal_String(S, "qartix7l") then
      return ARTIX7;
    elsif Equal_String(S, "zynq")  or Equal_String(S, "azynq") or Equal_String(S, "qzynq") then
      return ZYNQ;
    elsif Equal_String(S, "virtexu") or Equal_String(S, "qvirtexu") then
      return VIRTEXU;
    elsif Equal_String(S, "kintexu")  or Equal_String(S, "kintexul")  or
          Equal_String(S, "qkintexu") or Equal_String(S, "qkintexul") then
      return KINTEXU;
    elsif Equal_String(S, "zynque") then
      return ZYNQUE;
    elsif Equal_String(S, "virtexum") then
      return VIRTEXUM;
    elsif Equal_String(S, "kintexum") then
      return KINTEXUM;
    else
      assert (false) report "No known target family" severity failure;
      return RTL;
    end if;
  end function String_To_Family;

  function Family_To_LUT_Size(Family : TARGET_FAMILY_TYPE) return integer is
  begin  -- function String_To_Family
    return 6;
  end function Family_To_LUT_Size;

  function Has_Target(Family : TARGET_FAMILY_TYPE; TARGET_PROP : TARGET_PROPERTY_TYPE) return boolean is
  begin
    case TARGET_PROP is
      when LATCH_AS_LOGIC        => return (Family = VIRTEX7)    or
                                           (Family = KINTEX7)    or (Family = ARTIX7)   or (Family = ZYNQ)    or
                                           (Family = VIRTEXU)    or (Family = KINTEXU)  or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM);

      when DUAL_DFF              => return (Family = VIRTEX7)    or
                                           (Family = KINTEX7)    or (Family = ARTIX7)   or (Family = ZYNQ)    or
                                           (Family = VIRTEXU)    or (Family = KINTEXU)  or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM);

      when BRAM_WITH_BYTE_ENABLE => return (Family = VIRTEX7)    or (Family = KINTEX7)  or (Family = ARTIX7)  or 
                                           (Family = ZYNQ)       or (Family = VIRTEXU)  or (Family = KINTEXU) or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM);

      when BRAM_36k              => return (Family = VIRTEX7)    or
                                           (Family = KINTEX7)    or (Family = ARTIX7)   or (Family = ZYNQ)     or
                                           (Family = VIRTEXU)    or (Family = KINTEXU)  or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM) or
                                           (Family = RTL);

      when BRAM_16K_WE           => return false;
      when DSP                   => return (Family = VIRTEX7)    or
                                           (Family = KINTEX7)    or (Family = ARTIX7)   or (Family = ZYNQ)    or
                                           (Family = VIRTEXU)    or (Family = KINTEXU)  or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM);
      when DSP48_V4              => return false;
      when DSP48_A               => return false;
      when DSP48_E               => return (Family = VIRTEX7)    or
                                           (Family = KINTEX7)    or (Family = ARTIX7)   or (Family = ZYNQ)    or
                                           (Family = VIRTEXU)    or (Family = KINTEXU)  or
                                           (Family = ZYNQUE)     or (Family = VIRTEXUM) or (Family = KINTEXUM);

      when others                => return false;
    end case;
  end function Has_Target;
  
  
  -----------------------------------------------------------------------------
  -- System Cache Specific Functions
  -----------------------------------------------------------------------------
  
  -- Translate port vector to natural.
  function get_port_num(signal x : std_logic_vector(4 downto 0); constant y : natural) return natural is
    constant z : natural:= log2(y);
  begin 
    if( y = 1 ) then
      return 0;
    else
      return to_integer(unsigned(x(z-1 downto 0)));
    end if;
  end function get_port_num;
  
  
  -- Getnumber of common address bits.
  function Addr_Bits (x, y : std_logic_vector(0 to 63);
                      z    : natural) return natural is
    variable addr_xor : std_logic_vector(0 to 63);
  begin
    addr_xor := x xor y;
    if addr_xor(0) = '1' then
      return 1;
    end if;
    for i in 0 to 63 loop
      if addr_xor(i) = '1' then return i;
      end if;
    end loop;
    
    return 32;
  end function Addr_Bits;
  
  
  function To_StdVec(from : ARBITRATION_TYPE) return std_logic_vector is
  begin
    return from.Size &  from.Domain &  from.Barrier & from.Snoop & from.Prot & from.Ignore_Data & from.Evict & 
           from.Bufferable &  from.Allocate &  from.Exclusive & from.Kind &  from.Len &  from.Addr &  
           from.Port_Num &  from.Wr & from.Valid;
  end function To_StdVec;
  
  
  function To_StdVec(from : ACCESS_TYPE) return std_logic_vector is
  begin
    return from.Size &  from.Len &  from.Addr & from.Wr &  from.Kind &  
           from.Evict &  from.Exclusive & from.Allocate & from.Port_Num;
  end function To_StdVec;
  
  
  function To_StdVec(from : STAT_POINT_TYPE) return std_logic_vector is
  begin
    return from.Sum_2 &  from.Sum & from.Min_Max_Status & from.Events;
  end function To_StdVec;
  
  function To_StdVec(from : STAT_FIFO_TYPE) return std_logic_vector is
  begin
    return from.Index_Sum &  from.Index_Max & from.Index_Updates & from.Empty_Cycles;
  end function To_StdVec;
  
  
  function Stat_Get_Register(from : STAT_VECTOR_TYPE; 
                             idx  : natural) return STAT_TYPE is
  begin
    return from(idx);
  end function Stat_Get_Register;
                             
                             
  function Stat_Point_Get_Register(from : STAT_POINT_TYPE; 
                                   idx : natural range 0 to 7) return STAT_TYPE is
  begin
    case idx is
      when C_STAT_POINT_EVENTS =>
        return from.Events;
      when C_STAT_POINT_MIN_MAX_STATUS =>
        return from.Min_Max_Status;
      when C_STAT_POINT_SUM =>
        return from.Sum;
      when others =>
        return from.Sum_2;
    end case;
  end function Stat_Point_Get_Register;
  
  
  function Stat_FIFO_Get_Register(from : STAT_FIFO_TYPE; 
                                  idx : natural range 0 to 7) return STAT_TYPE is
  begin
    case idx is
      when C_STAT_FIFO_EMPTY_CYCLES =>
        return from.Empty_Cycles;
      when C_STAT_FIFO_INDEX_UPDATES =>
        return from.Index_Updates;
      when C_STAT_FIFO_INDEX_MAX =>
        return from.Index_Max;
      when others =>
        return from.Index_Sum;
    end case;
  end function Stat_FIFO_Get_Register;
  
  
  function Stat_Conf_Get_Register(from : STAT_CONF_VECTOR_TYPE; 
                                  idx  : natural) return STAT_TYPE is
  begin
    return Stat_Conf_Get_Register(from(idx));
  end function Stat_Conf_Get_Register;
  
  
  function Stat_Conf_Get_Register(from : STAT_CONF_TYPE) return STAT_TYPE is
    variable tmp : STAT_TYPE:= (others=>'0');
  begin
    tmp := (others=>'0');
    tmp(min_of(C_MAX_STAT_WIDTH, C_MAX_STAT_CONF_WIDTH) - 1 downto 0) := 
                            from(min_of(C_MAX_STAT_WIDTH, C_MAX_STAT_CONF_WIDTH) - 1 downto 0);
    return tmp;
  end function Stat_Conf_Get_Register;
  
  function Stat_Conf_Set_Register(from : std_logic_vector; 
                                  w    : natural) return STAT_CONF_TYPE is
    variable tmp : STAT_CONF_TYPE:= (others=>'0');
  begin
    tmp := (others=>'0');
    tmp(min_of(w, C_MAX_STAT_CONF_WIDTH) - 1 downto 0) := from(min_of(w, C_MAX_STAT_CONF_WIDTH) - 1 downto 0);
    return tmp;
  end function Stat_Conf_Set_Register;

  
  function Stat_Get_Register_32bit(from : STAT_VECTOR_TYPE; 
                                   idx  : natural;
                                   word : natural range 0 to 1) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_Get_Register(from, idx);
    
    if( word = 0 ) then
      return tmp(31 downto  0);
    else
      return tmp(63 downto 32);
    end if;
  end function Stat_Get_Register_32bit;
  
  function Stat_Get_Register_64bit(from : STAT_VECTOR_TYPE; 
                                   idx  : natural) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_Get_Register(from, idx);
    
    return tmp;
  end function Stat_Get_Register_64bit;
  
  
  function Stat_Point_Get_Register_32bit(from : STAT_POINT_TYPE; 
                                         idx  : natural range 0 to 7;
                                         word : natural range 0 to 1) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_Point_Get_Register(from, idx);
    
    if( word = 0 ) then
      return tmp(31 downto  0);
    else
      return tmp(63 downto 32);
    end if;
  end function Stat_Point_Get_Register_32bit;
  
  function Stat_Point_Get_Register_64bit(from : STAT_POINT_TYPE; 
                                         idx  : natural range 0 to 7) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_Point_Get_Register(from, idx);
    
    return tmp;
  end function Stat_Point_Get_Register_64bit;
  
  
  function Stat_FIFO_Get_Register_32bit(from  : STAT_FIFO_TYPE; 
                                        idx   : natural range 0 to 7;
                                        word  : natural range 0 to 1) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_FIFO_Get_Register(from, idx);
    
    if( word = 0 ) then
      return tmp(31 downto  0);
    else
      return tmp(63 downto 32);
    end if;
  end function Stat_FIFO_Get_Register_32bit;
  
  function Stat_FIFO_Get_Register_64bit(from  : STAT_FIFO_TYPE; 
                                        idx   : natural range 0 to 7) return std_logic_vector is
    variable tmp : std_logic_vector(63 downto 0):= (others=>'0');
  begin
    tmp(C_MAX_STAT_WIDTH - 1 downto 0) := Stat_FIFO_Get_Register(from, idx);
    
    return tmp;
  end function Stat_FIFO_Get_Register_64bit;
  

end package body system_cache_pkg;








library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.system_cache_pkg.all;


package system_cache_queue_pkg is

  -----------------------------------------------------------------------------
  -- System Cache Queue Specific Constants
  -----------------------------------------------------------------------------
  
  
  -- ----------------------------------------
  -- Types for Queue.
  
  constant C_QUEUE_LENGTH             : integer:= 16;
  constant C_QUEUE_LENGTH_BITS        : integer:= log2(C_QUEUE_LENGTH);
  subtype QUEUE_ADDR_POS              is natural range C_QUEUE_LENGTH - 1 downto 0;
  subtype QUEUE_ADDR_TYPE             is std_logic_vector(C_QUEUE_LENGTH_BITS - 1 downto 0);
  
  constant C_QUEUE_ALMOST_EMPTY       : QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(0, 
                                                                                        C_QUEUE_LENGTH_BITS));
  constant C_QUEUE_EMPTY              : QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 1, 
                                                                                        C_QUEUE_LENGTH_BITS));
  constant C_QUEUE_ALMOST_FULL        : QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 3, 
                                                                                        C_QUEUE_LENGTH_BITS));
  constant C_QUEUE_FULL               : QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 2, 
                                                                                        C_QUEUE_LENGTH_BITS));
  
  constant C_BIG_QUEUE_LENGTH         : integer:= 32;
  constant C_BIG_QUEUE_LENGTH_BITS    : integer:= log2(C_BIG_QUEUE_LENGTH);
  subtype BIG_QUEUE_ADDR_POS          is natural range C_BIG_QUEUE_LENGTH - 1 downto 0;
  subtype BIG_QUEUE_ADDR_TYPE         is std_logic_vector(C_BIG_QUEUE_LENGTH_BITS - 1 downto 0);
  
  constant C_BIG_QUEUE_ALMOST_EMPTY   : BIG_QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(0, 
                                                                                            C_BIG_QUEUE_LENGTH_BITS));
  constant C_BIG_QUEUE_EMPTY          : BIG_QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 1, 
                                                                                            C_BIG_QUEUE_LENGTH_BITS));
  constant C_BIG_QUEUE_ALMOST_FULL    : BIG_QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 3, 
                                                                                            C_BIG_QUEUE_LENGTH_BITS));
  constant C_BIG_QUEUE_FULL           : BIG_QUEUE_ADDR_TYPE := std_logic_vector(to_unsigned(C_QUEUE_LENGTH - 2, 
                                                                                            C_BIG_QUEUE_LENGTH_BITS));

  
end package system_cache_queue_pkg;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.system_cache_pkg.all;

package body system_cache_queue_pkg is

end package body system_cache_queue_pkg;
