# compile dmi_client and controller
CC:=gcc
CFLAGS:=-Wall -Werror -O2 -I./include
LINKERFLAGS:=-lreadline
COMMON_OBJ := common/util.o sim/client_common.o


all: dmi_client pard_controller

dmi_client: sim/dmi_client.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

pard_controller: sim/pard_controller.o common/dtm-loader.o common/cp.o sim/cp.o $(COMMON_OBJ)
	$(CC) $^ -o $@ $(LINKERFLAGS)

clean:
	rm -rf dmi_client pard_controller
