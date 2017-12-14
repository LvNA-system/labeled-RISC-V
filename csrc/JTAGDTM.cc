// See LICENSE.SiFive for license details.
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

#include "JTAGDTM.h"

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

void Pthread_mutex_init(pthread_mutex_t *mp,
	const pthread_mutexattr_t *mattr);
void Pthread_mutex_lock(pthread_mutex_t *mutex);
void Pthread_mutex_unlock(pthread_mutex_t *mutex);
void Pthread_mutex_destroy(pthread_mutex_t *mutex);
void set_bit(unsigned char &value, int index, int bit);
int get_bit(unsigned char value, int index);

  extern "C" void jtag_tick
(
 unsigned char* jtag_TMS,
 unsigned char* jtag_TCK,
 unsigned char* jtag_TDI,
 unsigned char jtag_TDO,
 unsigned char* jtag_TRST
 )
{
  // please use trylock
  // or we will block the emulator and timestamp will not advance
  // which may cause deadlock, if jtag_server_thread is waiting for a specific timestamp in gen_clk
  if (!pthread_mutex_trylock(&lock)) {
	*jtag_TMS = tms;
	*jtag_TCK = tck;
	*jtag_TDI = tdi;
	*jtag_TRST = trst;
	tdo = jtag_TDO;
	Pthread_mutex_unlock(&lock);
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
	// printf("tck\n");
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
  set_tms(1);
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
	  set_tms(0);
	  if (get_bit(data, j) == 1)
		set_tms(1);
	  // send one bit per clock
	  gen_clk(1);
	}
  }
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
	  set_tdi(0);
	  if (get_bit(data_out, _bit) == 1)
		set_tdi(1);

	  // On the last bit, set TMS to '1'
	  // so we will automatically leave shift_IR/shift_DR state after sending out the last bit
	  if (((_bit == (nb_bits_in_this_byte - 1)) && (index == (length - 1))) && (flip_tms == 1)) {
		set_tms(1);
	  }

	  // get_tdo will drive tck for one clock cycle
	  set_bit(data_in, _bit, get_tdo());
	}
	buffer_in[index] = data_in;
  }
  set_tdi(0);
  set_tms(0);
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

  struct vpi_cmd command;
  while (recv(client_fd, &command, sizeof(command), 0) > 0) {
	cmd = command.cmd;
	nb_bits = command.nb_bits;
	length = command.length;

	printf("**************************************\n\n");
	printf("recv: cmd %s, length %d, nb_bits %d\n", cmd_to_string(cmd), length, nb_bits);
	if (length > XFERT_MAX_SIZE || nb_bits > length * 8) {
	  perror("Invalid command");
	  exit(-1);
	}

	memcpy(buffer_out, command.buffer_out, length);

	// now switch on the command
	switch(cmd) {
	  case CMD_RESET:
		if (DEBUG_INFO)
		  printf("CMD_RESET\n");
		reset_tap_soft();
		goto_run_test_idle_from_reset();
		break;

	  case CMD_TMS_SEQ:
		if (DEBUG_INFO)
		  printf("CMD_TMS_SEQ\n");
		do_tms_seq();
		break;

	  case CMD_SCAN_CHAIN:
		if (DEBUG_INFO)
		  printf("CMD_SCAN_CHAIN\n");
		flip_tms = 0;
		do_scan_chain();
		// send result back
		memcpy(command.buffer_in, buffer_in, length);
		send(client_fd, &command, sizeof(command), 0);
		break;

	  case CMD_SCAN_CHAIN_FLIP_TMS:
		if(DEBUG_INFO)
		  printf("CMD_SCAN_CHAIN\n");
		flip_tms = 1;
		do_scan_chain();
		// send result back
		memcpy(command.buffer_in, buffer_in, length);
		send(client_fd, &command, sizeof(command), 0);
		break;

	  case CMD_STOP_SIMU:
		if(DEBUG_INFO)
		  printf("CMD_STOP_SIMU\n");
		exit(0);
		break;

	  case CMD_RESET_HARD:
		if (DEBUG_INFO)
		  printf("CMD_RESET_HARD\n");
		reset_tap_hard();
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
  int server_fd = create_server(8080);
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

/*******************************
 * bit helpers
 *******************************/
void set_bit(unsigned char &value, int index, int bit) {
  assert(index >= 0 && index <= 7 && (bit == 0 || bit == 1));
  unsigned char mask = 1 << index;
  if (bit) {
	// set bit
	value |= mask;
  } else {
	// clear bit
	value &= ~mask;
  }
}

int get_bit(unsigned char value, int index) {
  assert(index >= 0 && index <= 7);
  return (value >> index) & 0x1;
}

/*******************************
 * Wrappers for Posix mutexs
 *******************************/

void posix_error(int code, const char *msg) /* posix-style error */
{
  fprintf(stderr, "%s: %s\n", msg, strerror(code));
  exit(0);
}

void Pthread_mutex_init(pthread_mutex_t *mp,
	const pthread_mutexattr_t *mattr)
{
  int rc;
  if ((rc = pthread_mutex_init(mp, mattr)) != 0)
	posix_error(rc, "Pthread_mutex_init error");
}

void Pthread_mutex_lock(pthread_mutex_t *mutex)
{
  int rc;
  if ((rc = pthread_mutex_lock(mutex)) != 0)
	posix_error(rc, "Pthread_mutex_lock error");
}

void Pthread_mutex_unlock(pthread_mutex_t *mutex)
{
  int rc;
  if ((rc = pthread_mutex_unlock(mutex)) != 0)
	posix_error(rc, "Pthread_mutex_unlock error");
}

void Pthread_mutex_destroy(pthread_mutex_t *mutex)
{
  int rc;
  if ((rc = pthread_mutex_destroy(mutex)) != 0)
	posix_error(rc, "Pthread_mutex_destroy error");
}

// we put this here, just to make the original dtm happy
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
