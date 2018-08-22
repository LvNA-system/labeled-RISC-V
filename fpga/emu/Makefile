base_dir = $(abspath ../..)
fpga_dir = $(abspath ..)
fpga_script_dir = $(fpga_dir)/scripts
build_dir = $(fpga_dir)/build
generated_dir = $(build_dir)/generated-src

CONFIG ?= LvNAConfigemu

-include $(base_dir)/Makefrag

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(CONFIG)
emu = $(build_dir)/emu
emu_bin_file = $(build_dir)/linux.bin
emu_gen_script = gen_bin.sh
emu_bin_hex_file = $(build_dir)/bin.txt

$(emu): $(original_emu)
	ln -sf $< $@

$(original_emu):
	$(MAKE) all -C $(base_dir)/emulator CONFIG=$(CONFIG) \
		generated_dir=$(generated_dir)

$(emu_bin_hex_file): $(emu_bin_file)
	mkdir -p $(@D)
	bash $(emu_gen_script) $< $@

emu: $(emu)

run-emu: $(emu) $(emu_bin_hex_file)
	cd $(dir $(emu)) && $< +verbose . 3>&1 1>&2 2>&3 | spike-dasm > $(dir $(emu))/emu.log

emu-clean:
	-rm $(emu)
	-$(MAKE) clean -C $(base_dir)/emulator

.PHONY: $(original_emu) emu run-emu emu-clean
