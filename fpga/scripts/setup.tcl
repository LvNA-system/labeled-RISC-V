# get the directory where this script resides
set thisDir [file dirname [info script]]

if {[llength $argv] > 0} {
	set projectName [lindex $argv 0]
} else {
	set projectName rocket
}


# these variables point to the root directory location
# of various source types - change this to point to 
# any directory location accessible to the machine
set projectRoot $thisDir/../build
set rtlRoot $thisDir/../srcs/rtl
set ipRoot $thisDir/../srcs/ip
set bdRoot $thisDir/../srcs/bd
set xdcRoot $thisDir/../constrs
set dataRoot $thisDir/../bram_data

puts "INFO:  projectRoot is $projectRoot"
puts "INFO:  rtlRoot is $rtlRoot"
puts "INFO:  xdcRoot is $xdcRoot"
puts "INFO:  ipRoot is $ipRoot"
puts "INFO:  bdRoot is $bdRoot"
puts "INFO:  dataRoot is $dataRoot"


# Create project
create_project -force $projectName $projectRoot/$projectName/ -part xc7vx690tffg1761-2

# Set project properties
set obj [get_projects $projectName]
set_property "board_part" "xilinx.com:vc709:part0:1.8" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "Verilog" $obj
set_property coreContainer.enable 1 $obj


# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$thisDir/ip"]" $obj
# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Add Constraints Files
set fileset constrs_1
set files [list \
 "[file normalize "$xdcRoot/vc709.xdc"]"\
]
add_files -norecurse -fileset $fileset $files
set_property "file_type" "XDC" [get_files -of_objects [get_filesets $fileset]]

# Add RTL Files
set fileset sources_1

# Add files for rocketchip
set files [list \
 "[file normalize "$rtlRoot/rocket/rocketchip.v"]"\
 "[file normalize "$rtlRoot/rocket/rocketchip_top.v"]"\
]
add_files -norecurse -fileset $fileset $files

# Add files for cpn
set files [list \
 "[file normalize "$rtlRoot/control_plane/cpn/i2c_slave.v"]"\
 "[file normalize "$rtlRoot/control_plane/cpn/i2c_switch_top.v"]"\
 "[file normalize "$rtlRoot/control_plane/cpn/i2c_switch.v"]"\
 "[file normalize "$rtlRoot/control_plane/cpn/i2c_wire.v"]"\
 "[file normalize "$rtlRoot/control_plane/cpn/mux8.v"]"\
]
add_files -norecurse -fileset $fileset $files

# Add files for control planes
set files [list \
 "[file normalize "$rtlRoot/control_plane/ControlPlanes.v"]"\
 "[file normalize "$rtlRoot/control_plane/common/i2cintf.v"]"\
 "[file normalize "$rtlRoot/control_plane/core/control_plane.v"]"\
 "[file normalize "$rtlRoot/control_plane/cache/control_plane.v"]"\
 "[file normalize "$rtlRoot/control_plane/mig/control_plane.v"]"\
]
add_files -norecurse -fileset $fileset $files

# Add files for Si5324/SFP Module
set files [list \
 "[file normalize "$rtlRoot/vc709_sfp/kcpsm6.vhd"]"\
 "[file normalize "$rtlRoot/vc709_sfp/clock_control_program_125M.vhd"]"\
 "[file normalize "$rtlRoot/vc709_sfp/clock_control.vhd"]"\
 "[file normalize "$rtlRoot/vc709_sfp/vc709_sfp.v"]"\
]
add_files -norecurse -fileset $fileset $files

# Add files for Xilinx AXI4 cache
set files [list \
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_a_channel.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_arbiter.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_access.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_m_axi_interface.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/system_cache_pkg.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_stat_counter.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_opt_interface.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_gen_interface.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_r_channel.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_lru_module.v"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/xlnx_cache_pard_ooc.xdc"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/xlnx_cache_pard.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_lookup.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_length_generation.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_ctrl_interface.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_stat_latency.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_back_end.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_front_end.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/system_cache.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_stat_event.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_update.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_statistics_counters.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_cache_core.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_srl_fifo_counter.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_primitives.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_w_channel.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_s_axi_b_channel.vhd"]"\
 "[file normalize "$rtlRoot/xlnx_cache_pard/sc_ram_module.vhd"]"\
]
add_files -norecurse -fileset $fileset $files

# Add files for miscellaneous
set files [list \
 "[file normalize "$rtlRoot/misc/axi_reg.v"]"\
 "[file normalize "$rtlRoot/misc/uart_inverter.v"]"\
 "[file normalize "$rtlRoot/misc/cdma_addr.v"]"\
 "[file normalize "$rtlRoot/misc/cross_domain.v"]"\
 "[file normalize "$rtlRoot/misc/leds_mux_controller.v"]"\
 "[file normalize "$rtlRoot/include/axi.vh"]"\
 "[file normalize "$rtlRoot/include/dmi.vh"]"\
]
add_files -norecurse -fileset $fileset $files

# Add ELF data file
set files [list \
 "[file normalize "$dataRoot/prmcore-fsboot-dtb.elf"]"\
]
add_files -norecurse -fileset $fileset $files



source $bdRoot/system_top.tcl
set design_name [get_bd_designs]
save_bd_design
close_bd_design $design_name
set_property synth_checkpoint_mode Hierarchical [get_files *${design_name}.bd]
make_wrapper -files [get_files *${design_name}.bd] -top
add_files -norecurse $projectRoot/$projectName/$projectName.srcs/sources_1/bd/$design_name/hdl/${design_name}_wrapper.v
set_property top ${design_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1


# Add first stage bootloader ELF
## Bootloader for PRM
set file "bram_data/prmcore-fsboot-dtb.elf"
set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]
set_property "scoped_to_cells" "PRMSYS/PRM_CORE/prmcore" $file_obj
set_property "scoped_to_ref" "system_top" $file_obj
set_property "used_in_simulation" "0" $file_obj


# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
	create_run synth_1 -part xc7vx690tffg1761-2 -flow {Vivado Synthesis 2016} -strategy {Vivado Synthesis Defaults}
} else {
	set_property strategy {Vivado Synthesis Defaults} [get_runs synth_1]
	set_property flow "Vivado Synthesis 2016" [get_runs synth_1]
}
current_run [get_runs synth_1]

# create runs for all OOC IP
foreach ip [get_files -filter {GENERATE_SYNTH_CHECKPOINT==1} *.xci] {
    create_ip_run $ip
}

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
	create_run -name impl_1 -part xc7vx690tffg1761-2 -flow {Vivado Implementation 2016} -strategy {Vivado Implementation Defaults} -constrset constrs_1 -parent_run synth_1
}
current_run [get_runs impl_1]
