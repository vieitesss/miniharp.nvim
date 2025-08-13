---@class Miniharp
local M = {}

local state = require('miniharp.state')
local util = require('miniharp.util')
local core = require('miniharp.core')

local function ensure_autosave()
    if state.augroup then return end

    state.augroup = vim.api.nvim_create_augroup('Miniharp', { clear = true })

    vim.api.nvim_create_autocmd('BufLeave', {
        group = state.augroup,
        callback = function(args)
            local file = util.bufname(args.buf); if file == '' then return end
            local l, c = util.cursor(0)
            core.update_last_for_file(file, l, c)
        end,
        desc = 'miniharp: remember last position for file marks',
    })
end

---Setup miniharp.
---@param opts? { autosave?: boolean }
function M.setup(opts)
    opts = opts or {}

    local autosave = opts.autosave; if autosave == nil then autosave = true end

    if autosave then ensure_autosave() end
end

-- Re-export public API
M = vim.tbl_extend("keep", {}, core)

return M
