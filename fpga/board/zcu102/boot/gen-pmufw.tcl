# usage: hsi -nojournal -nolog -source [this tcl file] -tclargs [hdf file]

if {[llength $argv] > 0} {
  set hdf [lindex $argv 0]
} else {
  puts "hdf file path is not given!"
  return 1
}

set script_dir [file dirname [info script]]
set target_dir ${script_dir}/build/pmufw
generate_app -hw [open_hw_design ${hdf}] -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir ${target_dir}

puts "\[INFO\] ok! see ${target_dir}/executable.elf"

exit
