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
  vim.cmd("botright 20split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "signcolumn", "no")
  vim.api.nvim_win_set_option(win, "cursorline", true)
  return win
end

local function render_hint(buf, ns, state)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local line_count = vim.api.nvim_buf_line_count(buf)

  local hints = {
    title   = { line = 0,                                    text = " 🧠 Title:" },
    tags    = { line = (state.title_line_idx or 0) + 1,      text = " 🏷  Tags (comma separated):" },
    content = { line = state.content_start_line or 0,        text = " ✏  Write your note — :BrainSave or <C-s> to save" },
  }

  local h = hints[state.step]
  if h and h.line < line_count then
    vim.api.nvim_buf_set_extmark(buf, ns, h.line, 0, {
      virt_text = { { h.text, "Comment" } },
      virt_text_pos = "right_align",
    })
  end
end

local function extract_body(lines)
  local body_lines = {}
  local divider_seen = false
  for _, l in ipairs(lines) do
    if l == "---" and not divider_seen then
      divider_seen = true
    elseif divider_seen then
      table.insert(body_lines, l)
    end
  end
  return table.concat(body_lines, "\n")
end

function M.open()
  local state = { step = "title", title = "", tags = "" }
  local buf = create_buf()
  local win = create_win(buf)
  local ns  = vim.api.nvim_create_namespace("brain_ui")

  local function hint() render_hint(buf, ns, state) end

  -- Step 1: blank title line
  local function step_title()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    vim.cmd("startinsert!")
    hint()
  end

  -- Step 2: read title, add tags line
  local function step_tags()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    state.title = vim.trim(lines[1] or "")
    if state.title == "" then
      vim.notify("[Brain] Title cannot be empty.", vim.log.levels.WARN)
      return
    end
    state.step = "tags"
    state.title_line_idx = 0
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "tags: ", "" })
    local tag_line = vim.api.nvim_buf_line_count(buf) - 1
    vim.api.nvim_win_set_cursor(win, { tag_line, 100 })
    vim.cmd("startinsert!")
    hint()
  end

  -- Step 3: read tags, open content area
  local function step_content()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for _, l in ipairs(lines) do
      local t = l:match("^tags:%s*(.*)")
      if t then state.tags = vim.trim(t); break end
    end
    state.step = "content"
    local total = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_buf_set_lines(buf, total, -1, false, { "---", "" })
    state.content_start_line = total + 1
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
    vim.cmd("startinsert!")
    hint()
  end

  -- Save & open file
  local function do_save()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local body = extract_body(lines)
    local filepath = note.save(state.title, state.tags, body)
    vim.api.nvim_win_close(win, true)
    vim.notify("[Brain] Saved → " .. filepath, vim.log.levels.INFO)
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  end

  local function on_enter()
    if state.step == "title" then
      step_tags()
    elseif state.step == "tags" then
      step_content()
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    end
  end

  -- Keymaps
  local km = { noremap = true, silent = true, buffer = buf }
  vim.keymap.set("i",        "<CR>",  on_enter, km)
  vim.keymap.set("n",        "<CR>",  on_enter, km)
  vim.keymap.set({ "i","n" },"<Esc>", function()
    vim.api.nvim_win_close(win, true)
    vim.notify("[Brain] Cancelled.", vim.log.levels.INFO)
  end, km)
  vim.keymap.set({ "i","n" }, "<C-s>", function()
    if state.step == "content" then do_save() end
  end, km)

  vim.api.nvim_buf_create_user_command(buf, "BrainSave", do_save, {})

  step_title()
end

return M
