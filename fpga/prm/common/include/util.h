#ifndef __UTIL_H__
#define __UTIL_H__

#include <sys/times.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <unistd.h>
#include <pthread.h>

// -----------------------------------------------------
// Time related helper functions
// -----------------------------------------------------
clock_t Times(struct tms *buf);
void pr_times(clock_t rtime, struct tms *tmsstart, struct tms *tmsend,
	double *real, double *sys, double *user);
// given a start time, return current timestamp
double get_timestamp(clock_t start);

// -----------------------------------------------------
// Error handling functions
// -----------------------------------------------------
/* unix-style error */
void unix_error(const char *msg);
/* posix-style error */
void posix_error(int code, const char *msg);
/* application error */
void app_error(const char *msg);


// -----------------------------------------------------
// Bit handling functions
// -----------------------------------------------------
// get bits in range [high, low]
uint64_t get_bits(uint64_t data, int high, int low);
int get_bit(unsigned char value, int index);
void set_bit(unsigned char *value, int index, int bit);
void str_to_bits(const char *str, int *length, int *nb_bits, unsigned char *buffer);
char *bits_to_str(int length, int nb_bits, unsigned char *buffer);
// shift a uint64_t value into a buffer
void shift_bits_into_buffer(uint64_t value, int nb_bits,int *ret_length, int *ret_nb_bits, unsigned char *buffer);
// shift a uint64_t value out of a buffer
uint64_t shift_bits_outof_buffer(int nb_bits, unsigned char *buffer);

// -----------------------------------------------------
// Posix mutex wrapper functions
// -----------------------------------------------------
void Pthread_mutex_init(pthread_mutex_t *mp,
	const pthread_mutexattr_t *mattr);
void Pthread_mutex_lock(pthread_mutex_t *mutex);
void Pthread_mutex_unlock(pthread_mutex_t *mutex);
void Pthread_mutex_destroy(pthread_mutex_t *mutex);

int myrecv(int fd, char *buf, int size);
#endif
