"""
OpenOCD RPC example, covered by GNU GPLv3 or later
Copyright (C) 2014 Andreas Ortmann (ortmann@finf.uni-hannover.de)
"""

import socket
import itertools
import sys
from dm_reg import *
from dm_utils import *

def hexify(data):
    return "<None>" if data is None else ("0x%08x" % data)

class OpenOcd:
    COMMAND_TOKEN = '\x1a'
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.tclRpcIp       = "127.0.0.1"
        self.tclRpcPort     = 6666
        self.bufferSize     = 4096

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def __enter__(self):
        self.sock.connect((self.tclRpcIp, self.tclRpcPort))
        return self

    def __exit__(self, type, value, traceback):
        try:
            self.send("exit")
        finally:
            self.sock.close()

    def send(self, cmd):
        """Send a command string to TCL RPC. Return the result that was read."""
        if cmd == 'exit':
            data = ('exit' + OpenOcd.COMMAND_TOKEN).encode('utf-8')
        else:
            data = ('capture "' + cmd + '"' + OpenOcd.COMMAND_TOKEN).encode("utf-8")
        if self.verbose:
            print("<- ", data)

        self.sock.send(data)
        return self._recv()

    def _recv(self):
        """Read from the stream until the token (\x1a) was received."""
        data = bytes()
        while True:
            chunk = self.sock.recv(self.bufferSize)
            data += chunk
            if bytes(OpenOcd.COMMAND_TOKEN).encode("utf-8") in chunk:
                break

        if self.verbose:
            print("-> ", data)

        data = data.decode("utf-8").strip()
        data = data[:-1] # strip trailing \x1a

        return data.strip()

    def dmi_read(self, addr):
        return self.send("riscv dmi_read {}".format(addr))

    def dmi_write(self, addr, data):
        return self.send("riscv dmi_write {} {}".format(addr, data))

    # Field value should be integer!
    def dmi_write_fields(self, dm_reg, **fields_write):
        orig = self.dmi_read(dm_reg.addr)
        set_reg(dm_reg, orig)
        for f in fields_write:
            setattr(dm_reg, f, fields_write[f])
        print_fields(dm_reg)
        self.dmi_write(dm_reg.addr, dm_reg.bits)

    def dmi_read_fields(self, dm_reg, v=True):
        print("read files")
        orig = self.dmi_read(dm_reg.addr)
        set_reg(dm_reg, orig)
        if v:
            print_fields(dm_reg)
