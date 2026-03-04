-- tests/helpers.lua
-- Shared helpers and stub utilities for the anchorage test suite.

local Config = require("anchorage.config")

local H = {}

-- ── Config factory ───────────────────────────────────────────────────────────

--- Returns a merged config suitable for tests.
--- data_path points to /tmp, key() returns "test_project", keymaps disabled.
---@param overrides? table
function H.make_config(overrides)
  return Config.merge(vim.tbl_deep_extend("force", {
    data_path = "/tmp/anchorage_tests",
    key = function()
      return "test_project"
    end,
    keymaps = false,
  }, overrides or {}))
end

-- ── vim.fn stubs ─────────────────────────────────────────────────────────────

---@return table stub  { calls = {}, orig = fn }
function H.stub_writefile()
  local stub = { calls = {}, orig = vim.fn.writefile }
  vim.fn.writefile = function(...)
    table.insert(stub.calls, { ... })
    return 0
  end
  return stub
end

function H.restore_writefile(stub)
  vim.fn.writefile = stub.orig
end

---@param lines string[]  lines returned by the stub
---@return table stub
function H.stub_readfile(lines)
  local stub = { orig = vim.fn.readfile }
  vim.fn.readfile = function(_path)
    return lines or {}
  end
  return stub
end

function H.restore_readfile(stub)
  vim.fn.readfile = stub.orig
end

---@param returns number  0 = not readable, 1 = readable
---@return table stub
function H.stub_filereadable(returns)
  local stub = { orig = vim.fn.filereadable }
  vim.fn.filereadable = function(_path)
    return returns
  end
  return stub
end

function H.restore_filereadable(stub)
  vim.fn.filereadable = stub.orig
end

--- Stub vim.fn.mkdir so we don't actually create dirs in unit tests.
---@return table stub
function H.stub_mkdir()
  local stub = { calls = {}, orig = vim.fn.mkdir }
  vim.fn.mkdir = function(...)
    table.insert(stub.calls, { ... })
    return 1
  end
  return stub
end

function H.restore_mkdir(stub)
  vim.fn.mkdir = stub.orig
end

-- ── vim.notify stub ───────────────────────────────────────────────────────────

---@return table stub  { calls = {}, orig = fn }
function H.suppress_notify()
  local stub = { calls = {}, orig = vim.notify }
  vim.notify = function(msg, level, opts)
    table.insert(stub.calls, { msg = msg, level = level, opts = opts })
  end
  return stub
end

function H.restore_notify(stub)
  vim.notify = stub.orig
end

-- ── package cache helpers ────────────────────────────────────────────────────

--- Unload anchorage modules so each test starts fresh.
function H.unload_anchorage()
  package.loaded["anchorage"] = nil
  package.loaded["anchorage.list"] = nil
  package.loaded["anchorage.config"] = nil
  package.loaded["anchorage.picker"] = nil
  package.loaded["anchorage.health"] = nil
end

return H
