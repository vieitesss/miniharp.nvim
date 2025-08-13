# miniharp

> Minimal Harpoon-like plugin for Neovim. Session-only, zero deps, tiny API.

Inspired by (and giving full credit to) **Harpoon** by [ThePrimeagen](https://github.com/ThePrimeagen/). If you need a richer feature, check out [Harpoon2](https://github.com/ThePrimeagen/harpoon/tree/harpoon2)

## Features

- **File marks**.
- **Auto-remembers last cursor position** in each marked file when you switch buffers.
- **Jump next/prev** through marked files from anywhere.
- **Session-only** by design (simple and fast). No external deps.

## Install

### With a plugin manager (local path)

**lazy.nvim** example:

```lua
{
    'vieitesss/miniharp.nvim',
    config = true,
}
```

**vim.pack** example:

```lua
vim.pack.add({
    { src = 'https://github.com/vieitesss/miniharp.nvim' }
})

require('miniharp').setup()
```

## Usage (recommended keymaps)

`miniharp` doesn’t force maps. Here are some defaults you might like:

```lua
vim.keymap.set('n', '<leader>m', require('miniharp').toggle_file, { desc = 'miniharp: toggle file mark' })
vim.keymap.set('n', '<C-n>',     require('miniharp').next,        { desc = 'miniharp: next file mark' })
vim.keymap.set('n', '<C-p>',     require('miniharp').prev,        { desc = 'miniharp: prev file mark' })
```

Typical flow:

1. In a file you care about, hit `<leader>m` to toggle a **file mark**.
2. Work as usual. When you leave that file, its last cursor spot is auto-saved.
3. From anywhere, use `<C-n>`/`<C-p>` to jump around marked files.

## API

All functions are exposed from `require('miniharp')`:

- `setup(opts?)` → Initializes plugin.
  - `opts.autosave` (boolean, default `true`): Update a file’s saved position on `BufLeave`.
- `toggle_file()` → Toggle a file mark for the **current** file.
- `add_file()` → Add/update a file mark for the current file at the **current cursor**.
- `next()` / `prev()` → Jump to next/previous file mark (wraps).
- `list()` → Returns a deep copy of the marks table: `{ { file, lnum, col }, ... }`.
- `clear()` → Remove all marks.

## Design notes

- **Minimalism first.** No UI, no persistence, no indexing — just quick file hopping with remembered spots.
- **Session-only on purpose.** If you want per-project persistence or a picker UI, you probably want Harpoon or a heavier layer on top. (Miniharp can be extended later if needed.)

## License

MIT — see `LICENSE`.

