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
# Software generation
#--------------------------------------------------------------------

-include Makefile.sw

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

rocketchip_rtl = $(fpga_dir)/srcs/rtl/rocket/rocketchip.v

$(rocketchip_rtl): $(gen_rtl) $(base_dir)/vsrc/AsyncResetReg.v $(srams_rtl) $(other_rtl)
	cat $^ > $@

verilog: $(rocketchip_rtl)

.PHONY: $(gen_rtl) verilog

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

SIM_CONFIG ?= PARDSimConfig
original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(SIM_CONFIG)
emu = $(build_dir)/emu
emu_bin_file = $(fpga_dir)/emulator/bbl.bin
emu_gen_script = $(fpga_dir)/emulator/gen_bin.sh
emu_bin_hex_file = $(dir $(emu))/bin.txt

$(emu): $(original_emu)
	ln -sf $< $@

$(original_emu):
	$(MAKE) all -C $(base_dir)/emulator CONFIG=$(SIM_CONFIG) \
		generated_dir=$(generated_dir) generated_dir_debug=$(generated_dir)

$(emu_bin_hex_file): $(emu_bin_file)
	cd $(dir $(emu)) && bash $(emu_gen_script) $<

emu: $(emu)

run-emu: $(emu) $(emu_bin_hex_file)
	cd $(dir $(emu)) && $< +verbose . 3>&1 1>&2 2>&3 | spike-dasm > $(dir $(emu))/emu.log

emu-clean:
	-rm $(emu)
	-$(MAKE) clean -C $(base_dir)/emulator

.PHONY: $(original_emu) emu run-emu emu-clean

#--------------------------------------------------------------------
# PARD Chisel-impl part building and implementation
#--------------------------------------------------------------------
PARD_CP = ControlPlanes
PARD_CP_TARGET = $(fpga_dir)/srcs/rtl/control_plane/$(PARD_CP).v
PARD_CP_SRC_DIR = $(base_dir)/src/main/scala/uncore/pard/controlplane

$(PARD_CP_TARGET): $(shell find $(PARD_CP_SRC_DIR) -type f -name "*.scala")
	cd $(base_dir) && $(SBT) "runMain uncore.pard.CP"
	mv $(base_dir)/$(PARD_CP).v $(PARD_CP_TARGET)
	rm $(base_dir)/$(PARD_CP).fir $(base_dir)/$(PARD_CP).anno

pard-cp-clean:
	-rm $(PARD_CP_TARGET)

#--------------------------------------------------------------------
# Project building and implementation
#--------------------------------------------------------------------

PRJ_ROOT = $(build_dir)/$(PRJ)
XPR_FILE = $(PRJ_ROOT)/$(PRJ).xpr
$(XPR_FILE): $(PARD_CP_TARGET) | $(rocketchip_rtl)
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

clean: pard-cp-clean
	-rm -rf $(generated_dir)

.PHONY: default clean
