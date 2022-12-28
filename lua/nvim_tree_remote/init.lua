local remote_actions = setmetatable({}, {
  __index = function(_, k)
    error("Key does not exist for 'nvim_tree_remote': " .. tostring(k))
  end,
})

local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*[/\\])")
end

local function get_parent_dir(path)
  return path:match("(.*[/\\])")
end

local function python_file(name)
  return get_parent_dir(get_parent_dir(script_path())) .. "/python/" .. name
end

remote_actions.open_vsplit = function()
  local path = python_file("nvim_command.py")
  local nt_abspath = require('nvim-tree.api').get_node_at_cursor().absolute_path
  os.execute("python3 '" .. path .. "' '" .. vim.g.nvim_tree_remote_socket_path .. "' 'vsp \\'" .. nt_abspath .. "\\''")
end

return remote_actions
