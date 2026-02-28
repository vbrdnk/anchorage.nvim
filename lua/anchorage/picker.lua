-- lua/anchorage/picker.lua
-- Opens a snacks.picker showing the harpoon-like list.
-- Supports: select, delete, reorder (move up/down), open in split/vsplit/tab.

local M = {}

---@param list AnchorageList
---@param opts? table
function M.open(list, opts)
	opts = opts or {}

	local snacks = require("snacks")

	-- ── helpers ───────────────────────────────────────────────────────────────

	local function make_items()
		local out = {}
		for i, item in ipairs(list:items()) do
			table.insert(out, {
				idx = i,
				text = string.format("[%d] %s", i, list.config.default.display(item)),
				value = item.value,
				_item = item,
			})
		end
		return out
	end

	local function refresh(picker)
		picker:find({ items = make_items() })
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
		picker:close()
		list.config.default.select(sel._item, list, open_opts)
	end

	-- ── picker config ─────────────────────────────────────────────────────────

	snacks.picker({
		title = " Anchorage — " .. list.name,

		-- static item source (we refresh manually after mutations)
		items = make_items(),

		-- columns shown in the list
		format = function(item, _)
			-- icon + index badge + filename + optional row hint
			local icon = "󰀱 "
			local badge = string.format(" %d ", item.idx)
			local name = vim.fn.fnamemodify(item.value, ":t")
			local dir = vim.fn.fnamemodify(item.value, ":h")
			if dir == "." then
				dir = ""
			else
				dir = " " .. dir
			end

			-- Use snacks text spans for colour
			return {
				{ icon, "AnchorageIcon" },
				{ badge, "AnchorageBadge" },
				{ name, "AnchorageName" },
				{ dir, "AnchorageDir" },
			}
		end,

		-- Live preview using snacks built-in file preview
		preview = "file",

		-- Key mappings inside the picker
		actions = {
			-- default confirm → open file
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
		},

		win = {
			-- Main list window
			list = {
				keys = {
					["<CR>"] = "confirm",
					["<C-v>"] = "open_vsplit",
					["<C-x>"] = "open_split",
					["<C-t>"] = "open_tab",
					["dd"] = "delete",
					["<C-k>"] = "move_up",
					["<C-j>"] = "move_down",
					["q"] = "close",
					["<Esc>"] = "close",
				},
			},
		},

		on_close = function()
			if list.config.sync_on_close then
				list:save()
			end
		end,
	})
end

-- ── highlight groups (call once from setup) ───────────────────────────────

function M.setup_highlights()
	vim.api.nvim_set_hl(0, "AnchorageIcon", { fg = "#e5c07b", bold = true })
	vim.api.nvim_set_hl(0, "AnchorageBadge", { fg = "#282c34", bg = "#61afef", bold = true })
	vim.api.nvim_set_hl(0, "AnchorageName", { fg = "#abb2bf", bold = true })
	vim.api.nvim_set_hl(0, "AnchorageDir", { fg = "#5c6370", italic = true })
end

return M
