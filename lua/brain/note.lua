-- brain/note.lua
-- Handles note creation, formatting, and saving to disk

local config = require("brain.config")

local M = {}

local function ensure_dir()
  local dir = config.values.brain_dir
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  return dir
end

local function title_to_filename(title)
  return title
    :gsub('[%s/\\:*?"<>|]', "_")
    :gsub("_+", "_")
    :gsub("^_", "")
    :gsub("_$", "")
end

local function normalize_tags(raw)
  if not raw or raw == "" then
    return "(none)"
  end
  local list = {}
  for tag in raw:gmatch("[^,%s]+") do
    local t = tag:gsub("^#", "")
    if t ~= "" then
      table.insert(list, "#" .. t)
    end
  end
  return #list > 0 and table.concat(list, " ") or "(none)"
end

function M.format(title, tags, body)
  local lines = {
    "# " .. title,
    "",
    "tags: " .. normalize_tags(tags),
    "",
    "---",
    "",
  }
  if body and body ~= "" then
    for line in (body .. "\n"):gmatch("(.-)\n") do
      table.insert(lines, line)
    end
  end
  return lines
end

function M.save(title, tags, body)
  local dir = ensure_dir()
  local filepath = dir .. "/" .. title_to_filename(title) .. ".md"
  vim.fn.writefile(M.format(title, tags, body), filepath)
  return filepath
end

return M
