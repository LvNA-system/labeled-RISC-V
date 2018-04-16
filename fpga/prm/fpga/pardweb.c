#include "common.h"
#include "jtag.h"
#include "cp.h"
#include "map.h"
#include <sys/time.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>

static const char *json_format =
"{ \n\
    \"cpu_switch\" : [%d, %d, %d, %d],\n\
    \"cache_usage\" : [%d, %d, %d, %d],\n\
    \"mem_usage\": [%lf, %lf, %lf, %lf]\n\
    }";

static struct itimerval it;
static char buf[4096];

static double period = 1.0;

#define PARD_ROOT_PATH "/root/jtag/"
#define PARD_JSON_PATH PARD_ROOT_PATH "data.json"
static const char *pard_web_path = "/root/pard_web";

void gen_web_json(char *buf) {
  int i;
  int state[4] = {0};
  int cache_cap[4] = {0};
  double bw[4] = {0.0};

  for (i = 0; i < 4; i ++) {
    uint32_t byte_read = read_cp_reg(get_cp_addr(1, 1, 0, i)) * 64;
    uint32_t byte_write = read_cp_reg(get_cp_addr(1, 1, 1, i)) * 64;
    uint32_t v = byte_read + byte_write;
    printf("read: %d write: %d\n", byte_read, byte_write);
    write_cp_reg(get_cp_addr(1, 1, 0, i), 0);
    write_cp_reg(get_cp_addr(1, 1, 1, i), 0);

    bw[i] = v / period / 1024 / 1024;
    if (bw[i] > 100.0) {
      bw[i] = 5;
    }
  }

  /*
  // fix approximation
  extra -= 100;
  while (extra > 0) {
  cache_cap[find_max_idx(cache_cap)] --;
  extra --;
  }
  */

  sprintf(buf, json_format, state[0], state[1], state[2], state[3],
      cache_cap[0], cache_cap[1], cache_cap[2], cache_cap[3],
      bw[0], bw[1], bw[2], bw[3]);
}

static void send_to_web(int signum) {
  int ret;
  int len;

  ret = setitimer(ITIMER_REAL, &it, NULL);
  if(ret != 0) {
    perror("");
    assert(0);
  }

  gen_web_json(buf);
  len = strlen(buf);
  FILE *fp = fopen(PARD_JSON_PATH, "w");
  assert(fp != NULL);
  fwrite(buf, len, 1, fp);
  fclose(fp);

  char cmd[256];
  sprintf(cmd, "scp " PARD_JSON_PATH " %s > /dev/null", pard_web_path);
  Log("%s", cmd);
  ret = system(cmd);
}

static void init_timer(void *handler) {
  struct sigaction s;
  int ret;
  memset(&s, 0, sizeof(s));
  s.sa_handler = (void (*)(int))handler;
  ret = sigaction(SIGALRM, &s, NULL);
  if(ret != 0) {
    perror("");
    assert(0);
  }

  int sec = (int)period;
  int usec =  (int)((period - sec) * 1000000);

  it.it_value.tv_sec = sec;
  it.it_value.tv_usec = usec;
  Log("s = %d, us = %d", sec, usec);
  ret = setitimer(ITIMER_REAL, &it, NULL);
  if(ret != 0) {
    perror("");
    assert(0);
  }
}

int main(int argc, char *argv[]) {
  /* map some devices into the address space of this program */
  init_map();

  reset_soft();
  goto_run_test_idle_from_reset();

  sigset_t s;
  void *handler = (void *)send_to_web;

  init_timer(handler);

  sigemptyset(&s);
  while(1) {
    sleep(1);
  }

  finish_map();
  return 0;
}
