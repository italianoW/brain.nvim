-- brain/config.lua
-- Holds the plugin configuration and setup()

local M = {}

M.values = {
  brain_dir = vim.fn.expand("~/brain"),
}

function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", M.values, opts or {})
end

return M
