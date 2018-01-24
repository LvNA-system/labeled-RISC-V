# usage: hsi -nojournal -nolog -source [this tcl file] -tclargs [hdf file]

if {[llength $argv] > 0} {
  set hdf [lindex $argv 0]
} else {
  puts "hdf file path is not given!"
  return 1
}

set script_dir [file dirname [info script]]
set target_dir ${script_dir}/build/fsbl
generate_app -hw [open_hw_design ${hdf}] -os standalone -proc ps7_cortexa9_0 -app zynq_fsbl -compile -sw fsbl -dir ${target_dir}

puts "\[INFO\] ok! see ${target_dir}/executable.elf"

exit
