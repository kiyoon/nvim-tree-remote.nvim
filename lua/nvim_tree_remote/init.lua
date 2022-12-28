local status_ok, nt_api = pcall(require, "nvim-tree.api")
if not status_ok then
	return
end

local remote_actions = setmetatable({}, {
  __index = function(_, k)
    error("Key does not exist for 'nvim_tree_remote': " .. tostring(k))
  end,
})

local function script_path()
   return debug.getinfo(2, "S").source:sub(2)
end

local function get_parent_dir(path)
  return vim.fn.fnamemodify(path, ":h")
end


local function python_file(name)
  return get_parent_dir(get_parent_dir(get_parent_dir(script_path()))) .. "/python/" .. name
end

local function remote_nvim_command(command)
  if vim.g.nvim_tree_remote_socket_path then
    print(command)
    local path = python_file("nvim_command.py")
    local python_host = 'python3'
    if vim.g.python3_host_prog then
      python_host = vim.g.python3_host_prog
    end
    os.execute("'" .. python_host .. "' '" .. path .. "' '" .. vim.g.nvim_tree_remote_socket_path .. "' '" .. command .. "'")
  else
    print("ERROR: g:nvim_tree_remote_socket_path not set")
  end
end


remote_actions.vsplit = function()
  local nt_abspath = nt_api.tree.get_node_under_cursor().absolute_path
  remote_nvim_command("vsplit " .. nt_abspath)
end

remote_actions.split = function()
  local nt_abspath = nt_api.tree.get_node_under_cursor().absolute_path
  remote_nvim_command("split " .. nt_abspath)
end

remote_actions.tabnew = function()
  local nt_abspath = nt_api.tree.get_node_under_cursor().absolute_path
  remote_nvim_command("tabnew " .. nt_abspath)
end

remote_actions.edit = function()
  local nt_abspath = nt_api.tree.get_node_under_cursor().absolute_path
  remote_nvim_command("edit " .. nt_abspath)
end

return remote_actions
