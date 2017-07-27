#include "dmi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>


struct Entry {
  char name[20];
  uint32_t addr;
  void (*req_builder)(struct DMI_Req *, char *);
  void (*resp_handler)(uint32_t data);
};


#define STR(x) #x

#define CONCAT(x, y) x ## y

#define FIELD(name, bits) if (strcmp(STR(name), s) == 0) { msg->name = value; continue; }

#define PARSE_OPTION(type) do { \
  for (char *s = strtok(options, " "); s != NULL; s = strtok(NULL, " ")) { \
    char *eq = strchr(s, '='); \
    *eq = '\0'; \
    uint32_t value = (uint32_t)strtol(eq + 1, NULL, 16); \
    CONCAT(type, _FIELDS) \
  } \
} while(0)

void dmcontrol_req(struct DMI_Req *req, char *options) {
  struct DMControl *msg = &req->dmcontrol;
  PARSE_OPTION(DMCONTROL);
}

#undef FIELD

struct Entry entries[] = {
  { "data0", 0x04, NULL, NULL },
  { "dmcontrol", 0x10, &dmcontrol_req, NULL },
  { "dmstatus", 0x11, NULL, NULL },
  { "hartinfo", 0x12, NULL, NULL },
  { "haltsum", 0x13, NULL, NULL },
  { "abstracts", 0x16, NULL, NULL },
  { "command", 0x17, NULL, NULL },
};


int main(int argc, char *argv[])
{
  // Socket
  int sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd == -1) {
    perror("Failed to create socket");
    exit(-1);
  }

  // Config server
  struct sockaddr_in server;
  server.sin_addr.s_addr = inet_addr("127.0.0.1");
  server.sin_family = AF_INET;
  server.sin_port = htons(8080);

  // Connect
  if (connect(sfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect failed");
    exit(-1);
  }

  puts("Connected\n");

  struct DMI_Req req;
  struct DMI_Resp resp;
  char msg[1024];
  while (1) {
    printf("> ");
    fflush(stdout);
    memset(&req, 0, sizeof(req));

    scanf("%s", msg);
    if      (strcmp(msg, "read")  == 0) req.opcode = OP_READ;
    else if (strcmp(msg, "write") == 0) req.opcode = OP_WRITE;
    else if (strcmp(msg, "quit")  == 0) break;

    scanf("%s", msg);
    for (int i = 0; i < sizeof(entries) / sizeof(entries[0]); i++) {
      if (strcmp(entries[i].name, msg) == 0) {
        req.addr = entries[i].addr;
        if (req.opcode == OP_WRITE) {
          fgets(msg, sizeof(msg), stdin);
          entries[i].req_builder(&req, msg);
        }
        break;
      }
    }

    send(sfd, &req, sizeof(req), 0);

    recv(sfd, &resp, sizeof(resp), 0);
    printf("resp: %d, %08x\n", resp.state, resp.data);
  }

  close(sfd);
}
