#ifndef __DTM_H__
#define __DTM_H__

#include "common.h"

void load_program(const char *bin_file, uint64_t hartid, uint32_t base);
void start_program(uint64_t hartid);
void check_loaded_program(const char *bin_file, uint64_t hartid, uint32_t base);

void init_dtm();

#endif
