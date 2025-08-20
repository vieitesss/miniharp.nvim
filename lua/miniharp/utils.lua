---@class MiniharpUtils
local M = {}

function M.norm(path) return vim.fn.fnamemodify(path, ':p') end

---@param win? integer
---@return integer, integer
function M.cursor(win)
  local ok, pos = pcall(vim.api.nvim_win_get_cursor, win or 0)
  if not ok then return 1, 0 end

  return pos[1], pos[2]
end

---@param buf? integer
function M.bufname(buf)
  buf = buf or 0

  return M.norm(vim.api.nvim_buf_get_name(buf))
end

function M.pretty(path) return vim.fn.fnamemodify(path, ':~:.') end

function M.json_encode(tbl)
    if vim.json and vim.json.encode then
        return vim.json.encode(tbl)
    end
    return vim.fn.json_encode(tbl)
end

function M.json_decode(str)
    if vim.json and vim.json.decode then
        return vim.json.decode(str)
    end
    return vim.fn.json_decode(str)
end

return M
