#ifndef PARD_DBG_H
#define PARD_DBG_H
struct {
  const char *name;
  int idx;
} reg_table [] = {
  // register name
  {"x0", 0}, {"x1", 1}, {"x2", 2}, {"x3", 3}, {"x4", 4}, {"x5", 5}, {"x6", 6}, {"x7", 7},
  {"x8", 8}, {"x9", 9}, {"x10", 10}, {"x11", 11}, {"x12", 12}, {"x13", 13}, {"x14", 14}, {"x15", 15},
  {"x16", 16}, {"x17", 17}, {"x18", 18}, {"x19", 19}, {"x20", 20}, {"x21", 21}, {"x22", 22}, {"x23", 23},
  {"x24", 24}, {"x25", 25}, {"x26", 26}, {"x27", 27}, {"x28", 28}, {"x29", 29}, {"x30", 30}, {"x31", 31},
  // abi name
  {"zero", 0}, {"ra", 1}, {"sp", 2}, {"gp", 3}, {"tp", 4}, {"t0", 5}, {"t1", 6}, {"t2", 7},
  {"s0", 8}, {"s1", 9}, {"a0", 10}, {"a1", 11}, {"a2", 12}, {"a3", 13}, {"a4", 14}, {"a5", 15},
  {"a6", 16}, {"a7", 17}, {"s2", 18}, {"s3", 19}, {"s4", 20}, {"s5", 21}, {"s6", 22}, {"s7", 23},
  {"s8", 24}, {"s9", 25}, {"s10", 26}, {"s11", 27}, {"t3", 28}, {"t4", 29}, {"t5", 30}, {"t6", 31},
  {"fp", 8}
};

#define NR_REG (sizeof(reg_table) / sizeof(reg_table[0]))

struct {
  const char *name;
  int idx;
} csr_table [] = {
  {"mepc", 0x341},
  {"mcause", 0x342},
  {"mtval", 0x343},
  {"mhartid", 0xf14},
  {"dpc", 0x7b1},
  {"mtracebufferenable", 0x7c0},
  {"mtracebufferhead", 0x7c1},
  {"mtracebufferwindowsize", 0x7c2},
  {"mtracebufferindex", 0x7c3},
  {"mtracebuffertrigger", 0x7c4},

  {"mstackbufferenable", 0x7c5},
  {"mstackbufferhead", 0x7c6},
  {"mstackbuffertrigger", 0x7c7},
  {"mstacktargetindex", 0x7c8},
  {"mstackcallpcindex", 0x7c9},
  {"mstackarg0index", 0x7ca},
  {"mstackarg1index", 0x7cb},
  {"mstackarg2index", 0x7cc},

  {"mtracebuffercontent", 0xfc0},
  {"mstacktargetcontent", 0xfc1},
  {"mstackcallpccontent", 0xfc2},
  {"mstackarg0content", 0xfc3},
  {"mstackarg1content", 0xfc4},
  {"mstackarg2content", 0xfc5}
};

#define NR_CSR (sizeof(csr_table) / sizeof(csr_table[0]))
#endif
