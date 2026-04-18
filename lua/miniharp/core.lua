local state = require('miniharp.state')
local ui = require('miniharp.ui')
local utils = require('miniharp.utils')

---@class MiniharpMarks
local M = {}

local uv = vim.uv or vim.loop

---@param msg string
local function echo_status(msg)
    vim.api.nvim_echo({ { msg, 'ModeMsg' } }, false, {})
end

---@param file string
---@return integer|nil, MiniharpMark|nil
local function find_mark(file)
    for i, m in ipairs(state.marks) do
        if m.file == file then return i, m end
    end
end

---@param entry MiniharpMark
local function add_mark(entry)
    table.insert(state.marks, entry)
    state.idx = #state.marks
end

---@param i integer
---@return boolean, string?
local function jump_to(i)
    local m = state.marks[i]
    if not m then
        vim.notify('miniharp: no mark #' .. tostring(i), vim.log.levels.WARN)
        return false, 'missing-mark'
    end

    if not uv.fs_stat(m.file) then
        table.remove(state.marks, i)

        if state.idx >= i then
            state.idx = math.max(0, state.idx - 1)
        end

        vim.notify(('miniharp: removed missing mark %s'):format(utils.pretty(m.file)), vim.log.levels.WARN)
        return false, 'missing-file'
    end

    state.idx = i

    local target_win = vim.api.nvim_get_current_win()
    if state.ui_win and vim.api.nvim_win_is_valid(state.ui_win) and target_win == state.ui_win then
        if state.ui_origin_win and vim.api.nvim_win_is_valid(state.ui_origin_win) then
            target_win = state.ui_origin_win
        end
    end

    vim.api.nvim_win_call(target_win, function()
        if utils.bufname() ~= m.file then
            vim.cmd('edit ' .. vim.fn.fnameescape(m.file))
        end

        local maxline = vim.api.nvim_buf_line_count(0)
        local l = math.min(m.lnum, maxline)
        pcall(vim.api.nvim_win_set_cursor, 0, { l, m.col })
    end)

    vim.api.nvim_echo({ { ('miniharp %d/%d'):format(i, #state.marks), 'ModeMsg' } }, false, {})
    ui.refresh()
    return true
end

---@param step integer
local function cycle(step)
    if #state.marks == 0 then
        return vim.notify('miniharp: no file marks yet', vim.log.levels.WARN)
    end

    local cursor = state.idx
    if cursor < 0 then cursor = 0 end

    local attempts = #state.marks
    while attempts > 0 and #state.marks > 0 do
        local i = cursor + step
        if i > #state.marks then i = 1 end
        if i < 1 then i = #state.marks end

        local ok, reason = jump_to(i)
        if ok then return end
        if reason ~= 'missing-file' then return end

        attempts = attempts - 1
        if step > 0 then
            cursor = i - 1
        else
            cursor = i
        end
    end

    if #state.marks == 0 then
        vim.notify('miniharp: no file marks yet', vim.log.levels.WARN)
    end

    ui.refresh()
end

-- ---- public API ----

---Add or update a file mark for current buffer.
function M.add_file()
    local file = utils.bufname()
    if file == '' then
        vim.notify('miniharp: cannot mark an unnamed buffer', vim.log.levels.WARN)
        return
    end

    local i = find_mark(file)
    local l, c = utils.cursor()

    if i then
        state.marks[i].lnum, state.marks[i].col = l, c
        state.idx = i
        echo_status(('miniharp updated %d/%d %s'):format(i, #state.marks, utils.pretty(file)))
    else
        add_mark({ file = file, lnum = l, col = c })
        echo_status(('miniharp marked %d/%d %s'):format(state.idx, #state.marks, utils.pretty(file)))
    end

    ui.refresh()
end

---Toggle a file mark for current buffer.
function M.toggle_file()
    local file = utils.bufname()
    local i = find_mark(file)

    if i then
        table.remove(state.marks, i)

        if state.idx > #state.marks then state.idx = #state.marks end
        echo_status(('miniharp removed %d/%d %s'):format(math.max(state.idx, 0), #state.marks, utils.pretty(file)))
    else
        M.add_file()
        return
    end

    ui.refresh()
end

---Update last position for a file (used by autosave).
---@param file string
---@param l integer
---@param c integer
function M.update_last_for_file(file, l, c)
    local i, m = find_mark(file)
    if i then m.lnum, m.col = l, c end
end

function M.next()
    cycle(1)
end

function M.prev()
    cycle(-1)
end

---@return MiniharpMark[]
function M.list() return vim.deepcopy(state.marks) end

function M.clear()
    state.marks = {}
    state.idx = 0
    ui.refresh()
end

return M
