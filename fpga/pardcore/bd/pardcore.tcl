
################################################################
# This is a generated script based on design: pardcore
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2016.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source pardcore_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# rocketchip_top

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7vx690tffg1761-2
   set_property BOARD_PART xilinx.com:vc709:part0:1.8 [current_project]
}


# CHANGE DESIGN NAME HERE
set design_name pardcore

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set M_AXI_MEM [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MEM ]
  set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.DATA_WIDTH {64} \
CONFIG.FREQ_HZ {50000000} \
CONFIG.PROTOCOL {AXI4} \
 ] $M_AXI_MEM
  set UART0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART0 ]
  set UART1 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART1 ]

  # Create ports
  set coreclk [ create_bd_port -dir I coreclk ]
  set corerst0 [ create_bd_port -dir I -type rst corerst0 ]
  set interconnect_rstn [ create_bd_port -dir I -from 0 -to 0 -type rst interconnect_rstn ]
  set uncore_rstn [ create_bd_port -dir I -from 0 -to 0 -type rst uncore_rstn ]
  set uncoreclk [ create_bd_port -dir I -type clk uncoreclk ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {50000000} \
 ] $uncoreclk

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.M00_A00_ADDR_WIDTH {16} \
CONFIG.M00_A00_BASE_ADDR {0x0000000060000000} \
CONFIG.M01_A00_ADDR_WIDTH {16} \
CONFIG.M01_A00_BASE_ADDR {0x0000000060010000} \
 ] $axi_crossbar_0

  # Create instance: axi_dwidth_converter_0, and set properties
  set axi_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0 ]

  # Create instance: axi_protocol_converter_0, and set properties
  set axi_protocol_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_converter_0 ]

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {50000000} \
CONFIG.UARTLITE_BOARD_INTERFACE {Custom} \
 ] $axi_uartlite_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_0

  # Create instance: axi_uartlite_1, and set properties
  set axi_uartlite_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_1 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {50000000} \
 ] $axi_uartlite_1

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_1

  # Create instance: ila_core0, and set properties
  set ila_core0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.1 ila_core0 ]
  set_property -dict [ list \
CONFIG.C_DATA_DEPTH {4096} \
CONFIG.C_ENABLE_ILA_AXI_MON {false} \
CONFIG.C_INPUT_PIPE_STAGES {2} \
CONFIG.C_MONITOR_TYPE {Native} \
CONFIG.C_NUM_OF_PROBES {12} \
CONFIG.C_PROBE0_WIDTH {2} \
CONFIG.C_PROBE10_WIDTH {5} \
CONFIG.C_PROBE11_WIDTH {64} \
CONFIG.C_PROBE1_WIDTH {32} \
CONFIG.C_PROBE2_WIDTH {40} \
CONFIG.C_PROBE4_WIDTH {32} \
CONFIG.C_PROBE6_WIDTH {5} \
CONFIG.C_PROBE7_WIDTH {64} \
CONFIG.C_PROBE8_WIDTH {5} \
CONFIG.C_PROBE9_WIDTH {64} \
 ] $ila_core0

  # Create instance: ila_core1, and set properties
  set ila_core1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.1 ila_core1 ]
  set_property -dict [ list \
CONFIG.C_DATA_DEPTH {4096} \
CONFIG.C_ENABLE_ILA_AXI_MON {false} \
CONFIG.C_INPUT_PIPE_STAGES {2} \
CONFIG.C_MONITOR_TYPE {Native} \
CONFIG.C_NUM_OF_PROBES {12} \
CONFIG.C_PROBE0_WIDTH {2} \
CONFIG.C_PROBE10_WIDTH {5} \
CONFIG.C_PROBE11_WIDTH {64} \
CONFIG.C_PROBE1_WIDTH {32} \
CONFIG.C_PROBE2_WIDTH {40} \
CONFIG.C_PROBE4_WIDTH {32} \
CONFIG.C_PROBE6_WIDTH {5} \
CONFIG.C_PROBE7_WIDTH {64} \
CONFIG.C_PROBE8_WIDTH {5} \
CONFIG.C_PROBE9_WIDTH {64} \
 ] $ila_core1

  # Create instance: rocketchip_top_0, and set properties
  set block_name rocketchip_top
  set block_cell_name rocketchip_top_0
  if { [catch {set rocketchip_top_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $rocketchip_top_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {not} \
CONFIG.C_SIZE {1} \
CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {2} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {3} \
CONFIG.CONST_WIDTH {3} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_ports UART1] [get_bd_intf_pins axi_uartlite_1/UART]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M01_AXI [get_bd_intf_pins axi_crossbar_0/M01_AXI] [get_bd_intf_pins axi_uartlite_1/S_AXI]
  connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins axi_protocol_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_pins axi_crossbar_0/S00_AXI] [get_bd_intf_pins axi_protocol_converter_0/M_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports UART0] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MEM [get_bd_intf_ports M_AXI_MEM] [get_bd_intf_pins rocketchip_top_0/M_AXI_MEM]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MMIO [get_bd_intf_pins axi_dwidth_converter_0/S_AXI] [get_bd_intf_pins rocketchip_top_0/M_AXI_MMIO]

  # Create port connections
  connect_bd_net -net clk_1 [get_bd_ports uncoreclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_protocol_converter_0/aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_uartlite_1/s_axi_aclk] [get_bd_pins rocketchip_top_0/uncoreclk]
  connect_bd_net -net coreclk_1 [get_bd_ports coreclk] [get_bd_pins ila_core0/clk] [get_bd_pins ila_core1/clk] [get_bd_pins rocketchip_top_0/coreclk0] [get_bd_pins rocketchip_top_0/coreclk1] [get_bd_pins rocketchip_top_0/io_debug_clk0]
  connect_bd_net -net corerst0_1 [get_bd_ports corerst0] [get_bd_pins rocketchip_top_0/corerst0] [get_bd_pins rocketchip_top_0/io_debug_rst0]
  connect_bd_net -net rocketchip_top_0_ila_1_csr_time [get_bd_pins ila_core1/probe1] [get_bd_pins rocketchip_top_0/io_ila_1_csr_time]
  connect_bd_net -net rocketchip_top_0_ila_1_hartid [get_bd_pins ila_core1/probe0] [get_bd_pins rocketchip_top_0/io_ila_1_hartid]
  connect_bd_net -net rocketchip_top_0_io_ila_0_csr_time [get_bd_pins ila_core0/probe1] [get_bd_pins rocketchip_top_0/io_ila_0_csr_time]
  connect_bd_net -net rocketchip_top_0_io_ila_0_hartid [get_bd_pins ila_core0/probe0] [get_bd_pins rocketchip_top_0/io_ila_0_hartid]
  connect_bd_net -net rocketchip_top_0_io_ila_0_instr [get_bd_pins ila_core0/probe4] [get_bd_pins rocketchip_top_0/io_ila_0_instr]
  connect_bd_net -net rocketchip_top_0_io_ila_0_instr_valid [get_bd_pins ila_core0/probe3] [get_bd_pins rocketchip_top_0/io_ila_0_instr_valid]
  connect_bd_net -net rocketchip_top_0_io_ila_0_pc [get_bd_pins ila_core0/probe2] [get_bd_pins rocketchip_top_0/io_ila_0_pc]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rd_waddr [get_bd_pins ila_core0/probe6] [get_bd_pins rocketchip_top_0/io_ila_0_rd_waddr]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rd_wdata [get_bd_pins ila_core0/probe7] [get_bd_pins rocketchip_top_0/io_ila_0_rd_wdata]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rd_wen [get_bd_pins ila_core0/probe5] [get_bd_pins rocketchip_top_0/io_ila_0_rd_wen]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rs_raddr [get_bd_pins ila_core0/probe8] [get_bd_pins rocketchip_top_0/io_ila_0_rs_raddr]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rs_rdata [get_bd_pins ila_core0/probe9] [get_bd_pins rocketchip_top_0/io_ila_0_rs_rdata]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rt_raddr [get_bd_pins ila_core0/probe10] [get_bd_pins rocketchip_top_0/io_ila_0_rt_raddr]
  connect_bd_net -net rocketchip_top_0_io_ila_0_rt_rdata [get_bd_pins ila_core0/probe11] [get_bd_pins rocketchip_top_0/io_ila_0_rt_rdata]
  connect_bd_net -net rocketchip_top_0_io_ila_1_instr [get_bd_pins ila_core1/probe4] [get_bd_pins rocketchip_top_0/io_ila_1_instr]
  connect_bd_net -net rocketchip_top_0_io_ila_1_instr_valid [get_bd_pins ila_core1/probe3] [get_bd_pins rocketchip_top_0/io_ila_1_instr_valid]
  connect_bd_net -net rocketchip_top_0_io_ila_1_pc [get_bd_pins ila_core1/probe2] [get_bd_pins rocketchip_top_0/io_ila_1_pc]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rd_waddr [get_bd_pins ila_core1/probe6] [get_bd_pins rocketchip_top_0/io_ila_1_rd_waddr]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rd_wdata [get_bd_pins ila_core1/probe7] [get_bd_pins rocketchip_top_0/io_ila_1_rd_wdata]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rd_wen [get_bd_pins ila_core1/probe5] [get_bd_pins rocketchip_top_0/io_ila_1_rd_wen]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rs_raddr [get_bd_pins ila_core1/probe8] [get_bd_pins rocketchip_top_0/io_ila_1_rs_raddr]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rs_rdata [get_bd_pins ila_core1/probe9] [get_bd_pins rocketchip_top_0/io_ila_1_rs_rdata]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rt_raddr [get_bd_pins ila_core1/probe10] [get_bd_pins rocketchip_top_0/io_ila_1_rt_raddr]
  connect_bd_net -net rocketchip_top_0_io_ila_1_rt_rdata [get_bd_pins ila_core1/probe11] [get_bd_pins rocketchip_top_0/io_ila_1_rt_rdata]
  connect_bd_net -net s_axi_aresetn1_1 [get_bd_ports interconnect_rstn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_protocol_converter_0/aresetn] [get_bd_pins axi_uartlite_1/s_axi_aresetn] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_ports uncore_rstn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins rocketchip_top_0/uncorerst] [get_bd_pins util_vector_logic_0/Res]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins rocketchip_top_0/io_interrupts] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins rocketchip_top_0/L1enable] [get_bd_pins xlconstant_1/dout]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces rocketchip_top_0/M_AXI_MEM] [get_bd_addr_segs M_AXI_MEM/Reg] SEG_M_AXI_MEM_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x60000000 [get_bd_addr_spaces rocketchip_top_0/M_AXI_MMIO] [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x60010000 [get_bd_addr_spaces rocketchip_top_0/M_AXI_MMIO] [get_bd_addr_segs axi_uartlite_1/S_AXI/Reg] SEG_axi_uartlite_1_Reg

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port corerst0 -pg 1 -y 340 -defaultsOSRD
preplace port uncoreclk -pg 1 -y 440 -defaultsOSRD
preplace port UART0 -pg 1 -y 220 -defaultsOSRD
preplace port UART1 -pg 1 -y 60 -defaultsOSRD
preplace port coreclk -pg 1 -y 320 -defaultsOSRD
preplace port M_AXI_MEM -pg 1 -y 90 -defaultsOSRD
preplace portBus interconnect_rstn -pg 1 -y 490 -defaultsOSRD
preplace portBus uncore_rstn -pg 1 -y 720 -defaultsOSRD
preplace inst xlconstant_0 -pg 1 -lvl 1 -y 580 -defaultsOSRD
preplace inst xlconstant_1 -pg 1 -lvl 1 -y 390 -defaultsOSRD
preplace inst axi_protocol_converter_0 -pg 1 -lvl 4 -y 210 -defaultsOSRD
preplace inst axi_crossbar_0 -pg 1 -lvl 5 -y 220 -defaultsOSRD
preplace inst axi_dwidth_converter_0 -pg 1 -lvl 3 -y 210 -defaultsOSRD
preplace inst rocketchip_top_0 -pg 1 -lvl 2 -y 390 -defaultsOSRD
preplace inst util_vector_logic_0 -pg 1 -lvl 1 -y 490 -defaultsOSRD
preplace inst ila_core0 -pg 1 -lvl 4 -y 880 -defaultsOSRD
preplace inst ila_core1 -pg 1 -lvl 4 -y 520 -defaultsOSRD
preplace inst axi_uartlite_0 -pg 1 -lvl 6 -y 230 -defaultsOSRD
preplace inst axi_uartlite_1 -pg 1 -lvl 6 -y 70 -defaultsOSRD
preplace netloc xlconstant_1_dout 1 1 1 NJ
preplace netloc rocketchip_top_0_io_ila_1_pc 1 2 2 N 460 NJ
preplace netloc rocketchip_top_0_io_ila_1_instr 1 2 2 N 500 NJ
preplace netloc rocketchip_top_0_io_ila_0_rt_raddr 1 2 2 N 380 NJ
preplace netloc rocketchip_top_0_io_ila_0_rs_rdata 1 2 2 N 360 NJ
preplace netloc rocketchip_top_0_io_ila_0_rd_wen 1 2 2 N 280 NJ
preplace netloc rocketchip_top_0_io_ila_0_hartid 1 2 2 660 50 NJ
preplace netloc Conn2 1 6 2 NJ 60 NJ
preplace netloc axi_crossbar_0_M00_AXI 1 5 1 N
preplace netloc s_axi_aresetn1_1 1 0 6 20 80 NJ 80 670 70 1260 90 1550 90 NJ
preplace netloc rocketchip_top_0_io_ila_1_rd_wdata 1 2 2 N 560 NJ
preplace netloc rocketchip_top_0_io_ila_0_rd_wdata 1 2 2 N 320 NJ
preplace netloc s_axi_aresetn_1 1 0 6 NJ 40 NJ 40 NJ 40 NJ 40 NJ 150 1820
preplace netloc rocketchip_top_0_io_ila_1_instr_valid 1 2 2 N 480 NJ
preplace netloc rocketchip_top_0_ila_1_hartid 1 2 2 N 420 NJ
preplace netloc rocketchip_top_0_io_ila_1_rs_rdata 1 2 2 N 600 NJ
preplace netloc util_vector_logic_0_Res 1 1 1 NJ
preplace netloc rocketchip_top_0_io_ila_1_rs_raddr 1 2 2 N 580 NJ
preplace netloc rocketchip_top_0_io_ila_0_pc 1 2 2 720 140 NJ
preplace netloc rocketchip_top_0_M_AXI_MEM 1 2 6 690 110 NJ 110 NJ 110 NJ 140 2070 90 NJ
preplace netloc axi_protocol_converter_0_M_AXI 1 4 1 1560
preplace netloc xlconstant_0_dout 1 1 1 NJ
preplace netloc rocketchip_top_0_io_ila_1_rt_rdata 1 2 2 N 640 NJ
preplace netloc rocketchip_top_0_io_ila_1_rd_waddr 1 2 2 N 540 NJ
preplace netloc clk_1 1 0 6 NJ 440 260 90 700 90 1240 140 1540 140 1840
preplace netloc rocketchip_top_0_io_ila_1_rd_wen 1 2 2 N 520 NJ
preplace netloc axi_uartlite_0_UART 1 6 2 NJ 220 NJ
preplace netloc rocketchip_top_0_M_AXI_MMIO 1 2 1 690
preplace netloc rocketchip_top_0_ila_1_csr_time 1 2 2 N 440 NJ
preplace netloc rocketchip_top_0_io_ila_1_rt_raddr 1 2 2 N 620 NJ
preplace netloc rocketchip_top_0_io_ila_0_rs_raddr 1 2 2 N 340 NJ
preplace netloc rocketchip_top_0_io_ila_0_csr_time 1 2 2 680 80 NJ
preplace netloc axi_dwidth_converter_0_M_AXI 1 3 1 1130
preplace netloc rocketchip_top_0_io_ila_0_rt_rdata 1 2 2 N 400 NJ
preplace netloc rocketchip_top_0_io_ila_0_instr_valid 1 2 2 710 100 NJ
preplace netloc axi_crossbar_0_M01_AXI 1 5 1 1830
preplace netloc rocketchip_top_0_io_ila_0_rd_waddr 1 2 2 N 300 NJ
preplace netloc corerst0_1 1 0 2 NJ 340 270
preplace netloc coreclk_1 1 0 4 NJ 320 290 20 NJ 20 1270
preplace netloc rocketchip_top_0_io_ila_0_instr 1 2 2 730 120 NJ
levelinfo -pg 1 -10 140 480 980 1400 1690 1960 2160 2270 -top 0 -bot 1050
",
}

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


