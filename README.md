# anchorage.nvim

Harpoon2-compatible file bookmarking with a [`snacks.picker`](https://github.com/folke/snacks.nvim) UI.

**Runtime dependency**: [`snacks.nvim`](https://github.com/folke/snacks.nvim)

---

## Installation

```lua
-- lazy.nvim
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false,
}
```

That's it. Default keymaps are registered automatically.

---

## Default keymaps

| Key | Action |
|---|---|
| `<leader>ha` | Add current file |
| `<leader>he` | Open picker |
| `<leader>h1` – `<leader>h4` | Jump to slot 1–4 |
| `<leader>hp` | Previous file |
| `<leader>hn` | Next file |

---

## Customisation

Override any keymap, or pass `keymaps = false` to disable all defaults and define your own.

```lua
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    -- Override individual keys (others keep their defaults)
    keymaps = {
      add    = "<leader>fa",
      toggle = "<leader>fe",
    },

    -- Or disable built-in keymaps entirely:
    -- keymaps = false,
  },
}
```

### Manual keymaps (when `keymaps = false`)

```lua
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = { keymaps = false },
  keys = {
    { "<C-h>", function() require("anchorage").list():select(1) end, desc = "Anchorage: slot 1" },
    { "<C-t>", function() require("anchorage").list():select(2) end, desc = "Anchorage: slot 2" },
    { "<C-n>", function() require("anchorage").list():select(3) end, desc = "Anchorage: slot 3" },
    { "<C-s>", function() require("anchorage").list():select(4) end, desc = "Anchorage: slot 4" },
    { "<leader>ha", function() require("anchorage").list():add() end, desc = "Anchorage: add" },
    { "<leader>he", function() require("anchorage").toggle_picker(require("anchorage").list()) end, desc = "Anchorage: picker" },
  },
}
```

### Picker customisation

Pass a `picker` table to override any [snacks.picker](https://github.com/folke/snacks.nvim) option. Anchorage merges it on top of its defaults, so you only need to specify what you want to change.

```lua
opts = {
  picker = {
    -- Change the title
    title = "My Files",

    -- Use a different layout preset
    layout = { preset = "telescope" },

    -- Disable the file preview
    preview = false,

    -- Add or remap keys (merged with built-in keys)
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "delete", mode = { "i", "n" } },
        },
      },
    },
  },
}
```

> **Note**: `items`, `actions`, and `on_close` are always managed internally and cannot be overridden.

### Other options

```lua
opts = {
  -- Where list data is stored
  data_path = vim.fn.stdpath("data") .. "/anchorage",

  -- Storage key — override for git worktree support
  key = function()
    return vim.fn.systemlist("git rev-parse --show-toplevel")[1] or vim.loop.cwd()
  end,

  -- Persist lists when Neovim exits
  sync_on_close = true,
}
```

---

## Named lists

```lua
-- e.g. a separate list for terminal commands
require("anchorage").list("cmds"):add()
```
