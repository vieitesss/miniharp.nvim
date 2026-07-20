---@class Miniharp
local M = {}

local state = require('miniharp.state')
local utils = require('miniharp.utils')
local core = require('miniharp.core')
local storage = require('miniharp.storage')
local ui = require('miniharp.ui')
local marks = require('miniharp.marks')
local notifier = require('miniharp.notify')

local focus_autocmd

local function is_missing_session(err)
    return err and string.find(err, 'no session file for cwd', 1, true)
end

-- Create (or reuse) the plugin augroup
local function ensure_group()
    if state.augroup then
        return
    end
    state.augroup = vim.api.nvim_create_augroup('Miniharp', { clear = true })
end

local function sync_current_file()
    local current_win = vim.api.nvim_get_current_win()
    if current_win == state.ui_win then
        current_win = state.ui_origin_win
    end

    if not current_win or not vim.api.nvim_win_is_valid(current_win) then
        state.idx = 0
        ui.refresh()
        return
    end

    if state.ui_win then
        state.ui_origin_win = current_win
    end
    local current_buf = vim.api.nvim_win_get_buf(current_win)
    state.idx = marks.find(utils.bufname(current_buf)) or 0
    ui.refresh()
end

local function ensure_focus_tracking()
    if focus_autocmd then
        return
    end

    ensure_group()
    focus_autocmd = vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
        group = state.augroup,
        callback = sync_current_file,
        desc = 'miniharp: track current file mark',
    })
end

-- Track last cursor pos for marked files when leaving a buffer
local function ensure_autosave_positions()
    ensure_group()
    vim.api.nvim_create_autocmd('BufLeave', {
        group = state.augroup,
        callback = function(args)
            local file = utils.bufname(args.buf)
            if file == '' then
                return
            end
            local l, c = utils.cursor(0)
            core.update_last_for_file(file, l, c)
        end,
        desc = 'miniharp: remember last position for file marks',
    })
end

local function ensure_persist_autosave()
    ensure_group()
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = state.augroup,
        callback = function()
            storage.save()
        end,
        desc = 'miniharp: save marks session for cwd',
    })
end

local function ensure_dirchange(opts)
    ensure_group()
    vim.api.nvim_create_autocmd('DirChanged', {
        group = state.augroup,
        callback = function()
            local new_cwd = utils.norm(vim.fn.getcwd())
            local old_cwd = state.cwd
            if old_cwd == new_cwd then
                return
            end

            if opts.autosave ~= false then
                local ok, err = storage.save(old_cwd)
                if not ok then
                    notifier.notify(
                        ('miniharp: save failed for %s - %s'):format(
                            vim.fn.fnamemodify(old_cwd, ':~:.'),
                            err or 'unknown error'
                        ),
                        vim.log.levels.WARN
                    )
                end
            end

            core.clear()

            if opts.autoload then
                local ok, err = storage.load(new_cwd)
                if not ok and not is_missing_session(err) then
                    notifier.notify(
                        'miniharp: ' .. (err or 'unknown error'),
                        vim.log.levels.WARN
                    )
                end
            end

            sync_current_file()

            if opts.show_on_autoload and #state.marks > 0 then
                local msg = ('Restored %d mark(s)'):format(#state.marks)
                vim.schedule(function()
                    ui.open({ msg = msg })
                end)
            end

            state.cwd = new_cwd
        end,
        desc = 'miniharp: handle marks on DirChanged',
    })
end

M = vim.tbl_extend('keep', {}, core)

function M.show_list()
    if ui.is_open() then
        ui.close()
        return
    end

    ui.open({})
end

---Open the floating list and enter it. If already open, focus the existing window.
function M.enter_list()
    ui.enter()
end

---Persist current state for the working directory.
function M.save()
    local ok, err = storage.save()
    if not ok then
        notifier.notify(
            'miniharp: ' .. (err or 'unknown error'),
            vim.log.levels.ERROR
        )
    end
end

---Restore state for the working directory (if present).
function M.restore()
    local ok, err = storage.load()
    if not ok then
        local level = is_missing_session(err) and vim.log.levels.INFO
            or vim.log.levels.ERROR
        notifier.notify('miniharp: ' .. (err or 'unknown error'), level)
        return
    end

    sync_current_file()
end

---@class MiniharpOpts
---@field autoload? boolean  @Load saved marks for this cwd on startup (default: true)
---@field autosave? boolean  @Save marks for this cwd on exit (default: true)
---@field show_on_autoload? boolean  @Show the marks list UI after a successful autoload (default: false)
---@field notifications? boolean  @Enable notification and status messages (default: true)
---@field ui? MiniharpUIOpts  @Floating list UI options

---@class MiniharpUIOpts
---@field position? string  @Floating list position: 'center', 'top-left', 'top-right', 'bottom-left', or 'bottom-right' (default: 'center')
---@field show_hints? boolean  @Show close hints in the floating list (default: true)
---@field enter? boolean  @Enter the floating list window when opening it (default: true)

---Setup miniharp.
---@param opts? MiniharpOpts
function M.setup(opts)
    opts = opts or {}
    state.notifications = opts.notifications ~= false
    ui.configure(opts.ui)

    ensure_autosave_positions()
    ensure_focus_tracking()

    local autoload = opts.autoload ~= false
    local autosave = opts.autosave ~= false
    local show_ui = opts.show_on_autoload or false

    if autoload then
        local ok, err = storage.load()
        if not ok then
            if not is_missing_session(err) then
                notifier.notify(
                    'miniharp: ' .. (err or 'unknown error'),
                    vim.log.levels.WARN
                )
            end
        elseif #state.marks > 0 and show_ui then
            vim.schedule(function()
                ui.open({ msg = ('Restored %d mark(s)'):format(#state.marks) })
            end)
        end
    end

    sync_current_file()

    if autosave then
        ensure_persist_autosave()
    end

    ensure_dirchange({
        autoload = autoload,
        autosave = autosave,
        show_on_autoload = show_ui,
    })
end

return M
