# Nvim-Tree-Remote.nvim

A set of [Nvim-Tree](https://github.com/nvim-tree/nvim-tree.lua) actions to open files on another remote neovim.

## Installation

Install using vim-plug:
```vim
Plug 'kiyoon/nvim-tree-remote.nvim'
```

Install using packer:
```lua
use {'kiyoon/nvim-tree-remote.nvim'}
```

Setup telescope with path actions in vimscript / lua:
```vim
" For lua users, delete the first and the last line.
lua << EOF
local remote_actions = require('nvim_tree_remote')

require('nvim-tree').setup {
}
EOF
```
