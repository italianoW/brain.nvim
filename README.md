# 🧠 brain.nvim

A minimal Neovim plugin to quickly capture notes into a local `~/brain` folder.

## Features

- `:Brain` command opens a guided note editor (title → tags → content)
- Notes saved as Markdown files in `~/brain/` named after the title
- Tags normalized and written to frontmatter
- Opens the saved file after writing

---

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = "~/.config/nvim/plugins/brain.nvim", -- if using locally
  -- or use a GitHub path if you publish it:
  -- "yourusername/brain.nvim",
  config = function()
    require("brain").setup({
      brain_dir = vim.fn.expand("~/brain"), -- default
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "~/.config/nvim/plugins/brain.nvim",
  config = function()
    require("brain").setup()
  end,
}
```

### Manual

Copy the plugin to your Neovim runtime path:

```bash
cp -r brain.nvim ~/.config/nvim/plugins/brain.nvim
```

Then add to your `init.lua`:

```lua
require("brain").setup()
```

---

## Usage

1. Run `:Brain` — a split opens at the bottom
2. **Type your title**, press `<Enter>`
3. **Type your tags** (comma or space separated, e.g. `ideas, work, nvim`), press `<Enter>`
4. **Write your note content** freely
5. Press `<C-s>` or run `:BrainSave` to save

Press `<Esc>` at any point to cancel.

---

## Output Format

Each note is saved as `~/brain/<title>.md`:

```markdown
# My Note Title

tags: #ideas #work #nvim

---

Your note content goes here.
```

---

## Configuration

```lua
require("brain").setup({
  brain_dir = "~/brain", -- where notes are stored
})
```

---

## File Structure

```
brain.nvim/
├── plugin/
│   └── brain.lua       ← registers :Brain command
├── lua/
│   └── brain/
│       └── init.lua    ← core logic
└── README.md
```
