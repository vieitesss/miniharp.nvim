local state = require('miniharp.state')
local ui = require('miniharp.ui')
local utils = require('miniharp.utils')
local marks = require('miniharp.marks')
local notifier = require('miniharp.notify')

---@class MiniharpMarks
local M = {}

---@param msg string
local function echo_status(msg)
    vim.api.nvim_echo({ { msg, 'ModeMsg' } }, false, {})
end

---@param i any
---@return boolean
local function is_positive_integer(i)
    return type(i) == 'number' and i == i and i >= 1 and i % 1 == 0
end

---@param entry MiniharpMark
local function add_mark(entry)
    table.insert(state.marks, entry)
    state.idx = #state.marks
end

---@param step integer
local function cycle(step)
    if #state.marks == 0 then
        return notifier.notify('miniharp: no file marks yet', vim.log.levels.WARN)
    end

    local cursor = state.idx
    if cursor < 0 then
        cursor = 0
    end

    local attempts = #state.marks
    while attempts > 0 and #state.marks > 0 do
        local i = cursor + step
        if i > #state.marks then
            i = 1
        end
        if i < 1 then
            i = #state.marks
        end

        local ok, reason = marks.jump_to(i)
        if ok then
            notifier.echo(
                { { ('miniharp %d/%d'):format(i, #state.marks), 'ModeMsg' } },
                false,
                {}
            )
            ui.refresh()
            return
        end
        if reason ~= 'missing-file' then
            return
        end

        attempts = attempts - 1
        if step > 0 then
            cursor = i - 1
        else
            cursor = i
        end
    end

    if #state.marks == 0 then
        notifier.notify('miniharp: no file marks yet', vim.log.levels.WARN)
    end

    ui.refresh()
end

-- ---- public API ----

---Add or update a file mark for current buffer.
function M.add_file()
    local file = utils.bufname()
    if file == '' then
        notifier.notify(
            'miniharp: cannot mark an unnamed buffer',
            vim.log.levels.WARN
        )
        return
    end

    local i = marks.find(file)
    local l, c = utils.cursor()

    if i then
        state.marks[i].lnum, state.marks[i].col = l, c
        state.idx = i
        echo_status(
            ('miniharp updated %d/%d %s'):format(
                i,
                #state.marks,
                utils.pretty(file)
            )
        )
    else
        add_mark({ file = file, lnum = l, col = c })
        echo_status(
            ('miniharp marked %d/%d %s'):format(
                state.idx,
                #state.marks,
                utils.pretty(file)
            )
        )
    end

    ui.refresh()
end

---Toggle a file mark for current buffer.
function M.toggle_file()
    local file = utils.bufname()
    local i = marks.find(file)

    if i then
        marks.remove_at(i)
        echo_status(
            ('miniharp removed %d/%d %s'):format(
                math.max(state.idx, 0),
                #state.marks,
                utils.pretty(file)
            )
        )
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
    local i, m = marks.find(file)
    if i then
        m.lnum, m.col = l, c
    end
end

function M.next()
    cycle(1)
end

function M.prev()
    cycle(-1)
end

---@param i integer
function M.go_to(i)
    if #state.marks == 0 then
        notifier.notify('miniharp: no file marks yet', vim.log.levels.WARN)
        return
    end

    if not is_positive_integer(i) then
        notifier.notify(
            'miniharp: mark position must be a positive integer',
            vim.log.levels.WARN
        )
        return
    end

    local target = i
    while #state.marks > 0 do
        local ok, reason = marks.jump_to(target)
        if ok then
            echo_status(('miniharp %d/%d'):format(target, #state.marks))
            ui.refresh()
            return
        end

        if reason ~= 'missing-file' then
            return
        end

        target = math.min(target, #state.marks)
    end

    notifier.notify('miniharp: no file marks yet', vim.log.levels.WARN)
    ui.refresh()
end

---@return MiniharpMark[]
function M.list()
    return vim.deepcopy(state.marks)
end

function M.clear()
    state.marks = {}
    state.idx = 0
    state.ui_swap_from = nil
    ui.refresh()
end

return M
