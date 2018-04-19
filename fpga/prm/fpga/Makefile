CC:=gcc
CFLAGS:=-Wall -Werror -O2 -I../include
LINKERFLAGS:=-lreadline

all: server pardctl pardweb

COMMON_OBJ = ../common/util.o map.o jtag.o

server: server.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

pardctl: pardctl.o ../common/dtm-loader.o ../common/cp.o cp.o readline.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

pardweb: pardweb.o ../common/cp.o cp.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

clean:
	rm -rf server pardctl pardweb *.o
