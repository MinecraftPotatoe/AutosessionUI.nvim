local M = {}

local lib = require("auto-session-ui.lib")
local as = require("auto-session")
local asl = require("auto-session.lib")
local t = require("auto-session-ui.types")

local dataPath = vim.fn.stdpath("data") .. "/advanced_session_picker"

---@class AutoSessionData
---@field session_name string
local AutoSessionData = {}

---@return AutoSessionData[]
local function get_autosession_list()
  return require("auto-session.lib").get_session_list(as.get_root_dir())
end

function M.get_current_session_path()
  if as.session_exists_for_cwd() then
    local path = asl.current_session_name(false)
    if path == nil or path == "" then
      return vim.fn.getcwd()
    end
    return path
  else
    as.SaveSession(vim.fn.getcwd(), false)
    return vim.fn.getcwd()
  end
end

---@param path string
function M.restore_session(path)
  vim.cmd.wa()
  as.RestoreSession(path, { show_message = false })
end

function M.setup()
  if not lib.file_exists(dataPath) then
    M.create_default_data_file()
  end
end

---@param data SessionData[]
---@return SessionData[]
local function validate_sessions(data)
  local sessions = assert(get_autosession_list())
  ---@type string[]
  local names = lib.map(sessions, lib.fn("p1.session_name"))
  for i, session in pairs(data) do
    if not lib.list_contains(names, session.path) then
      data[i] = nil
    end
  end
  return data
end

---@return SessionData[]
local function loadData()
  local file = assert(io.open(dataPath, "r"))
  local content = file:read("*a")
  local data = vim.json.decode(content)
  file:close()
  local sessionData = lib.map(data, function(item)
    return t.SessionData:new(item.fullName, item.path, item.favorite, item.last_opened)
  end)
  return sessionData
end

---@param data SessionData[]
function M.save(data)
  local file = assert(io.open(dataPath, "w"))
  file:write(vim.json.encode(data))
  file:close()
end

---@return SessionData[]
function M.get_sessions()
  local newData = validate_sessions(loadData())
  return newData
end

function M.create_default_data_file()
  local file = assert(io.open(dataPath, "w"))
  file:write("{}")
  file:close()
end

return M
