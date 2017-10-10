
################################################################
# This is a generated script based on design: prm
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
# source prm_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# cdma_addr, leds_mux_controller, vc709_sfp

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
set design_name prm

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

proc write_mig_file_prm_mig_7series_0_0 { str_mig_prj_filepath } {

   set mig_prj_file [open $str_mig_prj_filepath  w+]

   puts $mig_prj_file {<?xml version='1.0' encoding='UTF-8'?>}
   puts $mig_prj_file {<!-- IMPORTANT: This is an internal file that has been generated by the MIG software. Any direct editing or changes made to this file may result in unpredictable behavior or data corruption. It is strongly advised that users do not edit the contents of this file. Re-run the MIG GUI with the required settings if any of the options provided below need to be altered. -->}
   puts $mig_prj_file {<Project DDR3Count="2" DDR2Count="0" NoOfControllers="2" RLDIICount="0" QDRIIPCount="0" >}
   puts $mig_prj_file {    <ModuleName>prm_mig_7series_0_0</ModuleName>}
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
   puts $mig_prj_file {            <C0_S_AXI_ID_WIDTH>3</C0_S_AXI_ID_WIDTH>}
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
   puts $mig_prj_file {            <C1_S_AXI_ID_WIDTH>6</C1_S_AXI_ID_WIDTH>}
   puts $mig_prj_file {            <C1_S_AXI_SUPPORTS_NARROW_BURST>1</C1_S_AXI_SUPPORTS_NARROW_BURST>}
   puts $mig_prj_file {        </AXIParameters>}
   puts $mig_prj_file {    </Controller>}
   puts $mig_prj_file {</Project>}

   close $mig_prj_file
}
# End of write_mig_file_prm_mig_7series_0_0()



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

# Hierarchical cell: pardcore_uart
proc create_hier_cell_pardcore_uart { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_pardcore_uart() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI1
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI2
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI3
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART3

  # Create pins
  create_bd_pin -dir O -type intr interrupt
  create_bd_pin -dir O -type intr interrupt1
  create_bd_pin -dir O -type intr interrupt2
  create_bd_pin -dir O -type intr interrupt3
  create_bd_pin -dir I -type clk s_axi_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn

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

  # Create interface connections
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins UART0] [get_bd_intf_pins axi_uartlite_0/UART]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins UART1] [get_bd_intf_pins axi_uartlite_1/UART]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins UART2] [get_bd_intf_pins axi_uartlite_2/UART]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins UART3] [get_bd_intf_pins axi_uartlite_3/UART]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M04_AXI [get_bd_intf_pins S_AXI1] [get_bd_intf_pins axi_uartlite_0/S_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M05_AXI [get_bd_intf_pins S_AXI2] [get_bd_intf_pins axi_uartlite_1/S_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M06_AXI [get_bd_intf_pins S_AXI3] [get_bd_intf_pins axi_uartlite_2/S_AXI]
  connect_bd_intf_net -intf_net prmcore_axi_periph_M07_AXI [get_bd_intf_pins S_AXI] [get_bd_intf_pins axi_uartlite_3/S_AXI]

  # Create port connections
  connect_bd_net -net axi_uartlite_0_interrupt1 [get_bd_pins interrupt1] [get_bd_pins axi_uartlite_0/interrupt]
  connect_bd_net -net axi_uartlite_1_interrupt [get_bd_pins interrupt2] [get_bd_pins axi_uartlite_1/interrupt]
  connect_bd_net -net axi_uartlite_2_interrupt [get_bd_pins interrupt3] [get_bd_pins axi_uartlite_2/interrupt]
  connect_bd_net -net axi_uartlite_3_interrupt [get_bd_pins interrupt] [get_bd_pins axi_uartlite_3/interrupt]
  connect_bd_net -net rst_Clk_100M_peripheral_aresetn [get_bd_pins s_axi_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn] [get_bd_pins axi_uartlite_1/s_axi_aresetn] [get_bd_pins axi_uartlite_2/s_axi_aresetn] [get_bd_pins axi_uartlite_3/s_axi_aresetn]
  connect_bd_net -net s_axi_aclk_1 [get_bd_pins s_axi_aclk] [get_bd_pins axi_uartlite_0/s_axi_aclk] [get_bd_pins axi_uartlite_1/s_axi_aclk] [get_bd_pins axi_uartlite_2/s_axi_aclk] [get_bd_pins axi_uartlite_3/s_axi_aclk]

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
  create_bd_pin -dir O -from 2 -to 0 interrupts
  create_bd_pin -dir I m_axi_mem_aclk
  create_bd_pin -dir I ref_clk
  create_bd_pin -dir I s_axi_lite_aclk
  create_bd_pin -dir I -from 0 -to 0 s_axi_lite_aresetn
  create_bd_pin -dir I -from 0 -to 0 signal_detect

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
  connect_bd_net -net axi_ethernet_interrupt [get_bd_pins axi_ethernet/interrupt] [get_bd_pins xlconcat_interrupts/In2]
  connect_bd_net -net m_axi_mem_aclk_1 [get_bd_pins m_axi_mem_aclk] [get_bd_pins axi_ethernet/axis_clk] [get_bd_pins axi_ethernet_dma/m_axi_mm2s_aclk] [get_bd_pins axi_ethernet_dma/m_axi_s2mm_aclk] [get_bd_pins axi_ethernet_dma/m_axi_sg_aclk]
  connect_bd_net -net ref_clk_1 [get_bd_pins ref_clk] [get_bd_pins axi_ethernet/ref_clk]
  connect_bd_net -net s_axi_lite_aclk_1 [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_ethernet/s_axi_lite_clk] [get_bd_pins axi_ethernet_dma/s_axi_lite_aclk] [get_bd_pins axi_lite_xbar/aclk]
  connect_bd_net -net s_axi_lite_aresetn_1 [get_bd_pins s_axi_lite_aresetn] [get_bd_pins axi_ethernet/s_axi_lite_resetn] [get_bd_pins axi_ethernet_dma/axi_resetn] [get_bd_pins axi_lite_xbar/aresetn]
  connect_bd_net -net signal_detect_1 [get_bd_pins signal_detect] [get_bd_pins axi_ethernet/signal_detect]
  connect_bd_net -net xlconcat_interrupts_dout [get_bd_pins interrupts] [get_bd_pins xlconcat_interrupts/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: cdma_block
proc create_hier_cell_cdma_block { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_cdma_block() - Empty argument(s)!"}
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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA2PARDCORE
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_SG
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_LITE

  # Create pins
  create_bd_pin -dir O -type intr cdma_introut
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_aresetn
  create_bd_pin -dir I -type clk s_axi_lite_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst s_axi_lite_aresetn

  # Create instance: axi_cdma_0, and set properties
  set axi_cdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_cdma:4.1 axi_cdma_0 ]
  set_property -dict [ list \
CONFIG.C_M_AXI_DATA_WIDTH {64} \
CONFIG.C_M_AXI_MAX_BURST_LEN {8} \
 ] $axi_cdma_0

  # Create instance: axi_cdma_xbar, and set properties
  set axi_cdma_xbar [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_cdma_xbar ]
  set_property -dict [ list \
CONFIG.M00_A00_ADDR_WIDTH {31} \
CONFIG.M00_A00_BASE_ADDR {0x0000000080000000} \
CONFIG.M01_A00_ADDR_WIDTH {31} \
CONFIG.M01_A00_BASE_ADDR {0x0000000000000000} \
 ] $axi_cdma_xbar

  # Create instance: axi_dwidth_converter_0, and set properties
  set axi_dwidth_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins M_AXI] [get_bd_intf_pins axi_dwidth_converter_0/M_AXI]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins M_AXI_SG] [get_bd_intf_pins axi_cdma_0/M_AXI_SG]
  connect_bd_intf_net -intf_net PRM_CORE_M01_AXI [get_bd_intf_pins M_AXI_CDMA2PARDCORE] [get_bd_intf_pins axi_cdma_xbar/M01_AXI]
  connect_bd_intf_net -intf_net axi_cdma_0_M_AXI [get_bd_intf_pins axi_cdma_0/M_AXI] [get_bd_intf_pins axi_cdma_xbar/S00_AXI]
  connect_bd_intf_net -intf_net axi_cdma_xbar_M00_AXI [get_bd_intf_pins axi_cdma_xbar/M00_AXI] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M07_AXI [get_bd_intf_pins S_AXI_LITE] [get_bd_intf_pins axi_cdma_0/S_AXI_LITE]

  # Create port connections
  connect_bd_net -net PRM_CORE_peripheral_aresetn [get_bd_pins s_axi_lite_aresetn] [get_bd_pins axi_cdma_0/s_axi_lite_aresetn]
  connect_bd_net -net aresetn1_1 [get_bd_pins s_axi_aresetn] [get_bd_pins axi_cdma_xbar/aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins cdma_introut] [get_bd_pins axi_cdma_0/cdma_introut]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins s_axi_lite_aclk] [get_bd_pins axi_cdma_0/m_axi_aclk] [get_bd_pins axi_cdma_0/s_axi_lite_aclk] [get_bd_pins axi_cdma_xbar/aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: clk_reset
proc create_hier_cell_clk_reset { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" create_hier_cell_clk_reset() - Empty argument(s)!"}
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
  create_bd_pin -dir I -type rst mb_debug_sys_rst
  create_bd_pin -dir O -type clk pardcore_coreclk
  create_bd_pin -dir I -type rst pardcore_ext_reset
  create_bd_pin -dir O -from 0 -to 0 -type rst pardcore_interconnect_rstn
  create_bd_pin -dir I -type clk pardcore_mem_clk
  create_bd_pin -dir I pardcore_mem_dcm_locked
  create_bd_pin -dir O -from 0 -to 0 -type rst pardcore_mem_interconnect_rstn
  create_bd_pin -dir O -from 0 -to 0 -type rst pardcore_mem_rstn
  create_bd_pin -dir O -from 0 -to 0 -type rst pardcore_uncore_rstn
  create_bd_pin -dir O -type clk pardcore_uncoreclk
  create_bd_pin -dir O -from 0 -to 0 -type rst prm_bus_struct_reset
  create_bd_pin -dir O -type clk prm_clk
  create_bd_pin -dir I -type rst prm_ext_reset
  create_bd_pin -dir O -from 0 -to 0 -type rst prm_interconnect_aresetn
  create_bd_pin -dir O -type rst prm_mb_reset
  create_bd_pin -dir I -type clk prm_mem_clk
  create_bd_pin -dir I prm_mem_dcm_locked
  create_bd_pin -dir O -from 0 -to 0 -type rst prm_mem_interconnect_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst prm_mem_peripheral_aresetn
  create_bd_pin -dir O -from 0 -to 0 -type rst prm_peripheral_aresetn
  create_bd_pin -dir O -type clk sfp_clk_50M
  create_bd_pin -dir O sfp_rst

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

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:5.3 clk_wiz_1 ]
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
CONFIG.MMCM_DIVCLK_DIVIDE {1} \
CONFIG.NUM_OUT_CLKS {3} \
CONFIG.PRIM_IN_FREQ {200.000} \
CONFIG.PRIM_SOURCE {Global_buffer} \
CONFIG.USE_SAFE_CLOCK_STARTUP {false} \
 ] $clk_wiz_1

  # Need to retain value_src of defaults
  set_property -dict [ list \
CONFIG.MMCM_CLKFBOUT_MULT_F.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN1_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKIN2_PERIOD.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT1_DIVIDE.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_CLKOUT2_DIVIDE.VALUE_SRC {DEFAULT} \
CONFIG.MMCM_COMPENSATION.VALUE_SRC {DEFAULT} \
 ] $clk_wiz_1

  # Create instance: reset_pardcore_mem_100M, and set properties
  set reset_pardcore_mem_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_pardcore_mem_100M ]

  # Create instance: reset_pardcore_uncore, and set properties
  set reset_pardcore_uncore [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_pardcore_uncore ]

  # Create instance: reset_prm, and set properties
  set reset_prm [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_prm ]

  # Create instance: reset_prm_mem_200M, and set properties
  set reset_prm_mem_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_prm_mem_200M ]

  # Create instance: reset_sfp_50M, and set properties
  set reset_sfp_50M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_sfp_50M ]

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]

  # Create port connections
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins sfp_clk_50M] [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins reset_sfp_50M/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins pardcore_uncoreclk] [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins reset_pardcore_uncore/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out3 [get_bd_pins pardcore_coreclk] [get_bd_pins clk_wiz_0/clk_out3]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_0/locked] [get_bd_pins reset_pardcore_uncore/dcm_locked] [get_bd_pins reset_sfp_50M/dcm_locked]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins prm_clk] [get_bd_pins clk_wiz_1/clk_out2] [get_bd_pins reset_prm/slowest_sync_clk]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins reset_prm/dcm_locked]
  connect_bd_net -net dcm_locked1_1 [get_bd_pins pardcore_mem_dcm_locked] [get_bd_pins reset_pardcore_mem_100M/dcm_locked]
  connect_bd_net -net dcm_locked_1 [get_bd_pins prm_mem_dcm_locked] [get_bd_pins reset_prm_mem_200M/dcm_locked]
  connect_bd_net -net ext_reset_in1_1 [get_bd_pins pardcore_ext_reset] [get_bd_pins clk_wiz_0/reset] [get_bd_pins reset_pardcore_mem_100M/ext_reset_in] [get_bd_pins reset_pardcore_uncore/ext_reset_in] [get_bd_pins reset_sfp_50M/ext_reset_in]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins prm_ext_reset] [get_bd_pins clk_wiz_1/reset] [get_bd_pins reset_prm/ext_reset_in] [get_bd_pins reset_prm_mem_200M/ext_reset_in]
  connect_bd_net -net mb_debug_sys_rst_1 [get_bd_pins mb_debug_sys_rst] [get_bd_pins reset_prm/mb_debug_sys_rst]
  connect_bd_net -net pardio_reset_interconnect_aresetn [get_bd_pins pardcore_interconnect_rstn] [get_bd_pins reset_pardcore_uncore/interconnect_aresetn]
  connect_bd_net -net pardio_reset_peripheral_aresetn [get_bd_pins pardcore_uncore_rstn] [get_bd_pins reset_pardcore_uncore/peripheral_aresetn]
  connect_bd_net -net prm_rst_bus_struct_reset [get_bd_pins prm_bus_struct_reset] [get_bd_pins reset_prm/bus_struct_reset]
  connect_bd_net -net prm_rst_interconnect_aresetn [get_bd_pins prm_interconnect_aresetn] [get_bd_pins reset_prm/interconnect_aresetn]
  connect_bd_net -net prm_rst_mb_reset [get_bd_pins prm_mb_reset] [get_bd_pins reset_prm/mb_reset]
  connect_bd_net -net prm_rst_peripheral_aresetn [get_bd_pins prm_peripheral_aresetn] [get_bd_pins reset_prm/peripheral_aresetn]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins sfp_rst] [get_bd_pins reset_sfp_50M/mb_reset]
  connect_bd_net -net reset_100M_interconnect_aresetn [get_bd_pins pardcore_mem_interconnect_rstn] [get_bd_pins reset_pardcore_mem_100M/interconnect_aresetn]
  connect_bd_net -net reset_100M_peripheral_aresetn [get_bd_pins pardcore_mem_rstn] [get_bd_pins reset_pardcore_mem_100M/peripheral_aresetn]
  connect_bd_net -net reset_200M_interconnect_aresetn [get_bd_pins prm_mem_interconnect_aresetn] [get_bd_pins reset_prm_mem_200M/interconnect_aresetn]
  connect_bd_net -net reset_200M_peripheral_aresetn [get_bd_pins prm_mem_peripheral_aresetn] [get_bd_pins reset_prm_mem_200M/peripheral_aresetn]
  connect_bd_net -net slowest_sync_clk1_1 [get_bd_pins pardcore_mem_clk] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins reset_pardcore_mem_100M/slowest_sync_clk]
  connect_bd_net -net slowest_sync_clk_1 [get_bd_pins prm_mem_clk] [get_bd_pins clk_wiz_1/clk_in1] [get_bd_pins reset_prm_mem_200M/slowest_sync_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins reset_sfp_50M/aux_reset_in] [get_bd_pins xlconstant_0/dout]

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
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_CDMA
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART0
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART1
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART2
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART3
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 mgt_clk
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:sfp_rtl:1.0 sfp

  # Create pins
  create_bd_pin -dir O -type rst Debug_SYS_Rst
  create_bd_pin -dir I -from 0 -to 0 -type rst LMB_Rst
  create_bd_pin -dir I -from 0 -to 0 apm_interrupt
  create_bd_pin -dir I -type clk eth_refclk_200M
  create_bd_pin -dir O -from 0 -to 0 gpio_softreset
  create_bd_pin -dir O -from 0 -to 0 pardcore_corerstn
  create_bd_pin -dir I -type clk prm_aclk
  create_bd_pin -dir I -type rst prm_corerst
  create_bd_pin -dir I -from 0 -to 0 -type rst prm_interconnect_rstn
  create_bd_pin -dir I -from 0 -to 0 -type rst prm_uncore_rstn
  create_bd_pin -dir I -from 0 -to 0 signal_detect

  # Create instance: axi_crossbar_0, and set properties
  set axi_crossbar_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_0 ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {32} \
CONFIG.NUM_MI {13} \
 ] $axi_crossbar_0

  # Create instance: axi_crossbar_mem, and set properties
  set axi_crossbar_mem [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_crossbar:2.1 axi_crossbar_mem ]
  set_property -dict [ list \
CONFIG.DATA_WIDTH {32} \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {7} \
 ] $axi_crossbar_mem

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

  # Create instance: axi_gpio_pardcore_corerstn, and set properties
  set axi_gpio_pardcore_corerstn [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_pardcore_corerstn ]
  set_property -dict [ list \
CONFIG.C_ALL_OUTPUTS {1} \
 ] $axi_gpio_pardcore_corerstn

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

  # Create instance: axi_protocol_converter_0, and set properties
  set axi_protocol_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 axi_protocol_converter_0 ]

  # Create instance: cdma_block
  create_hier_cell_cdma_block $hier_obj cdma_block

  # Create instance: ethernet_block
  create_hier_cell_ethernet_block $hier_obj ethernet_block

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: pardcore_uart
  create_hier_cell_pardcore_uart $hier_obj pardcore_uart

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

  # Create instance: prmcore_local_memory
  create_hier_cell_prmcore_local_memory $hier_obj prmcore_local_memory

  # Create instance: prmcore_xlconcat, and set properties
  set prmcore_xlconcat [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 prmcore_xlconcat ]
  set_property -dict [ list \
CONFIG.NUM_PORTS {10} \
 ] $prmcore_xlconcat

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins IIC] [get_bd_intf_pins axi_iic_0/IIC]
  connect_bd_intf_net -intf_net PRM_CORE_EMC_INTF [get_bd_intf_pins EMC_INTF] [get_bd_intf_pins axi_emc_flash/EMC_INTF]
  connect_bd_intf_net -intf_net PRM_CORE_M01_AXI [get_bd_intf_pins M_AXI_CDMA] [get_bd_intf_pins cdma_block/M_AXI_CDMA2PARDCORE]
  connect_bd_intf_net -intf_net PRM_CORE_SYS_UART_0 [get_bd_intf_pins SYS_UART0] [get_bd_intf_pins pardcore_uart/UART0]
  connect_bd_intf_net -intf_net PRM_CORE_UART [get_bd_intf_pins UART] [get_bd_intf_pins prm_uartlite/UART]
  connect_bd_intf_net -intf_net PRM_CORE_UART1 [get_bd_intf_pins SYS_UART1] [get_bd_intf_pins pardcore_uart/UART1]
  connect_bd_intf_net -intf_net PRM_CORE_UART2 [get_bd_intf_pins SYS_UART2] [get_bd_intf_pins pardcore_uart/UART2]
  connect_bd_intf_net -intf_net PRM_CORE_UART3 [get_bd_intf_pins SYS_UART3] [get_bd_intf_pins pardcore_uart/UART3]
  connect_bd_intf_net -intf_net PRM_CORE_sfp [get_bd_intf_pins sfp] [get_bd_intf_pins ethernet_block/sfp]
  connect_bd_intf_net -intf_net axi_crossbar_0_M00_AXI [get_bd_intf_pins axi_crossbar_0/M00_AXI] [get_bd_intf_pins prm_timer/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M01_AXI [get_bd_intf_pins axi_crossbar_0/M01_AXI] [get_bd_intf_pins prmcore_axi_intc/s_axi]
  connect_bd_intf_net -intf_net axi_crossbar_0_M02_AXI [get_bd_intf_pins axi_crossbar_0/M02_AXI] [get_bd_intf_pins axi_protocol_converter_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M03_AXI [get_bd_intf_pins axi_crossbar_0/M03_AXI] [get_bd_intf_pins axi_gpio_softreset/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M04_AXI [get_bd_intf_pins axi_crossbar_0/M04_AXI] [get_bd_intf_pins ethernet_block/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_crossbar_0_M05_AXI [get_bd_intf_pins axi_crossbar_0/M05_AXI] [get_bd_intf_pins prm_uartlite/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M06_AXI [get_bd_intf_pins axi_crossbar_0/M06_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M07_AXI [get_bd_intf_pins axi_crossbar_0/M07_AXI] [get_bd_intf_pins cdma_block/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_crossbar_0_M08_AXI [get_bd_intf_pins axi_crossbar_0/M08_AXI] [get_bd_intf_pins pardcore_uart/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_0_M09_AXI [get_bd_intf_pins axi_crossbar_0/M09_AXI] [get_bd_intf_pins pardcore_uart/S_AXI1]
  connect_bd_intf_net -intf_net axi_crossbar_0_M10_AXI [get_bd_intf_pins axi_crossbar_0/M10_AXI] [get_bd_intf_pins pardcore_uart/S_AXI2]
  connect_bd_intf_net -intf_net axi_crossbar_0_M11_AXI [get_bd_intf_pins axi_crossbar_0/M11_AXI] [get_bd_intf_pins pardcore_uart/S_AXI3]
  connect_bd_intf_net -intf_net axi_crossbar_0_M12_AXI [get_bd_intf_pins axi_crossbar_0/M12_AXI] [get_bd_intf_pins axi_gpio_pardcore_corerstn/S_AXI]
  connect_bd_intf_net -intf_net axi_crossbar_1_M00_AXI [get_bd_intf_pins MEM_AXI] [get_bd_intf_pins axi_crossbar_mem/M00_AXI]
  connect_bd_intf_net -intf_net axi_protocol_converter_0_M_AXI [get_bd_intf_pins axi_emc_flash/S_AXI_MEM] [get_bd_intf_pins axi_protocol_converter_0/M_AXI]
  connect_bd_intf_net -intf_net cdma_block_M_AXI [get_bd_intf_pins axi_crossbar_mem/S01_AXI] [get_bd_intf_pins cdma_block/M_AXI]
  connect_bd_intf_net -intf_net cdma_block_M_AXI_SG [get_bd_intf_pins axi_crossbar_mem/S00_AXI] [get_bd_intf_pins cdma_block/M_AXI_SG]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_MM2S [get_bd_intf_pins axi_crossbar_mem/S04_AXI] [get_bd_intf_pins ethernet_block/M_AXI_MM2S]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_S2MM [get_bd_intf_pins axi_crossbar_mem/S05_AXI] [get_bd_intf_pins ethernet_block/M_AXI_S2MM]
  connect_bd_intf_net -intf_net ethernet_block_M_AXI_SG [get_bd_intf_pins axi_crossbar_mem/S06_AXI] [get_bd_intf_pins ethernet_block/M_AXI_SG]
  connect_bd_intf_net -intf_net prmcore_M_AXI_DC [get_bd_intf_pins axi_crossbar_mem/S02_AXI] [get_bd_intf_pins prmcore/M_AXI_DC]
  connect_bd_intf_net -intf_net prmcore_M_AXI_DP [get_bd_intf_pins axi_crossbar_0/S00_AXI] [get_bd_intf_pins prmcore/M_AXI_DP]
  connect_bd_intf_net -intf_net prmcore_M_AXI_IC [get_bd_intf_pins axi_crossbar_mem/S03_AXI] [get_bd_intf_pins prmcore/M_AXI_IC]
  connect_bd_intf_net -intf_net prmcore_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins prmcore/DEBUG]
  connect_bd_intf_net -intf_net prmcore_dlmb_1 [get_bd_intf_pins prmcore/DLMB] [get_bd_intf_pins prmcore_local_memory/DLMB]
  connect_bd_intf_net -intf_net prmcore_ilmb_1 [get_bd_intf_pins prmcore/ILMB] [get_bd_intf_pins prmcore_local_memory/ILMB]
  connect_bd_intf_net -intf_net prmcore_interrupt [get_bd_intf_pins prmcore/INTERRUPT] [get_bd_intf_pins prmcore_axi_intc/interrupt]
  connect_bd_intf_net -intf_net sfp_mgt_clk_1 [get_bd_intf_pins mgt_clk] [get_bd_intf_pins ethernet_block/mgt_clk]

  # Create port connections
  connect_bd_net -net LMB_Rst_1 [get_bd_pins LMB_Rst] [get_bd_pins prmcore_local_memory/LMB_Rst]
  connect_bd_net -net PRM_CORE_peripheral_aresetn [get_bd_pins prm_uncore_rstn] [get_bd_pins axi_emc_flash/s_axi_aresetn] [get_bd_pins axi_gpio_pardcore_corerstn/s_axi_aresetn] [get_bd_pins axi_gpio_softreset/s_axi_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn] [get_bd_pins cdma_block/s_axi_lite_aresetn] [get_bd_pins ethernet_block/s_axi_lite_aresetn] [get_bd_pins pardcore_uart/s_axi_aresetn] [get_bd_pins prm_timer/s_axi_aresetn] [get_bd_pins prm_uartlite/s_axi_aresetn] [get_bd_pins prmcore_axi_intc/s_axi_aresetn]
  connect_bd_net -net apm_interrupt_1 [get_bd_pins apm_interrupt] [get_bd_pins prmcore_xlconcat/In9]
  connect_bd_net -net aresetn1_1 [get_bd_pins prm_interconnect_rstn] [get_bd_pins axi_crossbar_0/aresetn] [get_bd_pins axi_crossbar_mem/aresetn] [get_bd_pins axi_protocol_converter_0/aresetn] [get_bd_pins cdma_block/s_axi_aresetn]
  connect_bd_net -net axi_cdma_0_cdma_introut [get_bd_pins cdma_block/cdma_introut] [get_bd_pins prmcore_xlconcat/In7]
  connect_bd_net -net axi_gpio_0_gpio_io_o [get_bd_pins axi_gpio_pardcore_corerstn/gpio_io_o] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net axi_gpio_softreset_gpio_io_o [get_bd_pins gpio_softreset] [get_bd_pins axi_gpio_softreset/gpio_io_o]
  connect_bd_net -net axi_iic_0_iic2intc_irpt [get_bd_pins axi_iic_0/iic2intc_irpt] [get_bd_pins prmcore_xlconcat/In2]
  connect_bd_net -net axi_uartlite_0_interrupt [get_bd_pins prm_uartlite/interrupt] [get_bd_pins prmcore_xlconcat/In1]
  connect_bd_net -net axi_uartlite_0_interrupt1 [get_bd_pins pardcore_uart/interrupt1] [get_bd_pins prmcore_xlconcat/In3]
  connect_bd_net -net axi_uartlite_1_interrupt [get_bd_pins pardcore_uart/interrupt2] [get_bd_pins prmcore_xlconcat/In4]
  connect_bd_net -net axi_uartlite_2_interrupt [get_bd_pins pardcore_uart/interrupt3] [get_bd_pins prmcore_xlconcat/In5]
  connect_bd_net -net axi_uartlite_3_interrupt [get_bd_pins pardcore_uart/interrupt] [get_bd_pins prmcore_xlconcat/In6]
  connect_bd_net -net clk_wiz_0_clk_out2 [get_bd_pins prm_aclk] [get_bd_pins axi_crossbar_0/aclk] [get_bd_pins axi_crossbar_mem/aclk] [get_bd_pins axi_emc_flash/rdclk] [get_bd_pins axi_emc_flash/s_axi_aclk] [get_bd_pins axi_gpio_pardcore_corerstn/s_axi_aclk] [get_bd_pins axi_gpio_softreset/s_axi_aclk] [get_bd_pins axi_iic_0/s_axi_aclk] [get_bd_pins axi_protocol_converter_0/aclk] [get_bd_pins cdma_block/s_axi_lite_aclk] [get_bd_pins ethernet_block/m_axi_mem_aclk] [get_bd_pins ethernet_block/s_axi_lite_aclk] [get_bd_pins pardcore_uart/s_axi_aclk] [get_bd_pins prm_timer/s_axi_aclk] [get_bd_pins prm_uartlite/s_axi_aclk] [get_bd_pins prmcore/Clk] [get_bd_pins prmcore_axi_intc/processor_clk] [get_bd_pins prmcore_axi_intc/s_axi_aclk] [get_bd_pins prmcore_local_memory/LMB_Clk]
  connect_bd_net -net ethernet_block_interrupts [get_bd_pins ethernet_block/interrupts] [get_bd_pins prmcore_xlconcat/In8]
  connect_bd_net -net mdm_1_Debug_SYS_Rst [get_bd_pins Debug_SYS_Rst] [get_bd_pins mdm_1/Debug_SYS_Rst]
  connect_bd_net -net prmcore_intr [get_bd_pins prmcore_axi_intc/intr] [get_bd_pins prmcore_xlconcat/dout]
  connect_bd_net -net rst_processor_clk_mb_reset [get_bd_pins prm_corerst] [get_bd_pins prmcore/Reset] [get_bd_pins prmcore_axi_intc/processor_rst]
  connect_bd_net -net signal_detect_1 [get_bd_pins signal_detect] [get_bd_pins ethernet_block/signal_detect]
  connect_bd_net -net sysclk_1 [get_bd_pins eth_refclk_200M] [get_bd_pins ethernet_block/ref_clk]
  connect_bd_net -net timer_interrupt [get_bd_pins prm_timer/interrupt] [get_bd_pins prmcore_xlconcat/In0]
  connect_bd_net -net xlslice_0_Dout [get_bd_pins pardcore_corerstn] [get_bd_pins xlslice_0/Dout]

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
  set SYS_UART0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 SYS_UART0 ]
  set S_AXI_MEM [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_MEM ]
  set_property -dict [ list \
CONFIG.ADDR_WIDTH {32} \
CONFIG.ARUSER_WIDTH {16} \
CONFIG.AWUSER_WIDTH {16} \
CONFIG.BUSER_WIDTH {0} \
CONFIG.DATA_WIDTH {64} \
CONFIG.HAS_BRESP {1} \
CONFIG.HAS_BURST {1} \
CONFIG.HAS_CACHE {1} \
CONFIG.HAS_LOCK {1} \
CONFIG.HAS_PROT {1} \
CONFIG.HAS_QOS {1} \
CONFIG.HAS_REGION {1} \
CONFIG.HAS_RRESP {1} \
CONFIG.HAS_WSTRB {1} \
CONFIG.ID_WIDTH {5} \
CONFIG.MAX_BURST_LENGTH {256} \
CONFIG.NUM_READ_OUTSTANDING {2} \
CONFIG.NUM_WRITE_OUTSTANDING {2} \
CONFIG.PROTOCOL {AXI4} \
CONFIG.READ_WRITE_MODE {READ_WRITE} \
CONFIG.RUSER_WIDTH {0} \
CONFIG.SUPPORTS_NARROW_BURST {1} \
CONFIG.WUSER_WIDTH {0} \
 ] $S_AXI_MEM
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
  set pardcore_coreclk [ create_bd_port -dir O -type clk pardcore_coreclk ]
  set pardcore_corerstn [ create_bd_port -dir O -from 0 -to 0 pardcore_corerstn ]
  set pardcore_interconnect_rstn [ create_bd_port -dir O -from 0 -to 0 -type rst pardcore_interconnect_rstn ]
  set pardcore_uncore_rstn [ create_bd_port -dir O -from 0 -to 0 -type rst pardcore_uncore_rstn ]
  set pardcore_uncoreclk [ create_bd_port -dir O -type clk pardcore_uncoreclk ]
  set_property -dict [ list \
CONFIG.ASSOCIATED_BUSIF {S_AXI_MEM} \
 ] $pardcore_uncoreclk
  set si5324_rst_n [ create_bd_port -dir O si5324_rst_n ]
  set sys_rst [ create_bd_port -dir I -type rst sys_rst ]
  set_property -dict [ list \
CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $sys_rst

  # Create instance: PRMSYS
  create_hier_cell_PRMSYS [current_bd_instance .] PRMSYS

  # Create instance: axi_clock_converter_0, and set properties
  set axi_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0 ]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
CONFIG.NUM_MI {1} \
CONFIG.NUM_SI {2} \
 ] $axi_interconnect_0

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
  
  # Create instance: clk_reset
  create_hier_cell_clk_reset [current_bd_instance .] clk_reset

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
  set str_mig_file_name mig_a.prj
  set str_mig_file_path ${str_mig_folder}/${str_mig_file_name}

  write_mig_file_prm_mig_7series_0_0 $str_mig_file_path

  set_property -dict [ list \
CONFIG.BOARD_MIG_PARAM {Custom} \
CONFIG.RESET_BOARD_INTERFACE {Custom} \
CONFIG.XML_INPUT_FILE {mig_a.prj} \
 ] $mig_7series_0

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
  
  # Create instance: xlconstant_01010101, and set properties
  set xlconstant_01010101 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_01010101 ]
  set_property -dict [ list \
CONFIG.CONST_VAL {85} \
CONFIG.CONST_WIDTH {8} \
 ] $xlconstant_01010101

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]
  set_property -dict [ list \
CONFIG.DIN_FROM {0} \
CONFIG.DIN_TO {0} \
CONFIG.DIN_WIDTH {4} \
 ] $xlslice_0

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_1 [get_bd_intf_ports C0_SYS_CLK] [get_bd_intf_pins mig_7series_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net PRMSYS_MEM_AXI [get_bd_intf_pins PRMSYS/MEM_AXI] [get_bd_intf_pins axi_clock_converter_0/S_AXI]
  connect_bd_intf_net -intf_net PRMSYS_M_AXI_CDMA [get_bd_intf_pins PRMSYS/M_AXI_CDMA] [get_bd_intf_pins cdma_addr_0/s_axi]
  connect_bd_intf_net -intf_net PRMSYS_SYS_UART_0 [get_bd_intf_ports SYS_UART0] [get_bd_intf_pins PRMSYS/SYS_UART0]
  connect_bd_intf_net -intf_net PRM_CORE_EMC_INTF [get_bd_intf_ports linear_flash] [get_bd_intf_pins PRMSYS/EMC_INTF]
  connect_bd_intf_net -intf_net PRM_CORE_UART [get_bd_intf_ports UART] [get_bd_intf_pins PRMSYS/UART]
  connect_bd_intf_net -intf_net PRM_CORE_sfp [get_bd_intf_ports sfp] [get_bd_intf_pins PRMSYS/sfp]
  connect_bd_intf_net -intf_net S_AXI_MEM_1 [get_bd_intf_ports S_AXI_MEM] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_clock_converter_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins mig_7series_0/S0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins mig_7series_0/S1_AXI]
  connect_bd_intf_net -intf_net cdma_addr_0_m_axi [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins cdma_addr_0/m_axi]
  connect_bd_intf_net -intf_net mig_7series_0_C0_DDR3 [get_bd_intf_ports C0_DDR3] [get_bd_intf_pins mig_7series_0/C0_DDR3]
  connect_bd_intf_net -intf_net mig_7series_0_C1_DDR3 [get_bd_intf_ports C1_DDR3] [get_bd_intf_pins mig_7series_0/C1_DDR3]
  connect_bd_intf_net -intf_net sfp_mgt_clk_1 [get_bd_intf_ports sfp_mgt_clk] [get_bd_intf_pins PRMSYS/mgt_clk]

  # Create port connections
  connect_bd_net -net LMB_Rst_1 [get_bd_pins PRMSYS/LMB_Rst] [get_bd_pins clk_reset/prm_bus_struct_reset]
  connect_bd_net -net Net [get_bd_ports i2c_data] [get_bd_pins vc709_sfp_0/i2c_data]
  connect_bd_net -net Net1 [get_bd_ports i2c_clk] [get_bd_pins vc709_sfp_0/i2c_clk]
  connect_bd_net -net PRMSYS_Debug_SYS_Rst [get_bd_pins PRMSYS/Debug_SYS_Rst] [get_bd_pins clk_reset/mb_debug_sys_rst]
  connect_bd_net -net PRMSYS_pardcore_corerstn [get_bd_ports pardcore_corerstn] [get_bd_pins PRMSYS/pardcore_corerstn]
  connect_bd_net -net S01_ARESETN_1 [get_bd_pins PRMSYS/prm_interconnect_rstn] [get_bd_pins axi_clock_converter_0/s_axi_aresetn] [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins clk_reset/prm_interconnect_aresetn]
  connect_bd_net -net SFP_LOS_1 [get_bd_ports SFP_LOS] [get_bd_pins vc709_sfp_0/SFP_LOS]
  connect_bd_net -net SFP_MOD_DETECT_1 [get_bd_ports SFP_MOD_DETECT] [get_bd_pins vc709_sfp_0/SFP_MOD_DETECT]
  connect_bd_net -net aclk_1 [get_bd_pins PRMSYS/eth_refclk_200M] [get_bd_pins axi_clock_converter_0/m_axi_aclk] [get_bd_pins clk_reset/prm_mem_clk] [get_bd_pins mig_7series_0/c0_ui_clk]
  connect_bd_net -net buttons_1 [get_bd_ports buttons] [get_bd_pins leds_mux_controller_0/buttons]
  connect_bd_net -net clk_reset_clk_out1 [get_bd_pins clk_reset/sfp_clk_50M] [get_bd_pins vc709_sfp_0/clk50]
  connect_bd_net -net clk_reset_clk_out4 [get_bd_ports pardcore_coreclk] [get_bd_pins clk_reset/pardcore_coreclk]
  connect_bd_net -net clk_reset_interconnect_aresetn [get_bd_pins axi_clock_converter_0/m_axi_aresetn] [get_bd_pins clk_reset/prm_mem_interconnect_aresetn]
  connect_bd_net -net clk_reset_mb_reset1 [get_bd_pins clk_reset/sfp_rst] [get_bd_pins vc709_sfp_0/sync_reset]
  connect_bd_net -net clk_reset_peripheral_aresetn [get_bd_pins clk_reset/prm_mem_peripheral_aresetn] [get_bd_pins mig_7series_0/c0_aresetn]
  connect_bd_net -net clk_reset_peripheral_aresetn1 [get_bd_pins clk_reset/pardcore_mem_rstn] [get_bd_pins mig_7series_0/c1_aresetn]
  connect_bd_net -net clk_reset_peripheral_aresetn3 [get_bd_ports pardcore_uncore_rstn] [get_bd_pins clk_reset/pardcore_uncore_rstn]
  connect_bd_net -net clk_wiz_0_clk_out4 [get_bd_ports pardcore_uncoreclk] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins clk_reset/pardcore_uncoreclk]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins PRMSYS/prm_aclk] [get_bd_pins axi_clock_converter_0/s_axi_aclk] [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins clk_reset/prm_clk]
  connect_bd_net -net ext_reset_in_1 [get_bd_pins clk_reset/prm_ext_reset] [get_bd_pins mig_7series_0/c0_ui_clk_sync_rst]
  connect_bd_net -net leds_mux_controller_0_leds [get_bd_ports leds] [get_bd_pins leds_mux_controller_0/leds]
  connect_bd_net -net mig_7series_0_c0_mmcm_locked [get_bd_pins clk_reset/prm_mem_dcm_locked] [get_bd_pins mig_7series_0/c0_mmcm_locked]
  connect_bd_net -net mig_7series_0_c1_mmcm_locked [get_bd_pins clk_reset/pardcore_mem_dcm_locked] [get_bd_pins mig_7series_0/c1_mmcm_locked]
  connect_bd_net -net mig_7series_0_c1_ui_clk [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins clk_reset/pardcore_mem_clk] [get_bd_pins leds_mux_controller_0/clk] [get_bd_pins mig_7series_0/c1_ui_clk]
  connect_bd_net -net mig_7series_0_c1_ui_clk_sync_rst [get_bd_pins clk_reset/pardcore_ext_reset] [get_bd_pins mig_7series_0/c1_ui_clk_sync_rst]
  connect_bd_net -net pardcore_reset_interconnect_aresetn [get_bd_ports pardcore_interconnect_rstn] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins clk_reset/pardcore_interconnect_rstn]
  connect_bd_net -net prm_corerst_1 [get_bd_pins PRMSYS/prm_corerst] [get_bd_pins clk_reset/prm_mb_reset]
  connect_bd_net -net prm_uncore_rstn_1 [get_bd_pins PRMSYS/prm_uncore_rstn] [get_bd_pins clk_reset/prm_peripheral_aresetn]
  connect_bd_net -net reset_100M_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins clk_reset/pardcore_mem_interconnect_rstn] [get_bd_pins leds_mux_controller_0/aresetn]
  connect_bd_net -net signal_detect_1 [get_bd_pins PRMSYS/signal_detect] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net sys_rst_1 [get_bd_ports sys_rst] [get_bd_pins mig_7series_0/sys_rst]
  connect_bd_net -net vc709_sfp_0_SFP_RS0 [get_bd_ports SFP_RS0] [get_bd_pins vc709_sfp_0/SFP_RS0]
  connect_bd_net -net vc709_sfp_0_SFP_TX_DISABLE [get_bd_ports SFP_TX_DISABLE] [get_bd_pins vc709_sfp_0/SFP_TX_DISABLE]
  connect_bd_net -net vc709_sfp_0_i2c_mux_rst_n [get_bd_ports i2c_mux_rst_n] [get_bd_pins vc709_sfp_0/i2c_mux_rst_n]
  connect_bd_net -net vc709_sfp_0_si5324_rst_n [get_bd_ports si5324_rst_n] [get_bd_pins vc709_sfp_0/si5324_rst_n]
  connect_bd_net -net vc709_sfp_0_signal_detect [get_bd_pins vc709_sfp_0/signal_detect] [get_bd_pins xlslice_0/Din]
  connect_bd_net -net xlconstant_3_dout [get_bd_pins leds_mux_controller_0/group_0] [get_bd_pins leds_mux_controller_0/group_1] [get_bd_pins leds_mux_controller_0/group_2] [get_bd_pins leds_mux_controller_0/group_default] [get_bd_pins xlconstant_01010101/dout]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces cdma_addr_0/m_axi] [get_bd_addr_segs mig_7series_0/c1_memmap/c1_memaddr] SEG_mig_7series_0_c1_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x44A00000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/cdma_block/axi_cdma_0/S_AXI_LITE/Reg] SEG_axi_cdma_0_Reg
  create_bd_addr_seg -range 0x08000000 -offset 0x60000000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/axi_emc_flash/S_AXI_MEM/MEM0] SEG_axi_emc_flash_MEM0
  create_bd_addr_seg -range 0x00040000 -offset 0x40C00000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/ethernet_block/axi_ethernet/s_axi/Reg0] SEG_axi_ethernet_Reg0
  create_bd_addr_seg -range 0x00010000 -offset 0x41E00000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/ethernet_block/axi_ethernet_dma/S_AXI_LITE/Reg] SEG_axi_ethernet_dma_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40010000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/axi_gpio_pardcore_corerstn/S_AXI/Reg] SEG_axi_gpio_pardcore_corerstn_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40000000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/axi_gpio_softreset/S_AXI/Reg] SEG_axi_gpio_softreset_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40800000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/axi_iic_0/S_AXI/Reg] SEG_axi_iic_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40610000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/pardcore_uart/axi_uartlite_0/S_AXI/Reg] SEG_axi_uartlite_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40620000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/pardcore_uart/axi_uartlite_1/S_AXI/Reg] SEG_axi_uartlite_1_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40630000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/pardcore_uart/axi_uartlite_2/S_AXI/Reg] SEG_axi_uartlite_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40640000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/pardcore_uart/axi_uartlite_3/S_AXI/Reg] SEG_axi_uartlite_3_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x7FFF8000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/prmcore_local_memory/dlmb_bram_dtb_cntlr/SLMB/Mem] SEG_dlmb_bram_dtb_cntlr_Mem
  create_bd_addr_seg -range 0x00004000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/prmcore_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00004000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/prmcore/Instruction] [get_bd_addr_segs PRMSYS/prmcore_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/prmcore/Instruction] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x00010000 -offset 0x41C00000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/prm_timer/S_AXI/Reg] SEG_prm_timer_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x40600000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/prm_uartlite/S_AXI/Reg] SEG_prm_uartlite_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces PRMSYS/prmcore/Data] [get_bd_addr_segs PRMSYS/prmcore_axi_intc/S_AXI/Reg] SEG_prmcore_axi_intc_Reg
  create_bd_addr_seg -range 0x80000000 -offset 0x00000000 [get_bd_addr_spaces PRMSYS/cdma_block/axi_cdma_0/Data] [get_bd_addr_segs cdma_addr_0/s_axi/reg0] SEG_cdma_addr_0_reg0
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/cdma_block/axi_cdma_0/Data] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/cdma_block/axi_cdma_0/Data_SG] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/ethernet_block/axi_ethernet_dma/Data_SG] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/ethernet_block/axi_ethernet_dma/Data_MM2S] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x80000000 -offset 0x80000000 [get_bd_addr_spaces PRMSYS/ethernet_block/axi_ethernet_dma/Data_S2MM] [get_bd_addr_segs mig_7series_0/c0_memmap/c0_memaddr] SEG_mig_7series_0_c0_memaddr
  create_bd_addr_seg -range 0x000100000000 -offset 0x00000000 [get_bd_addr_spaces S_AXI_MEM] [get_bd_addr_segs mig_7series_0/c1_memmap/c1_memaddr] SEG_mig_7series_0_c1_memaddr

  # Perform GUI Layout
  regenerate_bd_layout -layout_string {
   guistr: "# # String gsaved with Nlview 6.5.12  2016-01-29 bk=1.3547 VDI=39 GEI=35 GUI=JA:1.6
#  -string -flagsOSRD
preplace port sfp_mgt_clk -pg 1 -y 810 -defaultsOSRD
preplace port UART -pg 1 -y 850 -defaultsOSRD
preplace port sys_rst -pg 1 -y 150 -defaultsOSRD
preplace port linear_flash -pg 1 -y 690 -defaultsOSRD
preplace port S_AXI_MEM -pg 1 -y 560 -defaultsOSRD
preplace port pardcore_coreclk -pg 1 -y 990 -defaultsOSRD
preplace port C0_DDR3 -pg 1 -y 70 -defaultsOSRD
preplace port si5324_rst_n -pg 1 -y 1150 -defaultsOSRD
preplace port sfp -pg 1 -y 870 -defaultsOSRD
preplace port C0_SYS_CLK -pg 1 -y 130 -defaultsOSRD
preplace port SYS_UART0 -pg 1 -y 770 -defaultsOSRD
preplace port C1_DDR3 -pg 1 -y 90 -defaultsOSRD
preplace port pardcore_uncoreclk -pg 1 -y 970 -defaultsOSRD
preplace port i2c_mux_rst_n -pg 1 -y 1130 -defaultsOSRD
preplace port i2c_data -pg 1 -y 1110 -defaultsOSRD
preplace port i2c_clk -pg 1 -y 1090 -defaultsOSRD
preplace portBus SFP_TX_DISABLE -pg 1 -y 1230 -defaultsOSRD
preplace portBus buttons -pg 1 -y 1370 -defaultsOSRD
preplace portBus SFP_RS0 -pg 1 -y 1210 -defaultsOSRD
preplace portBus SFP_MOD_DETECT -pg 1 -y 1190 -defaultsOSRD
preplace portBus pardcore_interconnect_rstn -pg 1 -y 1030 -defaultsOSRD
preplace portBus pardcore_uncore_rstn -pg 1 -y 1010 -defaultsOSRD
preplace portBus leds -pg 1 -y 1390 -defaultsOSRD
preplace portBus SFP_LOS -pg 1 -y 1170 -defaultsOSRD
preplace portBus pardcore_corerstn -pg 1 -y 930 -defaultsOSRD
preplace inst cdma_addr_0 -pg 1 -lvl 1 -y 610 -defaultsOSRD
preplace inst xlslice_0 -pg 1 -lvl 2 -y 910 -defaultsOSRD
preplace inst axi_clock_converter_0 -pg 1 -lvl 2 -y 250 -defaultsOSRD
preplace inst mig_7series_0 -pg 1 -lvl 3 -y 160 -defaultsOSRD
preplace inst PRMSYS -pg 1 -lvl 3 -y 810 -defaultsOSRD
preplace inst xlconstant_01010101 -pg 1 -lvl 2 -y 1420 -defaultsOSRD
preplace inst leds_mux_controller_0 -pg 1 -lvl 3 -y 1390 -defaultsOSRD
preplace inst axi_interconnect_0 -pg 1 -lvl 2 -y 650 -defaultsOSRD
preplace inst vc709_sfp_0 -pg 1 -lvl 3 -y 1160 -defaultsOSRD
preplace inst clk_reset -pg 1 -lvl 1 -y 370 -defaultsOSRD
preplace netloc sys_rst_1 1 0 3 NJ 150 NJ 150 NJ
preplace netloc leds_mux_controller_0_leds 1 3 1 NJ
preplace netloc clk_reset_peripheral_aresetn1 1 1 2 NJ 120 1160
preplace netloc C0_SYS_CLK_1 1 0 3 NJ 130 NJ 130 NJ
preplace netloc PRMSYS_M_AXI_CDMA 1 0 4 0 100 NJ 100 NJ 350 1550
preplace netloc prm_uncore_rstn_1 1 1 2 N 470 NJ
preplace netloc LMB_Rst_1 1 1 2 N 350 NJ
preplace netloc PRM_CORE_sfp 1 3 1 NJ
preplace netloc PRMSYS_SYS_UART_0 1 3 1 NJ
preplace netloc clk_reset_peripheral_aresetn3 1 1 3 NJ 80 NJ 330 NJ
preplace netloc clk_reset_peripheral_aresetn 1 1 2 NJ 370 1110
preplace netloc clk_reset_clk_out1 1 1 2 N 490 NJ
preplace netloc PRMSYS_pardcore_corerstn 1 3 1 NJ
preplace netloc mig_7series_0_C0_DDR3 1 3 1 NJ
preplace netloc reset_100M_interconnect_aresetn 1 1 2 580 430 NJ
preplace netloc PRM_CORE_UART 1 3 1 NJ
preplace netloc vc709_sfp_0_signal_detect 1 1 3 610 990 NJ 990 1550
preplace netloc signal_detect_1 1 2 1 NJ
preplace netloc mig_7series_0_c1_mmcm_locked 1 0 4 60 140 NJ 140 NJ 310 1550
preplace netloc clk_reset_interconnect_aresetn 1 1 1 570
preplace netloc SFP_LOS_1 1 0 3 NJ 1170 NJ 1170 NJ
preplace netloc cdma_addr_0_m_axi 1 1 1 NJ
preplace netloc PRMSYS_MEM_AXI 1 1 3 680 340 NJ 340 1560
preplace netloc clk_reset_clk_out4 1 1 3 NJ 360 NJ 360 NJ
preplace netloc mig_7series_0_C1_DDR3 1 3 1 NJ
preplace netloc pardcore_reset_interconnect_aresetn 1 1 3 610 390 NJ 390 NJ
preplace netloc mig_7series_0_c0_mmcm_locked 1 0 4 -10 20 NJ 20 NJ 20 1550
preplace netloc clk_reset_mb_reset1 1 1 2 NJ 480 1030
preplace netloc sfp_mgt_clk_1 1 0 3 NJ 680 NJ 500 NJ
preplace netloc S01_ARESETN_1 1 1 2 640 440 NJ
preplace netloc PRMSYS_Debug_SYS_Rst 1 0 4 20 980 NJ 980 NJ 980 1550
preplace netloc vc709_sfp_0_SFP_TX_DISABLE 1 3 1 NJ
preplace netloc prm_corerst_1 1 1 2 600 400 NJ
preplace netloc ext_reset_in_1 1 0 4 10 10 NJ 10 NJ 10 1610
preplace netloc PRM_CORE_EMC_INTF 1 3 1 NJ
preplace netloc axi_interconnect_0_M00_AXI 1 2 1 1100
preplace netloc axi_clock_converter_0_M_AXI 1 2 1 1040
preplace netloc mig_7series_0_c1_ui_clk_sync_rst 1 0 4 50 110 NJ 110 NJ 300 1560
preplace netloc clk_wiz_1_clk_out2 1 1 2 620 420 NJ
preplace netloc vc709_sfp_0_si5324_rst_n 1 3 1 NJ
preplace netloc vc709_sfp_0_i2c_mux_rst_n 1 3 1 NJ
preplace netloc SFP_MOD_DETECT_1 1 0 3 NJ 1190 NJ 1190 NJ
preplace netloc Net1 1 3 1 NJ
preplace netloc Net 1 3 1 NJ
preplace netloc vc709_sfp_0_SFP_RS0 1 3 1 NJ
preplace netloc mig_7series_0_c1_ui_clk 1 0 4 30 670 680 450 1160 450 1570
preplace netloc clk_wiz_0_clk_out4 1 1 3 590 380 NJ 380 NJ
preplace netloc aclk_1 1 0 4 40 170 660 160 1130 320 1610
preplace netloc S_AXI_MEM_1 1 0 2 NJ 560 NJ
preplace netloc xlconstant_3_dout 1 2 1 1100
preplace netloc buttons_1 1 0 3 NJ 1370 NJ 1370 NJ
levelinfo -pg 1 -30 310 870 1360 1630 -top 0 -bot 1500
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


