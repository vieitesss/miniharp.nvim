vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.o.columns = 80
vim.o.lines = 24

local miniharp = require('miniharp')
local ui = require('miniharp.ui')

local function list_window()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'miniharp' then
            return win
        end
    end
end

local function list_visible()
    local win = list_window()
    return win ~= nil and not vim.api.nvim_win_get_config(win).hide
end

miniharp.setup({
    autoload = false,
    autosave = false,
    notifications = false,
    ui = { position = 'top-left', enter = false, auto_hide = true },
})

vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    vim.tbl_map(tostring, vim.fn.range(1, 30))
)
vim.api.nvim_win_set_cursor(0, { 15, 0 })
ui.open({ enter = false })
assert(ui.is_open(), 'shows the list away from the cursor')

vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.api.nvim_exec_autocmds('CursorMovedI', {})
assert(not list_visible(), 'hides the list when it covers the cursor')

vim.api.nvim_win_set_cursor(0, { 15, 0 })
vim.api.nvim_exec_autocmds('CursorMoved', {})
assert(
    vim.wait(300, list_visible),
    'reshows the list after the cursor clears it'
)

vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.api.nvim_exec_autocmds('VimResized', {})
assert(
    vim.wait(100, function()
        return not list_visible()
    end),
    'rechecks overlap after resize'
)
vim.api.nvim_win_set_cursor(0, { 15, 0 })
vim.api.nvim_exec_autocmds('CursorMoved', {})
assert(vim.wait(300, list_visible), 'reshows after resize overlap clears')

local editor = vim.api.nvim_get_current_win()
ui.close()
vim.api.nvim_win_set_cursor(editor, { 15, 0 })
ui.open({ enter = true })
vim.api.nvim_win_set_cursor(editor, { 3, 0 })
vim.api.nvim_set_current_win(editor)
assert(not list_visible(), 'hides after leaving a focused list')

ui.close()
vim.api.nvim_exec_autocmds('CursorMoved', {})
vim.wait(150)
assert(not ui.is_open(), 'manual close prevents the list from reopening')
