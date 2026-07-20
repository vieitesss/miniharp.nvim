vim.opt.runtimepath:prepend(vim.fn.getcwd())

local miniharp = require('miniharp')
local state = require('miniharp.state')
local ui = require('miniharp.ui')

miniharp.setup({ autoload = false, autosave = false, notifications = false })

local files = { vim.fn.tempname(), vim.fn.tempname(), vim.fn.tempname() }
for _, file in ipairs(files) do
    vim.fn.writefile({ file }, file)
end

local function edit(file)
    vim.cmd('edit ' .. vim.fn.fnameescape(file))
end

local function indicator()
    local ui_buf = vim.api.nvim_win_get_buf(state.ui_win)
    for _, line in ipairs(vim.api.nvim_buf_get_lines(ui_buf, 0, -1, false)) do
        local index = line:match('^%* (%d+)%.')
        if index then
            return tonumber(index)
        end
    end
end

edit(files[1])
miniharp.add_file()
edit(files[2])
miniharp.add_file()
ui.open({ enter = false })
assert(state.idx == 2 and indicator() == 2, 'marks the current file')

edit(files[3])
assert(state.idx == 0 and indicator() == nil, 'clears an unmarked file')
miniharp.next()
assert(state.idx == 1 and indicator() == 1, 'starts next at the first mark')
edit(files[3])
miniharp.prev()
assert(state.idx == 2 and indicator() == 2, 'starts prev at the last mark')

edit(files[1])
assert(state.idx == 1 and indicator() == 1, 'tracks external buffer changes')

vim.cmd('vsplit ' .. vim.fn.fnameescape(files[2]))
assert(state.idx == 2 and indicator() == 2, 'tracks focused windows')

vim.api.nvim_set_current_win(state.ui_win)
assert(
    state.idx == 2 and indicator() == 2,
    'keeps the editor file when UI is focused'
)

ui.close()
for _, file in ipairs(files) do
    vim.fn.delete(file)
end
