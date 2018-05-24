// See LICENSE.SiFive for license details.
#include "dmi.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>

#include <vpi_user.h>
#include <svdpi.h>

dtm_t* dtm;

extern "C" int debug_tick
(
  unsigned char* debug_req_valid,
  unsigned char  debug_req_ready,
  int*           debug_req_bits_addr,
  int*           debug_req_bits_op,
  int*           debug_req_bits_data,
  unsigned char  debug_resp_valid,
  unsigned char* debug_resp_ready,
  int            debug_resp_bits_resp,
  int            debug_resp_bits_data
)
{
  if (!dtm) {
    s_vpi_vlog_info info;
    if (!vpi_get_vlog_info(&info))
      abort();
      dtm = new dtm_t(info.argc, info.argv);
  }

  *debug_resp_ready = 1;
  *debug_req_bits_op = req.opcode;
  *debug_req_bits_addr = req.addr;
  *debug_req_bits_data = req.data;

  return emu_exit ? 1 : 0;
}


static int create_server(short port)
{
  // Socket
  int server_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (server_fd == -1) {
    perror("Could not create socket");
    exit(-1);
  }

  int optval = 1;
  setsockopt(server_fd, SOL_SOCKET, SO_REUSEPORT, &optval, sizeof(optval));

  // Server config
  struct sockaddr_in server;
  server.sin_family = AF_INET;
  server.sin_addr.s_addr = INADDR_ANY;
  server.sin_port = htons(port);

  // Bind
  if (bind(server_fd, (struct sockaddr *)&server, sizeof(server)) < 0) {
    perror("Bind failed");
    exit(-1);
  }
  puts("Bind done");

  // Listen
  listen(server_fd, 5);
  puts("Listen done");

  return server_fd;
}


static void host_mainloop(int server_fd)
{
  struct sockaddr_in client;
  socklen_t sock_len = sizeof(struct sockaddr_in);
  int client_fd = accept(server_fd, (struct sockaddr *)&client, &sock_len);
  if (client_fd < 0) {
    perror("Accept failed");
    exit(-1);
  }
  puts("Connect established");

  DMI_Req req_msg;
  while (recv(client_fd, &req_msg, sizeof(req_msg), 0) > 0) {
    printf("recv: opcode %d, addr %08x, data %08x\n", req_msg.opcode, req_msg.addr, req_msg.data);

    req.opcode = req_msg.opcode;
    req.addr = req_msg.addr;
    req.data = req_msg.data;
    valid = true;

    while (valid || state != State::IDLE) {}  // Wait inflight request finished.

    DMI_Resp resp_msg;
    resp_msg.state = resp.state;
    resp_msg.data = resp.data;
    send(client_fd, &resp_msg, sizeof(resp_msg), 0);
  }

  close(client_fd);
  close(server_fd);
}


void *create_dmi_server(void *p)
{
  int server_fd = create_server(8080);
  host_mainloop(server_fd);
}


void create_dmi_server_thread(void)
{
  pthread_t tid;
  pthread_create(&tid, NULL, create_dmi_server, NULL);
}
