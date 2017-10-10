`define dmi_single_signal(interface_name, regular_name, in_out, width, prefix) \
  (* X_INTERFACE_INFO = `"riscv:rocket:dmi:1.0 interface_name regular_name`" *) \
  in_out [width - 1: 0] prefix``_``regular_name

`define dmi_connect_single_signal(io_prefix, wire_prefix, signal_name) \
	io_prefix``_``signal_name(wire_prefix``_``signal_name)

/* dir1 for master sends, dir2 for master recvs */
`define debug_interface(interface_name, dir1, dir2, prefix) \
	`dmi_single_signal(interface_name, req_valid,      dir1, 1,  prefix), \
	`dmi_single_signal(interface_name, req_ready,      dir2, 1,  prefix), \
	`dmi_single_signal(interface_name, req_bits_op,    dir1, 2,  prefix), \
	`dmi_single_signal(interface_name, req_bits_addr,  dir1, 7,  prefix), \
	`dmi_single_signal(interface_name, req_bits_data,  dir1, 32, prefix), \
	`dmi_single_signal(interface_name, resp_valid,     dir2, 1,  prefix), \
	`dmi_single_signal(interface_name, resp_ready,     dir1, 1,  prefix), \
	`dmi_single_signal(interface_name, resp_bits_resp, dir2, 2,  prefix), \
	`dmi_single_signal(interface_name, resp_bits_data, dir2, 32, prefix)

`define dmi_connect(io_prefix, wire_prefix) \
   `dmi_connect_single_signal(io_prefix, wire_prefix, req_valid     ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, req_ready     ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, req_bits_op   ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, req_bits_addr ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, req_bits_data ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, resp_valid    ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, resp_ready    ), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, resp_bits_resp), \
  .`dmi_connect_single_signal(io_prefix, wire_prefix, resp_bits_data)



`define dmi_master(interface_name, prefix) \
  `debug_interface(interface_name, output, input, prefix)

`define dmi_slave(interface_name, prefix) \
  `debug_interface(interface_name, input, output, prefix)
