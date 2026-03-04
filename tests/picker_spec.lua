-- tests/picker_spec.lua
-- Picker actions via snacks mock

local H = require("tests.helpers")

describe("anchorage.picker", function()
  -- ── snacks mock ─────────────────────────────────────────────────────────────

  local snacks_call

  local function install_snacks_mock()
    snacks_call = nil
    package.loaded["snacks"] = {
      picker = function(opts)
        snacks_call = opts
      end,
    }
    _G.Snacks = package.loaded["snacks"]
  end

  local function remove_snacks_mock()
    package.loaded["snacks"] = nil
    _G.Snacks = nil
  end

  --- Minimal mock picker returned when actions need a picker object.
  ---@param items table
  ---@param current_idx? number  defaults to 1
  local function make_mock_picker(items, current_idx)
    current_idx = current_idx or 1
    return {
      opts = { items = items },
      current = function(self)
        return self.opts.items[current_idx]
      end,
      refresh = function(_self) end,
      close = function(self)
        self._closed = true
      end,
      main = nil,
    }
  end

  -- ── shared state ─────────────────────────────────────────────────────────────

  local List, Picker, cfg, stubs

  before_each(function()
    stubs = {}
    stubs.filereadable = H.stub_filereadable(0)
    stubs.writefile = H.stub_writefile()
    stubs.readfile = H.stub_readfile({})
    stubs.mkdir = H.stub_mkdir()
    stubs.notify = H.suppress_notify()

    install_snacks_mock()

    package.loaded["anchorage.list"] = nil
    package.loaded["anchorage.picker"] = nil

    List = require("anchorage.list")
    Picker = require("anchorage.picker")
    cfg = H.make_config()
  end)

  after_each(function()
    H.restore_filereadable(stubs.filereadable)
    H.restore_writefile(stubs.writefile)
    H.restore_readfile(stubs.readfile)
    H.restore_mkdir(stubs.mkdir)
    H.restore_notify(stubs.notify)

    remove_snacks_mock()

    package.loaded["anchorage.list"] = nil
    package.loaded["anchorage.picker"] = nil
  end)

  -- ── local helpers ─────────────────────────────────────────────────────────

  local function make_list(values)
    local list = List.new("files", cfg)
    for _, v in ipairs(values or {}) do
      list._items[#list._items + 1] = { value = v, context = {} }
    end
    return list
  end

  local function open_and_capture(list)
    Picker.open(list)
    return snacks_call
  end

  -- ── Picker.open passes correct opts ───────────────────────────────

  describe("Picker.open", function()
    it("passes _anchorage_list = list.name in opts", function()
      local list = make_list({ "a.lua" })
      local opts = open_and_capture(list)
      assert.are.equal("files", opts._anchorage_list)
    end)

    it("items have correct idx, text, value, file, _item fields", function()
      local list = make_list({ "a.lua", "b.lua" })
      local opts = open_and_capture(list)

      assert.are.equal(2, #opts.items)

      local item1 = opts.items[1]
      assert.are.equal(1, item1.idx)
      assert.are.equal("a.lua", item1.value)
      assert.are.equal("a.lua", item1.file)
      assert.is_not_nil(item1.text)
      assert.are.equal("a.lua", item1._item.value)

      assert.are.equal(2, opts.items[2].idx)
      assert.are.equal("b.lua", opts.items[2].value)
    end)
  end)

  -- ── format() ──────────────────────────────────────────────────────

  describe("format()", function()
    it("returns 4-element span table with hl group names", function()
      local list = make_list({ "src/foo.lua" })
      local opts = open_and_capture(list)
      local span = opts.format(opts.items[1], nil)

      assert.are.equal(4, #span)
      assert.is_string(span[1][1])
      assert.are.equal("AnchorageIcon", span[1][2])
      assert.are.equal("AnchorageBadge", span[2][2])
      assert.are.equal("AnchorageName", span[3][2])
      assert.are.equal("AnchorageDir", span[4][2])
    end)

    it("dir segment is empty string when fnamemodify(:h) == '.'", function()
      local orig_fnm = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(path, mod)
        if mod == ":h" then
          return "."
        end
        if mod == ":t" then
          return path
        end
        return orig_fnm(path, mod)
      end

      local list = make_list({ "flat.lua" })
      local opts = open_and_capture(list)
      local span = opts.format(opts.items[1], nil)

      vim.fn.fnamemodify = orig_fnm

      assert.are.equal("", span[4][1])
    end)
  end)

  -- ── actions.delete ────────────────────────────────────────────────

  describe("actions.delete", function()
    it("removes the selected item (idx 2) and refreshes", function()
      local list = make_list({ "a.lua", "b.lua", "c.lua" })
      local opts = open_and_capture(list)

      local refreshed = false
      local mock_picker = make_mock_picker(opts.items, 2)
      mock_picker.refresh = function(self)
        refreshed = true
        -- simulate re-building items
        self.opts.items = {}
        for i, it in ipairs(list:items()) do
          table.insert(self.opts.items, {
            idx = i,
            text = string.format("[%d] %s", i, it.value),
            value = it.value,
            file = it.value,
            _item = it,
          })
        end
      end

      opts.actions.delete(mock_picker, nil)

      assert.are.equal(2, list:length())
      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("c.lua", list._items[2].value)
      assert.is_true(refreshed)
    end)

    it("no-op when picker:current() returns nil", function()
      local list = make_list({ "a.lua" })
      local opts = open_and_capture(list)

      local mock_picker = make_mock_picker({}, 1)
      mock_picker.current = function(_)
        return nil
      end

      opts.actions.delete(mock_picker, nil)

      assert.are.equal(1, list:length())
    end)
  end)

  -- ── actions.move_up ──────────────────────────────────────────────

  describe("actions.move_up", function()
    it("swaps item with previous and saves", function()
      local list = make_list({ "a.lua", "b.lua", "c.lua" })
      local opts = open_and_capture(list)
      local write_before = #stubs.writefile.calls

      local mock_picker = make_mock_picker(opts.items, 2) -- b.lua
      opts.actions.move_up(mock_picker, nil)

      assert.are.equal("b.lua", list._items[1].value)
      assert.are.equal("a.lua", list._items[2].value)
      assert.are.equal("c.lua", list._items[3].value)
      assert.is_true(#stubs.writefile.calls > write_before)
    end)

    it("no-op when current is at index 1", function()
      local list = make_list({ "a.lua", "b.lua" })
      local opts = open_and_capture(list)
      local write_before = #stubs.writefile.calls

      local mock_picker = make_mock_picker(opts.items, 1) -- a.lua
      opts.actions.move_up(mock_picker, nil)

      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("b.lua", list._items[2].value)
      assert.are.equal(write_before, #stubs.writefile.calls)
    end)
  end)

  -- ── actions.move_down ────────────────────────────────────────────

  describe("actions.move_down", function()
    it("swaps item with next and saves", function()
      local list = make_list({ "a.lua", "b.lua", "c.lua" })
      local opts = open_and_capture(list)
      local write_before = #stubs.writefile.calls

      local mock_picker = make_mock_picker(opts.items, 2) -- b.lua
      opts.actions.move_down(mock_picker, nil)

      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("c.lua", list._items[2].value)
      assert.are.equal("b.lua", list._items[3].value)
      assert.is_true(#stubs.writefile.calls > write_before)
    end)

    it("no-op when current is at last index", function()
      local list = make_list({ "a.lua", "b.lua" })
      local opts = open_and_capture(list)
      local write_before = #stubs.writefile.calls

      local mock_picker = make_mock_picker(opts.items, 2) -- b.lua (last)
      opts.actions.move_down(mock_picker, nil)

      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("b.lua", list._items[2].value)
      assert.are.equal(write_before, #stubs.writefile.calls)
    end)
  end)

  -- ── on_close ─────────────────────────────────────────────────────

  describe("on_close", function()
    it("with sync_on_close = true → writefile spy called", function()
      local sync_cfg = H.make_config({ sync_on_close = true })
      local list = List.new("files", sync_cfg)
      list._items = { { value = "a.lua", context = {} } }

      Picker.open(list)
      local write_before = #stubs.writefile.calls
      snacks_call.on_close()

      assert.is_true(#stubs.writefile.calls > write_before)
    end)

    it("with sync_on_close = false → no extra save", function()
      local nosync_cfg = H.make_config({ sync_on_close = false })
      local list = List.new("files", nosync_cfg)
      list._items = { { value = "a.lua", context = {} } }

      Picker.open(list)
      local write_before = #stubs.writefile.calls
      snacks_call.on_close()

      assert.are.equal(write_before, #stubs.writefile.calls)
    end)
  end)

  -- ── Picker.setup_highlights ─────────────────────────────────────

  describe("Picker.setup_highlights", function()
    it("defines all 4 anchorage highlight groups", function()
      Picker.setup_highlights()
      local groups = {
        "AnchorageIcon",
        "AnchorageBadge",
        "AnchorageName",
        "AnchorageDir",
      }
      for _, g in ipairs(groups) do
        local hl = vim.api.nvim_get_hl(0, { name = g })
        assert.is_not_nil(hl)
      end
    end)

    it("uses default = true so a prior user hl is preserved", function()
      -- Set a custom fg before calling setup
      vim.api.nvim_set_hl(0, "AnchorageIcon", { fg = "#ff0000" })
      local before = vim.api.nvim_get_hl(0, { name = "AnchorageIcon", link = false })

      Picker.setup_highlights()

      local after = vim.api.nvim_get_hl(0, { name = "AnchorageIcon", link = false })
      -- The custom fg should be preserved (setup used default=true)
      assert.are.equal(before.fg, after.fg)
    end)
  end)
end)
