-- plugin/anchorage.lua
-- Runs setup() with defaults so the plugin works without any user configuration.
-- Deferred so that lazy.nvim (or any other plugin manager) has a chance to call
-- setup() with the user's opts first. If setup() was already called, this is a no-op.
if package.loaded["lazy"] then
  return
end
vim.defer_fn(function()
  if not require("anchorage")._config then
    require("anchorage").setup()
  end
end, 0)
