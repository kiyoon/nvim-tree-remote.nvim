# Nvim-Tree-Remote.nvim

A set of [Nvim-Tree](https://github.com/nvim-tree/nvim-tree.lua) actions to open files on another remote neovim.

Why? Sometimes you want to use Nvim-Tree as a standalone file browser. This way, you can make your own IDE with Tmux, for example.  
The problem is that the Nvim-Tree doesn't interact with another Neovim which can get annoying.

With this tool, you can control a remote instance of Neovim which makes it possible to use Nvim-Tree as a seamless standalone file explorer!

## Installation

Install `pynvim`.  
```bash
/usr/bin/python3 -m pip install --user pynvim
```

Install using lazy.nvim:

```lua
-- Remote nvim's --listen address
vim.g.nvim_tree_remote_socket_path = '/tmp/nvim_tree_remote_socket'
vim.g.nvim_tree_remote_python_path = '/usr/bin/python3'  -- use python with pynvim installed

local function nvim_tree_on_attach(bufnr)
  local nt_remote = require "nvim_tree_remote"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set("n", "l", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<CR>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<C-t>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "<2-LeftMouse>", nt_remote.tabnew, opts "Open in treemux")
  vim.keymap.set("n", "v", nt_remote.vsplit, opts "Vsplit in treemux")
  vim.keymap.set("n", "<C-v>", nt_remote.vsplit, opts "Vsplit in treemux")
  vim.keymap.set("n", "<C-x>", nt_remote.split, opts "Split in treemux")
  vim.keymap.set("n", "o", nt_remote.tabnew_main_pane, opts "Open in treemux without tmux split")
end
local nvim_tree = require('nvim-tree')
local nt_remote = require('nvim_tree_remote')

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        on_attach = nvim_tree_on_attach,
      }
    end,
  }
})
```

## Usage

**If you came here for [Treemux](https://github.com/kiyoon/treemux), you don't have to worry about setting the variables because Treemux overrides them all!**

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
let g:nvim_tree_remote_tmux_split_position = 'top'  " top / bottom / left / right
let g:nvim_tree_remote_tmux_editor_init_file = ''	" ~/.config/nvim/init.vim
let g:nvim_tree_remote_tmux_split_size = '70%'
let g:nvim_tree_remote_tmux_focus = 'editor'      " tree / editor
```


#### [Treemux](https://github.com/kiyoon/treemux)

This will make it possible to turn off the sidebar from the editor.  
Again, you don't have to set this manually because Treemux will override it.

```vim
let g:nvim_tree_remote_treemux_path = '~/.tmux/plugins/treemux'
```

### Advanced configuration

You can create your own functions with fine-tuned parameters.  
WARNING! The plugin is currently experimental and the function might change in the future.

```lua
-- lua code
local nt_remote = require('nvim_tree_remote')

-- Change the arguments as you like.
-- i.e. You can choose to ignore some of the global variables and replace to what you want.
-- local function default_edit()
--   -- This is the same as nt_remote.edit
--   nt_remote.open_file_remote_and_folder_local(
--     vim.g.nvim_tree_remote_socket_path,
--     "edit",
--     nt_remote.tmux_defaults
--   )
-- end

local function vsplit_focus()
  local tmux_options = nt_remote.tmux_defaults()
  -- below are the default values
  -- tmux_options.pane = vim.g.nvim_tree_remote_tmux_pane
  -- tmux_options.split_position = vim.g.nvim_tree_remote_tmux_split_position
  -- tmux_options.split_size = vim.g.nvim_tree_remote_tmux_split_size
  -- tmux_options.focus = vim.g.nvim_tree_remote_tmux_focus
  tmux_options.focus = "editor"
  nt_remote.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "vsplit",
    tmux_options
  )
end

local function tabnew_main_pane_no_split()
  local tmux_options = nt_remote.tmux_defaults()
  tmux_options.split_position = ""
  nt_remote.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "tabnew",
    tmux_options
  )
end

nvim_tree.setup {
  -- ...
  view = {
    mappings = {
      list = {
        { key = "v", action = "vsplit_focus", action_cb = vsplit_focus },
        { key = "o", action = "tabnew_main_pane", action_cb = tabnew_main_pane_no_split },
      },
    },
  },
  -- ...
}
```
