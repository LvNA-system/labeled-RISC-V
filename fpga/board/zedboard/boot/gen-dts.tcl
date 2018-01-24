# usage: hsi -nojournal -nolog -source [this tcl file] -tclargs [hdf file]

set device_tree_repo_path "/home/yzh/xilinx/device-tree-xlnx"

if {[llength $argv] > 0} {
  set hdf [lindex $argv 0]
} else {
  puts "hdf file path is not given!"
  return 1
}

set script_dir [file dirname [info script]]
set target_dir ${script_dir}/build/dts
open_hw_design ${hdf}
set_repo_path ${device_tree_repo_path}
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
set_property CONFIG.periph_type_overrides "{BOARD zedboard}" [get_os]
generate_target -dir ${target_dir}

puts "\[INFO\] ok! see ${target_dir}/"

exit
