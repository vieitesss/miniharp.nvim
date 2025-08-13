-- Minimal Harpoon-like file marks for Neovim (session-only)
-- Save as: lua/miniharp/init.lua

local M = {}

-- internal state (ordered list to support next/prev)
local marks = {}
local idx = 0 -- 0 means "no current"

-- autocmd group (created once)
local augroup

local function norm(path)
    return vim.fn.fnamemodify(path, ':p')
end

local function cursor(win)
    local ok, pos = pcall(vim.api.nvim_win_get_cursor, win or 0)
    if not ok then return 1, 0 end
    return pos[1], pos[2]
end

local function bufname(buf)
    buf = buf or 0
    return norm(vim.api.nvim_buf_get_name(buf))
end

local function jump_to(i)
    local m = marks[i]
    if not m then
        vim.notify('miniharp: no mark #' .. tostring(i), vim.log.levels.WARN)
        return
    end
    idx = i
    if bufname() ~= m.file then
        vim.cmd('edit ' .. vim.fn.fnameescape(m.file))
    end
    local maxline = vim.api.nvim_buf_line_count(0)
    local l = math.min(m.lnum, maxline)
    local c = m.col
    pcall(vim.api.nvim_win_set_cursor, 0, { l, c })
end

local function find_mark(file)
    for i, m in ipairs(marks) do
        if m.file == file then
            return i, m
        end
    end
end

local function add_mark(entry)
    table.insert(marks, entry)
    idx = #marks
    return idx
end

--- Add or update a FILE mark for the current file.
--- A file mark always points to your *last cursor position* in that file.
function M.add_file()
    local file = bufname()
    if file == '' then
        vim.notify('miniharp: cannot mark an unnamed buffer', vim.log.levels.WARN)
        return
    end
    local i = find_mark(file)
    local l, c = cursor()
    if i then
        marks[i].lnum, marks[i].col = l, c
        idx = i
        vim.notify(('miniharp: updated file mark for %s → %d:%d (#%d)')
            :format(vim.fn.fnamemodify(file, ':~:.'), l, c + 1, i))
    else
        add_mark({ file = file, lnum = l, col = c })
        vim.notify(('miniharp: added file mark %s (#%d)')
            :format(vim.fn.fnamemodify(file, ':~:.'), idx))
    end
end

--- Toggle a FILE mark for the current file
function M.toggle_file()
    local file = bufname()
    local i = find_mark(file)
    if i then
        table.remove(marks, i)
        if idx > #marks then idx = #marks end
        vim.notify('miniharp: removed file mark for current file')
    else
        M.add_file()
    end
end

--- Jump to next file mark (wraps)
function M.next()
    if #marks == 0 then
        vim.notify('miniharp: no file marks yet', vim.log.levels.WARN)
        return
    end
    local i = idx + 1
    if i > #marks then i = 1 end
    jump_to(i)
end

--- Jump to previous file mark (wraps)
function M.prev()
    if #marks == 0 then
        vim.notify('miniharp: no file marks yet', vim.log.levels.WARN)
        return
    end
    local i = idx - 1
    if i < 1 then i = #marks end
    jump_to(i)
end

--- List marks (for custom UIs)
function M.list()
    return vim.deepcopy(marks)
end

--- Clear all marks
function M.clear()
    marks = {}
    idx = 0
end

-- autosave last position for FILE marks on buffer switches
local function ensure_autosave()
    if augroup then return end
    augroup = vim.api.nvim_create_augroup('Miniharp', { clear = true })
    vim.api.nvim_create_autocmd('BufLeave', {
        group = augroup,
        callback = function(args)
            local file = bufname(args.buf)
            if file == '' then return end
            local i, m = find_mark(file)
            if not i then return end
            local l, c = cursor(0)
            m.lnum, m.col = l, c
        end,
        desc = 'miniharp: remember last cursor position for file marks',
    })
end

--- Optional setup to register default keymaps
--- opts.keymaps = { file = '<leader>m', next = '<C-n>', prev = '<C-p>' }
--- opts.autosave = true -- update file marks on buffer switches
function M.setup(opts)
    opts = opts or {}
    local km = (opts.keymaps == false) and {} or (opts.keymaps or {})
    local map = function(lhs, rhs, desc)
        if lhs and lhs ~= '' then
            vim.keymap.set('n', lhs, rhs, { desc = 'miniharp: ' .. desc })
        end
    end

    if opts.autosave == nil or opts.autosave then ensure_autosave() end

    map(km.file or '<leader>m', M.toggle_file, 'toggle file mark')
    map(km.next or '<C-n>', M.next, 'next file mark')
    map(km.prev or '<C-p>', M.prev, 'previous file mark')
end

return M
