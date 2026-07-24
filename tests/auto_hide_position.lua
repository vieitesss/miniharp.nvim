vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.o.columns = 80
vim.o.lines = 24

local miniharp = require('miniharp')
local state = require('miniharp.state')

miniharp.setup({
    autoload = false,
    autosave = false,
    notifications = false,
    ui = { position = 'top-right', enter = false, auto_hide = true },
})

vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    vim.tbl_map(function()
        return string.rep('x', 80)
    end, vim.fn.range(1, 30))
)
vim.api.nvim_win_set_cursor(0, { 15, 0 })
miniharp.show_list()

local editor = vim.api.nvim_get_current_win()
local list = state.ui_win
local config = vim.api.nvim_win_get_config(list)
config.col = config.col - 2
vim.api.nvim_win_set_config(list, config)

local editor_start = vim.fn.screenpos(editor, 1, 1)
local title = vim.fn.screenpos(list, 1, 1)
vim.api.nvim_win_set_cursor(editor, {
    title.row - editor_start.row + 1,
    title.col - 1 - editor_start.col,
})
vim.api.nvim_exec_autocmds('CursorMoved', {})
assert(
    vim.api.nvim_win_get_config(list).hide,
    'hides at the actual left border'
)
