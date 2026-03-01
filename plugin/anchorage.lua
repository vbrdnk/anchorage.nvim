-- plugin/anchorage.lua
-- Runs setup() with defaults so the plugin works without any user configuration.
-- Skips auto-setup when lazy.nvim is present — lazy will call setup() with
-- the user's opts via its own mechanism (main module resolution).
if package.loaded["lazy"] then
  return
end
require("anchorage").setup()
