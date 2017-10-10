base_dir = $(abspath ../..)
fpga_dir = $(abspath ..)
fpga_script_dir = $(fpga_dir)/scripts
build_dir = $(fpga_dir)/build
generated_dir = $(build_dir)/generated-src

-include $(base_dir)/Makefrag

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

SIM_CONFIG ?= PARDSimConfig
original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(SIM_CONFIG)
emu = $(build_dir)/emu
emu_bin_file = bbl.bin
emu_gen_script = gen_bin.sh
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
