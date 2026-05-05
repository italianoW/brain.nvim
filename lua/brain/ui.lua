-- brain/ui.lua
-- Manages the split buffer UI, step flow, keymaps, and hints

local note = require("brain.note")

local M = {}

local function create_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  return buf
end

local function create_win(buf)
  vim.cmd("botright 6split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn", "no")
  vim.api.nvim_win_set_option(win, "cursorline", true)
  return win
end

local function render_hint(buf, ns, step)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local hints = {
    title = { line = 0, text = " 🧠 Title — <Enter> to continue · <Esc> cancel" },
    tags  = { line = 1, text = " 🏷  Tags (comma separated) — <Enter> to save" },
  }
  local h = hints[step]
  if h then
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, 0, {
      virt_text = { { h.text, "Comment" } },
      virt_text_pos = "right_align",
    })
  end
end

function M.open()
  local state = { step = "title", title = "", tags = "" }
  local buf = create_buf()
  local win = create_win(buf)
  local ns  = vim.api.nvim_create_namespace("brain_ui")

  -- Two fixed lines: title and tags
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", "tags: " })
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  vim.cmd("startinsert!")
  render_hint(buf, ns, "title")

  local function do_save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    state.title = vim.trim(lines[1] or "")
    local raw_tags = (lines[2] or ""):match("^tags:%s*(.*)")
    state.tags = vim.trim(raw_tags or "")

    if state.title == "" then
      vim.notify("[Brain] Title cannot be empty.", vim.log.levels.WARN)
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
      vim.cmd("startinsert!")
      return
    end

    local filepath = note.save(state.title, state.tags, "")
    vim.api.nvim_win_close(win, true)
    vim.notify("[Brain] Saved → " .. filepath, vim.log.levels.INFO)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    vim.schedule(function()
      vim.cmd("normal! G")
      vim.cmd("startinsert!")
    end)
  end

  local function on_enter()
    if state.step == "title" then
      local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
      state.title = vim.trim(lines[1] or "")
      if state.title == "" then
        vim.notify("[Brain] Title cannot be empty.", vim.log.levels.WARN)
        return
      end
      state.step = "tags"
      -- Move cursor to end of tags line
      vim.api.nvim_win_set_cursor(win, { 2, #"tags: " })
      vim.cmd("startinsert!")
      render_hint(buf, ns, "tags")
    elseif state.step == "tags" then
      do_save()
    end
  end

  local km = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("i", "<CR>", on_enter, km)
  vim.keymap.set("n", "<CR>", on_enter, km)
  vim.keymap.set({ "i", "n" }, "<Esc>", function()
    vim.api.nvim_win_close(win, true)
    vim.notify("[Brain] Cancelled.", vim.log.levels.INFO)
  end, km)
end

return M
