-- Test init file for miniharp.nvim development
-- Add the plugin to runtime path
vim.opt.runtimepath:prepend('.')

vim.g.mapleader = ' '

require('miniharp').setup({
    autoload = true,
    autosave = true,
    show_on_autoload = true,
    ui = {
        position = 'top-right',
        show_hints = false,
        enter = false,
    },
})

local miniharp = require('miniharp')

vim.keymap.set(
    'n',
    '<leader>ma',
    miniharp.toggle_file,
    { desc = 'miniharp: toggle file mark' }
)
vim.keymap.set(
    'n',
    '<C-n>',
    miniharp.next,
    { desc = 'miniharp: next file mark' }
)
vim.keymap.set(
    'n',
    '<C-p>',
    miniharp.prev,
    { desc = 'miniharp: previous file mark' }
)
vim.keymap.set('n', '<C-j>', function()
    miniharp.go_to(1)
end, { desc = 'miniharp: go to file mark 1' })
vim.keymap.set('n', '<C-k>', function()
    miniharp.go_to(2)
end, { desc = 'miniharp: go to file mark 2' })
vim.keymap.set('n', '<C-l>', function()
    miniharp.go_to(3)
end, { desc = 'miniharp: go to file mark 3' })
vim.keymap.set(
    'n',
    '<leader>l',
    miniharp.show_list,
    { desc = 'miniharp: toggle marks list' }
)
vim.keymap.set(
    'n',
    '<leader>L',
    miniharp.enter_list,
    { desc = 'miniharp: enter marks list' }
)
vim.keymap.set(
    'n',
    '<leader>ms',
    miniharp.save,
    { desc = 'miniharp: save marks' }
)
vim.keymap.set(
    'n',
    '<leader>mr',
    miniharp.restore,
    { desc = 'miniharp: restore marks' }
)
vim.keymap.set(
    'n',
    '<leader>mc',
    miniharp.clear,
    { desc = 'miniharp: clear marks' }
)
