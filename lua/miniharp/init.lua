---@class Miniharp
local M = {}

local state = require('miniharp.state')
local utils = require('miniharp.utils')
local core = require('miniharp.core')
local storage = require('miniharp.storage')
local ui = require('miniharp.ui')

-- Create (or reuse) the plugin augroup
local function ensure_group()
    if state.augroup then return end
    state.augroup = vim.api.nvim_create_augroup('Miniharp', { clear = true })
end

-- Track last cursor pos for marked files when leaving a buffer
local function ensure_autosave_positions()
    ensure_group()
    vim.api.nvim_create_autocmd('BufLeave', {
        group = state.augroup,
        callback = function(args)
            local file = utils.bufname(args.buf); if file == '' then return end
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
        callback = function() storage.save() end,
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
            if old_cwd == new_cwd then return end

            if opts.autosave ~= false and #state.marks > 0 then
                local ok, err = storage.save(old_cwd)
                if not ok then
                    vim.notify(
                        ('miniharp: save failed for %s - %s')
                        :format(vim.fn.fnamemodify(old_cwd, ':~:.'), err or 'unknown error'),
                        vim.log.levels.WARN)
                end
            end

            core.clear()

            if opts.autoload then
                local ok, err = storage.load(new_cwd)
                if not ok then
                    if err and string.find(err, 'no session file for cwd') then
                        vim.notify('miniharp: ' .. err, vim.log.levels.INFO)
                    else
                        vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.WARN)
                    end
                end
            end

            local msg = (#state.marks > 0)
                and ('Restored %d mark(s)'):format(#state.marks)
                or 'No saved marks'

            vim.schedule(function() ui.open(msg) end)

            state.cwd = new_cwd
        end,
        desc = 'miniharp: handle marks on DirChanged',
    })
end

M = vim.tbl_extend("keep", {}, core)

function M.show_list() ui.open() end

---Persist current state for the working directory.
function M.save()
    local ok, err = storage.save()
    if not ok then
        vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    end
end

---Restore state for the working directory (if present).
function M.restore()
    local ok, err = storage.load()
    if not ok then
        vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    end
end

---@class MiniharpOpts
---@field autoload? boolean  @Load saved marks for this cwd on startup (default: true)
---@field autosave? boolean  @Save marks for this cwd on exit (default: true)
---@field show_on_autoload? boolean  @Show the marks list UI after a successful autoload (default: false)

---Setup miniharp.
---@param opts? MiniharpOpts
function M.setup(opts)
    opts = opts or {}

    ensure_autosave_positions()

    local autoload = opts.autoload ~= false
    local autosave = opts.autosave ~= false
    local show_ui = opts.show_on_autoload or false

    if autoload then
        local ok, err = storage.load()
        if not ok then
            if err and string.find(err, 'no session file for cwd') then
                vim.notify('miniharp: ' .. err, vim.log.levels.INFO)
            else
                vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.WARN)
            end
        elseif #state.marks > 0 and show_ui then
            vim.schedule(function() ui.open() end)
        end
    end

    if autosave then
        ensure_persist_autosave()
    end

    ensure_dirchange({ autoload = autoload, autosave = autosave })
end

return M
