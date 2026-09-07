local S = {}

S.state = {}

local M = {}

M.SUPER = "SUPER"
M.SHIFT = "SHIFT"

function M.add(bind, callback, opts, description)
    local string_bind = table.concat(bind, " + ")
    S.state[string_bind] = {
        bind = string_bind,
        description = description,
    }
    hl.bind(string_bind, callback, opts)
end

function getState()
    return S.state
end

return M
