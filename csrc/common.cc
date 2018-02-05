#include "common.h"

#define	XFERT_MAX_SIZE	512

// -----------------------------------------------------
// Time related helper functions
// -----------------------------------------------------
clock_t Times(struct tms *buf) {
  clock_t ret;
  if ((ret = times(buf)) == -1)
	unix_error("times error");
  return ret;
}

void pr_times(clock_t rtime, struct tms *tmsstart, struct tms *tmsend,
	double *real, double *sys, double *user) {
  static long		clktck = 0;

  if (clktck == 0)	/* fetch clock ticks per second first time */
	if ((clktck = sysconf(_SC_CLK_TCK)) < 0)
	  app_error("sysconf error");

  if (real)
	*real = rtime / (double) clktck;
  if (sys)
	*sys = (tmsend->tms_stime - tmsstart->tms_stime) / (double) clktck;
  if (user)
	*user = (tmsend->tms_utime - tmsstart->tms_utime) / (double) clktck;
}

// given a start time, return current timestamp
double get_timestamp(clock_t start) {
  clock_t end = Times(nullptr);
  double real;
  pr_times(end - start, nullptr, nullptr, &real, nullptr, nullptr);
  return real;
}

// -----------------------------------------------------
// Error handling functions
// -----------------------------------------------------
/* unix-style error */
void unix_error(const char *msg) {
  fprintf(stderr, "%s: %s\n", msg, strerror(errno));
  exit(0);
}

/* posix-style error */
void posix_error(int code, const char *msg) {
  fprintf(stderr, "%s: %s\n", msg, strerror(code));
  exit(0);
}

/* application error */
void app_error(const char *msg) {
  fprintf(stderr, "%s\n", msg);
  exit(0);
}


// -----------------------------------------------------
// Bit handling functions
// -----------------------------------------------------

// get bits in range [high, low]
uint64_t get_bits(uint64_t data, int high, int low) {
  assert(high >= low && high <= 63 && low >= 0);
  int left_shift = 63 - high;
  // firstly, remove the higher bits, then remove the lower bits
  return ((data << left_shift) >> left_shift) >> low;
}

int get_bit(unsigned char value, int index) {
  assert(index >= 0 && index <= 7);
  return (value >> index) & 0x1;
}

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

void str_to_bits(const char *str, int &length,
	int &nb_bits, unsigned char *buffer) {
  nb_bits = 0;
  while (*str) {
	assert(*str == '0' || *str == '1');
	// which byte are we handling?
	int index = nb_bits / 8;
	set_bit(buffer[index], nb_bits % 8, *str - '0');
	str++;
	nb_bits++;
	assert(nb_bits <= XFERT_MAX_SIZE * 8);
  }
  length = (nb_bits + 7) / 8;
}

char *bits_to_str(int length,
	int nb_bits, unsigned char *buffer) {
  assert(nb_bits <= XFERT_MAX_SIZE * 8);
  char *str = (char *)malloc(sizeof(char) * (nb_bits + 1));
  assert(str);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	int bit = get_bit(buffer[index], i % 8);
	str[i] = '0' + bit;
  }
  str[nb_bits] = '\0';
  return str;
}

// shift a uint64_t value into a buffer
void shift_bits_into_buffer(uint64_t value, int nb_bits,int &ret_length,
	int &ret_nb_bits, unsigned char *buffer) {
  assert(nb_bits > 0 && nb_bits <= 64);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	set_bit(buffer[index], i % 8, value & 0x1);
	value >>= 1;
  }
  ret_nb_bits = nb_bits;
  ret_length = (nb_bits + 7) / 8;
}

// shift a uint64_t value out of a buffer
uint64_t shift_bits_outof_buffer(int nb_bits, 
	unsigned char *buffer) {
  assert(nb_bits > 0 && nb_bits <= 64);
  uint64_t value = 0;
  // 1 should be unsigned long long
  // if we simply write 1
  // it will be int32_t and sign extended to 64bit, 
  // which means mask will be 0xffffffff80000000
  uint64_t mask = 1ULL << (nb_bits - 1);
  for (int i = 0; i < nb_bits; i++) {
	// which byte are we handling?
	int index = i / 8;
	int bit = get_bit(buffer[index], i % 8);
	// be careful about the bit order here
	value >>= 1;
	if (bit)
	  value |= mask;
  }
  return value;
}

// -----------------------------------------------------
// Posix mutex wrapper functions
// -----------------------------------------------------
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

int myrecv(int fd, char *buf, int size) {
  int recvd = 0;
  while (recvd < size) {
    int cnt = recv(fd, buf + recvd, size - recvd, 0);
    if (cnt < 0) {
      perror("Recv failed");
      exit(-1);
    }
    // socket closed
    if (cnt == 0)
      return 0;
    recvd += cnt;
  }
  return 1;
}
