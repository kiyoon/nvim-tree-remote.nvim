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

local function remote_nvim_open(command, path)
  if vim.g.nvim_tree_remote_socket_path then
    print(command)
    local python_path = python_file("nvim_command.py")
    local python_host = 'python3'
    if vim.g.python3_host_prog then
      python_host = vim.g.python3_host_prog
    end
    local return_code = os.execute("'" .. python_host .. "' '" .. python_path .. "' '" .. vim.g.nvim_tree_remote_socket_path .. "' '" .. command .. " " .. path .. "' 0")
    if return_code ~= 0 then
      if vim.g.nvim_tree_remote_tmux_pane then
        -- Check current pane
        local handle = io.popen("tmux display-message -p '#{pane_id}'")
        if handle ~= nil then
          local current_pane_id = vim.fn.trim(handle:read("*a"))
          handle:close()

          -- split pane
          local new_pane_id = nil
          if vim.g.nvim_tree_remote_tmux_split_position == "bottom" then
            handle = io.popen("tmux split-window -v -l " .. vim.g.nvim_tree_remote_tmux_editor_size .. " -t " .. vim.g.nvim_tree_remote_tmux_pane .. " -P -F '#{pane_id}'")
          elseif vim.g.nvim_tree_remote_tmux_split_position == "right" then
            handle = io.popen("tmux split-window -h -l " .. vim.g.nvim_tree_remote_tmux_editor_size .. " -t " .. vim.g.nvim_tree_remote_tmux_pane .. " -P -F '#{pane_id}'")
          elseif vim.g.nvim_tree_remote_tmux_split_position == "left" then
            handle = io.popen("tmux split-window -h -b -l " .. vim.g.nvim_tree_remote_tmux_editor_size .. " -t " .. vim.g.nvim_tree_remote_tmux_pane .. " -P -F '#{pane_id}'")
          else
            handle = io.popen("tmux split-window -v -b -l " .. vim.g.nvim_tree_remote_tmux_editor_size .. " -t " .. vim.g.nvim_tree_remote_tmux_pane .. " -P -F '#{pane_id}'")
          end
          if handle ~= nil then
            new_pane_id = vim.fn.trim(handle:read("*a"))
            handle:close()
          end

          -- Register Treemux sidebar (turn off sidebar from the new editor pane)
          if vim.g.nvim_tree_remote_treemux_path then
            os.execute("'" .. vim.g.nvim_tree_remote_treemux_path .. "/scripts/register_sidebar.sh' " .. new_pane_id .. " " .. current_pane_id)
          end

          -- focus on the original pane
          os.execute("tmux select-pane -t '" .. current_pane_id .. "'")

          -- Open nvim
          if vim.g.nvim_tree_remote_editor_init_file and vim.g.nvim_tree_remote_editor_init_file ~= '' then
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' 'nvim --listen '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. vim.g.nvim_tree_remote_socket_path .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' ' -u '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. vim.g.nvim_tree_remote_editor_init_file .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' Enter")
          else
            --os.execute("tmux send-keys 'nvim --listen '\\'" .. vim.g.nvim_tree_remote_socket_path .. "\\' Enter")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' 'nvim --listen '")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' \\''" .. vim.g.nvim_tree_remote_socket_path .. "'\\'")
            os.execute("tmux send-keys -t '" .. new_pane_id .. "' Enter")
          end
          os.execute("'" .. python_host .. "' '" .. python_path .. "' '" .. vim.g.nvim_tree_remote_socket_path .. "' 'tabnew " .. path .. "' 100")
        end
      else
        print("Error executing command: " .. command)
      end
    end
  else
    print("ERROR: g:nvim_tree_remote_socket_path not set")
  end
end

local function open_local_or_remote(remote_command)
  local node = nt_api.tree.get_node_under_cursor()
  if node.type == "file" then
    remote_nvim_open(remote_command, node.absolute_path)
  else
    nt_api.node.open.edit()
  end
end


remote_actions.vsplit = function()
  open_local_or_remote("vsplit")
end

remote_actions.split = function()
  open_local_or_remote("split")
end

remote_actions.tabnew = function()
  open_local_or_remote("tabnew")
end

remote_actions.edit = function()
  open_local_or_remote("edit")
end

return remote_actions
