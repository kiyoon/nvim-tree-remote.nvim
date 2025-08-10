---@module 'nvim_tree_remote.transport' Open a file on a remote Neovim instance
---@author Kiyoon Kim
---@license MIT

local uv = vim.uv or vim.loop

local function retry(fn, timeout_secs)
  local attempts = math.max(1, math.floor((timeout_secs or 0) * 1000 / 100)) -- 100ms steps
  local last_err
  for i = 1, attempts do
    local ok, err = pcall(fn)
    if ok then
      return true
    end
    last_err = err
    if i < attempts then
      uv.sleep(100)
    end
  end
  return false, last_err
end

---@meta

---@class NTR.Transport
local transport = {}

---@alias NTR.AddrKind 'pipe'|'tcp'

local function kind_of(addr)
  if not addr or addr == "" then
    return "pipe"
  end
  if addr:match("^%d+%.%d+%.%d+%.%d+:%d+$") or addr:match("^[^:]+:%d+$") then
    return "tcp"
  end
  return "pipe"
end

local function with_server(addr, fn)
  local kind = kind_of(addr)
  local chan = assert(vim.fn.sockconnect(kind, addr, { rpc = true }), "sockconnect failed")
  local ok, err = pcall(fn, chan)
  pcall(vim.fn.chanclose, chan)
  if not ok then
    error(err)
  end
end

---Execute an Ex command on the remote Neovim instance.
---@param ex string    -- Ex command without preceding ':'
---@param addr_override string|nil
---@param timeout_secs number|nil
function transport.exec(ex, addr_override, timeout_secs)
  local function attempt()
    local addr = addr_override or vim.g.nvim_tree_remote_socket_path
    if not addr or addr == "" then
      error("nvim-tree-remote: set g:nvim_tree_remote_socket_path to the target Neovim address")
    end
    with_server(addr, function(chan)
      vim.rpcrequest(chan, "nvim_command", ex)
    end)
  end
  local ok, err = retry(attempt, timeout_secs)
  if not ok then
    error(err or "transport.exec retry failed")
  end
end

---Open a path on the remote instance using a given Ex command.
---@param path string
---@param open_cmd  'edit'|'split'|'vsplit'|'tabnew'|nil
---@param addr_override string|nil
---@param timeout_secs number|nil
function transport.open(path, open_cmd, addr_override, timeout_secs)
  if open_cmd ~= "split" and open_cmd ~= "vsplit" and open_cmd ~= "tabnew" then
    open_cmd = "edit"
  end
  local ex = ("%s %s"):format(open_cmd, vim.fn.fnameescape(path))
  transport.exec(ex, addr_override, timeout_secs)
end

return transport
