-- brain.nvim plugin entry point
if vim.g.loaded_brain then return end
vim.g.loaded_brain = 1

local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local lua_dir = plugin_dir .. "/lua"
package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path

vim.api.nvim_create_user_command("Brain", function()
  require("brain").open()
end, { desc = "Open Brain note editor" })

vim.api.nvim_create_user_command("BrainSearch", function()
  require("brain").search()
end, { desc = "Search Brain notes by title or tag" })
