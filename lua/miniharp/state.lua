local utils = require('miniharp.utils')

---@class MiniharpMark
---@field file string -- absolute file path
---@field lnum integer -- 1-based line number
---@field col integer -- 0-based column

---@class MiniharpState
---@field marks MiniharpMark[]
---@field cwd string
---@field idx integer
---@field augroup? integer
---@field ui_win? integer
---@field ui_origin_win? integer
---@field ui_swap_from? integer

local M ---@type MiniharpState

M = {
    marks = {},
    cwd = utils.norm(vim.fn.getcwd()),
    idx = 0,
    augroup = nil,
    ui_win = nil,
    ui_origin_win = nil,
    ui_swap_from = nil,
}

return M
