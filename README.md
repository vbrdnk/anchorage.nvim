# ⚓ anchorage.nvim

Harpoon2-compatible file bookmarking with a [`snacks.picker`](https://github.com/folke/snacks.nvim) UI.
The API mirrors harpoon2 so existing muscle memory transfers directly.

## ✨ Features

- **Project-scoped lists** — each working directory gets its own set of anchored files
- **snacks.picker UI** — fuzzy-searchable, with file preview and slot badges
- **Default keymaps** — works out of the box, fully overridable or opt-out
- **snacks.explorer integration** — anchor files directly from the file tree without opening them
- **Named lists** — maintain separate lists (e.g. `"files"`, `"cmds"`) per project
- **Fully customisable picker** — pass any `snacks.picker` option via `opts.picker`

## ⚡️ Requirements

- Neovim >= 0.9
- [snacks.nvim](https://github.com/folke/snacks.nvim)

## 📦 Installation

```lua
-- lazy.nvim
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false,
}
```

That's it. Default keymaps are registered automatically.

## 🚀 Usage

### Picker keymaps

| Key | Action |
|---|---|
| `<CR>` | Open file |
| `<C-v>` | Open in vertical split |
| `<C-x>` | Open in horizontal split |
| `<C-t>` | Open in new tab |
| `<C-j>` / `<C-k>` | Move item down / up |
| `dd` | Remove item from list |

### Default keymaps

| Key | Action |
|---|---|
| `<leader>ha` | Add current file (or hovered file in snacks.explorer) |
| `<leader>he` | Open picker |
| `<leader>h1` – `<leader>h4` | Jump to slot 1–4 |
| `<leader>hp` | Previous anchored file |
| `<leader>hn` | Next anchored file |

### Lua API

```lua
local anchorage = require("anchorage")

-- Add current buffer to the default list
anchorage.list():add()

-- Jump to a specific slot
anchorage.list():select(1)

-- Cycle through anchored files
anchorage.list():next()
anchorage.list():prev()

-- Open the picker for a list
anchorage.toggle_picker(anchorage.list())

-- Named lists — each list is stored independently
anchorage.list("tests"):add()
anchorage.toggle_picker(anchorage.list("tests"))
```

## ⚙️ Configuration

```lua
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false,
  opts = {
    -- Directory where list data is persisted
    -- Default: vim.fn.stdpath("data") .. "/anchorage"
    data_path = vim.fn.stdpath("data") .. "/anchorage",

    -- Storage key per project. Override for git worktree support:
    -- key = function()
    --   return vim.fn.systemlist("git rev-parse --show-toplevel")[1] or vim.loop.cwd()
    -- end,

    -- Persist lists when the picker closes
    -- Default: true
    sync_on_close = true,

    -- Default keymaps. Override individual keys or pass false to disable all.
    keymaps = {
      add      = "<leader>ha",
      toggle   = "<leader>he",
      select_1 = "<leader>h1",
      select_2 = "<leader>h2",
      select_3 = "<leader>h3",
      select_4 = "<leader>h4",
      prev     = "<leader>hp",
      next     = "<leader>hn",
    },

    -- snacks.picker overrides (layout, preview, format, win keys, etc.)
    -- See: https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
    picker = {},
  },
}
```

### Keymap customisation

Override individual keys — unspecified keys keep their defaults:

```lua
opts = {
  keymaps = {
    add    = "<leader>fa",
    toggle = "<leader>fe",
  },
}
```

Disable all built-in keymaps and define your own:

```lua
return {
  "vbrdnk/anchorage.nvim",
  dependencies = { "folke/snacks.nvim" },
  lazy = false,
  opts = { keymaps = false },
  keys = {
    { "<leader>ha", function() require("anchorage").list():add() end,            desc = "Anchorage: add file" },
    { "<leader>he", function() require("anchorage").toggle_picker(require("anchorage").list()) end, desc = "Anchorage: open picker" },
    { "<C-h>",      function() require("anchorage").list():select(1) end,        desc = "Anchorage: slot 1" },
    { "<C-t>",      function() require("anchorage").list():select(2) end,        desc = "Anchorage: slot 2" },
    { "<C-n>",      function() require("anchorage").list():select(3) end,        desc = "Anchorage: slot 3" },
    { "<C-s>",      function() require("anchorage").list():select(4) end,        desc = "Anchorage: slot 4" },
  },
}
```

### Picker customisation

Pass any [`snacks.picker`](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md) option via `opts.picker`.
Anchorage merges it on top of its defaults — only specify what you want to change.

> [!NOTE]
> `items`, `actions`, and `on_close` are always managed internally and cannot be overridden.

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
      list = {
        keys = {
          ["<C-d>"] = "delete",
        },
      },
    },
  },
}
```

## 🌈 Highlight Groups

Override these in your colorscheme to customise the picker appearance:

| Group | Default | Used for |
|---|---|---|
| `AnchorageIcon` | `#e5c07b` bold | Anchor icon |
| `AnchorageBadge` | `#61afef` bg, `#282c34` fg, bold | Slot number badge |
| `AnchorageName` | `#abb2bf` bold | Filename |
| `AnchorageDir` | `#5c6370` italic | Directory path |

```lua
-- Example overrides
vim.api.nvim_set_hl(0, "AnchorageBadge", { fg = "#1e1e2e", bg = "#cba6f7", bold = true })
vim.api.nvim_set_hl(0, "AnchorageDir",   { fg = "#6c7086", italic = true })
```
