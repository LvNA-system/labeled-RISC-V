# setting parameters

if {[llength $argv] > 0} {
  set project_name [lindex $argv 0]
  set s [split $project_name -]
  set prj [lindex $s 0]
  set brd [lindex $s 1]
} else {
  puts "project full name is not given!"
  return 1
}

set device xczu9eg-ffvb1156-2-e
set board xilinx.com:zcu102:part0:3.1
set topmodule system_top

set fpga_dir  [file dirname [info script]]/../..
set project_dir ${fpga_dir}/build/$project_name

create_project $project_name -force -dir $project_dir/ -part ${device}
set_property board_part $board [current_project] 

# the $brd variable will be passed to pardcore/mk.tcl
source ${fpga_dir}/pardcore/mk.tcl

# setting up the project
set script_dir  [file dirname [info script]]
set rtl_dir     ${script_dir}/rtl
set lib_dir     ${fpga_dir}/lib
set bd_dir      ${script_dir}/bd
set constr_dir  ${script_dir}/constr
set data_dir    ${script_dir}/data
set ip_dir      ${script_dir}/ip

# lib src files
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/include/axi.vh"]"
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/include/dmi.vh"]"
set_property is_global_include true [get_files "[file normalize "${lib_dir}/include/axi.vh"]"]
set_property is_global_include true [get_files "[file normalize "${lib_dir}/include/dmi.vh"]"]
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/jtag/axi4_lite_if.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/jtag/axi_jtag_v1_0.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/jtag/jtag_proc.v"]"

# Add files for system top
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/addr_mapper.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/system_top.v"]"

# Add files for constraint
add_files -norecurse -fileset constrs_1 "[file normalize "${constr_dir}/constr.xdc"]"


# Board Designs
source ${bd_dir}/prm.tcl
save_bd_design
close_bd_design $design_name
set_property synth_checkpoint_mode Hierarchical [get_files *${design_name}.bd]


# setting top module for FPGA flow and simulation flow
set_property "top" $topmodule [current_fileset]

# setting Synthesis options
set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]
# keep module port names in the netlist
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {none} [get_runs synth_1]

# setting Implementation options
set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]

# update compile order 
update_compile_order -fileset sources_1

