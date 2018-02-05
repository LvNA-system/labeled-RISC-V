#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <memory.h>
#include <sys/socket.h>
#include <sys/times.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>


#include <assert.h>
#include <sys/time.h>
#include <time.h>

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

#define JTAG_CONTROLLER_BASE ((uintptr_t)0x43c00000)
#define JTAG_CONTROLLER_SIZE 20
// Length of shift operation in bits
#define JTAG_LENGTH          0x0
// Test Mode Select (TMS) Bit Vector
#define JTAG_TMS_VECTOR      0x1
// Test Data In (TDI) Bit Vector
#define JTAG_TDI_VECTOR      0x2
// Test Data Out (TDO) Capture Vector
#define JTAG_TDO_VECTOR      0x3
// Bit 0: Enable Shift Operation
#define JTAG_CTRL            0x4

volatile uint32_t *jtag_base_ptr;

void wait_jtag_idle() {
  while((*(jtag_base_ptr + JTAG_CTRL) & 0x1));
}

void enable_shift() {
  *(jtag_base_ptr + JTAG_CTRL) = 0x1;
}

void set_tms_vec(uint32_t val, int length) {
  assert(length <= 32 && length >= 1);
  *(jtag_base_ptr + JTAG_TMS_VECTOR) = val;
  *(jtag_base_ptr + JTAG_LENGTH) = length;
}

void set_tdi_vec(uint32_t val, int length) {
  assert(length <= 32 && length >= 1);
  *(jtag_base_ptr + JTAG_TDI_VECTOR) = val;
  *(jtag_base_ptr + JTAG_LENGTH) = length;
}

uint32_t get_tdo_vec() {
  return *(jtag_base_ptr + JTAG_TDO_VECTOR);
}

int	fd;

void* create_map(size_t size, int fd, off_t offset) {
  void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);

  if (base == MAP_FAILED) {
    perror("init_mem mmap failed:");
    close(fd);
    exit(1);
  }

  printf("mapping paddr 0x%lx to vaddr 0x%x\n", offset, (uintptr_t)base);

  return base;
}

void init_map() {
  fd = open("/dev/mem", O_RDWR|O_SYNC);
  if (fd == -1)  {
    perror("init_map open failed:");
    exit(1);
  }

  jtag_base_ptr = (uint32_t *)create_map(JTAG_CONTROLLER_SIZE, fd, JTAG_CONTROLLER_BASE);
}

void finish_map() {
  munmap((void *)jtag_base_ptr, JTAG_CONTROLLER_SIZE);
  close(fd);
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

// TAP reset
void reset_tap_hard() {
  // five conseutive tms only makes sure that we put the tap state to reset
  // but does not necessarily resets jtag internal registers
  // so we use TRST signal
  if (DEBUG_INFO)
    printf("Task reset_tap\n");
  wait_jtag_idle();
  // five consecutive tms is enough
  set_tms_vec(0x1f, 5);
  enable_shift();
}

void reset_tap_soft() {
  // change the stat machine to test logic reset
  // does not clear any internal registers
  wait_jtag_idle();
  // five consecutive tms is enough
  set_tms_vec(0x1f, 5);
  enable_shift();
}

// Goes to RunTestIdle state
void goto_run_test_idle_from_reset() {
  if (DEBUG_INFO)
    printf("Task goto_run_test_idle_from_reset\n");
  wait_jtag_idle();
  set_tms_vec(0x0, 1);
  enable_shift();
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
      wait_jtag_idle();
      set_tms_vec(bit, 1);
      if (DEBUG_INFO)
        printf("%d", bit);
      // send one bit per clock
      enable_shift();
    }
  }
  if (DEBUG_INFO)
    printf("\n");
  wait_jtag_idle();
  set_tms_vec(0, 1);
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
      wait_jtag_idle();
      int bit = get_bit(data_out, _bit);
      set_tdi_vec(bit, 1);

      // On the last bit, set TMS to '1'
      // so we will automatically leave shift_IR/shift_DR state after sending out the last bit
      if (((_bit == (nb_bits_in_this_byte - 1)) && (index == (length - 1))) && (flip_tms == 1)) {
        set_tms_vec(1, 1);
      }

      // send one bit per clock
      enable_shift();
      wait_jtag_idle();
      int out = get_tdo_vec() & 1;
      set_bit(data_in, _bit, out);
      if (DEBUG_INFO)
        printf("in: %d out: %d\n", bit, out);
    }
    buffer_in[index] = data_in;
  }
  wait_jtag_idle();
  if (DEBUG_INFO)
    printf("\n");
  set_tdi_vec(0, 1);
  set_tms_vec(0, 1);
}

void check_bits(int length, int nb_bits) {
  if (length > XFERT_MAX_SIZE || nb_bits > length * 8) {
    printf("Invalid command");
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
  start = Times(NULL);

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

void create_jtag_vpi_server()
{
  int server_fd = create_server(8080);
  host_mainloop(server_fd);
}

int main(void) {
  init_map();
  create_jtag_vpi_server();
  finish_map();
  return 0;
}
