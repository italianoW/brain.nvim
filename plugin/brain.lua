-- brain.nvim plugin entry point
-- Registers the :Brain user command

if vim.g.loaded_brain then
  return
end
vim.g.loaded_brain = 1

vim.api.nvim_create_user_command("Brain", function()
  require("brain").open()
end, { desc = "Open Brain note editor" })
