---@class MiniharpStorage
local M = {}

local state = require('miniharp.state')
local utils = require('miniharp.utils')

-- Pick a base dir for sessions (prefer stdpath('state') if available)
local function base_dir()
    local ok, dir = pcall(vim.fn.stdpath, 'state')
    if not ok or type(dir) ~= 'string' or dir == '' then
        dir = vim.fn.stdpath('data')
    end
    return dir .. '/miniharp/sessions'
end

-- Compute a session file path for a given cwd.
---@param cwd? string
---@return string path
local function session_path(cwd)
    cwd = cwd or vim.fn.getcwd()
    local norm_cwd = utils.norm(cwd)

    local key
    if type(vim.fn.sha256) == "function" then
        local ok, result = pcall(vim.fn.sha256, norm_cwd)
        if ok and type(result) == "string" and result ~= "" then
            key = result
        else
            key = norm_cwd:gsub('[^%w]+', '_')
        end
    else
        key = norm_cwd:gsub('[^%w]+', '_')
    end

    local dir = base_dir()
    vim.fn.mkdir(dir, 'p')
    return dir .. '/session-' .. key .. '.json'
end


---Save current marks for the cwd into stdpath('state'|'data')/miniharp/sessions.
---@param cwd? string
---@return boolean ok, string? err
function M.save(cwd)
    local path = session_path(cwd)
    local payload = {
        version = 1,
        idx = state.idx or 0,
        marks = state.marks or {},
    }

    local ok, json = pcall(utils.json_encode, payload)
    if not ok then return false, 'miniharp: JSON encode failed' end

    local lines = vim.split(json, '\n', { plain = true })
    local w_ok, err = pcall(vim.fn.writefile, lines, path)
    if not w_ok then return false, ('miniharp: write failed: %s'):format(err or path) end

    return true
end

---Load marks for the cwd, replacing current state if a session file exists.
---@param cwd? string
---@return boolean ok, string? err
function M.load(cwd)
    local path = session_path(cwd)
    if vim.fn.filereadable(path) ~= 1 then
        return false, 'miniharp: no session file for cwd'
    end

    local ok_read, content = pcall(function()
        return table.concat(vim.fn.readfile(path), '\n')
    end)
    if not ok_read then return false, 'miniharp: read failed' end

    local ok_json, data = pcall(utils.json_decode, content)
    if not ok_json or type(data) ~= 'table' then
        return false, 'miniharp: JSON decode failed'
    end

    local restored = {}
    if type(data.marks) == 'table' then
        for _, m in ipairs(data.marks) do
            if m and m.file and m.lnum and m.col then
                table.insert(restored, {
                    file = utils.norm(m.file),
                    lnum = tonumber(m.lnum) or 1,
                    col  = tonumber(m.col) or 0,
                })
            end
        end
    end

    state.marks = restored
    state.idx = math.min(tonumber(data.idx or 0) or 0, #state.marks)

    return true
end

return M
