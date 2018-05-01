#include "common.h"
#include "util.h"

#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <unistd.h>

// server fd
static int sfd;

void server_connect(const char *ip_addr, int port) {
  // Socket
  sfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sfd == -1) {
    perror("Failed to create socket");
    exit(-1);
  }

  // Config server
  struct sockaddr_in server;
  server.sin_addr.s_addr = inet_addr(ip_addr);
  server.sin_family = AF_INET;
  server.sin_port = htons(port);

  // Connect
  if (connect(sfd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Connect failed");
    exit(-1);
  }

  puts("Connected\n");
}

void server_disconnect(void) {
  close(sfd);
}

ssize_t server_send(const void *buf, size_t len, int flags) {
  return send(sfd, buf, len, flags);
}

int server_recv(char *buf, int size) {
  return myrecv(sfd, buf, size);
}
