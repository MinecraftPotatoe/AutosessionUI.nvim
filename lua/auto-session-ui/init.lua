---@class opts
---@field use_telescope_picker boolean

---@type opts
local defaults = {
  use_telescope_picker = true,
}

local core = require("auto-session-ui.core")
local api = require("auto-session-ui.api")
local lib = require("auto-session-ui.lib")
local picker = require("auto-session-ui.picker")
local dataPath = vim.fn.stdpath("data") .. "/advanced_session_picker"

local M = {}

function M.add_current_session()
  local path = api.get_current_session_path()
  core.add_rename_session(path)
end

function M.remove_current_session()
  local path = api.get_current_session_path()
  core.remove_session(path)
end

function M.favorite_current_session()
  local path = api.get_current_session_path()
  core.favorite_session(path)
end

---@param opts opts
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts)
  api.setup()
  picker.setup(opts)
end

function M.pick_session()
  picker.pick_session_with_tree(nil, true)
end

return M
