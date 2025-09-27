local M = {}

local lib = require("auto-session-ui.lib")
local t = require("auto-session-ui.types")
local api = require("auto-session-ui.api")

---@param item SessionTreeItem|IntermediateSessionTreeItem
---@return boolean
function M.is_folder(item)
  return item.content ~= nil
end

--- Returns all folders
--- @param name string
function M.getFullFolderName(name)
  return name:sub(1, name:findLast("/") - 1)
end
--- Only returns the outermost folder
--- @param name string
function M.getFolderName(name)
  return name:sub(1, name:find("/") - 1)
end
--- @param name string
function M.getSubName(name)
  return name:sub(name:find("/") + 1)
end

---@param path string
---@param list SessionData[]
---@return number | nil
function M.getSessionIndex(path, list)
  return lib.lsearchIndex(list, function(item)
    return item.path == path
  end)
end

---@param name string
---@param tree SessionTree|IntermediateSessionTree
---@return Folder | IntermediateFolder | nil
function M.getFolder(name, tree)
  return lib.lsearch(tree, function(item)
    return M.is_folder(item) and item.name == name
  end) --[[@as Folder | IntermediateFolder | nil]]
end

---@param path string
---@param displayName string
function M.add_session(path, displayName)
  local sessions = api.get_sessions()
  table.insert(sessions, t.SessionData:new(displayName, path, false, 0))
  api.save(sessions)
  M.update_last_opened(path)
end

---@param path string
---@return boolean?
function M.add_rename_session(path, keep_folder)
  local prefix = ""
  local session = M.get_session(path)
  if keep_folder and session then
    prefix = session:getFullFolderName() .. "/"
  end

  M.remove_session(path)
  vim.ui.input({ prompt = "Choose name:" }, function(displayName)
    if displayName == nil then
      return
    end
    M.add_session(path, prefix .. displayName)
  end)
end

---@param path string
---@return SessionData | nil
function M.get_session(path)
  local sessions = api.get_sessions()
  local index = M.getSessionIndex(path, sessions)
  if index == nil then
    return nil
  end
  return sessions[index]
end

function M.remove_session(path)
  local sessions = api.get_sessions()
  local index = M.getSessionIndex(path, sessions)
  if index == nil then
    return
  end
  table.remove(sessions, index)
  api.save(sessions)
end

---@param path string
function M.open_session(path)
  M.update_last_opened(path)
  api.restore_session(path)
end

---------- Extended functionality ----------

function M.favorite_session(path)
  local sessions = api.get_sessions()
  local index = M.getSessionIndex(path, sessions)
  if index == nil then
    return
  end
  sessions[index].favorite = not sessions[index].favorite
  api.save(sessions)
end

---@param path string
function M.update_last_opened(path)
  local sessions = api.get_sessions()
  local index = M.getSessionIndex(path, sessions)
  if index == nil or sessions[index] == nil then
    vim.notify("Could not find session: " .. path, vim.log.levels.ERROR)
    return
  end
  sessions[index].last_opened = os.time()
  api.save(sessions)
end

return M
