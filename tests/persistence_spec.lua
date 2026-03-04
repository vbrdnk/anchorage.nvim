-- tests/persistence_spec.lua
-- JSON save/load, real disk I/O

local H = require("tests.helpers")

local TEST_DIR = "/tmp/anchorage_tests"

describe("anchorage.list persistence", function()
  local notify_stub

  before_each(function()
    vim.fn.mkdir(TEST_DIR, "p")
    notify_stub = H.suppress_notify()
    package.loaded["anchorage.list"] = nil
  end)

  after_each(function()
    H.restore_notify(notify_stub)
    local files = vim.fn.glob(TEST_DIR .. "/*.json", false, true)
    for _, f in ipairs(files) do
      vim.fn.delete(f)
    end
    package.loaded["anchorage.list"] = nil
  end)

  -- save → reload round-trip
  it("items survive a save → reload cycle", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    local list1 = List.new("files", cfg)
    list1:add("alpha.lua")
    list1:add("beta.lua")

    package.loaded["anchorage.list"] = nil
    List = require("anchorage.list")
    local list2 = List.new("files", cfg)

    assert.are.equal(2, list2:length())
    assert.are.equal("alpha.lua", list2._items[1].value)
    assert.are.equal("beta.lua", list2._items[2].value)
  end)

  -- empty list saves and reloads as {}
  it("empty list round-trips cleanly", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    local list1 = List.new("files", cfg)
    list1:save()

    package.loaded["anchorage.list"] = nil
    List = require("anchorage.list")
    local list2 = List.new("files", cfg)

    assert.are.equal(0, list2:length())
  end)

  -- _load() is silent when file missing
  it("_load() is silent when file does not exist", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    assert.has_no_error(function()
      local list = List.new("files", cfg)
      assert.are.equal(0, list:length())
    end)

    for _, call in ipairs(notify_stub.calls) do
      assert.is_not.equal(vim.log.levels.ERROR, call.level)
    end
  end)

  -- malformed JSON results in empty _items
  it("malformed JSON file results in _items = {}", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    local path = TEST_DIR .. "/test_project__files.json"
    local f = io.open(path, "w")
    f:write("{ this is not : valid JSON !!!")
    f:close()

    assert.has_no_error(function()
      local list = List.new("files", cfg)
      assert.are.equal(0, list:length())
    end)
  end)

  -- file path is correct
  it("saves to {data_path}/test_project__files.json", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    local list = List.new("files", cfg)
    list:add("x.lua")

    local expected = TEST_DIR .. "/test_project__files.json"
    assert.are.equal(1, vim.fn.filereadable(expected))
  end)

  -- global list uses __global__ key in file path
  it("global list key_override produces __global____files.json", function()
    local List = require("anchorage.list")
    local cfg = H.make_config()

    local list = List.new("files", cfg, { key_override = "__global__" })
    list:add("x.lua")

    local expected = TEST_DIR .. "/__global____files.json"
    assert.are.equal(1, vim.fn.filereadable(expected))
  end)

  -- custom encode/decode hooks are used
  it("custom encode/decode hooks are invoked during save/load", function()
    local encode_called = false
    local decode_called = false

    local function custom_encode(tbl)
      encode_called = true
      return "MARKER:" .. vim.json.encode(tbl)
    end

    local function custom_decode(str)
      decode_called = true
      local stripped = str:gsub("^MARKER:", "")
      return vim.json.decode(stripped)
    end

    local List = require("anchorage.list")
    local cfg = H.make_config({
      default = { encode = custom_encode, decode = custom_decode },
    })

    local list1 = List.new("files", cfg)
    list1:add("z.lua")
    assert.is_true(encode_called)

    package.loaded["anchorage.list"] = nil
    List = require("anchorage.list")
    local list2 = List.new("files", cfg)
    assert.is_true(decode_called)
    assert.are.equal(1, list2:length())
    assert.are.equal("z.lua", list2._items[1].value)
  end)
end)
