#=======================================================================
# Makefile for Verilog simulation w/ VCS
#-----------------------------------------------------------------------
# Yunsup Lee (yunsup@cs.berkeley.edu)
#
# This makefile will build a rtl simulator and run various tests to
# verify proper functionality.
#

default: verilog

fpga_dir = $(abspath ..)
base_dir = $(fpga_dir)/..
build_dir = $(fpga_dir)/build
generated_dir = $(build_dir)/generated-src

MODEL ?= PARDFPGAHarness
BOARD ?= zcu102
CONFIG = PARDFPGAConfig$(BOARD)

#--------------------------------------------------------------------
# Rocket-chip verilog source generation
#--------------------------------------------------------------------

-include $(base_dir)/Makefrag

gen_rtl = $(generated_dir)/$(long_name).v
srams_rtl = $(generated_dir)/$(long_name).behav_srams.v
other_rtl = $(base_dir)/vsrc/AsyncResetReg.v

$(gen_rtl):
	$(MAKE) verilog -C $(base_dir)/vsim CONFIG=$(CONFIG) MODEL=$(MODEL) generated_dir=$(generated_dir)

$(srams_rtl): $(gen_rtl)

rocketchip_rtl = rtl/rocket/rocketchip_board_$(BOARD).v

$(rocketchip_rtl): $(gen_rtl) $(srams_rtl) $(other_rtl)
	cat $^ > $@
	sed -i -e 's/_\(aw\|ar\|w\|r\|b\)_\(\|bits_\)/_\1/g' $@

verilog: $(rocketchip_rtl)

.PHONY: $(gen_rtl) verilog

#--------------------------------------------------------------------
# Cleaning
#--------------------------------------------------------------------

clean:
	-rm -rf $(generated_dir)

.PHONY: default clean
