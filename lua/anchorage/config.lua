-- lua/anchorage/config.lua
local M = {}

M.defaults = {
	data_path = vim.fn.stdpath("data") .. "/anchorage",

	keymaps = {
		add = "<leader>ha",
		toggle = "<leader>he",
		select_1 = "<leader>h1",
		select_2 = "<leader>h2",
		select_3 = "<leader>h3",
		select_4 = "<leader>h4",
		prev = "<leader>hp",
		next = "<leader>hn",
	},

	key = function()
		return vim.loop.cwd()
	end,

	sync_on_close = true,

	picker = {},

	default = {
		select_with_nil = false,

		create_list_item = function(_, item)
			if item then
				return { value = item, context = {} }
			end
			-- When invoked from snacks.explorer, grab the focused node's path
			if vim.bo.filetype == "snacks_picker_list" then
				local pickers = Snacks.picker.get({ source = "explorer" })
				local explorer = pickers[#pickers]
				if explorer then
					local node = explorer:current()
					if node and node.file and vim.fn.isdirectory(node.file) == 0 then
						return {
							value = vim.fn.fnamemodify(node.file, ":~:."),
							context = {},
						}
					end
				end
				return nil
			end
			local bufname = vim.api.nvim_buf_get_name(0)
			if bufname == "" then
				return nil
			end
			return {
				value = vim.fn.fnamemodify(bufname, ":~:."),
				context = { row = vim.fn.line("."), col = vim.fn.col(".") },
			}
		end,

		display = function(item)
			return item.value
		end,

		select = function(item, _, opts)
			if not item then
				return
			end
			opts = opts or {}
			local cmd = opts.vsplit and "vsplit" or opts.split and "split" or opts.tabedit and "tabedit" or "edit"
			vim.cmd(cmd .. " " .. vim.fn.fnameescape(item.value))
			if item.context and item.context.row then
				pcall(vim.api.nvim_win_set_cursor, 0, { item.context.row, item.context.col or 0 })
			end
		end,

		equals = function(a, b)
			return a.value == b.value
		end,

		encode = vim.json.encode,
		decode = vim.json.decode,
	},
}

function M.merge(user)
	user = user or {}
	local merged = vim.tbl_deep_extend("force", M.defaults, user)
	if user.keymaps == false then
		merged.keymaps = false
	end
	return merged
end

return M
