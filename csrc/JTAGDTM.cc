// See LICENSE.SiFive for license details.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/times.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdint.h>
#include <pthread.h>

#include <vpi_user.h>
#include <svdpi.h>

#include "JTAGDTM.h"
#include "common.h"

#define DEBUG_INFO 0
#define TCK_HALF_PERIOD 10

int cmd;
// number of bytes to send
int length;
// number of bits to send
int nb_bits;

unsigned char buffer_out[4096];
unsigned char buffer_in[4096];

int flip_tms;

unsigned char data_out;
unsigned char data_in;

// use this lock to arbitrate dpi and jtag_vpi_server thread's access to these four shared variables
pthread_mutex_t lock;

// jtag signals
// these variables are shared by dpi and jtag_vpi_server
unsigned char tms;
unsigned char tck;
unsigned char tdi;
unsigned char tdo;
unsigned char trst;

uint64_t get_time_stamp();

extern FILE *trace;
extern FILE *replay_trace;

// replay trace
bool has_trace = false;
bool trace_finished = false;
uint64_t trace_time;
unsigned char trace_tms;
unsigned char trace_tck;
unsigned char trace_tdi;
unsigned char trace_trst;


  extern "C" void jtag_tick
(
 unsigned char* jtag_TMS,
 unsigned char* jtag_TCK,
 unsigned char* jtag_TDI,
 unsigned char jtag_TDO,
 unsigned char* jtag_TRST
 )
{
  if (replay_trace) {
    if (!trace_finished) {
      if (!has_trace) {
        // get next trace input from trace file
        int cnt;
        cnt = fscanf(replay_trace, "%lu %hhu %hhu %hhu %hhu", &trace_time, &trace_tms, &trace_tck, &trace_tdi, &trace_trst);
        if (cnt == 5)
          has_trace = true;
        else if(cnt == EOF)
          trace_finished = true;
        else {
          fprintf(stderr, "fscanf error");
          exit(0);
        }
      }
      if (has_trace && get_time_stamp() == trace_time) {
        *jtag_TMS = trace_tms;
        *jtag_TCK = trace_tck;
        *jtag_TDI = trace_tdi;
        *jtag_TRST = trace_trst;
        has_trace = false;
      }
    }
  } else {
    if (!pthread_mutex_trylock(&lock)) {
      // please use trylock
      // or we will block the emulator and timestamp will not advance
      // which may cause deadlock, if jtag_server_thread is waiting for a specific timestamp in gen_clk
      *jtag_TMS = tms;
      *jtag_TCK = tck;
      *jtag_TDI = tdi;
      *jtag_TRST = trst;
      tdo = jtag_TDO;
      if (trace) {
        // we only need to trace the input signals
        fprintf(trace, "%lu %hhu %hhu %hhu %hhu\n", get_time_stamp(), tms, tck, tdi, trst);
      }
      Pthread_mutex_unlock(&lock);
    }
  }
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


void delay(int clock) {
  uint64_t start = get_time_stamp();
  while(get_time_stamp() < start + clock) {
    // do not read the timestamp too frequently
    volatile int tmp = 0;
    for (int i = 0; i < 100; i++)
      tmp = 0;
  }
}

// Generation of the TCK signal
void gen_clk(int number) {
  for (int i = 0; i < number; i = i + 1) {
    Pthread_mutex_lock(&lock);
    tck = 1;
    Pthread_mutex_unlock(&lock);
    delay(TCK_HALF_PERIOD);
    Pthread_mutex_lock(&lock);
    tck = 0;
    Pthread_mutex_unlock(&lock);
    delay(TCK_HALF_PERIOD);
  }
}

void set_tms(unsigned char val) {
  assert(val <= 1);
  Pthread_mutex_lock(&lock);
  tms = val;
  Pthread_mutex_unlock(&lock);
}

void set_tdi(unsigned char val) {
  assert(val <= 1);
  Pthread_mutex_lock(&lock);
  tdi = val;
  Pthread_mutex_unlock(&lock);
}

unsigned char get_tdo(void) {
  Pthread_mutex_lock(&lock);
  tck = 1;
  Pthread_mutex_unlock(&lock);
  delay(TCK_HALF_PERIOD);

  // according to JTAG Spec, tdo should be sampled at the rising edge of tck
  // if we simply read the tdo value after gen_clk(1)
  // we will get wrong value
  unsigned char ret = tdo;

  Pthread_mutex_lock(&lock);
  tck = 0;
  Pthread_mutex_unlock(&lock);
  delay(TCK_HALF_PERIOD);
  return ret;
}

void set_trst(unsigned char val) {
  assert(val <= 1);
  Pthread_mutex_lock(&lock);
  trst = val;
  Pthread_mutex_unlock(&lock);
}

// TAP reset
void reset_tap_hard() {
  // five conseutive tms only makes sure that we put the tap state to reset
  // but does not necessarily resets jtag internal registers
  // so we use TRST signal
  if (DEBUG_INFO)
    printf("Task reset_tap\n");

  set_trst(1);
  // set tms to 1, so that it will spin at test logic reset
  set_tms(1);

  // give it enough time to reset
  gen_clk(10);

  // deassert trst and tms, this does not sync with tck
  set_trst(0);
  set_tms(0);
}

void reset_tap_soft() {
  // change the stat machine to test logic reset
  // does not clear any internal registers
  set_tms(1);
  // give it enough time to reset
  gen_clk(5);
}

// Goes to RunTestIdle state
void goto_run_test_idle_from_reset() {
  if (DEBUG_INFO)
    printf("Task goto_run_test_idle_from_reset\n");
  set_tms(0);
  gen_clk(1);
}

void do_tms_seq() {
  int data;
  int nb_bits_rem;
  int nb_bits_in_this_byte;

  if (DEBUG_INFO)
    printf("Task do_tms_seq of %d bits (length = %d)\n", nb_bits, length);

  // number of bits to send in the last byte
  nb_bits_rem = nb_bits % 8;

  for (int i = 0; i < length; i = i + 1) {
    // If we are sending the last byte,
    // we only need to send nb_bits_rem bits.
    // If not, we send the whole byte.
    nb_bits_in_this_byte = (i == (length - 1)) ? nb_bits_rem : 8;

    // the byte to transfer
    data = buffer_out[i];
    for (int j = 0; j < nb_bits_in_this_byte; j = j + 1) {
      int bit = get_bit(data, j);
      set_tms(bit);
      if (DEBUG_INFO)
        printf("%d", bit);
      // send one bit per clock
      gen_clk(1);
    }
  }
  if (DEBUG_INFO)
    printf("\n");
  set_tms(0);
}

void do_scan_chain() {
  int _bit;
  int nb_bits_rem;
  int nb_bits_in_this_byte;
  int index;

  if(DEBUG_INFO)
    printf("Task do_scan_chain of %d bits (length = %d)\n", nb_bits, length);

  // number of bits to send in the last byte
  nb_bits_rem = nb_bits % 8;

  for (index = 0; index < length; index = index + 1) {
    nb_bits_in_this_byte = (index == (length - 1)) ? ((nb_bits_rem == 0) ? 8 : nb_bits_rem) : 8;

    data_out = buffer_out[index];
    for (_bit = 0; _bit < nb_bits_in_this_byte; _bit = _bit + 1) {
      int bit = get_bit(data_out, _bit);
      set_tdi(bit);
      // On the last bit, set TMS to '1'
      // so we will automatically leave shift_IR/shift_DR state after sending out the last bit
      if (((_bit == (nb_bits_in_this_byte - 1)) && (index == (length - 1))) && (flip_tms == 1)) {
        set_tms(1);
      }

      // get_tdo will drive tck for one clock cycle
      int out = get_tdo();
      set_bit(data_in, _bit, out);
      if (DEBUG_INFO)
        printf("in: %d out: %d\n", bit, out);
    }
    buffer_in[index] = data_in;
  }
  if (DEBUG_INFO)
    printf("\n");
  set_tdi(0);
  set_tms(0);
}

void check_bits(int length, int nb_bits) {
  if (length > XFERT_MAX_SIZE || nb_bits > length * 8) {
    fprintf(stderr, "Invalid command");
    exit(-1);
  }
}

static void host_mainloop(int server_fd) {
  struct sockaddr_in client;
  socklen_t sock_len = sizeof(struct sockaddr_in);
  int client_fd = accept(server_fd, (struct sockaddr *)&client, &sock_len);
  if (client_fd < 0) {
    perror("Accept failed");
    exit(-1);
  }
  puts("Connect established");

  clock_t start;
  start = Times(nullptr);

  struct vpi_cmd command;
  while (myrecv(client_fd, (char *)&command, sizeof(command))) {
    cmd = command.cmd;
    nb_bits = command.nb_bits;
    length = command.length;

    if (DEBUG_INFO) {
      printf("**************************************\n\n");
      printf("[%.6f] recv: cmd %s, length %d, nb_bits %d\n",
          get_timestamp(start), cmd_to_string(cmd), length, nb_bits);
    }

    // openocd jtag driver does not init vpi_cmd structure properly
    // when cmd == CMD_RESET, all fields except cmd may be garbage values
    // so do not check_bits on these cmds

    // now switch on the command
    switch(cmd) {
      case CMD_RESET:
        if (DEBUG_INFO)
          printf("CMD_RESET_HARD\n");
        reset_tap_hard();
        goto_run_test_idle_from_reset();
        break;

      case CMD_TMS_SEQ:
        if (DEBUG_INFO)
          printf("CMD_TMS_SEQ\n");
        check_bits(length, nb_bits);
        memcpy(buffer_out, command.buffer_out, length);
        do_tms_seq();
        break;

      case CMD_SCAN_CHAIN:
        if (DEBUG_INFO)
          printf("CMD_SCAN_CHAIN\n");
        check_bits(length, nb_bits);
        memcpy(buffer_out, command.buffer_out, length);
        flip_tms = 0;
        do_scan_chain();
        // send result back
        if (DEBUG_INFO)
          printf("[%.6f] send: cmd %s, length %d, nb_bits %d\n",
              get_timestamp(start), cmd_to_string(cmd), length, nb_bits);
        memcpy(command.buffer_in, buffer_in, length);
        send(client_fd, &command, sizeof(command), 0);
        break;

      case CMD_SCAN_CHAIN_FLIP_TMS:
        if(DEBUG_INFO)
          printf("CMD_SCAN_CHAIN\n");
        check_bits(length, nb_bits);
        memcpy(buffer_out, command.buffer_out, length);
        flip_tms = 1;
        do_scan_chain();
        // send result back
        if (DEBUG_INFO)
          printf("[%.6f] send: cmd %s, length %d, nb_bits %d\n",
              get_timestamp(start), cmd_to_string(cmd), length, nb_bits);
        memcpy(command.buffer_in, buffer_in, length);
        send(client_fd, &command, sizeof(command), 0);
        break;

      case CMD_STOP_SIMU:
        if(DEBUG_INFO)
          printf("CMD_STOP_SIMU\n");
        exit(0);
        break;

      case CMD_RESET_SOFT:
        if (DEBUG_INFO)
          printf("CMD_RESET_SOFT\n");
        reset_tap_soft();
        goto_run_test_idle_from_reset();
        break;

      default:
        printf("Somehow got to the default case in the command case statement.");
        printf("Command was: %x", cmd);
        printf("Exiting...");
        exit(0);
        break;
    }
    // flush stdout, so that when we ctrl-c to stop this process
    // we will not leave much output in buffer
    // which makes debugging easy
    fflush(stdout);
  }
  close(client_fd);
  close(server_fd);
}

void *create_jtag_vpi_server(void *p)
{
  extern int port;
  port = port == 0 ? 8080 : port;
  printf("Listen on port: %d\n", port);
  int server_fd = create_server(port);
  host_mainloop(server_fd);
}

void init_jtag_vpi(void)
{
  Pthread_mutex_init(&lock, NULL);
  tms = 0;
  tck = 0;
  tdi = 0;
  tdo = 0;
  trst = 0;
  pthread_t tid;
  pthread_create(&tid, NULL, create_jtag_vpi_server, NULL);
}
