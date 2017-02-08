# get the directory where this script resides
set thisDir [file dirname [info script]]

if {[llength $argv] > 0} {
	set projectName [lindex $argv 0]
} else {
	set projectName rocket
}

set projectDir $thisDir/../build/$projectName
open_project $projectDir/$projectName.xpr

# launch impl run
launch_runs impl_1 -jobs 36
wait_on_run impl_1
open_run impl_1

write_bitstream -force $projectDir/$projectName.runs/impl_1/$projectName.bit
