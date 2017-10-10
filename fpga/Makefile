include Makefile.check

default: project

# vivado project name
PRJ ?= myproject
PRJ_FULL = $(PRJ)-$(BOARD)
VIVADO_FLAG = -nolog -nojournal -notrace

build_dir = $(realpath ./build)

#--------------------------------------------------------------------
# Project building and implementation
#--------------------------------------------------------------------

PRJ_ROOT = $(build_dir)/$(PRJ_FULL)
XPR_FILE = $(PRJ_ROOT)/$(PRJ_FULL).xpr
$(XPR_FILE):
	vivado $(VIVADO_FLAG) -mode batch -source board/$(BOARD)/mk.tcl -tclargs $(PRJ_FULL)

project: $(XPR_FILE)

vivado: $(XPR_FILE)
	vivado $(VIVADO_FLAG) $(XPR_FILE) &

clean:
	#-rm -rf $(build_dir)

.PHONY: default project vivado clean
