-- tests/config_spec.lua
-- Configuration module tests

local Config = require("anchorage.config")
local H = require("tests.helpers")

describe("anchorage.config", function()
  -- M.defaults shape
  describe("M.defaults", function()
    it("has all expected top-level keys", function()
      local d = Config.defaults
      assert.is_not_nil(d.data_path)
      assert.is_not_nil(d.keymaps)
      assert.is_function(d.key)
      assert.is_not_nil(d.sync_on_close)
      assert.is_not_nil(d.picker)
      assert.is_not_nil(d.default)
    end)

    it("default.equals compares .value", function()
      local eq = Config.defaults.default.equals
      assert.is_true(eq({ value = "foo" }, { value = "foo" }))
      assert.is_false(eq({ value = "foo" }, { value = "bar" }))
    end)

    it("default.encode / decode round-trips a table", function()
      local enc = Config.defaults.default.encode
      local dec = Config.defaults.default.decode
      local tbl = {
        { value = "a.lua", context = {} },
        { value = "b.lua", context = { row = 3 } },
      }
      local ok, result = pcall(dec, enc(tbl))
      assert.is_true(ok)
      assert.are.equal(2, #result)
      assert.are.equal("a.lua", result[1].value)
      assert.are.equal("b.lua", result[2].value)
    end)
  end)

  -- M.merge()
  describe("M.merge()", function()
    it("M.merge(nil) returns defaults", function()
      local cfg = Config.merge(nil)
      assert.is_not_nil(cfg.keymaps)
      assert.is_function(cfg.key)
      assert.is_function(cfg.default.equals)
    end)

    it("M.merge({ keymaps = false }).keymaps == false", function()
      local cfg = Config.merge({ keymaps = false })
      assert.are.equal(false, cfg.keymaps)
    end)

    it("partial keymaps override merges deeply, preserving other keys", function()
      local cfg = Config.merge({ keymaps = { add = "x" } })
      assert.are.equal("x", cfg.keymaps.add)
      -- other keys still present
      assert.is_not_nil(cfg.keymaps.toggle)
      assert.is_not_nil(cfg.keymaps.prev)
    end)

    it("user default subtable doesn't clobber functions", function()
      local cfg = Config.merge({ default = { select_with_nil = true } })
      assert.is_true(cfg.default.select_with_nil)
      assert.is_function(cfg.default.equals)
      assert.is_function(cfg.default.select)
    end)

    it("custom data_path is respected", function()
      local cfg = Config.merge({ data_path = "/tmp/custom" })
      assert.are.equal("/tmp/custom", cfg.data_path)
    end)
  end)

  -- create_list_item
  describe("default.create_list_item", function()
    it("with explicit string item returns { value, context = {} }", function()
      local cfg = H.make_config()
      local result = cfg.default.create_list_item(cfg.default, "foo.lua")
      assert.are.equal("foo.lua", result.value)
      assert.are.same({}, result.context)
    end)

    it("with nil and empty bufname returns nil", function()
      local orig = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function(_)
        return ""
      end
      local orig_bo_ft = vim.bo.filetype
      -- ensure not in snacks picker context
      vim.bo.filetype = "lua"

      local cfg = H.make_config()
      local result = cfg.default.create_list_item(cfg.default, nil)

      vim.api.nvim_buf_get_name = orig
      vim.bo.filetype = orig_bo_ft

      assert.is_nil(result)
    end)
  end)

  -- global_create_list_item
  describe("M.global_create_list_item", function()
    it("with explicit item returns absolute path via :p", function()
      local expected = vim.fn.fnamemodify("foo.lua", ":p")
      local result = Config.global_create_list_item(nil, "foo.lua")
      assert.are.equal(expected, result.value)
      assert.are.same({}, result.context)
    end)

    it("with nil and empty bufname returns nil", function()
      local orig = vim.api.nvim_buf_get_name
      vim.api.nvim_buf_get_name = function(_)
        return ""
      end
      local orig_bo_ft = vim.bo.filetype
      vim.bo.filetype = "lua"

      local result = Config.global_create_list_item(nil, nil)

      vim.api.nvim_buf_get_name = orig
      vim.bo.filetype = orig_bo_ft

      assert.is_nil(result)
    end)
  end)
end)
