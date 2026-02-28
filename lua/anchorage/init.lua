-- lua/anchorage/init.lua
-- Public API surface — intentionally mirrors harpoon2 so muscle memory transfers.

local Config = require("anchorage.config")
local List = require("anchorage.list")
local Picker = require("anchorage.picker")

---@class Anchorage
local M = {
	_config = nil,
	_lists = {},
}

-- ── setup (REQUIRED, like harpoon:setup()) ────────────────────────────────

---@param user_config? table
function M.setup(user_config)
	M._config = Config.merge(user_config)
	Picker.setup_highlights()

	-- Re-apply highlights on colorscheme change
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("anchorage_hl", { clear = true }),
		callback = Picker.setup_highlights,
	})

	-- Persist all lists before quitting
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = vim.api.nvim_create_augroup("anchorage_save", { clear = true }),
		callback = function()
			for _, l in pairs(M._lists) do
				l:save()
			end
		end,
	})
end

-- ── list access (mirrors harpoon:list()) ──────────────────────────────────

---@param name? string  defaults to "files"
---@return AnchorageList
function M.list(name)
	assert(M._config, "[anchorage] call require('anchorage').setup() first")
	name = name or "files"
	if not M._lists[name] then
		M._lists[name] = List.new(name, M._config)
	end
	return M._lists[name]
end

-- ── picker toggle (mirrors harpoon.ui:toggle_quick_menu()) ───────────────

---@param list AnchorageList
---@param opts? table
function M.toggle_picker(list, opts)
	Picker.open(list, opts)
end

return M
