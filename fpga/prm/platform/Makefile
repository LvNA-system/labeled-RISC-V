NAME = platform
SRCS = $(shell find -L platform-$(PLATFORM)/src/ -name "*.c")

PRM_SW_HOME = $(shell echo $(abspath .) | sed -e 's+fpga/prm.*+fpga/prm+')
include $(PRM_SW_HOME)/Makefile.lib
