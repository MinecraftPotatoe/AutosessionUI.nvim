local M = {}

local core = require("auto-session-ui.core")
local api = require("auto-session-ui.api")
local lib = require("auto-session-ui.lib")
local trees = require("auto-session-ui.trees")
require("auto-session-ui.types")

local use_telescope = true

---@param item SessionTreeItem
---@return string
local function format_tree_item(item)
  if item.format_item ~= nil then
    return item.format_item()
  elseif core.is_folder(item) then
    return " " .. item.name
  elseif item.favorite then
    return item.name .. " ( )"
  else
    return item.name
  end
end

---@param session_tree SessionTree?
---@param is_root_tree boolean
---@param path string? path to a folder in the tree
---@return SessionTree
local function prepare_picker_tree(session_tree, is_root_tree, path)
  if session_tree == nil then
    session_tree = trees.get_tree(path)
    if session_tree == nil then
      vim.notify("Could not find folder with path " .. path, vim.log.levels.ERROR)
      error("Could not find folder with path " .. path)
    end
  end

  trees.sort_session_tree_alphabetically(session_tree)
  if is_root_tree then
    trees.add_special_sessions(session_tree)
  end

  return session_tree
end

local function create_finder(session_tree)
  local finders = require("telescope.finders")

  return finders.new_table({
    results = session_tree,
    entry_maker = function(entry)
      return {
        value = entry,
        display = format_tree_item(entry),
        ordinal = format_tree_item(entry),
      }
    end,
  })
end
---@param on_choice fun(choice: SessionTreeItem|nil): nil
---@param session_tree SessionTree
---@param path string?
local function setup_picker(session_tree, on_choice, path)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values

  local picker = pickers.new({}, {
    prompt_title = "Select session",
    finder = create_finder(session_tree),
    sorter = conf.generic_sorter({}),
    layout_strategy = "center",
    sorting_strategy = "ascending",
    layout_config = {
      -- prompt_position = "bottom",
      width = 0.4, -- 40% of screen width
      height = 0.3, -- 30% of screen height
    },
    attach_mappings = function(prompt_bufnr, map)
      local function update()
        ---@diagnostic disable-next-line: undefined-doc-name
        ---@type Picker
        local picker = action_state.get_current_picker(prompt_bufnr)
        ---@diagnostic disable-next-line: undefined-field
        local row = picker:get_selection_row()
        ---@diagnostic disable-next-line: undefined-field
        picker:refresh(create_finder(prepare_picker_tree(nil, path == "" or path == nil, path)), {})
        vim.defer_fn(function()
          ---@diagnostic disable-next-line: undefined-field
          picker:set_selection(row)
        end, 10)
      end

      local function default_action()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        on_choice(selection.value)
      end

      local function favorite_session_action()
        local selection = action_state.get_selected_entry()
        if not core.is_folder(selection.value) then
          core.favorite_session(selection.value.path)
          selection.value.favorite = not selection.value.favorite
          update()
        end
      end

      local function remove_session_action()
        local selection = action_state.get_selected_entry()
        if not core.is_folder(selection.value) then
          local conformation = vim.fn.confirm("Delete session: " .. selection.value.name, "Yes")
          if conformation == 0 then
            return
          end
          core.remove_session(selection.value.path)
          table.remove(session_tree, lib.indexOf(session_tree, selection.value))
          update()
        end
      end

      local function rename_session_map()
        local selection = action_state.get_selected_entry()
        if not core.is_folder(selection.value) then
          M.add_rename_session(selection.value)
          update()
        end
      end

      local function go_back_action()
        if path == nil or path == "" then
          return
        end

        local new_path = core.getFullFolderName(path)
        local new_is_root_tree = new_path == ""
        M.pick_session_with_tree(nil, new_is_root_tree, new_path)
      end

      -- override <CR>
      actions.select_default:replace(default_action)

      -- custom keymaps
      map("i", "<C-f>", favorite_session_action) -- split in insert mode
      map("n", "<C-f>", favorite_session_action) -- split in normal mode
      map("i", "<C-d>", remove_session_action)
      map("n", "<C-d>", remove_session_action)
      map("i", "<C-b>", go_back_action)
      map("n", "<C-b>", go_back_action)

      return true
    end,
  })
  picker:find()
  return picker
end

---@param session_tree SessionTree?
---@param is_root_tree boolean
---@param path string? path to a folder in the tree
function M.pick_session_with_tree(session_tree, is_root_tree, path)
  session_tree = prepare_picker_tree(session_tree, is_root_tree, path)

  if #session_tree == 0 then
    vim.notify("You currently have no sessions added. Use the ':AutosessionUI add' command to add your first session")
    return
  end

  ---@param choice SessionTreeItem|nil
  local function on_choice(choice)
    if choice == nil then
      return
    elseif core.is_folder(choice) then
      M.pick_session_with_tree(choice.content, false, (path or "") .. "/" .. choice.name)
    else
      core.open_session(choice.path)
    end
  end

  if use_telescope then
    setup_picker(session_tree, on_choice, path)
  else
    vim.ui.select(session_tree, { prompt = "Select Session", format_item = format_tree_item }, on_choice)
  end
end

---@param opts auto-session-ui.opts
function M.setup(opts)
  use_telescope = opts.use_telescope_picker
end

return M
