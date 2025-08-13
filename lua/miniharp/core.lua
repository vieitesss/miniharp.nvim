local state = require('miniharp.state')
local util = require('miniharp.util')

---@class MiniharpMarks
local M = {}

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
local function jump_to(i)
    local m = state.marks[i]
    if not m then
        vim.notify('miniharp: no mark #' .. tostring(i), vim.log.levels.WARN)
        return
    end
    state.idx = i
    if util.bufname() ~= m.file then
        vim.cmd('edit ' .. vim.fn.fnameescape(m.file))
    end
    local maxline = vim.api.nvim_buf_line_count(0)
    local l = math.min(m.lnum, maxline)
    pcall(vim.api.nvim_win_set_cursor, 0, { l, m.col })
end

-- ---- public API ----

---Add or update a file mark for current buffer.
function M.add_file()
    local file = util.bufname()
    if file == '' then
        vim.notify('miniharp: cannot mark an unnamed buffer', vim.log.levels.WARN)
        return
    end
    local i = find_mark(file)
    local l, c = util.cursor()
    if i then
        state.marks[i].lnum, state.marks[i].col = l, c
        state.idx = i
        vim.notify(('miniharp: updated %s → %d:%d (#%d)'):format(util.pretty(file), l, c + 1, i))
    else
        add_mark({ file = file, lnum = l, col = c })
        vim.notify(('miniharp: added %s (#%d)'):format(util.pretty(file), state.idx))
    end
end

---Toggle a file mark for current buffer.
function M.toggle_file()
    local file = util.bufname()
    local i = find_mark(file)
    if i then
        table.remove(state.marks, i)
        if state.idx > #state.marks then state.idx = #state.marks end
        vim.notify('miniharp: removed file mark')
    else
        M.add_file()
    end
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
    if #state.marks == 0 then return vim.notify('miniharp: no file marks yet', vim.log.levels.WARN) end
    local i = state.idx + 1; if i > #state.marks then i = 1 end
    jump_to(i)
end

function M.prev()
    if #state.marks == 0 then return vim.notify('miniharp: no file marks yet', vim.log.levels.WARN) end
    local i = state.idx - 1; if i < 1 then i = #state.marks end
    jump_to(i)
end

---@return MiniharpMark[]
function M.list() return vim.deepcopy(state.marks) end

function M.clear()
    state.marks = {}; state.idx = 0
end

return M
