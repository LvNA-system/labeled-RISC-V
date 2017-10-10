# setting parameters

if {[llength $argv] > 0} {
  set project_name [lindex $argv 0]
  set s [split $project_name -]
  set prj [lindex $s 0]
  set board [lindex $s 1]
} else {
  puts "project full name is not given!"
  return 1
}

set device xc7vx690tffg1761-2
set board xilinx.com:vc709:part0:1.8
set topmodule system_top

set fpga_dir  [file dirname [info script]]/../..
set project_dir ${fpga_dir}/build/$project_name

create_project $project_name -force -dir $project_dir/ -part ${device}
set_property board_part $board [current_project] 

set_property verilog_define {{HAS_CACHE}} [get_fileset sources_1]
set_property verilog_define {{HAS_CACHE}} [get_fileset sim_1]
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
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/util/cdma_addr.v"]"
add_files -norecurse -fileset sources_1 "[file normalize "${lib_dir}/util/leds_mux_controller.v"]"
set_property is_global_include true [get_files "[file normalize "${lib_dir}/include/axi.vh"]"]
set_property is_global_include true [get_files "[file normalize "${lib_dir}/include/dmi.vh"]"]

# Add files for Si5324/SFP Module
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/vc709_sfp/kcpsm6.vhd"]"
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/vc709_sfp/clock_control_program_125M.vhd"]"
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/vc709_sfp/clock_control.vhd"]"
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/vc709_sfp/vc709_sfp.v"]"

# Add files for system top
add_files -norecurse -fileset sources_1 "[file normalize "${rtl_dir}/system_top.v"]"


# Add ELF data file
add_files -norecurse -fileset sources_1 "[file normalize "${data_dir}/prmcore-fsboot-dtb.elf"]"


# Board Designs
source ${bd_dir}/prm.tcl
save_bd_design
close_bd_design $design_name
set_property synth_checkpoint_mode Hierarchical [get_files *${design_name}.bd]

# Add first stage bootloader ELF
## Bootloader for PRM
set file "${data_dir}/prmcore-fsboot-dtb.elf"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "scoped_to_ref" "prm" $file_obj
set_property "scoped_to_cells" "PRMSYS/prmcore" $file_obj
set_property "used_in_simulation" "0" $file_obj


# contraints files
add_files -norecurse -fileset constrs_1 "[file normalize "${constr_dir}/vc709.xdc"]"
set_property "file_type" "XDC" [get_files -of_objects [get_filesets constrs_1]]

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

