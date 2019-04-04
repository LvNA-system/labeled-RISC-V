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

ifdef DEBUG
DEBUG_ARGS = +jtag_rbb_enable=1 -r 4040
endif

run-emu: $(emu) $(emu_bin_hex_file)
	cd $(dir $(emu)) && $< $(DEBUG_ARGS) +verbose -m 50000000 . 3>&1 1>&2 2>&3 \
		| spike-dasm > $(dir $(emu))/emu.log

remote_host = dnode13
ssn = $(CONFIG)_$(shell date '+%y%m%d_%H%M%S')
remote_dir = /home/zyy-work/projects/emu-run/

# the trick to define multiline string in Makefile
define newline


endef

define s
session_name: $(ssn)

windows:

- layout: main-vertical

  shell_command_before:

    - cd $(remote_dir)

  panes:

    - focus: 'true'

    - shell_command:

      - docker run --name emu-$(ssn) --rm -it \
        -v /home/zyy-work/projects/emu-run/:/home/ygbao/lvna/ \
        shinezyy/ubuntu-18.04:emu \
        /bin/bash -c "export LD_LIBRARY_PATH=\`pwd\`; \
        ./$(ssn).emu +verbose -m 50000000 . 3>&1 1>&2 2>&3 | ./spike-dasm > $(ssn).log"

    - shell_command:

      - sleep 1

      - echo "tail -f $(ssn).log"

    - shell_command:

      - sleep 1

      - tail -f serial60000000

  window_name: work

- window_name: avoid-prev-not-found

  panes:

    -

endef

remote-run: $(original_emu) $(emu_bin_hex_file)
	echo -e '$(subst $(newline),\n,${s})' > $(ssn).yml
	# ssh -t $(remote_host) "mkdir -p $(remote_dir)"
	scp $(original_emu) $(remote_host):$(remote_dir)$(ssn).emu
	rsync $(emu_bin_hex_file) $(remote_host):$(remote_dir)
	scp $(ssn).yml $(remote_host):/tmp
	ssh -t $(remote_host) "~/.local/bin/tmuxp load -d /tmp/$(ssn).yml"
	rm $(ssn).yml
	# ssh -t $(remote_host) rm /tmp/$(ssn).yml

emu-clean:
	-rm $(emu)
	-$(MAKE) clean -C $(base_dir)/emulator

.PHONY: $(original_emu) emu run-emu emu-clean
