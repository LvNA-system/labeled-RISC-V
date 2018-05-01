#include "common.h"

void server_connect(const char *ip_addr, int port);
void server_disconnect();

void init_platform(const char *ip_addr, int port) {
  server_connect(ip_addr == NULL ? "127.0.0.1" : ip_addr, port == 0 ? 8080 : port);
}

void finish_platform() {
  server_disconnect();
}
