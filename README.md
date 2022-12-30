# Nvim-Tree-Remote.nvim

A set of [Nvim-Tree](https://github.com/nvim-tree/nvim-tree.lua) actions to open files on another remote neovim.

Why? Sometimes you want to use Nvim-Tree as a standalone file browser. This way, you can make your own IDE with Tmux, for example.  
The problem is that the Nvim-Tree doesn't interact with another Neovim which can get annoying.

With this tool, you can control a remote instance of Neovim which makes it possible to use Nvim-Tree as a seamless standalone file explorer!

## Installation

Install using vim-plug:
```vim
Plug 'kiyoon/nvim-tree-remote.nvim'
```

Install using packer:
```lua
use {'kiyoon/nvim-tree-remote.nvim'}
```

Install `pynvim`.  
```bash
pip3 install --user pynvim
```

Setup Nvim-Tree with remote actions in vimscript / lua:  
```vim
" For lua users, delete the first and the last line.
lua << EOF

-- Remote nvim's --listen address
vim.g.nvim_tree_remote_socket_path = '/tmp/nvim_tree_remote_socket'

local nvim_tree = require('nvim-tree')
local nt_remote = require('nvim_tree_remote')

nvim_tree.setup {
  -- ...
  view = {
    mappings = {
      list = {
        { key = { "l", "<CR>", "<C-t>", "<2-LeftMouse>" }, action = "remote_tabnew", action_cb = nt_remote.tabnew },
        { key = { "v", "<C-v>" }, action = "remote_vsplit", action_cb = nt_remote.vsplit },
        { key = "<C-x>", action = "remote_split", action_cb = nt_remote.split },
        { key = "o", action = "remote_edit", action_cb = nt_remote.edit },
        { key = "h", action = "close_node" },
      },
    },
  },
  remove_keymaps = {
    'O',
  },
  -- ...
}
EOF
```

## Usage

Run neovim like  
```bash
nvim --listen /tmp/nvim_tree_remote_socket
```

Then, run another nvim with Nvim-Tree.  
```bash
nvim .
```

If you open files from the Nvim-Tree, the remote nvim will open the file.  
Change `g:nvim_tree_remote_socket_path` to your Nvim-Tree to update the remote path to another Neovim host.

### Tmux

Optionally, you can open an nvim instance as a new tmux split.

```vim
let g:nvim_tree_remote_tmux_pane = '.1'
let g:nvim_tree_remote_tmux_split = 'top'  " top / bottom / left / right
let g:nvim_tree_remote_editor_init_file = ''	" ~/.config/nvim/init.vim
```


#### [Treemux](https://github.com/kiyoon/treemux)

This will make it possible to turn off the sidebar from the editor.

```vim
let g:nvim_tree_remote_treemux_path = '~/.tmux/plugins/treemux'
```
