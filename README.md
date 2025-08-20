# miniharp.nvim

> Minimal Harpoon-like plugin for Neovim. Zero deps, tiny API, optional per-cwd persistence.

Inspired by (and giving full credit to) **Harpoon** by [ThePrimeagen](https://github.com/ThePrimeagen/). If you want a richer feature set (lists, terminals, advanced UI), check out [Harpoon2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2).

## Features

- **File marks**.
- **Auto-remembers last cursor position** in each marked file when you switch buffers.
- **Jump next/prev** through marked files from anywhere.
- **Per-cwd persistence** with `autoload` / `autosave` (defaults **on**).
- **Tiny floating list UI** (top-right):
  - Shows the current marked files (relative paths).
  - Closes on **any key**.
  - Optional auto-show after autoload via `show_on_autoload` (default: **off**).

## Installation

### vim.pack

```lua
vim.pack.add({
  { src = 'https://github.com/vieitesss/miniharp.nvim' }
})

require('miniharp').setup({
  autoload = true, -- load marks for this cwd on startup (default: true)
  autosave = true, -- save marks for this cwd on exit (default: true)
  show_on_autoload = true, -- show popup list after a successful autoload (default: false)
})
```

### lazy.nvim

```lua
{
  'vieitesss/miniharp.nvim',
  opts = {
    autoload = true,
    autosave = true,
    show_on_autoload = false 
  },
}
```

## Usage (recommended keymaps)

`miniharp` doesn’t force maps. Here are some defaults you might like:

```lua
vim.keymap.set('n', '<leader>m', require('miniharp').toggle_file, { desc = 'miniharp: toggle file mark' })
vim.keymap.set('n', '<C-n>',     require('miniharp').next,        { desc = 'miniharp: next file mark' })
vim.keymap.set('n', '<C-p>',     require('miniharp').prev,        { desc = 'miniharp: prev file mark' })
vim.keymap.set('n', '<leader>l', require('miniharp').show_list,   { desc = 'miniharp: list marks' })
```

Typical flow:

1. In a file you care about, hit `<leader>m` to toggle a **file mark**.
2. Work as usual. When you leave that file, its last cursor spot is auto-saved.
3. From anywhere, use `<C-n>` / `<C-p>` to jump around marked files.
4. On a new Neovim session in the **same cwd**, marks auto-load (if `autoload = true`).  
   Show the list on demand with `<leader>l`, or enable `show_on_autoload = true` to pop it up automatically.

## API

All functions are exposed from `require('miniharp')`:

- `setup(opts?)` – Initialize the plugin.

  ```lua
  ---@class MiniharpOpts
  ---@field autoload? boolean          @Load saved marks for this cwd on startup (default: true)
  ---@field autosave? boolean          @Save marks for this cwd on exit (default: true)
  ---@field show_on_autoload? boolean  @Show the marks list UI after a successful autoload (default: false)
  ```

- `toggle_file()` – Toggle a file mark for the **current** file.
- `add_file()` – Add/update a file mark for the current file at the **current cursor**.
- `next()` / `prev()` – Jump to next/previous file mark (wraps).
- `list()` – Returns a deep copy of the marks table: `{ { file, lnum, col }, ... }`.
- `clear()` – Remove all marks.
- `show_list()` – Open the floating list UI (closes on any key).
- `save()` – Manually persist marks for the current cwd.
- `restore()` – Manually restore marks for the current cwd (if present).

## Design notes

- **Minimalism first.** Small surface area and simple behavior; no dependencies.
- **Per-cwd persistence.** Keeps things project-scoped. Disable by setting `autoload = false` and/or `autosave = false`.
- **UI stays out of the way.** The popup is read-only, top-right, and disappears on the next keypress; auto-show is opt-in.
