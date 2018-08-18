void init_map();
void finish_map();
void init_jtag();

void init_platform() {
  init_map();
  init_jtag();
}

void finish_platform() {
  finish_map();
}
