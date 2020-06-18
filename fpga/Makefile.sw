# check RISCV environment variable
ifndef RISCV
$(error Please set environment variable RISCV. Please take a look at README)
endif

build_dir = $(realpath ./build)
SW_PATH = $(abspath ../../sw)

$(SW_PATH):
	@echo "Do you want to put all software repos under $(SW_PATH) (You can modify 'SW_PATH' in Makefile.sw)? [y/n]"
	@read r; test $$r = "y"
	mkdir -p $(SW_PATH)

#--------------------------------------------------------------------
# Build tools
#--------------------------------------------------------------------

RISCV_PREFIX=riscv64-unknown-linux-gnu-
CC = $(RISCV_PREFIX)gcc
LD = $(RISCV_PREFIX)ld
RISCV_COPY = $(RISCV_PREFIX)objcopy
RISCV_COPY_FLAGS = --set-section-flags .bss=alloc,contents --set-section-flags .sbss=alloc,contents -O binary

#--------------------------------------------------------------------
# BBL variables
#--------------------------------------------------------------------

BBL_REPO_PATH = $(SW_PATH)/riscv-pk
BBL_BUILD_COMMIT = 852a0cfcb4ca5d8939cf1f4f4edc898ba6c9fa50

BBL_BUILD_PATH = $(BBL_REPO_PATH)/build
BBL_ELF_BUILD = $(BBL_BUILD_PATH)/bbl

BBL_PAYLOAD = $(LINUX_ELF)
BBL_CONFIG = --host=riscv64-unknown-elf --with-payload=$(BBL_PAYLOAD) --with-arch=rv64imac --enable-logo

BBL_ELF = $(build_dir)/bbl.elf
BBL_BIN = $(build_dir)/linux.bin

#--------------------------------------------------------------------
# Linux variables
#--------------------------------------------------------------------

LINUX_REPO_PATH = $(SW_PATH)/riscv-linux
LINUX_BUILD_COMMIT = 8e82b151eb00e268428ccd3f751485972d8c140d

LINUX_ELF_BUILD = $(LINUX_REPO_PATH)/vmlinux
LINUX_ELF = $(build_dir)/vmlinux

ROOTFS_PATH = $(SW_PATH)/riscv-rootfs
RFS_ENV = RISCV_ROOTFS_HOME=$(ROOTFS_PATH)

#--------------------------------------------------------------------
# BBL rules
#--------------------------------------------------------------------

bbl: $(BBL_BIN)

$(BBL_BIN): $(BBL_ELF)
	$(RISCV_COPY) $(RISCV_COPY_FLAGS) $< $@

$(BBL_ELF): $(BBL_ELF_BUILD)
	ln -sf $(abspath $<) $@

$(BBL_REPO_PATH): | $(SW_PATH)
	mkdir -p $@
	git clone https://github.com/LvNA-system/riscv-pk.git $@

$(BBL_BUILD_PATH): $(BBL_PAYLOAD) | $(BBL_REPO_PATH)
	mkdir -p $@
	cd $@ && \
		git checkout $(BBL_BUILD_COMMIT) && \
		($(BBL_REPO_PATH)/configure $(BBL_CONFIG) || (git checkout @{-1}; false)) && \
		git checkout @{-1}

$(BBL_ELF_BUILD): | $(BBL_BUILD_PATH)
	cd $(@D) && \
		git checkout $(BBL_BUILD_COMMIT) && \
		($(RFS_ENV) $(MAKE) || (git checkout @{-1}; false)) && \
		git checkout @{-1}

bbl-clean:
	-rm $(BBL_ELF) $(BBL_BIN)
	-$(RFS_ENV) $(MAKE) clean -C $(BBL_BUILD_PATH)

.PHONY: bbl bbl-clean $(BBL_ELF_BUILD)

#--------------------------------------------------------------------
# Linux rules
#--------------------------------------------------------------------

$(LINUX_REPO_PATH): | $(SW_PATH)
	mkdir -p $@
	@/bin/echo -e "\033[1;31mBy default, a shallow clone with only 1 commit history is performed, since the commit history is very large.\nThis is enough for building the project.\nTo fetch full history, run 'git fetch --unshallow' under $(LINUX_REPO_PATH).\033[0m"
	git clone --depth 1 https://github.com/LvNA-system/riscv-linux.git $@
	cd $@ && $(RFS_ENV) $(MAKE) ARCH=riscv emu_defconfig

$(ROOTFS_PATH): | $(SW_PATH)
	mkdir -p $@
	@/bin/echo -e "\033[1;31mPlease manually set the RISCV_ROOTFS_HOME environment variable to $(ROOTFS_PATH).\033[0m"
	git clone https://github.com/LvNA-system/riscv-rootfs.git $@

linux: $(LINUX_ELF)

$(LINUX_ELF): $(LINUX_ELF_BUILD)
	ln -sf $(abspath $<) $@

$(LINUX_ELF_BUILD): | $(LINUX_REPO_PATH) $(ROOTFS_PATH)
	$(RFS_ENV) $(MAKE) -C $(ROOTFS_PATH)
	cd $(@D) && \
		git checkout $(LINUX_BUILD_COMMIT) && \
		(($(RFS_ENV) $(MAKE) CROSS_COMPILE=$(RISCV_PREFIX) ARCH=riscv vmlinux) || (git checkout @{-1}; false)) && \
		git checkout @{-1}

linux-clean:
	-rm $(LINUX_ELF)
	-$(RFS_ENV) $(MAKE) clean -C $(LINUX_REPO_PATH)

.PHONY: linux linux-clean $(LINUX_ELF_BUILD)


#--------------------------------------------------------------------
# Software top-level rules
#--------------------------------------------------------------------

sw: bbl

sw-clean: bbl-clean linux-clean
	-$(RFS_ENV) $(MAKE) -C $(ROOTFS_PATH) clean

.PHONY: sw sw-clean
