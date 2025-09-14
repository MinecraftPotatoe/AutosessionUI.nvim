local M = {}

---@class SessionData
---@field fullName string
---@field path string
---@field favorite boolean
---@field last_opened number
M.SessionData = {}

--- Returns all folders
function M.SessionData:getFullFolderName()
  return self.fullName:sub(1, self.fullName:findLast("/") - 1)
end
--- Only returns the outermost foldr
function M.SessionData:getFolderName()
  return self.fullName:sub(1, self.fullName:find("/") - 1)
end
function M.SessionData:getSubName()
  return self.fullName:sub(self.fullName:find("/") + 1)
end

---@param fullName string
---@param path string
---@param favorite boolean
---@param last_opened number
---@return SessionData
function M.SessionData:new(fullName, path, favorite, last_opened)
  local o = {
    fullName = fullName,
    path = path,
    favorite = favorite,
    last_opened = last_opened,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M.SessionData:isFolder()
  return self.fullName:find("/")
end

---@alias SessionTree SessionTreeItem[]
---@alias SessionTreeItem Session|Folder

---@class Session
---@field name string
---@field path string
---@field favorite boolean
---@field last_opened number
---@field format_item? fun(): string
M.Session = {}

---@param name string
---@param path string
---@param favorite boolean
---@param last_opened number
---@return Session
function M.Session:new(name, path, favorite, last_opened)
  local o = {
    name = name,
    path = path,
    favorite = favorite,
    last_opened = last_opened,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function M.Session:isCurrentSession()
  return self.path == vim.fn.getcwd()
end

function M.SessionData:convert()
  return M.Session:new(self.fullName, self.path, self.favorite, self.last_opened)
end

---@class Folder
---@field name string
---@field content SessionTree
---@field format_item? fun(): string
M.Folder = {}

---@param name string
---@param content SessionTree
---@return Folder
function M.Folder:new(name, content)
  local o = {
    name = name,
    content = content,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

---@alias IntermediateSessionTree IntermediateSessionTreeItem[]
---@alias IntermediateSessionTreeItem Session|IntermediateFolder

---@class IntermediateFolder
---@field name string
---@field content SessionData[]
M.IntermediateFolder = {}

---@param name string
---@param content SessionData[]
---@return IntermediateFolder
function M.IntermediateFolder:new(name, content)
  local o = {
    name = name,
    content = content,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

return M
