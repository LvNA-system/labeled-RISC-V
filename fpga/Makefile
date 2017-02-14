#=======================================================================
# Makefile for Verilog simulation w/ VCS
#-----------------------------------------------------------------------
# Yunsup Lee (yunsup@cs.berkeley.edu)
#
# This makefile will build a rtl simulator and run various tests to
# verify proper functionality.
#

default: verilog

# vivado project name
PRJ ?= myproject
VIVADO_FLAG = -nolog -nojournal

base_dir = $(abspath ..)
fpga_dir = $(abspath .)
fpga_script_dir = $(fpga_dir)/scripts
build_dir = $(fpga_dir)/build
generated_dir = $(build_dir)/generated-src

MODEL ?= PARDFPGAHarness
CONFIG ?= PARDFPGAConfig

#--------------------------------------------------------------------
# Rocket-chip verilog source generation
#--------------------------------------------------------------------

-include $(base_dir)/Makefrag

gen_rtl = $(generated_dir)/$(long_name).v $(generated_dir)/$(long_name).behav_srams.v

$(gen_rtl):
	cd $(base_dir)/vsim && $(MAKE) verilog CONFIG=$(CONFIG) MODEL=$(MODEL) generated_dir=$(generated_dir)

rocketchip_rtl = $(fpga_dir)/srcs/rtl/rocket/rocketchip.v

$(rocketchip_rtl): $(gen_rtl) $(base_dir)/vsrc/AsyncResetReg.v
	cat $^ > $@

verilog: $(rocketchip_rtl)

.PHONY: verilog

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

SIM_CONFIG ?= PARDSimConfig
original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(SIM_CONFIG)
emu_dir = $(fpga_dir)/emulator
emu = $(emu_dir)/emu

$(emu): $(original_emu)
	ln -sf $< $@

$(original_emu):
	cd $(base_dir)/emulator && $(MAKE) all CONFIG=$(SIM_CONFIG) \
		generated_dir=$(generated_dir) generated_dir_debug=$(generated_dir)

emu: $(emu)

run-emu: $(emu)
	cd $(emu_dir) && $< +verbose $(emu) 3>&1 1>&2 2>&3 | spike-dasm > $(fpga_dir)/emulator/emu.log

#--------------------------------------------------------------------
# Project building and implementation
#--------------------------------------------------------------------

PRJ_ROOT = $(build_dir)/$(PRJ)
XPR_FILE = $(PRJ_ROOT)/$(PRJ).xpr
$(XPR_FILE): | $(rocketchip_rtl)
	vivado $(VIVADO_FLAG) -mode batch -source $(fpga_script_dir)/setup.tcl -tclargs $(PRJ)

project: $(XPR_FILE)

BIT_FILE = $(PRJ_ROOT)/$(PRJ).runs/impl_1/$(PRJ).bit
$(BIT_FILE): | $(XPR_FILE)
	vivado $(VIVADO_FLAG) -mode batch -source $(fpga_script_dir)/compile.tcl -tclargs $(PRJ)

bitstream: $(BIT_FILE)


vivado: $(XPR_FILE)
	vivado $(VIVADO_FLAG) $(XPR_FILE) &

.PHONY: project bitstream vivado

#--------------------------------------------------------------------
# Cleaning
#--------------------------------------------------------------------

clean:
	-rm -rf $(generated_dir)

.PHONY: default clean
