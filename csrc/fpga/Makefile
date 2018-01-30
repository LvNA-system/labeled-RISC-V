CC:=g++
CPPFLAGS:=-Wall -Werror -std=c++0x -O2 -I..
all: server
server:server.cc ../common.cc ../JTAGDTM.h ../common.h
	$(CC) $(CPPFLAGS) $^ -o $@
clean:
	rm -rf server
