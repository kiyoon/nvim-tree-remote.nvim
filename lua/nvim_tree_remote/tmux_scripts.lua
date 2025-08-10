local M = {}

local function script_path()
  return debug.getinfo(2, "S").source:sub(2)
end

local function get_parent_dir(path)
  return vim.fn.fnamemodify(path, ":h")
end

function M.get_tmux_pane_running_command(pane_id)
  local bash_path = get_parent_dir(get_parent_dir(get_parent_dir(script_path())))
    .. "/scripts/tmux_pane_current_command_full.sh"
  -- system call
  local handle = io.popen(bash_path .. " '" .. pane_id .. "' 2> /dev/null")
  if handle == nil then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return vim.fn.trim(result)
end

function M.get_current_tmux_window_nvim_address()
  local bash_path = get_parent_dir(get_parent_dir(get_parent_dir(script_path())))
    .. "/scripts/tmux_current_window_nvim_addr.sh"
  -- system call
  local handle = io.popen(bash_path)
  if handle == nil then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return vim.fn.trim(result)
end

function M.tmux_pane_wait_nvim(pane_id)
  local bash_path = get_parent_dir(get_parent_dir(get_parent_dir(script_path()))) .. "/scripts/tmux_pane_wait_nvim.sh"
  -- system call
  local handle = io.popen(bash_path .. " '" .. pane_id .. "' 2> /dev/null")
  if handle == nil then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return vim.fn.trim(result)
end

return M
