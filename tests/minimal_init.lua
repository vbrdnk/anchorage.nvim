-- tests/minimal_init.lua
-- Minimal Neovim bootstrap for headless plenary/busted test runs.

-- Reset rtp to just $VIMRUNTIME so we start from a clean slate
vim.opt.rtp = { vim.env.VIMRUNTIME }

-- Derive repo root from this file's location
local this_file = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fn.fnamemodify(this_file, ":h:h")
vim.opt.rtp:prepend(repo_root)

-- Add plenary (from env var or default lazy path)
local plenary_path = vim.env.PLENARY_PATH or (vim.fn.expand("~") .. "/.local/share/nvim/lazy/plenary.nvim")
vim.opt.rtp:prepend(plenary_path)

-- Point XDG dirs to a local .tests/ dir so tests never touch real config
local test_dir = repo_root .. "/.tests"
vim.env.XDG_DATA_HOME = test_dir .. "/data"
vim.env.XDG_CONFIG_HOME = test_dir .. "/config"
vim.env.XDG_CACHE_HOME = test_dir .. "/cache"
vim.env.XDG_STATE_HOME = test_dir .. "/state"

-- Disable swap files
vim.o.swapfile = false

-- Disable treesitter for headless runs (no parsers available, avoids noisy errors)
vim.g.loaded_nvim_treesitter = 1

-- Signal to plugin code that we are running under tests
_G.__TEST = true

-- Source plenary's plugin file to register PlenaryBustedDirectory/File commands
vim.cmd("runtime plugin/plenary.vim")

-- Register the plenary busted DSL (describe / it / before_each / etc.)
require("plenary.busted")
