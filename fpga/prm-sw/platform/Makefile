NAME = platform
SRCS = $(shell find -L platform-$(PLATFORM)/src/ -name "*.c")

PRM_SW_HOME = $(shell echo $(abspath .) | sed -e 's+/prm-sw/.*+/prm-sw+')
include $(PRM_SW_HOME)/Makefile.lib
