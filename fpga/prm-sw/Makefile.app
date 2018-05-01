.DEFAULT_GOAL = app

include $(PRM_SW_HOME)/Makefile.check
$(info Building $(NAME) [$(PLATFORM)])

APP_DIR ?= $(shell pwd)
INC_DIR += $(APP_DIR)/include/
DST_DIR ?= $(APP_DIR)/build/$(PLATFORM)/
BINARY ?= $(APP_DIR)/build/$(NAME)-$(PLATFORM)

INC_DIR += $(PRM_SW_HOME)/common/include/

$(shell mkdir -p $(DST_DIR))

include $(PRM_SW_HOME)/Makefile.compile

LINK_FILES += $(PRM_SW_HOME)/platform/build/platform-$(PLATFORM).a $(OBJS)
LINK_FILES += $(PRM_SW_HOME)/common/build/common-$(PLATFORM).a

.PHONY: app clean
app: $(OBJS) platform common
	$(CXX) -o $(BINARY) -Wl,--start-group $(LINK_FILES) -Wl,--end-group -lreadline

clean: 
	rm -rf $(APP_DIR)/build/
