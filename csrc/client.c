#include "dmi.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>

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
  while (1) {
    printf("> ");
    fflush(stdout);
    scanf("%d %x %x", &req.opcode, &req.addr, &req.data);
    send(sfd, &req, sizeof(req), 0);
    if (req.opcode == OP_READ) {
      recv(sfd, &resp, sizeof(resp), 0);
      printf("resp: %d, %08x\n", resp.state, resp.data);
    }
    else if (req.opcode == OP_EXIT) {
      break;
    }
  }
}
