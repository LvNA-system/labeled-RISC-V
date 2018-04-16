# compile dmi_client and controller
CC:=gcc
CFLAGS:=-Wall -Werror -O2 -I./include
COMMON_H:= JTAGDTM.h common.h client_common.h dmi.h
COMMON_CC:= common.cc client_common.cc
LINKERFLAGS:=-lreadline
COMMON_OBJ := common/util.o


all: dmi_client pard_controller

dmi_client: sim/dmi_client.o sim/client_common.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

pard_controller:pard_controller.cc $(COMMON_H) $(COMMON_CC)
	$(CC) $(CPPFLAGS) $^ -o $@ $(LINKERFLAGS)

clean:
	rm -rf dmi_client pard_controller
