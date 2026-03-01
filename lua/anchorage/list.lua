-- lua/anchorage/list.lua
-- Manages a named ordered list of items, with persistence.

local M = {}
M.__index = M

--- Create or load a list.
--- @param name string
--- @param config table  merged anchorage config
function M.new(name, config)
	local self = setmetatable({}, M)
	self.name = name
	self.config = config
	self._items = {}
	self:_load()
	return self
end

-- ── persistence ────────────────────────────────────────────────────────────

function M:_path()
	local key = self.config.key():gsub("[/\\%s]", "_"):gsub("[^%w_%-]", "")
	local dir = self.config.data_path
	vim.fn.mkdir(dir, "p")
	return dir .. "/" .. key .. "__" .. self.name .. ".json"
end

function M:_load()
	local path = self:_path()
	if vim.fn.filereadable(path) == 0 then return end
	local lines = vim.fn.readfile(path)
	local ok, data = pcall(self.config.default.decode, table.concat(lines, "\n"))
	if ok and type(data) == "table" then
		self._items = data
	end
end

function M:save()
	local path = self:_path()
	vim.fn.writefile({ self.config.default.encode(self._items) }, path)
end

-- ── item operations ─────────────────────────────────────────────────────────

function M:items()
	return self._items
end

function M:length()
	return #self._items
end

--- Add current buffer (or a provided value) to the list.
function M:add(item)
	local cfg = self.config.default
	local new_item = cfg.create_list_item(cfg, item)
	if not new_item then
		return
	end

	-- avoid duplicates
	for _, existing in ipairs(self._items) do
		if cfg.equals(existing, new_item) then
			return
		end
	end

	table.insert(self._items, new_item)
	self:save()
end

function M:prepend(item)
	local cfg = self.config.default
	local new_item = cfg.create_list_item(cfg, item)
	if not new_item then
		return
	end
	for _, existing in ipairs(self._items) do
		if cfg.equals(existing, new_item) then
			return
		end
	end
	table.insert(self._items, 1, new_item)
	self:save()
end

--- Remove by index (1-based).
function M:remove_at(idx)
	table.remove(self._items, idx)
	self:save()
end

--- Remove by value equality.
function M:remove(item)
	local cfg = self.config.default
	for i, existing in ipairs(self._items) do
		if cfg.equals(existing, item) then
			table.remove(self._items, i)
			self:save()
			return
		end
	end
end

--- Select item at 1-based index.
function M:select(idx, opts)
	local item = self._items[idx]
	if not item and not self.config.default.select_with_nil then
		return
	end
	self.config.default.select(item, self, opts)
end

function M:next()
	local cur = vim.api.nvim_buf_get_name(0)
	local rel = vim.fn.fnamemodify(cur, ":~:.")
	for i, item in ipairs(self._items) do
		if item.value == rel then
			local nxt = self._items[i % #self._items + 1]
			self.config.default.select(nxt, self, {})
			return
		end
	end
	-- not in list → jump to first
	if self._items[1] then
		self.config.default.select(self._items[1], self, {})
	end
end

function M:prev()
	local cur = vim.api.nvim_buf_get_name(0)
	local rel = vim.fn.fnamemodify(cur, ":~:.")
	for i, item in ipairs(self._items) do
		if item.value == rel then
			local prv = self._items[((i - 2) % #self._items) + 1]
			self.config.default.select(prv, self, {})
			return
		end
	end
	if self._items[#self._items] then
		self.config.default.select(self._items[#self._items], self, {})
	end
end

return M
