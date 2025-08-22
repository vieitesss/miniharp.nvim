---@class MiniharpMark
---@field file string -- absolute file path
---@field lnum integer -- 1-based line number
---@field col integer -- 0-based column

---@class MiniharpState
---@field marks MiniharpMark[]
---@field cwd string
---@field idx integer
---@field augroup? integer

local M ---@type MiniharpState

M = { marks = {}, cwd = vim.fn.cwd(), idx = 0, augroup = nil }

return M
