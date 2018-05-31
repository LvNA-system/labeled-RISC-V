#ifndef __COMMON_H__
#define __COMMON_H__

#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>

#ifndef __cplusplus
typedef uint8_t bool;
#endif

#define true 1
#define false 0

#define Log(format, ...) printf("[%s,%d,%s] " format "\n", __FILE__, __LINE__, __func__, ##__VA_ARGS__)

//#define DEBUG

#ifdef DEBUG
# define Debug(...) Log(__VA_ARGS__)
#else
# define Debug(...)
#endif

#endif
