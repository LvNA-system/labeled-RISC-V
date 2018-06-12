#include "common.h"
#include "jtag.h"
#include "platform.h"

void help() {
  fprintf(stderr, "tgctl [start|stop]\n");
}

void invalid_command() {
  fprintf(stderr, "Invalid command. Command format:\n");
  help();
}

#define RUN 0x1
#define TRAFFIX_DISABLE 0x2

int main(int argc, char *argv[]) {
  bool tg_enable = false;
  char *ip = NULL;
  int port = 0;
  for (int i = 1; i < argc; i++) {
    char *arg = argv[i];
    if (strcmp(arg, "start") == 0)
      tg_enable = true;
	else if (strcmp(arg, "stop") == 0)
		tg_enable = false;
    else {
		invalid_command();
	}
  }

  init_platform(ip, port);

  resetn(RUN | (tg_enable ? 0x0 : TRAFFIX_DISABLE));

  finish_platform();
  return 0;
}
