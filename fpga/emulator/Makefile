fpga_dir = $(abspath ..)
base_dir = $(fpga_dir)/..
build_dir = $(abspath ./build/$(PRJ))
generated_dir = $(build_dir)/generated-src
generated_dir_debug = $(build_dir)/generated-src-debug

PRJ ?= test
CONFIG = PARDSimConfig
boot = DIRECTBOOT

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

-include $(base_dir)/Makefrag

original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(CONFIG)
emu = $(build_dir)/emu
emu_bin_file = $(fpga_dir)/build/linux.bin
emu_gen_script = gen_bin.sh
emu_bin_hex_file = $(build_dir)/bin.txt

$(emu): $(original_emu)
	ln -sf $< $@

$(original_emu):
	$(MAKE) all -C $(base_dir)/emulator CONFIG=$(CONFIG) MODEL=$(MODEL) \
		generated_dir=$(generated_dir) generated_dir_debug=$(generated_dir_debug) \
		boot=$(boot)

$(emu_bin_hex_file): $(emu_bin_file)
	mkdir -p $(@D)
	bash $(emu_gen_script) $< $@

emu: $(emu)

run-emu: $(emu) $(emu_bin_hex_file)
	cd $(build_dir) && $< +verbose -p$(shell shuf -i 10000-20000 -n 1) . 3>&1 1>&2 2>&3 | spike-dasm > $(build_dir)/emu.log

clean:
	-rm -rf ./build
	-$(MAKE) clean -C $(base_dir)/emulator

.PHONY: $(original_emu) emu run-emu clean
