CC:=gcc
CFLAGS:=-Wall -Werror -O2 -I../include
LINKERFLAGS:=-lreadline

all: server cp pardweb

COMMON_OBJ = ../common/util.o map.o

server: server.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

cp: dtm.o cp.o readline.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

pardweb: pardweb.o cp.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

clean:
	rm -rf server cp pardweb
