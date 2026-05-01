-- brain/init.lua
local config = require("brain.config")
local ui     = require("brain.ui")
local search = require("brain.search")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.open()
  ui.open()
end

function M.search()
  search.open()
end

return M
