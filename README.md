# AutoSession UI

Name, sort and pick sessions made with the [auto-session](https://github.com/rmagatti/auto-session) plugin.

![Preview](https://imgur.com/a/jJATd5Q.gif)

(This plugin is not affiliated with the author of the original [auto-session](https://github.com/rmagatti/auto-session) plugin in any way. It's just a UI script I wrote for myself when using the original plugin)

## 🛠️ Features

- 🖋️ Name your sessions
- 📁 Organize your sessions in folders
- 🌟 Mark your favorite sessions for quick access
- 🕓 Start where you left off

## 📦 Installation

[Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "MinecraftPotatoe/auto-session-ui",
  ---@type auto-session-ui.opts
  opts = {
  },
  init = function()
    -- This is an example how your config could look like
    -- Set your keybindings here
    local wk = require("which-key")
    wk.add({
      { "<leader>s", group = "Sessions", icon = "" },
      { "<leader>sp", desc = "Pick session", callback = ":AutosessionUI pick<CR>" },
      { "<leader>sa", desc = "Add/Rename session", callback = ":AutosessionUI add<CR>" },
      { "<leader>sr", desc = "Remove session", callback = ":AutosessionUI remove<CR>" },
      { "<leader>sf", desc = "Toggle current session as favorite", callback = ":AutosessionUI favorite<CR>" },
    })
  end,
  dependencies = {
    "rmagatti/auto-session"
    "nvim-telescope/telescope.nvim", -- for using the telescope picker
  }
}
```

If you are using lazy.nvim's config function or another package manager, 🚨 MAKE SURE `require("auto-session-ui).setup({})` IS CALLED 🚨

## ⚙️ Configuration

Default settings (you don't have to copy these into your config):

<!-- config:start -->

```lua
local defaults = {
  use_telescope_picker = true,
}

```

<!-- config:end -->

The telescope_picker has some more features, like using
`<C-f>` to favorite a session, or
`<C-d>` to delete a session from in the picker.

But at the moment the picker is not updating the displayed sessions correctly when using the shortcuts, so you might need to close and open it again. It's also a bit slower than the other version, so just set `use_telescope_picker` to false if it annoys you.

## 🎉 Usage

Use the user commands or the lua functions of `require("auto-session-ui)`.
When naming a new session or renaming it, you can use slasher `/` to separate them into folders.

E.g. naming a session `a/b/c` would create a folder `a` with a folder `b` with a session `c`

## 🔜 Planned features

- 🔍 Search for a session name through all sessions
- 📁 Rename and move folders
- 🗺️ Better navigation using the telescope picker
- 🗃️ Options for sorting (alphabetical, recent, etc.)

## 📢 Commands

```viml
:AutosessionUI pick " Opens the picker
:AutosessionUI add " Asks for a name and saves the current session
:AutosessionUI remove " Removes the session from the session picker list
:AutosessionUI favorite " Toggles the current session as favorite
```
