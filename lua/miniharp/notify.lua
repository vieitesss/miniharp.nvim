local state = require('miniharp.state')

local M = {}

---@param msg string
---@param level? integer
---@param opts? table
function M.notify(msg, level, opts)
    if state.notifications == false then
        return
    end

    return vim.notify(msg, level, opts)
end

---@param chunks any[]
---@param history boolean
---@param opts table<string,any>|nil
function M.echo(chunks, history, opts)
    if state.notifications == false then
        return
    end

    return vim.api.nvim_echo(chunks, history, opts)
end

return M
