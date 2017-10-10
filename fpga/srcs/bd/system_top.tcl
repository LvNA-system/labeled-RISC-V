
################################################################
# This is a generated script based on design: system_top
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
# source system_top_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# cache_control_plane, cdma_addr, core_control_plane, i2c_switch_top, leds_mux_controller, mig_control_plane, uart_inverter, uart_inverter, xlnx_cache_pard, rocketchip_top, vc709_sfp, axi_reg

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
set design_name system_top

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
# MIG PRJ FILE TCL PROCs
##################################################################

proc write_mig_file_system_top_mig_7series_0_0 { str_mig_prj_filepath } {

   set mig_prj_file [open $str_mig_prj_filepath  w+]

   puts $mig_prj_file {<?xml version='1.0' encoding='UTF-8'?>}
   puts $mig_prj_file {<!-- IMPORTANT: This is an internal file that has been generated by the MIG software. Any direct editing or changes made to this file may result in unpredictable behavior or data corruption. It is strongly advised that users do not edit the contents of this file. Re-run the MIG GUI with the required settings if any of the options provided below need to be altered. -->}
   puts $mig_prj_file {<Project DDR3Count="2" DDR2Count="0" NoOfControllers="2" RLDIICount="0" QDRIIPCount="0" >}
   puts $mig_prj_file {    <ModuleName>system_top_mig_7series_0_0</ModuleName>}
   puts $mig_prj_file {    <dci_inouts_inputs>1</dci_inouts_inputs>}
   puts $mig_prj_file {    <dci_inputs>1</dci_inputs>}
   puts $mig_prj_file {    <Debug_En></Debug_En>}
   puts $mig_prj_file {    <DataDepth_En>1024</DataDepth_En>}
   puts $mig_prj_file {    <LowPower_En>OFF</LowPower_En>}
   puts $mig_prj_file {    <XADC_En>Enabled</XADC_En>}
   puts $mig_prj_file {    <TargetFPGA>xc7vx690t-ffg1761/-2</TargetFPGA>}
   puts $mig_prj_file {    <Version>4.0</Version>}
   puts $mig_prj_file {    <SystemClock>Differential</SystemClock>}
   puts $mig_prj_file {    <ReferenceClock>Use System Clock</ReferenceClock>}
   puts $mig_prj_file {    <SysResetPolarity>ACTIVE HIGH</SysResetPolarity>}
   puts $mig_prj_file {    <BankSelectionFlag>FALSE</BankSelectionFlag>}
   puts $mig_prj_file {    <InternalVref>0</InternalVref>}
   puts $mig_prj_file {    <dci_hr_inouts_inputs>50 Ohms</dci_hr_inouts_inputs>}
   puts $mig_prj_file {    <dci_cascade>0</dci_cascade>}
   puts $mig_prj_file {    <Controller number="0" >}
   puts $mig_prj_file {        <MemoryDevice>DDR3_SDRAM/SODIMMs/MT8KTF51264HZ-1G9</MemoryDevice>}
   puts $mig_prj_file {        <TimePeriod>2500</TimePeriod>}
   puts $mig_prj_file {        <VccAuxIO>1.8V</VccAuxIO>}
   puts $mig_prj_file {        <PHYRatio>2:1</PHYRatio>}
   puts $mig_prj_file {        <InputClkFreq>200</InputClkFreq>}
   puts $mig_prj_file {        <UIExtraClocks>0</UIExtraClocks>}
   puts $mig_prj_file {        <MMCM_VCO>800</MMCM_VCO>}
   puts $mig_prj_file {        <MMCMClkOut0> 1.000</MMCMClkOut0>}
   puts $mig_prj_file {        <MMCMClkOut1>1</MMCMClkOut1>}
   puts $mig_prj_file {        <MMCMClkOut2>1</MMCMClkOut2>}
   puts $mig_prj_file {        <MMCMClkOut3>1</MMCMClkOut3>}
   puts $mig_prj_file {        <MMCMClkOut4>1</MMCMClkOut4>}
   puts $mig_prj_file {        <DataWidth>64</DataWidth>}
   puts $mig_prj_file {        <DeepMemory>1</DeepMemory>}
   puts $mig_prj_file {        <DataMask>1</DataMask>}
   puts $mig_prj_file {        <ECC>Disabled</ECC>}
   puts $mig_prj_file {        <Ordering>Normal</Ordering>}
   puts $mig_prj_file {        <CustomPart>FALSE</CustomPart>}
   puts $mig_prj_file {        <NewPartName></NewPartName>}
   puts $mig_prj_file {        <RowAddress>16</RowAddress>}
   puts $mig_prj_file {        <ColAddress>10</ColAddress>}
   puts $mig_prj_file {        <BankAddress>3</BankAddress>}
   puts $mig_prj_file {        <MemoryVoltage>1.5V</MemoryVoltage>}
   puts $mig_prj_file {        <C0_MEM_SIZE>4294967296</C0_MEM_SIZE>}
   puts $mig_prj_file {        <UserMemoryAddressMap>BANK_ROW_COLUMN</UserMemoryAddressMap>}
   puts $mig_prj_file {        <PinSelection>}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A20" SLEW="" name="ddr3_addr[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="B21" SLEW="" name="ddr3_addr[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="B17" SLEW="" name="ddr3_addr[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A15" SLEW="" name="ddr3_addr[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A21" SLEW="" name="ddr3_addr[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="F17" SLEW="" name="ddr3_addr[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="E17" SLEW="" name="ddr3_addr[15]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="B19" SLEW="" name="ddr3_addr[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C20" SLEW="" name="ddr3_addr[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A19" SLEW="" name="ddr3_addr[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A17" SLEW="" name="ddr3_addr[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A16" SLEW="" name="ddr3_addr[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="D20" SLEW="" name="ddr3_addr[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C18" SLEW="" name="ddr3_addr[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="D17" SLEW="" name="ddr3_addr[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C19" SLEW="" name="ddr3_addr[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="D21" SLEW="" name="ddr3_ba[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C21" SLEW="" name="ddr3_ba[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="D18" SLEW="" name="ddr3_ba[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="K17" SLEW="" name="ddr3_cas_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15" PADName="E18" SLEW="" name="ddr3_ck_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15" PADName="E19" SLEW="" name="ddr3_ck_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="K19" SLEW="" name="ddr3_cke[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="J17" SLEW="" name="ddr3_cs_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="M13" SLEW="" name="ddr3_dm[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="K15" SLEW="" name="ddr3_dm[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="F12" SLEW="" name="ddr3_dm[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="A14" SLEW="" name="ddr3_dm[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C23" SLEW="" name="ddr3_dm[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="D25" SLEW="" name="ddr3_dm[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="C31" SLEW="" name="ddr3_dm[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="F31" SLEW="" name="ddr3_dm[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="N14" SLEW="" name="ddr3_dq[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="H13" SLEW="" name="ddr3_dq[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="J13" SLEW="" name="ddr3_dq[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="L16" SLEW="" name="ddr3_dq[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="L15" SLEW="" name="ddr3_dq[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="H14" SLEW="" name="ddr3_dq[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="J15" SLEW="" name="ddr3_dq[15]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E15" SLEW="" name="ddr3_dq[16]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E13" SLEW="" name="ddr3_dq[17]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F15" SLEW="" name="ddr3_dq[18]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E14" SLEW="" name="ddr3_dq[19]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="N13" SLEW="" name="ddr3_dq[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="G13" SLEW="" name="ddr3_dq[20]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="G12" SLEW="" name="ddr3_dq[21]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F14" SLEW="" name="ddr3_dq[22]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="G14" SLEW="" name="ddr3_dq[23]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B14" SLEW="" name="ddr3_dq[24]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C13" SLEW="" name="ddr3_dq[25]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B16" SLEW="" name="ddr3_dq[26]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D15" SLEW="" name="ddr3_dq[27]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D13" SLEW="" name="ddr3_dq[28]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E12" SLEW="" name="ddr3_dq[29]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="L14" SLEW="" name="ddr3_dq[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C16" SLEW="" name="ddr3_dq[30]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D16" SLEW="" name="ddr3_dq[31]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A24" SLEW="" name="ddr3_dq[32]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B23" SLEW="" name="ddr3_dq[33]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B27" SLEW="" name="ddr3_dq[34]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B26" SLEW="" name="ddr3_dq[35]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A22" SLEW="" name="ddr3_dq[36]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B22" SLEW="" name="ddr3_dq[37]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A25" SLEW="" name="ddr3_dq[38]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C24" SLEW="" name="ddr3_dq[39]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="M14" SLEW="" name="ddr3_dq[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E24" SLEW="" name="ddr3_dq[40]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D23" SLEW="" name="ddr3_dq[41]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D26" SLEW="" name="ddr3_dq[42]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C25" SLEW="" name="ddr3_dq[43]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E23" SLEW="" name="ddr3_dq[44]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D22" SLEW="" name="ddr3_dq[45]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F22" SLEW="" name="ddr3_dq[46]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E22" SLEW="" name="ddr3_dq[47]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A30" SLEW="" name="ddr3_dq[48]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D27" SLEW="" name="ddr3_dq[49]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="M12" SLEW="" name="ddr3_dq[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A29" SLEW="" name="ddr3_dq[50]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C28" SLEW="" name="ddr3_dq[51]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D28" SLEW="" name="ddr3_dq[52]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="B31" SLEW="" name="ddr3_dq[53]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A31" SLEW="" name="ddr3_dq[54]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="A32" SLEW="" name="ddr3_dq[55]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E30" SLEW="" name="ddr3_dq[56]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F29" SLEW="" name="ddr3_dq[57]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F30" SLEW="" name="ddr3_dq[58]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F27" SLEW="" name="ddr3_dq[59]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="N15" SLEW="" name="ddr3_dq[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="C30" SLEW="" name="ddr3_dq[60]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="E29" SLEW="" name="ddr3_dq[61]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="F26" SLEW="" name="ddr3_dq[62]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="D30" SLEW="" name="ddr3_dq[63]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="M11" SLEW="" name="ddr3_dq[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="L12" SLEW="" name="ddr3_dq[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="K14" SLEW="" name="ddr3_dq[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="K13" SLEW="" name="ddr3_dq[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="M16" SLEW="" name="ddr3_dqs_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="J12" SLEW="" name="ddr3_dqs_n[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="G16" SLEW="" name="ddr3_dqs_n[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="C14" SLEW="" name="ddr3_dqs_n[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="A27" SLEW="" name="ddr3_dqs_n[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="E25" SLEW="" name="ddr3_dqs_n[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="B29" SLEW="" name="ddr3_dqs_n[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="E28" SLEW="" name="ddr3_dqs_n[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="N16" SLEW="" name="ddr3_dqs_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="K12" SLEW="" name="ddr3_dqs_p[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="H16" SLEW="" name="ddr3_dqs_p[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="C15" SLEW="" name="ddr3_dqs_p[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="A26" SLEW="" name="ddr3_dqs_p[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="F25" SLEW="" name="ddr3_dqs_p[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="B28" SLEW="" name="ddr3_dqs_p[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="E27" SLEW="" name="ddr3_dqs_p[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="H20" SLEW="" name="ddr3_odt[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="E20" SLEW="" name="ddr3_ras_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="LVCMOS15" PADName="P18" SLEW="" name="ddr3_reset_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="F20" SLEW="" name="ddr3_we_n" IN_TERM="" />}
   puts $mig_prj_file {        </PinSelection>}
   puts $mig_prj_file {        <System_Clock>}
   puts $mig_prj_file {            <Pin PADName="H19/G18(CC_P/N)" Bank="38" name="c0_sys_clk_p/n" />}
   puts $mig_prj_file {        </System_Clock>}
   puts $mig_prj_file {        <System_Control>}
   puts $mig_prj_file {            <Pin PADName="AV40(MRCC_P)" Bank="15" name="sys_rst" />}
   puts $mig_prj_file {            <Pin PADName="No connect" Bank="Select Bank" name="init_calib_complete" />}
   puts $mig_prj_file {            <Pin PADName="No connect" Bank="Select Bank" name="tg_compare_error" />}
   puts $mig_prj_file {        </System_Control>}
   puts $mig_prj_file {        <TimingParameters>}
   puts $mig_prj_file {            <Parameters twtr="7.5" trrd="5" trefi="7.8" tfaw="27" trtp="7.5" tcke="5" trfc="260" trp="13.91" tras="34" trcd="13.91" />}
   puts $mig_prj_file {        </TimingParameters>}
   puts $mig_prj_file {        <mrBurstLength name="Burst Length" >8 - Fixed</mrBurstLength>}
   puts $mig_prj_file {        <mrBurstType name="Read Burst Type and Length" >Sequential</mrBurstType>}
   puts $mig_prj_file {        <mrCasLatency name="CAS Latency" >6</mrCasLatency>}
   puts $mig_prj_file {        <mrMode name="Mode" >Normal</mrMode>}
   puts $mig_prj_file {        <mrDllReset name="DLL Reset" >No</mrDllReset>}
   puts $mig_prj_file {        <mrPdMode name="DLL control for precharge PD" >Slow Exit</mrPdMode>}
   puts $mig_prj_file {        <emrDllEnable name="DLL Enable" >Enable</emrDllEnable>}
   puts $mig_prj_file {        <emrOutputDriveStrength name="Output Driver Impedance Control" >RZQ/7</emrOutputDriveStrength>}
   puts $mig_prj_file {        <emrMirrorSelection name="Address Mirroring" >Disable</emrMirrorSelection>}
   puts $mig_prj_file {        <emrCSSelection name="Controller Chip Select Pin" >Enable</emrCSSelection>}
   puts $mig_prj_file {        <emrRTT name="RTT (nominal) - On Die Termination (ODT)" >RZQ/6</emrRTT>}
   puts $mig_prj_file {        <emrPosted name="Additive Latency (AL)" >0</emrPosted>}
   puts $mig_prj_file {        <emrOCD name="Write Leveling Enable" >Disabled</emrOCD>}
   puts $mig_prj_file {        <emrDQS name="TDQS enable" >Enabled</emrDQS>}
   puts $mig_prj_file {        <emrRDQS name="Qoff" >Output Buffer Enabled</emrRDQS>}
   puts $mig_prj_file {        <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh" >Full Array</mr2PartialArraySelfRefresh>}
   puts $mig_prj_file {        <mr2CasWriteLatency name="CAS write latency" >5</mr2CasWriteLatency>}
   puts $mig_prj_file {        <mr2AutoSelfRefresh name="Auto Self Refresh" >Enabled</mr2AutoSelfRefresh>}
   puts $mig_prj_file {        <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate" >Normal</mr2SelfRefreshTempRange>}
   puts $mig_prj_file {        <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)" >Dynamic ODT off</mr2RTTWR>}
   puts $mig_prj_file {        <PortInterface>AXI</PortInterface>}
   puts $mig_prj_file {        <AXIParameters>}
   puts $mig_prj_file {            <C0_C_RD_WR_ARB_ALGORITHM>RD_PRI_REG</C0_C_RD_WR_ARB_ALGORITHM>}
   puts $mig_prj_file {            <C0_S_AXI_ADDR_WIDTH>32</C0_S_AXI_ADDR_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_DATA_WIDTH>32</C0_S_AXI_DATA_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_ID_WIDTH>4</C0_S_AXI_ID_WIDTH>}
   puts $mig_prj_file {            <C0_S_AXI_SUPPORTS_NARROW_BURST>0</C0_S_AXI_SUPPORTS_NARROW_BURST>}
   puts $mig_prj_file {        </AXIParameters>}
   puts $mig_prj_file {    </Controller>}
   puts $mig_prj_file {    <Controller number="1" >}
   puts $mig_prj_file {        <MemoryDevice>DDR3_SDRAM/SODIMMs/MT8KTF51264HZ-1G9</MemoryDevice>}
   puts $mig_prj_file {        <TimePeriod>2500</TimePeriod>}
   puts $mig_prj_file {        <VccAuxIO>1.8V</VccAuxIO>}
   puts $mig_prj_file {        <PHYRatio>4:1</PHYRatio>}
   puts $mig_prj_file {        <InputClkFreq>200</InputClkFreq>}
   puts $mig_prj_file {        <UIExtraClocks>0</UIExtraClocks>}
   puts $mig_prj_file {        <MMCM_VCO>800</MMCM_VCO>}
   puts $mig_prj_file {        <MMCMClkOut0> 1.000</MMCMClkOut0>}
   puts $mig_prj_file {        <MMCMClkOut1>1</MMCMClkOut1>}
   puts $mig_prj_file {        <MMCMClkOut2>1</MMCMClkOut2>}
   puts $mig_prj_file {        <MMCMClkOut3>1</MMCMClkOut3>}
   puts $mig_prj_file {        <MMCMClkOut4>1</MMCMClkOut4>}
   puts $mig_prj_file {        <DataWidth>64</DataWidth>}
   puts $mig_prj_file {        <DeepMemory>1</DeepMemory>}
   puts $mig_prj_file {        <DataMask>1</DataMask>}
   puts $mig_prj_file {        <ECC>Disabled</ECC>}
   puts $mig_prj_file {        <Ordering>Normal</Ordering>}
   puts $mig_prj_file {        <CustomPart>FALSE</CustomPart>}
   puts $mig_prj_file {        <NewPartName></NewPartName>}
   puts $mig_prj_file {        <RowAddress>16</RowAddress>}
   puts $mig_prj_file {        <ColAddress>10</ColAddress>}
   puts $mig_prj_file {        <BankAddress>3</BankAddress>}
   puts $mig_prj_file {        <MemoryVoltage>1.5V</MemoryVoltage>}
   puts $mig_prj_file {        <C1_MEM_SIZE>4294967296</C1_MEM_SIZE>}
   puts $mig_prj_file {        <UserMemoryAddressMap>BANK_ROW_COLUMN</UserMemoryAddressMap>}
   puts $mig_prj_file {        <PinSelection>}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AN19" SLEW="" name="ddr3_addr[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AM17" SLEW="" name="ddr3_addr[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AM18" SLEW="" name="ddr3_addr[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AL17" SLEW="" name="ddr3_addr[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AK17" SLEW="" name="ddr3_addr[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AM19" SLEW="" name="ddr3_addr[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AL19" SLEW="" name="ddr3_addr[15]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AR19" SLEW="" name="ddr3_addr[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AP20" SLEW="" name="ddr3_addr[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AP17" SLEW="" name="ddr3_addr[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AP18" SLEW="" name="ddr3_addr[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AJ18" SLEW="" name="ddr3_addr[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AN16" SLEW="" name="ddr3_addr[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AM16" SLEW="" name="ddr3_addr[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AK18" SLEW="" name="ddr3_addr[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AK19" SLEW="" name="ddr3_addr[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AR17" SLEW="" name="ddr3_ba[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AR18" SLEW="" name="ddr3_ba[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AN18" SLEW="" name="ddr3_ba[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AT20" SLEW="" name="ddr3_cas_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15" PADName="AU17" SLEW="" name="ddr3_ck_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15" PADName="AT17" SLEW="" name="ddr3_ck_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AW17" SLEW="" name="ddr3_cke[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AV16" SLEW="" name="ddr3_cs_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AT22" SLEW="" name="ddr3_dm[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AL22" SLEW="" name="ddr3_dm[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AU24" SLEW="" name="ddr3_dm[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="BB23" SLEW="" name="ddr3_dm[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="BB12" SLEW="" name="ddr3_dm[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AV15" SLEW="" name="ddr3_dm[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AK12" SLEW="" name="ddr3_dm[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AP13" SLEW="" name="ddr3_dm[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AN24" SLEW="" name="ddr3_dq[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AL21" SLEW="" name="ddr3_dq[10]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM21" SLEW="" name="ddr3_dq[11]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ21" SLEW="" name="ddr3_dq[12]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ20" SLEW="" name="ddr3_dq[13]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AK20" SLEW="" name="ddr3_dq[14]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AL20" SLEW="" name="ddr3_dq[15]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW22" SLEW="" name="ddr3_dq[16]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW23" SLEW="" name="ddr3_dq[17]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW21" SLEW="" name="ddr3_dq[18]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AV21" SLEW="" name="ddr3_dq[19]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM24" SLEW="" name="ddr3_dq[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AU23" SLEW="" name="ddr3_dq[20]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AV23" SLEW="" name="ddr3_dq[21]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AR24" SLEW="" name="ddr3_dq[22]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AT24" SLEW="" name="ddr3_dq[23]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BB24" SLEW="" name="ddr3_dq[24]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BA24" SLEW="" name="ddr3_dq[25]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY23" SLEW="" name="ddr3_dq[26]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY24" SLEW="" name="ddr3_dq[27]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY25" SLEW="" name="ddr3_dq[28]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BA25" SLEW="" name="ddr3_dq[29]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AR22" SLEW="" name="ddr3_dq[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BB21" SLEW="" name="ddr3_dq[30]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BA21" SLEW="" name="ddr3_dq[31]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY14" SLEW="" name="ddr3_dq[32]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW15" SLEW="" name="ddr3_dq[33]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BB14" SLEW="" name="ddr3_dq[34]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BB13" SLEW="" name="ddr3_dq[35]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW12" SLEW="" name="ddr3_dq[36]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY13" SLEW="" name="ddr3_dq[37]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AY12" SLEW="" name="ddr3_dq[38]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="BA12" SLEW="" name="ddr3_dq[39]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AR23" SLEW="" name="ddr3_dq[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AU12" SLEW="" name="ddr3_dq[40]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AU13" SLEW="" name="ddr3_dq[41]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AT12" SLEW="" name="ddr3_dq[42]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AU14" SLEW="" name="ddr3_dq[43]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AV13" SLEW="" name="ddr3_dq[44]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AW13" SLEW="" name="ddr3_dq[45]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AT15" SLEW="" name="ddr3_dq[46]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AR15" SLEW="" name="ddr3_dq[47]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AL15" SLEW="" name="ddr3_dq[48]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ15" SLEW="" name="ddr3_dq[49]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AN23" SLEW="" name="ddr3_dq[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AK14" SLEW="" name="ddr3_dq[50]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ12" SLEW="" name="ddr3_dq[51]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ16" SLEW="" name="ddr3_dq[52]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AL16" SLEW="" name="ddr3_dq[53]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ13" SLEW="" name="ddr3_dq[54]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AK13" SLEW="" name="ddr3_dq[55]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AR14" SLEW="" name="ddr3_dq[56]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AT14" SLEW="" name="ddr3_dq[57]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM12" SLEW="" name="ddr3_dq[58]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AP11" SLEW="" name="ddr3_dq[59]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM23" SLEW="" name="ddr3_dq[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM13" SLEW="" name="ddr3_dq[60]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AN13" SLEW="" name="ddr3_dq[61]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AM11" SLEW="" name="ddr3_dq[62]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AN11" SLEW="" name="ddr3_dq[63]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AN21" SLEW="" name="ddr3_dq[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AP21" SLEW="" name="ddr3_dq[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AK23" SLEW="" name="ddr3_dq[8]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15_T_DCI" PADName="AJ23" SLEW="" name="ddr3_dq[9]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AP22" SLEW="" name="ddr3_dqs_n[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AK22" SLEW="" name="ddr3_dqs_n[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AU21" SLEW="" name="ddr3_dqs_n[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="BB22" SLEW="" name="ddr3_dqs_n[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="BA14" SLEW="" name="ddr3_dqs_n[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AR12" SLEW="" name="ddr3_dqs_n[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AL14" SLEW="" name="ddr3_dqs_n[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AN14" SLEW="" name="ddr3_dqs_n[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AP23" SLEW="" name="ddr3_dqs_p[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AJ22" SLEW="" name="ddr3_dqs_p[1]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AT21" SLEW="" name="ddr3_dqs_p[2]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="BA22" SLEW="" name="ddr3_dqs_p[3]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="BA15" SLEW="" name="ddr3_dqs_p[4]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AP12" SLEW="" name="ddr3_dqs_p[5]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AK15" SLEW="" name="ddr3_dqs_p[6]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="DIFF_SSTL15_T_DCI" PADName="AN15" SLEW="" name="ddr3_dqs_p[7]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AT16" SLEW="" name="ddr3_odt[0]" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AV19" SLEW="" name="ddr3_ras_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="LVCMOS15" PADName="BB19" SLEW="" name="ddr3_reset_n" IN_TERM="" />}
   puts $mig_prj_file {            <Pin VCCAUX_IO="NORMAL" IOSTANDARD="SSTL15" PADName="AU19" SLEW="" name="ddr3_we_n" IN_TERM="" />}
   puts $mig_prj_file {        </PinSelection>}
   puts $mig_prj_file {        <System_Clock>}
   puts $mig_prj_file {            <Pin PADName="H19/G18(CC_P/N)" Bank="38" name="c1_sys_clk_p/n" />}
   puts $mig_prj_file {        </System_Clock>}
   puts $mig_prj_file {        <TimingParameters>}
   puts $mig_prj_file {            <Parameters twtr="7.5" trrd="5" trefi="7.8" tfaw="27" trtp="7.5" tcke="5" trfc="260" trp="13.91" tras="34" trcd="13.91" />}
   puts $mig_prj_file {        </TimingParameters>}
   puts $mig_prj_file {        <mrBurstLength name="Burst Length" >8 - Fixed</mrBurstLength>}
   puts $mig_prj_file {        <mrBurstType name="Read Burst Type and Length" >Sequential</mrBurstType>}
   puts $mig_prj_file {        <mrCasLatency name="CAS Latency" >6</mrCasLatency>}
   puts $mig_prj_file {        <mrMode name="Mode" >Normal</mrMode>}
   puts $mig_prj_file {        <mrDllReset name="DLL Reset" >No</mrDllReset>}
   puts $mig_prj_file {        <mrPdMode name="DLL control for precharge PD" >Slow Exit</mrPdMode>}
   puts $mig_prj_file {        <emrDllEnable name="DLL Enable" >Enable</emrDllEnable>}
   puts $mig_prj_file {        <emrOutputDriveStrength name="Output Driver Impedance Control" >RZQ/7</emrOutputDriveStrength>}
   puts $mig_prj_file {        <emrMirrorSelection name="Address Mirroring" >Disable</emrMirrorSelection>}
   puts $mig_prj_file {        <emrCSSelection name="Controller Chip Select Pin" >Enable</emrCSSelection>}
   puts $mig_prj_file {        <emrRTT name="RTT (nominal) - On Die Termination (ODT)" >RZQ/6</emrRTT>}
   puts $mig_prj_file {        <emrPosted name="Additive Latency (AL)" >0</emrPosted>}
   puts $mig_prj_file {        <emrOCD name="Write Leveling Enable" >Disabled</emrOCD>}
   puts $mig_prj_file {        <emrDQS name="TDQS enable" >Enabled</emrDQS>}
   puts $mig_prj_file {        <emrRDQS name="Qoff" >Output Buffer Enabled</emrRDQS>}
   puts $mig_prj_file {        <mr2PartialArraySelfRefresh name="Partial-Array Self Refresh" >Full Array</mr2PartialArraySelfRefresh>}
   puts $mig_prj_file {        <mr2CasWriteLatency name="CAS write latency" >5</mr2CasWriteLatency>}
   puts $mig_prj_file {        <mr2AutoSelfRefresh name="Auto Self Refresh" >Enabled</mr2AutoSelfRefresh>}
   puts $mig_prj_file {        <mr2SelfRefreshTempRange name="High Temparature Self Refresh Rate" >Normal</mr2SelfRefreshTempRange>}
   puts $mig_prj_file {        <mr2RTTWR name="RTT_WR - Dynamic On Die Termination (ODT)" >Dynamic ODT off</mr2RTTWR>}
   puts $mig_prj_file {        <PortInterface>AXI</PortInterface>}
   puts $mig_prj_file {        <AXIParameters>}
   puts $mig_prj_file {            <C1_C_RD_WR_ARB_ALGORITHM>RD_PRI_REG</C1_C_RD_WR_ARB_ALGORITHM>}
   puts $mig_prj_file {            <C1_S_AXI_ADDR_WIDTH>32</C1_S_AXI_ADDR_WIDTH>}
   puts $mig_prj_file {            <C1_S_AXI_DATA_WIDTH>64</C1_S_AXI_DATA_WIDTH>}
   puts $mig_prj_file {            <C1_S_AXI_ID_WIDTH>5</C1_S_AXI_ID_WIDTH>}
   puts $mig_prj_file {            <C1_S_AXI_SUPPORTS_NARROW_BURST>1</C1_S_AXI_SUPPORTS_NARROW_BURST>}
   puts $mig_prj_file {        </AXIParameters>}
   puts $mig_prj_file {    </Controller>}
   puts $mig_prj_file {</Project>}

   close $mig_prj_file
}
# End of write_mig_file_system_top_mig_7series_0_0()



##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: prmcore_local_memory
proc create_hier_cell_prmcore_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_prmcore_local_memory() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB

  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst LMB_Rst

  # Create instance: dlmb_bram_dtb_cntlr, and set properties
  set dlmb_bram_dtb_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_dtb_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
 ] $dlmb_bram_dtb_cntlr

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]
  set_property -dict [ list \
CONFIG.C_LMB_NUM_SLAVES {2} \
 ] $dlmb_v10

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram ]
  set_property -dict [ list \
CONFIG.Memory_Type {True_Dual_Port_RAM} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create instance: lmb_bram_dtb, and set properties
  set lmb_bram_dtb [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.3 lmb_bram_dtb ]
  set_property -dict [ list \
CONFIG.Memory_Type {Single_Port_RAM} \
CONFIG.Port_B_Clock {0} \
CONFIG.Port_B_Enable_Rate {0} \
CONFIG.Port_B_Write_Rate {0} \
CONFIG.Write_Depth_A {8192} \
CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram_dtb

  # Create interface connections
  connect_bd_intf_net -intf_net Conn [get_bd_intf_pins dlmb_bram_dtb_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_1]
  connect_bd_intf_net -intf_net dlmb_bram_dtb_cntlr_BRAM_PORT [get_bd_intf_pins dlmb_bram_dtb_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram_dtb/BRAM_PORTA]
  connect_bd_intf_net -intf_net prmcore_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net prmcore_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net prmcore_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net prmcore_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net prmcore_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net prmcore_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net prmcore_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_dtb_cntlr/LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]
  connect_bd_net -net prmcore_LMB_Rst [get_bd_pins LMB_Rst] [get_bd_pins dlmb_bram_dtb_cntlr/LMB_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: ethernet_block
proc create_hier_cell_ethernet_block { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_ethernet_block() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MM2S
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_SG
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_clk
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp

  # Create pins
  create_bd_pin -dir O -type clk gt0_qplloutclk_out
  create_bd_pin -dir O -type clk gt0_qplloutrefclk_out
  create_bd_pin -dir O -type clk gtref_clk_buf_out
  create_bd_pin -dir O -type clk gtref_clk_out
  create_bd_pin -dir O -from 2 -to 0 interrupts
  create_bd_pin -dir I m_axi_mem_aclk
  create_bd_pin -dir O mmcm_locked_out
  create_bd_pin -dir O -type rst pma_reset_out
  create_bd_pin -dir I ref_clk
  create_bd_pin -dir O -type clk rxuserclk2_out
  create_bd_pin -dir O -type clk rxuserclk_out
  create_bd_pin -dir I s_axi_lite_aclk
  create_bd_pin -dir I -from 0 -to 0 s_axi_lite_aresetn
  create_bd_pin -dir I -from 0 -to 0 signal_detect
  create_bd_pin -dir O -type clk userclk2_out
  create_bd_pin -dir O -type clk userclk_out

  # Create instance: axi_ethernet, and set properties
  set axi_ethernet [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet:7.0 axi_ethernet ]
  set_property -dict [ list \
CONFIG.DIFFCLK_BOARD_INTERFACE {sfp_mgt_clk} \
CONFIG.ETHERNET_BOARD_INTERFACE {sfp1} \
CONFIG.USE_BOARD_FLOW {true} \
 ] $axi_ethernet

  # Create instance: axi_ethernet_dma, and set properties
  set axi_ethernet_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma:7.1 axi_ethernet_dma ]
  set_property -dict [ list \
CONFIG.c_include_mm2s_dre {1} \
CONFIG.c_include_s2mm_dre {1} \
CONFIG.c_sg_length_width {16} \
CONFIG.c_sg_use_stsapp_length {1} \
 ] $axi_ethernet_dma

  # Create instance: axi_lite_xbar, and set properties
  set axi_lite_xbar [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_lite_xbar ]

  # Create instance: xlconcat_interrupts, and set properties
  set xlconcat_interrupts [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_interrupts ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {3} \
 ] $xlconcat_interrupts

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins sfp] [get_bd_intf_pins axi_ethernet/sfp]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins mgt_clk] [get_bd_intf_pins axi_ethernet/mgt_clk]
  connect_bd_intf_net -intf_net S_AXI_LITE_1 [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_lite_xbar/S00_AXI]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXIS_CNTRL [get_bd_intf_pins axi_ethernet/s_axis_txc] [get_bd_intf_pins axi_ethernet_dma/M_AXIS_CNTRL]
  connect_bd_intf_net -intf_net axi_ethernet_0_dma_M_AXIS_MM2S [get_bd_intf_pins axi_ethernet/s_axis_txd] [get_bd_intf_pins axi_ethernet_dma/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxd [get_bd_intf_pins axi_ethernet/m_axis_rxd] [get_bd_intf_pins axi_ethernet_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_ethernet_0_m_axis_rxs [get_bd_intf_pins axi_ethernet/m_axis_rxs] [get_bd_intf_pins axi_ethernet_dma/S_AXIS_STS]
  connect_bd_intf_net -intf_net axi_ethernet_dma_M_AXI_MM2S [get_bd_intf_pins M_AXI_MM2S] [get_bd_intf_pins axi_ethernet_dma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_ethernet_dma_M_AXI_S2MM [get_bd_intf_pins M_AXI_S2MM] [get_bd_intf_pins axi_ethernet_dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axi_ethernet_dma_M_AXI_SG [get_bd_intf_pins M_AXI_SG] [get_bd_intf_pins axi_ethernet_dma/M_AXI_SG]
  connect_bd_intf_net -intf_net axi_lite_xbar_M00_AXI [get_bd_intf_pins axi_ethernet/s_axi] [get_bd_intf_pins axi_lite_xbar/M00_AXI]
  connect_bd_intf_net -intf_net axi_lite_xbar_M01_AXI [get_bd_intf_pins axi_ethernet_dma/S_AXI_LITE] [get_bd_intf_pins axi_lite_xbar/M01_AXI]

  # Create port connections
  connect_bd_net -net axi_ethernet_0_dma_mm2s_cntrl_reset_out_n [get_bd_pins axi_ethernet/axi_txc_arstn] [get_bd_pins axi_ethernet_dma/mm2s_cntrl_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_mm2s_prmry_reset_out_n [get_bd_pins axi_ethernet/axi_txd_arstn] [get_bd_pins axi_ethernet_dma/mm2s_prmry_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_prmry_reset_out_n [get_bd_pins axi_ethernet/axi_rxd_arstn] [get_bd_pins axi_ethernet_dma/s2mm_prmry_reset_out_n]
  connect_bd_net -net axi_ethernet_0_dma_s2mm_sts_reset_out_n [get_bd_pins axi_ethernet/axi_rxs_arstn] [get_bd_pins axi_ethernet_dma/s2mm_sts_reset_out_n]
  connect_bd_net -net axi_ethernet_dma_mm2s_introut [get_bd_pins axi_ethernet_dma/mm2s_introut] [get_bd_pins xlconcat_interrupts/In0]
  connect_bd_net -net axi_ethernet_dma_s2mm_introut [get_bd_pins axi_ethernet_dma/s2mm_introut] [get_bd_pins xlconcat_interrupts/In1]
  connect_bd_net -net axi_ethernet_gt0_qplloutclk_out [get_bd_pins gt0_qplloutclk_out] [get_bd_pins axi_ethernet/gt0_qplloutclk_out]
  connect_bd_net -net axi_ethernet_gt0_qplloutrefclk_out [get_bd_pins gt0_qplloutrefclk_out] [get_bd_pins axi_ethernet/gt0_qplloutrefclk_out]
  connect_bd_net -net axi_ethernet_gtref_clk_buf_out [get_bd_pins gtref_clk_buf_out] [get_bd_pins axi_ethernet/gtref_clk_buf_out]
  connect_bd_net -net axi_ethernet_gtref_clk_out [get_bd_pins gtref_clk_out] [get_bd_pins axi_ethernet/gtref_clk_out]
  connect_bd_net -net axi_ethernet_interrupt [get_bd_pins axi_ethernet/interrupt] [get_bd_pins xlconcat_interrupts/In2]
  connect_bd_net -net axi_ethernet_mmcm_locked_out [get_bd_pins mmcm_locked_out] [get_bd_pins axi_ethernet/mmcm_locked_out]
  connect_bd_net -net axi_ethernet_pma_reset_out [get_bd_pins pma_reset_out] [get_bd_pins axi_ethernet/pma_reset_out]
  connect_bd_net -net axi_ethernet_rxuserclk2_out [get_bd_pins rxuserclk2_out] [get_bd_pins axi_ethernet/rxuserclk2_out]
  connect_bd_net -net axi_ethernet_rxuserclk_out [get_bd_pins rxuserclk_out] [get_bd_pins axi_ethernet/rxuserclk_out]
  connect_bd_net -net axi_ethernet_userclk2_out [get_bd_pins userclk2_out] [get_bd_pins axi_ethernet/userclk2_out]
  connect_bd_net -net axi_ethernet_userclk_out [get_bd_pins userclk_out] [get_bd_pins axi_ethernet/userclk_out]
  connect_bd_net -net m_axi_mem_aclk_1 [get_bd_pins m_axi_mem_aclk] [get_bd_pins axi_ethernet/axis_clk] [get_bd_pins axi_ethernet_dma/m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_dma/m_axi_s2mm_aclk] [get_bd_pins axi_ethernet_dma/m_axi_sg_aclk]
  connect_bd_net -net ref_clk_1 [get_bd_pins ref_clk] [get_bd_pins axi_ethernet/ref_clk]
  connect_bd_net -net s_axi_lite_aclk_1 [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_ethernet/s_axi_lite_clk] [get_bd_pins axi_ethernet_dma/s_axi_lite_aclk] [get_bd_pins axi_lite_xbar/aclk]
  connect_bd_net -net s_axi_lite_aresetn_1 [get_bd_pins s_axi_lite_aresetn] [get_bd_pins axi_ethernet/s_axi_lite_resetn] [get_bd_pins axi_ethernet_dma/axi_resetn] [get_bd_pins axi_lite_xbar/aresetn]
  connect_bd_net -net signal_detect_1 [get_bd_pins signal_detect] [get_bd_pins axi_ethernet/signal_detect]
  connect_bd_net -net xlconcat_interrupts_dout [get_bd_pins interrupts] [get_bd_pins xlconcat_interrupts/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PRM_CORE
proc create_hier_cell_PRM_CORE { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_PRM_CORE() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:emc_rtl:1.0 EMC_INTF
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_APM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA_SG
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_DC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_ETHERNET_MM2S
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_ETHERNET_S2MM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_ETHERNET_SG
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_IC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_3
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_clk
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp

  # Create pins
  create_bd_pin -dir O -from 15 -to 0 DMA_DS_ID
  create_bd_pin -dir I -from 0 -to 0 apm_interrupt
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I -from 0 -to 0 -type rst ext_reset_in
  create_bd_pin -dir O -type clk gt0_qplloutclk_out
  create_bd_pin -dir O -type clk gt0_qplloutrefclk_out
  create_bd_pin -dir O -type clk gtref_clk_buf_out
  create_bd_pin -dir O -type clk gtref_clk_out
  create_bd_pin -dir I -type clk io_clk
  create_bd_pin -dir I -type clk m_axi_aclk
  create_bd_pin -dir I -type clk mem_clk
  create_bd_pin -dir O mmcm_locked_out
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -type rst pma_reset_out
  create_bd_pin -dir O -from 0 -to 0 prm_softreset
  create_bd_pin -dir O -from 0 -to 0 -type rst processor_aresetn
  create_bd_pin -dir I -type clk processor_clk
  create_bd_pin -dir O -type clk rxuserclk2_out
  create_bd_pin -dir O -type clk rxuserclk_out
  create_bd_pin -dir I -from 0 -to 0 signal_detect
  create_bd_pin -dir O -type clk userclk2_out
  create_bd_pin -dir O -type clk userclk_out

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0 ]
  set_property -dict [ list \
CONFIG.C_M_AXI_DATA_WIDTH {64} \
CONFIG.C_M_AXI_MAX_BURST_LEN {8} \
 ] $axi_cdma_0

  # Create instance: axi_dma_dsid, and set properties
  set block_name axi_reg
  set block_cell_name axi_dma_dsid
  if { [catch {set axi_dma_dsid [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $axi_dma_dsid eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: axi_emc_flash, and set properties
  set axi_emc_flash [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_emc:3.0 axi_emc_flash ]
  set_property -dict [ list \
CONFIG.C_MEM0_TYPE {2} \
CONFIG.C_TAVDV_PS_MEM_0 {96000} \
CONFIG.C_TCEDV_PS_MEM_0 {96000} \
CONFIG.C_THZCE_PS_MEM_0 {9000} \
CONFIG.C_THZOE_PS_MEM_0 {9000} \
CONFIG.C_TLZWE_PS_MEM_0 {20000} \
CONFIG.C_TWC_PS_MEM_0 {40000} \
CONFIG.C_TWPH_PS_MEM_0 {20000} \
CONFIG.C_TWP_PS_MEM_0 {40000} \
CONFIG.C_WR_REC_TIME_MEM_0 {200000} \
CONFIG.EMC_BOARD_INTERFACE {linear_flash} \
CONFIG.USE_BOARD_FLOW {false} \
 ] $axi_emc_flash

  # Create instance: axi_gpio_softreset, and set properties
  set axi_gpio_softreset [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_softreset ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
CONFIG.C_GPIO_WIDTH {1} \
CONFIG.C_IS_DUAL {0} \
 ] $axi_gpio_softreset

  # Create instance: axi_iic_0, and set properties
  set axi_iic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 axi_iic_0 ]
  set_property -dict [ list \
CONFIG.C_SDA_LEVEL {1} \
CONFIG.IIC_FREQ_KHZ {1000} \
 ] $axi_iic_0

  # Create instance: axi_uartlite_0, and set properties
  set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
 ] $axi_uartlite_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_0

  # Create instance: axi_uartlite_1, and set properties
  set axi_uartlite_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_1 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
 ] $axi_uartlite_1

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_1

  # Create instance: axi_uartlite_2, and set properties
  set axi_uartlite_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_2 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
 ] $axi_uartlite_2

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_2

  # Create instance: axi_uartlite_3, and set properties
  set axi_uartlite_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_3 ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
 ] $axi_uartlite_3

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $axi_uartlite_3

  # Create instance: ethernet_block
  create_hier_cell_ethernet_block $hier_obj ethernet_block

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: prm_timer, and set properties
  set prm_timer [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer:2.0 prm_timer ]

  # Create instance: prm_uartlite, and set properties
  set prm_uartlite [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 prm_uartlite ]
  set_property -dict [ list \
CONFIG.C_BAUDRATE {115200} \
CONFIG.C_S_AXI_ACLK_FREQ_HZ {100000000} \
CONFIG.UARTLITE_BOARD_INTERFACE {rs232_uart} \
 ] $prm_uartlite

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.C_S_AXI_ACLK_FREQ_HZ.VALUE_SRC {DEFAULT} \
 ] $prm_uartlite

  # Create instance: prmcore, and set properties
  set prmcore [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:9.6 prmcore ]
  set_property -dict [ list \
CONFIG.C_CACHE_BYTE_SIZE {16384} \
CONFIG.C_DCACHE_BASEADDR {0x0000000080000000} \
CONFIG.C_DCACHE_BYTE_SIZE {16384} \
CONFIG.C_DCACHE_HIGHADDR {0x00000000FFFFFFFF} \
CONFIG.C_DEBUG_ENABLED {1} \
CONFIG.C_DIV_ZERO_EXCEPTION {1} \
CONFIG.C_D_AXI {1} \
CONFIG.C_D_LMB {1} \
CONFIG.C_ICACHE_BASEADDR {0x80000000} \
CONFIG.C_ICACHE_FORCE_TAG_LUTRAM {0} \
CONFIG.C_ICACHE_HIGHADDR {0xFFFFFFFF} \
CONFIG.C_ICACHE_LINE_LEN {8} \
CONFIG.C_ICACHE_STREAMS {1} \
CONFIG.C_ICACHE_VICTIMS {8} \
CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
CONFIG.C_I_LMB {1} \
CONFIG.C_MMU_ZONES {2} \
CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
CONFIG.C_PVR {2} \
CONFIG.C_PVR_USER1 {0xAA} \
CONFIG.C_PVR_USER2 {0x50415244} \
CONFIG.C_TRACE {1} \
CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
CONFIG.C_USE_BARREL {1} \
CONFIG.C_USE_DCACHE {1} \
CONFIG.C_USE_DIV {1} \
CONFIG.C_USE_FPU {1} \
CONFIG.C_USE_HW_MUL {2} \
CONFIG.C_USE_ICACHE {1} \
CONFIG.C_USE_MMU {3} \
CONFIG.C_USE_MSR_INSTR {1} \
CONFIG.C_USE_PCMP_INSTR {1} \
CONFIG.G_TEMPLATE_LIST {4} \
CONFIG.G_USE_EXCEPTIONS {1} \
 ] $prmcore

  # Create instance: prmcore_axi_intc, and set properties
  set prmcore_axi_intc [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_intc:4.1 prmcore_axi_intc ]
  set_property -dict [ list \
CONFIG.C_HAS_FAST {1} \
CONFIG.C_KIND_OF_INTR {0xFFFFE07A} \
 ] $prmcore_axi_intc

  # Create instance: prmcore_axi_periph, and set properties
  set prmcore_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 prmcore_axi_periph ]
  set_property -dict [ list \
CONFIG.NUM_MI {14} \
 ] $prmcore_axi_periph

  # Create instance: prmcore_local_memory
  create_hier_cell_prmcore_local_memory $hier_obj prmcore_local_memory

  # Create instance: prmcore_xlconcat, and set properties
  set prmcore_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 prmcore_xlconcat ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {10} \
 ] $prmcore_xlconcat

  # Create instance: rst_io_clk, and set properties
  set rst_io_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_io_clk ]

  # Create instance: rst_processor_clk, and set properties
  set rst_processor_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_processor_clk ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {15} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {64} \
CONFIG.DOUT_WIDTH {16} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins IIC] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins SYS_UART_0] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins SYS_UART_1] [get_bd_intf_pins axi_uartlite_1/UART]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins SYS_UART_2] [get_bd_intf_pins axi_uartlite_2/UART]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins SYS_UART_3] [get_bd_intf_pins axi_uartlite_3/UART]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins M_AXI_CDMA] [get_bd_intf_pins axi_cdma_0/M_AXI]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins M_AXI_CDMA_SG] [get_bd_intf_pins axi_cdma_0/M_AXI_SG]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins M_AXI_DC] [get_bd_intf_pins prmcore/M_AXI_DC]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins M_AXI_IC] [get_bd_intf_pins prmcore/M_AXI_IC]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins EMC_INTF] [get_bd_intf_pins axi_emc_flash/EMC_INTF]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins sfp] [get_bd_intf_pins ethernet_block/sfp]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins mgt_clk] [get_bd_intf_pins ethernet_block/mgt_clk]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins M_AXI_APM] [get_bd_intf_pins prmcore_axi_periph/M12_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins UART] [get_bd_intf_pins prm_uartlite/UART]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_MM2S [get_bd_intf_pins M_AXI_ETHERNET_MM2S] [get_bd_intf_pins ethernet_block/M_AXI_MM2S]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_S2MM [get_bd_intf_pins M_AXI_ETHERNET_S2MM] [get_bd_intf_pins ethernet_block/M_AXI_S2MM]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_SG [get_bd_intf_pins M_AXI_ETHERNET_SG] [get_bd_intf_pins ethernet_block/M_AXI_SG]
  connect_bd_intf_net -intf_net prmcore_axi_dp [get_bd_intf_pins prmcore/M_AXI_DP] [get_bd_intf_pins prmcore_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M01_AXI [get_bd_intf_pins prm_timer/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M02_AXI [get_bd_intf_pins prm_uartlite/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M03_AXI [get_bd_intf_pins axi_iic_0/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M04_AXI [get_bd_intf_pins axi_uartlite_0/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M04_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M05_AXI [get_bd_intf_pins axi_uartlite_1/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M05_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M06_AXI [get_bd_intf_pins axi_uartlite_2/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M06_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M07_AXI [get_bd_intf_pins axi_uartlite_3/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M07_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M08_AXI [get_bd_intf_pins axi_cdma_0/S_AXI_LITE] [get_bd_intf_pins prmcore_axi_periph/M08_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M09_AXI [get_bd_intf_pins axi_emc_flash/S_AXI_MEM] [get_bd_intf_pins prmcore_axi_periph/M09_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M10_AXI [get_bd_intf_pins axi_gpio_softreset/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M10_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M11_AXI [get_bd_intf_pins ethernet_block/S_AXI_LITE] [get_bd_intf_pins prmcore_axi_periph/M11_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M13_AXI [get_bd_intf_pins axi_dma_dsid/S_AXI] [get_bd_intf_pins prmcore_axi_periph/M13_AXI]
  connect_bd_intf_net -intf_net prmcore_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins prmcore/DEBUG]
  connect_bd_intf_net -intf_net prmcore_dlmb_1 [get_bd_intf_pins prmcore/DLMB] [get_bd_intf_pins prmcore_local_memory/DLMB]
  connect_bd_intf_net -intf_net prmcore_ilmb_1 [get_bd_intf_pins prmcore/ILMB] [get_bd_intf_pins prmcore_local_memory/ILMB]
  connect_bd_intf_net -intf_net prmcore_intc_axi [get_bd_intf_pins prmcore_axi_intc/s_axi] [get_bd_intf_pins prmcore_axi_periph/M00_AXI]
  connect_bd_intf_net -intf_net prmcore_interrupt [get_bd_intf_pins prmcore/INTERRUPT] [get_bd_intf_pins prmcore_axi_intc/interrupt]

  # Create port connections
  connect_bd_net -net In9_1 [get_bd_pins apm_interrupt] [get_bd_pins prmcore_xlconcat/In9]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins axi_cdma_0/cdma_introut] [get_bd_pins prmcore_xlconcat/In7]
  connect_bd_net -net axi_gpio_softreset_gpio_io_o [get_bd_pins prm_softreset] [get_bd_pins axi_gpio_softreset/gpio_io_o]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins prmcore_xlconcat/In2]
  connect_bd_net -net axi_reg_0_val [get_bd_pins axi_dma_dsid/val] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins prm_uartlite/interrupt] [get_bd_pins prmcore_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt1 [get_bd_pins axi_uartlite_0/interrupt] [get_bd_pins prmcore_xlconcat/In3]
  connect_bd_net -net axi_uartlite_1_interrupt [get_bd_pins axi_uartlite_1/interrupt] [get_bd_pins prmcore_xlconcat/In4]
  connect_bd_net -net axi_uartlite_2_interrupt [get_bd_pins axi_uartlite_2/interrupt] [get_bd_pins prmcore_xlconcat/In5]
  connect_bd_net -net axi_uartlite_3_interrupt [get_bd_pins axi_uartlite_3/interrupt] [get_bd_pins prmcore_xlconcat/In6]
  connect_bd_net -net dcm_locked_1 [get_bd_pins dcm_locked] [get_bd_pins rst_io_clk/dcm_locked] [get_bd_pins rst_processor_clk/dcm_locked]
  connect_bd_net -net ethernet_block_gt0_qplloutclk_out [get_bd_pins gt0_qplloutclk_out] [get_bd_pins ethernet_block/gt0_qplloutclk_out]
  connect_bd_net -net ethernet_block_gt0_qplloutrefclk_out [get_bd_pins gt0_qplloutrefclk_out] [get_bd_pins ethernet_block/gt0_qplloutrefclk_out]
  connect_bd_net -net ethernet_block_gtref_clk_buf_out [get_bd_pins gtref_clk_buf_out] [get_bd_pins ethernet_block/gtref_clk_buf_out]
  connect_bd_net -net ethernet_block_gtref_clk_out [get_bd_pins gtref_clk_out] [get_bd_pins ethernet_block/gtref_clk_out]
  connect_bd_net -net ethernet_block_interrupts [get_bd_pins ethernet_block/interrupts] [get_bd_pins prmcore_xlconcat/In8]
  connect_bd_net -net ethernet_block_mmcm_locked_out [get_bd_pins mmcm_locked_out] [get_bd_pins ethernet_block/mmcm_locked_out]
  connect_bd_net -net ethernet_block_pma_reset_out [get_bd_pins pma_reset_out] [get_bd_pins ethernet_block/pma_reset_out]
  connect_bd_net -net ethernet_block_rxuserclk2_out [get_bd_pins rxuserclk2_out] [get_bd_pins ethernet_block/rxuserclk2_out]
  connect_bd_net -net ethernet_block_rxuserclk_out [get_bd_pins rxuserclk_out] [get_bd_pins ethernet_block/rxuserclk_out]
  connect_bd_net -net ethernet_block_userclk2_out [get_bd_pins userclk2_out] [get_bd_pins ethernet_block/userclk2_out]
  connect_bd_net -net ethernet_block_userclk_out [get_bd_pins userclk_out] [get_bd_pins ethernet_block/userclk_out]
  connect_bd_net -net m_axi_aclk_1 [get_bd_pins m_axi_aclk] [get_bd_pins axi_cdma_0/m_axi_aclk]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_io_clk/mb_debug_sys_rst]
  connect_bd_net -net memclk_1 [get_bd_pins mem_clk] [get_bd_pins ethernet_block/m_axi_mem_aclk] [get_bd_pins ethernet_block/ref_clk]
  connect_bd_net -net prmcore_intr [get_bd_pins prmcore_axi_intc/intr] [get_bd_pins prmcore_xlconcat/dout]
  connect_bd_net -net processor_clk_1 [get_bd_pins processor_clk] [get_bd_pins prmcore/Clk] [get_bd_pins prmcore_axi_intc/processor_clk] [get_bd_pins prmcore_axi_periph/S00_ACLK] [get_bd_pins prmcore_local_memory/LMB_Clk] [get_bd_pins rst_processor_clk/slowest_sync_clk]
  connect_bd_net -net reset_rtl_1 [get_bd_pins ext_reset_in] [get_bd_pins rst_io_clk/ext_reset_in] [get_bd_pins rst_processor_clk/ext_reset_in]
  connect_bd_net -net rst_Clk_100M_interconnect_aresetn [get_bd_pins prmcore_axi_periph/ARESETN] [get_bd_pins rst_io_clk/interconnect_aresetn]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn] [get_bd_pins axi_dma_dsid/s_axi_aresetn] [get_bd_pins axi_emc_flash/s_axi_aresetn] [get_bd_pins axi_gpio_softreset/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins axi_uartlite_1/s_axi_aresetn] [get_bd_pins axi_uartlite_2/s_axi_aresetn] [get_bd_pins axi_uartlite_3/s_axi_aresetn] [get_bd_pins ethernet_block/s_axi_lite_aresetn] [get_bd_pins prm_timer/s_axi_aresetn] [get_bd_pins prm_uartlite/s_axi_aresetn] [get_bd_pins prmcore_axi_intc/s_axi_aresetn] [get_bd_pins prmcore_axi_periph/M00_ARESETN] [get_bd_pins prmcore_axi_periph/M01_ARESETN] [get_bd_pins prmcore_axi_periph/M02_ARESETN] [get_bd_pins prmcore_axi_periph/M03_ARESETN] [get_bd_pins prmcore_axi_periph/M04_ARESETN] [get_bd_pins prmcore_axi_periph/M05_ARESETN] [get_bd_pins prmcore_axi_periph/M06_ARESETN] [get_bd_pins prmcore_axi_periph/M07_ARESETN] [get_bd_pins prmcore_axi_periph/M08_ARESETN] [get_bd_pins prmcore_axi_periph/M09_ARESETN] [get_bd_pins prmcore_axi_periph/M10_ARESETN] [get_bd_pins prmcore_axi_periph/M11_ARESETN] [get_bd_pins prmcore_axi_periph/M12_ARESETN] [get_bd_pins prmcore_axi_periph/M13_ARESETN] [get_bd_pins rst_io_clk/peripheral_aresetn]
  connect_bd_net -net rst_processor_clk_bus_struct_reset [get_bd_pins prmcore_local_memory/LMB_Rst] [get_bd_pins rst_processor_clk/bus_struct_reset]
  connect_bd_net -net rst_processor_clk_mb_reset [get_bd_pins prmcore/Reset] [get_bd_pins prmcore_axi_intc/processor_rst] [get_bd_pins rst_processor_clk/mb_reset]
  connect_bd_net -net rst_processor_clk_peripheral_aresetn [get_bd_pins processor_aresetn] [get_bd_pins prmcore_axi_periph/S00_ARESETN] [get_bd_pins rst_processor_clk/peripheral_aresetn]
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins io_clk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_dma_dsid/s_axi_aclk] [get_bd_pins axi_emc_flash/rdclk] [get_bd_pins axi_emc_flash/s_axi_aclk] [get_bd_pins axi_gpio_softreset/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_uartlite_1/s_axi_aclk] [get_bd_pins axi_uartlite_2/s_axi_aclk] [get_bd_pins axi_uartlite_3/s_axi_aclk] [get_bd_pins ethernet_block/s_axi_lite_aclk] [get_bd_pins prm_timer/s_axi_aclk] [get_bd_pins prm_uartlite/s_axi_aclk] [get_bd_pins prmcore_axi_intc/s_axi_aclk] [get_bd_pins prmcore_axi_periph/ACLK] [get_bd_pins prmcore_axi_periph/M00_ACLK] [get_bd_pins prmcore_axi_periph/M01_ACLK] [get_bd_pins prmcore_axi_periph/M02_ACLK] [get_bd_pins prmcore_axi_periph/M03_ACLK] [get_bd_pins prmcore_axi_periph/M04_ACLK] [get_bd_pins prmcore_axi_periph/M05_ACLK] [get_bd_pins prmcore_axi_periph/M06_ACLK] [get_bd_pins prmcore_axi_periph/M07_ACLK] [get_bd_pins prmcore_axi_periph/M08_ACLK] [get_bd_pins prmcore_axi_periph/M09_ACLK] [get_bd_pins prmcore_axi_periph/M10_ACLK] [get_bd_pins prmcore_axi_periph/M11_ACLK] [get_bd_pins prmcore_axi_periph/M12_ACLK] [get_bd_pins prmcore_axi_periph/M13_ACLK] [get_bd_pins rst_io_clk/slowest_sync_clk]
  connect_bd_net -net signal_detect_1 [get_bd_pins signal_detect] [get_bd_pins ethernet_block/signal_detect]
  connect_bd_net -net timer_interrupt [get_bd_pins prm_timer/interrupt] [get_bd_pins prmcore_xlconcat/In0]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins DMA_DS_ID] [get_bd_pins xlslice_0/Dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: vc709_sfp
proc create_hier_cell_vc709_sfp { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_vc709_sfp() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins

  # Create pins
  create_bd_pin -dir O -from 0 -to 0 Dout
  create_bd_pin -dir I -from 3 -to 0 SFP_LOS
  create_bd_pin -dir I -from 3 -to 0 SFP_MOD_DETECT
  create_bd_pin -dir O -from 3 -to 0 SFP_RS0
  create_bd_pin -dir O -from 3 -to 0 SFP_TX_DISABLE
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir IO -type clk i2c_clk
  create_bd_pin -dir IO i2c_data
  create_bd_pin -dir O i2c_mux_rst_n
  create_bd_pin -dir O si5324_rst_n
  create_bd_pin -dir I -type clk slowest_sync_clk

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: vc709_sfp_0, and set properties
  set block_name vc709_sfp
  set block_cell_name vc709_sfp_0
  if { [catch {set vc709_sfp_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $vc709_sfp_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {4} \
 ] $xlslice_0

  # Create port connections
  connect_bd_net -net Net [get_bd_pins i2c_clk] [get_bd_pins vc709_sfp_0/i2c_clk]
  connect_bd_net -net Net1 [get_bd_pins i2c_data] [get_bd_pins vc709_sfp_0/i2c_data]
  connect_bd_net -net SFP_LOS_1 [get_bd_pins SFP_LOS] [get_bd_pins vc709_sfp_0/SFP_LOS]
  connect_bd_net -net SFP_MOD_DETECT_1 [get_bd_pins SFP_MOD_DETECT] [get_bd_pins vc709_sfp_0/SFP_MOD_DETECT]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins slowest_sync_clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins vc709_sfp_0/clk50]
  connect_bd_net -net dcm_locked_1 [get_bd_pins dcm_locked] [get_bd_pins proc_sys_reset_0/dcm_locked]
  connect_bd_net -net mig_7series_0_c1_ui_clk_sync_rst [get_bd_pins ext_reset_in] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins proc_sys_reset_0/mb_reset] [get_bd_pins vc709_sfp_0/sync_reset]
  connect_bd_net -net signal_detect_1 [get_bd_pins Dout] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net vc709_sfp_0_SFP_RS0 [get_bd_pins SFP_RS0] [get_bd_pins vc709_sfp_0/SFP_RS0]
  connect_bd_net -net vc709_sfp_0_SFP_TX_DISABLE [get_bd_pins SFP_TX_DISABLE] [get_bd_pins vc709_sfp_0/SFP_TX_DISABLE]
  connect_bd_net -net vc709_sfp_0_i2c_mux_rst_n [get_bd_pins i2c_mux_rst_n] [get_bd_pins vc709_sfp_0/i2c_mux_rst_n]
  connect_bd_net -net vc709_sfp_0_si5324_rst_n [get_bd_pins si5324_rst_n] [get_bd_pins vc709_sfp_0/si5324_rst_n]
  connect_bd_net -net vc709_sfp_0_signal_detect [get_bd_pins vc709_sfp_0/signal_detect] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: rocketchip
proc create_hier_cell_rocketchip { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_rocketchip() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv riscv:rocket:dmi_rtl:1.0 DMI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MEM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART1

  # Create pins
  create_bd_pin -dir I -from 2 -to 0 L1enable
  create_bd_pin -dir I coreclk
  create_bd_pin -dir I -type rst corerst0
  create_bd_pin -dir I -type rst corerst1
  create_bd_pin -dir I debug_clk
  create_bd_pin -dir I debug_rst
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn1
  create_bd_pin -dir I -type clk uncoreclk
  create_bd_pin -dir I -type rst uncorerst

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

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {2} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXI_CDMA] [get_bd_intf_pins rocketchip_top_0/M_AXI_CDMA]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins UART1] [get_bd_intf_pins axi_uartlite_1/UART]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins DMI] [get_bd_intf_pins rocketchip_top_0/DMI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M01_AXI [get_bd_intf_pins axi_crossbar_0/M01_AXI] [get_bd_intf_pins axi_uartlite_1/S_AXI]
  connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins axi_protocol_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_pins axi_crossbar_0/S00_AXI] [get_bd_intf_pins axi_protocol_converter_0/M_AXI]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_pins UART] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MEM [get_bd_intf_pins M_AXI_MEM] [get_bd_intf_pins rocketchip_top_0/M_AXI_MEM]
  connect_bd_intf_net -intf_net rocketchip_top_0_M_AXI_MMIO [get_bd_intf_pins axi_dwidth_converter_0/S_AXI] [get_bd_intf_pins rocketchip_top_0/M_AXI_MMIO]

  # Create port connections
  connect_bd_net -net L1enable_1 [get_bd_pins L1enable] [get_bd_pins rocketchip_top_0/L1enable]
  connect_bd_net -net clk_1 [get_bd_pins uncoreclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_protocol_converter_0/aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_uartlite_1/s_axi_aclk] [get_bd_pins rocketchip_top_0/uncoreclk]
  connect_bd_net -net coreclk_1 [get_bd_pins coreclk] [get_bd_pins ila_core0/clk] [get_bd_pins ila_core1/clk] [get_bd_pins rocketchip_top_0/coreclk0] [get_bd_pins rocketchip_top_0/coreclk1]
  connect_bd_net -net corerst0_1 [get_bd_pins corerst0] [get_bd_pins rocketchip_top_0/corerst0]
  connect_bd_net -net corerst1_1 [get_bd_pins corerst1] [get_bd_pins rocketchip_top_0/corerst1]
  connect_bd_net -net io_debug_clk0_1 [get_bd_pins debug_clk] [get_bd_pins rocketchip_top_0/io_debug_clk0]
  connect_bd_net -net io_debug_rst0_1 [get_bd_pins debug_rst] [get_bd_pins rocketchip_top_0/io_debug_rst0]
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
  connect_bd_net -net s_axi_aresetn1_1 [get_bd_pins s_axi_aresetn1] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_protocol_converter_0/aresetn] [get_bd_pins axi_uartlite_1/s_axi_aresetn]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]
  connect_bd_net -net uncorerst_1 [get_bd_pins uncorerst] [get_bd_pins rocketchip_top_0/uncorerst]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins rocketchip_top_0/io_interrupts] [get_bd_pins xlconstant_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: PRMSYS
proc create_hier_cell_PRMSYS { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_PRMSYS() - Empty argument(s)!"}
     return
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

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:emc_rtl:1.0 EMC_INTF
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 MEM_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_APM
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART_3
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_clk
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp

  # Create pins
  create_bd_pin -dir O -from 0 -to 0 -type rst ARESETN
  create_bd_pin -dir O -from 15 -to 0 DMA_DS_ID
  create_bd_pin -dir I -type clk aclk
  create_bd_pin -dir I -from 0 -to 0 apm_interrupt
  create_bd_pin -dir I -from 0 -to 0 -type rst aresetn1
  create_bd_pin -dir I dcm_locked
  create_bd_pin -dir I -type rst ext_reset_in
  create_bd_pin -dir O -type clk gt0_qplloutclk_out
  create_bd_pin -dir O -type clk gt0_qplloutrefclk_out
  create_bd_pin -dir O -type clk gtref_clk_buf_out
  create_bd_pin -dir O -type clk gtref_clk_out
  create_bd_pin -dir O -type clk io_clk
  create_bd_pin -dir I -type clk m_axi_aclk
  create_bd_pin -dir O mmcm_locked_out
  create_bd_pin -dir O -from 0 -to 0 -type rst peripheral_aresetn
  create_bd_pin -dir O -type rst pma_reset_out
  create_bd_pin -dir O -type clk rxuserclk2_out
  create_bd_pin -dir O -type clk rxuserclk_out
  create_bd_pin -dir I -from 0 -to 0 signal_detect
  create_bd_pin -dir O -type clk userclk2_out
  create_bd_pin -dir O -type clk userclk_out

  # Create instance: PRM_CORE
  create_hier_cell_PRM_CORE $hier_obj PRM_CORE

  # Create instance: axi_cdma_xbar, and set properties
  set axi_cdma_xbar [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_cdma_xbar ]
  set_property -dict [ list \
CONFIG.M00_A00_ADDR_WIDTH {31} \
CONFIG.M00_A00_BASE_ADDR {0x0000000080000000} \
CONFIG.M01_A00_ADDR_WIDTH {31} \
CONFIG.M01_A00_BASE_ADDR {0x0000000000000000} \
 ] $axi_cdma_xbar

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {32} \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {2} \
 ] $axi_crossbar_0

  # Create instance: axi_dwidth_converter_0, and set properties
  set axi_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0 ]

  # Create instance: axi_ethdma_xbar, and set properties
  set axi_ethdma_xbar [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_ethdma_xbar ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {32} \
CONFIG.M00_READ_ISSUING {2} \
CONFIG.M00_WRITE_ISSUING {2} \
CONFIG.M01_READ_ISSUING {2} \
CONFIG.M01_WRITE_ISSUING {2} \
CONFIG.M02_READ_ISSUING {2} \
CONFIG.M02_WRITE_ISSUING {2} \
CONFIG.M03_READ_ISSUING {2} \
CONFIG.M03_WRITE_ISSUING {2} \
CONFIG.M04_READ_ISSUING {2} \
CONFIG.M04_WRITE_ISSUING {2} \
CONFIG.M05_READ_ISSUING {2} \
CONFIG.M05_WRITE_ISSUING {2} \
CONFIG.M06_READ_ISSUING {2} \
CONFIG.M06_WRITE_ISSUING {2} \
CONFIG.M07_READ_ISSUING {2} \
CONFIG.M07_WRITE_ISSUING {2} \
CONFIG.M08_READ_ISSUING {2} \
CONFIG.M08_WRITE_ISSUING {2} \
CONFIG.M09_READ_ISSUING {2} \
CONFIG.M09_WRITE_ISSUING {2} \
CONFIG.M10_READ_ISSUING {2} \
CONFIG.M10_WRITE_ISSUING {2} \
CONFIG.M11_READ_ISSUING {2} \
CONFIG.M11_WRITE_ISSUING {2} \
CONFIG.M12_READ_ISSUING {2} \
CONFIG.M12_WRITE_ISSUING {2} \
CONFIG.M13_READ_ISSUING {2} \
CONFIG.M13_WRITE_ISSUING {2} \
CONFIG.M14_READ_ISSUING {2} \
CONFIG.M14_WRITE_ISSUING {2} \
CONFIG.M15_READ_ISSUING {2} \
CONFIG.M15_WRITE_ISSUING {2} \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {3} \
CONFIG.S00_READ_ACCEPTANCE {4} \
CONFIG.S00_WRITE_ACCEPTANCE {4} \
CONFIG.S01_READ_ACCEPTANCE {4} \
CONFIG.S01_WRITE_ACCEPTANCE {4} \
CONFIG.S02_READ_ACCEPTANCE {4} \
CONFIG.S02_WRITE_ACCEPTANCE {4} \
CONFIG.S03_READ_ACCEPTANCE {4} \
CONFIG.S03_WRITE_ACCEPTANCE {4} \
CONFIG.S04_READ_ACCEPTANCE {4} \
CONFIG.S04_WRITE_ACCEPTANCE {4} \
CONFIG.S05_READ_ACCEPTANCE {4} \
CONFIG.S05_WRITE_ACCEPTANCE {4} \
CONFIG.S06_READ_ACCEPTANCE {4} \
CONFIG.S06_WRITE_ACCEPTANCE {4} \
CONFIG.S07_READ_ACCEPTANCE {4} \
CONFIG.S07_WRITE_ACCEPTANCE {4} \
CONFIG.S08_READ_ACCEPTANCE {4} \
CONFIG.S08_WRITE_ACCEPTANCE {4} \
CONFIG.S09_READ_ACCEPTANCE {4} \
CONFIG.S09_WRITE_ACCEPTANCE {4} \
CONFIG.S10_READ_ACCEPTANCE {4} \
CONFIG.S10_WRITE_ACCEPTANCE {4} \
CONFIG.S11_READ_ACCEPTANCE {4} \
CONFIG.S11_WRITE_ACCEPTANCE {4} \
CONFIG.S12_READ_ACCEPTANCE {4} \
CONFIG.S12_WRITE_ACCEPTANCE {4} \
CONFIG.S13_READ_ACCEPTANCE {4} \
CONFIG.S13_WRITE_ACCEPTANCE {4} \
CONFIG.S14_READ_ACCEPTANCE {4} \
CONFIG.S14_WRITE_ACCEPTANCE {4} \
CONFIG.S15_READ_ACCEPTANCE {4} \
CONFIG.S15_WRITE_ACCEPTANCE {4} \
 ] $axi_ethdma_xbar

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {4} \
CONFIG.S00_HAS_REGSLICE {1} \
CONFIG.S01_HAS_REGSLICE {1} \
CONFIG.S02_HAS_REGSLICE {1} \
CONFIG.S03_HAS_REGSLICE {1} \
 ] $axi_interconnect_0

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.3 clk_wiz_0 ]
  set_property -dict [ list \
CONFIG.CLKIN1_JITTER_PS {50.0} \
CONFIG.CLKOUT1_DRIVES {BUFG} \
CONFIG.CLKOUT1_JITTER {106.183} \
CONFIG.CLKOUT1_PHASE_ERROR {89.971} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {133.333333333333} \
CONFIG.CLKOUT2_DRIVES {BUFG} \
CONFIG.CLKOUT2_JITTER {112.316} \
CONFIG.CLKOUT2_PHASE_ERROR {89.971} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT3_JITTER {129.198} \
CONFIG.CLKOUT3_PHASE_ERROR {89.971} \
CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {50.000} \
CONFIG.CLKOUT3_USED {true} \
CONFIG.MMCM_CLKFBOUT_MULT_F {5.000} \
CONFIG.MMCM_CLKIN1_PERIOD {5.0} \
CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {7.500} \
CONFIG.MMCM_CLKOUT1_DIVIDE {10} \
CONFIG.MMCM_CLKOUT2_DIVIDE {20} \
CONFIG.MMCM_COMPENSATION {ZHOLD} \
CONFIG.NUM_OUT_CLKS {3} \
CONFIG.PRIM_IN_FREQ {200.000} \
CONFIG.PRIM_SOURCE {Global_buffer} \
CONFIG.USE_SAFE_CLOCK_STARTUP {false} \
 ] $clk_wiz_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.MMCM_CLKFBOUT_MULT_F.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN1_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN2_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT1_DIVIDE.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT2_DIVIDE.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_COMPENSATION.VALUE_SRC {DEFAULT} \
 ] $clk_wiz_0

  # Create instance: rst_Clk_200M, and set properties
  set rst_Clk_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_Clk_200M ]
  set_property -dict [ list \
CONFIG.C_AUX_RESET_HIGH {1} \
 ] $rst_Clk_200M

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins IIC] [get_bd_intf_pins PRM_CORE/IIC]
  connect_bd_intf_net -intf_net PRM_CORE_EMC_INTF [get_bd_intf_pins EMC_INTF] [get_bd_intf_pins PRM_CORE/EMC_INTF]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_APM [get_bd_intf_pins M_AXI_APM] [get_bd_intf_pins PRM_CORE/M_AXI_APM]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_CDMA [get_bd_intf_pins PRM_CORE/M_AXI_CDMA] [get_bd_intf_pins axi_cdma_xbar/S00_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_CDMA_SG [get_bd_intf_pins PRM_CORE/M_AXI_CDMA_SG] [get_bd_intf_pins axi_crossbar_0/S00_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_DC [get_bd_intf_pins PRM_CORE/M_AXI_DC] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_ETHERNET_MM2S [get_bd_intf_pins PRM_CORE/M_AXI_ETHERNET_MM2S] [get_bd_intf_pins axi_ethdma_xbar/S01_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_ETHERNET_S2MM [get_bd_intf_pins PRM_CORE/M_AXI_ETHERNET_S2MM] [get_bd_intf_pins axi_ethdma_xbar/S02_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_ETHERNET_SG [get_bd_intf_pins PRM_CORE/M_AXI_ETHERNET_SG] [get_bd_intf_pins axi_ethdma_xbar/S00_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_M_AXI_IC [get_bd_intf_pins PRM_CORE/M_AXI_IC] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_SYS_UART_0 [get_bd_intf_pins SYS_UART_0] [get_bd_intf_pins PRM_CORE/SYS_UART_0]
  connect_bd_intf_net -intf_net PRM_CORE_UART [get_bd_intf_pins UART] [get_bd_intf_pins PRM_CORE/UART]
  connect_bd_intf_net -intf_net PRM_CORE_UART1 [get_bd_intf_pins SYS_UART_1] [get_bd_intf_pins PRM_CORE/SYS_UART_1]
  connect_bd_intf_net -intf_net PRM_CORE_UART2 [get_bd_intf_pins SYS_UART_2] [get_bd_intf_pins PRM_CORE/SYS_UART_2]
  connect_bd_intf_net -intf_net PRM_CORE_UART3 [get_bd_intf_pins SYS_UART_3] [get_bd_intf_pins PRM_CORE/SYS_UART_3]
  connect_bd_intf_net -intf_net PRM_CORE_sfp [get_bd_intf_pins sfp] [get_bd_intf_pins PRM_CORE/sfp]
  connect_bd_intf_net -intf_net axi_cdma_xbar_M00_AXI [get_bd_intf_pins axi_cdma_xbar/M00_AXI] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_cdma_xbar_M01_AXI [get_bd_intf_pins M_AXI_CDMA] [get_bd_intf_pins axi_cdma_xbar/M01_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins axi_interconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net axi_dwidth_converter_0_M_AXI [get_bd_intf_pins axi_crossbar_0/S01_AXI] [get_bd_intf_pins axi_dwidth_converter_0/M_AXI]
  connect_bd_intf_net -intf_net axi_ethdma_xbar_M00_AXI [get_bd_intf_pins axi_ethdma_xbar/M00_AXI] [get_bd_intf_pins axi_interconnect_0/S03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins MEM_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net sfp_mgt_clk_1 [get_bd_intf_pins mgt_clk] [get_bd_intf_pins PRM_CORE/mgt_clk]

  # Create port connections
  connect_bd_net -net PRM_CORE_Dout [get_bd_pins DMA_DS_ID] [get_bd_pins PRM_CORE/DMA_DS_ID]
  connect_bd_net -net PRM_CORE_gt0_qplloutclk_out [get_bd_pins gt0_qplloutclk_out] [get_bd_pins PRM_CORE/gt0_qplloutclk_out]
  connect_bd_net -net PRM_CORE_gt0_qplloutrefclk_out [get_bd_pins gt0_qplloutrefclk_out] [get_bd_pins PRM_CORE/gt0_qplloutrefclk_out]
  connect_bd_net -net PRM_CORE_gtref_clk_buf_out [get_bd_pins gtref_clk_buf_out] [get_bd_pins PRM_CORE/gtref_clk_buf_out]
  connect_bd_net -net PRM_CORE_gtref_clk_out [get_bd_pins gtref_clk_out] [get_bd_pins PRM_CORE/gtref_clk_out]
  connect_bd_net -net PRM_CORE_mmcm_locked_out [get_bd_pins mmcm_locked_out] [get_bd_pins PRM_CORE/mmcm_locked_out]
  connect_bd_net -net PRM_CORE_peripheral_aresetn [get_bd_pins ARESETN] [get_bd_pins PRM_CORE/peripheral_aresetn]
  connect_bd_net -net PRM_CORE_pma_reset_out [get_bd_pins pma_reset_out] [get_bd_pins PRM_CORE/pma_reset_out]
  connect_bd_net -net PRM_CORE_prm_softreset [get_bd_pins PRM_CORE/prm_softreset] [get_bd_pins rst_Clk_200M/aux_reset_in]
  connect_bd_net -net PRM_CORE_processor_aresetn [get_bd_pins PRM_CORE/processor_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins axi_interconnect_0/S01_ARESETN]
  connect_bd_net -net PRM_CORE_rxuserclk2_out [get_bd_pins rxuserclk2_out] [get_bd_pins PRM_CORE/rxuserclk2_out]
  connect_bd_net -net PRM_CORE_rxuserclk_out [get_bd_pins rxuserclk_out] [get_bd_pins PRM_CORE/rxuserclk_out]
  connect_bd_net -net PRM_CORE_userclk2_out [get_bd_pins userclk2_out] [get_bd_pins PRM_CORE/userclk2_out]
  connect_bd_net -net PRM_CORE_userclk_out [get_bd_pins userclk_out] [get_bd_pins PRM_CORE/userclk_out]
  connect_bd_net -net apm_interrupt_1 [get_bd_pins apm_interrupt] [get_bd_pins PRM_CORE/apm_interrupt]
  connect_bd_net -net aresetn1_1 [get_bd_pins aresetn1] [get_bd_pins axi_cdma_xbar/aresetn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_interconnect_0/S02_ARESETN]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins io_clk] [get_bd_pins PRM_CORE/io_clk] [get_bd_pins PRM_CORE/processor_clk] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins clk_wiz_0/clk_out2]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins PRM_CORE/dcm_locked] [get_bd_pins clk_wiz_0/locked]
  connect_bd_net -net dcm_locked_1 [get_bd_pins dcm_locked] [get_bd_pins rst_Clk_200M/dcm_locked]
  connect_bd_net -net m_axi_aclk_1 [get_bd_pins m_axi_aclk] [get_bd_pins PRM_CORE/m_axi_aclk] [get_bd_pins axi_cdma_xbar/aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/S02_ACLK]
  connect_bd_net -net reset_1 [get_bd_pins ext_reset_in] [get_bd_pins clk_wiz_0/reset] [get_bd_pins rst_Clk_200M/ext_reset_in]
  connect_bd_net -net rst_Clk_200M_interconnect_aresetn [get_bd_pins axi_ethdma_xbar/aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S03_ARESETN] [get_bd_pins rst_Clk_200M/interconnect_aresetn]
  connect_bd_net -net rst_Clk_200M_peripheral_aresetn [get_bd_pins peripheral_aresetn] [get_bd_pins rst_Clk_200M/peripheral_aresetn]
  connect_bd_net -net rst_Clk_200M_peripheral_reset [get_bd_pins PRM_CORE/ext_reset_in] [get_bd_pins rst_Clk_200M/peripheral_reset]
  connect_bd_net -net signal_detect_1 [get_bd_pins signal_detect] [get_bd_pins PRM_CORE/signal_detect]
  connect_bd_net -net sysclk_1 [get_bd_pins aclk] [get_bd_pins PRM_CORE/mem_clk] [get_bd_pins axi_ethdma_xbar/aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S03_ACLK] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins rst_Clk_200M/slowest_sync_clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


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
  set C0_DDR3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 C0_DDR3 ]
  set C0_SYS_CLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 C0_SYS_CLK ]
  set C1_DDR3 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 C1_DDR3 ]
  set UART [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART ]
  set linear_flash [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:emc_rtl:1.0 linear_flash ]
  set sfp [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp ]
  set sfp_mgt_clk [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sfp_mgt_clk ]
  set_property -dict [ list \
CONFIG.FREQ_HZ {125000000} \
 ] $sfp_mgt_clk

  # Create ports
  set SFP_LOS [ create_bd_port -dir I -from 3 -to 0 SFP_LOS ]
  set SFP_MOD_DETECT [ create_bd_port -dir I -from 3 -to 0 SFP_MOD_DETECT ]
  set SFP_RS0 [ create_bd_port -dir O -from 3 -to 0 SFP_RS0 ]
  set SFP_TX_DISABLE [ create_bd_port -dir O -from 3 -to 0 SFP_TX_DISABLE ]
  set buttons [ create_bd_port -dir I -from 2 -to 0 buttons ]
  set i2c_clk [ create_bd_port -dir IO -type clk i2c_clk ]
  set i2c_data [ create_bd_port -dir IO i2c_data ]
  set i2c_mux_rst_n [ create_bd_port -dir O i2c_mux_rst_n ]
  set leds [ create_bd_port -dir O -from 7 -to 0 leds ]
  set si5324_rst_n [ create_bd_port -dir O si5324_rst_n ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: PRMSYS
  create_hier_cell_PRMSYS [current_bd_instance .] PRMSYS

  # Create instance: axi_clock_converter_0, and set properties
  set axi_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0 ]

  # Create instance: axi_clock_converter_1, and set properties
  set axi_clock_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_1 ]

  # Create instance: axi_perf_mon_0, and set properties
  set axi_perf_mon_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_perf_mon:5.0 axi_perf_mon_0 ]
  set_property -dict [ list \
CONFIG.C_NUM_OF_COUNTERS {10} \
CONFIG.C_REG_ALL_MONITOR_SIGNALS {1} \
 ] $axi_perf_mon_0

  # Create instance: cache_control_plane_0, and set properties
  set block_name cache_control_plane
  set block_cell_name cache_control_plane_0
  if { [catch {set cache_control_plane_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cache_control_plane_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: cdma_addr_0, and set properties
  set block_name cdma_addr
  set block_cell_name cdma_addr_0
  if { [catch {set cdma_addr_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $cdma_addr_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.3 clk_wiz_0 ]
  set_property -dict [ list \
CONFIG.CLKOUT1_JITTER {151.636} \
CONFIG.CLKOUT1_PHASE_ERROR {98.575} \
CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
CONFIG.CLKOUT2_JITTER {151.636} \
CONFIG.CLKOUT2_PHASE_ERROR {98.575} \
CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50.000} \
CONFIG.CLKOUT2_USED {true} \
CONFIG.CLKOUT3_JITTER {130.958} \
CONFIG.CLKOUT3_PHASE_ERROR {98.575} \
CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} \
CONFIG.CLKOUT3_USED {true} \
CONFIG.MMCM_CLKFBOUT_MULT_F {10.000} \
CONFIG.MMCM_CLKIN1_PERIOD {10.0} \
CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} \
CONFIG.MMCM_CLKOUT1_DIVIDE {20} \
CONFIG.MMCM_CLKOUT2_DIVIDE {10} \
CONFIG.MMCM_COMPENSATION {ZHOLD} \
CONFIG.MMCM_DIVCLK_DIVIDE {1} \
CONFIG.NUM_OUT_CLKS {3} \
 ] $clk_wiz_0

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.MMCM_CLKIN1_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN2_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_COMPENSATION.VALUE_SRC {DEFAULT} \
 ] $clk_wiz_0

  # Create instance: core_control_plane_0, and set properties
  set block_name core_control_plane
  set block_cell_name core_control_plane_0
  if { [catch {set core_control_plane_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $core_control_plane_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: i2c_switch_top_0, and set properties
  set block_name i2c_switch_top
  set block_cell_name i2c_switch_top_0
  if { [catch {set i2c_switch_top_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $i2c_switch_top_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: leds_mux_controller_0, and set properties
  set block_name leds_mux_controller
  set block_cell_name leds_mux_controller_0
  if { [catch {set leds_mux_controller_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $leds_mux_controller_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: mig_7series_0, and set properties
  set mig_7series_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.0 mig_7series_0 ]

  # Generate the PRJ File for MIG
  set str_mig_folder [get_property IP_DIR [ get_ips [ get_property CONFIG.Component_Name $mig_7series_0 ] ] ]
  set str_mig_file_name mig_b.prj
  set str_mig_file_path ${str_mig_folder}/${str_mig_file_name}

  write_mig_file_system_top_mig_7series_0_0 $str_mig_file_path

  set_property -dict [ list \
CONFIG.BOARD_MIG_PARAM {Custom} \
CONFIG.RESET_BOARD_INTERFACE {Custom} \
CONFIG.XML_INPUT_FILE {mig_b.prj} \
 ] $mig_7series_0

  # Create instance: mig_control_plane_0, and set properties
  set block_name mig_control_plane
  set block_cell_name mig_control_plane_0
  if { [catch {set mig_control_plane_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $mig_control_plane_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: pardcore_reset0, and set properties
  set pardcore_reset0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pardcore_reset0 ]

  # Create instance: pardcore_reset1, and set properties
  set pardcore_reset1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pardcore_reset1 ]

  # Create instance: pardio_reset, and set properties
  set pardio_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 pardio_reset ]

  # Create instance: reset_100M, and set properties
  set reset_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_100M ]

  # Create instance: rocketchip
  create_hier_cell_rocketchip [current_bd_instance .] rocketchip

  # Create instance: uart_inverter_0, and set properties
  set block_name uart_inverter
  set block_cell_name uart_inverter_0
  if { [catch {set uart_inverter_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $uart_inverter_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: uart_inverter_1, and set properties
  set block_name uart_inverter
  set block_cell_name uart_inverter_1
  if { [catch {set uart_inverter_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $uart_inverter_1 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {not} \
CONFIG.C_SIZE {4} \
CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {not} \
CONFIG.C_SIZE {1} \
CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
CONFIG.C_OPERATION {not} \
CONFIG.C_SIZE {1} \
CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $util_vector_logic_2

  # Create instance: vc709_sfp
  create_hier_cell_vc709_sfp [current_bd_instance .] vc709_sfp

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {5} \
 ] $xlconcat_0

  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {4} \
 ] $xlconcat_1

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {120} \
CONFIG.CONST_WIDTH {7} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {0} \
CONFIG.CONST_WIDTH {3} \
 ] $xlconstant_1

  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {122} \
CONFIG.CONST_WIDTH {7} \
 ] $xlconstant_2

  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_3 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {121} \
CONFIG.CONST_WIDTH {7} \
 ] $xlconstant_3

  # Create instance: xlconstant_4, and set properties
  set xlconstant_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_4 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {3} \
CONFIG.CONST_WIDTH {3} \
 ] $xlconstant_4

  # Create instance: xlconstant_01010101, and set properties
  set xlconstant_01010101 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_01010101 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {85} \
CONFIG.CONST_WIDTH {8} \
 ] $xlconstant_01010101

  # Create instance: xlnx_cache_pard_0, and set properties
  set block_name xlnx_cache_pard
  set block_cell_name xlnx_cache_pard_0
  if { [catch {set xlnx_cache_pard_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_msg_id "BD_TCL-105" "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $xlnx_cache_pard_0 eq "" } {
     catch {common::send_msg_id "BD_TCL-106" "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [ list \
CONFIG.ID_WIDTH {5} \
 ] $xlnx_cache_pard_0

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_ports C0_SYS_CLK] [get_bd_intf_pins mig_7series_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net DMI_1 [get_bd_intf_pins core_control_plane_0/DMI] [get_bd_intf_pins rocketchip/DMI]
  connect_bd_intf_net -intf_net PRMSYS_IIC [get_bd_intf_pins PRMSYS/IIC] [get_bd_intf_pins i2c_switch_top_0/M]
  connect_bd_intf_net -intf_net PRMSYS_MEM_AXI [get_bd_intf_pins PRMSYS/MEM_AXI] [get_bd_intf_pins mig_7series_0/S0_AXI]
  connect_bd_intf_net -intf_net PRMSYS_M_AXI_APM [get_bd_intf_pins PRMSYS/M_AXI_APM] [get_bd_intf_pins axi_perf_mon_0/S_AXI]
  connect_bd_intf_net -intf_net PRMSYS_M_AXI_CDMA [get_bd_intf_pins PRMSYS/M_AXI_CDMA] [get_bd_intf_pins cdma_addr_0/S_AXI]
  connect_bd_intf_net -intf_net PRM_CORE_EMC_INTF [get_bd_intf_ports linear_flash] [get_bd_intf_pins PRMSYS/EMC_INTF]
  connect_bd_intf_net -intf_net PRM_CORE_UART [get_bd_intf_ports UART] [get_bd_intf_pins PRMSYS/UART]
  connect_bd_intf_net -intf_net PRM_CORE_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins PRMSYS/sfp]
  connect_bd_intf_net -intf_net axi_clock_converter_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins mig_7series_0/S1_AXI]
  connect_bd_intf_net -intf_net axi_clock_converter_1_M_AXI [get_bd_intf_pins axi_clock_converter_1/M_AXI] [get_bd_intf_pins rocketchip/M_AXI_CDMA]
  connect_bd_intf_net -intf_net cache_control_plane_0_I2C [get_bd_intf_pins cache_control_plane_0/I2C] [get_bd_intf_pins i2c_switch_top_0/S1]
  connect_bd_intf_net -intf_net cdma_addr_0_M_AXI [get_bd_intf_pins axi_clock_converter_1/S_AXI] [get_bd_intf_pins cdma_addr_0/M_AXI]
  connect_bd_intf_net -intf_net core_control_plane_0_I2C [get_bd_intf_pins core_control_plane_0/I2C] [get_bd_intf_pins i2c_switch_top_0/S0]
  connect_bd_intf_net -intf_net mig_7series_0_C0_DDR3 [get_bd_intf_ports C0_DDR3] [get_bd_intf_pins mig_7series_0/C0_DDR3]
  connect_bd_intf_net -intf_net mig_7series_0_C1_DDR3 [get_bd_intf_ports C1_DDR3] [get_bd_intf_pins mig_7series_0/C1_DDR3]
  connect_bd_intf_net -intf_net mig_control_plane_0_I2C [get_bd_intf_pins i2c_switch_top_0/S2] [get_bd_intf_pins mig_control_plane_0/I2C]
  connect_bd_intf_net -intf_net rocketchip_M_AXI_MEM [get_bd_intf_pins rocketchip/M_AXI_MEM] [get_bd_intf_pins xlnx_cache_pard_0/S0_AXI]
  connect_bd_intf_net -intf_net sfp_mgt_clk_1 [get_bd_intf_ports sfp_mgt_clk] [get_bd_intf_pins PRMSYS/mgt_clk]
  connect_bd_intf_net -intf_net xlnx_cache_pard_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/S_AXI] [get_bd_intf_pins xlnx_cache_pard_0/M_AXI]

  # Create port connections
  connect_bd_net -net L1enable_1 [get_bd_pins rocketchip/L1enable] [get_bd_pins xlconstant_4/dout]
  connect_bd_net -net Net [get_bd_ports i2c_clk] [get_bd_pins vc709_sfp/i2c_clk]
  connect_bd_net -net Net1 [get_bd_ports i2c_data] [get_bd_pins vc709_sfp/i2c_data]
  connect_bd_net -net PRMSYS_ARESETN [get_bd_pins PRMSYS/ARESETN] [get_bd_pins axi_perf_mon_0/s_axi_aresetn] [get_bd_pins i2c_switch_top_0/aresetn]
  connect_bd_net -net PRMSYS_DMA_DS_ID [get_bd_pins PRMSYS/DMA_DS_ID] [get_bd_pins cdma_addr_0/s_axi_ar_bits_user] [get_bd_pins cdma_addr_0/s_axi_aw_bits_user]
  connect_bd_net -net PRMSYS_SYS_UART_0_txd [get_bd_pins PRMSYS/SYS_UART_0_txd] [get_bd_pins uart_inverter_0/tx_dest]
  connect_bd_net -net PRMSYS_SYS_UART_1_txd [get_bd_pins PRMSYS/SYS_UART_1_txd] [get_bd_pins uart_inverter_1/tx_dest]
  connect_bd_net -net PRMSYS_peripheral_aresetn [get_bd_pins PRMSYS/peripheral_aresetn] [get_bd_pins mig_7series_0/c0_aresetn]
  connect_bd_net -net SFP_LOS_1 [get_bd_ports SFP_LOS] [get_bd_pins vc709_sfp/SFP_LOS]
  connect_bd_net -net SFP_MOD_DETECT_1 [get_bd_ports SFP_MOD_DETECT] [get_bd_pins vc709_sfp/SFP_MOD_DETECT]
  connect_bd_net -net SYS_UART_1_rxd_1 [get_bd_pins PRMSYS/SYS_UART_1_rxd] [get_bd_pins uart_inverter_1/rx_dest]
  connect_bd_net -net aclk_1 [get_bd_pins PRMSYS/aclk] [get_bd_pins mig_7series_0/c0_ui_clk]
  connect_bd_net -net axi_perf_mon_0_interrupt [get_bd_pins PRMSYS/apm_interrupt] [get_bd_pins axi_perf_mon_0/interrupt]
  connect_bd_net -net buttons_1 [get_bd_ports buttons] [get_bd_pins leds_mux_controller_0/buttons]
  connect_bd_net -net cache_control_plane_0_way_mask_to_cache [get_bd_pins cache_control_plane_0/way_mask_to_cache] [get_bd_pins xlnx_cache_pard_0/way_mask_from_ptab]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins vc709_sfp/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins PRMSYS/io_clk] [get_bd_pins axi_perf_mon_0/s_axi_aclk] [get_bd_pins i2c_switch_top_0/aclk]
  connect_bd_net -net clk_wiz_0_clk_out3 [get_bd_pins clk_wiz_0/clk_out3] [get_bd_pins pardcore_reset0/slowest_sync_clk] [get_bd_pins pardcore_reset1/slowest_sync_clk] [get_bd_pins rocketchip/coreclk]
  connect_bd_net -net clk_wiz_0_clk_out4 [get_bd_pins axi_clock_converter_0/s_axi_aclk] [get_bd_pins axi_clock_converter_1/m_axi_aclk] [get_bd_pins cache_control_plane_0/SYS_CLK] [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins pardio_reset/slowest_sync_clk] [get_bd_pins rocketchip/uncoreclk] [get_bd_pins xlnx_cache_pard_0/ACLK]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins pardcore_reset0/dcm_locked] [get_bd_pins pardcore_reset1/dcm_locked] [get_bd_pins pardio_reset/dcm_locked] [get_bd_pins vc709_sfp/dcm_locked]
  connect_bd_net -net core_control_plane_0_EXT_RESET_IN_CORE0 [get_bd_pins core_control_plane_0/EXT_RESET_IN_CORE0] [get_bd_pins pardcore_reset0/ext_reset_in] [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net core_control_plane_0_EXT_RESET_IN_CORE1 [get_bd_pins core_control_plane_0/EXT_RESET_IN_CORE1] [get_bd_pins pardcore_reset1/ext_reset_in] [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net corerst0_1 [get_bd_pins pardcore_reset0/mb_reset] [get_bd_pins rocketchip/corerst0]
  connect_bd_net -net dcm_locked_1 [get_bd_pins PRMSYS/dcm_locked] [get_bd_pins mig_7series_0/c0_mmcm_locked]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins PRMSYS/ext_reset_in] [get_bd_pins mig_7series_0/c0_ui_clk_sync_rst]
  connect_bd_net -net leds_mux_controller_0_leds [get_bd_ports leds] [get_bd_pins leds_mux_controller_0/leds]
  connect_bd_net -net mig_7series_0_c1_mmcm_locked [get_bd_pins mig_7series_0/c1_mmcm_locked] [get_bd_pins reset_100M/dcm_locked]
  connect_bd_net -net mig_7series_0_c1_ui_clk [get_bd_pins PRMSYS/m_axi_aclk] [get_bd_pins axi_clock_converter_0/m_axi_aclk] [get_bd_pins axi_clock_converter_1/s_axi_aclk] [get_bd_pins axi_perf_mon_0/core_aclk] [get_bd_pins axi_perf_mon_0/slot_0_axi_aclk] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins core_control_plane_0/SYS_CLK] [get_bd_pins leds_mux_controller_0/clk] [get_bd_pins mig_7series_0/c1_ui_clk] [get_bd_pins mig_control_plane_0/aclk] [get_bd_pins reset_100M/slowest_sync_clk] [get_bd_pins rocketchip/debug_clk]
  connect_bd_net -net mig_7series_0_c1_ui_clk_sync_rst [get_bd_pins clk_wiz_0/reset] [get_bd_pins mig_7series_0/c1_ui_clk_sync_rst] [get_bd_pins pardio_reset/ext_reset_in] [get_bd_pins reset_100M/ext_reset_in] [get_bd_pins vc709_sfp/ext_reset_in]
  connect_bd_net -net pardcore_reset1_mb_reset [get_bd_pins pardcore_reset1/mb_reset] [get_bd_pins rocketchip/corerst1]
  connect_bd_net -net pardcore_reset_interconnect_aresetn [get_bd_pins axi_clock_converter_0/s_axi_aresetn] [get_bd_pins axi_clock_converter_1/m_axi_aresetn] [get_bd_pins pardio_reset/interconnect_aresetn] [get_bd_pins rocketchip/s_axi_aresetn1] [get_bd_pins util_vector_logic_2/Op1] [get_bd_pins xlnx_cache_pard_0/ARESETN]
  connect_bd_net -net pardcore_reset_peripheral_aresetn [get_bd_pins PRMSYS/aresetn1] [get_bd_pins axi_perf_mon_0/core_aresetn] [get_bd_pins axi_perf_mon_0/slot_0_axi_aresetn] [get_bd_pins mig_7series_0/c1_aresetn] [get_bd_pins reset_100M/peripheral_aresetn]
  connect_bd_net -net pardio_reset_mb_reset [get_bd_pins pardio_reset/mb_reset] [get_bd_pins rocketchip/uncorerst] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net reset_100M_interconnect_aresetn [get_bd_pins axi_clock_converter_0/m_axi_aresetn] [get_bd_pins axi_clock_converter_1/s_axi_aresetn] [get_bd_pins leds_mux_controller_0/aresetn] [get_bd_pins mig_control_plane_0/aresetn] [get_bd_pins reset_100M/interconnect_aresetn]
  connect_bd_net -net reset_100M_mb_reset [get_bd_pins core_control_plane_0/RST] [get_bd_pins reset_100M/mb_reset] [get_bd_pins rocketchip/debug_rst]
  connect_bd_net -net rocketchip_UART1_txd [get_bd_pins rocketchip/UART1_txd] [get_bd_pins uart_inverter_1/tx_src] [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net rocketchip_UART_txd [get_bd_pins rocketchip/UART_txd] [get_bd_pins uart_inverter_0/tx_src] [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net s_axi_aresetn_1 [get_bd_pins pardio_reset/peripheral_aresetn] [get_bd_pins rocketchip/s_axi_aresetn]
  connect_bd_net -net signal_detect_1 [get_bd_pins PRMSYS/signal_detect] [get_bd_pins vc709_sfp/Dout]
  connect_bd_net -net sys_rst_1 [get_bd_ports sys_rst] [get_bd_pins mig_7series_0/sys_rst]
  connect_bd_net -net uart_inverter_0_rx_dest [get_bd_pins PRMSYS/SYS_UART_0_rxd] [get_bd_pins uart_inverter_0/rx_dest]
  connect_bd_net -net uart_inverter_0_rx_src [get_bd_pins rocketchip/UART_rxd] [get_bd_pins uart_inverter_0/rx_src] [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net uart_inverter_1_rx_src [get_bd_pins rocketchip/UART1_rxd] [get_bd_pins uart_inverter_1/rx_src] [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins xlconcat_0/In4]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins cache_control_plane_0/RST] [get_bd_pins util_vector_logic_2/Res]
  connect_bd_net -net vc709_sfp_0_SFP_RS0 [get_bd_ports SFP_RS0] [get_bd_pins vc709_sfp/SFP_RS0]
  connect_bd_net -net vc709_sfp_0_SFP_TX_DISABLE [get_bd_ports SFP_TX_DISABLE] [get_bd_pins vc709_sfp/SFP_TX_DISABLE]
  connect_bd_net -net vc709_sfp_0_i2c_mux_rst_n [get_bd_ports i2c_mux_rst_n] [get_bd_pins vc709_sfp/i2c_mux_rst_n]
  connect_bd_net -net vc709_sfp_0_si5324_rst_n [get_bd_ports si5324_rst_n] [get_bd_pins vc709_sfp/si5324_rst_n]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins leds_mux_controller_0/group_default] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_1_dout [get_bd_pins util_vector_logic_0/Op1] [get_bd_pins xlconcat_1/dout]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins core_control_plane_0/ADDR] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_1_dout [get_bd_pins i2c_switch_top_0/addr] [get_bd_pins xlconstant_1/dout]
  connect_bd_net -net xlconstant_2_dout [get_bd_pins mig_control_plane_0/ADDR] [get_bd_pins xlconstant_2/dout]
  connect_bd_net -net xlconstant_3_dout [get_bd_pins leds_mux_controller_0/group_0] [get_bd_pins leds_mux_controller_0/group_1] [get_bd_pins leds_mux_controller_0/group_2] [get_bd_pins xlconstant_01010101/dout]
  connect_bd_net -net xlconstant_3_dout1 [get_bd_pins cache_control_plane_0/ADDR] [get_bd_pins xlconstant_3/dout]
  connect_bd_net -net xlnx_cache_pard_0_lookup_DSid_to_stab [get_bd_pins cache_control_plane_0/lookup_DSid_to_stab] [get_bd_pins xlnx_cache_pard_0/lookup_DSid_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_lookup_hit_to_stab [get_bd_pins cache_control_plane_0/lookup_hit_to_stab] [get_bd_pins xlnx_cache_pard_0/lookup_hit_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_lookup_miss_to_stab [get_bd_pins cache_control_plane_0/lookup_miss_to_stab] [get_bd_pins xlnx_cache_pard_0/lookup_miss_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_lookup_valid_to_stab [get_bd_pins cache_control_plane_0/lookup_valid_to_stab] [get_bd_pins xlnx_cache_pard_0/lookup_valid_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_lru_dsid_to_ptab [get_bd_pins cache_control_plane_0/lru_dsid_to_ptab] [get_bd_pins xlnx_cache_pard_0/lru_dsid_to_ptab]
  connect_bd_net -net xlnx_cache_pard_0_lru_dsid_valid_to_ptab [get_bd_pins cache_control_plane_0/lru_dsid_valid_to_ptab] [get_bd_pins xlnx_cache_pard_0/lru_dsid_valid_to_ptab]
  connect_bd_net -net xlnx_cache_pard_0_lru_history_en_to_ptab [get_bd_pins cache_control_plane_0/lru_history_en_to_ptab] [get_bd_pins xlnx_cache_pard_0/lru_history_en_to_ptab]
  connect_bd_net -net xlnx_cache_pard_0_update_tag_en_to_stab [get_bd_pins cache_control_plane_0/update_tag_en_to_stab] [get_bd_pins xlnx_cache_pard_0/update_tag_en_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_update_tag_new_DSid_vec_to_stab [get_bd_pins cache_control_plane_0/update_tag_new_DSid_vec_to_stab] [get_bd_pins xlnx_cache_pard_0/update_tag_new_DSid_vec_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_update_tag_old_DSid_vec_to_stab [get_bd_pins cache_control_plane_0/update_tag_old_DSid_vec_to_stab] [get_bd_pins xlnx_cache_pard_0/update_tag_old_DSid_vec_to_stab]
  connect_bd_net -net xlnx_cache_pard_0_update_tag_we_to_stab [get_bd_pins cache_control_plane_0/update_tag_we_to_stab] [get_bd_pins xlnx_cache_pard_0/update_tag_we_to_stab]

  # Create address segments
  create_bd_addr_seg -range 0x80000000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/axi_cdma_0/Data] [get_bd_addr_segs cdma_addr_0/S_AXI/Reg] SEG_cdma_addr_0_Reg
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/axi_cdma_0/Data] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/axi_cdma_0/Data_SG] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_cdma_0/S_AXI_LITE/Reg] SEG_axi_cdma_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x40010000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_dma_dsid/S_AXI/Reg] SEG_axi_dma_dsid_Reg
  create_bd_addr_seg -range 0x08000000 -offset 0x60000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_emc_flash/S_AXI_MEM/MEM0] SEG_axi_emc_flash_MEM0
  create_bd_addr_seg -range 0x00040000 -offset 0x40C00000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/ethernet_block/axi_ethernet/s_axi/Reg0] SEG_axi_ethernet_Reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41E00000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/ethernet_block/axi_ethernet_dma/S_AXI_LITE/Reg] SEG_axi_ethernet_dma_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_gpio_softreset/S_AXI/Reg] SEG_axi_gpio_softreset_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_iic_0/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x44B00000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs axi_perf_mon_0/S_AXI/Reg] SEG_axi_perf_mon_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40610000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40620000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_uartlite_1/S_AXI/Reg] SEG_axi_uartlite_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40630000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_uartlite_2/S_AXI/Reg] SEG_axi_uartlite_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40640000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/axi_uartlite_3/S_AXI/Reg] SEG_axi_uartlite_3_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x7FFF8000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/prmcore_local_memory/dlmb_bram_dtb_cntlr/SLMB/Mem] SEG_dlmb_bram_dtb_cntlr_Mem
  create_bd_addr_seg -range 0x00004000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/prmcore_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00004000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Instruction] [get_bd_addr_segs PRMSYS/PRM_CORE/prmcore_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Instruction] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/prm_timer/S_AXI/Reg] SEG_prm_timer_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/prm_uartlite/S_AXI/Reg] SEG_prm_uartlite_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces PRMSYS/PRM_CORE/prmcore/Data] [get_bd_addr_segs PRMSYS/PRM_CORE/prmcore_axi_intc/S_AXI/Reg] SEG_prmcore_axi_intc_Reg
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/ethernet_block/axi_ethernet_dma/Data_SG] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/ethernet_block/axi_ethernet_dma/Data_MM2S] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/PRM_CORE/ethernet_block/axi_ethernet_dma/Data_S2MM] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_msg_id "BD_TCL-1000" "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

