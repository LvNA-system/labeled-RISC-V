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


namespace {

  // Remove args that will confuse dtm, such as those that require two tokens, like VCS code coverage "-cm line+cond"
std::vector<std::string> filter_argv_for_dtm(int argc, char** argv)
{
  std::vector<std::string> out;
  for (int i = 1; i < argc; ++i) { // start with 1 to skip my executable name
    if (!strncmp(argv[i], "-cm", 3)) {
      ++i; // skip this one and the next one
    }
    else {
      out.push_back(argv[i]);
    }
  }
  return out;
}

}


enum State {
  IDLE, ISSUE, WAIT, DELAY
};


volatile bool valid = false;
volatile struct DMI_Req req;
volatile struct DMI_Resp resp;
volatile bool emu_exit = false;
volatile State state = State::IDLE;


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
  const int LATENCY = 10;
  static int count_down = 10;

  switch (state) {
  case IDLE:
    if (valid) {
      *debug_req_valid = 1;
      if (debug_req_ready) {
        state = State::WAIT;
      }
      else {
        state = State::ISSUE;
      }
      valid = false;
    }
    else {
      *debug_req_valid = 0;
    }
    break;
  case ISSUE:
    assert(!valid);
    if (debug_req_ready) {
      *debug_req_valid = 0;
      state = State::WAIT;
    }
    else {
      *debug_req_valid = 1;
    }
    break;
  case WAIT:
    assert(!valid);
    *debug_req_valid = 0;
    if (debug_resp_valid) {
      state = State::DELAY;
      count_down = LATENCY;
      resp.state = debug_resp_bits_resp;
      resp.data = debug_resp_bits_data;
    }
  case DELAY:
    assert(!valid);
    if (count_down == 0) {
      state = State::IDLE;
    }
    count_down--;
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
