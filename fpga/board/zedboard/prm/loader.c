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

#define DDR_TOTAL_SIZE		(1 << 28)
#define DDR_BASE_ADDR		0x10000000

#define GPIO_RESET_TOTAL_SIZE	(1 << 16)
#define GPIO_RESET_BASE_ADDR	0x41200000

void *ddr_base;
volatile uint32_t *gpio_reset_base;
int	fd;

void loader(char *imgfile, char *dtbfile, int offset) {
	FILE *fp = fopen(imgfile, "rb");
	assert(fp);

	fseek(fp, 0, SEEK_END);
	long size = ftell(fp);
	printf("image size = %ld\n", size);

	fseek(fp, 0, SEEK_SET);
	fread(ddr_base + offset, size, 1, fp);

	fclose(fp);

	fp = fopen(dtbfile, "rb");
	if (fp == NULL) {
		printf("No valid dtb file provided. Dtb in bootrom will be used.\n");
		return ;
	}

	fseek(fp, 0, SEEK_END);
	size = ftell(fp);
	printf("dtb size = %ld\n", size);

	fseek(fp, 0, SEEK_SET);
	fread(ddr_base + offset + 0x8, size, 1, fp);

	fclose(fp);
}

void* create_map(size_t size, int fd, off_t offset) {
	void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, offset);
	
	if (base == NULL) {
		perror("init_mem mmap failed:");
		close(fd);
		exit(1);
	}

	return base;
}

void init_map() {
	fd = open("/dev/mem", O_RDWR|O_SYNC);  
	if (fd == -1)  {  
		perror("init_map open failed:");
		exit(1);
	} 

	gpio_reset_base = create_map(GPIO_RESET_TOTAL_SIZE, fd, GPIO_RESET_BASE_ADDR);
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

//	loader(argv[1], argv[2], 0x4000000);

	/* finish resetting RISC-V cores */
	resetn(3);

	finish_map();

	return 0; 
} 
