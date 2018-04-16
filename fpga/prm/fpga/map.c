#include "common.h"

#include <sys/stat.h>  
#include <sys/mman.h>  
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>

#include "map.h"

#define GPIO_RESET_TOTAL_SIZE	(1 << 12)
#define JTAG_TOTAL_SIZE		(1 << 12)

volatile uint32_t *gpio_reset_base;
volatile uint32_t *jtag_base;

static inline void* create_map(size_t size, int fd, off_t offset) {
  void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);

  if (base == NULL) {
    perror("init_mem mmap failed:");
    close(fd);
    exit(1);
  }

  return base;
}

static int fd;
void init_map() {
  fd = open("/dev/mem", O_RDWR|O_SYNC);  
  if (fd == -1)  {  
    perror("init_map open failed:");
    exit(1);
  } 

  jtag_base = (uint32_t *)create_map(JTAG_TOTAL_SIZE, fd, JTAG_BASE_ADDR);
  gpio_reset_base = (uint32_t *)create_map(GPIO_RESET_TOTAL_SIZE, fd, GPIO_RESET_BASE_ADDR);
}

void resetn(int val) {
  gpio_reset_base[0] = val;
}

void finish_map() {
  munmap((void *)jtag_base, JTAG_TOTAL_SIZE);
  munmap((void *)gpio_reset_base, GPIO_RESET_TOTAL_SIZE);
  close(fd);
}
