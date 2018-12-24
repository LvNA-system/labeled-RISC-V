from ctypes import *
from dm_reg import *

def print_fields(dm_reg):
    names = [f[0] for f in dm_reg.reg._fields_ if f[0]]
    align = len(max(names, key=len))
    for name in reversed(names):
        aligned_name = name.ljust(align, ' ')
        value  = hex(int(getattr(dm_reg, name)))
        print(aligned_name + ': ' + value)

def set_reg(dm_reg, hex_str):
    dm_reg.bits = int(hex_str, 16)
