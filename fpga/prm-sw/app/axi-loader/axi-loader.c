#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <memory.h>
#include <unistd.h>  
#include <sys/mman.h>  
#include <sys/types.h>  
#include <sys/stat.h>  
#include <fcntl.h>
#include <elf.h>

#include <assert.h>
#include <sys/time.h>
#include <time.h>

#define BOARD_zedboard   0
#define BOARD_zcu102     1
#define BOARD_sidewinder 2
#define BOARD_ultraZ     3

#define BOARD BOARD_ultraZ

#if BOARD == BOARD_zcu102
# define DDR_TOTAL_SIZE		((uintptr_t)0x80000000)
# define DDR_BASE_ADDR		((uintptr_t)0x800000000)
# define GPIO_RESET_BASE_ADDR	((uintptr_t)0x80010000)
#elif BOARD == BOARD_ultraZ
# define DDR_TOTAL_SIZE		((uintptr_t)0x40000000)
# define DDR_BASE_ADDR		((uintptr_t)0x40000000)
# define GPIO_RESET_BASE_ADDR	((uintptr_t)0x80010000)
#elif BOARD == BOARD_zedboard
# define DDR_TOTAL_SIZE		((uintptr_t)0x10000000)
# define DDR_BASE_ADDR		((uintptr_t)0x10000000)
# define GPIO_RESET_BASE_ADDR	((uintptr_t)0x41200000)
#elif
# error unsupported BOARD
#endif

#define GPIO_RESET_TOTAL_SIZE	0x1000
#define LDOM_MEM_SIZE		(DDR_TOTAL_SIZE / 2)

void *ddr_base;
volatile uint32_t *gpio_reset_base;
int	fd;

void loader(char *imgfile, char *dtbfile, uint32_t offset) {
	FILE *fp = fopen(imgfile, "rb");
	assert(fp);

	fseek(fp, 0, SEEK_END);
	long size = ftell(fp);
	printf("image size = %ld\n", size);

	fseek(fp, 0, SEEK_SET);

	size_t ret = fread(ddr_base + offset, size, 1, fp);
  assert(ret == 1);

	fclose(fp);

	fp = fopen(dtbfile, "rb");
	if (fp == NULL) {
		printf("No valid configure string file provided. Configure string in bootrom will be used.\n");
		return ;
	}

	fseek(fp, 0, SEEK_END);
	size = ftell(fp);
	printf("configure string size = %ld\n", size);

	fseek(fp, 0, SEEK_SET);
	ret = fread(ddr_base + offset + 0x8, size, 1, fp);
  assert(ret == 1);

	fclose(fp);
}

void* create_map(size_t size, int fd, off_t offset) {
	void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
	
	if (base == MAP_FAILED) {
		perror("init_mem mmap failed:");
		close(fd);
		exit(1);
	}

	printf("mapping paddr 0x%lx to vaddr 0x%lx\n", offset, (uintptr_t)base);

	return base;
}

void init_map() {
	fd = open("/dev/mem", O_RDWR|O_SYNC);  
	if (fd == -1)  {  
		perror("init_map open failed:");
		exit(1);
	} 

	gpio_reset_base = create_map(GPIO_RESET_TOTAL_SIZE, fd, GPIO_RESET_BASE_ADDR);
	printf("DDR_TOTAL_SIZE = %lx, DDR_BASE_ADDR = %lx\n", DDR_TOTAL_SIZE, DDR_BASE_ADDR);
	ddr_base = create_map(DDR_TOTAL_SIZE, fd, DDR_BASE_ADDR);
}

void resetn(int val) {
	gpio_reset_base[0] = val;
}

void finish_map() {
	munmap((void *)gpio_reset_base, GPIO_RESET_TOTAL_SIZE);
	munmap((void *)ddr_base, DDR_TOTAL_SIZE);
	close(fd);
}

int main(int argc, char *argv[]) {
	/* map some devices into the address space of this program */
	init_map();

	/* reset RISC-V cores */
	resetn(0);

	loader(argv[1], argv[2], 0);

	/* finish resetting RISC-V cores */
	resetn(3);

	finish_map();

	return 0; 
} 
