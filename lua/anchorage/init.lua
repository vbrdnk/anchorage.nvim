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

local function apply_keymaps(cfg)
	if cfg.keymaps == false then
		return
	end
	local km = cfg.keymaps
	local function map(lhs, fn, desc)
		if lhs and lhs ~= "" then
			vim.keymap.set("n", lhs, fn, { desc = desc, silent = true })
		end
	end

	map(km.add, function()
		M.list():add()
	end, "Anchorage: add file")
	map(km.toggle, function()
		M.toggle_picker(M.list())
	end, "Anchorage: open picker")
	map(km.select_1, function()
		M.list():select(1)
	end, "Anchorage: jump to slot 1")
	map(km.select_2, function()
		M.list():select(2)
	end, "Anchorage: jump to slot 2")
	map(km.select_3, function()
		M.list():select(3)
	end, "Anchorage: jump to slot 3")
	map(km.select_4, function()
		M.list():select(4)
	end, "Anchorage: jump to slot 4")
	map(km.prev, function()
		M.list():prev()
	end, "Anchorage: prev file")
	map(km.next, function()
		M.list():next()
	end, "Anchorage: next file")

	-- Register which-key group label if which-key is available
	local ok, wk = pcall(require, "which-key")
	if ok then
		local prefix = cfg.keymap_prefix
			or (km.add and km.add ~= "" and km.add:match("^(.+)%a$"))
			or nil
		if prefix then
			wk.add({ { prefix, group = "anchorage", icon = "⚓" } })
		end
	end
end

---@param user_config? table
function M.setup(user_config)
	M._config = Config.merge(user_config)
	M._lists = {}
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

	apply_keymaps(M._config)
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
function M.toggle_picker(list)
	if rawget(_G, "Snacks") then
		for _, p in ipairs(Snacks.picker.get()) do
			if p.opts._anchorage_list == list.name then
				p:close()
				return
			end
		end
	end
	Picker.open(list)
end

return M
