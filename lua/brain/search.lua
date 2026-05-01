-- brain/search.lua
-- :BrainSearch — fuzzy-filter notes by title or tag, open on select

local config = require("brain.config")

local M = {}

-- Parse a .md file and return { title, tags, filepath }
local function parse_note(filepath)
  local lines = vim.fn.readfile(filepath)
  local title, tags = "", ""
  for _, line in ipairs(lines) do
    if title == "" then
      title = line:match("^#%s+(.*)")  or title
    end
    if tags == "" then
      local raw = line:match("^tags:%s+(.*)")
      if raw and raw ~= "(none)" then
        tags = raw
      end
    end
    if title ~= "" and tags ~= "" then break end
  end
  return { title = title, tags = tags, filepath = filepath }
end

-- Load all notes from brain_dir
local function load_notes()
  local dir = config.values.brain_dir
  if vim.fn.isdirectory(dir) == 0 then return {} end
  local files = vim.fn.globpath(dir, "*.md", false, true)
  local notes = {}
  for _, f in ipairs(files) do
    table.insert(notes, parse_note(f))
  end
  return notes
end

-- Check if query matches note (title or any tag), case-insensitive
local function matches(note, query)
  query = query:lower():gsub("^#", "")
  if note.title:lower():find(query, 1, true) then return true end
  for tag in note.tags:gmatch("[^%s]+") do
    if tag:lower():gsub("^#", ""):find(query, 1, true) then return true end
  end
  return false
end

-- Render results into the search buffer
local function render(buf, ns, notes, query, cursor_idx)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local filtered = {}
  for _, n in ipairs(notes) do
    if query == "" or matches(n, query) then
      table.insert(filtered, n)
    end
  end

  local lines = {}
  for _, n in ipairs(filtered) do
    local tag_display = n.tags ~= "" and ("  " .. n.tags) or ""
    table.insert(lines, n.title .. tag_display)
  end

  if #lines == 0 then
    lines = { "  (no results)" }
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Highlight tags with a dimmer color
  for i, n in ipairs(filtered) do
    local title_len = #n.title
    if n.tags ~= "" then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, title_len, {
        end_col = #lines[i],
        hl_group = "Comment",
      })
    end
  end

  -- Highlight the cursor line
  if cursor_idx <= #filtered then
    vim.api.nvim_buf_set_extmark(buf, ns, cursor_idx - 1, 0, {
      line_hl_group = "CursorLine",
    })
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  return filtered
end

function M.open()
  local notes = load_notes()
  local query = ""
  local cursor_idx = 1
  local filtered = notes

  -- ── Layout: input line on top, results below ──
  local total_height = 20
  local results_height = total_height - 2  -- minus prompt + separator

  -- Results buffer (read-only list)
  local results_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(results_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(results_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(results_buf, "modifiable", false)

  -- Input buffer (one line)
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(input_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(input_buf, "bufhidden", "wipe")

  -- Open results window first (bottom split)
  vim.cmd("botright " .. results_height .. "split")
  local results_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(results_win, results_buf)
  vim.api.nvim_win_set_option(results_win, "number", false)
  vim.api.nvim_win_set_option(results_win, "relativenumber", false)
  vim.api.nvim_win_set_option(results_win, "signcolumn", "no")
  vim.api.nvim_win_set_option(results_win, "cursorline", false)

  -- Open input window above results
  vim.cmd("aboveleft 2split")
  local input_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(input_win, input_buf)
  vim.api.nvim_win_set_option(input_win, "number", false)
  vim.api.nvim_win_set_option(input_win, "relativenumber", false)
  vim.api.nvim_win_set_option(input_win, "signcolumn", "no")

  local ns = vim.api.nvim_create_namespace("brain_search")

  -- Prompt hint
  vim.api.nvim_buf_set_extmark(input_buf, ns, 0, 0, {
    virt_text = { { " 🔍 <Enter> open · < r> delete · <Tab>/<S-Tab> navigate · <Esc> cancel", "Comment" } },
    virt_text_pos = "right_align",
  })

  -- Initial render
  filtered = render(results_buf, ns, notes, query, cursor_idx)

  local function open_selected()
    if #filtered == 0 then return end
    local sel = filtered[cursor_idx]
    if not sel then return end
    -- Close both windows
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_win_close(results_win, true)
    vim.cmd("edit " .. vim.fn.fnameescape(sel.filepath))
  end

  local function close_all()
    vim.api.nvim_win_close(input_win, true)
    if vim.api.nvim_win_is_valid(results_win) then
      vim.api.nvim_win_close(results_win, true)
    end
  end

  local function move_cursor(delta)
    local max = math.max(1, #filtered)
    cursor_idx = math.max(1, math.min(cursor_idx + delta, max))
    render(results_buf, ns, notes, query, cursor_idx)
  end

  -- Re-render on every keystroke in the input buffer
  -- vim.schedule defers the render outside on_lines (which cannot modify buffers)
  vim.api.nvim_buf_attach(input_buf, false, {
    on_lines = function()
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(input_buf) then return end
        local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
        query = vim.trim(lines[1] or "")
        cursor_idx = 1
        filtered = render(results_buf, ns, notes, query, cursor_idx)
      end)
    end,
  })

  local function delete_selected()
    if #filtered == 0 then return end
    local sel = filtered[cursor_idx]
    if not sel then return end

    -- vim.fn.confirm is safe to call from insert mode via vim.schedule
    vim.schedule(function()
      local choice = vim.fn.confirm(
        'Delete "' .. sel.title .. '"?',
        "&Yes\n&No", 2
      )
      if choice ~= 1 then return end

      -- Delete the file
      local ok, err = os.remove(sel.filepath)
      if not ok then
        vim.notify("[Brain] Failed to delete: " .. (err or "unknown error"), vim.log.levels.ERROR)
        return
      end

      vim.notify("[Brain] Deleted: " .. sel.title, vim.log.levels.INFO)

      -- Remove from master notes list and re-render
      for i, n in ipairs(notes) do
        if n.filepath == sel.filepath then
          table.remove(notes, i)
          break
        end
      end
      cursor_idx = math.max(1, cursor_idx - 1)
      filtered = render(results_buf, ns, notes, query, cursor_idx)
    end)
  end

  local km = { noremap = true, silent = true, buffer = input_buf }
  vim.keymap.set("i", "<CR>",    open_selected,   km)
  vim.keymap.set("i", "<Esc>",   close_all,       km)
  vim.keymap.set("n", "<Esc>",   close_all,       km)
  vim.keymap.set("i", "<leader>r",   delete_selected, km)
  vim.keymap.set("n", "<leader>r",   delete_selected, km)
  vim.keymap.set("i", "<Tab>",   function() move_cursor(1)  end, km)
  vim.keymap.set("i", "<S-Tab>", function() move_cursor(-1) end, km)
  vim.keymap.set("n", "<Tab>",   function() move_cursor(1)  end, km)
  vim.keymap.set("n", "<S-Tab>", function() move_cursor(-1) end, km)

  vim.cmd("startinsert!")
end

return M
