-- brain/search.lua
-- :BrainSearch — telescope live_grep scoped to the brain folder

local config = require("brain.config")

local M = {}

function M.open()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("[Brain] telescope.nvim is required for BrainSearch.", vim.log.levels.ERROR)
    return
  end

  local dir = config.values.brain_dir
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("[Brain] Brain folder not found: " .. dir, vim.log.levels.WARN)
    return
  end

  builtin.live_grep({
    cwd          = dir,
    prompt_title = "🧠 Brain Search",
  })
end

return M
