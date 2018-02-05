CC:=g++
CPPFLAGS:=-Wall -Werror -std=c++0x -O2 -I..
COMMON_H:= ../JTAGDTM.h ../common.h ../dmi.h
COMMON_CC:= ../common.cc
LINKERFLAGS:=-lreadline
all: server jtag pardweb
server:server.cc $(COMMON_H) $(COMMON_CC)
	$(CC) $(CPPFLAGS) $^ -o $@
jtag:jtag.cc $(COMMON_H) $(COMMON_CC)
	$(CC) $(CPPFLAGS) $^ -o $@ $(LINKERFLAGS) $(LINKERFLAGS)
pardweb:pardweb.cc $(COMMON_H) $(COMMON_CC)
	$(CC) $(CPPFLAGS) $^ -o $@ $(LINKERFLAGS) $(LINKERFLAGS)

clean:
	rm -rf server pard_controller jtag pardweb
