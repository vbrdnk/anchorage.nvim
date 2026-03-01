-- lua/anchorage/picker.lua
-- Opens a snacks.picker showing the harpoon-like list.
-- Supports: select, delete, reorder (move up/down), open in split/vsplit/tab.

local M = {}

---@param list AnchorageList
function M.open(list)
	local snacks = require("snacks")

	-- ── helpers ───────────────────────────────────────────────────────────────

	local function make_items()
		local out = {}
		for i, item in ipairs(list:items()) do
			table.insert(out, {
				idx = i,
				text = string.format("[%d] %s", i, list.config.default.display(item)),
				value = item.value,
				file = item.value,
				_item = item,
			})
		end
		return out
	end

	local function refresh(picker)
		picker.opts.items = make_items()
		picker:refresh()
	end

	-- ── action helpers ────────────────────────────────────────────────────────

	local function delete_selected(picker)
		local sel = picker:current()
		if not sel then
			return
		end
		list:remove_at(sel.idx)
		refresh(picker)
	end

	local function move_up(picker)
		local sel = picker:current()
		if not sel or sel.idx <= 1 then
			return
		end
		local items = list:items()
		items[sel.idx], items[sel.idx - 1] = items[sel.idx - 1], items[sel.idx]
		list:save()
		refresh(picker)
	end

	local function move_down(picker)
		local sel = picker:current()
		if not sel or sel.idx >= list:length() then
			return
		end
		local items = list:items()
		items[sel.idx], items[sel.idx + 1] = items[sel.idx + 1], items[sel.idx]
		list:save()
		refresh(picker)
	end

	local function open_with(picker, open_opts)
		local sel = picker:current()
		if not sel then
			return
		end
		local item = sel._item
		local main = picker.main
		picker:close()
		vim.schedule(function()
			if main and vim.api.nvim_win_is_valid(main) then
				vim.api.nvim_set_current_win(main)
			end
			list.config.default.select(item, list, open_opts)
		end)
	end

	-- ── picker config ─────────────────────────────────────────────────────────

	-- Internal actions — never overridable
	local actions = {
		confirm = function(picker, _item)
			open_with(picker, {})
		end,
		open_vsplit = function(picker, _)
			open_with(picker, { vsplit = true })
		end,
		open_split = function(picker, _)
			open_with(picker, { split = true })
		end,
		open_tab = function(picker, _)
			open_with(picker, { tabedit = true })
		end,
		delete = delete_selected,
		move_up = move_up,
		move_down = move_down,
	}

	-- Defaults — all overridable via config.picker
	local defaults = {
		_anchorage_list = list.name,
		title = " Anchorage — " .. list.name,
		focus = "list",
		preview = "file",

		format = function(item, _)
			local icon = "󰀱 "
			local badge = string.format(" %d ", item.idx)
			local name = vim.fn.fnamemodify(item.value, ":t")
			local dir = vim.fn.fnamemodify(item.value, ":h")
			if dir == "." then
				dir = ""
			else
				dir = " " .. dir
			end
			return {
				{ icon, "AnchorageIcon" },
				{ badge, "AnchorageBadge" },
				{ name, "AnchorageName" },
				{ dir, "AnchorageDir" },
			}
		end,

		win = {
			list = {
				keys = {
					["<C-v>"] = "open_vsplit",
					["<C-x>"] = "open_split",
					["<C-t>"] = "open_tab",
					["<C-k>"] = "move_up",
					["<C-j>"] = "move_down",
					["dd"] = "delete",
					["q"] = "close",
				},
			},
		},
	}

	-- Merge: user overrides defaults, but internal fields always win
	local picker_opts = vim.tbl_deep_extend("force", defaults, list.config.picker or {}, {
		items = make_items(),
		actions = actions,
		on_close = function()
			if list.config.sync_on_close then
				list:save()
			end
		end,
	})

	snacks.picker(picker_opts)
end

-- ── highlight groups (call once from setup) ───────────────────────────────

function M.setup_highlights()
	vim.api.nvim_set_hl(0, "AnchorageIcon",  { link = "DiagnosticWarn", default = true })
	vim.api.nvim_set_hl(0, "AnchorageBadge", { link = "CurSearch",      default = true })
	vim.api.nvim_set_hl(0, "AnchorageName",  { link = "Normal",         default = true })
	vim.api.nvim_set_hl(0, "AnchorageDir",   { link = "Comment",        default = true })
end

return M
