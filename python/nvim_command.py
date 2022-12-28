#!/use/bin/env python3

import sys

import pynvim

nvim_addr = sys.argv[1]
command = sys.argv[2]

try:
    nvim = pynvim.attach('socket', path=nvim_addr)
    nvim.command(command)
except (FileNotFoundError, pynvim.NvimError):
    pass
