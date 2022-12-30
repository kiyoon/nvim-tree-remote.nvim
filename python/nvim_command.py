#!/use/bin/env python3

import sys
import time

import pynvim

nvim_addr = sys.argv[1]
command = sys.argv[2]
timeout = int(sys.argv[3])


if timeout > 0:
    for _ in range(timeout * 10):
        try:
            nvim = pynvim.attach('socket', path=nvim_addr)
        except Exception:
            time.sleep(0.1)
        else:
            break
    else:
        # Silently fail if Neovim is not running
        sys.exit(1)
else:
    try:
        nvim = pynvim.attach('socket', path=nvim_addr)
    except (FileNotFoundError, pynvim.NvimError):
        # Silently fail if Neovim is not running
        sys.exit(1) 

try:
    nvim.command(command)
except (FileNotFoundError, pynvim.NvimError):
    # Silently fail if Neovim is not running
    sys.exit(1) 
