local M = {}

local lib = require("auto-session-ui.lib")
local t = require("auto-session-ui.types")
local api = require("auto-session-ui.api")
local core = require("auto-session-ui.core")

---@param sessions SessionData[]
---@return SessionTree
function M.build_tree(sessions)
  ---@type IntermediateSessionTree
  local tree = {}
  for _, session in pairs(sessions) do
    if session:isFolder() then
      ---@type IntermediateFolder | nil
      local folder = core.getFolder(session:getFolderName(), tree) --[[@as IntermediateFolder | nil]]

      -- Take folder name away, so we don't end up in a loop
      local folderName = session:getFolderName()
      session.fullName = session:getSubName()

      if folder == nil then
        ---@type IntermediateFolder
        local newFolder = t.IntermediateFolder:new(folderName, { session })
        table.insert(tree, newFolder)
      else
        table.insert(folder.content, session)
      end
    else
      ---@type Session
      local newSession = session:convert()
      table.insert(tree, newSession)
    end
  end

  ---@type SessionTree
  local convertedTree = lib.map(tree, function(item)
    if core.is_folder(item) then
      return t.Folder:new(item.name, M.build_tree(item.content))
    else
      return item
    end
  end)
  return convertedTree
end

---@param path string? path of a folder in the tree
---@return SessionTree|nil
function M.get_tree(path)
  local tree = M.build_tree(api.get_sessions())

  if path == nil then
    return tree
  end

  for _, item in pairs(lib.split(path, "/")) do
    local matching_folder = lib.lsearch(tree, function(folder)
      return folder.name == item and core.is_folder(folder)
    end)

    if matching_folder == nil then
      return nil
    else
      tree = matching_folder.content
    end
  end
  return tree
end

---@param session_tree SessionTree
function M.sort_session_tree_alphabetically(session_tree)
  -- sort by folder/session and then by name
  ---@param a SessionTreeItem
  ---@param b SessionTreeItem
  local function comp(a, b)
    local a_folder = core.is_folder(a)
    local b_folder = core.is_folder(b)
    if a_folder == b_folder then
      -- Order by name
      return a.name < b.name
    else
      -- Return the folder, so its higher in the list
      return a_folder
    end
  end

  table.sort(session_tree, comp)
end

---@param sessions SessionData[]
---@return Session
local function get_last_session(sessions)
  -- Sort by last opened
  table.sort(sessions, function(a, b)
    return a.last_opened > b.last_opened
  end)
  -- If we are already in the latest session, show the second latest
  local latest = sessions[1]:convert()
  if latest:isCurrentSession() then
    latest = sessions[2]:convert()
  end

  latest.format_item = function()
    return " " .. latest.name
  end

  return latest
end

---@param session_tree SessionTree
function M.add_special_sessions(session_tree)
  local all_sessions = api.get_sessions()

  -- Add favorite sessions
  for _, session in pairs(all_sessions) do
    if session.favorite then
      local convertedSession = session:convert()
      table.insert(session_tree, 1, convertedSession)
      convertedSession.format_item = function()
        return " " .. convertedSession.name
      end
    end
  end

  local last_session = get_last_session(all_sessions)
  table.insert(session_tree, 1, last_session)
end

return M
