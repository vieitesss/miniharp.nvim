---@class MiniharpUI
local M = {}

local state = require('miniharp.state')

local ns = vim.api.nvim_create_namespace('MiniharpUI')
local win, buf

local function close()
    if win and vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
    end

    if buf and vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end

    win, buf = nil, nil
    vim.on_key(nil, ns)
end

local function build_lines()
    local lines = { 'Miniharp marks' }
    for i, m in ipairs(state.marks) do
        local rel = vim.fn.fnamemodify(m.file, ':.')
        lines[#lines + 1] = string.format(' %d. %s', i, rel)
    end

    return lines
end

---Open the floating list until any key is pressed.
function M.open()
    if #state.marks == 0 then
        return
    end

    if win and vim.api.nvim_win_is_valid(win) then close() end

    buf = vim.api.nvim_create_buf(false, true)
    local lines = build_lines()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('filetype', 'miniharp', { buf = buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    local width = 0
    for _, l in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(l))
    end

    width = math.min(width + 2, math.floor(vim.o.columns * 0.45))
    local height = math.min(#lines, math.max(3, math.floor(vim.o.lines * 0.5)))
    local col = math.max(0, vim.o.columns - width - 1)
    local row = 1

    win = vim.api.nvim_open_win(buf, false, {
        relative  = 'editor',
        row       = row,
        col       = col,
        width     = width,
        height    = height,
        style     = 'minimal',
        border    = 'rounded',
        noautocmd = true,
    })

    local wo = vim.wo[win]
    wo.wrap = false
    wo.cursorline = false
    wo.number = false
    wo.relativenumber = false
    wo.signcolumn = 'no'

    -- Close on ANY key
    vim.on_key(function() close() end, ns)
end

return M
