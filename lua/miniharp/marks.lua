local state = require('miniharp.state')
local utils = require('miniharp.utils')
local notifier = require('miniharp.notify')

local uv = vim.uv or vim.loop

local M = {}

---@param file string
---@return integer|nil, MiniharpMark|nil
function M.find(file)
    for i, m in ipairs(state.marks) do
        if m.file == file then
            return i, m
        end
    end
end

---@param i integer
---@return boolean, MiniharpMark?
function M.remove_at(i)
    local mark = state.marks[i]
    if not mark then
        return false
    end

    table.remove(state.marks, i)

    if state.idx > i then
        state.idx = state.idx - 1
    elseif state.idx == i then
        state.idx = math.min(i, #state.marks)
    end

    return true, mark
end

---@param i integer
---@param j integer
---@return boolean
function M.swap(i, j)
    if i == j or not state.marks[i] or not state.marks[j] then
        return false
    end

    state.marks[i], state.marks[j] = state.marks[j], state.marks[i]

    if state.idx == i then
        state.idx = j
    elseif state.idx == j then
        state.idx = i
    end

    return true
end

---@param i integer
---@return boolean, string?
function M.jump_to(i)
    local mark = state.marks[i]
    if not mark then
        notifier.notify('miniharp: no mark #' .. tostring(i), vim.log.levels.WARN)
        return false, 'missing-mark'
    end

    if not uv.fs_stat(mark.file) then
        M.remove_at(i)
        notifier.notify(
            ('miniharp: removed missing mark %s'):format(utils.pretty(mark.file)),
            vim.log.levels.WARN
        )
        return false, 'missing-file'
    end

    state.idx = i

    local target_win = vim.api.nvim_get_current_win()
    if
        state.ui_win
        and vim.api.nvim_win_is_valid(state.ui_win)
        and target_win == state.ui_win
    then
        if state.ui_origin_win and vim.api.nvim_win_is_valid(state.ui_origin_win) then
            target_win = state.ui_origin_win
        end
    end

    vim.api.nvim_win_call(target_win, function()
        if utils.bufname() ~= mark.file then
            vim.cmd('edit ' .. vim.fn.fnameescape(mark.file))
        end

        local maxline = vim.api.nvim_buf_line_count(0)
        local lnum = math.min(mark.lnum, maxline)
        pcall(vim.api.nvim_win_set_cursor, 0, { lnum, mark.col })
    end)

    return true
end

return M
