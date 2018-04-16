#include "common.h"
#include "client_common.h"
#include <stdlib.h>

static void help(void);

static void invalid_command(void);

int main(int argc, char *argv[]) {
  char *ip = NULL;
  int port = 0;
  for (int i = 1; i < argc; i++) {
    char *arg = argv[i];
    if (strncmp(arg, "-p", 2) == 0)
      port = atoi(argv[i] + 2);
    else if (strncmp(arg, "-ip", 3) == 0)
      ip = argv[i] + 3;
  }

  connect_server(ip == NULL ? "127.0.0.1" : ip, port == 0 ? 8080 : port);
  init_dtm();

  while (1) {
    fflush(stdout);
    char *line = NULL;
    if(!(line = rl_gets()))
      break;
    char cmd[1024] = {'\0'};
    char reg[1024] = {'\0'};
    int cnt = 0;

    if (sscanf(line, "%s %n",cmd, &cnt) != 1) {
      invalid_command();
      help();
      break;
    }

    if (!strcmp(cmd, "help")) {
      help();
      break;
    }

    line += cnt;

    if (sscanf(line, "%s %n",reg, &cnt) != 1) {
      invalid_command();
      help();
      break;
    }
    else {
      line += cnt;
      handle_debug_request(cmd, reg, line);
    }
  }

  disconnect_server();
  return 0;
}

static void help(void) {
  fprintf(stderr, "Command format:\n"
      "\tread/write debug_module_register_name field_1=value_1 field_2=value_2\n"
      "Example:\n"
      "\t1. send interrupt to hart 0\n"
      "\t   write dmcontrol hartid=0 interrupt=1\n");
}

static void invalid_command(void) {
  fprintf(stderr, "Invalid command, use \"help\" to see the command format\n");
}
