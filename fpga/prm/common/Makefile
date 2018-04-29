NAME = common
SRCS = $(shell find . -name "*.c")

PRM_SW_HOME = $(shell echo $(abspath .) | sed -e 's+fpga/prm.*+fpga/prm+')
include $(PRM_SW_HOME)/Makefile.lib
