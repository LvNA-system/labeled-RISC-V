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
CONFIG ?= PARDFPGAConfig

#--------------------------------------------------------------------
# Rocket-chip verilog source generation
#--------------------------------------------------------------------

-include $(base_dir)/Makefrag

gen_rtl = $(generated_dir)/$(long_name).v
srams_rtl = $(generated_dir)/$(long_name).behav_srams.v
other_rtl = $(base_dir)/vsrc/plusarg_reader.v

$(gen_rtl):
	$(MAKE) verilog -C $(base_dir)/vsim CONFIG=$(CONFIG) MODEL=$(MODEL) generated_dir=$(generated_dir)

$(srams_rtl): $(gen_rtl)

rocketchip_rtl = rtl/rocket/rocketchip.v

$(rocketchip_rtl): $(gen_rtl) $(base_dir)/vsrc/AsyncResetReg.v $(srams_rtl) $(other_rtl)
	cat $^ > $@
	sed -i -e 's/_\(aw\|ar\|w\|r\|b\)_\(\|bits_\)/_\1/g' $@

#--------------------------------------------------------------------
# PARD Chisel-impl part building and implementation
#--------------------------------------------------------------------
PARD_CP = ControlPlanes
PARD_CP_TARGET = rtl/control_plane/$(PARD_CP).v
PARD_CP_SRC_DIR = $(base_dir)/src/main/scala/uncore/pard/controlplane

$(PARD_CP_TARGET): $(shell find $(PARD_CP_SRC_DIR) -type f -name "*.scala")
	cd $(base_dir) && $(SBT) "runMain uncore.pard.CP"
	mv $(base_dir)/$(PARD_CP).v $@
	sed -i -e 's/_\(aw\|ar\|w\|r\|b\)_\(\|bits_\)/_\1/g' $@
	rm $(base_dir)/$(PARD_CP).fir $(base_dir)/$(PARD_CP).anno


verilog: $(rocketchip_rtl) $(PARD_CP_TARGET)

.PHONY: $(gen_rtl) verilog

#--------------------------------------------------------------------
# Cleaning
#--------------------------------------------------------------------

clean:
	-rm -rf $(generated_dir)
	-rm $(PARD_CP_TARGET)

.PHONY: default clean
