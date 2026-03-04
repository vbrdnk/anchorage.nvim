-- tests/list_spec.lua
-- List CRUD, navigation, and field tests

local H = require("tests.helpers")

describe("anchorage.list", function()
  local List
  local cfg
  local stubs = {}

  before_each(function()
    stubs.filereadable = H.stub_filereadable(0)
    stubs.writefile = H.stub_writefile()
    stubs.readfile = H.stub_readfile({})
    stubs.mkdir = H.stub_mkdir()
    stubs.notify = H.suppress_notify()

    package.loaded["anchorage.list"] = nil
    List = require("anchorage.list")
    cfg = H.make_config()
  end)

  after_each(function()
    H.restore_filereadable(stubs.filereadable)
    H.restore_writefile(stubs.writefile)
    H.restore_readfile(stubs.readfile)
    H.restore_mkdir(stubs.mkdir)
    H.restore_notify(stubs.notify)
    package.loaded["anchorage.list"] = nil
  end)

  -- ── List.new / fields ─────────────────────────────────────────────

  describe("List.new", function()
    it("sets .name, .config, ._items = {}", function()
      local list = List.new("files", cfg)
      assert.are.equal("files", list.name)
      assert.are.equal(cfg, list.config)
      assert.are.same({}, list._items)
    end)

    it("sets _key_override from opts.key_override", function()
      local list = List.new("files", cfg, { key_override = "__global__" })
      assert.are.equal("__global__", list._key_override)
    end)

    it("_key_override is nil when opts not provided", function()
      local list = List.new("files", cfg)
      assert.is_nil(list._key_override)
    end)
  end)

  -- ── _path() ───────────────────────────────────────────────────────

  describe("_path()", function()
    it("with project key produces test_project__files.json", function()
      local list = List.new("files", cfg)
      local path = list:_path()
      assert.are.equal("/tmp/anchorage_tests/test_project__files.json", path)
    end)

    it("with key_override = '__global__' contains __global____files.json", function()
      local list = List.new("files", cfg, { key_override = "__global__" })
      local path = list:_path()
      assert.are.equal("/tmp/anchorage_tests/__global____files.json", path)
    end)

    it("sanitizes slashes to underscores and strips non-[%w_-] chars", function()
      local slash_cfg = H.make_config({
        key = function()
          return "/home/user/myproject"
        end,
      })
      local list = List.new("files", slash_cfg)
      local path = list:_path()
      -- basename should only contain word chars, underscores, dashes, dots
      local basename = path:match("([^/]+)$")
      assert.is_nil(basename:match("[^%w_%.%-]"), "Basename contains invalid chars: " .. basename)
      -- Should contain the sanitised key fragment
      assert.matches("home_user_myproject__files%.json$", path)
    end)
  end)

  -- ── add() ─────────────────────────────────────────────────────────

  describe("add()", function()
    it("appends item to list", function()
      local list = List.new("files", cfg)
      list:add("foo.lua")
      assert.are.equal(1, list:length())
      assert.are.equal("foo.lua", list._items[1].value)
    end)

    it("triggers writefile spy after add", function()
      local list = List.new("files", cfg)
      list:add("foo.lua")
      assert.are.equal(1, #stubs.writefile.calls)
    end)

    it("notifies INFO on success", function()
      local list = List.new("files", cfg)
      list:add("foo.lua")
      assert.are.equal(1, #stubs.notify.calls)
      assert.are.equal(vim.log.levels.INFO, stubs.notify.calls[1].level)
    end)

    it("duplicate item keeps length at 1 and notifies WARN", function()
      local list = List.new("files", cfg)
      list:add("foo.lua")
      list:add("foo.lua")
      assert.are.equal(1, list:length())
      local last = stubs.notify.calls[#stubs.notify.calls]
      assert.are.equal(vim.log.levels.WARN, last.level)
    end)

    it("create_list_item returning nil → no-op, no notify", function()
      local patched_cfg = H.make_config({
        default = {
          create_list_item = function()
            return nil
          end,
        },
      })
      local list = List.new("files", patched_cfg)
      list:add("anything")
      assert.are.equal(0, list:length())
      assert.are.equal(0, #stubs.notify.calls)
    end)
  end)

  -- ── prepend() ─────────────────────────────────────────────────────

  describe("prepend()", function()
    it("inserts at index 1 and pushes others down", function()
      local list = List.new("files", cfg)
      list:add("b.lua")
      list:prepend("a.lua")
      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("b.lua", list._items[2].value)
    end)

    it("saves after prepend", function()
      local list = List.new("files", cfg)
      local before = #stubs.writefile.calls
      list:prepend("a.lua")
      assert.is_true(#stubs.writefile.calls > before)
    end)

    it("duplicate is silent (no extra notify, no extra save)", function()
      local list = List.new("files", cfg)
      list:add("a.lua")
      local write_before = #stubs.writefile.calls
      local notify_before = #stubs.notify.calls
      list:prepend("a.lua")
      assert.are.equal(write_before, #stubs.writefile.calls)
      assert.are.equal(notify_before, #stubs.notify.calls)
      assert.are.equal(1, list:length())
    end)
  end)

  -- ── remove_at() / remove() ────────────────────────────────────────

  describe("remove_at()", function()
    it("removes the correct item and saves", function()
      local list = List.new("files", cfg)
      list:add("a.lua")
      list:add("b.lua")
      list:add("c.lua")
      local before = #stubs.writefile.calls
      list:remove_at(2)
      assert.are.equal(2, list:length())
      assert.are.equal("a.lua", list._items[1].value)
      assert.are.equal("c.lua", list._items[2].value)
      assert.is_true(#stubs.writefile.calls > before)
    end)
  end)

  describe("remove()", function()
    it("removes by value equality and saves", function()
      local list = List.new("files", cfg)
      list:add("a.lua")
      list:add("b.lua")
      local before = #stubs.writefile.calls
      list:remove({ value = "a.lua" })
      assert.are.equal(1, list:length())
      assert.are.equal("b.lua", list._items[1].value)
      assert.is_true(#stubs.writefile.calls > before)
    end)

    it("no-op when item is not in list", function()
      local list = List.new("files", cfg)
      list:add("a.lua")
      local before = #stubs.writefile.calls
      list:remove({ value = "nonexistent.lua" })
      assert.are.equal(1, list:length())
      assert.are.equal(before, #stubs.writefile.calls)
    end)
  end)

  -- ── select() ──────────────────────────────────────────────────────

  describe("select()", function()
    it("calls config.default.select with the correct item", function()
      local selected = nil
      local sel_cfg = H.make_config({
        default = {
          select = function(item, _, _)
            selected = item
          end,
        },
      })
      local list = List.new("files", sel_cfg)
      list:add("a.lua")
      list:select(1)
      assert.are.equal("a.lua", selected.value)
    end)

    it("out-of-bounds with select_with_nil = false → no call", function()
      local called = false
      local sel_cfg = H.make_config({
        default = {
          select_with_nil = false,
          select = function(_, _, _)
            called = true
          end,
        },
      })
      local list = List.new("files", sel_cfg)
      list:select(99)
      assert.is_false(called)
    end)

    it("out-of-bounds with select_with_nil = true → called with nil", function()
      local called_with = "NOT_CALLED"
      local sel_cfg = H.make_config({
        default = {
          select_with_nil = true,
          select = function(item, _, _)
            called_with = item
          end,
        },
      })
      local list = List.new("files", sel_cfg)
      list:select(99)
      assert.is_nil(called_with)
    end)
  end)

  -- ── next() ────────────────────────────────────────────────────────

  describe("next()", function()
    local orig_buf, orig_fnm

    before_each(function()
      orig_buf = vim.api.nvim_buf_get_name
      orig_fnm = vim.fn.fnamemodify
    end)

    after_each(function()
      vim.api.nvim_buf_get_name = orig_buf
      vim.fn.fnamemodify = orig_fnm
    end)

    local function make_nav_list(items_values, on_select)
      local nav_cfg = H.make_config({ default = { select = on_select } })
      local list = List.new("files", nav_cfg)
      list._items = {}
      for _, v in ipairs(items_values) do
        list._items[#list._items + 1] = { value = v, context = {} }
      end
      return list
    end

    local function stub_current_buf(name)
      vim.api.nvim_buf_get_name = function(_)
        return name
      end
      vim.fn.fnamemodify = function(path, mod)
        if mod == ":~:." then
          return path
        end
        return orig_fnm(path, mod)
      end
    end

    it("current buf A in [A,B,C] → selects B", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua", "c.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("a.lua")
      list:next()
      assert.are.equal("b.lua", selected.value)
    end)

    it("current buf C in [A,B,C] → wraps to A", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua", "c.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("c.lua")
      list:next()
      assert.are.equal("a.lua", selected.value)
    end)

    it("current buf not in list → selects first", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("other.lua")
      list:next()
      assert.are.equal("a.lua", selected.value)
    end)

    it("empty list → no-op (no error)", function()
      local nav_cfg = H.make_config({
        default = {
          select = function()
            error("should not be called")
          end,
        },
      })
      local list = List.new("files", nav_cfg)
      stub_current_buf("x.lua")
      assert.has_no_error(function()
        list:next()
      end)
    end)
  end)

  -- ── prev() ────────────────────────────────────────────────────────

  describe("prev()", function()
    local orig_buf, orig_fnm

    before_each(function()
      orig_buf = vim.api.nvim_buf_get_name
      orig_fnm = vim.fn.fnamemodify
    end)

    after_each(function()
      vim.api.nvim_buf_get_name = orig_buf
      vim.fn.fnamemodify = orig_fnm
    end)

    local function make_nav_list(items_values, on_select)
      local nav_cfg = H.make_config({ default = { select = on_select } })
      local list = List.new("files", nav_cfg)
      list._items = {}
      for _, v in ipairs(items_values) do
        list._items[#list._items + 1] = { value = v, context = {} }
      end
      return list
    end

    local function stub_current_buf(name)
      vim.api.nvim_buf_get_name = function(_)
        return name
      end
      vim.fn.fnamemodify = function(path, mod)
        if mod == ":~:." then
          return path
        end
        return orig_fnm(path, mod)
      end
    end

    it("current buf B in [A,B,C] → selects A", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua", "c.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("b.lua")
      list:prev()
      assert.are.equal("a.lua", selected.value)
    end)

    it("current buf A in [A,B,C] → wraps to C", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua", "c.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("a.lua")
      list:prev()
      assert.are.equal("c.lua", selected.value)
    end)

    it("current buf not in list → selects last", function()
      local selected
      local list = make_nav_list({ "a.lua", "b.lua" }, function(item)
        selected = item
      end)
      stub_current_buf("other.lua")
      list:prev()
      assert.are.equal("b.lua", selected.value)
    end)

    it("empty list → no-op (no error)", function()
      local nav_cfg = H.make_config({
        default = {
          select = function()
            error("should not be called")
          end,
        },
      })
      local list = List.new("files", nav_cfg)
      stub_current_buf("x.lua")
      assert.has_no_error(function()
        list:prev()
      end)
    end)
  end)
end)
