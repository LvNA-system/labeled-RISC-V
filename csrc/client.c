#include "dmi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

#define STR(x) #x

#define CONCAT(x, y) x ## y

/**
 * Request builder definitions
 */
#define FIELD(name, bits) if (strcmp(STR(name), s) == 0) { msg->name = value; continue; }

#define REQ(x) void CONCAT(x, _REQ)(struct DMI_Req *req, char *options) { \
  struct x *msg = (void *)&req->data; \
  for (char *s = strtok(options, " "); s != NULL; s = strtok(NULL, " ")) { \
    char *eq = strchr(s, '='); \
    *eq = '\0'; \
    uint32_t value = (uint32_t)strtol(eq + 1, NULL, 16); \
    CONCAT(x, _FIELDS) \
  } \
}

REQ(DMCONTROL);
REQ(COMMAND);
REQ(SBCS);

#undef FIELD


/**
 * Response handler definitions
 */
#define FIELD(name, bits) do { \
  const char *s = STR(name); \
  if (s[0] != '_') { \
    printf("%s: %x\n", s, msg->name); \
  } \
} while(0);

#define RESP(x) void CONCAT(x, _RESP)(struct DMI_Resp *resp) { \
  struct x *msg = (void *)&resp->data; \
  CONCAT(x, _FIELDS) \
}

RESP(DMCONTROL);
RESP(DMSTATUS);
RESP(ABSTRACTS);
RESP(SBCS);


#undef FIELD

void default_req(struct DMI_Req *req, char *msg)
{
  req->data = (int)strtol(msg, NULL, 16);
}

void default_resp(struct DMI_Resp *resp)
{
  printf("%08x\n", resp->data);
}

struct Entry {
  char name[20];
  uint32_t addr;
  void (*req_builder)(struct DMI_Req *, char *);
  void (*resp_handler)(struct DMI_Resp *);
};


struct Entry entries[] = {
  { "data0",     0x04, NULL,           default_resp   },
  { "data1",     0x05, NULL,           default_resp   },
  { "dmcontrol", 0x10, DMCONTROL_REQ,  DMCONTROL_RESP },
  { "dmstatus",  0x11, NULL,           DMSTATUS_RESP  },
  { "hartinfo",  0x12, NULL,           NULL           },
  { "haltsum",   0x13, NULL,           NULL           },
  { "abstracts", 0x16, NULL,           ABSTRACTS_RESP },
  { "command",   0x17, COMMAND_REQ,    NULL           },
  { "sbcs", 0x38, SBCS_REQ, SBCS_RESP },
  { "sbaddress0", 0x39, default_req, default_resp },
  { "sbaddress1", 0x3a, default_req, default_resp },
  { "sbaddress2", 0x3b, default_req, default_resp },
  { "sbdata0", 0x3c, default_req, default_resp },
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
    memset(&resp, 0xff, sizeof(resp));

    scanf("%s", msg);
    if      (strcmp(msg, "read")  == 0) req.opcode = OP_READ;
    else if (strcmp(msg, "write") == 0) req.opcode = OP_WRITE;
    else if (strcmp(msg, "quit")  == 0) break;

    scanf("%s", msg);
    int i = 0;
    for (; i < sizeof(entries) / sizeof(entries[0]); i++) {
      if (strcmp(entries[i].name, msg) == 0) {
        break;
      }
    }
    if (i == sizeof(entries) / sizeof(entries[0])) {
      printf("not found %s\n", msg);
      continue;
    }

    req.addr = entries[i].addr;

    if (req.opcode == OP_WRITE) {
      req.opcode = OP_READ;
      send(sfd, &req, sizeof(req), 0);
      recv(sfd, &resp, sizeof(resp), 0);
      if (resp.state != 0) {
        puts("access failed");
        continue;
      }
      req.opcode = OP_WRITE;
      req.data = resp.data;
      fgets(msg, sizeof(msg), stdin);
      entries[i].req_builder(&req, msg);
      send(sfd, &req, sizeof(req), 0);
      recv(sfd, &resp, sizeof(resp), 0);
      if (resp.state != 0) {
        puts("access failed");
        continue;
      }
    }
    else if (req.opcode == OP_READ) {
      send(sfd, &req, sizeof(req), 0);
      recv(sfd, &resp, sizeof(resp), 0);
      if (resp.state == 0) {
        entries[i].resp_handler(&resp);
      }
      else {
        puts("access failed");
      }
    }
  }

  close(sfd);
}
