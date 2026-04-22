---@class MiniharpUI
local M = {}

local state = require('miniharp.state')
local utils = require('miniharp.utils')

local ns = vim.api.nvim_create_namespace('MiniharpUI')
local win, buf
local last_opts = {}
local config = {
    position = 'center',
    show_hints = true,
    enter = true,
}
local valid_positions = {
    center = true,
    ['top-left'] = true,
    ['top-right'] = true,
    ['bottom-left'] = true,
    ['bottom-right'] = true,
}

local function has_win(id)
    return id and vim.api.nvim_win_is_valid(id)
end

local function has_buf(id)
    return id and vim.api.nvim_buf_is_valid(id)
end

---@param position? string
---@return string
local function normalize_position(position)
    if type(position) ~= 'string' then
        return 'center'
    end

    position = position:lower():gsub('[%s_]+', '-')
    if valid_positions[position] then
        return position
    end

    vim.notify(
        ("miniharp: invalid ui.position '%s', using 'center'"):format(position),
        vim.log.levels.WARN
    )

    return 'center'
end

local function split_path(path)
    local rel = utils.pretty(path)
    local dir = vim.fn.fnamemodify(rel, ':h')
    local name = vim.fn.fnamemodify(rel, ':t')
    if dir == '.' then
        dir = ''
    end
    return name, dir
end

---@param opts? { msg?: string }
---@return string[], table
local function build_lines(opts)
    opts = opts or {}
    local lines = { 'Miniharp marks' }
    local row_offset = #lines
    local current_file = ''
    local current_idx
    local meta = {
        row_offset = row_offset,
        rows = {},
        current_idx = nil,
        close_line = nil,
    }

    if has_win(state.ui_origin_win) then
        local origin_buf = vim.api.nvim_win_get_buf(state.ui_origin_win)
        current_file = utils.bufname(origin_buf)
    else
        current_file = utils.bufname()
    end

    for i, m in ipairs(state.marks) do
        if m.file == current_file then
            current_idx = i
            break
        end
    end

    meta.current_idx = current_idx

    if opts.msg and opts.msg ~= '' then
        lines[#lines + 1] = ' ' .. opts.msg
        row_offset = #lines
        meta.row_offset = row_offset
    end

    if #state.marks == 0 then
        lines[#lines + 1] = ' No marks yet'
        lines[#lines + 1] = ' Toggle current file to start a loop'
    else
        for i, m in ipairs(state.marks) do
            local marker = current_idx == i and '*' or ' '

            local name, dir = split_path(m.file)
            local prefix = string.format('%s %d. ', marker, i)
            local row = prefix .. name
            local row_meta = {
                line = #lines + 1,
                marker_start = 0,
                marker_end = 1,
                number_start = 2,
                number_end = #prefix,
                name_start = #prefix,
                name_end = #prefix + #name,
                dir_start = nil,
                dir_end = nil,
            }
            if dir ~= '' then
                row = row .. '  ' .. dir
                row_meta.dir_start = #prefix + #name + 2
                row_meta.dir_end = #row
            end

            lines[#lines + 1] = row
            meta.rows[i] = row_meta
        end

        if config.show_hints then
            lines[#lines + 1] = ''
            lines[#lines + 1] = ' Close: [q] [esc] [ctrl-c]'
            meta.close_line = #lines
        end
    end

    return lines, meta
end

local function add_token_highlight(line, token, start_col)
    local col = string.find(line, token, start_col or 1, true)
    if not col then
        return
    end
    return col - 1, col - 1 + #token
end

local function apply_highlights(lines, meta)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, 'Title', 0, 0, -1)

    if meta.row_offset > 1 then
        vim.api.nvim_buf_add_highlight(buf, ns, 'Comment', 1, 0, -1)
    end

    if #state.marks == 0 then
        vim.api.nvim_buf_add_highlight(
            buf,
            ns,
            'Comment',
            meta.row_offset,
            0,
            -1
        )
        vim.api.nvim_buf_add_highlight(
            buf,
            ns,
            'Comment',
            meta.row_offset + 1,
            0,
            -1
        )
        return
    end

    for i, row in ipairs(meta.rows) do
        if row.dir_start and row.dir_end then
            vim.api.nvim_buf_add_highlight(
                buf,
                ns,
                'Comment',
                row.line - 1,
                row.dir_start,
                row.dir_end
            )
        end

        if meta.current_idx == i then
            vim.api.nvim_buf_add_highlight(
                buf,
                ns,
                'String',
                row.line - 1,
                row.marker_start,
                row.marker_end
            )
            vim.api.nvim_buf_add_highlight(
                buf,
                ns,
                'String',
                row.line - 1,
                row.number_start,
                row.number_end
            )
            vim.api.nvim_buf_add_highlight(
                buf,
                ns,
                'String',
                row.line - 1,
                row.name_start,
                row.name_end
            )
        end
    end

    if meta.close_line then
        local line = lines[meta.close_line]
        vim.api.nvim_buf_add_highlight(
            buf,
            ns,
            'Comment',
            meta.close_line - 1,
            0,
            7
        )

        for _, token in ipairs({ '[q]', '[esc]', '[ctrl-c]' }) do
            local start_col, end_col = add_token_highlight(line, token)
            if start_col and end_col then
                vim.api.nvim_buf_add_highlight(
                    buf,
                    ns,
                    'Special',
                    meta.close_line - 1,
                    start_col,
                    end_col
                )
            end
        end
    end
end

local function position_window(lines)
    local width = 0
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end

    width = math.min(width + 4, math.max(28, math.floor(vim.o.columns * 0.6)))
    local height = math.min(#lines, math.max(4, math.floor(vim.o.lines * 0.6)))
    local max_row = math.max(1, vim.o.lines - height - 2)
    local max_col = math.max(0, vim.o.columns - width)
    local row = math.max(1, math.floor((vim.o.lines - height) / 2) - 1)
    local col = math.max(0, math.floor((vim.o.columns - width) / 2))

    if config.position == 'top-left' then
        row, col = 1, 0
    elseif config.position == 'top-right' then
        row, col = 1, max_col
    elseif config.position == 'bottom-left' then
        row, col = max_row, 0
    elseif config.position == 'bottom-right' then
        row, col = max_row, max_col
    end

    return width, height, row, col
end

local function render()
    if not has_buf(buf) then
        return
    end

    local lines, meta = build_lines(last_opts)
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    apply_highlights(lines, meta)

    if has_win(win) then
        local width, height, row, col = position_window(lines)
        vim.api.nvim_win_set_config(win, {
            relative = 'editor',
            row = row,
            col = col,
            width = width,
            height = height,
        })
    end
end

local function close()
    local origin = state.ui_origin_win

    state.ui_win = nil
    state.ui_origin_win = nil

    if has_win(win) then
        pcall(vim.api.nvim_win_close, win, true)
    end

    if has_buf(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end

    win, buf = nil, nil
    last_opts = {}

    if has_win(origin) then
        pcall(vim.api.nvim_set_current_win, origin)
    end
end

function M.is_open()
    return has_win(win) and has_buf(buf)
end

function M.close()
    if not M.is_open() then
        return
    end
    close()
end

function M.refresh()
    if not has_win(win) or not has_buf(buf) then
        return
    end
    render()
end

local function focus_window()
    if not has_win(win) then
        return false
    end

    local current = vim.api.nvim_get_current_win()
    if current ~= win and has_win(current) then
        state.ui_origin_win = current
    end

    if current ~= win then
        pcall(vim.api.nvim_set_current_win, win)
    end

    return true
end

---@param opts? { position?: string, show_hints?: boolean, enter?: boolean }
function M.configure(opts)
    opts = opts or {}

    config = {
        position = normalize_position(opts.position),
        show_hints = opts.show_hints ~= false,
        enter = opts.enter ~= false,
    }
end

---@param opts? { msg?: string, enter?: boolean }
function M.open(opts)
    opts = opts or {}

    if has_win(win) then
        close()
    end

    last_opts = { msg = opts.msg }
    state.ui_origin_win = vim.api.nvim_get_current_win()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('filetype', 'miniharp', { buf = buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    local lines = build_lines(last_opts)
    local width, height, row, col = position_window(lines)
    local enter = opts.enter
    if enter == nil then
        enter = config.enter
    end

    win = vim.api.nvim_open_win(buf, enter, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        noautocmd = true,
    })

    state.ui_win = win

    local wo = vim.wo[win]
    wo.wrap = false
    wo.cursorline = false
    wo.number = false
    wo.relativenumber = false
    wo.signcolumn = 'no'

    vim.keymap.set('n', 'q', close, {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = 'miniharp: close list',
    })
    vim.keymap.set('n', '<Esc>', close, {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = 'miniharp: close list',
    })
    vim.keymap.set('n', '<C-c>', close, {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = 'miniharp: close list',
    })

    render()
end

function M.enter()
    if M.is_open() then
        focus_window()
        return
    end

    M.open({ enter = true })
end

return M
