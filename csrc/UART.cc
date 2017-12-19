// See LICENSE for license details.

#include <cstdio>
#include <cassert>
#include <map>

#include <fesvr/dtm.h>
#include <vpi_user.h>
#include <svdpi.h>

using std::map;

map<unsigned int, FILE *> m;

extern "C" void uart_tick
(
  char  data,
  int   addr
)
{
  FILE *f = m[addr];
  if (!f) {
	char name[200];
	sprintf(name, "serial@%x", addr);
	assert(f = fopen(name, "w"));
	m[addr] = f;
  }
  fprintf(f, "%c", data);
  fflush(f);
}
