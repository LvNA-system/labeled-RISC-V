base_dir = $(abspath ../..)
fpga_dir = $(abspath ..)
fpga_script_dir = $(fpga_dir)/scripts
build_dir = $(fpga_dir)/build
generated_dir = $(build_dir)/generated-src

CONFIG ?= LvNAConfigemu
NUMA_CONFIG ?=
SEED ?=

-include $(base_dir)/Makefrag

#--------------------------------------------------------------------
# Emulator generation
#--------------------------------------------------------------------

original_emu = $(base_dir)/emulator/emulator-$(PROJECT)-$(CONFIG)
emu = $(build_dir)/emu
emu_bin_file = $(build_dir)/linux.bin
emu_gen_script = gen_bin.sh
emu_bin_hex_file = $(build_dir)/bin.txt
nohype_dtb = $(build_dir)/c0.dtb
nohype_dtb_hex_file = $(build_dir)/c0.dtb.txt
# max_cycles = 40000000
max_cycles = 2209069

$(emu): $(original_emu)
	ln -sf $< $@

$(original_emu):
	$(MAKE) all -C $(base_dir)/emulator CONFIG=$(CONFIG) \
		generated_dir=$(generated_dir)

$(nohype_dtb): $(build_dir)/generated-src/freechips.rocketchip.system.$(CONFIG).dts
	dtc $^ -O dtb -o emu.dtb
	./gen_nohype_dtb emu.dtb $(build_dir) || echo "Please install python module 'pyfdt'"
	rm emu.dtb

$(nohype_dtb_hex_file): $(nohype_dtb)
	./gen_dtb_bin.sh $(build_dir)

$(emu_bin_hex_file): $(emu_bin_file)
	mkdir -p $(@D)
	bash $(emu_gen_script) $< $@

emu: $(emu)

ifdef DEBUG
DEBUG_ARGS = +jtag_rbb_enable=1 -r 4040
endif

run-emu: $(emu) $(emu_bin_hex_file) $(nohype_dtb_hex_file)
	cd $(dir $(emu)) && time $< $(DEBUG_ARGS) $(SEED) +verbose -m $(max_cycles) . 3>&1 1>&2 2>&3 \
		| spike-dasm > $(dir $(emu))/emu.log

dtb-clean:
	-rm -f $(build_dir)/c*.dtb{,.txt}

emu-clean:
	-rm $(emu)
	-$(MAKE) clean -C $(base_dir)/emulator

.PHONY: $(original_emu) emu run-emu emu-clean
