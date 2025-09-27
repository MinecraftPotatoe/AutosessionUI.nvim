local M = {}

function string.findLast(haystack, needle)
  local i = haystack:match(".*" .. needle .. "()")
  if i == nil then
    return nil
  else
    return i - 1
  end
end

function M.split(str, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for s in string.gmatch(str, "([^" .. sep .. "]+)") do
    table.insert(t, s)
  end
  return t
end

---Apply a function to all values in a table
---@param tbl table The table to map over
---@param f fun(value: any): any The function to apply to each value
---@return table t A new table with mapped values
function M.map(tbl, f)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = f(v)
  end
  return t
end

---Create a function from a string
---@param s string The string to create the function from
---@return function fn The created function
function M.fn(s, ...)
  local src = [[
    local l1, l2, l3, l4, l5, l6, l7, l8, l9 = ...
    return function(p1,p2,p3,p4,p5,p6,p7,p8,p9) return ]] .. s .. [[ end
  ]]
  return loadstring(src)(...)
end

---Check if a list contains a given value
---@param list table The list to check
---@param val any The value to check for
---@return boolean
function M.list_contains(list, val)
  for i = 1, #list do
    if list[i] == val then
      return true
    end
  end
  return false
end

--- Search first element matching predicate and return index
--- @generic T
--- @param list T[] The list to check
--- @param predicate fun(T): boolean The predicate to check against
--- @return number | nil
function M.lsearchIndex(list, predicate)
  for index, item in ipairs(list) do
    if predicate(item) then
      return index
    end
  end
  return nil
end

--- Search first element matching predicate
--- @generic T
--- @param list T[] The list to check
--- @param predicate fun(item: T): boolean The predicate to check against
--- @return T | nil
function M.lsearch(list, predicate)
  for _, item in ipairs(list) do
    if predicate(item) then
      return item
    end
  end
  return nil
end

---@param name string
function M.file_exists(name)
  local f = io.open(name, "r")
  return f ~= nil and io.close(f)
end

---Find the index of an object in a table
---@param t table The table to search in
---@param object any The value to search for
---@return number|nil index The index of the object if found, nil otherwise
function M.indexOf(t, object)
  if type(t) ~= "table" then
    error("table expected, got " .. type(t), 2)
  end

  for i, v in pairs(t) do
    if object == v then
      return i
    end
  end
end

return M
