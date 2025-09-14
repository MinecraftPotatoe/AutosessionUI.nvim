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
local function setup_picker(session_tree, on_choice)
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
        ---@type Picker
        local picker = action_state.get_current_picker(prompt_bufnr)
        local row = picker:get_selection_row()
        picker:refresh(create_finder(session_tree), {})
        vim.defer_fn(function()
          picker:set_selection(row)
        end, 10)
      end

      local function do_default()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        on_choice(selection.value)
      end

      local function favorite_session_map()
        local selection = action_state.get_selected_entry()
        if not core.is_folder(selection.value) then
          core.favorite_session(selection.value.path)
          selection.value.favorite = not selection.value.favorite
          update()
        end
      end

      local function remove_session_map()
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

      -- override <CR>
      actions.select_default:replace(do_default)

      -- custom keymaps
      map("i", "<C-f>", favorite_session_map) -- split in insert mode
      map("n", "<C-f>", favorite_session_map) -- split in normal mode
      map("i", "<C-d>", remove_session_map)
      map("n", "<C-d>", remove_session_map)

      return true
    end,
  })
  picker:find()
  return picker
end

---@param session_tree SessionTree|nil
---@param is_root_tree boolean
function M.pick_session_with_tree(session_tree, is_root_tree)
  if session_tree == nil then
    session_tree = trees.build_tree(api.get_sessions())
  end

  trees.sort_session_tree_alphabetically(session_tree)
  if is_root_tree then
    trees.add_special_sessions(session_tree)
  end

  ---@param choice SessionTreeItem|nil
  local function on_choice(choice)
    if choice == nil then
      return
    elseif core.is_folder(choice) then
      M.pick_session_with_tree(choice.content, false)
    else
      core.open_session(choice.path)
    end
  end

  if use_telescope then
    setup_picker(session_tree, on_choice)
  else
    vim.ui.select(session_tree, { prompt = "Select Session", format_item = format_tree_item }, on_choice)
  end
end

---@param opts opts
function M.setup(opts)
  use_telescope = opts.use_telescope_picker
end

return M
