// See LICENSE for license details.
#include <vpi_user.h>
#include <svdpi.h>

extern "C" int debug_tick
(
  unsigned char* debug_req_valid,
  unsigned char  debug_req_ready,
  int*           debug_req_bits_addr,
  int*           debug_req_bits_op,
  long long*     debug_req_bits_data,
  unsigned char  debug_resp_valid,
  unsigned char* debug_resp_ready,
  int            debug_resp_bits_resp,
  long long      debug_resp_bits_data
)
{
  return 0;
}
