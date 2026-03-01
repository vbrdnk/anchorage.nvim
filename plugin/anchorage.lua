-- plugin/anchorage.lua
-- Runs setup() with defaults so the plugin works without any user configuration.
-- If the user calls setup() explicitly (e.g. via opts/config in their plugin manager),
-- that call will simply overwrite this one — no double-init issues.
require("anchorage").setup()
