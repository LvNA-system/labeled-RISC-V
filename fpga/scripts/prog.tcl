# Please link the target bitstream file as prog.bit under
# this directory before running this script in vivado

set board_id 210203826486A

open_hw
connect_hw_server -url 10.30.6.123:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/$board_id]
set_property PARAM.FREQUENCY 30000000 [get_hw_targets */xilinx_tcf/Digilent/$board_id]
open_hw_target

current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {prog.bit} [lindex [get_hw_devices] 0]
#set_property PROBES.FILE {design.ltx} [lindex [get_hw_devices] 0]

program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]

close_hw
