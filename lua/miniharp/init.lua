---@class Miniharp
local M = {}

local state = require('miniharp.state')
local utils = require('miniharp.utils')
local core = require('miniharp.core')
local storage = require('miniharp.storage')

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

M = vim.tbl_extend("keep", {}, core)

---Persist current state for the working directory.
function M.save()
    local ok, err = storage.save()
    vim.print(ok)
    if not ok then
        vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    else
        vim.notify('miniharp: saved marks for ' .. utils.pretty(vim.fn.getcwd()), vim.log.levels.INFO)
    end
end

---Restore state for the working directory (if present).
function M.restore()
    local ok, err = storage.load()

    vim.print(ok)
    if not ok then
        vim.notify('miniharp: ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    else
        vim.notify('miniharp: restored marks for ' .. utils.pretty(vim.fn.getcwd()), vim.log.levels.INFO)
    end
end

---@class MiniharpOpts
---@field autoload? boolean  @Load saved marks for this cwd on startup (default: false)
---@field autosave? boolean  @Save marks for this cwd on exit (default: false)

---Setup miniharp.
---@param opts? MiniharpOpts
function M.setup(opts)
    opts = opts or {}

    ensure_autosave_positions()

    local autoload = opts.autoload == true
    local autosave = opts.autosave == true

    if autoload then
        storage.load()
    end

    if autosave then
        ensure_persist_autosave()
    end
end

return M
