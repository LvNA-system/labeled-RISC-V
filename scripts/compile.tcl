# get the directory where this script resides
set thisDir [file dirname [info script]]

if {[llength $argv] > 0} {
	set projectName [lindex $argv 0]
} else {
	set projectName rocket
}

set projectDir $thisDir/../../project/$projectName
open_project $projectDir/$projectName.xpr

# create runs for all OOC IP
foreach ip [get_files -filter {GENERATE_SYNTH_CHECKPOINT==1} *.xci] {
    create_ip_run $ip
}

# launch all ooc runs in parallel (8 jobs max)
launch_runs [get_runs *_synth*] -jobs 8

# then launch impl run
launch_runs impl_1
wait_on_run impl_1
open_run impl_1

write_bitstream -force $projectDir/$projectName.runs/impl_1/$projectName.bit
