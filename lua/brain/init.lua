-- brain/init.lua
-- Public API — thin entry point that wires config + ui

local config = require("brain.config")
local ui     = require("brain.ui")

local M = {}

function M.setup(opts)
  config.setup(opts)
end

function M.open()
  ui.open()
end

return M
