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

local function get_tmux_pane_running_command(pane_id)
  local bash_path = get_parent_dir(get_parent_dir(get_parent_dir(script_path()))) .. "/scripts/tmux_pane_current_command_full.sh"
  -- system call
  local handle = io.popen(bash_path .. " '" .. pane_id .. "'")
  if handle == nil then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return vim.fn.trim(result)
end

remote_actions.remote_nvim_open = function(socket_path, command, path, tmux)
  -- Args:
  --  socket_path: str, path to nvim --listen socket
  --  command: str, vim command to run in neovim (e.g. edit, split, vsplit, tabnew)
  --  path: str, path to file to open
  --  tmux: table, tmux options
  --    tmux.pane: str | nil, pane ID to open in or make split from
  --    tmux.split_position: str, split direction, or empty string for no split (e.g. "top", "bottom", "left", "right", "")
  --    tmux.split_size: str, split size (e.g. "40" means 40 rows, or "70%". Only used if tmux_split is top / bottom / left / right.
  --    tmux.focus: str, either "tree" or "editor".
  if socket_path then
    local python_path = python_file("nvim_command.py")
    local python_host = 'python3'
    if vim.g.python3_host_prog then
      python_host = vim.g.python3_host_prog
    end
    local return_code = os.execute("'" .. python_host .. "' '" .. python_path .. "' '" .. socket_path .. "' '" .. command .. " " .. path .. "' 0")
    if return_code ~= 0 then
      if tmux.pane ~= nil then
        -- Check current pane
        local handle = io.popen("tmux display-message -p '#{pane_id}'")
        if handle ~= nil then
          local current_pane_id = vim.fn.trim(handle:read("*a"))
          handle:close()

          -- split pane
          local new_pane_id = nil
          if tmux.split_position == "bottom" then
            handle = io.popen("tmux split-window -v -l " .. tmux.split_size .. " -t " .. tmux.pane .. " -P -F '#{pane_id}'")
          elseif tmux.split_position == "right" then
            handle = io.popen("tmux split-window -h -l " .. tmux.split_size .. " -t " .. tmux.pane .. " -P -F '#{pane_id}'")
          elseif tmux.split_position == "left" then
            handle = io.popen("tmux split-window -h -b -l " .. tmux.split_size .. " -t " .. tmux.pane .. " -P -F '#{pane_id}'")
          elseif tmux.split_position == "top" then
            handle = io.popen("tmux split-window -v -b -l " .. tmux.split_size .. " -t " .. tmux.pane .. " -P -F '#{pane_id}'")
          else
            -- default open to main pane, if main pane is not running any processes
            handle = nil
            local pane_command = get_tmux_pane_running_command(tmux.pane)
            if pane_command == "" then
              new_pane_id = tmux.pane
              os.execute("tmux send-keys -t '" .. new_pane_id .. "' C-c")
            else
              print("ERROR: Main pane has a running process.")
              return
            end
          end
          if handle ~= nil then
            new_pane_id = vim.fn.trim(handle:read("*a"))
            handle:close()
          end
          -- Register Treemux sidebar (turn off sidebar from the new editor pane)
          if vim.g.nvim_tree_remote_treemux_path and new_pane_id ~= tmux.pane then
            os.execute("'" .. vim.g.nvim_tree_remote_treemux_path .. "/scripts/register_sidebar.sh' " .. new_pane_id .. " " .. current_pane_id)
          end

          if tmux.focus == "tree" then
            -- focus on the original pane
            os.execute("tmux select-pane -t '" .. current_pane_id .. "'")
          end

          -- Open nvim
          if vim.g.nvim_tree_remote_editor_init_file and vim.g.nvim_tree_remote_editor_init_file ~= '' then
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' 'nvim --listen '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. socket_path .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' ' -u '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. vim.g.nvim_tree_remote_editor_init_file .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' Enter")
          else
            --os.execute("tmux send-keys 'nvim --listen '\\'" .. vim.g.nvim_tree_remote_socket_path .. "\\' Enter")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' 'nvim --listen '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. socket_path .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' Enter")
          end
          os.execute("'" .. python_host .. "' '" .. python_path .. "' '" .. socket_path .. "' 'edit " .. path .. "' 10")

          if tmux.focus == "editor" then
            -- focus on the original pane
            os.execute("tmux select-pane -t '" .. new_pane_id .. "'")
          end
        end
      else
        print("Error executing command: " .. command)
      end
    else
      if tmux.pane ~= nil then
        if tmux.focus == "editor" then
          local focus_command = 'call system("tmux select-pane -t $TMUX_PANE")'
          os.execute("'" .. python_host .. "' '" .. python_path .. "' '" .. socket_path .. "' '" .. focus_command .. "' 0")
        end
      end
    end
  else
    print("ERROR: g:nvim_tree_remote_socket_path not set")
  end
end

remote_actions.open_file_remote_and_folder_local = function(socket_path, remote_command, tmux_opts)
  local node = nt_api.tree.get_node_under_cursor()
  if node.type == "file" then
    remote_actions.remote_nvim_open(socket_path, remote_command, node.absolute_path, tmux_opts)
  else
    nt_api.node.open.edit()
  end
end


remote_actions.tmux_defaults = function()
  return {
    pane = vim.g.nvim_tree_remote_tmux_pane,
    split_position = vim.g.nvim_tree_remote_tmux_split_position,
    split_size = vim.g.nvim_tree_remote_tmux_split_size,
    focus = vim.g.nvim_tree_remote_tmux_focus,
  }
end

remote_actions.vsplit = function()
  remote_actions.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "vsplit",
    remote_actions.tmux_defaults()
  )
end

remote_actions.split = function()
  remote_actions.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "split",
    remote_actions.tmux_defaults()
  )
end

remote_actions.tabnew = function()
  remote_actions.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "tabnew",
    remote_actions.tmux_defaults()
  )
end

remote_actions.edit = function()
  remote_actions.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "edit",
    remote_actions.tmux_defaults()
  )
end

remote_actions.tabnew_main_pane = function()
  local tmux_opts = remote_actions.tmux_defaults()
  tmux_opts.split_position = ""
  remote_actions.open_file_remote_and_folder_local(
    vim.g.nvim_tree_remote_socket_path,
    "tabnew_main_pane",
    tmux_opts
  )
end

return remote_actions
