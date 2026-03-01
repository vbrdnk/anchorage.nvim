-- lua/anchorage/health.lua
-- Run with :checkhealth anchorage

local M = {}

function M.check()
  vim.health.start("anchorage.nvim")

  if rawget(_G, "Snacks") then
    vim.health.ok("snacks.nvim is loaded")
  else
    vim.health.error("snacks.nvim is not loaded", { "Ensure snacks.nvim is listed as a dependency" })
  end

  local anchorage = require("anchorage")
  if anchorage._config then
    vim.health.ok("setup() has been called")
    local data_path = anchorage._config.data_path
    if vim.fn.isdirectory(data_path) == 1 or vim.fn.mkdir(data_path, "p") == 1 then
      vim.health.ok("data directory is writable: " .. data_path)
    else
      vim.health.error("data directory not writable: " .. data_path)
    end
  else
    vim.health.warn("setup() has not been called yet", { "Add lazy = false to your plugin spec" })
  end
end

return M
