# compile dmi_client and controller
CC:=g++
CPPFLAGS:=-Wall -Werror -std=c++0x -O2
COMMON_H:= JTAGDTM.h common.h client_common.h dmi.h
COMMON_CC:= common.cc client_common.cc
LINKERFLAGS:=-lreadline


all: dmi_client pard_controller
dmi_client:$(COMMON_H) $(COMMON_CC) dmi_client.cc
	$(CC) $(CPPFLAGS) $^ -o $@ $(LINKERFLAGS)

pard_controller:pard_controller.cc $(COMMON_H) $(COMMON_CC)
	$(CC) $(CPPFLAGS) $^ -o $@ $(LINKERFLAGS)

clean:
	rm -rf dmi_client pard_controller
