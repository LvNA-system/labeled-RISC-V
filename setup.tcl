# get the directory where this script resides
set thisDir [file dirname [info script]]

if {[llength $argv] > 0} {
	set projectName $argv
} else {
	set projectName rocket
}


# these variables point to the root directory location
# of various source types - change this to point to 
# any directory location accessible to the machine
set projectRoot ./project
set rtlRoot $thisDir/srcs/rtl
set ipRoot $thisDir/srcs/ip
set bdRoot $thisDir/srcs/bd
set xdcRoot $thisDir/constrs

puts "INFO:  projectRoot is $projectRoot"
puts "INFO:  rtlRoot is $rtlRoot"
puts "INFO:  xdcRoot is $xdcRoot"
puts "INFO:  ipRoot is $ipRoot"
puts "INFO:  bdRoot is $bdRoot"


# Create project
create_project -force $projectName $projectRoot/$projectName/ -part xc7vx690tffg1761-2

# Set project properties
set obj [get_projects $projectName]
set_property "board_part" "xilinx.com:vc709:part0:1.8" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "Verilog" $obj
set_property coreContainer.enable 1 $obj

add_files -norecurse $rtlRoot/rocketchip_top.v
add_files -norecurse $rtlRoot/rocketchip.v

source $bdRoot/rocket_system.tcl

set bd_dir $projectRoot/$projectName/$projectName.srcs/sources_1/bd/rocket_system
set bd_file $bd_dir/rocket_system.bd
set_property synth_checkpoint_mode Hierarchical [get_files $bd_file]
make_wrapper -files [get_files $bd_file] -top
add_files -norecurse $bd_dir/hdl/rocket_system_wrapper.v
#add_files -norecurse $bdRoot/design_1.bd

set_property top rocket_system_wrapper [current_fileset]
update_compile_order -fileset sources_1

