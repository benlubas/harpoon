local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data")
local Job = require("plenary.job")

local M = {}

M.data_path = data_path

function M.project_key()
  return vim.loop.cwd()
end

M.cached_branch_key = nil

function M.branch_key()
  if M.cached_branch_key then
    return M.cached_branch_key
  end
  -- `git branch --show-current` requires Git v2.22.0+ so going with more
  -- widely available command
  local branch = M.get_os_command_output({
    "git",
    "branch",
    "--show-current",
  })[1]

  if branch then
    M.cached_branch_key = vim.loop.cwd() .. "-" .. branch
  else
    M.cached_branch_key = M.project_key()
  end
  return M.cached_branch_key
end

function M.normalize_path(item)
  return Path:new(item):make_relative(M.project_key())
end

function M.get_os_command_output(cmd, cwd)
  local start = vim.loop.now()
  if type(cmd) ~= "table" then
    print("Harpoon: [get_os_command_output]: cmd has to be a table")
    return {}
  end
  local command = table.remove(cmd, 1)
  local stderr = {}
  local stdout, ret = Job:new({
    command = command,
    args = cmd,
    cwd = cwd,
    on_stderr = function(_, data)
      table.insert(stderr, data)
    end,
  }):sync()

  print("cmd time:", (vim.loop.now() - start) / 1000)

  return stdout, ret, stderr
end

function M.split_string(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

function M.is_white_space(str)
  return str:gsub("%s", "") == ""
end

return M
