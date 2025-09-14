local asu = function()
  return require("auto-session-ui")
end

---@class Subcommand
---@field impl fun(args:string[], opts: table)
---@field complete? fun(subcmd_arg_lead: string): string[]

---@type table<string, Subcommand>
local subcommand_tbl = {
  pick = {
    impl = function(args, opts)
      asu().pick_session()
    end,
  },
  add = {
    impl = function(args, opts)
      asu().add_current_session()
    end,
  },
  remove = {
    impl = function(args, opts)
      asu().remove_current_session()
    end,
  },
  favorite = {
    impl = function(args, opts)
      asu().favorite_current_session()
    end,
  },
}

---@param opts table
local function asu_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = subcommand_tbl[subcommand_key]
  if not subcommand then
    vim.notify("Auto-session-ui: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

vim.api.nvim_create_user_command("AutosessionUI", asu_cmd, {
  nargs = "+",
  desc = "AutosessionUI commands",
  complete = function(arg_lead, cmdline, _)
    -- Get the subcommand.
    local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*AutosessionUI[!]*%s(%S+)%s(.*)$")
    if subcmd_key and subcmd_arg_lead and subcommand_tbl[subcmd_key] and subcommand_tbl[subcmd_key].complete then
      -- The subcommand has completions. Return them.
      return subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
    end
    -- Check if cmdline is a subcommand
    if cmdline:match("^['<,'>]*AutosessionUI[!]*%s+%w*$") then
      -- Filter subcommands that match
      local subcommand_keys = vim.tbl_keys(subcommand_tbl)
      return vim
        .iter(subcommand_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
    end
  end,
  bang = true, -- If you want to support ! modifiers
})
