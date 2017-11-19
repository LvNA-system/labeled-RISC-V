
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
set scripts_vivado_version 2017.3
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
   create_project project_1 myproj -part xc7z020clg484-1
   set_property BOARD_PART em.avnet.com:zed:part0:1.3 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
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

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_dwidth_converter:2.1\
xilinx.com:ip:axi_protocol_converter:2.1\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:xlslice:1.0\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
rocketchip_top\
"

   set list_mods_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_msg_id "BD_TCL-008" "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

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
  set M_AXILITE_MMIO [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXILITE_MMIO ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $M_AXILITE_MMIO
  set M_AXI_MEM [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MEM ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.PROTOCOL {AXI4} \
   ] $M_AXI_MEM

  # Create ports
  set coreclk [ create_bd_port -dir I coreclk ]
  set corersts [ create_bd_port -dir I -from 1 -to 0 corersts ]
  set uncore_rstn [ create_bd_port -dir I -from 0 -to 0 -type rst uncore_rstn ]
  set uncoreclk [ create_bd_port -dir I -type clk uncoreclk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {50000000} \
 ] $uncoreclk

  # Create instance: axi_dwidth_converter_0, and set properties
  set axi_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0 ]

  # Create instance: axi_protocol_converter_0, and set properties
  set axi_protocol_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_converter_0 ]

  # Create instance: ila_core0, and set properties
  set ila_core0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_core0 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU {false} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {12} \
   CONFIG.C_PROBE0_WIDTH {2} \
   CONFIG.C_PROBE10_WIDTH {5} \
   CONFIG.C_PROBE11_WIDTH {64} \
   CONFIG.C_PROBE1_WIDTH {32} \
   CONFIG.C_PROBE2_MU_CNT {2} \
   CONFIG.C_PROBE2_WIDTH {40} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE6_WIDTH {5} \
   CONFIG.C_PROBE7_WIDTH {64} \
   CONFIG.C_PROBE8_WIDTH {5} \
   CONFIG.C_PROBE9_WIDTH {64} \
 ] $ila_core0

  # Create instance: ila_core1, and set properties
  set ila_core1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_core1 ]
  set_property -dict [ list \
   CONFIG.ALL_PROBE_SAME_MU {false} \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_INPUT_PIPE_STAGES {2} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {12} \
   CONFIG.C_PROBE0_WIDTH {2} \
   CONFIG.C_PROBE10_WIDTH {5} \
   CONFIG.C_PROBE11_WIDTH {64} \
   CONFIG.C_PROBE1_WIDTH {32} \
   CONFIG.C_PROBE2_MU_CNT {2} \
   CONFIG.C_PROBE2_WIDTH {40} \
   CONFIG.C_PROBE4_WIDTH {32} \
   CONFIG.C_PROBE6_WIDTH {5} \
   CONFIG.C_PROBE7_WIDTH {64} \
   CONFIG.C_PROBE8_WIDTH {5} \
   CONFIG.C_PROBE9_WIDTH {64} \
 ] $ila_core1

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

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
  
  set_property -dict [ list \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
 ] [get_bd_intf_pins /rocketchip_top_0/M_AXI_CDMA]

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /rocketchip_top_0/M_AXI_MEM]

  set_property -dict [ list \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.MAX_BURST_LENGTH {256} \
 ] [get_bd_intf_pins /rocketchip_top_0/M_AXI_MMIO]

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

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {2} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {2} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create interface connections
  connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins axi_protocol_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_ports M_AXILITE_MMIO] [get_bd_intf_pins axi_protocol_converter_0/M_AXI]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MEM [get_bd_intf_ports M_AXI_MEM] [get_bd_intf_pins rocketchip_top_0/M_AXI_MEM]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MMIO [get_bd_intf_pins axi_dwidth_converter_0/S_AXI] [get_bd_intf_pins rocketchip_top_0/M_AXI_MMIO]

  # Create port connections
  connect_bd_net -net clk_1 [get_bd_ports uncoreclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_protocol_converter_0/aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins rocketchip_top_0/io_debug_clk0] [get_bd_pins rocketchip_top_0/uncoreclk]
  connect_bd_net -net coreclk_1 [get_bd_ports coreclk] [get_bd_pins ila_core0/clk] [get_bd_pins ila_core1/clk] [get_bd_pins rocketchip_top_0/coreclk0] [get_bd_pins rocketchip_top_0/coreclk1]
  connect_bd_net -net corerst0_1 [get_bd_pins rocketchip_top_0/corerst0] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net corersts_1 [get_bd_ports corersts] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din]
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
  connect_bd_net -net rocketchip_top_0_io_ila_1_csr_time [get_bd_pins ila_core1/probe1] [get_bd_pins rocketchip_top_0/io_ila_1_csr_time]
  connect_bd_net -net rocketchip_top_0_io_ila_1_hartid [get_bd_pins ila_core1/probe0] [get_bd_pins rocketchip_top_0/io_ila_1_hartid]
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
  connect_bd_net -net s_axi_aresetn1_1 [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_protocol_converter_0/aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net uncore_rstn_1 [get_bd_ports uncore_rstn] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins proc_sys_reset_0/mb_reset] [get_bd_pins rocketchip_top_0/io_debug_rst0] [get_bd_pins rocketchip_top_0/uncorerst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins rocketchip_top_0/io_interrupts] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins rocketchip_top_0/L1enable] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlslice_1_Dout [get_bd_pins rocketchip_top_0/corerst1] [get_bd_pins xlslice_1/Dout]

  # Create address segments
  create_bd_addr_seg -range 0x20000000 -offset 0x60000000 [get_bd_addr_spaces rocketchip_top_0/M_AXI_MMIO] [get_bd_addr_segs M_AXILITE_MMIO/Reg] SEG_M_AXILITE_MMIO_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces rocketchip_top_0/M_AXI_MEM] [get_bd_addr_segs M_AXI_MEM/Reg] SEG_M_AXI_MEM_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


