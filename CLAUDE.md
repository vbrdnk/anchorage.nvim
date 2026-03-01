# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Anchorage** is a Neovim plugin written in Lua. It provides file bookmarking heavily inspired by harpoon2, with a `snacks.picker`-powered UI.

**Runtime dependency**: [`snacks.nvim`](https://github.com/folke/snacks.nvim) — the picker is built entirely on `snacks.picker`.

## Architecture

The plugin is structured as four modules under `lua/anchorage/`:

| Module       | Role                                                                                                                                                                                                                 |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `init.lua`   | Public API. Entry point. Holds global `_config` and `_lists` state. Registers autocmds for highlight refresh on colorscheme change and persistence on `VimLeavePre`.                                                 |
| `config.lua` | Default config table + `merge()`. All user-facing options live here. The `default` subtable holds per-list hooks: `create_list_item`, `display`, `select`, `equals`, `encode`, `decode`.                             |
| `list.lua`   | `AnchorageList` class (metatables). Manages an ordered item array with JSON persistence per `(cwd_key, list_name)`. Key operations: `add`, `prepend`, `remove`, `remove_at`, `select`, `next`, `prev`, `save`.       |
| `picker.lua` | Thin wrapper around `snacks.picker`. Builds formatted item spans (icon, badge, name, dir), registers actions (confirm, open_vsplit, open_split, open_tab, delete, move_up, move_down), and sets up highlight groups. |

### Data flow

```
User keymap
  → M.list("files"):add()          -- list.lua: appends item, saves JSON
  → M.toggle_picker(list)           -- picker.lua: opens snacks.picker
      → picker action (delete/move) -- mutates list._items, calls list:save(), refreshes picker
```

### Persistence

Lists are saved as JSON files at:

```
{data_path}/{cwd_key}__{list_name}.json
```

where `cwd_key` is the sanitized CWD (`vim.loop.cwd()`), and `data_path` defaults to `vim.fn.stdpath("data") .. "/anchorage"`.

## Conventions

- **Module pattern**: each file returns a local table `M`; `list.lua` uses `M.__index = M` for OOP via `setmetatable`.
- **Config hooks**: behavior is customizable through function fields in `config.default` (`create_list_item`, `display`, `select`, `equals`). New list behaviors should follow this pattern — override via config, not hardcoded logic.
- **No external test framework**: there is currently no test harness. Manual testing is done inside Neovim.
- **Highlight groups**: defined once in `Picker.setup_highlights()` and reapplied on `ColorScheme` autocmd. Colors are hardcoded to match One Dark palette.
- **Picker state**: the picker does not hold canonical state — `list._items` is the source of truth. Picker refreshes by calling `picker:find({ items = make_items() })` after mutations.
