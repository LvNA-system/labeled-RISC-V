#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>

typedef uint8_t bool;
#define true 1
#define false 0

// #define DEBUG

#ifdef DEBUG
# define Log(format, ...) printf("[%s,%d] " format "\n", __func__, __LINE__, ##__VA_ARGS__)
#else
# define Log(format, ...)
#endif

#endif
