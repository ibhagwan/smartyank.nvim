local M = {}

local __defaults = {
  highlight = {
    enabled = true,         -- highlight yanked text
    higroup = "IncSearch",  -- highlight group of yanked text
    timeout = 2000,         -- timeout for clearing the highlight
  },
  clipboard = {
    enabled = true
  },
  tmux = {
    enabled = true,
    -- remove `-w` to disable copy to host client's clipboard
    cmd = { 'tmux', 'set-buffer', '-w' }
  },
  osc52 = {
    enabled = true,
    ssh_only = true,        -- false to OSC52 yank also in local sessions
    silent = false,         -- true to disable the "n chars copied" echo
    echo_hl = "Directory",  -- highlight group of the OSC52 echo message
  }
}

local __config = vim.deepcopy(__defaults)
local __actions = nil

M.setup = function(opts)
  __config = vim.tbl_deep_extend("force", __config, opts or {})
  M.setup_actions()
  M.setup_aucmd()
end

M.osc52printf = function(...)
  local str = string.format(...)
  local base64 = require('smartyank.base64').encode(str)
  local osc52str = string.format("\x1b]52;c;%s\x07", base64)
  local bytes = vim.fn.chansend(vim.v.stderr, osc52str)
  assert(bytes > 0)
  if not __config.osc52.silent then
    local msg = string.format(
      "[smartyank] %d chars copied using OSC52 (%d bytes)", #str, bytes)
    if __config.osc52.echo_hl then
      vim.api.nvim_echo({ {msg, __config.osc52.echo_hl} }, false, {})
    else
      vim.api.nvim_out_write(msg .. "\n")
    end
  end
end

M.setup_actions = function()
  __actions = {}

  -- clipboard
  __actions[1] = {
    cond = function(valid)
      return valid and __config.clipboard and __config.clipboard.enabled and
          vim.fn.has('clipboard') == 1
    end,
    yank = function(str)
      pcall(vim.fn.setreg, "+", str)
    end
  }

  -- osc52
  __actions[2] = {
    cond = function(valid)
      return valid and __config.osc52 and __config.osc52.enabled and
          (not __config.osc52.ssh_only or vim.env.SSH_CONNECTION)
    end,
    yank = function(str)
      M.osc52printf(str)
    end
  }

  -- tmux
  __actions[3] = {
    cond = function(valid)
      return valid and __config.tmux and __config.tmux.enabled and vim.env.TMUX
    end,
    yank = function(str)
      local cmd = vim.deepcopy(__config.tmux.cmd)
      table.insert(cmd, str)
      vim.fn.system(cmd)
    end
  }

  -- highlight
  __actions[4] = {
    cond = function(_)
      return __config.highlight and __config.highlight.enabled
    end,
    yank = function(_)
      vim.highlight.on_yank({
        higroup = __config.highlight.higroup,
        timeout = __config.highlight.timeout
      })
    end
  }

  -- Add custom user actions
  if type(__config.actions) == "table" then
    for _, a in ipairs(__config.actions) do
      assert(type(a.cond) == "function" and type(a.yank) == "function")
      table.insert(__actions, a)
    end
  end
end

M.setup_aucmd = function()
  local function augroup(name, fnc)
    fnc(vim.api.nvim_create_augroup(name, { clear = true }))
  end

  augroup('SmartTextYankPost', function(g)
    -- Setup our actions table
    if not __actions then M.setup_actions() end

    -- Highlight yanked text and copy to system clipboard
    -- TextYankPost is also called on deletion, limit to
    -- yanks via v:operator
    -- If we are connected over ssh also copy using OSC52
    -- If we are connected to tmux also copy to tmux buffer
    vim.api.nvim_create_autocmd("TextYankPost", {
      group = g,
      pattern = '*',
      desc = "[smartyank] Copy to clipboard/tmux/OSC52",
      callback = function()
        -- check for local|global disable
        if vim.b.smartyank_disable or vim.g.smartyank_disable then
          return
        end
        local ok, yank_data = pcall(vim.fn.getreg, "0")
        local valid_yank = ok and #yank_data > 0 and vim.v.operator == 'y'
        for _, a in ipairs(__actions) do
          if a.cond(valid_yank) then
            a.yank(yank_data)
          end
        end
      end
    })
  end)
end

-- Run once with defaults at initial loading
-- in case user doesn't call setup
M.setup_aucmd()

return M
