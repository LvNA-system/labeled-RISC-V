# (c) Copyright 2014 Xilinx, Inc. All rights reserved.

# Add in a clock definition for each input clock to the out-of-context module.
# The module will be synthesized as top so reference the clock origin using get_ports.
# You will need to define a clock on each input clock port, no top level clock information
# is provided to the module when set as out-of-context.
# Here is an example:
# create_clock -name clk_200 -period 5 [get_ports clk]

create_clock -name clk_200 -period 5 [get_ports ACLK]
